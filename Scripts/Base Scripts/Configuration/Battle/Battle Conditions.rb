class Scene_Battle 
  #--------------------------------------------------------------------------#
  # **  Custom Commands for Easy Checks for Conditional Switches             #
  # Refer to Heretics "Unlimited Battle Conditions" for details.             #
  #                                                                          #
  #             ALL METHODS MUST RETURN TRUE OR FALSE                        #
  #--------------------------------------------------------------------------#
  #--------------------------------------------------------------------------
  # * Tutorial checks
  #--------------------------------------------------------------------------
  def player_first_input?
    ($game_party.actors[0].input_selected? || $game_party.actors[0].committed_action?) && $game_party.actors[0].current_action.basic == :attack
  end

  def player_finished_first_attack?
    $game_party.actors[0].current_action.basic == :none
  end

  def player_second_input?
    $game_party.actors[0].holding?
  end

  def player_took_damage?
    #
  end

  def player_used_skill?
    $game_party.actors[0].sp < $game_party.actors[0].maxsp
  end

  def tutorial_enemy_ready?
    $game_troop.enemies[0].atp >= ATB::COMMIT_ATP
  end

  def tutorial_three_seconds?
    System.uptime - $game_variables[88] >= 5
  end

  def tutorial_took_damage?
    $game_party.actors[0].hp != $game_variables[88]
  end

  # Player either successfully waited, and took damage while defending
  # OR they hastily attacked, and then another turn passed
  def tutorial_last_step?
    ($game_variables[86] == 4 && $game_troop.enemies[0].hp != $game_variables[88]) ||
    ($game_variables[86] == 3 && tutorial_took_damage?)
  end


  #--------------------------------------------------------------------------
  # * Troop Used a skill?
  #--------------------------------------------------------------------------
  def enemy_used_skill?(skill_id)
    result = false
    $game_troop.enemies.each do |enemy|
      next unless enemy.input_selected
      if enemy.temp_action&.skill_id == skill_id
        result = true
        break
      end
    end
    return result
  end
  #--------------------------------------------------------------------------
  # * Item In Inventory
  #     item_id : Item Id from Database
  #
  #   Example: 1 is a Potion
  #            # If Party has a Potion in the Inventory
  #            item_in_inventory?(1)
  #
  #            2 is a High Potion
  #            # If Party has a High Potion in the Inventory
  #            item_in_inventory?(2)
  #
  #  This is an Example Script.  It could be accomplished by copying and
  #  pasting the one "return true if ..." line of code.  I provided this
  #  because it makes it easy for us to script easier condition checks
  #  for others that may use this script.
  #--------------------------------------------------------------------------
  def item_in_inventory?(item_id)
    # If Item is in Inventry, return True
    return true if $game_party.item_number(item_id) > 0
    # Default
    return false
  end
  #--------------------------------------------------------------------------
  # * Troop Defeated?
  #  - Returns TRUE if the Troops have all been defeated or run away
  #  - Returns FALSE if any of the Troops are still alive
  #--------------------------------------------------------------------------
  def troop_defeated?
    # Return false if even 1 enemy exists
    for enemy in $game_troop.enemies
      # If this Enemy hasn't run away
      if enemy.exist?
        # They are still being battled in the battle scene so not defeated yet
        return false
      end
    end
    # Default Some of the Troops are still alive
    return true
  end
  #--------------------------------------------------------------------------
  # * Troop Alive?
  #--------------------------------------------------------------------------
  def enemies_defeated?(num)
    defeated = 0
    $game_troop.enemies.each do |enemy|
      if !enemy.exist?
        defeated += 1
      end
    end
    # If the number of alive troop members is less than 
    # or equal to the checked number
    if defeated >= num
      return true
    else
      return false
    end      
  end
  #--------------------------------------------------------------------------
  # * Level Up? - Scene_Battle
  #  - Returns TRUE if anyone in the Party will Level Up
  #   NOTE: This will evaluate to TRUE during the entire battle so be sure
  #         to use this as a SECOND CONDITION
  #--------------------------------------------------------------------------
  def level_up?
    # Placeholder for Total Exp to be won in this battle
    battle_exp = 0
    # Check each Enemy in the current Troop that is fought
    for enemy in $game_troop.enemies
      # If enemy is not hidden and didnt run away / escape
      unless enemy.hidden
        # Add the Enemy's experience to the Total Experience to be gained
        battle_exp += enemy.exp
      end
    end
    # If using Heretic's Window Level Up and Bonus Exp
    if @bonus_exp.is_a?(Integer)
      # Add the Bonus Experience to Total Exp each Actor will receive on a Win
      battle_exp += @bonus_exp
    end
    # Check each of the Party Members
    for actor in $game_party.actors
      # If Actor isnt Dead or other Conditions that prevent getting Exp
      if actor.cant_get_exp? == false 
        # If this Actor will Level Up
        if battle_exp >= actor.next_rest_exp_s.to_i
          # Return an Evaluator for Comparison
          return true
        end
      end
    end
    # No Actors will Level Up this Battle
    return false
  end

end