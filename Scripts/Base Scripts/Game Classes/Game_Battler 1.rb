#==============================================================================
# ** Game_Battler (part 1)
# Initialization, getters, settters and checks
#------------------------------------------------------------------------------
#  This class deals with battlers. It's used as a superclass for the Game_Actor
#  and Game_Enemy classes.
#==============================================================================
module BattleConfig; end

class Game_Battler
  # Include Battle Configuration method
  include BattleConfig
  #--------------------------------------------------------------------------
  # * Constants
  #--------------------------------------------------------------------------
  STAT_MAX = 999
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :battler_name             # battler file name
  attr_reader   :battler_hue              # battler hue
  attr_reader   :hp                       # HP
  attr_reader   :sp                       # SP
  attr_reader   :states                   # states
  attr_accessor :hidden                   # hidden flag
  attr_accessor :immortal                 # immortal flag
  attr_accessor :damage_pop               # damage display flag
  attr_accessor :damage                   # damage value
  attr_accessor :sp_absorb                # sp absorption value
  attr_accessor :hp_absorb                # hp absorption value
  attr_accessor :critical                 # critical flag
  attr_accessor :animation_id             # animation ID
  attr_accessor :animation_hit            # animation hit flag
  attr_accessor :white_flash              # white flash flag
  attr_accessor :blink                    # blink flag
  attr_accessor   :weapon_id                # weapon ID
  #--------------------------------------------------------------------------
  # Sideview Battlers
  #
  attr_accessor :dmg_type # Replaces SP Damage
  attr_accessor :collapse
  attr_accessor :move_x
  attr_accessor :move_y
  attr_accessor :move_z
  attr_accessor :jump
  attr_accessor :animating
  attr_accessor :non_dead
  attr_accessor :slip_damage
  attr_accessor :linked_skill_id
  attr_accessor :individual
  attr_accessor :play
  attr_accessor :force_action
  attr_accessor :temp_action # Temporary action saved (but not applied) to enemies
  attr_accessor :force_target
  attr_accessor :revival
  attr_accessor :reflex
  attr_accessor :absorb
  attr_accessor :anime_mirror
  attr_accessor :dying
  attr_accessor :state_animation_id
  attr_accessor :dead_anim
  attr_accessor :missed
  attr_accessor :evaded
  attr_accessor :true_immortal
  attr_accessor :defense_pose
  attr_accessor :inputting
  attr_accessor :skilling
  attr_reader   :base_position_x
  attr_reader   :base_position_y  
  attr_accessor :state_changes # Hash of added/removed states {id => :add, id => :lose}
  attr_accessor :targets
  attr_accessor :last_target
  #--------------------------------------------------------------------------
  # ATB Related
  #
  #attr_accessor :now_atp
  attr_accessor :atp
  attr_accessor :roll_atp # Point at which an enemy will actually commit an action
  #attr_accessor :full_atp
  attr_accessor :countup
  attr_accessor :movable_backup
  #attr_accessor :input_selected   # Determines if battler has selected an input
  #attr_accessor :committed_action # Specifically for enemies, flags if they are committed to an action
  # Specific action restriction
  attr_accessor :attack_disabled
  attr_accessor :hold_disabled
  attr_accessor :items_disabled
  attr_accessor :skills_disabled
  attr_accessor :temp_member # Temporary battler (can only have forced actions)
  attr_accessor :targeted # Flag battler as being targeted (for visual updates)
  attr_accessor :action_count # Total actions the battler has taken so far in battle
                              # Used in place of "turn counts" for enemies, since turns do not exist
                              # Not currently used for actors
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @battler_name = ""
    @battler_hue = 0
    @hp = 0
    @sp = 0
    @states = []
    @states_turn = {}
    @maxhp_plus = 0
    @maxsp_plus = 0
    @luk_plus = 0
    @dex_plus = 0
    @agi_plus = 0
    @int_plus = 0
    @hidden = false
    @immortal = false
    @damage_pop = false
    @damage = nil
    @critical = false
    @animation_id = 0
    @animation_hit = false
    @white_flash = false
    @blink = false
    @current_action = Game_BattleAction.new
    @temp_action = nil
    @temp_member = false
    # Sideview Battlers
    reset
  end
  #--------------------------------------------------------------------------
  # ● Full Battler Reset
  # (Called at the start of battle)
  #--------------------------------------------------------------------------
  def reset
    @move_x = @move_y = @move_z = @plus_y = @jump = @linked_skill_id = 0
    @force_action = @force_target = 0 #@base_position_x = @base_position_y = 0
    @absorb = @play = @now_state = @state_frame = @state_animation_id = 0
    @hp_absorb = @sp_absorb = 0
    @animating = @non_dead = @individual = @slip_damage = @revival = @inputting = @skilling = false
    @collapse = @anime_mirror = @dying = @defense_pose = @blink = false
    @dmg_type = :hp
    @evaded = @missed = false
    @state_changes = {}
    @anim_states = []
    @attack_disabled = false
    @hold_disabled = false
    @items_disabled = false
    @skills_disabled = false
    @last_target = nil
    @targets = []
    @targeted = false
    @action_count = 1
    # ATB
    # @now_atp = 0
    # @roll_atp = 0
    # @full_atp = false
    # @input_selected = false
    # @committed_action = false
  end
  #--------------------------------------------------------------------------
  # ● Basic battler reset
  # Called at the end of each sprite action
  #--------------------------------------------------------------------------
  def reset_basic
    @move_x = @move_y = @move_z = @jump = @linked_skill_id = 0
    @animating = @non_dead = @individual = false
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
  # * Get Maximum SP
  #--------------------------------------------------------------------------
  def maxsp
    n = [[base_maxsp + @maxsp_plus, 0].max, 9999].min
    for i in @states
      n *= $data_states[i].maxsp_rate / 100.0
    end
    n = [[Integer(n), 0].max, 9999].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Luck
  # !!! Luck has taken strength's slot in the DB !!!
  # In all contexts where Luck must be accessed from $data, 
  # it will be referred to as STR instead.
  #--------------------------------------------------------------------------
  def luk
    n = [[base_luk + @luk_plus, 1].max, STAT_MAX].min
    for i in @states
      n *= $data_states[i].str_rate / 100.0
    end
    n = [[Integer(n), 1].max, STAT_MAX].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Dexterity (DEX)
  #--------------------------------------------------------------------------
  def dex
    n = [[base_dex + @dex_plus, 1].max, STAT_MAX].min
    for i in @states
      n *= $data_states[i].dex_rate / 100.0
    end
    n = [[Integer(n), 1].max, STAT_MAX].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Agility (AGI)
  #--------------------------------------------------------------------------
  def agi
    n = [[base_agi + @agi_plus, 1].max, STAT_MAX].min
    for i in @states
      n *= $data_states[i].agi_rate / 100.0
    end
    n = [[Integer(n), 1].max, STAT_MAX].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Get Intelligence (INT)
  #--------------------------------------------------------------------------
  def int
    n = [[base_int + @int_plus, 1].max, STAT_MAX].min
    for i in @states
      n *= $data_states[i].int_rate / 100.0
    end
    n = [[Integer(n), 1].max, STAT_MAX].min
    return n
  end
  #--------------------------------------------------------------------------
  # * Set Maximum HP
  #     maxhp : new maximum HP
  #--------------------------------------------------------------------------
  def maxhp=(maxhp)
    @maxhp_plus += maxhp - self.maxhp
    @maxhp_plus = [[@maxhp_plus, -9999].max, 9999].min
    @hp = [@hp, self.maxhp].min
  end
  #--------------------------------------------------------------------------
  # * Set Maximum SP
  #     maxsp : new maximum SP
  #--------------------------------------------------------------------------
  def maxsp=(maxsp)
    @maxsp_plus += maxsp - self.maxsp
    @maxsp_plus = [[@maxsp_plus, -9999].max, 9999].min
    @sp = [@sp, self.maxsp].min
  end
  #--------------------------------------------------------------------------
  # * Set Luck
  #--------------------------------------------------------------------------
  def luk=(luk)
    @luk_plus += luk - self.luk
    @luk_plus = [[@luk_plus, -STAT_MAX].max, STAT_MAX].min
  end
  #--------------------------------------------------------------------------
  # * Set Dexterity (DEX)
  #     dex : new Dexterity (DEX)
  #--------------------------------------------------------------------------
  def dex=(dex)
    @dex_plus += dex - self.dex
    @dex_plus = [[@dex_plus, -STAT_MAX].max, STAT_MAX].min
  end
  #--------------------------------------------------------------------------
  # * Set Agility (AGI)
  #     agi : new Agility (AGI)
  #--------------------------------------------------------------------------
  def agi=(agi)
    @agi_plus += agi - self.agi
    @agi_plus = [[@agi_plus, -STAT_MAX].max, STAT_MAX].min
  end
  #--------------------------------------------------------------------------
  # * Set Intelligence (INT)
  #     int : new Intelligence (INT)
  #--------------------------------------------------------------------------
  def int=(int)
    @int_plus += int - self.int
    @int_plus = [[@int_plus, -STAT_MAX].max, STAT_MAX].min
  end
  #--------------------------------------------------------------------------
  # * Get Hit Rate
  #--------------------------------------------------------------------------
  def hit
    n = 100
    for i in @states
      n *= $data_states[i].hit_rate / 100.0
    end
    return Integer(n)
  end
  #--------------------------------------------------------------------------
  # * Get Attack Power
  #--------------------------------------------------------------------------
  def atk
    n = base_atk
    for i in @states
      n *= $data_states[i].atk_rate / 100.0
    end
    return Integer(n)
  end
  #--------------------------------------------------------------------------
  # * Get Physical Defense Power
  #--------------------------------------------------------------------------
  def pdef
    n = base_pdef
    for i in @states
      n *= $data_states[i].pdef_rate / 100.0
    end
    return Integer(n)
  end
  #--------------------------------------------------------------------------
  # * Get Magic Defense Power
  #--------------------------------------------------------------------------
  def mdef
    n = base_mdef
    for i in @states
      n *= $data_states[i].mdef_rate / 100.0
    end
    return Integer(n)
  end
  #--------------------------------------------------------------------------
  # * Get Evasion Correction
  #--------------------------------------------------------------------------
  def eva
    n = base_eva
    for i in @states
      n += $data_states[i].eva
    end
    return n
  end
  #--------------------------------------------------------------------------
  # * Change HP
  #     hp : new HP
  #--------------------------------------------------------------------------
  def hp=(hp)
    @hp = [[hp, maxhp].min, 0].max
    # add or exclude incapacitation
    for i in 1...$data_states.size
      if $data_states[i].zero_hp
        if self.dead?
          add_state(i)
        else
          remove_state(i)
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Change SP
  #     sp : new SP
  #--------------------------------------------------------------------------
  def sp=(sp)
    @sp = [[sp, maxsp].min, 0].max
  end
  #--------------------------------------------------------------------------
  # * Recover All
  #--------------------------------------------------------------------------
  def recover_all
    @hp = maxhp
    @sp = maxsp
    for i in @states.clone
      remove_state(i)
    end
  end
  #--------------------------------------------------------------------------
  # * Change base (starting) x/y coordinates
  #--------------------------------------------------------------------------
  def change_base_position(x, y)
    @base_position_x = x
    @base_position_y = y
  end
  #--------------------------------------------------------------------------
  # * Get Screen X-Coordinates
  #--------------------------------------------------------------------------
  def screen_x
    return Camera.calc_zoomed_x(@base_position_x)
  end
  #--------------------------------------------------------------------------
  # * Get Screen Y-Coordinates
  #--------------------------------------------------------------------------
  def screen_y
    return Camera.calc_zoomed_y(@base_position_y - 32)
  end
  #--------------------------------------------------------------------------
  # * Perform collapse
  #--------------------------------------------------------------------------
  def perform_collapse
    if $game_temp.in_battle && dead?
      # Determine actor or enemy
      if actor?
        @non_repeat = true
        $game_system.se_play($data_system.actor_collapse_se) 
        #@force_action = ANIME["ACTOR_COLLAPSE"]
      else
        @force_action = [:enemy_collapse]
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Get Current Action
  #--------------------------------------------------------------------------
  def current_action
    return @current_action
  end
  #--------------------------------------------------------------------------
  # * Determine Action Speed
  #--------------------------------------------------------------------------
  def make_action_speed
    @current_action.speed = agi + rand(10 + agi / 4)
  end
  #--------------------------------------------------------------------------
  # * Decide Incapacitation
  # Because "immortal" is used for hit frames, this should be "true immortal"
  #--------------------------------------------------------------------------
  def dead?
    return (@hp == 0 && !@true_immortal)
  end
  #--------------------------------------------------------------------------
  # * Decide Existance
  # Because "immortal" is used for hit frames, this should be "true immortal"
  #--------------------------------------------------------------------------
  def exist?
    return (!@hidden && (@hp > 0 or @true_immortal))
  end
  #--------------------------------------------------------------------------
  # * Decide HP 0
  #--------------------------------------------------------------------------
  def hp0?
    return (!@hidden && @hp == 0)
  end
  #--------------------------------------------------------------------------
  # * Decide if Command is Inputable
  #--------------------------------------------------------------------------
  def inputable?
    return (!@hidden && restriction <= 1)
  end
  #--------------------------------------------------------------------------
  # * Decide if Action is Possible
  #--------------------------------------------------------------------------
  def movable?
    return (!@hidden && restriction < 4)
  end
  #--------------------------------------------------------------------------
  # * Decide if Attacking is allowed
  #--------------------------------------------------------------------------
  def attack_allowed?
    !@attack_disabled && restriction != 4
  end
  #--------------------------------------------------------------------------
  # * Decide if Skills are allowed
  #--------------------------------------------------------------------------
  def skills_allowed?
    restriction != 4 && restriction != 1 && !@skills_disabled
  end
  #--------------------------------------------------------------------------
  # * Decide if Items are allowed
  #--------------------------------------------------------------------------
  def items_allowed?
    !@items_disabled && restriction != 4
  end
  #--------------------------------------------------------------------------
  # * Decide if Holding is allowed
  #--------------------------------------------------------------------------
  def hold_allowed?
    !@hold_disabled && restriction != 4
  end
  #--------------------------------------------------------------------------
  # * Decide if Guarding
  #--------------------------------------------------------------------------
  def guarding?
    return (@current_action.kind == :basic && @current_action.basic == :guard)
  end
  #--------------------------------------------------------------------------
  # * Decide if Holding
  #--------------------------------------------------------------------------
  def holding?
    return actor? && @defense_pose
  end
  #--------------------------------------------------------------------------
  # * Is Actor?
  #--------------------------------------------------------------------------
  def actor?
    self.is_a?(Game_Actor)
  end
  #--------------------------------------------------------------------------
  # * Is Enemy?
  #--------------------------------------------------------------------------
  def enemy?
    self.is_a?(Game_Enemy)
  end
  #--------------------------------------------------------------------------
  # * Determine if battler is in danger (1/4 hp)
  #--------------------------------------------------------------------------
  def in_danger?
    return @hp <= self.maxhp / 4
  end
  #--------------------------------------------------------------------------
  # * Determine if battler has low hp (1/2 hp)
  #--------------------------------------------------------------------------
  def low_hp?
    return @hp < self.maxhp / 2
  end
  #--------------------------------------------------------------------------
  # * Determine if battler is dying
  #--------------------------------------------------------------------------
  def collapsing?
    return @collapse
  end
  #--------------------------------------------------------------------------
  # * Determine if battler is inputting a command
  #--------------------------------------------------------------------------
  def inputting?
    return @inputting
  end
  #--------------------------------------------------------------------------
  # * Determine if using a skill
  #--------------------------------------------------------------------------
  def skilling?
    return @skilling
  end
  #--------------------------------------------------------------------------
  # * Determine if being targeted
  #--------------------------------------------------------------------------
  def targeted?
    return @targeted
  end
  #--------------------------------------------------------------------------
  # ● Make the battler a temporary member (invincible, no actions allowed)
  #--------------------------------------------------------------------------
  def make_temporary(bool)
    @temp_member = bool
    @countup = !bool
    @true_immortal = bool
  end
end
