#==============================================================================
# Sideview Battle System Configurations Version 2.5xp
#==============================================================================
#  Reorganized and Revamped by Jaiden
#     Specifically for the Elemental Engine
#  Original Script by: 
#               Enu (http://rpgex.sakura.ne.jp/home/)
#  Conversion to XP by:
#               Atoa
#  Original translation versions by: 
#               Kylock
#  Translation continued by:
#               Mr. Bubble
#  XP version Translation by:
#               cairn
#  Special thanks:
#               Shu (for translation help)
#               Moonlight (for her passionate bug support for this script)
#               NightWalker (for his community support for this script)
#               XRXS (for the script of damage gravity, which was modified and 
#                     used as the system's base of damage exibition)
#               Squall (for the FF styled damage script, which was modified
#                       and added to the damage exibition system)
#               KGC (for the STBreaker script, which was the base for the 
#                    attribute limit system)
#               Herena Isaberu (for her support in XP version bug fixes)
#               Enu (for making an awesome battle system)
#==============================================================================

#==============================================================================
# ■ module BattleConfig
#------------------------------------------------------------------------------
#  Sideview Battle System Config
#==============================================================================
module BattleConfig
 #--------------------------------------------------------------------------
 # * Key Bindings
 # These are input constants used for each particular battle action,
 # useful for quickly changing bindings during testing
 #-------------------------------------------------------------------------- 
  BATTLE_INPUT = {
    Slow_Down: Input::L,
    Speed_Up: Input::R,
    Confirm: Input::C,
    Back: Input::B,
    Attack: Input::DOWN,
    Hold: Input::RIGHT,
    Skill: Input::LEFT,
    Item: Input::UP,
    Actor_Back: Input::A,
    Actor_Forward: Input::Z,
    Pause: Input::PAUSE
  }
  #--------------------------------------------------------------------------
  # * Party member starting positions
  # Positions of battlers, calculated from the battlefield CENTER
  #-------------------------------------------------------------------------- 
  def self.actor_position(party_size)
    case party_size
    when 1
      [[96,0]]
      #[[74,14]]
    when 2
      #return [[96,-16],[136,16]]
      [[104,-12],[150,12]]
      #[[62,28],[116,8]]
    when 3
      #return [[96,-32],[128,0],[164,32]]
      [[80,-24],[120,0],[160,24]]
      #[[62,32],[116,12],[168,-4]] 
    # Temporary catch for party > 3
    when 4
      [[80,-24],[120,0],[160,24],[0,0]]
    when 5
      [[80,-24],[120,0],[160,24],[0,0],[0,0]]
    end
  end
  #--------------------------------------------------------------------------
  # * Camera Setup
  # Constants utilized for battle screen / camera 
  #-------------------------------------------------------------------------- 
  # Battlefield setup
  BATTLEFIELD_WIDTH = 720 * 2
  BATTLEFIELD_HEIGHT = 440 * 2
  BATTLEFIELD_CENTER = [BATTLEFIELD_WIDTH / 4, BATTLEFIELD_HEIGHT / 4 + 60]
  # Speed at which the camera zooms in and out
  ZOOM_INCREMENT = 4
  # Default # of frames for the camera to move
  CAMERA_SPEED = 30
  # Max movement from center to constrain (+/-)
  # This value is multiplied by the current zoom ratio
  MIN_CAMERA_X = 18
  MAX_CAMERA_X = 18
  MIN_CAMERA_Y = 3
  MAX_CAMERA_Y = 2
  # Offset bb graphic (added)
  BATTLEBACK_Y_OFFSET = 20
  #--------------------------------------------------------------------------
  # * Action Delay Times (SECONDS)
  #-------------------------------------------------------------------------- 
  # Delay time before a battler starts an action
  ACTION_START_WAIT = 0.125
  # Delay time after a battler completes an action
  ACTION_WAIT = 0.25
  # Delay time before enemy collapse (defeat of enemy)
  COLLAPSE_WAIT = 1
  # Delay before victory is processed 
  WIN_WAIT = 0.5
  #--------------------------------------------------------------------------
  # * Animation Configuration
  #--------------------------------------------------------------------------
  # These values are for manual battler animation instead of GIFs
  # Battler horizontal frame count
  ANIME_PATTERN = 4
  # Battler vertical frame count
  ANIME_KIND = 4
  # Animation ID for any unarmed attack.
  NO_WEAPON = 11
  # Auto-Life State: Revivial Animation ID
  RES_ANIM_ID = 34
  # Animation ID for Casting State
  CASTING_ANIM = 70
  CASTING_END_ANIM = 69
  # Number of frames to delay between looping animations
  STATE_LOOP_DELAY = 120
  # Toggle shadow display under all battlers
  SHADOW = true
  # Animation IDs for slip damage
  HP_SLIP_ANIM_ID = 0
  SP_SLIP_ANIM_ID = 0
  HP_ABSORB_ANIM_ID = 117
  SP_ABSORB_ANIM_ID = 118
  #--------------------------------------------------------------------------
  # * Algorithm / Damage Calculation Constants
  # These are all in Game_Battler 3 !
  #-------------------------------------------------------------------------- 
  # Damage Constants
  # These tweak the damage value from attacks and skills 
  ACTOR_ATTACK_CONST = 10 # Damage is divided by this number minus the actors level for an exp growth curve
  ENEMY_ATTACK_CONST = 10 # Enemy ATK is multiplied by this number
  SKILL_POWER_CONST = 20 # Power is divided by this value to temper damage amounts
                         # higher = less damage overall
  # Defense percentages
  # Actor-weighted, these are the max % damage reduced based on points of defense
  ACTOR_ATK_DEF_PERCENT = 60
  ENEMY_ATK_DEF_PERCENT = 50
  SKILL_MAX_DEF_REDUCE = 90
  LUCK_HIT_PERCENT = 50      # Max boost (%) to current hitrate based on luck
  LUCK_EE_ENHANCE = 50       # Maximum enhancement (%) to elemental efficiency from Luck
  ACTOR_GUARD_PERCENT = [60, 95] # Min,max percent damage stopped when guarding
  ENEMY_GUARD_PERCENT = [40, 75] # Min,max percent damage stopped when guarding
  CRIT_LUCK_RATE_MIN = 25  # Minimum (.1 percent) crit rate
  CRIT_LUCK_RATE_MAX = 250  # Maximum (.1 percent) crit rate
  CRIT_DMG_BASE = 175
  AGI_DODGE_PERCENT = 50     # Max dodge rate (percent) based on agility
  DAMAGE_VARIANCE = 3       # Percent to vary damage for normal attacks
  #-------------------------------------------------------------------------- 
  # Character unarmed attack power
  UNARMED_ATTACK = 10
  # Enemy IDs whose standard attack is magic damage based
  MAGIC_ATTACK_ENEMIES = []
  # Amount healed when holding %
  HOLD_HP_HEAL = 4
  HOLD_SP_HEAL = 7
  # 0.1 %
  HOLD_HEAL = 80
  # Elemental effectiveness ratings
  # Multiplier: 1.35x, 1.15x, 1x, 0.75x, 0.30x, 0x
  # Slightly changed from default, removing the "heal" effect from F and making it null instead
  # If an element is to heal, this should be calculated later with a flag
  #                -  A   B   C   D   E  F
  ELEMENT_RATES = [0,150,130,100, 80, 30,0]
  #--------------------------------------------------------------------------
  # * Text Configuration (TODO Strings need to be localized)
  #-------------------------------------------------------------------------- 
  # POP Window indicator words.  For no word results, use "".
  POP_MISS    = '&MUI[BattleMiss]'       # Attack missed　
  POP_EVA     = '&MUI[BattleEvade]'       # Attack avoided
  POP_CRI     = '&MUI[BattleCrit]'    # Attack scored a critical hit
  # Damage text colors
  DEFAULT_COLOR  = Color.new(255, 255, 255)
  HP_REC_COLOR   = Color.new(176, 255, 144)
  SP_DMG_COLOR   = Color.new(200, 150, 200)
  SP_REC_COLOR   = Color.new(144, 176, 255)
  HPSP_REC_COLOR = Color.new( 19, 209, 199)
  HPSP_DMG_COLOR = Color.new(126,  72, 153)
  CRIT_DMG_COLOR = Color.new(255, 144,  96)
  CRIT_TXT_COLOR = Color.new(255,  96,   0)
  DAMAGE_COLORS = {
    hp_dmg: DEFAULT_COLOR,
    sp_dmg: SP_DMG_COLOR,
    hp_heal: HP_REC_COLOR,
    sp_heal: SP_REC_COLOR ,
    hpsp_dmg: HPSP_DMG_COLOR,
    hpsp_heal: HPSP_REC_COLOR, 
    critical: CRIT_DMG_COLOR
  }
  DAMAGE_FONT   = "Trykker"   # Damage exhibition font
  DMG_F_SIZE    = 60     # Size of the damage exhibition font
  DMG_TXT_F_SIZE = 42
  DMG_DURATION  = 60    # Duration, in frames, that the damage stays on screen      
  CRITIC_TEXT   = true   # Show text when critical damage is delt?
  CRITIC_FLASH  = true  # Flash effect when critical damage is dealt?
  CRIT_FLASH_COLOR   = Color.new(255, 250, 200, 175)
  MULTI_POP     = false # Style in which the damage is shown true = normal / false = FF styled
  POP_MOVE      = true   # Moviment for damage exhibition?
  DMG_SPACE     = 11    # Space between the damage digits
  DMG_X_MOVE    = 2      # X movement of the damage (only if POP_MOVE = true)
  DMG_Y_MOVE    = 6      # Y movement of the damage
  DMG_GRAVITY   = 0.98   # Gravity effect, affects on the heeight the damage "jumps"
  # Message shown when a flee attempt succeeds
  ESCAPE_SUCCESS = "&MUI[BattleEscaped]"
  # Message shown when a flee attempt fails
  ESCAPE_FAIL = "&MUI[BattleEscapeFail]"
  # Define the message shown when an Ambush occurs
  BACK_ATTACK_ALERT = "&MUI[BattleAmbush]"
  # Define here the message shown when a Preemptive Attack occurs
  PREEMPTIVE_ALERT = "&MUI[BattlePreemptive]"
  #--------------------------------------------------------------------------
  # * Sound Related
  #-------------------------------------------------------------------------- 
  # Name of the sound file used when a dodge occurs.
  EVASION_SFX = "FX_Evade"
  # Pause SFX
  PAUSE_SFX = 'MUI_Pause'
  # Command Sound effects
  COMMAND_SOUNDS = {
    attack: RPG::AudioFile.new('MUI_ComAttack',80,100),
    hold: RPG::AudioFile.new('MUI_ComHold',100,100),
    item: RPG::AudioFile.new('MUI_ComItem',80,100),
    skill: RPG::AudioFile.new('MUI_ComSkill',80,120)
  }
  SPEED_UP_SFX = RPG::AudioFile.new('MUI_SpeedUp',80,150)
  SLOW_DOWN_SFX = RPG::AudioFile.new('MUI_SlowDown',80,150)
  ACTION_SFX = RPG::AudioFile.new('MUI_NewGame',80,150)
  # Level up sound
  LEVEL_UP_SFX = 'MUI_LevelUp'
  #--------------------------------------------------------------------------
  # * Windows / UI
  #--------------------------------------------------------------------------
  # Effects' icons configuration
  ICON_MAX = 5   # Maximum amount of showed icons
  # Configurations of the Battle Window (All unused)
  # STATUS_OPACITY  = 160  # Opacity of the Battle Window
  # MENU_OPACITY    = 160  # Opacity of the Item/Skills window
  # HELP_OPACITY    = 160  # Opacity of the Help Window
  # COMMAND_OPACITY = 160  # Opacity of the Commands Window
  # HIDE_WINDOW     = true # Hide status window when selecting items/skills?
  # Fill speed for victory EXP windowss
  EXP_FILL_SPEED = 5
  # Duration for level up windows
  LEVEL_WINDOW_DURATION = 120
  EXP_METER_GRAPHIC = 'MeterEXPSmall'
  LEVEL_UP_STRING = 'Level Up!'
  # Wait time (in frames) for battle end
  POST_BATTLE_WAIT = 90
  #--------------------------------------------------------------------------
  # * MISC
  #--------------------------------------------------------------------------
  # Item ID for Escape item
  ESCAPE_ITEM_ID = 103
  # Variable ID used for Overriding Troop ID
  TROOP_OVERRIDE_ID = 17
  #--------------------------------------------------------------------------
  # * Back Attack / Preemptive Config
  #-------------------------------------------------------------------------- 
  # Allow Ambushes to occur?
  BACK_ATTACK = false
  # Define here the Ambush occurance rate
  BACK_ATTACK_RATE = 10
  # Invert the battle background when an Ambush occurs?
  BACK_ATTACK_BATTLE_BACK_MIRROR = false
  # Here you can configurate the system (itens, skills, switchs) to protect 
  # the character from Ambushes. The item must be equiped, the skill must be
  # learned, and switches must be ON so the Ambush protection works. 
  # Only one of the 3 need to match the requirements to work.
  # In other words, the item can be equiped, but the skill not learned and the
  # switch OFF for the item's effect to take place.
  # For one item/skill/switch only: = [1]
  # For multiple: = [1,2]
  # Weapons' ID's
  #NON_BACK_ATTACK_WEAPONS = []
  # Shields' ID's
  #NON_BACK_ATTACK_ARMOR1 = []
  # Helmets' ID's
  #NON_BACK_ATTACK_ARMOR2 = []
  # Armors' ID's
  #NON_BACK_ATTACK_ARMOR3 = []
  # Accesories' ID's
  NON_BACK_ATTACK_ARMOR_IDS = []
  # Skills' ID's
  NON_BACK_ATTACK_SKILLS = []
  # Number of the Switch - when ON, the chance for Ambushes is zero
  NO_BACK_ATTACK_SWITCH = 9
  # Number of the Switch - when ON, the chance for Ambushes is 100%
  BACK_ATTACK_SWITCH = 8
  # Allow Preemptive Attacks to occur?
  PREEMPTIVE = false
  # Define here the occurance rate of Preemptive Attacks
  PREEMPTIVE_RATE = 10
  # Here you can configurate the system (itens, skills, switchs) to increase 
  # the occurance of Preemptive Attacks. The item must be equiped, the skill must
  # be learned, and switches must be ON so the Ambush protection works. 
  # Only one of the 3 need to match the requirements to work.
  # In other words, the item can be equiped, but the skill not learned and the
  # switch OFF for the item's effect to take place.
  # For one item/skill/switch only: = [1]
  # For multiple: = [1,2]
  # Weapons' ID's
  #PREEMPTIVE_WEAPONS = []
  # Shields' ID's
  #PREEMPTIVE_ARMOR1 = []
  # Helmets' ID's
  #PREEMPTIVE_ARMOR2 = []
  # Armors' ID's
  #PREEMPTIVE_ARMOR3 = []
  # Accesories' ID's
  PREEMPTIVE_ARMOR_IDS = []
  # Skills' ID's
  PREEMPTIVE_SKILLS = []
  # Number of the Switch - when ON, the chance for Preemptive Attacks is zero
  NO_PREEMPTIVE_SWITCH = 13
  # Number of the Switch - when ON, the chance for Preemptive Attacks is 100%
  PREEMPTIVE_SWITCH = 12
end
#==============================================================================
# * Overdrive Module
# Overdrive is the original Atoa name for "Limit Breaker" type skills
# In game, they're referred to as "Awakenings" and "Unleash"
# The player has a bar that fills up based on certain actions, with a 
# unique character ability that can be cased for free once it is filled
#==============================================================================
module Overdrive
  #-------------------------------------------------------------------------- 
  # * Overdrive Configuration (AKA, "Unleash")
  #-------------------------------------------------------------------------- 
  # Maximum value of the Overdrive Bar.
  MAX_OD = 1000
  # Action gain rates (10 = 1% gain)
  GAIN_RATES = {
    attacking:     50, 
    attacked:     200, 
    skilling:     100,
    skilled:      150,
    dodged:       100, 
    missed:       100, 
    killed:       200, 
    battle_won:   200, 
    escaped:        0,
    dead_ally:    100,
    alive_ally:    30,
    normal_turn:   50,
    danger_turn:  300
  }
  #-------------------------------------------------------------------------- 
  # * Formulas for OD Gain on attacks
  #-------------------------------------------------------------------------- 
  # This is silliness, and probably should be changed
  # For now, keeping the original formula
  # Attacking
  def self.od_attacking_formula(damage, level)
    value = [damage * Overdrive::GAIN_RATES[:attacking] / (level + 10) / 50, 10].max
    return value
  end
  # Attacked
  def self.od_attacked_formula(damage, max_hp)
    value = [damage * Overdrive::GAIN_RATES[:attacked] / max_hp, 1].max 
    return value
  end
end
#==============================================================================
# * Battle Descriptions Module
# A module for creating the strings for various actions in battle
#==============================================================================
module BattleDescriptions
  #--------------------------------------------------------------------------
  # * State Pop text and color
  #--------------------------------------------------------------------------
  def self.state_pop(state_id)
    state = $data_states[state_id]
    return ["", DEFAULT_COLOR] if state.nil?
    ["&MUI[#{state.name_loc_key}]",state.pop_color]
  end
  #--------------------------------------------------------------------------
  # * Special Action Text
  # These are just unique strings that don't use self.action
  #--------------------------------------------------------------------------
  def self.special_text(text = "", action)
    # Get string
    str = 
      case action
      when :resume
        Localization.localize("&MUI[BattleActResume]")
      when :en_defend
        Localization.localize("&MUI[BattleActEnemyDefend]")
      when :en_resume
        Localization.localize("&MUI[BattleActEnemyResume]")
      when :crystal # Escape crystal warning
        Localization.localize("&MUI[EscapeCrystalWarn]")
      else 
        ""
      end
    # Perform substitution (if relevant)
    str.sub!('!N', text) if text != ""
    return str
  end
  #--------------------------------------------------------------------------
  # * Action text
  # name: battler name
  # action: Game_BattleAction object
  # type: 'Commit', 'Verb' or 'Detail' 
  # detailed: whether the full detail of the action (skill) is drawn
  #--------------------------------------------------------------------------  
  def self.action(name, action, type, detailed = true)
    # Catch invalid actions
    return 'nil action!!!' if action.nil?
    str = ''
    # Branch by action type
    case action.kind
    when :basic
      basic_s = action.basic.to_s.capitalize
      # BattleActTypeAttack, BattleActTypeGuard, Etc.
      str = Localization.localize("&MUI[BattleAct#{type}#{basic_s}]")
      str.sub!('!N', name)
    when :skill
      skill_id = action.skill_id
      # Early return for invalid skill
      return '' if skill_id == 0
      skill = $data_skills[skill_id]
      str = 
        if skill.has_extension?(:TYPE_UNLEASH)
          "&MUI[BattleAct#{type}Unleash]"
        elsif skill.magic?
          "&MUI[BattleAct#{type}Magic]"
        elsif !skill.magic?
          "&MUI[BattleAct#{type}Ability]"
        else
          "&MUI[BattleAct#{type}Skill]"
        end
      str = Localization.localize(str)
      str.sub!('!N', name)
      if type == 'Detail' && !detailed
        str.sub!('!A', '')
      else
        str.sub!('!A', Localization.localize("&MUI[Skill#{skill_id}]"))
      end
    when :item
      item_id = action.item_id
      # Early return for invalid item
      return '' if item_id == 0
      str = Localization.localize("&MUI[BattleAct#{type}Item]")
      item = Localization.localize("&MUI[Item#{item_id}]")
      str.sub!('!N', name)
      str.sub!('!A', item)
    end 
    # Return the substituted string
    return str
  end
  #--------------------------------------------------------------------------
  # * Enemy Idle Text
  #--------------------------------------------------------------------------  
  def self.enemy_idle(enemy)
    custom_ids = [7]
    str = 
      if custom_ids.include?(enemy.id)
        Localization.localize("&MUI[EnemyIdleText#{enemy.id}]")
      else
        Localization.localize('&MUI[EnemyIdleText0]')
      end
    str.sub!('!N', enemy.name)
    str
  end
end