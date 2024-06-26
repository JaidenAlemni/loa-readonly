#==============================================================================
# ■ Game_Enemy
#------------------------------------------------------------------------------
# 　Enemy Basic Action Settings
#==============================================================================
class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● Name ID Constants
  #--------------------------------------------------------------------------
  DUMMY = 1
  TUT_MUSH = 5
  MUSHDOOM = 6
  KILLER_BEE = 7
  SLIME_EARTH = 8 
  BALDRIC = 10
  SOULICH = 11
  GUNTHER = 12
  KNIGHT_S = 13
  KNIGHT_P = 14
  CAVE_BAT = 15
  RAT = 17
  #--------------------------------------------------------------------------
  # ● Enemy Unarmed Attack Animation Sequence
  #--------------------------------------------------------------------------
  # when DUMMY <- EnemyID#
  #   return :enemy_normal_atk <- Corresponding action sequence name.
  def base_action
    case @enemy_id
    when SOULICH            then :soulich_attack
    when GUNTHER, KNIGHT_S  then :normal_attack
    when KNIGHT_P           then :charge_attack
    # Default for unassigned
    else
      :enemy_normal_atk
    end
  end 
  #--------------------------------------------------------------------------
  # ● Enemy Default Cast Animation
  #--------------------------------------------------------------------------
  def cast_action
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :soulich_special_attack
    # Default unassigned
    else
      :enemy_skill_use
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Wait/Idle Animation
  #-------------------------------------------------------------------------- 
  def normal
    case @enemy_id
    when SOULICH, GUNTHER then :idle_slow
    # Default unassigned
    else
      :idle
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Critical (DUMMY/4th HP) Animation
  #-------------------------------------------------------------------------- 
  def pinch
    case @enemy_id
    when SOULICH then :idle_critical
    # Default unassigned
    else
      :idle
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Action Commit Animation
  #-------------------------------------------------------------------------- 
  def commit
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :enemy_ready_atk
    when KNIGHT_S then :idle_ready
    # Default unassigned
    else
      :idle_ready
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Casting Spell Animation
  #-------------------------------------------------------------------------- 
  def casting
    case @enemy_id
    when DUMMY  then :idle
    # Default unassigned
    else
      :idle_casting
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Guarding Animation
  #--------------------------------------------------------------------------  
  def defence
    case @enemy_id
    when DUMMY  then :idle
    when KNIGHT_S then :enemy_defend
    else
      :enemy_defend
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Guarding on Hit
  #--------------------------------------------------------------------------  
  def defence_hit
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :damage_fixed
    else
      :damage
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Damage　Taken Animation
  #-------------------------------------------------------------------------- 
  def damage_hit
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :damage_fixed
    else
      :damage
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Evasion Animation
  #-------------------------------------------------------------------------- 
  def evasion
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :idle
    when KNIGHT_S then :evade_attack
    else
      :evade_attack
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Flee Animation
  #-------------------------------------------------------------------------- 
  def run_success
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :idle
    else
      :flee_success
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Battle Start Animation
  #--------------------------------------------------------------------------  
  def first_action
    case @enemy_id
    when DUMMY  then :idle
    when SOULICH then :idle
    else
      :enemy_start
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Return Action when action is interuptted/discontinued
  #--------------------------------------------------------------------------  
  def recover_action
    case @enemy_id
    when DUMMY then :fixed_reset
    when SOULICH then :fixed_reset
    else
      :reset_position
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Shadow
  #-------------------------------------------------------------------------- 
  # return "shadow01" <- Image file name in .Graphics\Characters
  # return "" <- No shadow used.
  def shadow
    case @enemy_id
    when DUMMY then ""
    when 2, GUNTHER..14 then "shadow_oliver"
    when RAT then "shadow_oliver"
    else
      "shadow00"
    end
  end 
  #--------------------------------------------------------------------------
  # ● Enemy Shadow Adjustment
  #-------------------------------------------------------------------------- 
  # return [ X-Coordinate, Y-Coordinate] 
  def shadow_plus
    case @enemy_id
    when 2 then [ 38, -6]
    when GUNTHER, KNIGHT_S then [ 92, -6]
    when 8 then [9, -14]
    when 14 then [ 24, -6]
    when 10 then [ 0, 85]
    when RAT then [ 12, -4]
    else
      [ 0, -8]
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy origin set
  # Sets the origin for movement calculation (pixels, from the bottom up)
  # i.e., 24 sets the origin 24 pixels from the bottom of the sprite
  #-------------------------------------------------------------------------- 
  def origin_setting
    case @enemy_id
    when 2, GUNTHER..14 then 24
    when SOULICH then 120
    when 50 then 24
    # Default positioning for all unassigned Enemy IDs.
    else
      2
    end
  end
  #--------------------------------------------------------------------------
  # ● Cursor offset
  # Determines the offset (-y) for the battle cursor
  #-------------------------------------------------------------------------- 
  def cursor_offset
    case @enemy_id
    when 2 then 80
    when GUNTHER..14 then 64
    when SOULICH then 24
    when 50 then 140
    else
      36
    end
  end
  #--------------------------------------------------------------------------
  # ● Balloon offset
  # Determines the offset (-x) for the enemy balloon display
  #-------------------------------------------------------------------------- 
  def balloon_offset
    case @enemy_id
    when SOULICH then 48
    when GUNTHER, KNIGHT_S then 4
    when 14 then 8
    else
      nil
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Collapse Animation Settings
  #--------------------------------------------------------------------------
  # return DUMMY  (Enemy sprite stays on screen after death.)
  # return 2  (Enemy disappears from the battle like normal.)
  # return 3  (Special collapse animation.) <- Good for bosses.
  # return 4  (Advanced collapse type)
  def collapse_type
    case @enemy_id
    when DUMMY  then :normal_collapse
    when 2  then :no_collapse # Baldric
    when SOULICH then :boss_collapse
    else
      :normal_collapse
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Multiple Action Settings
  #--------------------------------------------------------------------------
  # Maximum Actions, Probability, Speed Adjustment
  # return [ 2, 100, 100]
  #
  # Maximum Actions - Maximum number of actions enemy may execute in a turn.
  # Probability - % value. Chance for a successive action.
  # Speed Adjustment - % value that decreases enemy's speed after
  #                       each successive action.
  def action_time
    case @enemy_id
    when DUMMY then [ DUMMY, 100, 100]
    else
      [ DUMMY, 100, 100]
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Animated Battler Settings
  #--------------------------------------------------------------------------
  # This is different now
  # Checks if the battler should use the walking graphic or 
  # if it should use the series of battler graphics
  # false - will look in "Characters"
  # true - will look in "Battlers"
  def anime_on
    case @enemy_id
    when KNIGHT_S then true
    else
      true
    end
  end
  #--------------------------------------------------------------------------
  # ● Enemy Invert Settings
  #--------------------------------------------------------------------------
  # return false  <- Normal
  # return true   <- Inverts enemy image
  def action_mirror
    case @enemy_id
    when DUMMY then false
    else 
      false
    end
  end
  #--------------------------------------------------------------------------
  # ● Skill Action
  # Determine if the battler should use a skill action defined in RPG::Skill
  # or use a unique action here
  #--------------------------------------------------------------------------
  def skill_action(skill)
    # Fallback for invalid skill
    if skill.nil? || skill.id == 0
      return self.cast_action
    end
    # Branch by enemy ID
    case @enemy_id
    when KILLER_BEE
      case skill.id
      when 150
        return :enemy_normal_atk # venom strike
      end
    when GUNTHER, KNIGHT_S # Rogue Knight (Sword)
      case skill.id
      when 41
        return :dual_strike # Dual strike
      end
    end
    # If a valid skill isn't found, return the default
    self.cast_action
  end
end