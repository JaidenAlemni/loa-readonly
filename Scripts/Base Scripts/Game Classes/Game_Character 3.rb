#==============================================================================
# ** Game_Character (part 3) (Movement Methods)
#------------------------------------------------------------------------------
#  This class deals with characters. It's used as a superclass for the
#  Game_Player and Game_Event classes.
#==============================================================================

class Game_Character
  # Map directions to move directions (catch 0 and 5)
  DIRECTION_TO_SYM = [:move_down, :move_lower_left, :move_down, 
                      :move_lower_right, :move_left, :move_down,
                      :move_right, :move_upper_left, :move_up, :move_upper_right
                     ]
  #-----------------------------------------------------------------------------
  # * Convert direction integer to symbol
  #-----------------------------------------------------------------------------
  def move_custom(direction, steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.send(DIRECTION_TO_SYM[direction], steps, turn_enabled, full_move)
  end
  #-----------------------------------------------------------------------------
  # * Move Down
  #     turn_enabled : a flag permits direction change on that spot
  #     full_move    : if @max_steps != steps passed, don't move
  #-----------------------------------------------------------------------------
  def move_down(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_down if turn_enabled
    # passable?
    if passable?(@x, @y, 2, steps)
      @y += @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @y += @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Left
  #     turn_enabled : a flag permits direction change on that spot
  #--------------------------------------------------------------------------
  def move_left(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_left if turn_enabled
    # passable?
    if passable?(@x, @y, 4, steps)
      @x -= @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x -= @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Right
  #     turn_enabled : a flag permits direction change on that spot
  #--------------------------------------------------------------------------
  def move_right(steps=Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_right if turn_enabled
    # passable?
    if passable?(@x, @y, 6, steps)
      @x += @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x += @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move up
  #     turn_enabled : a flag permits direction change on that spot
  #--------------------------------------------------------------------------
  def move_up(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_up if turn_enabled
    # passable?
    if passable?(@x, @y, 8, steps)
      @y -= @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @y -= @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Lower Left
  #--------------------------------------------------------------------------
  def move_lower_left(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_lower_left if turn_enabled
    # passable?
    if passable?(@x, @y, 1, steps)
      @x -= @max_steps
      @y += @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x -= @max_steps
        @y += @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Lower Right
  #--------------------------------------------------------------------------
  def move_lower_right(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_lower_right if turn_enabled
    # passable?
    if passable?(@x, @y, 3, steps)
      @x += @max_steps
      @y += @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x += @max_steps
        @y += @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Upper Left
  #--------------------------------------------------------------------------
  def move_upper_left(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true)
    self.turn_upper_left if turn_enabled
    # passable?
    if passable?(@x, @y, 7, steps)
      @x -= @max_steps
      @y -= @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x -= @max_steps
        @y -= @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Upper Right
  #--------------------------------------------------------------------------
  def move_upper_right(steps = Game_Map::TILE_SIZE, turn_enabled = true, full_move = true) 
    self.turn_upper_right if turn_enabled
    # passable?
    if passable?(@x, @y, 9, steps)
      @x += @max_steps
      @y -= @max_steps
      increase_steps
    else
      # not permitted to move a partial amount
      if full_move
        @max_steps = 0
        return
      end
      # not passable but the character can walk (@maxsteps > 0)
      if (@max_steps > 0 && @max_steps < steps)
        @x += @max_steps
        @y -= @max_steps
        increase_steps
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move at Random
  # steps = (rand(9) + 8) * 2
  #--------------------------------------------------------------------------
  def move_random(steps = Game_Map::TILE_SIZE, turn_enabled = true)
        
    # for different movement types
    add = 0
    case PixelMove::MOVEMENT_TYPE
    when :dir8
      number = 12
    when :dir4
      number = 8
    when :dir4diag
      number = 4
      add = 8
    when :dir8diag
      number = 12
    end
    
    case rand(number) + add
    when 0..1
      move_down(steps, turn_enabled)
    when 2..3
      move_left(steps, turn_enabled)
    when 4..5
      move_right(steps, turn_enabled)
    when 6..7
      move_up(steps, turn_enabled)
    when 8
      move_lower_left(steps, turn_enabled)
    when 9
      move_lower_right(steps, turn_enabled)
    when 10
      move_upper_left(steps, turn_enabled)
    when 11
      move_upper_right(steps, turn_enabled)
    end
  end
  #-----------------------------------------------------------------------------
  # * New Move Toward Player (more pixellike)
  # Moves the towards the player only if they're within 20 tiles
  #-----------------------------------------------------------------------------
  def move_type_toward_player
    sx_abs = (@x - $game_player.x).abs
    sy_abs = (@y - $game_player.y).abs
    if sx_abs + sy_abs  >= Game_Map::TILE_SIZE * 20
      move_random(Game_Map::TILE_SIZE)
    elsif sx_abs > 0 || sy_abs > 0
      move_toward_player(Game_Map::TILE_SIZE)
    end
  end
  #-----------------------------------------------------------------------------
  # move_toward_event, more pixellike
  #-----------------------------------------------------------------------------
  def move_toward_event(id, steps = Game_Map::TILE_SIZE)
    # For some unknown reason, this was originally written to fail 1/6
    # of the time. I am putting this note in case I find out why -jaiden
    self.turn_toward_event(id, false)
    self.move_forward(steps)
  end
  #-----------------------------------------------------------------------------
  # move_toward_player, more pixellike
  #-----------------------------------------------------------------------------
  def move_toward_player(steps = Game_Map::TILE_SIZE)
    # Player is always event id 0
    self.move_toward_event(0, steps)
  end
  #-----------------------------------------------------------------------------
  # move_away_from_event, more pixellike
  #-----------------------------------------------------------------------------
  def move_away_from_event(id, steps = Game_Map::TILE_SIZE)
    self.turn_away_from_event(id, false)
    self.move_forward(steps)
  end
  #-----------------------------------------------------------------------------
  # move_away_from_player, more pixellike
  #-----------------------------------------------------------------------------
  def move_away_from_player(steps = Game_Map::TILE_SIZE)
    # Player is always event id 0
    self.move_away_from_event(0, steps)
  end
  #--------------------------------------------------------------------------
  # * Move toward Player (Vanilla code, saved for later reference)
  #--------------------------------------------------------------------------
  # def move_toward_player
  #   # Get difference in player coordinates
  #   sx = @x - $game_player.x
  #   sy = @y - $game_player.y
  #   # If coordinates are equal
  #   if sx == 0 and sy == 0
  #     return
  #   end
  #   # Get absolute value of difference
  #   abs_sx = sx.abs
  #   abs_sy = sy.abs
  #   # If horizontal and vertical distances are equal
  #   if abs_sx == abs_sy
  #     # Increase one of them randomly by 1
  #     rand(2) == 0 ? abs_sx += 1 : abs_sy += 1
  #   end
  #   # If horizontal distance is longer
  #   if abs_sx > abs_sy
  #     # Move towards player, prioritize left and right directions
  #     sx > 0 ? move_left : move_right
  #     if not moving? and sy != 0
  #       sy > 0 ? move_up : move_down
  #     end
  #   # If vertical distance is longer
  #   else
  #     # Move towards player, prioritize up and down directions
  #     sy > 0 ? move_up : move_down
  #     if not moving? and sx != 0
  #       sx > 0 ? move_left : move_right
  #     end
  #   end
  # end
  #--------------------------------------------------------------------------
  # * Move Forward
  # steps - pixels
  #--------------------------------------------------------------------------
  def move_forward(steps = Game_Map::TILE_SIZE)
    case @direction
    when 1
      move_lower_left(steps, false)
    when 2
      move_down(steps, false)
    when 3
      move_lower_right(steps, false)
    when 4
      move_left(steps, false)
    when 6
      move_right(steps, false)
    when 7
      move_upper_left(steps, false)
    when 8
      move_up(steps, false)
    when 9
      move_upper_right(steps, false)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Backward
  #--------------------------------------------------------------------------
  def move_backward(steps =Game_Map::TILE_SIZE)
    # Remember direction fix situation
    last_direction_fix = @direction_fix
    # Force directino fix
    @direction_fix = true
    # FIXME (or don't). This is a monkey patch for fixing characters not 
    # animating when stepping backwards. For some reason, when an event starts
    # It temporarily locks in place. Dunno if it's intentional, but this fixes
    # the animation bug.
    @stop_count = 0
    # Branch by direction
    case @direction
    when 1
      move_upper_right(steps, false)
    when 2
      move_up(steps, false)
    when 3
      move_upper_left(steps, false)
    when 4
      move_right(steps, false)
    when 6
      move_left(steps, false)
    when 7
      move_lower_right(steps, false)
    when 8
      move_down(steps, false)
    when 9
      move_lower_left(steps, false)
    end
    # Return direction fix situation back to normal
    @direction_fix = last_direction_fix
  end
  #-----------------------------------------------------------------------------
  #  * Move straight to the coordinates x, y
  #-----------------------------------------------------------------------------
  def move_to_place(x, y, turn = true)
    self.turn_toward_coords(x, y) if turn
    self.x = x
    self.y = y
    increase_steps
  end
  #-----------------------------------------------------------------------------
  #  * Move straight to the coordinates x, y
  #-----------------------------------------------------------------------------
  def move_to_tile(x, y, turn = true)
    self.turn_toward_coords(x, y) if turn
    self.x = x * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE / 2
    self.y = y * Game_Map::TILE_SIZE
    increase_steps
  end
  #-----------------------------------------------------------------------------
  #  * Move straight to the coordinates of the specified event id
  #-----------------------------------------------------------------------------
  def move_to_event(id, turn = true)
    event = (id == 0) ? $game_player : $game_map.events[id]
    x = event.x
    y = event.y
    self.turn_toward_coords(x, y) if turn
    self.x = x
    self.y = y
    increase_steps
  end
  #-----------------------------------------------------------------------------
  # Jumps to coordiantes x, y
  #-----------------------------------------------------------------------------
  def jump_to(new_x, new_y, height = 5)
    x_plus = new_x - self.x
    y_plus = new_y - self.y
    jump(x_plus, y_plus, height)
  end
  #--------------------------------------------------------------------------
  # * Jump
  #     x_plus : x-coordinate plus value
  #     y_plus : y-coordinate plus value
  #     height : jump height
  #--------------------------------------------------------------------------
  def jump(x_plus, y_plus, height = 5)
    new_x = @x + x_plus
    new_y = @y + y_plus
    # TODO This is gross but it currently works
    if (x_plus == 0 && y_plus == 0) || @through || $game_map.passable?(new_x, new_y, self)
      self.turn_toward_coords(new_x, new_y) if x_plus != 0 || y_plus != 0
      #self.straighten
      self.x = new_x
      self.y = new_y
      height_2 = 100 / height 
      x_plus /= height_2
      y_plus /= height_2
      distance = [x_plus.abs,y_plus.abs].max
      @jump_peak = 10 + distance - @move_speed.round
      @jump_count = @jump_peak * 2
      @stop_count = 0
    end
  end
  # Vanilla method, for reference
  #--------------------------------------------------------------------------
  # def jump(x_plus, y_plus)
  #   # If plus value is not (0,0)
  #   if x_plus != 0 or y_plus != 0
  #     # If horizontal distnace is longer
  #     if x_plus.abs > y_plus.abs
  #       # Change direction to left or right
  #       x_plus < 0 ? turn_left : turn_right
  #     # If vertical distance is longer, or equal
  #     else
  #       # Change direction to up or down
  #       y_plus < 0 ? turn_up : turn_down
  #     end
  #   end
  #   # Calculate new coordinates
  #   new_x = @x + x_plus
  #   new_y = @y + y_plus
  #   # If plus value is (0,0) or jump destination is passable
  #   if (x_plus == 0 and y_plus == 0) or passable?(new_x, new_y, 0)
  #     # Straighten position
  #     straighten
  #     # Update coordinates
  #     @x = new_x
  #     @y = new_y
  #     # Calculate distance
  #     distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
  #     # Set jump count
  #     @jump_peak = 10 + distance - @move_speed
  #     @jump_count = @jump_peak * 2
  #     # Clear stop count
  #     @stop_count = 0
  #   end
  # end
  #--------------------------------------------------------------------------
  # * Turn Down
  #--------------------------------------------------------------------------
  def turn_down(step_by_step = true)
    return if @direction_fix
    @direction = 2
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #--------------------------------------------------------------------------
  # * Turn Left
  #--------------------------------------------------------------------------
  def turn_left(step_by_step = true)
    return if @direction_fix
    @direction = 4
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #--------------------------------------------------------------------------
  # * Turn Right
  #--------------------------------------------------------------------------
  def turn_right(step_by_step = true)
    return if @direction_fix
    @direction = 6
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #--------------------------------------------------------------------------
  # * Turn Up
  #--------------------------------------------------------------------------
  def turn_up(step_by_step = true)
    return if @direction_fix
    @direction = 8
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #-----------------------------------------------------------------------------
  # turn_lower_left
  #-----------------------------------------------------------------------------
  def turn_lower_left(step_by_step = true)
    return if @direction_fix
    @direction = 1
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #-----------------------------------------------------------------------------
  # turn_lower_right
  #-----------------------------------------------------------------------------
  def turn_lower_right(step_by_step = true)
    return if @direction_fix
    @direction = 3
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #-----------------------------------------------------------------------------
  # turn_upper_left
  #-----------------------------------------------------------------------------
  def turn_upper_left(step_by_step = true)
    return if @direction_fix
    @direction = 7
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #-----------------------------------------------------------------------------
  # turn_upper_right
  #-----------------------------------------------------------------------------
  def turn_upper_right(step_by_step = true)
    return if @direction_fix
    @direction = 9
    @stop_count = 0
    if step_by_step
      self.update_turn_step_by_step
    else
      @old_direction = @direction
    end
  end
  #--------------------------------------------------------------------------
  # * Turn 90° Right
  #--------------------------------------------------------------------------
  def turn_right_90(step_by_step = true)    
    case @direction
    when 1
      turn_upper_left(step_by_step)
    when 3
      turn_lower_left(step_by_step)
    when 7
      turn_upper_right(step_by_step)
    when 9
      turn_lower_right(step_by_step)
    when 2
      turn_left(step_by_step)
    when 4
      turn_up(step_by_step)
    when 6
      turn_down(step_by_step)
    when 8
      turn_right(step_by_step)
    end
  end
  #--------------------------------------------------------------------------
  # * Turn 90° Left
  #--------------------------------------------------------------------------
  def turn_left_90(step_by_step = true)    
    case @direction
    when 1
      turn_lower_right(step_by_step)
    when 3
      turn_upper_right(step_by_step)
    when 7
      turn_lower_left(step_by_step)
    when 9
      turn_upper_left(step_by_step)
    when 2
      turn_right(step_by_step)
    when 4
      turn_down(step_by_step)
    when 6
      turn_up(step_by_step)
    when 8
      turn_left(step_by_step)
    end
  end
  #--------------------------------------------------------------------------
  # * Turn 180°
  #--------------------------------------------------------------------------
  def turn_180(step_by_step = true)
    case @direction
    when 1
      turn_upper_right(step_by_step)
    when 3
      turn_upper_left(step_by_step)
    when 7
      turn_lower_right(step_by_step)
    when 9
      turn_lower_left(step_by_step)
    when 2
      turn_up(step_by_step)
    when 4
      turn_right(step_by_step)
    when 6
      turn_left(step_by_step)
    when 8
      turn_down(step_by_step)
    end
  end
  #--------------------------------------------------------------------------
  # * Turn 90° Right or Left
  #--------------------------------------------------------------------------
  def turn_right_or_left_90(step_by_step = true)
    if rand(2) == 0
      turn_right_90(step_by_step)
    else
      turn_left_90(step_by_step)
    end
  end
  #--------------------------------------------------------------------------
  # * Turn at Random
  #--------------------------------------------------------------------------
  def turn_random(step_by_step = true)
    # for different movement types
    add = 0
    case PixelMove::MOVEMENT_TYPE
    when :dir8
      number = 12
    when :dir4
      number = 8
    when :dir4diag
      number = 4
      add = 8
    when :dir8diag
      number = 12
    end
    
    case rand(number) + add
    when 0..1
      turn_up(step_by_step)
    when 2..3
      turn_right(step_by_step)
    when 4..5
      turn_left(step_by_step)
    when 6..7
      turn_down(step_by_step)
    when 8
      turn_upper_right(step_by_step)
    when 9
      turn_upper_left(step_by_step)
    when 10
      turn_lower_right(step_by_step)
    when 11
      turn_lower_left(step_by_step)
    end
  end
  #-----------------------------------------------------------------------------
  # Turn toward coordinates x, y
  #-----------------------------------------------------------------------------
  def turn_toward_coords(x, y, step_by_step = true)
    # Get coordinate difference
    sx = x - @x
    sy = y - @y
    return if sx == 0 && sy == 0
    
    case PixelMove::MOVEMENT_TYPE
    when :dir8, :dir8diag
      if sx.abs > sy.abs * 2
        sx > 0 ? turn_right(step_by_step) : turn_left(step_by_step)
      elsif sy.abs > sx.abs * 2
        sy > 0 ? turn_down(step_by_step) : turn_up(step_by_step)
      else
        if sy > 0
          sx>0 ? turn_lower_right(step_by_step) : turn_lower_left(step_by_step) 
        else
          sx>0 ? turn_upper_right(step_by_step) : turn_upper_left(step_by_step)
        end
      end
    when :dir4
      if sx.abs > sy.abs
        sx > 0 ? turn_right(step_by_step) : turn_left(step_by_step)
      elsif sy.abs > sx.abs
        sy > 0 ? turn_down(step_by_step) : turn_up(step_by_step)
      end
    when :dir4diag
      if sy > 0
        sx > 0 ? turn_lower_right(step_by_step) : turn_lower_left(step_by_step)
      else
        sx > 0 ? turn_upper_right(step_by_step) : turn_upper_left(step_by_step)
      end
    end
  end
  #-----------------------------------------------------------------------------
  # turn_toward_event, for 8 directions
  #-----------------------------------------------------------------------------
  def turn_toward_event(id, step_by_step = true)
    event = (id == 0) ? $game_player : $game_map.events[id]
    self.turn_toward_coords(event.x, event.y, step_by_step)
  end
  #-----------------------------------------------------------------------------
  # turn_away_from_event, for 8 directions
  #-----------------------------------------------------------------------------
  def turn_away_from_event(id, step_by_step = true)
    self.turn_toward_event(id, false)
    self.turn_180(step_by_step)
  end
  #--------------------------------------------------------------------------
  # * Turn Towards Player
  #--------------------------------------------------------------------------
  def turn_toward_player(step_by_step = true)
    self.turn_toward_event(0, step_by_step)
  end
  #--------------------------------------------------------------------------
  # * Turn Away from Player
  #--------------------------------------------------------------------------
  def turn_away_from_player(step_by_step = true)
    self.turn_toward_event(0, false)
    self.turn_180(step_by_step)
  end
  #-----------------------------------------------------------------------------
  # * Stay in Range
  # self stays in the given range of the event with id as its id, 0 means 
  # game_player
  #-----------------------------------------------------------------------------
  def stay_in_range(id, d1 = 0, d2 = 640)
    if self.distance_to_event(id) < d1
      self.move_away_from_event(id)
    elsif self.distance_to_event(id) > d2
      self.move_toward_event(id)
    end
  end
  #-----------------------------------------------------------------------------
  # Pathfinding to a Place / Coords
  #-----------------------------------------------------------------------------
  def find_path(target_x, target_y, radius = 0, walk = true)
    if $game_map.valid?(target_x, target_y) && $game_map.passable?(target_x, target_y, 0, self)
      @pathfinding.find_path(target_x, target_y, walk, radius)
    end
  end
  #-----------------------------------------------------------------------------
  # Pathfinding to an Event
  #-----------------------------------------------------------------------------
  def find_event(id, radius = 0, walk = true)
    target = (id == 0) ? $game_player : $game_map.events[id]
    if target.through
      @pathfinding.find_path(target.x, target.y, walk, radius)
    else
      radius = (radius >= @size.values.max + 4 ? radius : @size.values.max + 4)
      @pathfinding.find_path(target.x, target.y, walk, radius)
    end
  end
  #-----------------------------------------------------------------------------
  # Returns true if self reached the target
  #-----------------------------------------------------------------------------
  def reached_target?
    return (!@pathfinding.active)
  end
  #--------------------------------------------------------------------------
  # * Reset sprite (useful for gremlin chasing)
  #--------------------------------------------------------------------------
  def sprite_reset
    @anime_count = 0
    @stop_count = 0
    @jump_count = 0
    @jump_start_count = 0
    @jump_end_count = 0
    @jump_peak = 0
    @wait_count = 0
    @force_redraw = true
  end
  #--------------------------------------------------------------------------
  # * Stop Move Route (by KK20)
  #--------------------------------------------------------------------------
  def stop_move_route
    # Release forced move route
    @move_route_forcing = false
    # Restore original move route
    @move_route = @original_move_route
    @move_route_index = @original_move_route_index - 1
    @original_move_route = nil
    # Clear stop count
    @stop_count = 0
  end
  #----------------------------------------------------------------------------
  # * Movement continues (MMW)
  #----------------------------------------------------------------------------
  # Call from Event Editor => Scripts 
  # DO NOT call from Set Move Route => Scripts
  def event_move_continue(event_id, valid = false, alt = false)
    # return if Event has a No 'M'ove 'C'ontinue flag
    return if @no_mc
    # Restore Original Move Route if Event went off the screen while talking
    # This may be buggy if multiple event pages are used
    if @ff_original_move_route != nil and valid
      # Release forced move route
      @move_route_forcing = false
      # Restore original values        
      @move_speed = @ff_original_move_speed
      @move_frequency = @ff_original_move_frequency
      @move_route = @ff_original_move_route
      @move_route_index = @ff_original_move_route_index 
      # Release storing variables
      @ff_original_move_index = nil
      @ff_original_move_speed = nil
      @ff_original_move_frequency = nil
      @ff_original_move_route = nil
      @original_move_route = nil
      @original_move_route_index = nil
    elsif @original_move_route != nil and valid and alt
      # Release forced move route
      @move_route_forcing = false      
      @move_route = @original_move_route
      @move_route_index = @original_move_route_index
      @original_move_route = nil
      @original_move_route_index = nil      
    end
  end
  #----------------------------------------------------------------------------
  # * Allows Animation Change regardless of Direction (MMW)
  #----------------------------------------------------------------------------
  def foot_forward_on(frame = 0)
    return if @direction_fix or !@walk_anime or @step_anime or 
              $game_temp.in_battle
    if frame == 0
      case @direction
      when 2
        @pattern = 3
      when 4, 6, 8
        @pattern = 1
      else
        @pattern = 0
      end
      @original_pattern = @pattern
    elsif frame == 1
      case @direction
      when 2
        @pattern = 1
        when 4, 6, 8
        @pattern = 3
      else
        @pattern = 0
      end
      @original_pattern = @pattern
    end
  end
  #----------------------------------------------------------------------------
  # * FF Off
  #----------------------------------------------------------------------------
  def foot_forward_off
    # If called by walking off screen, dont affect a Sign or Stepping Actor
    return if $game_temp.in_battle or @direction_fix or !@walk_anime or @no_ff
    @pattern, @original_pattern = 0, 0
  end
  #--------------------------------------------------------------------------
  # * Set Self Switch(ch, value, id, map_id) - Game_Character
  #       ch     : A, B, C, or D
  #       value  : true, false, 'On', 'Off', 1, or 0
  #       id     : Event ID
  #       map_id : (Optional) Current or Specified Map ID
  #
  #   - Change a Self Switch from a Move Route Event
  #--------------------------------------------------------------------------  
  def set_self_switch(ch, value, id = @id, map_id = $game_map.map_id)
    # if Player Move Route and id is not Specified
    if id == 0 and $DEBUG
      # Print Error
      print "When using set_self_switch from Player Move Route, you need to\n",
            "specify an Event ID because the Game Player does not\n",
            "have any Self Switches"
    end
    # Valid Values
    value_valid = [true, false, 0, 1, 'on','off']
    if value.is_a?(String)
      value = true if value.to_s.downcase == 'on'
      value = false if value.to_s.downcase == 'off'
    elsif value.is_a?(Integer)
      value = true if value == 1
      value = false if value == 0
    end
    # If we have A, B, C, or D, and the Event exists    
    if ch.is_a?(String) and "ABCD".include?(ch.upcase) and 
       (value == true or value == false) and  
       (map_id != $game_map.map_id or $game_map.events[id])
      # If event ID is valid
      if @id > 0
        # Make Upper Case for Key
        ch = ch.to_s.upcase
        # Make a self switch key
        key = [map_id, id, ch]
        # Change self switches
        $game_self_switches[key] = value
      end
      # Refresh map
      $game_map.need_refresh = true
      # Continue
      return true
    else
      if $DEBUG
        print "Warning: set_self_switch expects Two Arguments\n",
              "The First Argument should be the letter A, B, C, or D\n",
              "The Second Argument should be either True or False.\n",
              "(On or Off is acceptable too.  Just need you",
              "to say what you want to set it to.)\n\n",
              "Example: set_self_switch('A',true)\n\n",
              "Example 2: set_self_switch('A','On')\n\n",
              "There is an Optional 3rd Argument for",
              "specifying an Event ID\n\n",
              "Example 2: set_self_switch('B',false, 32)\n\n",
              "This Script call to get_self_switch was made\n",
              "from MOVE ROUTE => SCRIPT\n\n",
              "set_self_switch in MOVE ROUTES => SCRIPT expect TWO Arguments,",
              "THIRD Optional\n",
              "set_self_switch in EVENT => SCRIPT expects THREE Arguments\n\n",
              "Your Script: Move Route -> Script set_self_switch",
              "('",ch,"','",value,"','",id,"')"
        # If on the Same Map and Event doesn't exist, explain the Problem
        if map_id == $game_map.map_id and not $game_map.events[id]
          print "The Event ID: ", id, " you specified\n",
                "doesn't exist on this map"
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Get Self Switch(ch, id) - Game_Character
  #       ch     : A, B, C, or D
  #       id     : Event ID
  #       map_id : (Optional) Current or Specified Map ID  
  #
  #   - Returns True if a Switch is ON, False if Switch is OFF
  #   - This is usually only good with Ternary Operator but I included it anyway
  #     Example:  @direction = (get_self_switch('A',15) ? 8 : 2
  #--------------------------------------------------------------------------  
  def get_self_switch(ch, id = @id, map_id = $game_map.map_id)
    # if Player Move Route and id is not Specified
    if id == 0 and $DEBUG
      # Print Error
      print "When using get_self_switch for Player Set Move Route,",
            "you need to\n",
            "specify an Event ID because the Game Player does not\n",
            "have any Self Switches\n\n",
            "Calling in Player with no ID argument causes\n",
            "the ID to be set to 0"
    end    
    # If we have A, B, C, or D, and the Event exists if same Map
    if ch.is_a?(String) and "ABCD".include?(ch.upcase) and 
       id and (map_id != $game_map.map_id or $game_map.events[id])
      # Make a Key
      key = [map_id, id, ch.upcase]
      return $game_self_switches[key]
    else
      if $DEBUG
        print "Warning: get_self_switch expects Two Arguments\n",
              "The First Argument should be the Letter of\n",
              " the Self Switch you are Checking, A, B, C, or D\n",        
              "The Second Argument should be the Event's ID\n",
              "Example: get_self_switch('B', 23)\n\n",
              "This Script call to get_self_switch was made\n",
              "from MOVE ROUTE => SCRIPT\n\n",
              "Your Script: Move Route -> Script get_self_switch",
              "('",ch,"','",id,"')"
        if map_id == $game_map.map_id and not $game_map.events[id]
          print "The Event ID: ", id, " you specified\n",
                "doesn't exist on this map"
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  # * Check block move
  # eval'd during a move route to see if the block actually changed coordinates
  #-----------------------------------------------------------------------------
  def check_block_move
    # Play SFX based on coord change
    if self.last_x != self.x || self.last_y != self.y
      $game_system.se_play(RPG::AudioFile.new(PushBlocks::PUSH_SFX, 80, 100))
    else
      $game_system.se_play(RPG::AudioFile.new(PushBlocks::STUCK_SFX, 50, 100))
    end
  end
end
