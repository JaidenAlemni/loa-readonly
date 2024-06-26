#==============================================================================
# ■ Spriteset_Battle
# Main spriteset controlling all battle animation elements
#==============================================================================
class Spriteset_Battle
  #--------------------------------------------------------------------------
  # * Public instance variables
  #--------------------------------------------------------------------------
  attr_reader   :viewport1                
  attr_reader   :viewport2      
  attr_reader   :viewport4       
  attr_accessor :actor_sprites
  attr_accessor :enemy_sprites
  attr_accessor :atb_bar
  attr_accessor :default_zoom
  attr_accessor :default_camera_x
  attr_accessor :default_camera_y
  #--------------------------------------------------------------------------
  include BattleConfig
  #--------------------------------------------------------------------------
  # * Object initialization
  #--------------------------------------------------------------------------
  def initialize(status_win_array, test_mode = false)
    @viewport1 = Viewport.new(0, 0, BATTLEFIELD_WIDTH, BATTLEFIELD_HEIGHT)
    @viewport2 = Viewport.new(0, 0, BATTLEFIELD_WIDTH, BATTLEFIELD_HEIGHT)
    @viewport3 = Viewport.new(0, 0, LOA::SCRES[0], LOA::SCRES[1])
    @viewport4 = Viewport.new(0, 0, LOA::SCRES[0], LOA::SCRES[1])
    @viewport2.z = 101
    @viewport3.z = 200
    @viewport4.z = 9000
    @battleback_sprite = Sprite.new(@viewport1, :camera)
    @battleback_sprite.mirror = true if $game_temp.battle_ambushed && BACK_ATTACK_BATTLE_BACK_MIRROR
    @battleback_sprite.tone = $game_temp.battleback_tone
    @battleback_sprite.y += BATTLEBACK_Y_OFFSET
    @enemy_sprites = []
    for enemy in $game_troop.enemies
      @enemy_sprites.push(Sprite_Battler.new(@viewport2, enemy, :camera))
    end
    # Create battle status faces and actors
    @actor_sprites = []
    @battle_faces = []
    $game_party.actors.each_with_index do |actor, i|
      @actor_sprites[i] = Sprite_Battler.new(@viewport2, actor, :camera)
      # Get the battle face X Y values based on where the status window overlays them
      party_size = $game_party.actors.size
      if test_mode
        x = 1280
        y = 720
      else
        x = status_win_array[i].x
        y = status_win_array[i].y
      end
      # Draw the faces
      @battle_faces[i] = Sprite_BattleFace.new(actor, x, y)
      # Set them inactive
      @battle_faces[i].inactive
      # Draw dead characters
      @battle_faces[i].dead = true if actor.dead?
    end
    # Set first actor as active
    @battle_faces[0].active
    @weather = RPG::Weather.new(@viewport1)
    @picture_sprites = []
    for i in 51..100
      @picture_sprites.push(Sprite_Picture.new(@viewport4, $game_screen.pictures[i]))
    end
    @timer_sprite = Sprite_Timer.new
    # Create ATB bar
    @atb_bar = ATB_Bar.new(@viewport3)
    # Draw status window and upper background       
    @battle_frame = Sprite.new(@viewport3)
    @battle_frame.bitmap = RPG::Cache.windowskin("BattleFrame")
    @battle_frame.oy = @battle_frame.bitmap.height
    @battle_frame.x = 0
    @battle_frame.y = LOA::SCRES[1]
    @default_zoom, @default_camera_x, @default_camera_y = $game_troop.camera_setup
    @new_camera_x = @default_camera_x
    @new_camera_y = @default_camera_y
    @duration = 30
    @total_duration = 30
    @camera_bounds = {
      x: {
        min: @default_camera_x - MIN_CAMERA_X * Camera.zoom,
        max: @default_camera_x + MAX_CAMERA_X * Camera.zoom
      },
      y: {
        min: @default_camera_y - MIN_CAMERA_Y * Camera.zoom,
        max: @default_camera_y + MAX_CAMERA_Y * Camera.zoom
      }
    }
    reset_camera_bounds
    # update once
    update
  end
  #--------------------------------------------------------------------------
  # * Determine if Effects are Displayed
  #--------------------------------------------------------------------------
  def effect?
    # Return true if even 1 effect is being displayed
    for sprite in @enemy_sprites + @actor_sprites
      return true if sprite.effect?
    end
    return false
  end
  #===============================================================================
  # The Art of Screenshake™ By: TheoAllen
  #===============================================================================
  def update_shake_screen
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
  # * Check if a battler has joined / left
  #--------------------------------------------------------------------------
  def check_party_sprites
    # A new battler joined
    if $game_party.actors.size > @actor_sprites.size
      for i in @actor_sprites.size...$game_party.actors.size
        actor = $game_party.actors[i]
        @actor_sprites[i] = Sprite_Battler.new(@viewport2, actor, :camera)
        @actor_sprites[i].battler = actor
        # @battle_faces[i] = Sprite_BattleFace.new(actor, status_win_array[i].x, status_win_array[i].y)
      end
    # A battler left
    elsif @actor_sprites.size > $game_party.actors.size
      change = @actor_sprites.size - $game_party.actors.size
      # Ensure the new actors are set as temporary
      change.times do |i|
        @actor_sprites[i + change].dispose
        @actor_sprites[i + change] = nil
      end
      @actor_sprites.compact!
    end
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update
    update_camera
    if @battleback_name != $game_temp.battleback_name
      @battleback_name = $game_temp.battleback_name
      if @battleback_sprite.bitmap != nil
        @battleback_sprite.bitmap.dispose
      end
      @battleback_sprite.bitmap = RPG::Cache.battleback(@battleback_name)
      #@battleback_sprite.src_rect.set(0, 0, BATTLEFIELD_WIDTH, BATTLEFIELD_HEIGHT)
    end
    for sprite in @enemy_sprites + @actor_sprites
      sprite.update
    end
    @battle_faces.each{|face| face.update}
    @weather.type = $game_screen.weather_type
    @weather.max = $game_screen.weather_max
    @weather.update
    for sprite in @picture_sprites
      sprite.update
    end
    @timer_sprite.update
    # Update screenshake
    update_shake_screen
    @viewport1.tone = $game_screen.tone
    #@viewport1.ox = $game_screen.shake
    @viewport2.tone = $game_screen.tone
    #@viewport2.ox = $game_screen.shake
    @viewport2.color = $game_screen.flash_color
    @viewport1.update
    @viewport2.update
    @viewport4.update
    # Update ATB bar
    @atb_bar.update
  end
  #--------------------------------------------------------------------------
  # * Set camera boundaries back to default
  #--------------------------------------------------------------------------
  def reset_camera_bounds
    Camera.x_bounds = @camera_bounds[:x].values
    Camera.y_bounds = @camera_bounds[:y].values
  end
  #--------------------------------------------------------------------------
  # * Camera update
  #--------------------------------------------------------------------------
  def update_camera
    if @duration > 0
      Camera.x = Easing.apply(Camera.x, @new_camera_x, @duration, @total_duration, :quad_out)
      Camera.y = Easing.apply(Camera.y, @new_camera_y, @duration, @total_duration, :quad_out)
      @duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # * Dispose 
  #--------------------------------------------------------------------------
  def dispose
    # Dispose of battleback sprite
    @battleback_sprite.dispose
    @battle_frame.dispose
    # Dispose of enemy sprites and actor sprites
    for sprite in @enemy_sprites + @actor_sprites
      sprite.dispose
    end
    # Dispose of weather
    @weather.dispose
    # Dispose of picture sprites
    for sprite in @picture_sprites
      sprite.dispose
    end
    # Dispose of actor faces
    @battle_faces.each{|face| face.dispose}
    @atb_bar.dispose
    # Dispose of timer sprite
    @timer_sprite.dispose
    # Dispose of viewports
    @viewport1.dispose
    @viewport2.dispose
    @viewport3.dispose
    @viewport4.dispose
  end
  #--------------------------------------------------------------------------
  # * Initiate Screen Shake
  #--------------------------------------------------------------------------
  def shake_screen(duration, power)
    $game_temp.shake_maxdur = duration
    $game_temp.shake_dur = duration
    $game_temp.shake_power = power
  end
  #--------------------------------------------------------------------------
  # * Refresh ATB bar
  #--------------------------------------------------------------------------
  def refresh_atb
    @atb_bar.create_icons
  end
  #--------------------------------------------------------------------------
  # * Make actor faces active
  #--------------------------------------------------------------------------
  def set_active_face(index, active)
    return if index.nil? || @battle_faces[index].nil?
    active ? @battle_faces[index].active : @battle_faces[index].inactive
  end
  #--------------------------------------------------------------------------
  # * Move actor faces
  #--------------------------------------------------------------------------
  def move_battle_faces(dir = :left, actor_index)
    return if actor_index.nil? || @battle_faces[actor_index].nil?
     dir == :left ? @battle_faces[actor_index].move(-160) : @battle_faces[actor_index].move(0)
  end
  #--------------------------------------------------------------------------
  # * Apply damage animation to battler if valid
  #--------------------------------------------------------------------------
  def set_damage_action(actor, index, action)
    return if index.nil?
    if actor
      # Play damage action and flag if it's a successful hit
      flag = @actor_sprites[index].damage_action(action)
      # Animate face on hit
      if @battle_faces[index]
        @battle_faces[index].hit if flag
        if $game_party.actors[index].dead?
          @battle_faces[index].dead = true 
        else
          @battle_faces[index].dead = false
        end
      end
    else
      @enemy_sprites[index].damage_action(action)
    end
  end
  #--------------------------------------------------------------------------
  # * Apply damage pop to battler if valid
  #--------------------------------------------------------------------------
 # def set_damage_pop(actor, index, damage)
  def set_damage_pop(actor, index)
    return if index.nil?
    @actor_sprites[index].damage_pop if actor
    @enemy_sprites[index].damage_pop unless actor
  end
  #--------------------------------------------------------------------------
  # * Set battler target(?)
  #--------------------------------------------------------------------------
  def set_target(actor, index, target)
    return if index.nil?
    @actor_sprites[index].new_target(target) if actor
    @enemy_sprites[index].new_target(target) unless actor
  end
  #--------------------------------------------------------------------------
  # * Set battler action 
  #--------------------------------------------------------------------------
  def set_action(actor, index, kind)
    return if index.nil?
    @actor_sprites[index].start_action(kind) if actor
    @enemy_sprites[index].start_action(kind) unless actor
  end  
  #--------------------------------------------------------------------------
  # * Set battler stand-by action
  #--------------------------------------------------------------------------
  def set_stand_by_action(actor, index)
    return if index.nil?
    @actor_sprites[index].push_stand_by if actor
    @enemy_sprites[index].push_stand_by unless actor
  end
  #--------------------------------------------------------------------------
  # * Set battler balloon graphic
  #--------------------------------------------------------------------------
  def start_balloon(actor, index, name)
    return if index.nil?
    @actor_sprites[index].start_balloon(name) if actor
    @enemy_sprites[index].start_balloon(name) unless actor
  end
  #--------------------------------------------------------------------------
  # * Stop balloon graphic
  #--------------------------------------------------------------------------
  def stop_balloon(actor, index)
    return if index.nil?
    @actor_sprites[index].stop_balloon if actor
    @enemy_sprites[index].stop_balloon unless actor
  end
  #--------------------------------------------------------------------------
  # * New camera setter / getters (with constraints)
  #--------------------------------------------------------------------------
  def new_camera_x=(value)
    @new_camera_x = value.clamp(@camera_bounds[:x][:min], @camera_bounds[:x][:max])
  end
  def new_camera_y=(value)
    @new_camera_y = value.clamp(@camera_bounds[:y][:min], @camera_bounds[:y][:max])
  end
  #--------------------------------------------------------------------------
  # * Make camera follow a battler
  #--------------------------------------------------------------------------
  def focus_camera(is_actor, index, lock = false, duration = CAMERA_SPEED)
    return if $game_options.disable_battle_camera
    return if index.nil?
    Camera.lock_y = lock
    Camera.unfollow
    sprite = is_actor ? @actor_sprites[index] : @enemy_sprites[index]
    if sprite.nil?
      center_camera
      return
    end
    @duration = 0
    Camera.follow(sprite)
  end
  #--------------------------------------------------------------------------
  # * Shift camera to battler
  #--------------------------------------------------------------------------
  def shift_camera(battler, duration = CAMERA_SPEED)
    return if $game_options.disable_battle_camera
    #Camera.lock_y = true
    reset_camera_bounds
    Camera.unfollow
    if battler.nil? || !battler.exist?
      center_camera
      return
    end
    if battler.actor?
      self.new_camera_x = battler.base_position_x - 24 * Camera.zoom
    else
      self.new_camera_x = battler.base_position_x + 24 * Camera.zoom
    end
    self.new_camera_y = battler.base_position_y - (4 * Camera.zoom)
    # Constrain 
    @duration = duration
    @total_duration = duration
  end
  #--------------------------------------------------------------------------
  # * Center camera to battlefield
  #--------------------------------------------------------------------------
  def center_camera(duration = CAMERA_SPEED + 20)
    Camera.lock_y = false
    Camera.unfollow
    reset_camera_bounds
    @new_camera_x = @default_camera_x
    @new_camera_y = @default_camera_y
    @duration = duration
    @total_duration = duration
    Camera.zoom_to(@default_zoom, ZOOM_INCREMENT)
  end
  #--------------------------------------------------------------------------
  # * Set camera zoom level
  #--------------------------------------------------------------------------
  def set_camera(x = nil, y = nil, zoom = nil)
    Camera.lock_y = false
    Camera.unfollow
    reset_camera_bounds
    Camera.zoom_to(zoom, ZOOM_INCREMENT) if zoom
    self.new_camera_x ||= x
    self.new_camera_y ||= y
    @duration = CAMERA_SPEED if (y || x)
  end
  #--------------------------------------------------------------------------
  # * Set wait time for battler actions
  #--------------------------------------------------------------------------
  def set_wait(time)
    for battler in @actor_sprites + @enemy_sprites
      battler.wait += time
    end
  end
end
