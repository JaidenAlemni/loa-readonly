#=======================
# * Dependencies / Mods
#=======================
# GAME CLASSES:
# ----------------
# > Game_Map
# > Game_Event

#==============================================================================
# ** Dungeon Enemies
# Created by Jaiden - 11/22/18
#------------------------------------------------------------------------------
# Manages enemy movement and respawn on specific maps.
#
# Maps tagged with "[Dung]" activate the script
#
# In these maps, the following event prefixes have effects:
# EN_ - Enemy: does not respond to move route events
# ENm_ - Enemy move: responds to move route events
# In order to reset enemies on a map, call:
# $game_map.respawn_enemies(MAP_ID)
# All EN_/ENm_ enemies will be reset with this call. 
#==============================================================================
module DungeonConfig
  # Self-switch that stops the enemy from recieving "Wait" commands
  #
  # This allows an enemy to move on their own if the player does something
  # to trigger them, such as the Event Sensor. 
  #
  # When set to "True", the specified self-switch will prevent the enemy
  # from locking into place.
  ANTI_WAIT_SWITCH = 'D'
  # Determines how long to wait (in frames) when escaping from an event
  WAIT_TIME = 150
  # Static code
  STATIC_COMMENT = 'ENEMY_STATIC'
  # Moving code
  MOVING_COMMENT = 'ENEMY_MOVE'
  # List of maps that have relevant enemies for the demo
  DEMO_MAP_IDS = [22, 73, 64, 88, 77, 81, 93, 94, 95, 162, 215]
  #--------------------------------------------------------------------------
  # * Queue Respawn
  # Sets a map to have its enemies respawned upon setup
  #--------------------------------------------------------------------------
  def self.queue_respawn(map_id)
    $game_system.respawn_maps << map_id
  end
end