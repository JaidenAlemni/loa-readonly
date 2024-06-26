#==============================================================================
# ** BattleTarget Module
#------------------------------------------------------------------------------
#  Utility for managing targets in battle
#==============================================================================
module BattleTarget
  #--------------------------------------------------------------------------
  # * Start Selection
  # Determines the values to pass to "start_target_select" in battle based
  # on the object passed. Returns the following as an array:
  #   - Arrow type : (:single, :all)
  #   - Arrow target : (:actor, :enemy, :all, :only_self)
  #   - Start index : The actor/enemy index to start, based on object conditions. default 0
  # Arguments:
  #     object (battler, item or skill)
  #     action (:attack, :hold, :skill, :item) for sanity
  #--------------------------------------------------------------------------
  def self.start_selection(battler, obj, action)
    # Something went wrong (invalid battler, skill or item)
    if obj == nil || battler == nil
      return nil
    end
    # Invalid object
    if !obj.is_a?(RPG::Item) && !obj.is_a?(RPG::Skill)
      GUtil.write_log("invalid object passed to BattleTarget #{obj}")
      return nil
    end
    # Special overrides
    if obj.has_extension?(:TARGET_ALL)
      return [:all, :all, 0]
    elsif obj.has_extension?(:TARGET_RANDOM) || (battler.fork_skill_valid?(obj))
      if obj.scope <= 2 # Enemies (or none)
        return [:all, :enemy, 0]
      elsif obj.scope > 2 # Allies
        return [:all, :actor, 0]
      end
    end
    # Case by scope 
    case obj.scope
    when 0 # None (start_target_select won't be called)
      nil
    when 1 # Single enemy
      get_index = filter_battler(:enemy)&.index
      return nil if get_index.nil?
      [:single, :enemy, get_index]
    when 2 # All enemies
      [:all, :enemy, 0]
    when 3 # Single ally
      get_index = filter_battler(:actor)&.index
      return nil if get_index.nil?
      [:single, :actor, 0]
    when 4 # All allies
      [:all, :actor, 0]
    when 5 # Single Ally (0hp)
      # Default to the actor with no HP
      get_index = filter_battler(:actor, :hp0)&.index
      [:single, :actor, get_index.nil? ? 0 : get_index]
    when 6 # All allies (hp0)
      [:all, :actor, 0]
    when 7 # User
      [:single, :only_self, battler.index]
    end      
  end
  #--------------------------------------------------------------------------
  # * Get Individual Battler
  # Gets the specified Game_Battler from either the Game_Party or Game_Troop based on index
  # (Replaces smooth_target_enemy)
  #     battler_type : either :actor or :enemy
  #     index : Game_Party or Game_Troop index
  #     filter : When set, seeks the next available battler
  #     params : Additional filter parameters, like min/max, etc.
  #--------------------------------------------------------------------------
  def self.individual(battler_type, index, filter = :any, *params)
    # Forego all of it if the index is -1 (cleared action)
    return [] if index == -1
    # Find target
    target = []
    case battler_type
    when :actor
      battler = $game_party.actors[index]
    when :enemy
      battler = $game_troop.enemies[index]
    else
      GUtil.write_log("Invalid BattleTarget#individual battler_type")
    end
    # Return the battler if valid
    target.push(battler) if battler.exist?
    # If the individual index fails, and a filter is chosen, 
    # return the next existing target in the troop
    if filter && target.empty?
      new_target = filter_battler(battler_type, filter, *params)
      target = new_target.nil? ? [] : [new_target]
    end
    # Return target (as array)
    target
  end
  #--------------------------------------------------------------------------
  # * Get multiple battlers
  # Selects multiple battlers, filtered optionally by condition (returns an array)
  #   battler_type : either :actor, :enemy, or :all
  #   args : additional arguments for certain filters
  #   filter : limit selection based on certain conditions. "none" selects all battlers
  #--------------------------------------------------------------------------
  def self.multiple(battler_type, filter = :none, args = [])
    targets = []
    case battler_type
    when :actor
      battlers = $game_party.actors 
    when :enemy
      battlers = $game_troop.enemies 
    when :all
      battlers = $game_party.actors + $game_troop.enemies
    end
    # Loop
    battlers.each do |battler|
      case filter
      when :hp0
        next if !battler.hp0?
      else
        targets.push(battler) if battler.exist?
      end      
    end
    targets
    # if obj.has_extension?(:TARGET_RANDOM)
    #   # Create targets to select from
    #   random_targets = @target_battlers.dup
    #   # Remove the previous target from the roll
    #   if @last_target != nil && random_targets.size > 1
    #     random_targets.delete(@last_target)
    #   end
    #   # Select a random target
    #   selected_target = rand(random_targets.size)
    #   @target_battlers = [random_targets[selected_target]]
    #   @last_target = @target_battlers[0]
    # end
  end
  #--------------------------------------------------------------------------
  # * Target Validation
  # Confirms the target selection for an actor or enemy is valid before 
  # doing an action
  #   battler : the Game_Battler who is being assigned the objects
  #--------------------------------------------------------------------------
  def self.validate(battler)
    battler.targets.each do |target|
      if (!battler.current_action.for_one_friend_hp0? && !target.exist?) || 
         (battler.current_action.for_one_friend_hp0? && !target.hp0?)
        battler.targets.delete(target)
      end
    end
    battler.targets.compact!
    # Re-roll if all possible targets were deleted
    if battler.targets.empty?
      decision(battler)
    end
  end
  #--------------------------------------------------------------------------
  # * Target Decision
  # Creates the battler's targets
  #   battler : the Game_Battler who is being assigned the objects
  #      temp : for enemies--use their temporary action instead
  #--------------------------------------------------------------------------
  def self.decision(battler, temp = false)
    # Redacted
  end
  #--------------------------------------------------------------------------
  # * Get Random Battler
  #  Selectes a random battler from Game_Party / Game_Troop
  #     battler_type : either :actor or :enemy, or :all
  #     num : number of battlers to return (as an array)      
  #     args : additional arguments for certain filters
  #     filter : Limit selection to certain conditions. 
  #       :hp0 - Only include battlers with 0hp
  #       :exclude_last - removes the last targeted battler from the selection, if > 1 targets 
  #                       arguments: [battler.last_target]
  #--------------------------------------------------------------------------
  def self.random(battler_type, num = 1, filter = :none, *args)
    # Initialize selection array
    selection = []
    # Filter based on battler type
    battlers = 
      case battler_type
      when :actor
        $game_party.actors 
      when :enemy
        $game_troop.enemies
      when :all
        $game_troop.enemies + $game_party.actors
      end
    # Filter the battlers
    battlers.each do |battler|
      # Filter out certain battlers
      case filter
      when :hp0
        battlers.delete(battler) unless battler.hp0?
      when :exclude_last
        battlers.delete(battler) if battler == args[0]
      when :no_duplicates
        selection << battler if battler.exist?
      end
    end
    if filter == :no_duplicates
      return selection.shuffle!
    end
    # Fill the selection array randomly
    b_size = battlers.size
    if b_size < 2
      # Nothing to randomly select from
      selection = battlers
    else
      # Random selection (based on threat if enemy -> actor)
      if battler_type == :actor && args[0]&.enemy?
        a_threats = battlers.map{|b| b.threat}
        target_index = GUtil.wr_select(a_threats)
        selection = [battlers[target_index]]
      else
        num.times do
          pick = battlers[rand(b_size)]
          selection << pick
        end
      end
    end
    # Return the selection as an array
    selection
  end
  #--------------------------------------------------------------------------
  # * Filter Index
  #  Returns the index of the battler based on certain filtering conditions
  #     battler_type : either :actor or :enemy      
  #     filter : Limit selection to certain conditions.   
  #     params: custom parameters. for example, when filtering by :stat, gets the
  #             stat to filter by from the array
  #       :max - Filters by high to low
  #--------------------------------------------------------------------------
  def self.filter_battler(battler_type, filter = :any, *params)
    # Filter based on battler type
    battlers = 
      case battler_type
      when :actor
        $game_party.actors.dup 
      when :enemy
        $game_troop.enemies.dup
      else
        $game_troop.enemies.dup + $game_party.actors.dup
      end
    case filter
    when :hp0
      filter_battlers = battlers.select{|b| b.hp0?}
    when :current_hp
      filter_battlers = battlers.sort_by(&:hp)
      # Lowest goes first, so flip if set to check max
      if params[0] == :max
        filter_battlers.reverse!
      end
    when :current_sp
      filter_battlers = battlers.sort_by(&:sp)
      # Lowest goes first, so flip if set to check max
      if params[0] == :max
        filter_battlers.reverse!
      end
    when :stat
      stat, sort = params
      filter_battlers = battlers.sort_by(&stat)
      # Lowest goes first, so flip if set to check max
      if sort == :max
        filter_battlers.reverse!
      end
    when :index
      index = params[0]
      filter_battlers = battlers[index] ? [battlers[index]] : []      
    when :state
      # Get state id from parameters
      filter_battlers = battlers.select{|b| b.states.include?(params[0])}
    when :any
      filter_battlers = battlers.delete_if{|b| !b.exist?}
    end
    if filter_battlers.empty?
      nil
    else
      filter_battlers.first
    end
  end
  #--------------------------------------------------------------------------
  # * Last Attacker
  #  Returns the battler that last attacked this one
  #--------------------------------------------------------------------------
  def self.last_attacker(type, battler)
    battlers = 
      case type
      when :actor
        $game_party.actors
      when :enemy
        $game_troop.enemies
      else
        $game_troop.enemies + $game_party.actors
      end
    last_targets = battlers.select{|b| b.last_target == battler && battler != b}
    last_targets.first
  end
end