#==============================================================================
# ** Game_BattleAction
#------------------------------------------------------------------------------
#  This class handles actions in battle. It's used within the Game_Battler 
#  class.
#==============================================================================

class Game_BattleAction
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :speed                    # speed
  attr_reader :kind                     # kind (basic / skill / item)
  attr_reader :basic                    # basic (attack / guard / escape / none)
  attr_accessor :skill_id                 # skill ID
  attr_accessor :item_id                  # item ID
  attr_accessor :target_index             # target index
  attr_accessor :forcing                  # forced flag
  # Enemy use only
  attr_accessor :weapon_id 
  attr_accessor :behavior
  attr_accessor :condition_custom
  attr_accessor :custom_params
  # Get action names
  attr_reader :name
  attr_reader :name_detail
  # Correct integers to symbols (index = original integer from vanilla xp)
  KIND_TO_SYM = [:basic, :skill, :item]
  BASIC_TO_SYM = [:attack, :guard, :escape, :none]
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    clear
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    @speed = 0
    @kind = :basic
    @basic = :none
    @skill_id = 0
    @item_id = 0
    @target_index = -1
    @forcing = false
    @weapon_id = 0
    @behavior = :default
    @condition_custom = nil
    @custom_params = []
  end
  #--------------------------------------------------------------------------
  # * Setup from a database action (enemies)
  #--------------------------------------------------------------------------
  def setup(db_action)
    @kind = db_action.kind
    @basic = db_action.basic
    @skill_id = db_action.skill_id
    @item_id = db_action.item_id
    @weapon_id = db_action.weapon_id
    @behavior = db_action.behavior
  end
  #--------------------------------------------------------------------------
  # * Is (valid) Skill?
  #--------------------------------------------------------------------------
  def skill?
    @kind == :skill && @skill_id != 0
  end
  #--------------------------------------------------------------------------
  # * Is (valid) Item?
  #--------------------------------------------------------------------------
  def item?
    @kind == :item && @item_id != 0
  end
  #--------------------------------------------------------------------------
  # * Needs target?
  # Determinent for an action that should have more than 0 targets
  #--------------------------------------------------------------------------
  def needs_target?
    skill? || item? || (@kind == :basic && @basic == :attack)
  end
  #--------------------------------------------------------------------------
  # * Compare two actions
  #--------------------------------------------------------------------------
  def same_as?(other)
    return (@basic == other.basic && @kind == other.kind)
  end
  #--------------------------------------------------------------------------
  # * Determine Validity
  #--------------------------------------------------------------------------
  def valid?
    return !(@kind == :basic && @basic == :none)
  end
  #--------------------------------------------------------------------------
  # * Kind assignment (catch integers)
  #--------------------------------------------------------------------------
  def kind=(value)
    if value.is_a?(Integer)
      value = KIND_TO_SYM[value]
    end
    @kind = value
  end
  #--------------------------------------------------------------------------
  # * Basic assignment (catch integers)
  #--------------------------------------------------------------------------
  def basic=(value)
    if value.is_a?(Integer)
      value = BASIC_TO_SYM[value]
    end
    @basic = value
  end
  #--------------------------------------------------------------------------
  # * Determine if for One Ally
  #--------------------------------------------------------------------------
  def for_one_friend?
    # If kind = skill, and effect scope is for ally (including 0 HP)
    if @kind == :skill && [3, 5].include?($data_skills[@skill_id].scope)
      return true
    end
    # If kind = item, and effect scope is for ally (including 0 HP)
    if @kind == :item && [3, 5].include?($data_items[@item_id].scope)
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Determine if for One Ally (HP 0)
  #--------------------------------------------------------------------------
  def for_one_friend_hp0?
    # If kind = skill, and effect scope is for ally (only 0 HP)
    if @kind == :skill && $data_skills[@skill_id].scope == 5
      return true
    end
    # If kind = item, and effect scope is for ally (only 0 HP)
    if @kind == :item && $data_items[@item_id].scope == 5
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Random Target (for Actor)
  #--------------------------------------------------------------------------
  def decide_random_target_for_actor
    # Diverge with effect scope
    if for_one_friend_hp0?
      battler = $game_party.random_target_actor_hp0
    elsif for_one_friend?
      battler = $game_party.random_target_actor
    else
      battler = $game_troop.random_target_enemy
    end
    # If a target exists, get an index, and if a target doesn't exist,
    # clear the action
    if battler != nil
      @target_index = battler.index
    else
      clear
    end
  end
  #--------------------------------------------------------------------------
  # * Random Target (for Enemy)
  #--------------------------------------------------------------------------
  def decide_random_target_for_enemy
    # Diverge with effect scope
    if for_one_friend_hp0?
      battler = $game_troop.random_target_enemy_hp0
    elsif for_one_friend?
      battler = $game_troop.random_target_enemy
    else
      battler = $game_party.random_target_actor
    end
    # If a target exists, get an index, and if a target doesn't exist,
    # clear the action
    if battler != nil
      @target_index = battler.index
    else
      clear
    end
  end
  #--------------------------------------------------------------------------
  # * Last Target (for Actor)
  #--------------------------------------------------------------------------
  def decide_last_target_for_actor
    # If effect scope is ally, then it's an actor, anything else is an enemy
    if @target_index == -1
      battler = nil
    elsif for_one_friend?
      battler = $game_party.actors[@target_index]
    else
      battler = $game_troop.enemies[@target_index]
    end
    # Clear action if no target exists
    if battler == nil || !battler.exist?
      clear
    end
  end
  #--------------------------------------------------------------------------
  # * Last Target (for Enemy)
  #--------------------------------------------------------------------------
  def decide_last_target_for_enemy
    # If effect scope is ally, then it's an enemy, anything else is an actor
    if @target_index == -1
      battler = nil
    elsif for_one_friend?
      battler = $game_troop.enemies[@target_index]
    else
      battler = $game_party.actors[@target_index]
    end
    # Clear action if no target exists
    if battler == nil || !battler.exist?
      clear
    end
  end
  #--------------------------------------------------------------------------
  # * Method to allow icon name return on actions
  # detailed - true / false value to determine if detailed
  # skill information is allowed 
  #--------------------------------------------------------------------------  
  def icon
    case @kind
    when :basic #basic
      case @basic
        when :attack
          'Battle/Attack'
        when :guard
          'Battle/Hold'
        when :escape
          ''
        else
          ''
      end
    when :skill # skill
      return '' if @skill_id == 0
      skill = $data_skills[@skill_id]
      skill_name = skill.name
      # Use the ATOA command skills to determine if it's a spell, skill, etc
      if skill.has_extension?(:TYPE_UNLEASH)
        'Battle/Unleash'
      elsif skill.magic?
        'Battle/Spell'
      elsif !skill.magic?
        'Battle/Ability'
      else
        # Catch
        'Battle/Ability'
      end
    when :item # item
      return '' if @item_id == 0
      'Battle/Item'
    else
      return ''
    end
  end
  #--------------------------------------------------------------------------
  # * Method to record balloon animation gifs
  #--------------------------------------------------------------------------  
  def balloon
    return '' if $game_switches[10]
    case @kind
    when :basic #basic
      case @basic
        when :attack
          'Attack_Balloon'
        when :guard
          'Guard_Balloon'
        when :escape
          'Failed_Balloon'
        else
          'Idle_Balloon'
      end
    when :skill # skill
      return '' if @skill_id == 0
      skill = $data_skills[@skill_id]
      skill_name = skill.name
      # Use the ATOA command skills to determine if it's a spell, skill, etc
      if skill.has_extension?(:TYPE_UNLEASH)
        'Unleash_Balloon'
      elsif skill.magic?
        'Spell_Balloon'
      elsif !skill.magic?
        'Ability_Balloon'
      else
        # Catch
        'Ability_Balloon'
      end
    when :item # item
      return '' if @item_id == 0
      'Item_Balloon'
    else
      return ''
    end
  end
  #--------------------------------------------------------------------------
  # * Print method
  #--------------------------------------------------------------------------
  def to_s
    return "#{@kind} | #{@basic} | Skill: #{@skill_id} | Item: #{@item_id} | Force? #{@forcing} | TIndex: #{@target_index}"
  end
end
