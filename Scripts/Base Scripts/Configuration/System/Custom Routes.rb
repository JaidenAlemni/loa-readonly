#==============================================================================
# * CustomRoutes Module
# This module stores a series of custom move routes, called within 
# RPG::MoveRoute. It allows for modularity in direction, etc. 
# RPG::MoveCommand.new(ID, [parameters])
# Command IDs (Game_Character#move_type_custom)
# 0 - End of list
# 1-14 - move down, left, right, up, ll, lr, ul, ur, random, toward player
# away from player, forward, backwards, jump (steps)
# 15 - wait (frames)
# 16-26 - turn down, left, right, up, r90, l90, 180, r||l 90, random, toward, away
# 27-28 - Switch ON, OFF (switch ID)
# 29 - Change speed
# 30 - Change frequency
# 31-32 - Move anim ON, OFF
# 33-34 - Stop anim ON, OFF
# 35-36 - Dir fix ON, OFF
# 37-38 - Through ON, OFF
# 39-40 - Always on top ON, OFF
# 41 - Change Graphic (name, hue, direction, pattern)
# 42 - Change opacity (0-255)
# 43 - Change blending (0-4)
# 44 - Play SE (RPG::AudioFile.new("Name",vol,pitch))
# 45 - eval
# 46 - change pattern (pattern)
# 47 - change direction (direction)
# 48 - Jump to coordinates
#==============================================================================
module CustomRoutes
  # Constants for readability
  EOL = 0
  MOVE_D = 1; MOVE_L = 2;  MOVE_R = 3;  MOVE_U = 4;  MOVE_LL = 5;  MOVE_LR = 6;
  MOVE_UL = 7;  MOVE_UR = 8;  MOVE_RAND = 9;  MOVE_TO_PLAYER = 10  
  MOVE_AWAY_PLAYER = 11;  MOVE_FWD = 12;  MOVE_BCK = 13;  JUMP = 14;  WAIT = 15
  TURN_D = 16;  TURN_L = 17;  TURN_R = 18;  TURN_U = 19;  TURN_R90 = 20;  TURN_L90 = 21
  TURN_180 = 22;  TURN_LOR90 = 23;  TURN_RAND = 24;  TURN_TO_PLAYER = 25;  TURN_AWAY_PLAYER = 26
  SWITCH_ON = 27;  SWITCH_OFF = 28;  CHG_SPEED = 29;  CHG_FREQ = 30
  WALK_ANIM_ON = 31;  WALK_ANIM_OFF = 32;  STOP_ANIM_ON = 33;  STOP_ANIM_OFF = 34
  DIR_FIX_ON = 35;  DIR_FIX_OFF = 36;  THROUGH_ON = 37;  THROUGH_OFF = 38
  MAX_Z_ON = 39;  MAX_Z_OFF = 40;  CHG_GRAPHIC = 41;  CHG_OPACITY = 42;  CHG_BLEND = 43
  SE_PLAY = 44;  EVAL = 45;  CHG_PATTERN = 46;  CHG_DIR = 47;  JUMP_TO_COORDS = 48
  # An array of routes that take a Game_Character object as the first parameter
  #CHARACTER_ROUTES = [:look_around, :look_direction, :blink, :look_down, :push_block, :jump_gap]
  #--------------------------------------------------------------------------
  # * Saves the move route objects. Should only be called after object initialization
  #--------------------------------------------------------------------------
  def self.create_route(key, *params)
    route = RPG::MoveRoute.new
    route.load_route(key, *params)
    return route
  end
  #--------------------------------------------------------------------------
  # * Reset character graphic
  # This is the safest way to restore a character graphic previously used
  # in another custom move route / animation
  #--------------------------------------------------------------------------
  def self.reset_graphic(character)
    repeat = false
    skippable = false
    # If there isn't an original graphic to set to
    if character.original_char_name == ""
      # Return an empty move
      list = [RPG::MoveCommand.new]
    else
      # Set to original graphic and reset the pattern
      list = [
        RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0]),
        RPG::MoveCommand.new(EVAL, ["@frame_order = @original_frame_order"]),
        RPG::MoveCommand.new
      ]
    end
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * An empty move route list. When set, the autonomous 
  # move route list takes over each step.
  #--------------------------------------------------------------------------
  def self.continue(_character = nil)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character waits repeatedly
  #--------------------------------------------------------------------------
  def self.wait_forever(_character = nil)
    repeat = true
    skippable = false
    list = [
      RPG::MoveCommand.new(WAIT, [1]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character pushes a block
  #--------------------------------------------------------------------------
  def self.push_block(character)
    repeat = false
    skippable = true
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Save original name and set graphic
    character.original_char_name = character.character_name
    graphic = "#{character.character_name}_Push"
    original_speed = character.move_speed
    movedir = case character.direction
              when 2; 1
              when 4; 2
              when 6; 3
              when 8; 4
              end
    list = [
      # wait (to give time for block to move)
      RPG::MoveCommand.new(WAIT, [1]),
      # turn on stepping animation
      RPG::MoveCommand.new(STOP_ANIM_ON),
      # set graphic (character name, hue, direction, pattern)
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 0]),
      # set move speed
      RPG::MoveCommand.new(CHG_SPEED, [PushBlocks::MOVE_SPEED]),
      # move one tile
      RPG::MoveCommand.new(movedir, [Game_Map::TILE_SIZE]),
      # reset move speed
      RPG::MoveCommand.new(CHG_SPEED, [original_speed]),
      # reset step
      RPG::MoveCommand.new(STOP_ANIM_OFF),
      # reset graphic
      RPG::MoveCommand.new(CHG_GRAPHIC, [character.character_name, 0, character.direction, 0]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Block move
  # Called on the pushblock itself to move
  #--------------------------------------------------------------------------
  def self.block_move(_character, direction)
    repeat = false
    skippable = true
    # Set direction
    movedir = direction / 2
    # movedir = case direction
    #           when 2; 1
    #           when 4; 2
    #           when 6; 3
    #           when 8; 4
    #           end
    list = [
      # Move one tile (based on direction)
      RPG::MoveCommand.new(movedir, [Game_Map::TILE_SIZE, true]),
      # Check if the move happened & play a sound (eval)
      RPG::MoveCommand.new(EVAL, ['check_block_move']),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character jumps a tile gap
  # tx, ty - Jump coordinates, in pixels
  #--------------------------------------------------------------------------
  def self.jump_gap(character, tx, ty)
    repeat = false
    skippable = false
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Save original name and set graphic
    character.original_char_name = character.character_name
    graphic = "#{character.character_name}_Jump"
    # Set direction
    movedir = case character.direction
              when 2; 1
              when 4; 2
              when 6; 3
              when 8; 4
              end
    # Set camera lock
    lock = [4,6].include?(character.direction) ? true : false
    list = [
      # Unfollow camera
      RPG::MoveCommand.new(EVAL, ["Camera.lock_y = #{lock}"]),
      # Disable move anim
      RPG::MoveCommand.new(WALK_ANIM_OFF),
      # Dir fix
      RPG::MoveCommand.new(DIR_FIX_ON),
      # Change graphic to jumping 
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 0]),
      # Change pattern
      RPG::MoveCommand.new(CHG_PATTERN, [1]),
      # Jump
      RPG::MoveCommand.new(JUMP_TO_COORDS, [tx, ty, -2]),
      # Play SFX
      RPG::MoveCommand.new(SE_PLAY, [RPG::AudioFile.new("MAP_Hop", 80, 100)]),
      # Wait
      RPG::MoveCommand.new(WAIT, [4]),
      # Revert character graphic
      RPG::MoveCommand.new(WALK_ANIM_ON),
      RPG::MoveCommand.new(STOP_ANIM_OFF),
      RPG::MoveCommand.new(DIR_FIX_OFF),
      # Change pattern
      RPG::MoveCommand.new(CHG_PATTERN, [0]), 
      # Wait
      RPG::MoveCommand.new(WAIT, [4]),
      RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0]),
      # Refollow Camera
      RPG::MoveCommand.new(EVAL, ['Camera.unlock']),
      RPG::MoveCommand.new,
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * End jump
  # Reset pose from jumping animation
  #--------------------------------------------------------------------------
  def self.end_jump(character)
    repeat = false
    skippable = false
    # If there isn't an original graphic to set to
    if character.original_char_name == ""
      # Return an empty move
      list = [RPG::MoveCommand.new]
    else
      # Set to original graphic and reset the pattern
      list = [
        RPG::MoveCommand.new(WALK_ANIM_ON),
        RPG::MoveCommand.new(STOP_ANIM_OFF),
        RPG::MoveCommand.new(DIR_FIX_OFF),
        # Change pattern
        RPG::MoveCommand.new(CHG_PATTERN, [0]), 
        # Wait
        RPG::MoveCommand.new(WAIT, [4]),
        RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0]),
        # Refollow Camera
        RPG::MoveCommand.new(EVAL, ['Camera.unlock']),
        RPG::MoveCommand.new
      ]
    end
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character shakes their head
  #--------------------------------------------------------------------------
  def self.look_around(character, delay = 4)
    repeat = false
    skippable = false
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Save original name and set graphic
    character.original_char_name = character.character_name
    character.original_frame_order = character.frame_order
    character.frame_order = [1,2,3,4]
    graphic = "#{character.character_name}_HeadTurn"
    list = [
      # Change the graphic to "look around", 2nd frame
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 1]),
      RPG::MoveCommand.new(WAIT, [delay*4]), # Wait (longer)
      # Set back to original graphic to get the center frame
      RPG::MoveCommand.new(CHG_GRAPHIC, [character.character_name, 0, character.direction, 0]),
      RPG::MoveCommand.new(WAIT, [delay]),
      # Looking the other direction now
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 2]),
      RPG::MoveCommand.new(WAIT, [delay*5]),
      # Return to original graphic
      RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0]),
      RPG::MoveCommand.new(EVAL, ["@frame_order = @original_frame_order"]),
      RPG::MoveCommand.new # End
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character blinks a few times
  #--------------------------------------------------------------------------
  def self.blink(character)
    repeat = false
    skippable = false
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Set graphic details
    character.original_char_name = character.character_name
    character.original_frame_order = character.frame_order
    character.frame_order = [1,2,3,4]
    graphic = "#{character.character_name}_Blink"
    list = [
      # Change the graphic to "blink", 1st frame
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 0]),
      RPG::MoveCommand.new(WAIT, [30]), # Wait a bit
      RPG::MoveCommand.new(CHG_PATTERN, [2]), # Blink
      RPG::MoveCommand.new(WAIT, [8]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new(WAIT, [4]),
      RPG::MoveCommand.new(CHG_PATTERN, [2]),
      RPG::MoveCommand.new(WAIT, [20]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      # Return to original graphic
      RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0]),
      RPG::MoveCommand.new(EVAL, ["@frame_order = @original_frame_order"]),
      RPG::MoveCommand.new # End
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character looks down
  # delay - how long, in frames, to hold the animation
  # reset - whether or not to reset the graphic or stay looking down
  # (if true, the graphic must be reset afterwards)
  #--------------------------------------------------------------------------
  def self.look_down(character, delay, reset = true)
    repeat = false
    skippable = false
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Save original name
    character.original_char_name = character.character_name
    character.original_frame_order = character.frame_order
    character.frame_order = [1,2,3,4]
    graphic = "#{character.character_name}_Blink"
    list = [
      # Change the graphic to "blink", 1st frame
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, 0]),
      RPG::MoveCommand.new(WAIT, [30]), # Wait a bit
      RPG::MoveCommand.new(CHG_PATTERN, [1]), # Squint eyes
      RPG::MoveCommand.new(WAIT, [8]),
      RPG::MoveCommand.new(CHG_PATTERN, [3]) # Look down
    ]
    # If the graphic is to be reset
    if reset
      # Push a wait and reset
      list << RPG::MoveCommand.new(WAIT, [delay])
      list << RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0])
      list << RPG::MoveCommand.new(EVAL, ["@frame_order = @original_frame_order"])
    end
    # Push the list terminator
    list << RPG::MoveCommand.new
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Character looks a certain direction
  # dir - Direction to look
  # delay - how long, in frames, to hold the animation
  # reset - whether or not to reset the graphic or stay looking down
  # (if true, the graphic must be reset afterwards)
  #--------------------------------------------------------------------------
  def self.look_direction(character, dir, delay = 8, reset = true)
    repeat = false
    skippable = false
    # Reset the graphic (to prevent _Suffix_Suffix cases)
    character.character_name = character.original_char_name if character.original_char_name != ""
    # Save original name
    character.original_char_name = character.character_name
    character.original_frame_order = character.frame_order
    character.frame_order = [1,2,3,4]
    graphic = "#{character.character_name}_HeadTurn"
    pattern =
      case dir
      when :left; 3
      when :upper_left, :lower_right; 2
      when :right; 0
      when :upper_right, :lower_left; 1
      end
    list = [
      # Change the graphic, specified direction
      RPG::MoveCommand.new(CHG_GRAPHIC, [graphic, 0, character.direction, pattern]),
      RPG::MoveCommand.new(WAIT, [30]) # Wait a bit
    ]
    # If the graphic is to be reset
    if reset
      # Push a wait and reset
      list << RPG::MoveCommand.new(WAIT, [delay])
      list << RPG::MoveCommand.new(CHG_GRAPHIC, [character.original_char_name, 0, character.direction, 0])
      list << RPG::MoveCommand.new(EVAL, ["@frame_order = @original_frame_order"])
    end
    # Push the list terminator
    list << RPG::MoveCommand.new
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Cycles the character forward four frames
  #--------------------------------------------------------------------------
  def self.cycle_anim_forward(_character, delay = 4)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(WAIT, [delay]), # Wait
      RPG::MoveCommand.new(CHG_PATTERN, [1]), # Set pattern
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [2]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [3]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Cycles the character back four frames
  #--------------------------------------------------------------------------
  def self.cycle_anim_back(_character, delay = 4)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [2]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [1]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Spins the character in place (unwritten)
  #--------------------------------------------------------------------------
  # def self.spin(delay, times = 1)
  #   repeat = false
  #   skippable = false
  #   list = [
  #     RPG::MoveCommand.new(WAIT, [delay]),
  #     RPG::MoveCommand.new
  #   ]
  #   return [repeat,skippable,list]
  # end
  #--------------------------------------------------------------------------
  # * Situp animation (oliver, using _situp)
  #--------------------------------------------------------------------------
  def self.sit_up(_character, delay = 4)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [1]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [1]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new(WAIT, [60]),
      RPG::MoveCommand.new(CHG_PATTERN, [2]),
      RPG::MoveCommand.new(WAIT, [delay*2]),
      RPG::MoveCommand.new(CHG_PATTERN, [3]),
      RPG::MoveCommand.new(WAIT, [30]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Stand up from sitting animation (oliver, using _situp)
  #--------------------------------------------------------------------------
  def self.stand_up(_character, delay = 4)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new(CHG_DIR, [4]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [1]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [2]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_PATTERN, [3]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new(CHG_DIR, [6]),
      RPG::MoveCommand.new(CHG_PATTERN, [0]),
      RPG::MoveCommand.new(WAIT, [delay]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Spawn party member
  #--------------------------------------------------------------------------
  def self.spawn_party_member(_character, move_dir)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(THROUGH_ON),
      RPG::MoveCommand.new(EVAL, ['moveto($game_player.x,$game_player.y)']),
      RPG::MoveCommand.new(CHG_OPACITY, [150]),
      RPG::MoveCommand.new(EVAL, ["move_custom(#{move_dir})"]),
      RPG::MoveCommand.new(WAIT, [4]),
      RPG::MoveCommand.new(CHG_OPACITY, [255]),
      RPG::MoveCommand.new(WAIT, [8]),
      RPG::MoveCommand.new(CHG_DIR, [$game_player.direction]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Despawn party member
  #--------------------------------------------------------------------------
  def self.despawn_party_member(_character)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(THROUGH_ON),
      RPG::MoveCommand.new(EVAL, ['move_to_place($game_player.x,$game_player.y)']),
      RPG::MoveCommand.new(CHG_OPACITY, [150]),
      RPG::MoveCommand.new(WAIT, [8]),
      RPG::MoveCommand.new(CHG_OPACITY, [0]),
      RPG::MoveCommand.new
    ]
    return [repeat,skippable,list]
  end
  #--------------------------------------------------------------------------
  # * Appear (Type A)
  # reverse - run the animation in reverse
  #--------------------------------------------------------------------------
  def self.appear_a(_character, reverse = false)
    repeat = false
    skippable = false
    list = [
      RPG::MoveCommand.new(CHG_BLEND, [1]),
      RPG::MoveCommand.new(CHG_OPACITY, [0]),
      RPG::MoveCommand.new(SE_PLAY, [RPG::AudioFile.new("FX_CastSpell", 80, 100)]),
      RPG::MoveCommand.new(WAIT, [10]),
      RPG::MoveCommand.new(CHG_OPACITY, [64]),
      RPG::MoveCommand.new(WAIT, [4]),
      RPG::MoveCommand.new(CHG_OPACITY, [0]),
      RPG::MoveCommand.new(WAIT, [2]),
      RPG::MoveCommand.new(CHG_OPACITY, [128]),
      RPG::MoveCommand.new(WAIT, [2]),
      RPG::MoveCommand.new(CHG_OPACITY, [0]),
      RPG::MoveCommand.new(WAIT, [1]),
      RPG::MoveCommand.new(CHG_OPACITY, [255]),
      RPG::MoveCommand.new(WAIT, [2]),
      RPG::MoveCommand.new(CHG_OPACITY, [64]),
      RPG::MoveCommand.new(WAIT, [1]),
      RPG::MoveCommand.new(CHG_OPACITY, [255]),
      RPG::MoveCommand.new(EVAL, ['self.tone = Tone.new(0,0,64)']),
      RPG::MoveCommand.new(WAIT, [2]),
      RPG::MoveCommand.new(CHG_OPACITY, [64]),
      RPG::MoveCommand.new(WAIT, [1]),
      RPG::MoveCommand.new(CHG_OPACITY, [255]),
      RPG::MoveCommand.new(WAIT, [4]),
      RPG::MoveCommand.new(CHG_OPACITY, [64]),
      RPG::MoveCommand.new(EVAL, ['self.tone = Tone.new(0,0,0)']),
      RPG::MoveCommand.new(CHG_OPACITY, [128]),
      RPG::MoveCommand.new(WAIT, [8]),
      RPG::MoveCommand.new(CHG_OPACITY, [180]),
      RPG::MoveCommand.new(WAIT, [2]),
      RPG::MoveCommand.new(SE_PLAY, [RPG::AudioFile.new("FX_Teleport1", 80, 130)]),
      RPG::MoveCommand.new(CHG_BLEND, [1]),
      RPG::MoveCommand.new(CHG_BLEND, [0]),
      RPG::MoveCommand.new(CHG_OPACITY, [255]),
      RPG::MoveCommand.new
    ]
    if reverse
      list.delete_at(2)
      end_command = list.pop
      list.reverse!
      list << end_command
    end
    return [repeat,skippable,list]
  end
end