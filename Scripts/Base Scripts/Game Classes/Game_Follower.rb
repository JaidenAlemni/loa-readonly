#===============================================================================
# Class for the Caterpillar Characters
#===============================================================================
class Game_Follower < Game_Character
  attr_accessor :move_list
  attr_accessor :ice_sliding
     
  #-----------------------------------------------------------------------------
  # initialising method
  #-----------------------------------------------------------------------------
  def initialize(id)    
    super()

    self.moveto($game_player.x, $game_player.y)
    @through = true
    @id = id
    @move_list = []
    @move_speed = $game_player.move_speed
    @moving = false
    
    @character_name = $game_party.actors(:all)[id - 1].character_name if id > 1
    self.init_special_settings
                      
  end
  
  #---------------------------------------------------------------------------
  # checks if Pixel Setting is activated, adds every event consisting a 
  # "jump/ice-comment" to an array or for special frame rates, etc..
  #---------------------------------------------------------------------------
  def init_special_settings
    super

    if $pixelmovement.player_frame_order != nil
      @frame_order = $pixelmovement.player_frame_order 
    end
    if $pixelmovement.player_direction_order != nil
      @direction_order = $pixelmovement.player_direction_order 
    end
    if $pixelmovement.player_stand_frame_order != nil
      @stand_frame_order = $pixelmovement.player_stand_frame_order 
    end
    if $pixelmovement.player_shift_x != nil
      @shift_x = $pixelmovement.player_shift_x
    end
    if $pixelmovement.player_shift_y != nil
      @shift_y = $pixelmovement.player_shift_y
    end
    if $pixelmovement.player_frame_speed != nil
      @frame_speed = $pixelmovement.player_frame_speed
    end
    if $pixelmovement.player_stand_frame_speed != nil
      @stand_frame_speed = $pixelmovement.player_stand_frame_speed
    end
    
    if $pixelmovement.player_size != []
      @size_x = $pixelmovement.player_size[0]
      @size_y = $pixelmovement.player_size[1]
    elsif @character_name != ''
      name='Graphics/Characters/' + @character_name
      bitmap = Bitmap.new(name)
      bla = [bitmap.width / @frame_order.length / 4, 
             bitmap.height / @direction_order.length / 4].max + 
             $pixelmovement.event_size_add
      @size_x = bla
      @size_y = bla
    end
    
    @step_anime = true if @stand_frame_order.length > 1
  end

  #-----------------------------------------------------------------------------
  # passable method, caterpillars can always walk if the new position is on 
  # the map
  #-----------------------------------------------------------------------------
  def passable?(x, y, d,steps = Game_Map::TILE_SIZE)
    @max_steps = steps
    return true
  end
  
  #-----------------------------------------------------------------------------
  # update method
  #-----------------------------------------------------------------------------
  def update
    
    # no update if the game stops
    if $game_system.map_interpreter.running? || @move_route_forcing || $game_temp.message_window_showing
      return
    end
           
    # the "hero" caterpillar (invisible, just copies the moves of the player)
    if @id == 1      
      @move_speed = $game_player.move_speed
      @walk_anime = $game_player.walk_anime
      @jump_count = $game_player.jump_count
      @jump_peak = $game_player.jump_peak
      @ice_sliding = $game_player.ice_sliding

      x = $game_player.real_x / 4
      y = $game_player.real_y / 4
      self.loop_map(x, y)
      
      if @ice_sliding
        para = 1
      elsif @jump_count > 0
        para = 2
      else
        para = 0
      end

      if x != @x || y != @y
        @moving = true
        while x - @x != 0 || y - @y != 0
          dir = 0
          if x > @x
            @x += 1
            dir = 6
          elsif x < @x
            @x -= 1
            dir = 4
          end
          if y > @y
            @y += 1
            if dir == 6
              dir = 3
            elsif dir == 4
              dir = 1
            else
              dir = 2
            end
          elsif y < @y
            @y -= 1
            if dir == 6
              dir = 9
            elsif dir == 4
              dir = 7
            else
              dir = 8
            end
          end
          @move_list.push([dir, para, @move_speed])
        end
        self.moveto(x, y)
      else
        @moving = false
      end

    # normal caterpillars
    else
      super
      @pattern = @original_pattern if @ice_sliding # no frame change if sliding
      
      @ice_sliding = false
      actor = $game_map.game_followers[@id - 2]
      return if actor.move_list == []
      
      dir = actor.move_list.last[0]
      speed = actor.move_list.last[2]
      sizes = @size_x + actor.size_x + @size_y + actor.size_y
      dist = $pixelmovement.cater_distance + sizes / 4
      dist = (dist / Math.sqrt(2.0)).round if [1, 3, 7, 9].include?(dir)
      if @id == 2 && $pixelmovement.cater_overlap
        dist -= [(2 ** (speed - 1)).round, 1].max
      end
      
      self.increase_steps
      
      loop do      
        if actor.move_list == [] || (actor.jumping? && actor.jump_count > actor.jump_peak) || (self.jumping? && actor.move_list[0][1] != 2) || (actor.move_list.length < dist + 1 && (actor.moving? || actor.ice_sliding || !($pixelmovement.cater_overlap || self.jumping?)))
          if @move_list != []
            @move_speed = @move_list.last[2]
            @direction = @move_list.last[0]
          end
          break
        end
        case actor.move_list[0][0]
        when 1
          @x -= 1
          @y += 1
        when 2
          @y += 1
        when 3
          @x += 1
          @y += 1
        when 4
          @x -= 1
        when 6
          @x += 1
        when 7
          @x -= 1
          @y -= 1
        when 8
          @y -= 1
        when 9
          @x += 1
          @y -= 1
        end
        self.loop_map(actor.x, actor.y)
        if actor.move_list[0][1] == 1
          @ice_sliding = true
        else
          if actor.move_list[0][1] == 2 && !self.jumping?
            @jump_peak = actor.jump_peak
            @jump_count = @jump_peak * 2
          end
        end
        @move_list.push(actor.move_list[0])
        actor.move_list.shift
      end
    end
       
  end   
  
  #-----------------------------------------------------------------------------
  # Loop Map: Do nothing, see below
  #-----------------------------------------------------------------------------
  def update_loop_map
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Loop Map Teleport when Player reached the border
  #-----------------------------------------------------------------------------
  def loop_map(x, y)
    
    # returns if map isnt looped
    return unless MapConfig.looping?($game_map)

    #---------------------------------------------------------------------------
    # teleports when is at the border
    #---------------------------------------------------------------------------
    if (@x - x).abs > (@x + $game_map.width * Game_Map::TILE_SIZE - x).abs    
      @x = @x + $game_map.width * Game_Map::TILE_SIZE
      @real_x = @real_x + $game_map.width * Game_Map::TILE_SIZE * 4
      
    elsif (@x - x).abs > (@x - $game_map.width * Game_Map::TILE_SIZE - x).abs      
      @x = @x - $game_map.width * Game_Map::TILE_SIZE
      @real_x = @real_x - $game_map.width * Game_Map::TILE_SIZE * 4
    end
    
    if (@y - y).abs > (@y + $game_map.height * Game_Map::TILE_SIZE - y).abs      
      @y = @y + $game_map.height * Game_Map::TILE_SIZE
      @real_y = @real_y + $game_map.height * Game_Map::TILE_SIZE * 4
      
    elsif (@y - y).abs > (@y - $game_map.height * Game_Map::TILE_SIZE - y).abs      
      @y = @y - $game_map.height * Game_Map::TILE_SIZE
      @real_y = @real_y - $game_map.height * Game_Map::TILE_SIZE * 4
    end            
  end
  
  #-----------------------------------------------------------------------------
  # checks if the speed has to be changed because of the ground,
  # changed because the Caterpillar speed is only changed when the game player's
  # speed changes
  #-----------------------------------------------------------------------------
  def move_speed_change
    return
  end
  
  #-----------------------------------------------------------------------------
  # returns Sprite (ID) of the event
  #-----------------------------------------------------------------------------
  def char_sprite(id = false)
    return if !$scene.is_a?(Scene_Map)
    return (id ? @id - 1 : $scene.spriteset.game_followers_sprites[@id - 1])
  end
  
  #-----------------------------------------------------------------------------
  # returns if caterpillar moves; if id == 1, returns if player moves
  #-----------------------------------------------------------------------------
  def moving?
    return @id == 1 ? @moving : super
  end
  
  #-----------------------------------------------------------------------------
  # moves to x, y
  #-----------------------------------------------------------------------------
  def moveto(x, y)
    super(x, y)
    @move_list = [] if @id != 1
  end
  
  #-----------------------------------------------------------------------------
  # never returns
  #-----------------------------------------------------------------------------
  def update_turn_step_by_step
    super
    return false
  end
end # Class