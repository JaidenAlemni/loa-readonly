#==============================================================================
# ** Spriteset_Map
#------------------------------------------------------------------------------
#  This class brings together map screen sprites, tilemaps, etc.
#  It's used within the Scene_Map class.
#==============================================================================

class Spriteset_Map
  #-----------------------------------------------------------------------------
  # * Public Instance Variables
  #-----------------------------------------------------------------------------
  attr_accessor :character_sprites
  attr_accessor :game_followers_sprites
  attr_reader   :viewport3
  attr_accessor :timer_sprite
  attr_accessor :parallax
  attr_accessor :lightmap
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @loop_x_add = 0
    @loop_y_add = 0
    # Make viewports
    @viewport1 = Viewport.new(0, 0, LOA::SCRES[0], LOA::SCRES[1])
    @viewport2 = Viewport.new(0, 0, LOA::SCRES[0], LOA::SCRES[1])
    @viewport3 = Viewport.new(0, 0, LOA::SCRES[0], LOA::SCRES[1])
    @viewport2.z = 200
    @viewport3.z = 5000
    # Make tilemap
    @tilemap = Tilemap.new(@viewport1, :camera)
    @tilemap.tileset = RPG::Cache.tileset($game_map.tileset_name)
    for i in 0..6
      autotile_name = $game_map.autotile_names[i]
      @tilemap.autotiles[i] = RPG::Cache.autotile(autotile_name)
    end
    @tilemap.map_data = $game_map.data
    @tilemap.priorities = $game_map.priorities
    if $DEBUG
      $COLLISIONDB = false
      @tilemap_debug = Tilemap.new(@viewport2, :camera)
      # Find a way to use a catch all / create one based on TTs / passability
      #@tilemap_debug.tileset = Bitmap.new("Graphics/ZPassability/#{$game_map.tileset_name}")
      @tilemap_debug.tileset = Bitmap.new(32,32)
      # for i in 0..6
      #   autotile_name = $game_map.autotile_names[i]
      #   @tilemap_debug.autotiles[i] = RPG::Cache.collision_maps(autotile_name)
      # end
      @tilemap_debug.map_data = $game_map.data
      @tilemap_debug.visible = false
    end
    # Make panorama plane
    @panorama = Plane.new(@viewport1, :camera)
    @panorama.z = -1000
    # Make fog planes, record names
    @fog_names = []
    @fog_hues = []
    @fogs = []
    Game_Map::MAX_FOGS.times do |i|
      @fogs[i] = Plane.new(@viewport1, :camera)
      @fogs[i].z = 4000 - i * 100
      @fog_names[i] = ""
      @fog_hues[i] = 0
    end
    # Make extra fog and pano
    init_extra_pano
    # Lightmap
    @lightmap = Sprite.new(@viewport1, :camera)
    @lightmap.z = 4000
    @lightmap_name = nil
    # Make character sprites
    @character_sprites = []
    for i in $game_map.events.keys.sort
      sprite = Sprite_Character.new(@viewport1, $game_map.events[i])
      @character_sprites.push(sprite)
    end
    # Draw follower sprites
    if $game_system.caterpiller_enabled
      @game_followers_sprites = []
      for i in 1..$game_map.game_followers.length
        j = $game_map.game_followers.length - i
        sprite = Sprite_Character.new(@viewport1, $game_map.game_followers[j])
        @game_followers_sprites.push(sprite)
      end
    end
    @character_sprites.push(Sprite_Character.new(@viewport1, $game_player))
    # Make weather
    @weather = RPG::Weather.new(@viewport1)
    # Make picture sprites
    @picture_sprites = []
    for i in 1..50
      @picture_sprites.push(Sprite_Picture.new(@viewport2, $game_screen.pictures[i]))
    end
    # Make character bust sprites
    @bust_sprites = []
    for i in 1..6
      @bust_sprites.push(Sprite_Picture.new(@viewport2, $game_busts.busts[i]))
    end
    # Make map name sprite
    @map_name = Sprite_MapName.new(@viewport3, $data_map_exts[$game_map.map_id].loc_name)
    # Make timer sprite
    @timer_sprite = Sprite_Timer.new
    # Frame update
    update
  end
  #--------------------------------------------------------------------------
  # * Create extra fog, panorama and lightmap
  #--------------------------------------------------------------------------
  def init_extra_pano
    # Create parallax (unlike panorama, this overlays the map and should always = map size)
    if MapConfig.has_parallax?($game_map)
      @parallax = Plane.new(@viewport1, :camera)
      # If we're drawing above the player instead (but below other fogs)
      if CustomFogsPanorama.parallax_layer($game_map.map_id) == true
        @parallax.z = 2800
      end 
      @parallax.bitmap = RPG::Cache.fog("/Parallax/Map#{$game_map.map_id}", 0)
      @parallax.blend_type = 0 # Normal blending
      @parallax.opacity = 255
      @parallax.ox = $game_map.display_x / 4
      @parallax.oy = $game_map.display_y / 4
    end
  end
  #--------------------------------------------------------------------------
  # * Apply Tone to Tileset (experimental, unused)
  #--------------------------------------------------------------------------
  def tileset_tone(tone)
    @tilemap.tone = tone
  end
  #--------------------------------------------------------------------------
  # * Toggle Element Display
  # sym: :parallax, :lightmap
  #--------------------------------------------------------------------------
  def display_element(sym, bool)
    self.send(sym)&.visible = bool
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    # Dispose of tilemap
    @tilemap.tileset.dispose
    for i in 0..6
      @tilemap.autotiles[i].dispose
    end
    @tilemap.dispose
    if $DEBUG
      @tilemap_debug.tileset.dispose
      # for i in 0..6
      #   @tilemap_debug.autotiles[i].dispose
      # end
      @tilemap_debug.dispose
    end
    # Dispose of panorama plane
    @panorama.dispose
    # Dispose of fog planes
    @fogs.each{|f| f.dispose}
    # Dispose of extra fogs & pano
    @parallax.dispose if @parallax
    if @lightmap
      @lightmap.bitmap&.dispose
      @lightmap.bitmap = nil
      @lightmap.dispose
    end
    # Dispose of character sprites
    for sprite in @character_sprites
      sprite.dispose
    end
    # Dispose of followers
    if @game_followers_sprites
      for sprite in @game_followers_sprites
        sprite.dispose
      end
    end
    # Dispose of weather
    @weather.dispose
    # Dispose of picture sprites
    for sprite in @picture_sprites
      sprite.dispose
    end
    # Dispose character bust sprites
    @bust_sprites.each{|s| s.dispose}
    # Dispose of the map name sprite
    @map_name.dispose
    # Dispose of timer sprite
    @timer_sprite.dispose
    # Dispose of viewports
    @viewport1.dispose
    @viewport2.dispose
    @viewport3.dispose
  end
  #--------------------------------------------------------------------------
  # * Update Screenshake (TheoAllen)
  #--------------------------------------------------------------------------
  def update_screenshake
    if $game_temp.shake_dur > 0
      $game_temp.shake_dur -= 1
      return if $game_options.disable_screen_shake
      rate = $game_temp.shake_dur/$game_temp.shake_maxdur.to_f
      x_rand = rand($game_temp.shake_power)*rate*(rand > 0.5 ? 1 : -1)
      y_rand = rand($game_temp.shake_power)*rate*(rand > 0.5 ? 1 : -1)
      @viewport1.ox = x_rand
      @viewport1.oy = y_rand
      @viewport2.ox = x_rand
      @viewport2.oy = y_rand
    end
  end
  #--------------------------------------------------------------------------
  # * Update Fogs & Pano
  #--------------------------------------------------------------------------
  def update_extra_pano
    # Update parallax
    if @parallax
      @parallax.ox = $game_map.display_x / 4 
      @parallax.oy = $game_map.display_y / 4
    end
  end
  #--------------------------------------------------------------------------
  # * Loop map update
  #--------------------------------------------------------------------------
  def update_loop_map
    return unless MapConfig.looping?($game_map)
    width = ($game_map.width * Game_Map::TILE_SIZE)
    height = ($game_map.height * Game_Map::TILE_SIZE)
    if $game_player.x < Game_Map::TILE_SIZE # Hero at the left border
      @hero_left = true
      @loop_x_add += width if @hero_right
      @hero_right = false
    elsif $game_player.x > width - Game_Map::TILE_SIZE # Hero at the right border
      @hero_right = true
      @loop_x_add -= width if @hero_left
      @hero_left = false
    else
      @hero_left = false
      @hero_right = false
    end
    if $game_player.y < Game_Map::TILE_SIZE # Hero at the upper border
      @hero_up = true
      @loop_y_add += height if @hero_down
      @hero_down = false
    elsif $game_player.y > height - Game_Map::TILE_SIZE # Hero at the lower border
      @hero_down = true
      @loop_y_add -= height if @hero_up
      @hero_up = false
    else
      @hero_up = false
      @hero_down = false
    end
  end
  #--------------------------------------------------------------------------
  # * Update Lightmap
  #--------------------------------------------------------------------------
  def update_lightmap
    return unless $game_map.lightmap
    # Position
    @lightmap.ox = $game_map.display_x / 4 
    @lightmap.oy = $game_map.display_y / 4
    # If the lightmap file exists, update the file info
    if @lightmap_name != $game_map.lightmap[:name]
      if $game_map.lightmap[:name] == ""
        @lightmap.bitmap = Bitmap.new($game_map.width * Game_Map::TILE_SIZE, $game_map.height * Game_Map::TILE_SIZE)
      else
        @lightmap.bitmap = RPG::Cache.fog("/Lightmaps/#{$game_map.lightmap[:name]}", 0)
        Graphics.frame_reset
      end
      @lightmap_name = $game_map.lightmap[:name]
    end
    # Color blending
    if $game_map.lightmap[:duration] >= 1
      d = $game_map.lightmap[:duration]
      $game_map.lightmap[:color].red = ($game_map.lightmap[:color].red * (d - 1) + $game_map.lightmap[:color_target].red) / d
      $game_map.lightmap[:color].green = ($game_map.lightmap[:color].green * (d - 1) + $game_map.lightmap[:color_target].green) / d
      $game_map.lightmap[:color].blue = ($game_map.lightmap[:color].blue * (d - 1) + $game_map.lightmap[:color_target].blue) / d
      $game_map.lightmap[:color].alpha = ($game_map.lightmap[:color].alpha * (d - 1) + $game_map.lightmap[:color_target].alpha) / d
      bm = @lightmap.bitmap
      bm.clear
      bm.fill_rect(0,0,bm.width,bm.height,$game_map.lightmap[:color])
      @lightmap.color = $game_map.lightmap[:color]
      $game_map.lightmap[:duration] -= 1
    elsif @lightmap.color != $game_map.lightmap[:color]
      bm = @lightmap.bitmap
      bm.clear
      bm.fill_rect(0,0,bm.width,bm.height,$game_map.lightmap[:color])
      puts "applied color"
      puts @lightmap.color
      @lightmap.color = $game_map.lightmap[:color]
    end
    # If the blend type or opacity changed
    if @lightmap.blend_type != $game_map.lightmap[:blend_type]
      @lightmap.blend_type = $game_map.lightmap[:blend_type]
    end
    if @lightmap.opacity != $game_map.lightmap[:opacity]
      @lightmap.opacity = $game_map.lightmap[:opacity]
    end
  end
  #--------------------------------------------------------------------------
  # * Fogs update
  #--------------------------------------------------------------------------
  def update_fogs
    # Loop in fogs
    $game_map.fogs.each_with_index do |fog, index|
      fog_plane = @fogs[index]
      ss_fog_name = @fog_names[index]
      ss_fog_hue = @fog_hues[index]
      # If fog is different than current fog
      if ss_fog_name != fog[:name] || ss_fog_hue != fog[:hue]
        ss_fog_name = fog[:name]
        ss_fog_hue = fog[:hue]
        if fog_plane.bitmap != nil
          fog_plane.bitmap.dispose
          fog_plane.bitmap = nil
        end
        if ss_fog_name != ""
          fog_plane.bitmap = RPG::Cache.fog(ss_fog_name, ss_fog_hue)
        end
        @fog_names[index] = fog[:name]
        @fog_hues[index] = fog[:hue]
        Graphics.frame_reset
      end
      # Update fog plane
      fog_plane.zoom_x = fog[:zoom] / 100.0
      fog_plane.zoom_y = fog[:zoom] / 100.0
      fog_plane.opacity = fog[:opacity]
      fog_plane.blend_type = fog[:blend_type]
      fog_plane.ox = $game_map.display_x / 4 + fog[:ox] + @loop_x_add
      fog_plane.oy = $game_map.display_y / 4 + fog[:oy] + @loop_y_add
      fog_plane.tone = fog[:tone]
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # If panorama is different from current one
    if @panorama_name != $game_map.panorama_name or
       @panorama_hue != $game_map.panorama_hue
      @panorama_name = $game_map.panorama_name
      @panorama_hue = $game_map.panorama_hue
      if @panorama.bitmap != nil
        @panorama.bitmap.dispose
        @panorama.bitmap = nil
      end
      if @panorama_name != ""
        @panorama.bitmap = RPG::Cache.panorama(@panorama_name, @panorama_hue)
      end
      Graphics.frame_reset
    end
    # Update tilemap
    @tilemap.ox = $game_map.display_x / 4 
    @tilemap.oy = $game_map.display_y / 4 
    @tilemap.update
    if $DEBUG
      @tilemap_debug.ox = $game_map.display_x / 4 
      @tilemap_debug.oy = $game_map.display_y / 4 
      @tilemap_debug.update
      # A little messy, but this was the best place to do it
      if Input.triggerex?(Input::F8)
        @tilemap_debug.visible = true
        # Flag drawing of collider sprites too
        $COLLISIONDB = !$COLLISIONDB
      end
    end
    # Update looping
    update_loop_map
    # Update panorama plane
    if $game_map.parallax_lock
      @panorama.ox = $game_map.display_x / (Camera.zoom * 8).to_i
      @panorama.oy = $game_map.display_y / (Camera.zoom * 8).to_i
      @panorama.ox += @loop_x_add / 2
      @panorama.oy += @loop_y_add / 2
    else
      @panorama.ox = $game_map.display_x / 4 + $game_map.pano_ox
      @panorama.oy = $game_map.display_y / 4 + $game_map.pano_oy
      @panorama.ox += @loop_x_add
      @panorama.oy += @loop_y_add
    end
    # Update fog planes
    update_fogs
    # Update lightmaps
    update_lightmap
    # Update extra pano / lightmap
    update_extra_pano
    # Update character sprites
    for sprite in @character_sprites
      sprite.update
    end
    @game_followers_sprites&.each {|s| s.update} 
    # Update weather graphic
    @weather.type = $game_screen.weather_type
    @weather.max = $game_screen.weather_max
    @weather.ox = $game_map.display_x / 4
    @weather.oy = $game_map.display_y / 4
    @weather.update
    # Update picture sprites
    for sprite in @picture_sprites
      sprite.update
    end
    # Update bust sprites
    @bust_sprites.each{|s| s.update}
    # Update 
    if $game_temp.display_map_name
      @map_name.update
    end
    # Update timer sprite
    @timer_sprite.update
    # Set screen color tone and shake position
    @viewport1.tone = $game_screen.tone
    @viewport1.ox = $game_screen.shake
    # Set screen flash color
    @viewport3.color = $game_screen.flash_color
    # Update screenshake
    update_screenshake
    # Update viewports
    @viewport1.update
    @viewport3.update
  end
end
