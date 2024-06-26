#==============================================================================
# ■ Game_Actor
#------------------------------------------------------------------------------
# 　Actor Basic Action Settings
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● Name-ID Constants
  #-------------------------------------------------------------------------- 
  OLIVER = 1
  SARINA = 2
  ARLYN = 3
  MINERVA = 4
  AZEL = 5
  BALDRIC = 7
  #--------------------------------------------------------------------------
  # ● Actor Unarmed Attack Animation Sequence
  #-------------------------------------------------------------------------- 
  # when 1 <- Actor ID number
  #   return "NORMAL_ATTACK" <- Corresponding action sequence name.
  def non_weapon
    case @actor_id
    when OLIVER # Actor ID
      return :normal_attack
    when BALDRIC
      return :unarmed_attack
    end
    # Default action sequence for all unassigned Actor IDs.
    return :normal_attack
  end
  #--------------------------------------------------------------------------
  # ● Actor Wait/Idle Animation
  #-------------------------------------------------------------------------- 
  def normal
    case @actor_id
    when OLIVER
      if $DUEL_CS_FLAG
        return :oliver_fire_idle
      end
      return :idle
    else
    # Default action sequence for all unassigned Actor IDs.
    return :idle
    end
  end
  #--------------------------------------------------------------------------
  # ● Actor Action Commit Animation
  #-------------------------------------------------------------------------- 
  def commit
    case @actor_id
    when OLIVER
      if $DUEL_CS_FLAG
        return :oliver_fire_idle
      end
      return :idle_ready
    else
    return :idle_ready
    end
  end
  #--------------------------------------------------------------------------
  # ● Actor Critical (1/4th HP) Animation
  #-------------------------------------------------------------------------- 
  def pinch
    case @actor_id
    when OLIVER
      if $DUEL_CS_FLAG
        return :oliver_fire_idle
      end
      return :idle_critical
    end
    # Default action sequence for all unassigned Actor IDs.
    return :idle_critical
  end
  #--------------------------------------------------------------------------
  # ● Actor Casting Spell Animation
  #-------------------------------------------------------------------------- 
  def casting
    case @actor_id
    when OLIVER # Oliver, determine special cases
      if $DUEL_CS_FLAG
        return :oliver_fire_cast
      end
      return :idle_casting
    end
    return :idle_casting
  end
  #--------------------------------------------------------------------------
  # ● Actor Guarding Animation
  #-------------------------------------------------------------------------- 
  def defence
    case @actor_id
    when OLIVER
      return :idle_defend
    end
    # Default action sequence for all unassigned Actor IDs.
    return :idle_defend
  end
  #--------------------------------------------------------------------------
  # ● Actor Damage Taken Animation
  #-------------------------------------------------------------------------- 
  def defence_hit
    case @actor_id
    when OLIVER
      return :damage_blocked
    end
    # Default action sequence for all unassigned Actor IDs.
    return :damage_blocked
  end  
  #--------------------------------------------------------------------------
  # ● Actor Damage Taken Animation
  #-------------------------------------------------------------------------- 
  def damage_hit
    case @actor_id
    when OLIVER
      return :damage
    end
    # Default action sequence for all unassigned Actor IDs.
    return :damage
  end  
  #--------------------------------------------------------------------------
  # ● Actor Evasion Animation
  #-------------------------------------------------------------------------- 
  def evasion
    case @actor_id
    when OLIVER
      return :evade_attack
    when AZEL
      return :miss_attack
    end
    # Default action sequence for all unassigned Actor IDs.
    return :evade_attack
  end
  #--------------------------------------------------------------------------
  # ● Actor Dying Animation
  #-------------------------------------------------------------------------- 
  def collapsing
    case @actor_id
    when OLIVER
      return :collapse
    end
    # Default action sequence for all unassigned Actor IDs.
    return :collapse
  end
  #--------------------------------------------------------------------------
  # ● Actor Command Input Animation
  #-------------------------------------------------------------------------- 
  def command_b
    case @actor_id
    when OLIVER
      return :resume
    end
    # Default action sequence for all unassigned Actor IDs.
    return :resume
  end
  #--------------------------------------------------------------------------
  # ● Actor Command Selected Animation
  #-------------------------------------------------------------------------- 
  def command_a
    case @actor_id
    when OLIVER
      return :pause
    end
    # Default action sequence for all unassigned Actor IDs.
    return :pause
  end
  #--------------------------------------------------------------------------
  # ● Actor Flee Success Animation
  #-------------------------------------------------------------------------- 
  def run_success
    case @actor_id
    when OLIVER
      return :flee_success
    end
    # Default action sequence for all unassigned Actor IDs.
    return :flee_success
  end
  #--------------------------------------------------------------------------
  # ● Actor Flee Failure Animation
  #-------------------------------------------------------------------------- 
  def run_ng
    case @actor_id
    when OLIVER
      return :flee_fail
    end
    # Default action sequence for all unassigned Actor IDs.
    return :flee_fail
  end
  #--------------------------------------------------------------------------
  # ● Actor Victory Animation
  #-------------------------------------------------------------------------- 
  def win
    case @actor_id
    when OLIVER
      return :idle
    end
    # Default action sequence for all unassigned Actor IDs.
    return :idle
  end
  #--------------------------------------------------------------------------
  # ● Actor Battle Start Animation
  #--------------------------------------------------------------------------  
  def first_action
    case @actor_id
    when OLIVER
      return :actor_start
    end
    # Default action sequence for all unassigned Actor IDs.
    return :actor_start
  end
  #--------------------------------------------------------------------------
  # ● Actor Return Action when actions are interuptted/canceled
  #--------------------------------------------------------------------------  
  def recover_action
    case @actor_id
    when OLIVER
      return :actor_reset
    end
   # Default action sequence for all unassigned Actor IDs.
    return :actor_reset
  end
  #--------------------------------------------------------------------------
  # ● Actor Shadow
  #-------------------------------------------------------------------------- 
  # return "shadow01" <- Image file name in .Graphics\Characters
  # return "" <- No shadow used.
  def shadow
    case @actor_id
    when OLIVER
      return "shadow_oliver"
    end
    # Default shadow for all unassigned Actor IDs.
    return "shadow_oliver"
  end 
  #--------------------------------------------------------------------------
  # ● Actor Shadow Adjustment
  #-------------------------------------------------------------------------- 
  # return [ X-Coordinate, Y-Coordinate] 
  def shadow_plus
    case @actor_id
    when OLIVER, MINERVA
      return [38, -6]
    when AZEL
      return [64, -6]
    when BALDRIC, ARLYN
      return [80, -6]
    when SARINA
      return [106, -6]
    end
    # Default shadow positioning for all unassigned Actor IDs.
    return [0, -8]
  end
  #--------------------------------------------------------------------------
  # ● Cursor offset
  # Determines the offset (-y) for the battle cursor
  #-------------------------------------------------------------------------- 
  # return [ 0, 0]  <- [X-coordinate、Y-coordinate]
  def cursor_offset
    case @actor_id
    when OLIVER, MINERVA, SARINA
      return 64
    when AZEL, BALDRIC, ARLYN
      return 72
    end
    # Default positioning for all unassigned Enemy IDs.
    return 32
  end
  #--------------------------------------------------------------------------
  # ● Animation Sheet
  # Determine if the battler has a custom sheet (Graphics\Battlers)
  # or should just use the map sprite in Graphics\Characters
  #-------------------------------------------------------------------------- 
  def anime_on
    case @actor_id
    when 99; return false
    else
      return true
    end
  end
  #--------------------------------------------------------------------------
  # ● Overdrive Actions
  # Determine if the battler gains overdrive based on particular action types
  # (from the Overdrive GAIN_RATES hash)
  #-------------------------------------------------------------------------- 
  def overdrive_actions
    case @actor_id
    when OLIVER
      [:attacking, :attacked, :dodged, :battle_won, :escaped]
    when AZEL
      [:attacking, :killed, :dead_ally, :battle_won]
    else
      []
    end
  end
  #--------------------------------------------------------------------------
  # ● Use Skill Action?
  # Determine if the battler should use a skill action defined in RPG::Skill
  # or use a unique action here
  #-------------------------------------------------------------------------- 
  def skill_action(skill)
    # Fallback for invalid skill
    if skill.nil? || skill.id == 0
      return skill.base_action
    end
    # Branch by actor ID
    case @actor_id
    when AZEL
      case skill.id
      when 41; :dual_strike_staff
      when 43; :double_attack_staff
      else
        skill.base_action
      end
    when BALDRIC
      case skill.id
      when 41; :dual_strike_baldric
      when 43; :double_attack_baldric
      else
        skill.base_action
      end
    else
      skill.base_action
    end
  end
end