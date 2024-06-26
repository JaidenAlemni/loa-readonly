#==============================================================================
# ** Custom Enemy Actions
#------------------------------------------------------------------------------
#  This module extends the enemy conditions in the database to allow
#  for more particular AI. 
#==============================================================================
module EnemyAI
  #------------------------------------------------------------------------------
  # * Targeting Behavior
  #------------------------------------------------------------------------------
  # Target behavior is now determined by "condition_level" from the DB \
  # which is an integer from 2-99. Each ID has a predictable type of behavior
  # 
  #   id : action.condition_level
  #   enemy : Game_Enemy
  #   action : Game_BattleAction
  #
  def self.find_single_target(enemy, action)
    # Ensure correct target is chosen
    target_type = action.for_one_friend? ? :enemy : :actor

    case action.behavior
    # Vengeful - Targets the actor who attacked them last
    when :last_attacker
      return if catch_invalid_behavior(target_type, enemy, action)
      target = BattleTarget.last_attacker(:actor, enemy)

    # Stubborn - Targets the same party member consistently
    when :fixed_target
      return if catch_invalid_behavior(target_type, enemy, action)
      # If the target is no longer valid or not yet set, find the target
      if enemy.saved_target.nil? || !enemy.saved_target.exist?
        enemy.saved_target = BattleTarget.random(:actor, 1, :none, enemy).first
      end
      target = enemy.saved_target

    # Avenger - Targets party member who attacked a troopmate other than them
    when :avenge_ally
      return if catch_invalid_behavior(target_type, enemy, action)
      other_enemies = $game_troop.enemies.select{|e| e != enemy}
      if other_enemies.empty?
        self.decide_random_target(action, enemy)
        return
      end
      attacked_other = $game_party.actors.select{|b| other_enemies.include?(b.last_target)}
      target = attacked_other.sample

    # Targets a character with the highest health
    when :highest_hp
      target = BattleTarget.filter_battler(target_type, :current_hp, :max)

    # Assessor - Targets character with the highest mana
    when :highest_mp
      target = BattleTarget.filter_battler(target_type, :current_sp, :max)

    # Protector - Targets troopmate with low health with buffs / heals
    when :lowest_hp
      target = BattleTarget.filter_battler(target_type, :current_hp)

    # Cruel - Targets character with the lowest health
    when :lowest_mp
      target = BattleTarget.filter_battler(target_type, :current_sp)

    when :max_hp
      target = BattleTarget.filter_battler(target_type, :stat, :maxhp, :max)

    when :max_mp
      target = BattleTarget.filter_battler(target_type, :stat, :maxsp, :max)

    # CUSTOM - Soulich targeting
    when :custom_soulich_bind
      # Target Azel 90% of the time
      if rand(100) <= 75
        target = BattleTarget.filter_battler(target_type, :index, 1)
      else
        self.decide_random_target(action, enemy)
      end

    when :custom_soulich_attack
      # Target Azel 75% of the time
      if rand(100) <= 75
        target = BattleTarget.filter_battler(target_type, :index, 1)
      # Dice roll
      else
        self.decide_random_target(action, enemy)
      end

    # Default behavior; random (target actors based on threat level)
    else
      self.decide_random_target(action, enemy)
      return
    end
    # If a target doesn't meet preferred condition, random (target actors based on threat level)
    if target.nil?
      self.decide_random_target(action, enemy)
    # Set target index
    else
      action.target_index = target.index
    end
  end

  def self.catch_invalid_behavior(target_type, enemy, action)
    if target_type == :enemy
      puts "Assigned invalid behavior to enemy action!"
      self.decide_random_target(action, enemy)
      return true
    end
    false
  end
  #------------------------------------------------------------------------------
  # * Pick a random target (accounting for threat level)
  #------------------------------------------------------------------------------
  def self.decide_random_target(action, enemy = nil)
    # Diverge with effect scope
    battler = 
      if action.for_one_friend_hp0?
        BattleTarget.random(:enemy, 1, :hp0).first
      elsif action.for_one_friend?
        BattleTarget.random(:enemy).first
      else
        BattleTarget.random(:actor, 1, :none, enemy).first
      end
    # If a target exists, get an index, and if a target doesn't exist,
    # clear the action
    if battler != nil
      action.target_index = battler.index
    else
      # FIXME: Does this work as expected?
      action.clear
    end
  end
  # REDACTED
end