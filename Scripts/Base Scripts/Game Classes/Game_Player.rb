#==============================================================================
# ** Game_Player
#------------------------------------------------------------------------------
#  This class handles the player. Its functions include event starting
#  determinants and map scrolling. Refer to "$game_player" for the one
#  instance of this class.
#==============================================================================

class Game_Player < Game_Character
  #-----------------------------------------------------------------------------
  # Public Instance Variables
  #-----------------------------------------------------------------------------
  attr_accessor :direction
  attr_accessor :msg_stick  # Used for Positioning Msg Bubbles
  # Push blocks
  attr_accessor :old_speed
  attr_accessor :old_sprite
  # Pixel movement
  attr_accessor   :sprint
  attr_accessor   :ice_sliding
  attr_accessor   :slide
  #-----------------------------------------------------------------------------
  # Initialize
  #-----------------------------------------------------------------------------
  def initialize
    super
    @old_speed = @move_speed * 1.0
    @old_sprite = @character_name
    @real_steps = 0 # counts real steps, every 10 steps the step variable of
    # the game is increased by 1
    @sprint = false # true if sprinting
    @move_to_place = false # true if move_to_place method has been used
    @last_input = false # true if a key was pressed the last update
    @jump_wait = 0 # waiting time until player can jump again
    @ice_sliding = false
    @slide = PixelMove::ENABLE_SLIDE
    @step_anime = true if @stand_frame_order.length > 1
    @shadow = true
    @msg_stick = true
  end
  #--------------------------------------------------------------------------
  # * Passable Determinants
  #     x : x-coordinate
  #     y : y-coordinate
  #     d : direction 
  #--------------------------------------------------------------------------
  def passable?(x, y, d, steps = Game_Map::TILE_SIZE)
    @max_steps = 0

    steps_x = steps
    steps_y = steps

    new_x = x + get_xy_dir_value(:x, d, steps_x)
    new_y = y + get_xy_dir_value(:y, d, steps_y)
                 
    if $DEBUG && Input.press?(Input::CTRL)
      return false if !$game_map.valid?(new_x, new_y)
      @max_steps = steps
      return true
    end
    
    super
  end
  #--------------------------------------------------------------------------
  # * Set Map Display Position to Center of Screen
  #--------------------------------------------------------------------------
  def center(x, y)
    # Recalculate the screen center based on the new resolution.
    $game_map.display_x = [0, [x * 4 - $game_map.screen_center[0], $game_map.map_edge[0]].min].max
    $game_map.display_y = [0, [y * 4 - $game_map.screen_center[1], $game_map.map_edge[1]].min].max
    # max_x = (($game_map.width - (LOA::SCRES[0]/Game_Map::TILE_SIZE.to_f)) * Game_Map::REAL_FACTOR).to_i
    # max_y = (($game_map.height - (LOA::SCRES[1]/Game_Map::TILE_SIZE.to_f)) * Game_Map::REAL_FACTOR).to_i
    # $game_map.display_x = [0, [x * Game_Map::REAL_FACTOR - CENTER_X, max_x].min].max
    # $game_map.display_y = [0, [y * Game_Map::REAL_FACTOR - CENTER_Y, max_y].min].max
  end
  #--------------------------------------------------------------------------
  # * Move to Designated Position
  #     x : x-coordinate
  #     y : y-coordinate
  #--------------------------------------------------------------------------
  def moveto(x, y)
    super
    # Centering
    center(x, y)
    # Move caterpillers if they exist
    if $game_system.caterpiller_enabled
      $game_followers.each{|actor| actor.moveto(x, y)}
    end
    # if there is an event on the new player position, this event is moved
    $game_map.events.values.each do |event|
      next if (!self.on_event?(event)) || event.through
      event.moveto(event.event.x * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE/2, event.event.y * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE-2)
    end
  end
  #--------------------------------------------------------------------------
  # * Increaase Steps
  #--------------------------------------------------------------------------
  def increase_steps
    if @real_steps >= 10
      super
      # If move route is not forcing
      unless @move_route_forcing
        # Increase steps
        $game_party.increase_steps
        # Number of steps are an even number
        if $game_party.steps % 2 == 0
          # Slip damage check
          $game_party.check_map_slip_damage
        end
      end
      @real_steps = 0
    else
      @real_steps += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Get Encounter Count
  #--------------------------------------------------------------------------
  def encounter_count
    return @encounter_count
  end
  #--------------------------------------------------------------------------
  # * Make Encounter Count
  #--------------------------------------------------------------------------
  def make_encounter_count
    # Image of two dice rolling
    if $game_map.map_id != 0
      n = $game_map.encounter_step
      @encounter_count = rand(n) + rand(n) + 1
    end
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    # If party members = 0
    if $game_party.actors.size == 0
      # Clear character file name and hue
      @character_name = ""
      @character_hue = 0
      # End method
      return
    end
    # Get lead actor
    actor = $game_party.actors[0]
    # Set character file name and hue
    @character_name = actor.character_name
    @character_hue = actor.character_hue
    # Initialize opacity level and blending method
    @opacity = 255
    @blend_type = 0
  end
  #--------------------------------------------------------------------------
  # * Activation: Push key, Passable (same position as event)
  #--------------------------------------------------------------------------
  def check_event_trigger_here
    result = false
    # If event is running
    if $game_system.map_interpreter.running?
      return result
    end
    # Loop events
    for event in $game_map.events.values
      # Skip if it isn't the right trigger
      next unless event.trigger == 0
      # Skip if the event is jumping or already has been triggered
      next if event.jumping? || event.trigger_on
      # Skip unless the event overlaps
      next unless event.over_trigger?
      # If the player is inside of the event's bounding box
      if self.on_event?(event)
        # Prevent reactivation of the same event twice
        event.trigger_on = true
        # Start the event
        event.triggering_event_id = 0
        event.start
        # Flag activation
        result = true
        puts "triggered here event"
        break
      end
    end
    return result
  end
  #--------------------------------------------------------------------------
  # * Activation: Push Key, not Passable (outside of the event)
  #--------------------------------------------------------------------------
  def check_event_trigger_there
    result = false
    # If event is running
    if $game_system.map_interpreter.running?
      return result
    end
    # Loop Events
    for event in $game_map.events.values
      # Skip if it isn't the right trigger
      next unless event.trigger == 0
      # Skip if the event is jumping or inside the player's rect
      next if event.jumping? || event.over_trigger?
      # Is the player facing the event and less than 1 tile away?
      if self.borders?(event, self.size_rad * 2)
        event.triggering_event_id = 0
        event.start
        result = true
        puts "event trigger there (#{event.name})"
        break
      else
        # TODO : Probably not working properly
        # Get the center of the tile that the player is on
        cx = (@x / Game_Map::TILE_SIZE) * Game_Map::TILE_SIZE + 16
        cy = ((@y - 16) / Game_Map::TILE_SIZE) * Game_Map::TILE_SIZE + 30
        # Get the tile in front of the player
        new_x = cx + get_xy_dir_value(:x, @direction, Game_Map::TILE_SIZE)
        new_y = cy + get_xy_dir_value(:y, @direction, Game_Map::TILE_SIZE)
        # Is there a counter on that tile?
        if $game_map.counter?(new_x, new_y)
          # Check if there is a triggerable event on the next tile
          puts "checking counter top"
          new_x += get_xy_dir_value(:x, @direction, Game_Map::TILE_SIZE)
          new_y += get_xy_dir_value(:y, @direction, Game_Map::TILE_SIZE)
          front_rect = [new_x - Game_Map::TILE_SIZE / 2, new_y - Game_Map::TILE_SIZE, self.size_x, self.size_y]
          if Collision.rect_in_rect?(front_rect, event.bounding_box)
            event.triggering_event_id = 0
            event.start
            result = true
            puts "event trigger there (counter)"
            break
          end
        end
      end
    end
    return result
  end
  #-----------------------------------------------------------------------------
  # * Move to X, Y
  # turn - turn enabled
  # input - allow input while moving(?)
  #-----------------------------------------------------------------------------
  def move_to_place(x, y, turn = true, input = false)
    @move_to_place = !input
    super(x, y, turn)
  end
  #-----------------------------------------------------------------------------
  # * Check if movement is allowed during message display
  #-----------------------------------------------------------------------------
  def message_movement_allowed?
    # Is a message window showing?
    if $game_temp.message_window_showing
      # Is movement during message windows allowed?
      if $game_system.message.move_during
        # Is the window floating above an npc, and are there no choices showing
        if $game_system.message.floating && $scene.message_window.float_id != 0 && $game_temp.choice_max == 0 && $game_temp.num_input_digits_max == 0
          return true
        else
          return false
        end
      else
        return false
      end
    else
      # Is the interpreter running in another way?
      if $game_system.map_interpreter.running?
        return false
      end
      # A message window isn't showing and the interpreter isn't running: OK to move
      return true
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # If the player is not jumping, the interpreter is not running, a move_to_place or move route is not occuring
    # the direction didn't change, there isn't an ice slide, and there isn't a message showing that requires input
    if !self.jumping? && message_movement_allowed? && !@move_to_place && !@move_route_forcing && @direction == @old_direction && !@ice_sliding && @wait_count < 1
      # Set the player's steps
      steps = [(2 ** (@move_speed - 1)).round, 2].max
      # Upon releasing input(?)
      if @last_input
        # Reset coords
        #puts "SET REAL TO COORDS BEFORE: #{@x},#{@y}"
        @x = @real_x / 4
        @y = @real_y / 4
        #puts "AFTER: #{@x},#{@y}"
        #puts "======="
      end
      @last_input = true
      if @last_dir_input != Input.dir8
        @slide_dir = nil
        @slide_timer = 0
      end
      # Check player input
      case Input.dir8
      when 1 
        move_lower_left(steps, true, false)
      when 2
        move_down(steps, true, false)
      when 3
        move_lower_right(steps, true, false)
      when 4
        move_left(steps, true, false)
      when 6
        move_right(steps, true, false)
      when 7
        move_upper_left(steps, true, false)
      when 8 
        move_up(steps, true, false)
      when 9 
        move_upper_right(steps, true, false)
      else
        @last_input = false
      end
      @last_dir_input = Input.dir8
      # Stop sprinting
      if @sprint
        @sprint = false
      end
    end
    # Record old coordinates
    @last_real_x = @real_x
    @last_real_y = @real_y
    # Check push-key
    if !moving?
      # Disable move to place?
      @move_to_place = false if @move_to_place
      if Input.trigger?(Input::C) && !(@move_route_forcing || @move_to_place)
        self.check_event_trigger_here
        self.check_event_trigger_there
      end
    end
    # Update sprint input
    self.check_sprint_input
    # checks if player shall jump
    #self.check_jump_input
    # checks if player is sliding on ice
    self.check_ice_sliding
    
    # Game_Character#update
    super

    if !(@move_route_forcing || @move_to_place)
      # Event determinant is via touch of same position event
      # result = check_event_trigger_here([1, 2])
      # # updates encounter count according to move_speed
      # if result == false && (@encounter_count > 0 && !($DEBUG && Input.press?(Input::CTRL)))
      #   @encounter_count -= @max_steps
      # end
    end

    # Reset character's patter when sliding (lock direction?_
    @pattern = @original_pattern if @ice_sliding
                        
    # Check if the player is on a jumping tile
    self.check_jump_gap

    # Scroll the map
    if @real_y > @last_real_y && @real_y - $game_map.display_y > $game_map.screen_center[1]
      $game_map.scroll_down(@real_y - @last_real_y)
    end
    if @real_x < @last_real_x && @real_x - $game_map.display_x < $game_map.screen_center[0]
      $game_map.scroll_left(@last_real_x - @real_x)
    end
    if @real_x > @last_real_x && @real_x - $game_map.display_x > $game_map.screen_center[0]
      $game_map.scroll_right(@real_x - @last_real_x)
    end
    if @real_y < @last_real_y && @real_y - $game_map.display_y < $game_map.screen_center[1]
      $game_map.scroll_up(@last_real_y - @real_y)
    end

  end
  #--------------------------------------------------------------------------
  # * Jump tile determinant
  #--------------------------------------------------------------------------
  def on_jump_tile?
    if self.all_terrain_tags.include?(7)
      return true
    end
    # If on a jump event
    if $game_map.jump_tiles != []
      $game_map.jump_tiles.each do |event|
        if self.on_event?(event)
          return true
        end
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Check for jump gaps
  #--------------------------------------------------------------------------
  def check_jump_gap
    # Are we on a jump tile
    return unless on_jump_tile?
    # Don't check unless stationary
    return if self.moving?
    # Case by direction
    case @direction
    when 4; key = :LEFT
    when 2; key = :DOWN
    when 8; key = :UP
    when 6; key = :RIGHT
    end
    # Pressing a key against tile edge cardinally
    if Input.press?(key) && @direction % 2 == 0
      # Timer hasn't started
      if @jump_gap_timer.nil? 
        # Create timer
        # Note, if we reduce this too much, the player will jump twice--address that goofy logic first.
        @jump_gap_timer = Timer.new(0.25)
      # Timer finished
      elsif @jump_gap_timer.finished?
        # Initiate jump
        trigger_jump_gap
        # Clear timer
        @jump_gap_timer = nil
        return
      else
        # Timer update
        @jump_gap_timer.update
      end
    else
      # Reset timer
      if @jump_gap_timer && @jump_gap_timer.counter > 0
        @jump_gap_timer.reset
      end
    end
  end
  #-----------------------------------------------------------------------------
  # * Check ice sliding tiles
  #-----------------------------------------------------------------------------
  def check_ice_sliding
    # This will likely call for checking tiles via the collision map, not terrain tags
    # but if it does end up using terrain tags...
    return 
    
    if PixelMove::ICE_TILES == [] || (self.moving? && @ice_sliding)
      return
    end
    
    #---------------------------------------------------------------------------
    # checks for tile ids
    #---------------------------------------------------------------------------
    if PixelMove::ICE_TILES.include?($game_map.terrain_tag(@x, @y))  
      self.move_forward(28)
      @ice_sliding = @max_steps > 0
      return if @ice_sliding
    end
    
    @ice_sliding = false
  end
  #-----------------------------------------------------------------------------
  # * Check jump tiles
  #-----------------------------------------------------------------------------
  def check_jump
    # TODO
  end
  #-----------------------------------------------------------------------------
  # * Input for sprinting
  #-----------------------------------------------------------------------------
  def check_sprint_input
    return if !self.moving?
    if (PixelMove::SPRINT_KEY != nil && Input.press?(PixelMove::SPRINT_KEY) && Camera.zoom <= 3.0 && !@sprint)
      @sprint = true
    else
      @sprint = false if @sprint
    end
  end
  #-----------------------------------------------------------------------------
  # * Loop Map Teleport when Event reached the border, etc.
  #-----------------------------------------------------------------------------
  def update_loop_map
    result = super
    return if !result
    
    # corrects screen position
    $game_map.display_x += (@real_x - @last_real_x)
    $game_map.display_y += (@real_y - @last_real_y)
    @last_real_x = @real_x
    @last_real_y = @real_y
    
    return result
  end
  #-----------------------------------------------------------------------------
  # * Check steps on looping map
  #-----------------------------------------------------------------------------
  def check_steps_loop(dir, steps_max, x_add, y_add)
    counter = 0
    # Check steps in direction to see move length
    while counter < steps_max
      if self.passable?(@x + x_add, @y + y_add, dir, counter)
        counter += 1
      else
        break
      end
    end
    # Return potential number of steps
    return counter
  end
end #Class
