#==============================================================================
# ** Game_Party
#------------------------------------------------------------------------------
#  This class handles the party. It includes information on amount of gold 
#  and items. Refer to "$game_party" for the instance of this class.
#==============================================================================

class Game_Party
  #--------------------------------------------------------------------------
  # * Constants
  #-------------------------------------------------------------------------
  MAX_ESSENCE = 16
  MAX_BATTLE_MEMBERS = 3
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :gold                     # amount of gold
  attr_reader   :steps                    # number of steps
  attr_accessor :quests_new               # quest data
  attr_accessor :quests_accepted
  attr_accessor :quests_completed
  attr_accessor :quests_repeating
  attr_reader   :essences                 # essence data
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    # Create actor array
    @actors = []
    # Initialize amount of gold and steps
    @gold = 0
    @steps = 0
    # Create amount in possession hash for items, weapons, and armor
    @items = {}
    @weapons = {}
    @armors = {}
    # Add quest data
    @quests_new = []
    @quests_accepted = []
    @quests_completed = []
    @quests_repeating = []
    # Hash of owned essence IDs & their quantity
    @essences = {}
  end
  #--------------------------------------------------------------------------
  # * Initial Party Setup
  #--------------------------------------------------------------------------
  def setup_starting_members
    @actors = []
    for i in $data_system.party_members
      @actors.push($game_actors[i])
      # Setup the battle team
      add_battle_char($game_actors[i])
    end
  end
  #--------------------------------------------------------------------------
  # * Battle Test Party Setup
  #--------------------------------------------------------------------------
  def setup_battle_test_members
    @actors = []
    for battler in $data_system.test_battlers
      actor = $game_actors[battler.actor_id]
      actor.level = battler.level
      gain_weapon(battler.weapon_id, 1)
      gain_armor(battler.armor1_id, 1)
      gain_armor(battler.armor2_id, 1)
      gain_armor(battler.armor3_id, 1)
      gain_armor(battler.armor4_id, 1)
      actor.equip(0, battler.weapon_id)
      actor.equip(1, battler.armor1_id)
      actor.equip(2, battler.armor2_id)
      actor.equip(3, battler.armor3_id)
      actor.equip(4, battler.armor4_id)
      actor.recover_all
      @actors.push(actor)
      add_battle_char(actor)
    end
    @items = {}
    for i in 1...$data_items.size
      if $data_items[i].name != ""
        occasion = $data_items[i].occasion
        if occasion == 0 or occasion == 1
          @items[i] = 99
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Getting Maximum Level
  #--------------------------------------------------------------------------
  def max_level
    # If 0 members are in the party
    if @actors.size == 0
      return 0
    end
    # Initialize local variable: level
    level = 0
    # Get maximum level of party members
    for actor in @actors
      if level < actor.level
        level = actor.level
      end
    end
    return level
  end
  #--------------------------------------------------------------------------
  # * Refresh Party Members
  #--------------------------------------------------------------------------
  def refresh
    # Actor objects split from $game_actors right after loading game data
    # Avoid this problem by resetting the actors each time data is loaded.
    new_actors = []
    for i in 0...@actors.size
      if $data_actors[@actors[i].id] != nil
        new_actors.push($game_actors[@actors[i].id])
      end
    end
    @actors = new_actors
    # Save compatibility for new feature
    @actors.each do |actor|
      # Place Oliver in the team, the rest can be manually re-added
      if actor.in_battle_team.nil? && actor.id == 1
        actor.in_battle_team = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Get Actors
  # ------------------------------------------------------------------------
  # Because Game_Party was written in such a way that battle would never have 
  # less than the number of actors in the party, we need to slightly modify
  # how actors are handled.
  #
  # The optional :all parameter indicates that we should be looking at 
  # all party members, not just those tagged as active for battle
  # This is primarily relevant for menus, etc.
  #--------------------------------------------------------------------------
  def actors(all = false)
    if all
      @actors
    else
      @actors.select{|a| a.in_battle_team? }
    end
  end
  #--------------------------------------------------------------------------
  # * Active Battle team
  #--------------------------------------------------------------------------
  def battle_team
    @actors.select{|a| a.in_battle_team? }
  end
  #--------------------------------------------------------------------------
  # * Standby Actors (not on battle team)
  #--------------------------------------------------------------------------
  def standby_actors
    @actors.select{|a| !a.in_battle_team? }
  end
  #--------------------------------------------------------------------------
  # * Add an Actor
  #     actor_id : actor ID
  #--------------------------------------------------------------------------
  def add_actor(actor_id)
    # Get actor
    actor = $game_actors[actor_id]
    # If the party has less than party max and this actor is not in the party
    if !@actors.include?(actor)
      # Add actor
      @actors.push(actor)
      # If battle team is < max size, auto push
      if self.battle_team.size < MAX_BATTLE_MEMBERS
        add_battle_char(actor)
      end
      # Refresh player
      $game_player.refresh
      # Ensure actor array order
      @actors.sort_by!{|a| a.id}
    end
  end
  #--------------------------------------------------------------------------
  # * Remove Actor
  #     actor_id : actor ID
  #--------------------------------------------------------------------------
  def remove_actor(actor_id)
    # Delete actor
    actor = $game_actors[actor_id]
    remove_battle_char(actor)
    @actors.delete(actor)
    # Refresh player
    $game_player.refresh
  end
  #--------------------------------------------------------------------------
  # * Check Party Actor Existence
  #     actor_id : actor ID
  #--------------------------------------------------------------------------
  def actor_in_party?(actor)
    @actors.include?(actor)
  end
  #--------------------------------------------------------------------------
  # * Add Battle Teammate
  #     actor : Game_Actor object
  #--------------------------------------------------------------------------
  def add_battle_char(actor)
    if !actor_in_party?(actor)
      puts "Actor isn't in party"
      return false
    elsif self.battle_team.include?(actor)
      puts "Actor already in battle team"
      return false
    elsif self.battle_team.size >= MAX_BATTLE_MEMBERS
      puts "Team full"
      return false
    end
    actor.in_battle_team = true
  end
  #--------------------------------------------------------------------------
  # * Remove Battle Teammate
  #     actor : Game_Actor object
  #--------------------------------------------------------------------------
  def remove_battle_char(actor)
    if !self.battle_team.include?(actor)
      puts "Actor wasn't in team"
      return false
    end
    actor.in_battle_team = false
    true
  end
  #--------------------------------------------------------------------------
  # * Gain Gold (or lose)
  #     n : amount of gold
  #--------------------------------------------------------------------------
  def gain_gold(n)
    @gold = [[@gold + n, 0].max, 9999999].min
    # Add amount to total gold counter if positive
    $game_system.total_gold += n if n > 0
  end
  #--------------------------------------------------------------------------
  # * Lose Gold
  #     n : amount of gold
  #--------------------------------------------------------------------------
  def lose_gold(n)
    # Reverse the numerical value and call it gain_gold
    gain_gold(-n)
  end
  #--------------------------------------------------------------------------
  # * Increase Steps
  #--------------------------------------------------------------------------
  def increase_steps
    @steps = [@steps + 1, 9999999].min
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items Possessed
  #     item_id : item ID
  #--------------------------------------------------------------------------
  def item_number(item_id)
    # If quantity data is in the hash, use it. If not, return 0
    return @items.include?(item_id) ? @items[item_id] : 0
  end
  #--------------------------------------------------------------------------
  # * Get Number of Weapons Possessed
  #     weapon_id : weapon ID
  #--------------------------------------------------------------------------
  def weapon_number(weapon_id)
    # If quantity data is in the hash, use it. If not, return 0
    return @weapons.include?(weapon_id) ? @weapons[weapon_id] : 0
  end
  #--------------------------------------------------------------------------
  # * Get Amount of Armor Possessed
  #     armor_id : armor ID
  #--------------------------------------------------------------------------
  def armor_number(armor_id)
    # If quantity data is in the hash, use it. If not, return 0
    return @armors.include?(armor_id) ? @armors[armor_id] : 0
  end
  #--------------------------------------------------------------------------
  # * Get List of Items Possessed
  #--------------------------------------------------------------------------
  def all_items
    ary = []
    for i in 1...$data_items.size
      if item_number(i) > 0
        ary << $data_items[i]
      end
    end
    ary
  end
  #--------------------------------------------------------------------------
  # * Get List of Weapons Possessed
  #--------------------------------------------------------------------------
  def all_weapons
    ary = []
    for i in 1...$data_weapons.size
      if weapon_number(i) > 0
        ary << $data_weapons[i]
      end
    end
    ary
  end
  #--------------------------------------------------------------------------
  # * Get List of Armor Possessed
  #--------------------------------------------------------------------------
  def all_armors
    ary = []
    for i in 1...$data_armors.size
      if armor_number(i) > 0
        ary << $data_armors[i]
      end
    end
    ary
  end
  #--------------------------------------------------------------------------
  # * Get List of Essences Owned
  #--------------------------------------------------------------------------
  def all_essences
    [] # TODO
  end
  #--------------------------------------------------------------------------
  # * Gain Items (or lose)
  #     item_id : item ID
  #     n       : quantity
  #--------------------------------------------------------------------------
  def gain_item(item_id, n)
    # Update quantity data in the hash.
    if item_id > 0
      @items[item_id] = [[item_number(item_id) + n, 0].max, 999].min
    end
  end
  #--------------------------------------------------------------------------
  # * Gain Weapons (or lose)
  #     weapon_id : weapon ID
  #     n         : quantity
  #--------------------------------------------------------------------------
  def gain_weapon(weapon_id, n)
    # Update quantity data in the hash.
    if weapon_id > 0
      @weapons[weapon_id] = [[weapon_number(weapon_id) + n, 0].max, 99].min
    end
  end
  #--------------------------------------------------------------------------
  # * Gain Armor (or lose)
  #     armor_id : armor ID
  #     n        : quantity
  #--------------------------------------------------------------------------
  def gain_armor(armor_id, n)
    # Update quantity data in the hash.
    if armor_id > 0
      @armors[armor_id] = [[armor_number(armor_id) + n, 0].max, 99].min
    end
  end
  #--------------------------------------------------------------------------
  # * Lose Items
  #     item_id : item ID
  #     n       : quantity
  #--------------------------------------------------------------------------
  def lose_item(item_id, n)
    # Reverse the numerical value and call it gain_item
    gain_item(item_id, -n)
  end
  #--------------------------------------------------------------------------
  # * Lose Weapons
  #     weapon_id : weapon ID
  #     n         : quantity
  #--------------------------------------------------------------------------
  def lose_weapon(weapon_id, n)
    # Reverse the numerical value and call it gain_weapon
    gain_weapon(weapon_id, -n)
  end
  #--------------------------------------------------------------------------
  # * Lose Armor
  #     armor_id : armor ID
  #     n        : quantity
  #--------------------------------------------------------------------------
  def lose_armor(armor_id, n)
    # Reverse the numerical value and call it gain_armor
    gain_armor(armor_id, -n)
  end
  #--------------------------------------------------------------------------
  # * Determine if Item is Usable
  #     item_id : item ID
  # !!! Modified to check revival items
  #--------------------------------------------------------------------------
  def item_can_use?(item_id, all_actors = false)
    # If item quantity is 0
    if item_number(item_id) == 0
      # Unusable
      return false
    end
    # Get usable time
    occasion = $data_items[item_id].occasion
    # If in battle
    if $game_temp.in_battle
      # If useable time is 0 (normal) or 1 (only battle) it's usable
      return (occasion == 0 or occasion == 1)
    else
      # If the item's scope is designed for revival
      if [5, 6].include?($data_items[item_id].scope)
        dead_flag = false
        self.actors(all_actors).each do |actor|
          if actor.dead?
            dead_flag = true
            break
          end
        end
        # But no actors are actually dead
        if !dead_flag
          # Can't use it
          return false
        end
      end
      # If useable time is 0 (normal) or 2 (only menu) it's usable
      return (occasion == 0 or occasion == 2)
    end
  end
  #--------------------------------------------------------------------------
  # * Clear All Member Actions
  #--------------------------------------------------------------------------
  def clear_actions
    # Clear All Member Actions
    for actor in self.actors
      actor.current_action.clear
    end
  end
  #--------------------------------------------------------------------------
  # * Determine if Command is Inputable
  #--------------------------------------------------------------------------
  def inputable?
    # Return true if input is possible for one person as well
    for actor in self.actors
      if actor.inputable?
        return true
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Determine Everyone is Dead
  # Note: This may become relevant to change if substituting standby
  # characters into battle Golden Sun-style becomes a thing.
  #--------------------------------------------------------------------------
  def all_dead?
    # If number of party members is 0
    if $game_party.actors.size == 0
      return false
    end
    # If an actor is in the party with 0 or more HP
    for actor in self.actors
      if actor.hp > 0
        return false
      end
    end
    # All members dead
    return true
  end
  #--------------------------------------------------------------------------
  # * Slip Damage Check (for map)
  #--------------------------------------------------------------------------
  def check_map_slip_damage
    for actor in self.actors(:all)
      if actor.hp > 0 and actor.slip_damage?
        actor.hp -= [actor.maxhp / 100, 1].max
        if actor.hp == 0
          $game_system.se_play($data_system.actor_collapse_se)
        end
        $game_screen.start_flash(Color.new(255,0,0,128), 4)
        $game_temp.gameover = $game_party.all_dead?
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Random Selection of Target Actor
  #     hp0 : limited to actors with 0 HP
  #--------------------------------------------------------------------------
  def random_target_actor(hp0 = false, all_actors = false)
    # Initialize roulette
    roulette = []
    # Loop
    self.actors(all_actors).each do |actor|
      # If it fits the conditions
      if (not hp0 and actor.exist?) or (hp0 and actor.hp0?)
        # Get actor class [position]
        position = $data_classes[actor.class_id].position
        # Front guard: n = 4; Mid guard: n = 3; Rear guard: n = 2
        n = 4 - position
        # Add actor to roulette n times
        n.times do
          roulette.push(actor)
        end
      end
    end
    # If roulette size is 0
    if roulette.size == 0
      return nil
    end
    # Spin the roulette, choose an actor
    return roulette[rand(roulette.size)]
  end
  #--------------------------------------------------------------------------
  # * Random Selection of Target Actor (HP 0)
  #--------------------------------------------------------------------------
  def random_target_actor_hp0
    random_target_actor(true)
  end
  #--------------------------------------------------------------------------
  # * Smooth Selection of Target Actor
  #     actor_index : actor index
  #--------------------------------------------------------------------------
  def smooth_target_actor(actor_index, all_actors = false)
    # Get an actor
    actor = self.actors(all_actors)[actor_index]
    # If an actor exists
    if actor != nil and actor.exist?
      return actor
    end
    # Loop
    for actor in self.actors(all_actors)
      # If an actor exists
      if actor.exist?
        return actor
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Add New Quest
  #--------------------------------------------------------------------------
  def add_newquest(id)
    unless has_available?(id)
      @quests_new.push(id)
    end
  end
  #--------------------------------------------------------------------------
  # * Accept Quest
  #--------------------------------------------------------------------------
  def accept_quest(id)
    if !@quests_accepted.include?(id) and @quests_new.include?(id)
      @quests_new.delete(id)
      @quests_accepted.push(id)
    end
  end
  #--------------------------------------------------------------------------
  # * Complete Quest
  #--------------------------------------------------------------------------
  def complete(id)
    if !completed?(id, true) and @quests_accepted.include?(id)
      @quests_accepted.delete(id)
      @quests_repeating.delete(id)
      @quests_completed.push(id)
      if QuestData::RewardOnComplete
        $game_party.gain_gold(QuestData.gold(id))
        $game_party.actors(:all).each{|actor|
          unless actor.cant_get_exp?
            actor.exp += QuestData.exp(id)
          end
        }
        rewards = QuestData.reward(id)
        return if rewards.nil?
        #~~begin loop~~
        rewards.each{|reward|
          next if reward.is_a?(String)
          case reward[0]
          when 1 then $game_party.gain_item(reward[1], reward[2])
          when 2 then $game_party.gain_weapon(reward[1], reward[2])
          when 3 then $game_party.gain_armor(reward[1], reward[2])
          end
        }
        #~~end loop~~
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Repeat Quest
  #--------------------------------------------------------------------------
  def repeat(id)
    if completed?(id, true)
      @quests_completed.delete(id)
      @quests_repeating.push(id)
      @quests_new.push(id)
    end
  end
  #--------------------------------------------------------------------------
  # * Is Repeating?
  #--------------------------------------------------------------------------
  def repeating?(id)
    return @quests_repeating.include?(id)
  end
  #--------------------------------------------------------------------------
  # * Is Completed?
  #--------------------------------------------------------------------------
  def completed?(id, only=false)
    if only
      return @quests_completed.include?(id)
    else 
      return (@quests_completed.include?(id) or @quests_repeating.include?(id))
    end
  end
  #--------------------------------------------------------------------------
  # * Has quest in progress?
  #--------------------------------------------------------------------------
  def has_quest?(id, only=false)
    if only
      return @quests_accepted.include?(id)
    else
      return (@quests_accepted.include?(id) or @quests_completed.include?(id) or
              @quests_repeating.include?(id))
    end
  end
  #--------------------------------------------------------------------------
  # * Has new quest available?
  #--------------------------------------------------------------------------
  def has_available?(id, only=false)
    if only
      return @quests_new.include?(id)
    else
      return (@quests_new.include?(id) or @quests_accepted.include?(id) or 
              @quests_completed.include?(id) or @quests_repeating.include?(id))
    end
  end
  #--------------------------------------------------------------------------
  # * Get Number of Available Essences, not equipped
  #     item_id : item ID
  #--------------------------------------------------------------------------
  def number_free_essence(essence_id)
    return 0 if essence_id == 0
    # If quantity data is in the hash, use it. If not, return 0
    return @essences.include?(essence_id) ? @essences[essence_id] : 0
  end
  #--------------------------------------------------------------------------
  # * Get Number of Essences possessed, across all actors
  #     item_id : item ID
  #--------------------------------------------------------------------------
  def number_all_essence(essence_id)
    return 0 if essence_id == 0
    # Init count
    count = 0
    # If the party pool has the essence
    if @essences.include?(essence_id)
      count += @essences[essence_id]
    end
    # Check each actor
    @actors.each do |actor|
      # If the actor has the essence
      if actor.essences.include?(essence_id)
        # Add however many they have to the count
        count += actor.essences.select{|i| i == essence_id}.size
      end
    end
    return count
  end
  #--------------------------------------------------------------------------
  # * Gain Essence
  # Adds an essence to the party's pool of essences
  # Called when acquiring an essence "item"
  #
  # essence_id: ID of the Essence object to be added.
  # n: number of essence to be added
  #--------------------------------------------------------------------------
  def gain_essence(essence_id, n = 1)
    return if essence_id == 0
    # Update the number of essences, ensuring quantity is between 0 and 99.
    @essences[essence_id] = (number_free_essence(essence_id) + n).clamp(0, MAX_ESSENCE)
  end
  #--------------------------------------------------------------------------
  # * Lose Essence
  # Removes an essence from the party's pool of essences
  # 
  # essence_id: ID of the Essence object to be removed.
  # amount: amount to remove
  #--------------------------------------------------------------------------
  def lose_essence(essence_id, n = 1)
    # Gain in reverse
    gain_essence(essence_id, -n)
  end
  #--------------------------------------------------------------------------
  # * Get Battle Drops
  # Adds associated items from battle to party inventory
  # gold - flat gold amount
  # treasures - treasure array
  #--------------------------------------------------------------------------
  def gain_battle_spoil(gold, treasures)
    gain_gold(gold)
    for item in treasures
      case item
      when RPG::Item
        gain_item(item.id, 1)
      when RPG::Weapon
        gain_weapon(item.id, 1)
      when RPG::Armor
        gain_armor(item.id, 1)
      when RPG::Essence
        gain_essence(item.id, 1)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Debugging
  #--------------------------------------------------------------------------
  def to_s
    "Actors: #{@actors}\nBattle Team: #{self.battle_team.map{|a| a.name}}\nStandby: #{self.standby_actors.map{|a| a.name}}"
  end
end