#==============================================================================
# Extra Fogs & Panorama Lock
# - - - 
# By Jaiden (RPGmaker.net / rpgmakerweb.com)
# (Twitter: @studioalemni)
# v1.0 - September 2019
# * Allows for an additional fog, which is per map instead of per tileset
# * Allows a panorama to lock so it doesn't scroll, allowing it to be used
#  as a ground layer
#  (Thanks to Game_Guy from www.chaos-project.com for help on this)
# * Designated fog for parallax/detail mapping 
# * Designated fog for lighting overlay
#
# [[Compatibility]]
# This script aliases the Spriteset_Map class. Place it above main
# like any other custom script. 
# It hasn't been extensively tested, but should otherwise play nicely
# with other map scripts. 
#
# [[How to Use]]
# The "fogs" folder should contains two subfolders:
# /Fogs/Lightmaps
# /Fogs/Parallax
#
# In these folders, place a file named "Map[MAPID]", such as "Map002.png"
# If the file is detected, it will be applied to the map.
#
# ***NOTE: In order to get the desired effect, these files MUST be the same size
# as the map they're applied to. If they are not, the panorama/lights will not
# match up with the tilemap / player. 
#
# Lightmaps will always have subtractive blending, and "parallax" will always 
# be drawn above the ground layer but below the player. This means the player 
# can always walk over items in the parallax, and is best reserved for things 
# like vegetation, etc.
#
#==============================================================================
module CustomFogsPanorama
  NORMAL = 0
  ADD = 1
  SUB = 2
  MULTIPLY = 3
  ABOVE = true
  BELOW = false
  NO_TONE = Tone.new(0,0,0)
  # def self.fogs(map_id)
  #   case map_id
  #   #==============================================================================
  #   #
  #   # BEGIN CONFIGURATION
  #   #
  #   # When a fog is specified here, it will be drawn in addition to the 
  #   # already existing map fog. 
  #   #
  #   # Configuration values are identical to that of the editor.
  #   # Please follow the format exactly, and do not modify the "else"
  #   # or the lines below it. Mind your commas!
    
  #   # when MAPID then ["Name", Zoom_x (%), Zoom_y (%), Opacity (0-255), Blend (0:norm, 1:add, 2:sub), Tone.new(r,g,b), scroll x, scroll y]
  #   #---- Mordin -------------------------------------------------  
  #     # Forest
  #     when 63
  #       #["Rift_Overlay1", 100, 100, 255, MULTIPLY, nil, 0, 0]
  #     when 68
  #       #["TreeCover1", 200, 200, 50, SUB, nil, 0, 0]
  #     when 73
  #       #["Fog1", 100, 100, 25, SUB, nil, 1.5, 0.5]
  #     # Swamp
  #     when 64, 88, 38
  #       ["Fog1", 100, 100, 50, SUB, Tone.new(25,25,-10), 1.5, 0.5]
  #     when 27
  #       ["Fog4", 100, 100, 50, SUB, nil, 1.5, 0]
  #     # Dungeon
  #     when 69, 70, 76, 77, 81, 90, 93..98
  #       ["Fog1", 200, 200, 50, SUB, Tone.new(25,25,-10), -2, -2]
  #   #---- End Extra Fog Config -------------------------------------------------
  #     when 999 then ["", 100, 100, 255, NORMAL, DEFAULT_TONE, 0, 0]
  #   else 
  #     [""]
  #   end
  # end
  #--------------------------------------------------------------------------
  # * Panorama settings
  # ["Filename", Lock?, Scroll x, Scroll Y]
  # Lock? - When set to true, panorama acts like a fog and scrolls on movement like the map
  # Note that scrolling doesn't happen unless the panorama is locked
  #
  def self.panoramas(map_id)
    case map_id
    when  9 then ["Sky1", false, 1, 2]
    when 74 then ["Sky2", false, -1, -2]
    when 78 then ["Sky2", false, -1, -2]
    when 72 then ["Falling1", false, 0, -64]
    when 63 then ["DarkSpace2", false, 2, 1]
    when 21 then ["Sky6", true, 0, 0]
    when 52, 53, 55, 56
      ["DarkSpace3", false, -1, -1]
    else
      ["", true, 0, 0]
    end
  end

  def self.parallax_layer(map_id)
    case map_id
    #==========================================================================
    # * PARALLAX POSITION CONFIG
    #
    # Use this to determine where the Parallax (Graphics/Fogs/Parallax)
    # is positioned. If ABOVE, it will be above the player and all other layers of the map.
    # If BELOW it will be drawn below the player but above the ground layer.
    #
    # Default value is BELOW
    #
    # when MAPID then VALUE
    when 1 then ABOVE
    # when 2 then BELOW
    #
    #---- End Parallax Position Config ----------------------------------------
    # Please don't edit the code between configuration blocks	
    else
      BELOW
    end	
  end
  #--------------------------------------------------------------------------
  # * Lightmap Control
  #
  # List of maps whose opacity/hue should shift for day/night
  OUTDOOR_IDS = [3, 11, 12, 13, 14, 15, 16, 20, 37, 89]

  # Switch to flip lights off for "day"
  DAY_NIGHT_SWITCH = 72
  
  # Time, in seconds, day/night should automatically cycle
  #DAY_NIGHT_CYCLE = 30.0
#
# END CONFIGURATION
# (Do not modify below this line unless you know what you're doing!)
#
#==============================================================================
end

# Day night system
__END__
class Game_System
  attr_reader :is_day
  attr_reader :is_night
  attr_accessor :current_time
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  alias jaiden_lightmap_system_initialize initialize
  def initialize
    jaiden_lightmap_system_initialize
    # The current time in the cycle
    @current_time = 0.0
    @full_day_cycle = CustomFogsPanorama::DAY_NIGHT_CYCLE
    # Dawn starts at zero
    @day_start = 0.0
    # Dusk starts at 1/2
    @night_start = @full_day_cycle * 0.5
    # Flags for dusk and dawn
    @is_day = false
    @is_night = true
  end
  #--------------------------------------------------------------------------
  # * Update time
  #--------------------------------------------------------------------------
  alias jaiden_lightmap_system_update update
  def update
    # Call original
    jaiden_lightmap_system_update
    # Update timer
    @current_time += $deltaTime
    # We've reached the end of the cycle
    if @current_time >= @full_day_cycle
      # Reset
      @current_time = 0.0
    end
    # Flag dusk or dawn
    if @current_time >= @day_start && @current_time <= @night_start
      @is_day = true if !@is_day
      @is_night = false if @is_night
    elsif @current_time >= @night_start 
      @is_night = true if !@is_night
      @is_day = false if @is_day
    end
    p @current_time
    p "night? #{@is_night}"
    p "day? #{@is_day}"
    p "==="
  end
end