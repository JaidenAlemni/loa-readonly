#==============================================================================
# Sideview Battle System Version 3.0xp
# Custom system designed by Jaiden
# Based on SBS by Enu, ported by Atoa
#--------------------------------------
# Scene Battle Part 2:
# Victory, pre-battle and post battle processing
#==============================================================================
class Scene_Battle
  #--------------------------------------------------------------------------
  # * Start battle phase 1 (Begin battle)
  # This phase deteremines if it is preemptive/back attack
  # and the alive/dead status of members in the party
  # It only runs once.
  #--------------------------------------------------------------------------
  def prebattle_start
    # Play battle BGM
    $game_system.bgm_play($game_system.battle_bgm) unless $game_temp.continue_map_bgm_battle
    @phase = 1
    # Run start method, handling preemptive/ambush placement
    ATB.battle_start
    # If there was an ambush
    if $game_temp.battle_preemptive
      # Display in help
      pop_help(PREEMPTIVE_ALERT, 1.5, false, nil)
    elsif $game_temp.battle_ambushed
      # Set phase to action
      @phase = 3
      # Display in help
      pop_help(BACK_ATTACK_ALERT, 1.5, false, nil)
      # Start action phase
      start_action_phase
      # Clear flag
      $game_temp.battle_ambushed = false
    end
  end 
  #--------------------------------------------------------------------------
  # * Update pre-battle phase
  #--------------------------------------------------------------------------
  def update_prebattle
    # Determine win/loss situation
    if judge
      # FIXME This is a little hairy. If the battle is lost before starting,
      # it should cut right to the gameover screen. 
      # However, if "battle can lose" is true when this happens,
      # could result in an unexpected behavior. 
      return
    end
    # Flag and start battle phase
    @phase = 2
    start_battle
  end 
  #--------------------------------------------------------------------------
  # * Check if player won or lost battle
  #--------------------------------------------------------------------------
  def judge
    # Check if actors are dead or no party members
    if $game_party.all_dead? || $game_party.actors.size == 0
      # If the battle can be lost without gameover
      if $game_temp.battle_can_lose
        # End battle (2 = lose)
        battle_end(LOSE)
        # Return "Battle over"
        return true
      end
      # Set gameover flag
      $game_temp.gameover = true
      # Return "battle over"
      return true
    end
    # Check if enemies exist 
    for enemy in $game_troop.enemies
      # Return "battle continue"
      return false if enemy.exist?
    end
    # Process victory
    process_victory
    # Return "battle over"
    return true
  end
  #--------------------------------------------------------------------------
  # * Check pre-victory variables
  #--------------------------------------------------------------------------
  def process_victory
    # Check each enemy
    for enemy in $game_troop.enemies
      # Check collapse type for special animation
      if [:boss_collapse, :advanced_collapse].include?(enemy.collapse_type)
          # Set boss_wait to true
        boss_wait = true
        break
      end
    end
    # Check for boss wait
    if boss_wait
      # Wait 440 frames
      wait(8)
    else
      # Wait normal amount
      wait(WIN_WAIT)
    end 
    # Check each player
    for actor in $game_party.actors
      # Animate victory poses
      unless actor.restriction == 4
        @spriteset.set_action(true, actor.index, actor.win)
      end
    end
    # End battle
    battle_end(WIN)
    # Phase 4 (battle end)
    @phase = 4
  end
  #--------------------------------------------------------------------------
  # * Battle Ends
  #     result : results (0:win 1:escape 2:lose)
  # NOTE: Lose here means lose WITHOUT gameover. Expects a clean exit.
  #--------------------------------------------------------------------------
  def battle_end(result)
    # Clear entire party's actions
    $game_party.clear_actions
    # Remove "end of battle" states
    for actor in $game_party.actors
      actor.remove_states_battle
    end
    # Battle result
    case result
    when WIN
      $game_party.actors.each do |actor|
        actor.remove_state(1, true)
        # Overdrive gain
        if actor.overdrive_actions.include?(:battle_won) && actor.exist?
          actor.overdrive += Overdrive::GAIN_RATES[:battle_won]
        end 
      end
      # Stop music
      $game_system.bgm_fade(1, false)
    when ESCAPE 
      $game_party.actors.each do |actor|
        # Overdrive gain
        if actor.overdrive_actions.include?(:escaped) && actor.exist? 
          actor.overdrive += Overdrive::GAIN_RATES[:escaped]
        end
      end
      # Clear enemies
      $game_troop.enemies.clear
    end
    # Update meters
    refresh_windows
    # Clear in battle flag
    $game_temp.in_battle = false
    # Switch Scenes
    if $BTEST
      # If we're battle testing, quit
      $scene = nil
    elsif result == WIN
      # Clear main phase flag
      $game_temp.battle_main_phase = false
      # Set BGM
      $game_system.bgm_play($game_system.battle_end_me)
      # Recenter camera
      @spriteset.center_camera
      # Wait
      wait(1.5)
      # Switch to victory scene
      $scene = Scene_Victory.new
    else # Lose or Escape
      # Call battle callback (win/lose/escape branches)
      if $game_temp.battle_proc != nil
        $game_temp.battle_proc.call(result)
        $game_temp.battle_proc = nil
      end
      # Switch to map screen
      $scene = Scene_Map.new
    end
  end
end