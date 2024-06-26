#==============================================================================
# ** Game_Actor
#------------------------------------------------------------------------------
#  This class handles the actor. It's used within the Game_Actors class
#  ($game_actors) and refers to the Game_Party class ($game_party).
#==============================================================================

class Game_Actor < Game_Battler
  # Constant array for now. Will do math later as needed.
  ESSENCE_SLOTS = [nil, # 0 doesn't count
    3,  3,  3,  3,  4,  4,  4,  4,  4,  5,    # 1 - 10
    5,  5,  5,  6,  6,  6,  7,  7,  7,  8,   # 11 - 20
    8,  8,  8,  9,  9,  9, 10, 10, 10, 11,   # 21 - 30
    11, 11, 11, 12, 12, 12, 13, 13, 13, 14,   # 31 - 40
    14, 14, 15, 15, 15, 16, 16, 17, 17, 18,   # 41 - 50
    18, 18, 18, 19, 19, 20, 20, 21, 21, 22,   # 51 - 60
    22, 23, 23, 24, 24, 25, 25, 26, 26, 27,   # 61 - 70
    27, 27, 28, 28, 29, 29, 30, 31, 32, 33,   # 71 - 80
    34, 34, 35, 35, 36, 36, 37, 38, 39, 40,   # 81 - 90
    41, 42, 43, 44, 45, 46, 47, 48, 48        # 91 - 99
  ]
  MAX_ACTIVE_ESSENCE = 4
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor   :name                     # name
  attr_accessor :character_name           # character file name
  attr_reader   :character_hue            # character hue
  attr_reader   :class_id                 # class ID
  #attr_reader   :weapon_id                # weapon ID
  attr_reader   :armor1_id                # shield ID
  attr_reader   :armor2_id                # helmet ID
  attr_reader   :armor3_id                # body armor ID
  attr_reader   :armor4_id                # accessory ID
  # Additional Armors
  #attr_reader   :armor5_id                # accessory ID 2
  attr_reader   :armor6_id                # ?
  attr_reader   :armor7_id                # ?
  attr_reader   :level                    # level
  attr_reader   :exp                      # EXP
  attr_reader   :skills                   # skills
  # Essence management
  attr_reader   :essences       # Equipped abilities
  # EXP Management
  attr_accessor :old_exp
  attr_accessor :max_exp
  attr_accessor :plus_exp
  # Battle
  attr_accessor :actor_index # Record the actor's index in the party
  attr_accessor :actor_height # Character height px
  attr_accessor :two_swords_change # 2 Sword management
  attr_accessor :in_battle_team
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     actor_id : actor ID
  #--------------------------------------------------------------------------
  def initialize(actor_id)
    super()
    setup(actor_id)
  end
  #--------------------------------------------------------------------------
  # * Setup
  #     actor_id : actor ID
  #--------------------------------------------------------------------------
  def setup(actor_id)
    actor = $data_actors[actor_id]
    @actor_id = actor_id
    @name = Localization.localize("&MUI[Actor#{@actor_id}]")
    @character_name = actor.character_name
    @character_hue = actor.character_hue
    @battler_name = actor.battler_name
    @battler_hue = actor.battler_hue
    @class_id = actor.class_id
    @weapon_id = actor.weapon_id
    @armor1_id = actor.armor1_id
    @armor2_id = actor.armor2_id
    @armor3_id = actor.armor3_id
    @armor4_id = actor.armor4_id
    #@armor5_id = 0
    @level = actor.initial_level
    @exp_list = actor.exp_list
    @exp = @exp_list[@level]
    @skills = []
    @hp = maxhp
    @sp = maxsp
    @states = []
    @states_turn = {}
    @maxhp_plus = 0
    @maxsp_plus = 0
    @str_plus = 0
    @dex_plus = 0
    @agi_plus = 0
    @int_plus = 0
    # Learn skill
    for i in 1..@level
      for j in $data_classes[@class_id].learnings
        if j.level == i
          learn_skill(j.skill_id)
        end
      end
    end
    # Update auto state
    update_auto_state(nil, $data_armors[@armor1_id])
    update_auto_state(nil, $data_armors[@armor2_id])
    update_auto_state(nil, $data_armors[@armor3_id])
    update_auto_state(nil, $data_armors[@armor4_id])
    #update_auto_state(nil, $data_armors[@armor5_id]) # Accessory 2
    # Initialize equipped abilitites
    @essences = []
    @active_essences = []
    @in_battle_team = false
  end
  #--------------------------------------------------------------------------
  # * Get Actor ID
  #--------------------------------------------------------------------------
  def id
    return @actor_id
  end
  #--------------------------------------------------------------------------
  # * Get Actor Name
  #--------------------------------------------------------------------------
  def name
    # Localize actor names that aren't the player
    @name = Localization.localize("&MUI[#{$data_actors[@actor_id].name_loc_key}]") unless @actor_id == 1
    return @name
  end
  #--------------------------------------------------------------------------
  # * Get Description (* Separates newline)
  #--------------------------------------------------------------------------
  def description
    Localization.localize("&MUI[#{$data_actors[@actor_id].description_loc_key}]")
  end
  #--------------------------------------------------------------------------
  # * Get Index
  # This applies to the battle team only--use a custom call for all actors instead.
  #--------------------------------------------------------------------------
  def index
    return $game_party.actors.index(self)
  end
  #--------------------------------------------------------------------------
  # * Battle team conditional
  #--------------------------------------------------------------------------
  def in_battle_team?
    @in_battle_team
  end
  #--------------------------------------------------------------------------
  # * Set current exp
  #--------------------------------------------------------------------------
  def now_exp
    return @exp - @exp_list[@level]
  end
  #--------------------------------------------------------------------------
  # * Set ext exp
  #--------------------------------------------------------------------------
  def next_exp
    return @exp_list[@level + 1] > 0 ? @exp_list[@level+1] - @exp_list[@level] : 0
  end
  #--------------------------------------------------------------------------
  # * Get Element Revision Value
  #     element_id : element ID
  #--------------------------------------------------------------------------
  def element_rate(element_id)
    # Get values corresponding to element effectiveness
    table = BattleConfig::ELEMENT_RATES
    result = table[$data_classes[@class_id].element_ranks[element_id]]
    # If this element is protected by armor, then it's reduced by half
    for i in [@armor1_id, @armor2_id, @armor3_id, @armor4_id] #@armor5_id removed
      armor = $data_armors[i]
      if armor != nil and armor.guard_element_set.include?(element_id)
        result /= 2
      end
    end
    # If this element is protected by states, then it's reduced by half
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
    return $data_classes[@class_id].state_ranks
  end
  #--------------------------------------------------------------------------
  # * Determine State Guard
  #     state_id : state ID
  #--------------------------------------------------------------------------
  def state_guard?(state_id)
    for i in [@armor1_id, @armor2_id, @armor3_id, @armor4_id] #@armor5_id removed
      armor = $data_armors[i]
      if armor != nil
        if armor.guard_state_set.include?(state_id)
          return true
        end
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack Element
  #--------------------------------------------------------------------------
  def element_set
    weapon = $data_weapons[@weapon_id]
    return weapon != nil ? weapon.element_set : []
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack State Change (+)
  #--------------------------------------------------------------------------
  def plus_state_set
    weapon = $data_weapons[@weapon_id]
    return weapon != nil ? weapon.plus_state_set : []
  end
  #--------------------------------------------------------------------------
  # * Get Normal Attack State Change (-)
  #--------------------------------------------------------------------------
  def minus_state_set
    weapon = $data_weapons[@weapon_id]
    return weapon != nil ? weapon.minus_state_set : []
  end
  #--------------------------------------------------------------------------
  # * Get Maximum HP
  #--------------------------------------------------------------------------
  def maxhp
    n = [[base_maxhp + @maxhp_plus, 1].max, 9999].min
    for i in @states
      n *= $data_states[i].maxhp_rate / 100.0
    end
    n = [[Integer(n), 1].max, 9999].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Basic Maximum HP
  #--------------------------------------------------------------------------
  def base_maxhp
    n = $data_actors[@actor_id].parameters[0, @level]
    #weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id]
    #n += weapon != nil ? weapon.maxhp_plus : 0
    n += armor1 != nil ? armor1.maxhp_plus : 0
    n += armor2 != nil ? armor2.maxhp_plus : 0
    n += armor3 != nil ? armor3.maxhp_plus : 0
    n += armor4 != nil ? armor4.maxhp_plus : 0
    #n += armor5 != nil ? armor5.maxhp_plus : 0 # Accessory 2
    return [[n, 1].max, 9999].min
  end
  #--------------------------------------------------------------------------
  # * Get Basic Maximum SP
  #--------------------------------------------------------------------------
  def base_maxsp
    n = $data_actors[@actor_id].parameters[1, @level]
    #weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id]
    #n += weapon != nil ? weapon.maxsp_plus : 0
    n += armor1 != nil ? armor1.maxsp_plus : 0
    n += armor2 != nil ? armor2.maxsp_plus : 0
    n += armor3 != nil ? armor3.maxsp_plus : 0
    n += armor4 != nil ? armor4.maxsp_plus : 0
    #n += armor5 != nil ? armor5.maxsp_plus : 0 # Accessory 2
    return [[n, 1].max, 9999].min
  end
  #--------------------------------------------------------------------------
  # * Get Basic Luck
  #--------------------------------------------------------------------------
  def base_luk
    n = $data_actors[@actor_id].parameters[2, @level]
    weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id] # Accessory 2
    n += weapon != nil ? weapon.str_plus : 0
    n += armor1 != nil ? armor1.str_plus : 0
    n += armor2 != nil ? armor2.str_plus : 0
    n += armor3 != nil ? armor3.str_plus : 0
    n += armor4 != nil ? armor4.str_plus : 0
    #n += armor5 != nil ? armor5.str_plus : 0 # Accessory 2
    return [[n, 1].max, 999].min
  end
  alias base_str base_luk
  alias str luk
  #--------------------------------------------------------------------------
  # * Get Basic Dexterity
  #--------------------------------------------------------------------------
  def base_dex
    n = $data_actors[@actor_id].parameters[3, @level]
    weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id] # Accessory 2
    n += weapon != nil ? weapon.dex_plus : 0
    n += armor1 != nil ? armor1.dex_plus : 0
    n += armor2 != nil ? armor2.dex_plus : 0
    n += armor3 != nil ? armor3.dex_plus : 0
    n += armor4 != nil ? armor4.dex_plus : 0
    #n += armor5 != nil ? armor5.dex_plus : 0 # Accessory 2
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # * Get Basic Agility
  #--------------------------------------------------------------------------
  def base_agi
    n = $data_actors[@actor_id].parameters[4, @level]
    weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id] # Accessory 2
    n += weapon != nil ? weapon.agi_plus : 0
    n += armor1 != nil ? armor1.agi_plus : 0
    n += armor2 != nil ? armor2.agi_plus : 0
    n += armor3 != nil ? armor3.agi_plus : 0
    n += armor4 != nil ? armor4.agi_plus : 0
    #n += armor5 != nil ? armor5.agi_plus : 0 # Accessory 2
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # * Get Basic Intelligence
  #--------------------------------------------------------------------------
  def base_int
    n = $data_actors[@actor_id].parameters[5, @level]
    weapon = $data_weapons[@weapon_id]
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    #armor5 = $data_armors[@armor5_id] # Accessory 2
    n += weapon != nil ? weapon.int_plus : 0
    n += armor1 != nil ? armor1.int_plus : 0
    n += armor2 != nil ? armor2.int_plus : 0
    n += armor3 != nil ? armor3.int_plus : 0
    n += armor4 != nil ? armor4.int_plus : 0
    #n += armor5 != nil ? armor5.int_plus : 0 # Accessory 2
    return [[n, 1].max, 999].min
  end
  #--------------------------------------------------------------------------
  # * Get Basic Attack Power
  #--------------------------------------------------------------------------
  def base_atk
    n = 0
    for item in weapons.compact do n += item.atk end
    n = UNARMED_ATTACK if weapons[0] == nil && weapons[1] == nil 
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Basic Physical Defense
  #--------------------------------------------------------------------------
  def base_pdef
    n = 0
    for item in equips.compact do n += item.pdef end
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Basic Magic Defense
  #--------------------------------------------------------------------------
  def base_mdef
    n = 0
    for item in equips.compact do n += item.mdef end
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Basic Evasion Correction
  #--------------------------------------------------------------------------
  def base_eva
    n = 0
    for item in armors.compact do n += item.eva end
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Offensive Animation ID for Normal Attacks
  #--------------------------------------------------------------------------
  def animation1_id
    weapon = $data_weapons[@weapon_id]
    return weapon != nil ? weapon.animation1_id : 0
  end
  #--------------------------------------------------------------------------
  # * Get Target Animation ID for Normal Attacks
  #--------------------------------------------------------------------------
  def animation2_id
    weapon = $data_weapons[@weapon_id]
    return weapon != nil ? weapon.animation2_id : 0
  end
  #--------------------------------------------------------------------------
  # * Get Class Name
  #--------------------------------------------------------------------------
  def class_name
    return $data_classes[@class_id].loc_name
  end
  #--------------------------------------------------------------------------
  # * Get EXP String
  #--------------------------------------------------------------------------
  def exp_s
    return @exp_list[@level+1] > 0 ? @exp.to_s : "-------"
  end
  #--------------------------------------------------------------------------
  # * Get Next Level EXP String
  #--------------------------------------------------------------------------
  def next_exp_s
    return @exp_list[@level+1] > 0 ? @exp_list[@level+1].to_s : "-------"
  end
  #--------------------------------------------------------------------------
  # * Get Until Next Level EXP String
  #--------------------------------------------------------------------------
  def next_rest_exp_s
    return @exp_list[@level+1] > 0 ?
      (@exp_list[@level+1] - @exp).to_s : "-------"
  end
  #--------------------------------------------------------------------------
  # * Update Auto State
  #     old_armor : unequipped armor
  #     new_armor : equipped armor
  #--------------------------------------------------------------------------
  def update_auto_state(old_armor, new_armor)
    # Forcefully remove unequipped armor's auto state
    if old_armor != nil and old_armor.auto_state_id != 0
      remove_state(old_armor.auto_state_id, true)
    end
    # Forcefully add unequipped armor's auto state
    if new_armor != nil and new_armor.auto_state_id != 0
      add_state(new_armor.auto_state_id, true)
    end
  end
  #--------------------------------------------------------------------------
  # * Determine Fixed Equipment
  #     equip_type : type of equipment
  #--------------------------------------------------------------------------
  def equip_fix?(equip_type)
    case equip_type
    when 0  # Weapon
      return $data_actors[@actor_id].weapon_fix
    when 1  # Shield
      return $data_actors[@actor_id].armor1_fix
    when 2  # Head
      return $data_actors[@actor_id].armor2_fix
    when 3  # Body
      return $data_actors[@actor_id].armor3_fix
    when 4  # Accessory
      return $data_actors[@actor_id].armor4_fix
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Change Equipment
  #     equip_type : type of equipment
  #     id    : weapon or armor ID (If 0, remove equipment)
  #--------------------------------------------------------------------------
  def equip(equip_type, id)
    case equip_type
    when 0  # Weapon
      if id == 0 or $game_party.weapon_number(id) > 0
        $game_party.gain_weapon(@weapon_id, 1)
        @weapon_id = id
        $game_party.lose_weapon(id, 1)
      end
    when 1  # Shield
      if id == 0 or $game_party.armor_number(id) > 0
        update_auto_state($data_armors[@armor1_id], $data_armors[id])
        $game_party.gain_armor(@armor1_id, 1)
        @armor1_id = id
        $game_party.lose_armor(id, 1)
      end
    when 2  # Head
      if id == 0 or $game_party.armor_number(id) > 0
        update_auto_state($data_armors[@armor2_id], $data_armors[id])
        $game_party.gain_armor(@armor2_id, 1)
        @armor2_id = id
        $game_party.lose_armor(id, 1)
      end
    when 3  # Body
      if id == 0 or $game_party.armor_number(id) > 0
        update_auto_state($data_armors[@armor3_id], $data_armors[id])
        $game_party.gain_armor(@armor3_id, 1)
        @armor3_id = id
        $game_party.lose_armor(id, 1)
      end
    when 4  # Accessory
      if id == 0 or $game_party.armor_number(id) > 0
        update_auto_state($data_armors[@armor4_id], $data_armors[id])
        $game_party.gain_armor(@armor4_id, 1)
        @armor4_id = id
        $game_party.lose_armor(id, 1)
      end
    # when 5  # Accessory 2
    #   if id == 0 or $game_party.armor_number(id) > 0
    #     update_auto_state($data_armors[@armor5_id], $data_armors[id])
    #     $game_party.gain_armor(@armor5_id, 1)
    #     @armor5_id = id
    #     $game_party.lose_armor(id, 1)
    #   end
    end
  end
  #--------------------------------------------------------------------------
  # * Determine if Equippable
  #     item : item
  #--------------------------------------------------------------------------
  def equippable?(item)
    # If weapon
    if item.is_a?(RPG::Weapon)
      # If included among equippable weapons in current class
      if $data_classes[@class_id].weapon_set.include?(item.id)
        return true
      end
    end
    # If armor
    if item.is_a?(RPG::Armor)
      # If included among equippable armor in current class
      if $data_classes[@class_id].armor_set.include?(item.id)
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Get weapons
  #--------------------------------------------------------------------------
  def weapons
    return [$data_weapons[@weapon_id]]
  end
  #--------------------------------------------------------------------------
  # * Get armors
  #--------------------------------------------------------------------------
  def armors
    result = []
    result << $data_armors[@armor1_id]
    result << $data_armors[@armor2_id]
    result << $data_armors[@armor3_id]
    result << $data_armors[@armor4_id]
    #result << $data_armors[@armor5_id] # Accessory
    return result
  end
  #--------------------------------------------------------------------------
  # * Get all equipment
  #--------------------------------------------------------------------------
  def equips
    return weapons + armors
  end
  #--------------------------------------------------------------------------
  # * Determine if skill is learned
  #--------------------------------------------------------------------------
  def skill_id_learn?(skill_id)
    return @skills.include?(skill_id)
  end
  #--------------------------------------------------------------------------
  # * Change EXP
  #     exp : new EXP
  #--------------------------------------------------------------------------
  def exp=(exp)
    @exp = [exp, 0].max
    while @exp >= @exp_list[@level+1] and @exp_list[@level+1] > 0
      @level += 1
      for j in $data_classes[@class_id].learnings
        if j.level == @level
          learn_skill(j.skill_id)
        end
      end
    end
    # Allow for leveling down
    while @exp < @exp_list[@level]
      @level -= 1
    end
    @hp = [@hp, self.maxhp].min
    @sp = [@sp, self.maxsp].min
  end
  #--------------------------------------------------------------------------
  # * Change Level
  #     level : new level
  #--------------------------------------------------------------------------
  def level=(level)
    # Check up and down limits
    level = [[level, $data_actors[@actor_id].final_level].min, 1].max
    # Change EXP
    self.exp = @exp_list[level]
  end
  #--------------------------------------------------------------------------
  # * Learn Skill
  #     skill_id : skill ID
  #--------------------------------------------------------------------------
  def learn_skill(skill_id)
    if skill_id > 0 and not skill_learn?(skill_id)
      @skills.push(skill_id)
      @skills.sort!
    end
  end
  #--------------------------------------------------------------------------
  # * Forget Skill
  #     skill_id : skill ID
  #--------------------------------------------------------------------------
  def forget_skill(skill_id)
    @skills.delete(skill_id)
  end
  #--------------------------------------------------------------------------
  # * Determine if Finished Learning Skill
  #     skill_id : skill ID
  #--------------------------------------------------------------------------
  def skill_learn?(skill_id)
    return @skills.include?(skill_id)
  end
  #--------------------------------------------------------------------------
  # * Determine if Skill can be Used
  #     skill_id : skill ID
  #--------------------------------------------------------------------------
  def skill_can_use?(skill_id)
    if !skill_learn?(skill_id)
      return false
    end
    return super
  end
  #--------------------------------------------------------------------------
  # * Change Class ID
  #     class_id : new class ID
  #--------------------------------------------------------------------------
  def class_id=(class_id)
    if $data_classes[class_id] != nil
      @class_id = class_id
      # Remove items that are no longer equippable
      unless equippable?($data_weapons[@weapon_id])
        equip(0, 0)
      end
      unless equippable?($data_armors[@armor1_id])
        equip(1, 0)
      end
      unless equippable?($data_armors[@armor2_id])
        equip(2, 0)
      end
      unless equippable?($data_armors[@armor3_id])
        equip(3, 0)
      end
      unless equippable?($data_armors[@armor4_id])
        equip(4, 0)
      end
      # unless equippable?($data_armors[@armor5_id]) #Accessory 2
      #   equip(5, 0)
      # end
    end
  end
  #--------------------------------------------------------------------------
  # * Change Graphics
  #     character_name : new character file name
  #     character_hue  : new character hue
  #     battler_name   : new battler file name
  #     battler_hue    : new battler hue
  #--------------------------------------------------------------------------
  def set_graphic(character_name, character_hue, battler_name, battler_hue)
    @character_name = character_name
    @character_hue = character_hue
    @battler_name = battler_name
    @battler_hue = battler_hue
  end
  #--------------------------------------------------------------------------
  # * Change Only Character
  #     character_name : new character file name
  #--------------------------------------------------------------------------
  def set_character_graphic(character_name)
    @character_name = character_name
  end
  #--------------------------------------------------------------------------
  # * Get Battle Screen X-Coordinate
  #--------------------------------------------------------------------------
  # def screen_x
  #   # Return after calculating x-coordinate by order of members in party
  #   if self.index != nil
  #     return self.index * 160 + 80
  #   else
  #     return 0
  #   end
  # end
  # #--------------------------------------------------------------------------
  # # * Get Battle Screen Y-Coordinate
  # #--------------------------------------------------------------------------
  # def screen_y
  #   return 464
  # end
  #--------------------------------------------------------------------------
  # * Get Battle Screen Z-Coordinate
  #--------------------------------------------------------------------------
  def screen_z
    # Return after calculating z-coordinate by order of members in party
    if self.index != nil
      return 4 - self.index
    else
      return 0
    end
  end
  #==============================================================================
  # * Set the actor's starting positions in battle
  # ACTOR_POSITION is the arrangement of battlers relative to the first actor
  # !! Appears to run every frame...?
  #--------------------------------------------------------------------------
  def base_position
    base = BattleConfig.actor_position($game_party.actors.size)[self.index]
    @base_position_x = base[0] + BATTLEFIELD_CENTER[0]
    @base_position_y = base[1] + BATTLEFIELD_CENTER[1]
  end
  #--------------------------------------------------------------------------
  def position_x
    return 0 if self.index == nil
    return @base_position_x + @move_x
  end
  #--------------------------------------------------------------------------
  def position_y
    return 0 if self.index == nil
    return @base_position_y + @move_y + @jump
  end
  #--------------------------------------------------------------------------
  def position_z
    return 0 if self.index == nil
    return position_y + @move_z - @jump + 200
  end  
  #--------------------------------------------------------------------------
  # * Basic attack is magic?
  #--------------------------------------------------------------------------
  def magic_attack?
    @weapon_id != 0 && $data_weapons[@weapon_id].magic?
  end
  #--------------------------------------------------------------------------
  # * Begin guarding
  #--------------------------------------------------------------------------
  def start_hold
    if !@defense_pose && !self.input_selected? && !self.committed_action?
      self.defense_pose = true
      return true # Flag a change
    end
    false
  end
  #--------------------------------------------------------------------------
  # * Stop guarding
  #--------------------------------------------------------------------------
  def stop_hold
    if @defense_pose
      self.defense_pose = false
      return true # Flag the change
    end
    false
  end
  #============================================================================== 
  # * Unleash (overdrive) Functions
  #============================================================================== 
  def max_overdrive
    return Overdrive::MAX_OD
  end
  #--------------------------------------------------------------------------
  def overdrive
    return @overdrive == nil ? @overdrive = 0 : @overdrive
  end
  #--------------------------------------------------------------------------
  def overdrive=(n)
    @overdrive = [[n.to_i, 0].max, self.max_overdrive].min
  end
  #--------------------------------------------------------------------------
  def overdrive_full?
    return @overdrive >= self.max_overdrive
  end
  #--------------------------------------------------------------------------
  def overdrive_reset
    @overdrive = 0 if self.dead?
  end
  #--------------------------------------------------------------------------
  # * Calculate Threat
  # Threat is used to determine how likely an enemy is to target a given 
  # actor. The base value is set by their class, and further modulated by
  # current actions and equipped essences.
  #--------------------------------------------------------------------------  
  def threat
    # Get their base threat level, determined by class
    base = $data_classes[@class_id].base_threat
    modifier = 100
    # Determine factors based on current action type
    # Attacking : +50%
    if self.current_action && self.current_action.basic == :attack
      modifier += 50
    # Skill: +100%
    elsif self.current_action && self.current_action.kind == :skill
      modifier += 100
    # Holding +200%
    elsif self.holding?
      modifier += 200
    end
    # Factors based on state
    @states.each do |state_id|
      case state_id
      when 36, 37 # Reflect
        modifier += 600
      end
    end
    # Determine factors based on essence
    self.unique_essences do |essence, level|
      # To do
    end
    # Return the adjusted threat (min: 0, max: 30)
    (base * modifier / 100).clamp(0, 100)
  end
  #============================================================================== 
  # ** Essence Functions
  #--------------------------------------------------------------------------
  # * Determine if Essence can be Equipped
  # Returns true if equippable, otherwise returns the error string.
  #--------------------------------------------------------------------------  
  def essence_equippable?(essence_id)
    essence_qty = $game_party.number_all_essence(essence_id)
    essence_obj = $data_essences[essence_id]
    # Not equippable if nil or 0 quantity
    if essence_qty.nil? || essence_qty < 1
      return 1
    end
    # The actor has no free slots
    if @essences.size >= self.essence_slots
      return 2
    end
    # The actor already has the maximum equippable number available
    if num_essence_equipped(essence_id) >= essence_obj.max_level
      return 3
    end
    # The actor cannot equip any more active essences
    if !active_essence_equippable?(essence_id)
      return 4
    end
    # It's equippable
    true
  end

  # REDACTED

  #--------------------------------------------------------------------------
  # * Strip Party Member
  # Removes a party member's equipment and essence and returns it to the party
  #--------------------------------------------------------------------------
  def strip
    # Don't run if actor isn't in the party
    unless $game_party.actors.include?(self)
      puts "Actor not in party!"
      return
    end
    # Essences 
    @essences.dup.each do |essence_id|
      unequip_essence(essence_id)
    end
    # Equipment
    5.times do |equip_type|
      # Don't touch locked equipment
      next if equip_fix?(equip_type)
      equip(equip_type, 0)
    end
  end
end