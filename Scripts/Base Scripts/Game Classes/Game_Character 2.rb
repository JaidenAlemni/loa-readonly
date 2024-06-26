#==============================================================================
# ** Game_Character (part 2) (Update Methods)
#------------------------------------------------------------------------------
#  This class deals with characters. It's used as a superclass for the
#  Game_Player and Game_Event classes.
#==============================================================================

class Game_Character
  # None in index 0. 1 = slowest, 6 = fastest
  #MOVE_SPEEDS = [1, 2, 3, 5, 7, 10, 15]  1 2 3 5 8 13 21 34 52
  tile = Game_Map::TILE_SIZE
  MOVE_SPEEDS = [nil, 
    tile / 8,     # Slowest
    tile / 4,     # Slower
    tile * 3 / 8, # Slow
    tile * 5 / 8, # Fast
    tile * 3 / 4, # Faster
    tile          # Fastest
  ]
  MOVE_SMOOTH_VARIABLE_ID = 11 # Variable for adjusting speed modulation based on zoom amount
  DASH_SPEED_VARIABLE_ID = 12  # Variable for adjusting dash speed modulation
  #-----------------------------------------------------------------------------
  # Frame Update
  #-----------------------------------------------------------------------------
  def update              
 
    # update special for looped maps
    self.update_loop_map
       
    # checks if the move speed changes because of hills, swamps, etc.
    #self.move_speed_change
    
    # updates pathfinding (or creates new)
    @pathfinding.update
    return if self.update_turn_step_by_step
    if self.jumping?
      self.update_jump
    elsif self.moving?
      self.update_move
    else
      self.update_stop
    end

    # Update the bounding box
    if @old_bb_x != @x || @old_bb_y != @y
      update_bounding_coords
      @old_bb_x = @x
      @old_bb_y = @y
    end
                        
    #---------------------------------------------------------------------------
    # updates shown frame
    #---------------------------------------------------------------------------
    # stop animation
    if @stop_count > 0
      if @anime_count * @stand_frame_speed > (18 - (@move_speed * 2))
        if !@step_anime
          @pattern = @original_pattern
        else
          if @stand_frame_order.length < 2
            @pattern = (@pattern + 1) % @frame_order.length
          else
            @pattern = (@pattern + 1) % @stand_frame_order.length
          end
          @anime_count = 0
        end
      end
    # move animation
    elsif @move_count > 0
      # Lowering this number = faster animation
      frame_max = @sprint ? 14 : 18 
      if @anime_count * @frame_speed > (frame_max - (@move_speed * 2))
        @pattern = (@pattern + 1) % @frame_order.length
        @anime_count = 0
      end
    end
    
    if @wait_count > 0
      @wait_count -= 1
      return
    end

    if @move_route_forcing
      self.move_type_custom
      return
    end

    # If starting an event execution or locked (locking is used to auto-turn an event when interacted with)
    return if @starting || lock?

    
    #if @stop_count > (40 - @move_frequency * 2) * (6 - @move_frequency)
    # Calculate frequency based on framerate (count) instead
    if @stop_count % MOVE_FREQUENCIES[(6 - @move_frequency)] == 0
      case @move_type
      when 1
        self.move_type_random
      when 2
        self.move_type_toward_player
      when 3
        self.move_type_custom
      end
    end
  end
  #-----------------------------------------------------------------------------
  # * Update Step by Step Turn
  #-----------------------------------------------------------------------------
  def update_turn_step_by_step
    # If we aren't turning step by step
    if !$game_system.turn_step_by_step
      @old_direction = @direction
      return false
    end
    puts "step by step"
    # Direction Fix
    return false if @direction_fix
    # Direction did not change
    return false if @direction == @old_direction
    # In a cutscene
    #return false if self.is_a?(Game_Player) && $game_switches[PixelMove::CUTSCENE_PATTERN_SW]
    # Determine turn speed based on move speed
    # Currently step_by_step dur currently set to 4 (frames?)
    dur = 
      if @move_speed < 3.5
        [$game_system.turn_step_by_step_duration / 2, 1].max
      elsif @move_speed > 5.5
        [$game_system.turn_step_by_step_duration / 8, 1].max
      else
        [$game_system.turn_step_by_step_duration / 4, 1].max
      end
    # Get the indexes of the current and desired direction
    # TURN_CIRCLE is an array of direction integers starting at south (2) moving clockwise
    ind1 = TURN_CIRCLE.index(@old_direction)
    ind2 = TURN_CIRCLE.index(@direction)
 
    # Update turn
    # If the change in direction is greater than 1 
    if (ind1 - ind2).abs > 1 && [ind1, ind2].min - [ind1, ind2].max + 8 > 1
      
      if (Graphics.frame_count > @changed_dir + dur || @changed_dir == 0)
        dir = @direction
        @direction = @old_direction
        @old_direction = dir
        @pattern = 0 
        @changed_dir = Graphics.frame_count
    
      # changing is in progress
      elsif @changed_dir > 0 && (Graphics.frame_count - @changed_dir) % dur == 0
        # Turn counter clockwise (left)
        if (ind1 < ind2 && ind1 - ind2 + 8 > ind2 - ind1) || (ind2 < ind1 && ind2 - ind1 + 8 < ind1 - ind2)
          @direction = get_dir_ccw(@direction, 1)
        else # turn cw
          @direction = get_dir_cw(@direction, 1)
        end
        @direction = TURN_CIRCLE[0] if @direction == nil
        @changed_dir = Graphics.frame_count
      end
    end
    
    # ends
    if Graphics.frame_count > @changed_dir + dur + 1 || @changed_dir == 0
      @old_direction = @direction
    elsif Graphics.frame_count > @changed_dir + dur
      @direction = @old_direction
    else
      return true
    end
    return false
    
  end
  #--------------------------------------------------------------------------
  # * Frame Update (jump)
  #--------------------------------------------------------------------------
  def update_jump
    # Reduce jump count by 1
    @jump_count -= 1
    # Finished jumping
    # FIXME If you uncomment this, any move routes with a Jump call will
    # behave extraordinarily badly. 
    # if @jump_count == 0
    #   route = CustomRoutes.create_route(:end_jump, self)
    #   self.force_move_route(route)
    # end
    # Calculate new coordinates
    @real_x = ((@real_x * @jump_count) + (@x * 4)) / (@jump_count + 1)
    @real_y = ((@real_y * @jump_count) + (@y * 4)) / (@jump_count + 1)
  end
  #--------------------------------------------------------------------------
  # * Update frame (move)
  #--------------------------------------------------------------------------
  def update_move
    #puts "= Pre Move =\n[#{self.x},#{self.y}] Real: [#{@real_x},#{@real_y}]\n" if self.is_a?(Game_Player)
    
    # Round coordinates
    self.x = @x.round
    self.y = @y.round

    # Absolute values
    x_abs = ((@x * 4) - @real_x).abs
    y_abs = ((@y * 4) - @real_y).abs 

    # Amount to move in pixels, modulated by zoom factor
    # FIXME: Less float math fuckery would really help with performance
    base_speed = MOVE_SPEEDS[@move_speed] * (1 - ($game_variables[MOVE_SMOOTH_VARIABLE_ID] / 1000.0 * @move_speed)) * @speed_factor
    #speed_factor = (MOVE_SPEEDS[@move_speed] * (0.5 + (($game_variables[ZOOM_SPEED_VARIABLE_ID] / 100.0) * Camera.zoom / 5.0))).round

    # Check Sprint
    if self.is_a?(Game_Player) && @sprint
      base_speed = base_speed * (100 + $game_variables[DASH_SPEED_VARIABLE_ID]) / 100
    elsif @sliding
      base_speed /= 2
      @sliding = false
    else
      base_speed
    end

    # Diagonals
    if @direction % 2 != 0
      base_speed /= LOA::SQRT_2
    end

    # Make sure this never ends up as 0
    distance = [base_speed.round, 1].max

    distance_y = distance

    # changes distance so the event uses the straight way
    if x_abs != 0 && y_abs < x_abs
      distance_y = distance * 1.0 * y_abs / x_abs
    end

    #puts "Distance Y: #{distance_y}" if self.is_a?(Game_Player)

    # moves the character
    if @y * 4 < @real_y
      # Up
      @real_y = [@real_y - distance_y, @y * 4].max.round
    elsif @y * 4 > @real_y
      # Down
      @real_y = [@real_y + distance_y, @y * 4].min.round
    end
    
    distance_x = distance

    # changes distance so the event uses the straight way
    if y_abs != 0 && x_abs / 1 < y_abs
      distance_x = distance * 1.0 * x_abs / y_abs
    end
                
    #puts "Distance X: #{distance_x}" if self.is_a?(Game_Player)

    # moves the character
    if @x * 4 < @real_x
      # Left
      @real_x = [@real_x - distance_x, @x * 4].max.round
    elsif @x * 4 > @real_x
      # Right
      @real_x = [@real_x + distance_x, @x * 4].min.round
    end

    # changes variables for the frames
    @move_count += 1
    @anime_count += 1.5 if @walk_anime
    #puts "= Post Move =\n[#{self.x},#{self.y}] Real: [#{@real_x},#{@real_y}]" if self.is_a?(Game_Player)
  end
  #-----------------------------------------------------------------------------
  # Loop Map Teleport when Event reached the border, etc.
  #-----------------------------------------------------------------------------
  def update_loop_map
    
    # returns if map isnt looped
    return unless MapConfig.looping?($game_map)

    l_update = false
        
    # teleports at the border
    if @x > $game_map.width * Game_Map::TILE_SIZE
      @x -= $game_map.width * Game_Map::TILE_SIZE
      @real_x -= $game_map.width * Game_Map::REAL_FACTOR
      self.char_sprite.loop_x_add = 0
      l_update = true

    elsif @x < 0
      @x += $game_map.width * Game_Map::TILE_SIZE
      @real_x += $game_map.width * Game_Map::REAL_FACTOR
      self.char_sprite.loop_x_add = 0
      l_update = true
    end
    
    if @y > $game_map.height * Game_Map::TILE_SIZE
      @y -= $game_map.height * Game_Map::TILE_SIZE
      @real_y -= $game_map.height * Game_Map::REAL_FACTOR
      self.char_sprite.loop_y_add = 0
      l_update = true

    elsif @y < 0
      @y += $game_map.height * Game_Map::TILE_SIZE
      @real_y += $game_map.height * Game_Map::REAL_FACTOR
      self.char_sprite.loop_y_add = 0
      l_update = true
    end
    
    self.char_sprite.update if l_update && self.char_sprite != nil
    return l_update
      
  end
  #--------------------------------------------------------------------------
  # * Frame Update (stop)
  #--------------------------------------------------------------------------
  def update_stop
    @move_count = 0
    # If stop animation is ON
    if @step_anime
      # Increase animation count by 1
      @anime_count += 1
    # If stop animation is OFF, but current pattern is different from original
    elsif @pattern != @original_pattern
      # Increase animation count by 1.5
      @anime_count += 1.5
    end
    # When waiting for event execution, or not locked
    # (Locking means the event has been interacted with, and stops moving?)
    unless @starting || lock?
      # Increase stop count by 1
      @stop_count += 1
    end
    @anime_count += 0.5 if @step_anime # ???
  end
  #-----------------------------------------------------------------------------
  # * Change speed based on heightmap
  #-----------------------------------------------------------------------------
  def move_speed_change
    return if $game_map.height_map == nil && $game_map.swamp_map == nil
    
    @move_speed /= @speed_factor
    @speed_factor = 1.0 # changing factor
    
    #---------------------------------------------------------------------------
    # checks height-map
    #---------------------------------------------------------------------------
    if $game_map.height_map != nil
      
      # loads x, y coordinates
      x = @x
      y = @y
      new_x = x + get_xy_dir_value(:x, @direction, 2)
      new_y = y + get_xy_dir_value(:y, @direction, 2)
                  
      # if new position is on the map
      if $game_map.valid?(new_x, new_y)
      
        # loads z coordinates
        z = $game_map.height_table[x - 1, y - 1]
        if z == 0
          z = $game_map.height_map.get_pixel(x, y).red 
          $game_map.height_table[x - 1, y - 1] = z
        end
        new_z = $game_map.height_table[new_x - 1, new_y - 1]
        if new_z == 0
          new_z = $game_map.height_map.get_pixel(new_x, new_y).red 
          $game_map.height_table[new_x - 1, new_y - 1] = new_z
        end 
              
        # changes factor
        @speed_factor *= 1 + ((z-new_z) / @move_speed) if z != nil && new_z != nil
      end
    end
                                
    #---------------------------------------------------------------------------
    # checks swamp-map
    #---------------------------------------------------------------------------
    if $game_map.swamp_map != nil
      
      # loads coordinates
      x = @x
      y = @y - 1
      
      # loads swamp pixel
      px = $game_map.swamp_table[x, y]
      if px == 0
        px = $game_map.swamp_map.get_pixel(x, y).red
        $game_map.swamp_table[x, y] = px
      elsif px == nil
        px = 255.0
      end
      @speed_factor *= px / 255.0
    
    end
    
    # changes speed
    @speed_factor = [[0.1, (@speed_factor * 1000).round / 1000.0].max, 2.0].min
    @move_speed *= @speed_factor
    
  end
  #--------------------------------------------------------------------------
  # * Move Type : Random
  #--------------------------------------------------------------------------
  def move_type_random
    # Branch by random numbers 0-5
    case rand(6)
    when 0..3  # Random
      move_random
    when 4  # 1 step forward
      move_forward
    when 5  # Temporary stop
      @stop_count = 0
    end
  end
  #--------------------------------------------------------------------------
  # * Move Type : Approach
  #--------------------------------------------------------------------------
  def move_type_toward_player
    # Get difference in player coordinates
    sx = @x - $game_player.x
    sy = @y - $game_player.y
    # Get absolute value of difference
    abs_sx = sx > 0 ? sx : -sx
    abs_sy = sy > 0 ? sy : -sy
    # If separated by 20 or more tiles matching up horizontally and vertically
    if sx + sy >= 20
      # Random
      move_random
      return
    end
    # Branch by random numbers 0-5
    case rand(6)
    when 0..3  # Approach player
      move_toward_player
    when 4  # random
      move_random
    when 5  # 1 step forward
      move_forward
    end
  end
  #--------------------------------------------------------------------------
  # * Move Type : Custom
  #--------------------------------------------------------------------------
  def move_type_custom
    # Exit if already moving or jumping
    return if jumping? || moving?
    # Loop until finally arriving at move command list
    while @move_route_index < @move_route.list.size
      # Acquire move command
      command = @move_route.list[@move_route_index]
      # If command code is 0 (end of list)
      if command.code == 0
        # If [repeat action] option is ON, reset index
        @move_route_index = 0 if @move_route.repeat
        # If [repeat action] option is OFF
        unless @move_route.repeat
          # If a move route is forcing
          if @move_route_forcing && !@move_route.repeat
            # Release forced move route
            @move_route_forcing = false
            # Restore original move route
            @move_route = @original_move_route
            @move_route_index = @original_move_route_index
            @original_move_route = nil
            # Begin pathfinding
            if @pathfinding.active
              @pathfinding.active = false
              self.turn_toward_coords(@pathfinding.target_x, @pathfinding.target_y)
            end
          end
          # Clear stop count
          @stop_count = 0
        end
        # Exit
        return
      end
      # During move command (from move down to jump)
      if command.code <= 14
        # Adjust editor 1 tile to 32 pixels
        command.parameters[0] = Game_Map::TILE_SIZE if command.parameters[0] == nil
        # Branch by code
        # Pass move amount and enable turning
        case command.code
        when 1
          move_down(command.parameters[0], true, command.parameters[1])
        when 2
          move_left(command.parameters[0], true, command.parameters[1])
        when 3
          move_right(command.parameters[0], true, command.parameters[1])
        when 4
          move_up(command.parameters[0], true, command.parameters[1])
        when 5
          move_lower_left(command.parameters[0], true)
        when 6
          move_lower_right(command.parameters[0], true)
        when 7
          move_upper_left(command.parameters[0], true)
        when 8
          move_upper_right(command.parameters[0], true)
        when 9
          move_random(command.parameters[0], true)
        when 10
          move_toward_player(command.parameters[0])
        when 11
          move_away_from_player(command.parameters[0])
        when 12
          move_forward(command.parameters[0])
        when 13
          move_backward(command.parameters[0])
        when 14
          jump(command.parameters[0] * Game_Map::TILE_SIZE, command.parameters[1] * Game_Map::TILE_SIZE)
        end
        # FIXME Oh lord give me strength what the fuck is this
        if @max_steps != 0 && @max_steps != command.parameters[0] && command.code != 14
          puts "Checking steps"
          length = @move_route.list.length - 1
          if @move_route_index - 1 < 0
            part1 = []
          else
            part1 = @move_route.list[0..@move_route_index - 1]
          end
          part2 = @move_route.list[@move_route_index + 1..length]
          partnew1 = command.clone
          partnew2 = command.clone
          partnew2.parameters = [partnew2.parameters[0] - @max_steps]
          partnew1.parameters = [@max_steps]
          @move_route.list = part1 + [partnew1, partnew2] + part2
        elsif !@move_route.skippable && !moving? && !jumping?
          # Not advancing index?
          puts "No advance"
          return
        end
        # Advance index
        @move_route_index += 1
        return
      end
      # If waiting
      if command.code == 15
        # Set wait count
        @wait_count = (command.parameters[0] * 2) - 1
        @move_route_index += 1
        return
      end
      # If direction change command
      if command.code >= 16 and command.code <= 26
        # Branch by command code
        case command.code
        when 16  # Turn down
          turn_down
        when 17  # Turn left
          turn_left
        when 18  # Turn right
          turn_right
        when 19  # Turn up
          turn_up
        when 20  # Turn 90° right
          turn_right_90
        when 21  # Turn 90° left
          turn_left_90
        when 22  # Turn 180°
          turn_180
        when 23  # Turn 90° right or left
          turn_right_or_left_90
        when 24  # Turn at Random
          turn_random
        when 25  # Turn toward player
          turn_toward_player
        when 26  # Turn away from player
          turn_away_from_player
        end
        @move_route_index += 1
        return
      end
      # If other command
      if command.code >= 27
        # Branch by command code
        case command.code
        when 27  # Switch ON
          $game_switches[command.parameters[0]] = true
          $game_map.need_refresh = true
        when 28  # Switch OFF
          $game_switches[command.parameters[0]] = false
          $game_map.need_refresh = true
        when 29  # Change speed
          @move_speed = command.parameters[0]
        when 30  # Change freq
          @move_frequency = command.parameters[0]
        when 31  # Move animation ON
          @walk_anime = true
        when 32  # Move animation OFF
          @walk_anime = false
        when 33  # Stop animation ON
          @step_anime = true
        when 34  # Stop animation OFF
          @step_anime = false
        when 35  # Direction fix ON
          @direction_fix = true
        when 36  # Direction fix OFF
          @direction_fix = false
        when 37  # Through ON
          @through = true
        when 38  # Through OFF
          @through = false
        when 39  # Always on top ON
          @always_on_top = true
        when 40  # Always on top OFF
          @always_on_top = false
        when 41  # Change Graphic
          @tile_id = 0
          @character_name = command.parameters[0]
          @character_hue = command.parameters[1]
          if @original_direction != command.parameters[2]
            @direction = command.parameters[2]
            @original_direction = @direction
            @prelock_direction = 0
          end
          if @original_pattern != command.parameters[3]
            @pattern = command.parameters[3]
            @original_pattern = @pattern
          end
        when 42  # Change Opacity
          @opacity = command.parameters[0]
        when 43  # Change Blending
          @blend_type = command.parameters[0]
        when 44  # Play SE
          $game_system.se_play(command.parameters[0])
        when 45  # Script
          result = eval(command.parameters[0])
        #--------------------------------------------------------------------------
        # CUSTOM COMMAND CODES (not in editor)
        when 46 # Change graphic frame
          if @original_pattern != command.parameters[0]
            @pattern = command.parameters[0]
            @original_pattern = @pattern
          end
        when 47 # Set direction
          if @original_direction != command.parameters[0]
            @direction = command.parameters[0]
            @original_direction = @direction
            @prelock_direction = 0
          end
        when 48 # Jump to coordinates
          jump_to(command.parameters[0], command.parameters[1], command.parameters[2])
        end
        @move_route_index += 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Increase Steps
  #--------------------------------------------------------------------------
  def increase_steps
    # Clear stop count
    @stop_count = 0
  end
end
