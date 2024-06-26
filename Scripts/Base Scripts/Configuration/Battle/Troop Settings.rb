#==============================================================================
# ** Troop Position Database
# Records [x, y] positions for all enemies in a specific troop
# (Origin is always center of battlefield)
# Format:      Enemy 1, Enemy 2, etc.
# troop_id => [[x, y], [x, y], [x, y]]
#==============================================================================
class Game_Troop
  # Positions Grid:
  # [ NW ]  [ N ]  [ NE ]
  # [ W ]  [ C ]  [ E ]
  # [ SW ]  [ S ]  [ SE ]
  # TOP_ROW =    [[-140, -20], [-100, -30], [-60, -40]]
  # CENTER_ROW = [[-150,  10], [-110,   0], [-70, -10]]
  # BOTTOM_ROW = [[-160,  40], [-120,  30], [-80,  20]]
  # GRID = [
  #   [-140, -20], [-100, -30], [-60, -40],
  #   [-150,  10], [-110,   0], [-70, -10],
  #   [-160,  40], [-120,  30], [-80,  20]
  # ]

  ONE_TOP     = [ [ -92, -12] ]
  ONE_BOTTOM  = [ [-134,  28] ]
  ONE_CENTER  = [ [-114,  10] ]
  ONE_FORWARD = [ [ -78,  10] ]
  ONE_BACK    = [ [-148,  10] ]

  ONE_ENEMY = [ONE_TOP, ONE_BOTTOM, ONE_CENTER, ONE_FORWARD, ONE_BACK]

  TWO_CENTER = [ [ -88,  -2], [-138,  22] ]
  TWO_HIGH   = [ [ -70, -12], [-114,  10] ]
  TWO_LOW    = [ [-114,  10], [-164,  34] ]
  TWO_WIDE   = [ [ -70, -12], [-164,  34] ]

  TWO_ENEMIES = [TWO_CENTER, TWO_HIGH, TWO_LOW, TWO_WIDE]

  THREE_LINE = [ [ -68, -14], [-112,   8], [-160,  32] ]
  THREE_V    = [ [-110, -14], [ -68,  12], [-150,  32] ] # Need to fix cursor behavior for this

  THREE_ENEMIES = [THREE_LINE]

  FOUR_ENEMIES = [ [ -88,  10], [-160,   2], [ -74,  24], [-144,  36] ]

  FIVE_ENEMIES = [ [ -88,  10], [-160,   2], [-116,  12], [ -74,  24], [-144,  36] ]

  # In case the battle background is adjusted after, use this to 
  # globally adjust all coordinates
  POS_X_OFFSET = 8
  POS_Y_OFFSET = -4

  CUSTOM_COORDS = [32, 50, 51] # List of IDs that contain custom setups
  #--------------------------------------------------------------------------
  # * Get start positions for each enemy
  #--------------------------------------------------------------------------
  def positions
    # If the coordinates are customized
    if CUSTOM_COORDS.include?(@troop_id)
      # Branch by troop
      case @troop_id
      when 32 # tutorial
        return ONE_CENTER
      when 51 # Rogue Knights
        return TWO_CENTER
      when 50
        return [[-124,-88]]
      end
    end
    # Otherwise get positions based on troop size
    num_members = $data_troops[@troop_id].members.size
    case num_members
    when 1
      # [GRID.sample]
      ONE_ENEMY.sample
    when 2
      # [TOP_ROW.sample, BOTTOM_ROW.sample]
      TWO_ENEMIES.sample
    when 3
      # [TOP_ROW.sample, CENTER_ROW.sample, BOTTOM_ROW.sample]
      THREE_ENEMIES.sample
    when 4
      FOUR_ZAG
    else
      ONE_CENTER
    end
  end
  #--------------------------------------------------------------------------
  # * Get zoom conditions for each troop
  #--------------------------------------------------------------------------
  def camera_setup
    center_x, center_y = BattleConfig::BATTLEFIELD_CENTER
    case @troop_id
    when 50
      # zoom, center x, center y
      [2.0, center_x, center_y - 48]
    else
      [3.0, center_x, center_y - 16]
    end
  end
end