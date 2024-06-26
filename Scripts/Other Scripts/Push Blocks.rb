#==============================================================================
# ** Push Blocks
#
# Created by Jaiden Alemni
# For exclusive use in Legends of Astravia Only
#
# v1.0 12/9/19 
# - Script creation
#------------------------------------------------------------------------------
# Manages "push blocks" on the game map. 
#==============================================================================

#==============================================================================
# * Configuration Module
#==============================================================================
module PushBlocks
  # Number of frames before the event should be triggered
  TIMER = 10
  # Push SFX
  PUSH_SFX = 'MAP_PushBlock'
  STUCK_SFX = 'MAP_BlockStuck'
  # Block speed
  MOVE_SPEED = 2
end

#===============================================================================
# Interpreter Class
#
# This stuff really belongs in like, game_character & sprite map or something
#===============================================================================
class Interpreter
  #-----------------------------------------------------------------------------
  # Push block command
  #-----------------------------------------------------------------------------
  def push_block
    # Get details
    player = get_character(-1)
    event = get_character(0)
    # Exit if characters don't exist
    if player == nil || event == nil
      return false
    end
    # Exit if diagonal or characters don't exist
    if player.direction % 2 != 0 
      return false
    end
    player.straighten
    event.last_x = event.x
    event.last_y = event.y
    event.move_speed = PushBlocks::MOVE_SPEED
    # Call the custom move routes
    block_route = CustomRoutes.create_route(:block_move, player, player.direction)
    player_route = CustomRoutes.create_route(:push_block, player)
    # Initiate move routes
    event.force_move_route(block_route)
    player.force_move_route(player_route)
    return true
  end
end


