#==============================================================================
# ** Game_Enemy
#------------------------------------------------------------------------------
#  This class handles enemies. It's used within the Game_Troop class
#  ($game_troop).
#==============================================================================

class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :adj_speed
  attr_accessor :letter
  attr_accessor :plural
  attr_writer   :current_action
  attr_writer   :actions
  attr_reader :original_name
  attr_accessor  :start_position
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     troop_id     : troop ID
  #     member_index : troop member index
  #--------------------------------------------------------------------------
  def initialize(troop_id, member_index)
    super()
    @troop_id = troop_id
    @member_index = member_index
    troop = $data_troops[@troop_id]
    @enemy_id = troop.members[@member_index].enemy_id
    enemy = $data_enemies[@enemy_id]
    @battler_name = enemy.battler_name
    @battler_hue = enemy.battler_hue
    @hp = maxhp
    @sp = maxsp
    @hidden = troop.members[@member_index].hidden
    @immortal = troop.members[@member_index].immortal
    @letter = ""
    @plural = false
    @start_position = [0,0]
  end
  #--------------------------------------------------------------------------
  # * Get Enemy ID
  #--------------------------------------------------------------------------
  def id
    return @enemy_id
  end
  #--------------------------------------------------------------------------
  # * Get Index
  #--------------------------------------------------------------------------
  def index
    return @member_index
  end
  #--------------------------------------------------------------------------
  # * Get Name
  #--------------------------------------------------------------------------
  def name
    # If the name is localized
    name_s = Localization.localize("&MUI[#{$data_enemies[@enemy_id].name_loc_key}]")
    if name_s != @original_name
      @original_name = name_s
    end
    return @plural ? @original_name + @letter : @original_name
  end
  #--------------------------------------------------------------------------
  # * Get Basic Maximum HP
  #--------------------------------------------------------------------------
  def base_maxhp
    return $data_enemies[@enemy_id].maxhp
  end
  #--------------------------------------------------------------------------
  # * Get Basic Maximum SP
  #--------------------------------------------------------------------------
  def base_maxsp
    return $data_enemies[@enemy_id].maxsp
  end
  #--------------------------------------------------------------------------
  # * Get Basic Strength
  #--------------------------------------------------------------------------
  def base_luk
    return $data_enemies[@enemy_id].str
  end
  #--------------------------------------------------------------------------
  # * Get Basic Dexterity
  #--------------------------------------------------------------------------
  def base_dex
    return $data_enemies[@enemy_id].dex
  end
  #--------------------------------------------------------------------------
  # * Get Basic Agility
  #--------------------------------------------------------------------------
  def base_agi
    return $data_enemies[@enemy_id].agi
  end
  #--------------------------------------------------------------------------
  # * Get Basic Intelligence
  #--------------------------------------------------------------------------
  def base_int
    return $data_enemies[@enemy_id].int
  end
  #--------------------------------------------------------------------------
  # * Get Basic Attack Power
  #--------------------------------------------------------------------------
  def base_atk
    wep = $data_weapons[self.weapon_id]
    wep != nil ? wep.atk : $data_enemies[@enemy_id].atk
  end
  #--------------------------------------------------------------------------
  # * Get Basic Physical Defense
  #--------------------------------------------------------------------------
  def base_pdef
    return $data_enemies[@enemy_id].pdef
  end
  #--------------------------------------------------------------------------
  # * Get Basic Magic Defense
  #--------------------------------------------------------------------------
  def base_mdef
    return $data_enemies[@enemy_id].mdef
  end
  #--------------------------------------------------------------------------
  # * Get Basic Evasion
  #--------------------------------------------------------------------------
  def base_eva
    return $data_enemies[@enemy_id].eva
  end
  #--------------------------------------------------------------------------
  # * Get Offensive Animation ID for Normal Attack
  #--------------------------------------------------------------------------
  def animation1_id
    return $data_enemies[@enemy_id].animation1_id
  end
  #--------------------------------------------------------------------------
  # * Get Target Animation ID for Normal Attack
  #--------------------------------------------------------------------------
  def animation2_id
    return $data_enemies[@enemy_id].animation2_id
  end
  #--------------------------------------------------------------------------
  # * Get Element Revision Value
  #     element_id : Element ID
  #--------------------------------------------------------------------------
  def element_rate(element_id)
    # Get a numerical value corresponding to element effectiveness
    table = BattleConfig::ELEMENT_RATES
    result = table[$data_enemies[@enemy_id].element_ranks[element_id]]
    # If protected by state, this element is reduced by half
    for i in @states
      if $data_states[i].guard_element_set.include?(element_id)
        result /= 2
      end
    end
    # End Method
    return result
  end
  #--------------------------------------------------------------------------
  # * Get State Effectiveness
  #--------------------------------------------------------------------------
  def state_ranks
    return $data_enemies[@enemy_id].state_ranks
  end
  #--------------------------------------------------------------------------
  # * Determine State Guard
  #     state_id : state ID
  #--------------------------------------------------------------------------
  def state_guard?(_state_id)
    return false
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack Element
  #--------------------------------------------------------------------------
  def element_set
    return []
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack State Change (+)
  #--------------------------------------------------------------------------
  def plus_state_set
    wep = $data_weapons[self.weapon_id]
    return wep != nil ? wep.plus_state_set : []
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack State Change (-)
  #--------------------------------------------------------------------------
  def minus_state_set
    wep = $data_weapons[self.weapon_id]
    return wep != nil ? wep.minus_state_set : []
  end
  #--------------------------------------------------------------------------
  # * Aquire Actions
  #--------------------------------------------------------------------------
  def actions
    return $data_enemies[@enemy_id].actions
  end
  #--------------------------------------------------------------------------
  # * Get EXP
  #--------------------------------------------------------------------------
  def exp
    return $data_enemies[@enemy_id].exp
  end
  #--------------------------------------------------------------------------
  # * Get Gold
  #--------------------------------------------------------------------------
  def gold
    return $data_enemies[@enemy_id].gold
  end
  #--------------------------------------------------------------------------
  # * Get Item ID
  #--------------------------------------------------------------------------
  def item_id
    return $data_enemies[@enemy_id].item_id
  end
  #--------------------------------------------------------------------------
  # * Get Weapon ID
  #--------------------------------------------------------------------------
  def weapon_id
    return $data_enemies[@enemy_id].weapon_id
  end
  #--------------------------------------------------------------------------
  # * Get Armor ID
  #--------------------------------------------------------------------------
  def armor_id
    return $data_enemies[@enemy_id].armor_id
  end
  #--------------------------------------------------------------------------
  # * Get Treasure Appearance Probability
  #--------------------------------------------------------------------------
  def treasure_prob
    return $data_enemies[@enemy_id].treasure_prob
  end
  #--------------------------------------------------------------------------
  # * Set starting position
  #--------------------------------------------------------------------------
  def base_position
    return if self.index == nil
    # if self.anime_on
    #   bitmap = Bitmap.new("Graphics/Battlers/" + @battler_name + "_1")
    # else
    #   bitmap = Bitmap.new("Graphics/Characters/" + @battler_name) 
    # end
    # height = bitmap.height
    @base_position_x, @base_position_y = @start_position
    # bitmap.dispose 
  end
  #--------------------------------------------------------------------------
  # * Get X Position
  #--------------------------------------------------------------------------
  def position_x
    return @base_position_x - @move_x
  end
  #--------------------------------------------------------------------------
  # * Get Y Position
  #--------------------------------------------------------------------------
  def position_y
    return @base_position_y + @move_y + @jump
  end
  #--------------------------------------------------------------------------
  # * Get Z Position
  #--------------------------------------------------------------------------
  def position_z
    return position_y + @move_z - @jump + 200
  end
  #--------------------------------------------------------------------------
  # * Get Battle Screen X-Coordinate
  #--------------------------------------------------------------------------
  def screen_x
    super
  end
  #--------------------------------------------------------------------------
  # * Get Battle Screen Y-Coordinate
  #--------------------------------------------------------------------------
  def screen_y
    super
  end
  #--------------------------------------------------------------------------
  # * Get Battle Screen Z-Coordinate
  #--------------------------------------------------------------------------
  def screen_z
    return screen_y
  end
  #--------------------------------------------------------------------------
  # * Escape
  #--------------------------------------------------------------------------
  def escape
    # Set hidden flag
    @hidden = true
    # Clear current action
    self.current_action.clear
  end
  #--------------------------------------------------------------------------
  # * Transform
  #     enemy_id : ID of enemy to be transformed
  #--------------------------------------------------------------------------
  def transform(enemy_id)
    # Change enemy ID
    @enemy_id = enemy_id
    # Change battler graphics
    @battler_name = $data_enemies[@enemy_id].battler_name
    @battler_hue = $data_enemies[@enemy_id].battler_hue
    # Remake action
    make_action
  end
  #--------------------------------------------------------------------------
  # * Make action speed again (?)
  #--------------------------------------------------------------------------
  def make_action_speed2(adj)
    @adj_speed = @current_action.speed if @adj_speed == nil
    @adj_speed = @adj_speed * adj / 100
  end
  #--------------------------------------------------------------------------
  # * Empty element set?
  #--------------------------------------------------------------------------
  def element_set2
    return []
  end
  #--------------------------------------------------------------------------
  # * Basic attack is magic?
  #--------------------------------------------------------------------------
  def magic_attack?
    BattleConfig::MAGIC_ATTACK_ENEMIES.include?(self.id)
  end
  #--------------------------------------------------------------------------
  # * Determine discovered status
  #--------------------------------------------------------------------------
  def inspected?
    return $game_system.enemies_inspected.include?(@enemy_id)
  end
  # Safety (unused)
  def threat
    5
  end
end
