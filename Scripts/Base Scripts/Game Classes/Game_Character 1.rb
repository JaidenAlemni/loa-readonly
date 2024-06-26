#==============================================================================
# ** Game_Character (part 1) (Initialization and Checks)
#------------------------------------------------------------------------------
#  This class deals with characters. It's used as a superclass for the
#  Game_Player and Game_Event classes.
#==============================================================================

class Game_Character
  #-----------------------------------------------------------------------------
  # Directional Constants
  #-----------------------------------------------------------------------------
  DOWN = 2
  UP = 8
  LEFT = 4 
  RIGHT = 6
  UP_LEFT = 7
  UP_RIGHT = 9
  DOWN_LEFT = 1
  DOWN_RIGHT = 3
  #-----------------------------------------------------------------------------
  # Move Frequencies
  # Arrays are faster than quadratic equations!
  #-----------------------------------------------------------------------------
  MOVE_FREQUENCIES = [4,8,16,24,42,60]
  #-----------------------------------------------------------------------------
  # Turn Circle Management
  #
  # The turn circle accounts for the player's direction, as on the numpad
  # i.e. 2 = South, 9 = North East
  # - It is manipulated to get the direction based on different functions.
  #-----------------------------------------------------------------------------
  TURN_CIRCLE = [2, 1, 4, 7, 8, 9, 6, 3]
  #-----------------------------------------------------------------------------
  # Collision Sets
  #
  # A set of points checked on each collision direction
  # The center point should be checked before the edges, so for example facing down:
  # 5       4
  #   3   2 
  #     1
  # 
  # This principle applies to each direction, with the appropriate key returning
  # the center, left / right center, and left / right points to be checked
  #
  # I'm sure there's math for this. But I'm bad at math. -Jaiden
  #-----------------------------------------------------------------------------
  COLLISION_SETS = {
    1 => [1,4,2,7,3], # SW
    2 => [2,1,3,4,6], # S
    3 => [3,2,6,1,9], # SE
    4 => [4,7,1,8,2], # W
    6 => [6,3,9,2,8], # E
    7 => [7,8,4,9,1], # NW
    8 => [8,9,7,6,4], # N
    9 => [9,6,8,3,7]  # NE
  }
  # Default increment in pixels for steps
  SLIDE_INCREMENT = 2
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :id                       # ID
  attr_accessor :x                        # map x-coordinate (logical)
  attr_accessor :y                        # map y-coordinate (logical)
  attr_reader   :real_x                   # map x-coordinate (real * 128)
  attr_reader   :real_y                   # map y-coordinate (real * 128)
  attr_reader   :tile_id                  # tile ID (invalid if 0)
  attr_accessor   :character_name           # character file name
  attr_accessor :original_char_name       # character name prior to changes
  attr_reader   :character_hue            # character hue
  attr_accessor :opacity                  # opacity level
  attr_reader   :blend_type               # blending method
  attr_accessor :direction                # direction
  attr_accessor :pattern                  # pattern
  attr_reader   :move_route_forcing       # forced move route flag
  attr_reader   :through                  # through
  attr_accessor :animation_id             # animation ID
  attr_accessor :transparent              # transparent flag
  #--------------------------------------------------------------------------
  # * MMW
  attr_accessor :move_route              # Character's Move Route  
  attr_accessor :direction               # Used for changing bubble orientation
  attr_accessor :direction_fix           # Character locked facing a direction 
  attr_accessor :walk_anime              # Character steps when moves
  attr_accessor :step_anime              # Character is Stepping
  attr_accessor :erased                  # Erased Flag
  attr_accessor :original_move_speed     # Characters original Move Speed
  attr_accessor :original_move_frequency # Characters original Move Speed
  attr_accessor :no_ff                   # Prevents Auto Foot Forward Off
  attr_accessor :no_mc                   # No 'M'ove Continue
  attr_accessor :dist_kill               # Closes ALL windows if Player X Dist
  attr_reader   :last_real_x             # last map x-coordinate
  attr_reader   :last_real_y             # last map y-coordinate
  attr_accessor :move_frequency          # allows resetting if interrupted
  attr_accessor :allow_flip              # if event was triggered by player
  attr_accessor :preferred_loc           # triggered after Msg Reposition
  #--------------------------------------------------------------------------
  # * Pixel Movement
  attr_accessor   :stop_count
  attr_accessor   :event
  attr_accessor   :move_speed
  attr_accessor   :walk_anime
  attr_accessor   :step_anime
  attr_accessor   :speed_factor
  attr_accessor   :frame_order
  attr_accessor   :original_frame_order # For special move routes
  attr_accessor   :direction_order
  attr_accessor   :stand_frame_order
  attr_accessor   :frame_speed
  attr_accessor   :stand_frame_speed
  attr_accessor   :shift_x
  attr_accessor   :shift_y
  # attr_accessor   :jump_count
  # attr_accessor   :jump_peak
  attr_accessor   :pathfinding
  attr_reader     :always_on_top
  attr_reader     :move_count
  attr_reader     :move_type
  attr_reader     :collision_circle
  attr_reader     :size_rad
  attr_accessor   :bounding_box  # Collision bounding box (ORIGIN IS TOP LEFT!!!)
  attr_accessor   :bounding_circ # Collision bounding circle (Origin is center)
  attr_accessor   :collide_type
  attr_accessor   :pass_height # Map passability level
  attr_accessor   :force_redraw # Flag to redraw sprite
  #--------------------------------------------------------------------------
  # * Push Blocks
  attr_accessor :last_x
  attr_accessor :last_y
  #--------------------------------------------------------------------------
  attr_accessor :shadow
  attr_accessor :shadow_offset
  attr_accessor :shadow_scale
  attr_reader :mirror
  attr_accessor :tone
  attr_accessor :light # Light object
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @id = 0
    @x = 0
    @y = 0
    @last_x = 0
    @last_y = 0
    @real_x = 0
    @real_y = 0
    @tile_id = 0
    @character_name = ""
    @original_char_name = ""
    @character_hue = 0
    @opacity = 255
    @blend_type = 0
    @direction = 2
    @pattern = 0
    @move_route_forcing = false
    @through = false
    @animation_id = 0
    @transparent = false
    @original_direction = 2
    @original_pattern = 0
    @move_type = 0
    @move_speed = 4
    @move_frequency = 6
    @move_route = nil
    @move_route_index = 0
    @original_move_route = nil
    @original_move_route_index = 0
    @walk_anime = true
    @step_anime = false
    @direction_fix = false
    @always_on_top = false
    @force_redraw = false
    @mirror = false
    @tone = Tone.new()
    @light = {
      name: "",
      opacity: 255,
      hue: 0,
      size: [100,100],
      offset: [0,0],
      animation: :none
    }
    @anime_count = 0
    @stop_count = 0
    @jump_count = 0
    @jump_start_count = 0
    @jump_end_count = 0
    @jump_peak = 0
    @wait_count = 0
    @locked = false
    @over_lightmap = false
    @prelock_direction = 0
    @pass_height = 0 # Flag for the map elevation the character is currently on
    # MMW
    @original_move_speed = 4
    @original_move_frequency = 6    
    @no_ff = nil
    @no_mc = nil
    @dist_kill = nil
    @shadow = false
    @shadow_offset = [0,0]
    @shadow_scale = [0,0]
    @sticky = false
    # Used with Flip and Sticky Options...
    @preferred_loc = nil
    # Pixel Movement
    @move_count = 0 #  counts the movement
    @move_speed = @move_speed * 1.0
    @max_steps = 0 # for moving commands
    @speed_factor = 1.0 # factor for changing the move speed with swamps/heights
    @pathfinding = Game_Pathfinding.new(self)
    @changed_dir = 0 
    @old_direction = @direction
    @collide_point = 0 # Records the point on the collision circle in which the collision happened
    # Initialize pixel movement settings
    init_pixel_movement
    # Update the bounding box to match character size
    create_event_hitbox 
    # Default to circular collision
    @collide_type = :circ
    # Create the collision circle
    create_collision_circle
  end
  #------------------------------------------------------------------------------
  # * Save compatibility for new attributes
  #------------------------------------------------------------------------------
  def shadow_offset
    @shadow_offset ||= [0,0]
    @shadow_offset
  end
  #------------------------------------------------------------------------------
  def shadow_scale
    @shadow_scale ||= [0,0]
    @shadow_scale
  end
  #------------------------------------------------------------------------------
  def tone
    @tone ||= Tone.new()
    @tone
  end
  #------------------------------------------------------------------------------
  def mirror
    @mirror ||= false
    @mirror
  end
  #------------------------------------------------------------------------------
  def light
    @light ||= {name: "", opacity: 255, hue: 0, size: [100,100], offset: [0,0], animation: :none}
    @light
  end
  #------------------------------------------------------------------------------
  def original_frame_order
    @original_frame_order ||= @frame_order
    @original_frame_order
  end
  #------------------------------------------------------------------------------
  # * Mirror sprite
  #------------------------------------------------------------------------------
  def mirror=(bool)
    @mirror = bool
    @force_redraw = true
  end

  # REDACTED

  #---------------------------------------------------------------------------
  # Slides character to the left of their relevant direction, if possible
  #---------------------------------------------------------------------------
  # def slide_left(side_ccw_point, steps)
  #   move_method = get_move_method(side_ccw_point)
  #   self.send(move_method, steps, false, false)
  # end
  #---------------------------------------------------------------------------
  # Slides character to the right of their relevant direction, if possible 
  #---------------------------------------------------------------------------
  # def slide_right(side_cw_point, steps)
  #   move_method = get_move_method(side_cw_point)
  #   self.send(move_method, steps, false, false)
  # end
  #--------------------------------------------------------------------------
  # * Lock
  #--------------------------------------------------------------------------
  def lock
    # If already locked
    if @locked
      # End method
      return
    end
    # Save prelock direction
    @prelock_direction = @direction
    # Turn toward player
    turn_toward_player
    # Set locked flag
    @locked = true
    # Store Movement Variables in case player walks away
    @ff_original_move_route_index = @move_route_index
    @ff_original_move_speed = @move_speed
    @ff_original_move_frequency = @move_frequency
    @ff_original_move_route = @move_route
    # Store Variable that Event was Triggered by Player
    # @allow_flip = true
  end
  #--------------------------------------------------------------------------
  # * Determine if Locked
  #--------------------------------------------------------------------------
  def lock?
    @locked
  end
  #--------------------------------------------------------------------------
  # * Unlock
  #--------------------------------------------------------------------------
  def unlock
    # If not locked
    unless @locked
      # End method
      return
    end
    # Clear locked flag
    @locked = false
    # If direction is not fixed
    unless @direction_fix
      # If prelock direction is saved
      if @prelock_direction != 0
        # Restore prelock direction
        @direction = @prelock_direction
      end
    end
    # Unset Variable that Event was Triggered by Player (MMW)
    # @allow_flip = false
    # @preferred_loc = nil
    # # Reset Player as well...
    # $game_player.allow_flip = false
    # $game_player.preferred_loc = nil
    # $game_player.sticky = false
    # Unset any possible dist kill flags
    if $game_temp.message_text == nil
      $game_map.events[@id].dist_kill = nil if @id
      $game_system.map_interpreter.max_dist_id = nil
    end
    # Reset Choice Index
    #$choice_index = 0    
    # Loads the Default Sound Settings at the End of Event Interaction
    #$game_system.message.load_sound_settings if $game_system.message.sound
    # Update step by step turn
    return if @direction_fix || @prelock_direction == 0
    self.update_turn_step_by_step
  end
  #-----------------------------------------------------------------------------
  # * Move to location
  #-----------------------------------------------------------------------------
  def moveto(x, y)
    self.x = x % ($game_map.width * Game_Map::TILE_SIZE)
    self.y = y % ($game_map.height * Game_Map::TILE_SIZE)
    @real_x = @x * 4
    @real_y = @y * 4
    @prelock_direction = 0
  end
  #--------------------------------------------------------------------------
  # * Get Screen X-Coordinates
  #--------------------------------------------------------------------------
  def screen_x(camera = true)
    # I don't know what the f I was doing here
    # But the message system uses this so UH
    unless camera
      return (@real_x / 4 - (Camera.x_edge + $game_map.display_x / 4)) * Camera.zoom + (Game_Map::TILE_SIZE/2 * Camera.zoom) 
    end
    # Get screen coordinates from real coordinates and map display position
    (@real_x - $game_map.display_x + 3) / 4 + @shift_x
  end
  #--------------------------------------------------------------------------
  # * Get Screen Y-Coordinates
  #--------------------------------------------------------------------------
  def screen_y(camera = true, ignore_jump = false)
    unless camera
      return (@real_y / 4 - (Camera.y_edge + $game_map.display_y / 4)) * Camera.zoom + (Game_Map::TILE_SIZE/2 * Camera.zoom)
    end
    # Get screen coordinates from real coordinates and map display position
    y = (@real_y - $game_map.display_y + 3) / 4 + @shift_y
    return y if ignore_jump
    # Make y-coordinate smaller via jump count
    if @jump_count >= @jump_peak
      n = @jump_count - @jump_peak
    else
      n = @jump_peak - @jump_count
    end
    y - (@jump_peak * @jump_peak - n * n) / 2
  end
  #--------------------------------------------------------------------------
  # * Get Screen Z-Coordinates
  # Rewrite of method to compensate for pixel movement
  #     height : character height
  #     add_shift : adds @shift_y to the calculation
  #     (disable to have event sprites move but still 
  #     calculate priority based on their original y)
  #--------------------------------------------------------------------------
  def screen_z(height = 0, camera = true, add_shift = false)
    # If set to Alway on Top, or is a tile event with a valid z-override case
    # This may end up having unintentional behavior such as applying to door
    # events, etc. that are on an override tile. Maybe use on player only?
    if @always_on_top || (self.tile_id == 0 && z_override_tile?)
      # 999, unconditional
      return 999
    end
    # Determine if y shift or camera correction should be added
    shift_y = add_shift ? @shift_y : 0
    y_edge = camera ? Camera.y_edge : 0
    # Get screen coordinates from real coordinates and map display position
    z = (@real_y - $game_map.display_y + 3) / 4 - y_edge + shift_y
    # If tile
    if @tile_id > 0
      # Add tile priority * Game_Map::TILE_SIZE
      z = z + $game_map.priorities[@tile_id] * Game_Map::TILE_SIZE
    # If character
    else
      # If height exceeds 32, then add 31
      # Issue with priority 1 tiles and slide putting the player 1 z increment off
      # For now, just subtract one to layer them below
      z = (z + ((height > Game_Map::TILE_SIZE) ? Game_Map::TILE_SIZE - 1 : 0))
    end
    z
  end
  #--------------------------------------------------------------------------
  # * Get Thicket Depth
  #--------------------------------------------------------------------------
  def bush_depth
    # If tile, or if display flag on the closest surface is ON
    if @tile_id > 0 or @always_on_top
      return 0
    end
    # If element tile other than jumping, then 12; anything else = 0
    if @jump_count == 0 and $game_map.bush?(@x, @y)
      return 12
    else
      return 0
    end
  end
  #--------------------------------------------------------------------------
  # * Get Z Override situation
  # (If the event is on a terrain tag that overrides z order)
  #--------------------------------------------------------------------------
  def z_override_tile?
    $game_map.z_override_tile(@x, @y, @pass_height)
  end
  #--------------------------------------------------------------------------
  # * Get Terrain Tag
  #--------------------------------------------------------------------------
  def terrain_tag
    $game_map.terrain_tag(@x, @y)
  end
  #--------------------------------------------------------------------------
  # * Get All Terrain Tags
  #--------------------------------------------------------------------------
  def all_terrain_tags
    $game_map.all_terrain_tags(@x, @y)
  end
end
