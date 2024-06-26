#==============================================================================
# ** Sprite_Character
#------------------------------------------------------------------------------
#  This sprite is used to display the character.It observes the Game_Character
#  class and automatically changes sprite conditions.
#==============================================================================

class Sprite_Character < RPG::Sprite
  SHADOW_OPACITY = 80
  SHADOW_BLEND = 2
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :character                # character
  # Pixel movement related
  attr_accessor :direction
  attr_accessor :_loop_animation 
  attr_accessor :_animation 
  attr_accessor :_animation_hit
  attr_reader :character_name
  attr_reader :ch
  attr_accessor :loop_x_add
  attr_accessor :loop_y_add
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     viewport  : viewport
  #     character : character (Game_Character)
  #--------------------------------------------------------------------------
  def initialize(viewport, character = nil)
    @loop_x_add = 0
    @loop_y_add = 0
    @light_anim_count = 0
    super(viewport, :camera)
    @character = character
    update
  end
  #-----------------------------------------------------------------------------
  # Create a sprite of the characters collider for debugging
  #-----------------------------------------------------------------------------
  def create_collider_sprite
    half_size = @character.size_rad
    if [@character.size_x, @character.size_y].include?(0)
      puts "Character with 0 size?"
      puts @character.id
    end
    bmp = Bitmap.new(@character.size_x+1, @character.size_y+1)
    # Determine draw type based on collision type
    if @character.collide_type == :circ
      bmp.draw_circle(half_size, half_size, half_size, Color.new(0,255,0,50))
    else
      bmp.fill_rect(Rect.new(0,0,@character.size_x,@character.size_y), Color.new(0,255,0,50))
    end
    for coord in @character.collision_circle
      bmp.set_pixel(coord[0]+half_size,coord[1]+half_size,Color.new(255,0,0))
    end
    @collider_sprite = RPG::Sprite.new(:camera)
    @collider_sprite.bitmap = bmp
    @collider_sprite.ox = half_size
    @collider_sprite.oy = @character.size_y
  end
  #-----------------------------------------------------------------------------
  # Update collider sprite
  #-----------------------------------------------------------------------------
  def update_collider_sprite
    return unless $DEBUG
    if @collider_sprite.nil? || @character.size_x != @old_size_x
      create_collider_sprite
      @old_size_x = @character.size_x
      return
    end
    @collider_sprite.visible = $COLLISIONDB if @collider_sprite.visible != $COLLISIONDB
    @collider_sprite.update
    @collider_sprite.x = @character.screen_x
    @collider_sprite.y = @character.screen_y
  end
  #---------------------------------------------------------------------------
  # * Loop map update
  #---------------------------------------------------------------------------
  def update_map_looping
    puts "update map looping character"
    width = ($game_map.width * 32)
    height = ($game_map.height * 32)
    @loop_x_add = 0
    @loop_y_add = 0
    
    # Hero at the left border
    if $game_player.x < 32 * 10
      @loop_x_add = - width if @character.x > width - 32 * 10
      
    # Hero at the right border
    elsif $game_player.x > width - 32 * 10
      @loop_x_add = width if @character.x < 32 * 10
    end

    # Hero at the upper border
    if $game_player.y < 32 * 8
      @loop_y_add = - height if @character.y > height - 32 * 8
      
    # Hero at the lower border
    elsif $game_player.y > height - 32 * 8
      @loop_y_add = height if @character.y < 32 * 8
    end
  end
  #---------------------------------------------------------------------------
  # * Loop map update
  #---------------------------------------------------------------------------
  def process_graphic_change
    return unless @tile_id != @character.tile_id || 
      @character_name != @character.character_name ||
      @character_hue != @character.character_hue || 
      @frame_order != @character.frame_order ||
      @stand_frame_order != @character.stand_frame_order ||
      @direction_order != @character.direction_order ||
      self.tone != @character.tone
      @character.force_redraw
    self.mirror = @character.mirror
    @tile_id = @character.tile_id
    @character_name = @character.character_name
    @character_hue = @character.character_hue
    @frame_order = @character.frame_order
    @direction_order = @character.direction_order
    @stand_frame_order = @character.stand_frame_order
    self.tone = @character.tone
    @character.force_redraw = false
    if @tile_id >= 384
      self.bitmap = RPG::Cache.tile($game_map.tileset_name, @tile_id, @character.character_hue)
      self.src_rect.set(0, 0, Game_Map::TILE_SIZE, Game_Map::TILE_SIZE)
      self.ox = Game_Map::TILE_SIZE / 2
      self.oy = Game_Map::TILE_SIZE
    else
      if @character.character_name == ''
        self.bitmap = Bitmap.new(128,128)
      else
        self.bitmap = RPG::Cache.character(@character.character_name, @character.character_hue)
      end
      @cw = bitmap.width / (@character.frame_order + @character.stand_frame_order).uniq.length
      @ch = bitmap.height / @character.direction_order.length
      self.ox = @cw / 2
      self.oy = @ch
      create_shadow
      @shadow.visible = false if @character.character_name == ''
    end
    create_light
  end
  #--------------------------------------------------------------------------
  # * Create Shadow
  #--------------------------------------------------------------------------
  def create_shadow
    @shadow.dispose if @shadow
    @shadow = nil
    @shadow = Sprite.new(self.viewport, :camera)
    @shadow.ox = self.ox
    @shadow.oy = self.oy
    @shadow.bitmap = Bitmap.new(@cw * 2, @ch * 2)
    sg = RPG::Cache.character("Shadow", 0)
    # Stretch shadow to character width
    sw = @cw + @character.shadow_scale[0]
    sh = sg.height + @character.shadow_scale[1]
    @shadow.bitmap.stretch_blt(Rect.new(0,0,sw,sh), sg, Rect.new(0,0,sg.width,sg.height))
    @shadow.blend_type = SHADOW_BLEND
    @shadow.opacity = SHADOW_OPACITY
    @shadow.visible = true
  end
  #--------------------------------------------------------------------------
  # * Create Light
  #--------------------------------------------------------------------------
  def create_light
    @light.dispose if @light
    if @character.light[:name] == ""
      @light = nil
      return
    end
    @light = Sprite.new(self.viewport, :camera)
    # If the light is a cutout, duplicate existing graphic
    if @character.light[:name] == 'CUTOUT'
      # TODO
      return
    else
    # TODO: Hue
      @light.bitmap = RPG::Cache.light(@character.light[:name])
      @light.blend_type = 1
    end
    @light.ox = @light.bitmap.width / 2
    @light.oy = @light.bitmap.height / 2 + (@ch ? @ch / 2 : 8)
    @light.opacity = @character.light[:opacity]
    # Stretch accordingly
    @light.zoom_x = @character.light[:size][0] / 100.0
    @light.zoom_y = @character.light[:size][1] / 100.0
    # Always above lightmap
    @light.z = 5000
  end
  #--------------------------------------------------------------------------
  # * Update Shadow
  #--------------------------------------------------------------------------
  def update_shadow
    return unless @shadow
    if @character.shadow != @shadow.visible
      @shadow.visible = @character.shadow
    end
    @shadow.x = self.x + @character.shadow_offset[0]
    # Shadow does not "jump"
    @shadow.y = @character.screen_y(true, true) + @loop_y_add + @character.shadow_offset[1]
    @shadow.z = self.z - 20
    # Opacity variation
    @shadow.opacity = SHADOW_OPACITY * self.opacity / 255
    @shadow.bush_depth = self.bush_depth
  end
  #--------------------------------------------------------------------------
  # * Update Light
  #--------------------------------------------------------------------------
  def update_light
    return unless @light
    @light.x = self.x + @character.light[:offset][0]
    @light.y = self.y + @character.light[:offset][1]
    # TODO: Flicker animation, clean up, variable speed
    case @character.light[:animation]
    when :glow
      if @light_anim_count < 100
        @light.opacity -= 2
      elsif @light_anim_count > 150 && @light_anim_count < 250 && @light.opacity < @character.light[:opacity]
        @light.opacity += 2
      elsif @light_anim_count >= 250
        @light_anim_count = 0
      end
      @light_anim_count += 1
    when :flicker

    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    return if @character.nil?
    # Sprite of the characters collider for debugging
    update_collider_sprite
    # Update loop map
    if MapConfig.looping?($game_map)
      update_map_looping
    end
    # Process graphic change
    process_graphic_change
    # Set visible situation
    self.visible = (!@character.transparent)
    # If graphic is a character
    if @tile_id == 0
      # Frame update
      @character.pattern = 0 if @character.frame_order[@character.pattern] == nil
      if (@character.stop_count > 0 || @character.move_count == 0) &&
      (!@character.step_anime || @character.stand_frame_order.length > 1) &&
      @character.stand_frame_order.length > @character.pattern
        sx = (@character.stand_frame_order[@character.pattern] - 1) * @cw
      else
        sx = (@character.frame_order[@character.pattern] - 1) * @cw
      end       
      #-------------------------------------------------------------------------
      # 8 Dirs
      #-------------------------------------------------------------------------
      if @character.direction_order.length == 8
        sy = @character.direction_order.index(@character.direction) * @ch
      #-------------------------------------------------------------------------
      # 4 Dirs
      #-------------------------------------------------------------------------
      else
        if @character.direction % 2 == 0
          dir = @character.direction
        elsif @character.direction < 4 
          dir = 2
        elsif @character.direction > 6 
          dir = 8
        end
        sy = @character.direction_order.index(dir) * @ch
      end
      self.src_rect.set(sx, sy, @cw, @ch)
    end
    # Set sprite coordinates
    self.x = @character.screen_x + @loop_x_add
    self.y = @character.screen_y + @loop_y_add
    self.z = @character.screen_z(@ch) + @loop_y_add
    # Set opacity level, blend method, and bush depth
    # Allow overrides for effects
    unless self.effect?
      self.opacity = @character.opacity 
      self.blend_type = @character.blend_type
    end
    self.bush_depth = @character.bush_depth
    update_shadow
    update_light
    # Animation
    if @character.animation_id != 0
      animation = $data_animations[@character.animation_id]
      animation(animation, true)
      @character.animation_id = 0
    end
  end
  #-----------------------------------------------------------------------------
  # Dispose
  #-----------------------------------------------------------------------------
  def dispose
    if $DEBUG
      @collider_sprite.dispose
      @collider_sprite = nil
    end
    @shadow.dispose if @shadow
    @shadow = nil
    @light.dispose if @light
    @light = nil
    super
  end
end
