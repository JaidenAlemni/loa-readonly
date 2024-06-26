#==============================================================================
# * Map Configuration
# ------------------------------------------
# RPG Maker XP doesn't allow for adding much to the map properties with 
# the exception of encounters. 
# $game_map.encounter_list returns an array of troop IDs.
#
# Since troop IDs are just integers, we can utilize these "IDs" to apply
# properties to a map, instead of parsing through the map name string. 
#
# The first 30 troop IDs will be reserved for this use.
#==============================================================================
module MapConfig
  # MAP PROPERTY CONSTANTS
  DUNGEON = 1 # Map allows enemies to move when the player moves
  INDOORS = 2 # Map softens BGM and applies other "indoor only" properties
  LOOPING = 3 # Map wraps at edges
  RESPAWN = 4 # Map respawns enemies
  NO_ANTILAG = 5 # Maps that ignore the anti-lag function of Blizz ABSEAL
  HAS_PARALLAX = 6 # Maps that have a parallax overlay enabled
  HAS_LIGHTMAP = 7 # Maps that have a lightmap enabled
  #----------------------------------------------------------
  # Extra Terrain Tags
  # Permits setting / checking terrain tags higher than 7
  #----------------------------------------------------------
  EXTRA_TERRAIN_TAGS = {
    # Tileset_ID => {Tile_ID => Tag, Tile_ID => Tag}
    5 => {2 => 11, 3 => 12, 4 => 13, 5 => 14} # Mordin Dungeon
  }
  #----------------------------------------------------------
  # Setup Extra Terrain Tags
  # Adds the additional tags from the hash above to the specified
  # tileset. Called on Game_Map#setup
  #----------------------------------------------------------
  # Permits setting / checking terrain tags higher than 7
  def self.setup_extra_ttags(tileset_id, tt_table)
    return if EXTRA_TERRAIN_TAGS[tileset_id].nil?
    EXTRA_TERRAIN_TAGS[tileset_id].each do |tile_id, terrain_tag|
      tt_table[tile_id + 384] = terrain_tag
    end
  end
  #----------------------------------------------------------
  # Get Map 
  # Quick function for returning the map object from the ID
  #----------------------------------------------------------
  def get_map(map_id)
    if $game_map.map_id == map_id
      $game_map
    else
      # Load the map data
      load_data(sprintf("Data/Map%03d.rxdata", map_id))
    end
  end
  #----------------------------------------------------------
  # Check if the map is indoors (and should have its audio softened)
  #----------------------------------------------------------
  def self.house?(map)
    map.encounter_list.include?(INDOORS)
  end
  #----------------------------------------------------------
  # Check if the map is a dungeon (certain properties)
  #----------------------------------------------------------
  def self.dungeon?(map)
    map.encounter_list.include?(DUNGEON)
  end
  #----------------------------------------------------------
  # Check if the map should loop
  #----------------------------------------------------------
  def self.looping?(map)
    map.encounter_list.include?(LOOPING)
  end
  #----------------------------------------------------------
  # Check if the map should respawn enemies on exit
  #----------------------------------------------------------
  def self.respawning?(map)
    map.encounter_list.include?(RESPAWN)
  end
  #----------------------------------------------------------
  # Check if the map should respawn enemies on exit
  #----------------------------------------------------------
  def self.disable_antilag?(map)
    map.encounter_list.include?(NO_ANTILAG)
  end
  #----------------------------------------------------------
  # Check if the map has a parallax
  #----------------------------------------------------------
  def self.has_parallax?(map)
    map.encounter_list.include?(HAS_PARALLAX)
  end
  #----------------------------------------------------------
  # Check if the map has a lightmap
  #----------------------------------------------------------
  def self.has_lightmap?(map)
    map.encounter_list.include?(HAS_LIGHTMAP)
  end
end


