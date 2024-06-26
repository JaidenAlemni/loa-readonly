#==============================================================================
# * GIF Animations
#
# Created by Jaiden 
# For exclusive use in Legends of Astravia Only
#
# Overwrites the Sprite animation methods to instead utilize GIF functionality
# for animations
# Timing is still handled relatively the same way, with the 
# RPG::Animation::Timing array still holding SE and flash data.
# The animation graphic is now a GIF file, and frames do nothing.
#
# The animation hue instead holds the blending value. So a hue of 20 =
# 20 / 10 = 2 Blend type (Subtract)
#==============================================================================
module RPG
  class Sprite < ::Sprite
    #--------------------------------------------------------------------------
    # * Object Initialization
    #--------------------------------------------------------------------------
    alias gif_anim_initialize initialize
    def initialize(viewport=nil,camera=nil)
      gif_anim_initialize(viewport, camera)
      @_cells_max = 0
      @_loop_cells_max = 0
      @_z_order = 0
      @_animation_duration = 0
      @_animation_current_frame = 0
      @_animation_sprite = nil
      @time = 0
    end
    #--------------------------------------------------------------------------
    # * Dispose
    #--------------------------------------------------------------------------
    alias gif_anim_dispose dispose
    def dispose
      dispose_animation
      dispose_loop_animation
      gif_anim_dispose
    end
    #--------------------------------------------------------------------------
    # * Frame Update
    #--------------------------------------------------------------------------
    alias gif_anim_update update
    def update
      if @_animation != nil
        set_animation_coords(@_animation_sprite, @_animation.position, @_animation_sprite.camera)
        if (Graphics.frame_count % @_animation.frame_rate == 0)
          update_animation
        end
      end
      if @_loop_animation != nil
        set_animation_coords(@_loop_animation_sprite, @_loop_animation.position, @_loop_animation_sprite.camera)
        if (Graphics.frame_count % @_loop_animation.frame_rate == 0)
          update_loop_animation
        end
      end
      gif_anim_update
      #@@_animations.clear
    end
    #--------------------------------------------------------------------------
    # * Dispose Animation
    #--------------------------------------------------------------------------
    def dispose_animation
      if @_animation_sprite != nil
        @_animation_sprite.dispose
        @_animation_sprite = nil
      end
      @_animation = nil
      @_animation_duration = 0
      @mirror = false
    end
    #--------------------------------------------------------------------------
    # * Dispose Looping Animation
    #--------------------------------------------------------------------------
    def dispose_loop_animation
      if @_loop_animation_sprite != nil
        @_loop_animation_sprite.dispose
        @_loop_animation_sprite = nil
      end
      @_loop_animation = nil
    end
    #--------------------------------------------------------------------------
    # * Mirror Animation
    #--------------------------------------------------------------------------
    def animation_mirror(mirror_effect)
      @mirror = mirror_effect
    end
    #--------------------------------------------------------------------------
    # * Setup animation sprite
    # position: (0: top, 1: middle, 2: bottom, 3: screen)
    #--------------------------------------------------------------------------
    def setup_animation_sprite(data_animation)
      sprite = ::Sprite.new(self.viewport, :camera)
      bitmap = RPG::Cache.animation(data_animation.animation_name, 0)
      bitmap.looping = false
      bitmap.goto_and_stop(0)
      sprite.bitmap = bitmap
      sprite.mirror = @mirror
      sprite.z = @_z_order
      sprite.blend_type = data_animation.blend_type
      sprite.ox = bitmap.width / 2
      sprite.oy = data_animation.position == 2 ? bitmap.height - 24 : bitmap.height / 2
      set_animation_coords(sprite, data_animation.position, sprite.camera)
      return sprite
    end
    #--------------------------------------------------------------------------
    # * Manually Set Animation Coords
    # For sprites with mismatched zoom ratios
    #--------------------------------------------------------------------------
    def set_animation_coords(sprite, position, camera = false)
      # This coordinate varies based on the sprites origin  
      offset = self.height - self.oy
      if camera
        case position
        when 0 #top
          sprite.x = self.x
          sprite.y = (self.y + offset) - self.height
        when 2 #bottom
          sprite.x = self.x
          sprite.y = self.y
        else # Default to middle
          sprite.x = self.x
          sprite.y = (self.y + offset) - self.height / 2
        end
      else
        case position
        when 0
          sprite.x = Camera.calc_zoomed_x(self.x)
          sprite.y = Camera.calc_zoomed_y((self.y + offset) - self.height)
        when 2
          sprite.x = Camera.calc_zoomed_x(self.x)
          sprite.y = Camera.calc_zoomed_y(self.y)
        else # Default to middle
          sprite.x = Camera.calc_zoomed_x(self.x)
          sprite.y = Camera.calc_zoomed_y((self.y + offset) - self.height / 2)
        end
        sprite.zoom_x = [Camera.zoom - 1.0, 1.0].max
        sprite.zoom_y = [Camera.zoom - 1.0, 1.0].max
      end
    end
    #--------------------------------------------------------------------------
    # * Begin Single Animation
    # animation: $data_animations[id]
    # hit:       animation hit flag 
    # z_order:   sprite z position
    #--------------------------------------------------------------------------
    def animation(data_animation, hit, z_order=1000)
      # Dispose current animation
      dispose_animation
      # Setup the animation
      @_animation = data_animation
      return if @_animation == nil      
      # Set to nil and return if the graphic is nonexistant
      if data_animation.animation_name == ""
        @_animation = nil
        @_animation_duration = 0
        return
      end
      @_z_order = z_order
      @_animation_sprite = setup_animation_sprite(data_animation)
      @_animation_hit = hit
      @_animation_duration = @_animation_sprite.bitmap.frame_count
      @_animation_current_frame = 0
    end
    #--------------------------------------------------------------------------
    # * Begin Loop Animation
    #--------------------------------------------------------------------------
    def loop_animation(data_animation, z_order=1000)
      # Exit if animation did not change
      return if data_animation == @_loop_animation
      # Dispose current animation
      dispose_loop_animation
      # Setup new animation
      @_loop_animation = data_animation
      return if @_loop_animation == nil
      # Set to nil and return if the graphic is nonexistant
      if data_animation.animation_name == ""
        @_loop_animation = nil
        return
      end
      @_z_order = z_order
      @_loop_animation_sprite = setup_animation_sprite(data_animation)
      @_loop_animation_sprite.bitmap.looping = true
    end
    #--------------------------------------------------------------------------
    # * Update Single Animation
    #--------------------------------------------------------------------------
    def update_animation
      if @_animation_duration > 0
        # Check and process each timing
        @_animation.timings.each do |timing|
          if timing.frame == @_animation_current_frame
            animation_process_timing(timing, @_animation_hit)
          end
        end
        # Advance the bitmap and set the current frame
        @_animation_current_frame = @_animation_sprite.bitmap.next_frame
        @_animation_duration -= 1
      else
        dispose_animation
      end
    end
    #--------------------------------------------------------------------------
    # * Update Loop Animation
    #--------------------------------------------------------------------------    
    def update_loop_animation
      @_loop_animation.timings.each do |timing|
        if timing.frame == @loop_animation_sprite.current_frame
          animation_process_timing(timing, true)
        end
      end
      @_loop_animation_sprite.bitmap.next_frame
    end
    #--------------------------------------------------------------------------
    # * Setup Animation Sprites
    #--------------------------------------------------------------------------    
    def animation_set_sprites(sprites, cell_data, position, max_cells)
      # No longer needed :)
    end
    #--------------------------------------------------------------------------
    # * Process Animation Timing
    # Condition : (0: none, 1: hit, 2: miss)
    # Flash area : (0: none, 1: target, 2: screen; 3: delete target).
    #--------------------------------------------------------------------------  
    def animation_process_timing(timing, hit)
      if timing.condition == 0 || (timing.condition == 1 && hit) || (timing.condition == 2 && !hit)
        if timing.se.name != ''
          se = timing.se
          $game_system.se_play(RPG::AudioFile.new(se.name, se.volume, se.pitch))
        end
        # Shake the screens for flashes?
        if (timing.condition == 1 && hit) && $game_temp.in_battle
          $game_temp.shake_maxdur = timing.shake_duration
          $game_temp.shake_dur = timing.shake_duration
          $game_temp.shake_power = timing.shake_power
        end
        case timing.flash_scope
        when 1
          self.flash(timing.flash_color, timing.flash_duration * 2)
        when 2
          if self.viewport != nil
            self.viewport.flash(timing.flash_color, timing.flash_duration * 2)
          end
        when 3
          self.flash(nil, timing.flash_duration * 2)
        end
      end
    end
  #   #--------------------------------------------------------------------------
  #   # * Set X Coordinate
  #   #--------------------------------------------------------------------------      
  #   def x=(x)
  #     sx = x - self.x
  #     if sx != 0
  #       if @_animation_sprite != nil
  #         @_animation_sprite.x += sx
  #       end
  #       if @_loop_animation_sprite != nil
  #         @_loop_animation_sprite.x += sx
  #       end
  #     end
  #     super
  #   end
  #   #--------------------------------------------------------------------------
  #   # * Set Y Coordinate
  #   #--------------------------------------------------------------------------    
  #   def y=(y)
  #     sy = y - self.y
  #     if sy != 0
  #       if @_animation_sprite != nil
  #         @_animation_sprite.y += sy
  #       end
  #       if @_loop_animation_sprite != nil
  #         @_loop_animation_sprite.y += sy
  #       end
  #     end
  #     super
  #   end  
  end
end