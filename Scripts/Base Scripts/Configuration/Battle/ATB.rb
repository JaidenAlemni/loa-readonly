#==============================================================================
# ** ATB Controller
#------------------------------------------------------------------------------
#  This module manages all aspects of the Time Bar in battle
#==============================================================================
module ATB
  module Config
    # Battle speed (Determines how quickly ATP is accumulated)
    # Percentage rate of gain (1 = 100%)
    BATTLE_SPEEDS = [25,75,100,150,250]
    DEFAULT_SPEED = BATTLE_SPEEDS[2] # Make sure this matches a speed in the array
    MAX_SPEED = 1000
    MIN_SPEED = 25

    # These values modulate the ATB calculation

    # REDACTED

    # Configuration of the Time Bar
    Bar_Skin = 'ATBBar' # Name of the graphic file that represents the bar, must be
    # ---------------------------------------------
    # Individual icons for actors
    #
    def self.actor_icon(actor_id)
      case actor_id
      when 1 # Oliver
        return 'Oliver'
      when 2 # Sarina
        return 'Sarina'
      when 3 # Arlyn
        return 'Arlyn'
      when 4
        return 'Minerva'
      when 5 # Azel
        return 'Azel'
      when 7 # Baldric
        return 'Baldric'
      else
        return 'Oliver'
      end
    end
    # ---------------------------------------------
    # Individual icons for enemies
    #
    def self.enemy_icon(enemy_id)
      case enemy_id
      when 5, 6
        return 'Mushdoom'
      when 7
        return 'Bee'
      when 8 
        return 'BogDem'
      #when 9 
        #return 'WolfBandit'
      #when 12
        #return 'Mimic'
      else
        return 'Enemy'
      end
    end
    # ---------------------------------------------
    # Percentage value that a state has on a battler's ATB tick
    # 
    def self.state_speed_effect(state_id)
      $data_states[state_id].atb_speed_factor
    end
    # ---------------------------------------------
    # One-time percentage effect a state has on battlers ATB
    #
    def self.state_flat_effect(state_id)
      $data_states[state_id].atb_flat_change
    end
  end
  #--------------------------------------------------------------------------
  include Config
  #--------------------------------------------------------------------------
  # * Time Bar Battlers Array
  # Instead of separate arrays, battlers are handled instead by state
  # |     ---- COMMAND ----    | -- WAIT -- |[ ACTION ] 
  # | :idle, :command, :committed |  :ready    |[:action ]
  #
  # :idle - Not command ready, none selected
  # :command - Awaiting command / input, atp < commit
  # :committed - Command selected, atp <= commit
  # :ready - Committed, ready for action
  # :action - Preparing to do action, no countup
  #--------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  # * Setup ATB Controller
  #--------------------------------------------------------------------------
  def self.setup
    @global_countup = false
    # Init battler array
    @battlers = []
  end
  #--------------------------------------------------------------------------
  # * Start ATB for the first time
  #--------------------------------------------------------------------------
  def self.battle_start   
    # Loop in battlers to assign to array and manage preempt/ambush conditions
    ($game_party.actors + $game_troop.enemies).each do |battler|
      battler.init_atb
      if battler.movable? && !battler.dead?
        $scene.spriteset.set_stand_by_action(battler.actor?, battler.index)
        battler.countup = true
        battler.atb_state = :command if battler.actor?
        battler.atb_start_position
        battler.dead_anim = false
      elsif battler.dead?
        battler.dead_anim = true
      end
      # Actors advantage
      if $game_temp.battle_preemptive
        if battler.enemy?
          battler.atp = 0
          # enemies don't count up until actors take their first action
          battler.countup = false
        # Set actors to the front of the ATB bar
        else
          if battler.movable? && !battler.dead?
            battler.atp = COMMIT_ATP - 1
          end
        end
      # Enemies advantage
      elsif $game_temp.battle_ambushed
        if battler.enemy?
          if battler.movable? && !battler.dead?
            battler.atb_state = :committed
            battler.atp = COMMIT_ATP - 1
          end
        end
      end
      $scene.spriteset.set_stand_by_action(battler.actor?, battler.index)
      @battlers << battler
    end
    # Refresh ATB bar
    $scene.spriteset.refresh_atb
    # Start countup
    resume_atb
  end
  #--------------------------------------------------------------------------
  # * Get all battlers
  #--------------------------------------------------------------------------
  def self.battlers
    @battlers
  end
  #--------------------------------------------------------------------------
  # * Get next commandable battler
  # TODO: Ensure this doesn't result in unexpected switching
  #--------------------------------------------------------------------------
  def self.find_next_actor
    commandable = filter_battlers(:command)
    return commandable.first if commandable.size < 2
    # Bypass holding actors
    # commandable.each do |actor|
    #   next if actor.holding?
    #   return actor
    # end
    # All actors are holding, default to first one in array
    # (Or returns nil if there are none)
    return commandable.first
  end    
  #--------------------------------------------------------------------------
  # * Quick method for filtering battlers by ATB state
  # ATBController.filter_battlers(:idle, :command) => array
  #--------------------------------------------------------------------------      
  def self.filter_battlers(*filters)
    @battlers.select {|battler| filters.include?(battler.atb_state) }
  end
  #--------------------------------------------------------------------------
  # * Stop Bar
  #--------------------------------------------------------------------------
  def self.stop_atb
    @global_countup = false
  end
  #--------------------------------------------------------------------------
  # * Resume Bar
  #--------------------------------------------------------------------------
  def self.resume_atb
    @global_countup = true
  end
  #--------------------------------------------------------------------------
  # * Update ATB
  #--------------------------------------------------------------------------
  def self.update(battle_speed)
    return unless @global_countup
    # Tick up each battler
    @battlers.each do |battler|
      # Check counting
      next unless battler.ticking?
      # ACTION READY
      if battler.ready_for_action?
        # Handle atp overshoot
        battler.atp = MAX_ATP
        battler.atb_state = :action
        battler.countup = false
      # COMMIT READY
      elsif battler.ready_for_commit?
        battler.atp = COMMIT_ATP
        commit_action(battler)
      # COMMAND READY (Enemy)
      elsif battler.ready_for_input? && battler.enemy?
        enemy_decide_action(battler)
      # Normal Tick
      else
        atb_tick(battler, battle_speed)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Battler Commit Action
  #--------------------------------------------------------------------------
  def self.commit_action(battler)
    if battler.enemy?
      # Apply the action
      battler.current_action = battler.temp_action
      battler.temp_action = nil
      # If the action is "Guard"
      if battler.current_action.kind == :basic && battler.current_action.basic == :guard
        text = BattleDescriptions.special_text(battler.name, :en_defend)
        # Announce action
        $scene.pop_help(text, BattleConfig::ACTION_START_WAIT, false, battler)
      end
      # TODO: Can actually announce the spell name here?
      battler.atb_state = :ready
      # Set standby animation
      $scene.spriteset.set_stand_by_action(false, battler.index)
    else
      # Ignore holding actors
      return if battler.holding?
      # Hardmode check
      # if !input_selected? && $game_options.battle_hardmode
      #   # Force no action
      #   battler.current_action.kind = :basic
      #   battler.current_action.basic = :none
      #   # If the battler whose turn is ending was the active one
      #   if battler == @active_battler
      #     # End window or target input
      #     if @active_window
      #       end_window_select
      #     end
      #     if @active_arrow
      #       end_target_select(true)
      #     end
      #     @input_state = nil
      #     disable_command_window(true)
      #     confirm_actor_input
      #   end
      #   # Display balloon
      #   @spriteset.start_balloon(battler.actor?, battler.index, 'Failed_Balloon')
      # end
      # Otherwise Exit unless an action was selected
      return unless battler.input_selected?
      # Set ATB state
      battler.atb_state = :ready
      # Determine if casting
      if battler.current_action.kind == :skill
        battler.skilling = true
      end
      # Announce action
      action_str = BattleDescriptions.action(battler.name, battler.current_action, 'Commit')
      #$scene.pop_help(action_str, 1)
      # Set actor to standby animation
      $scene.spriteset.set_stand_by_action(true, battler.index)
    end
  end
  #--------------------------------------------------------------------------
  # * Enemy Decide Action (Command)
  #--------------------------------------------------------------------------
  def self.enemy_decide_action(battler)
    # Create the action in the context of battle
    # (Proof of concept; works well. Untested and not quite needed yet.)
    #instance_exec &battler.create_action
    # Make the action (but do not apply it yet)
    battler.temp_action = battler.make_action
    # If enemy was immovable
    return if battler.temp_action.nil?
    # Determine if casting
    battler.skilling = true if battler.temp_action.kind == :skill
    battler.weapon_id = battler.temp_action.weapon_id
    # Determine if blocking
    battler.defense_pose = true if battler.temp_action.basic == :guard
    # Announce "attacking" if actually doing nothing
    if battler.temp_action.kind == :basic && battler.temp_action.basic == :none
      fakeout = Game_BattleAction.new
      fakeout.basic = :attack
      action_str = BattleDescriptions.action(battler.name, fakeout, 'Commit')
      #$scene.pop_help(action_str, 1)
    else
      # Announce action
      action_str = BattleDescriptions.action(battler.name, battler.temp_action, 'Commit')
      #$scene.pop_help(action_str, 1)
    end
    battler.atb_state = :committed
    # Set actor to standby animation
    # FIXME Since the action is temporary, the correct idle won't actually display here
    #@spriteset.set_stand_by_action(false, battler.index)
    # Start balloon
    if fakeout
      $scene.spriteset.start_balloon(false, battler.index, fakeout.balloon)
    else
      $scene.spriteset.start_balloon(false, battler.index, battler.temp_action.balloon)
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Battler's ATP
  # Returns the amount to add per update frame
  #--------------------------------------------------------------------------
  def self.atb_tick(battler, battle_speed)
    # Apply state effects
    battler.apply_atb_state_effects
    # Ready to commit
    if battler.atb_state == :ready
      # If a nil action was committed, something went wrong
      # abort and reset ATB position as a catch
      if battler.current_action.nil?
        GUtil.write_log("Nil action on #{battler}! Trace: #{caller}")
        battler.atb_reset
        battler.countup = true
        return
      end
      battler.atp += commit_tick(battler, battler.state_atb_modifier, battle_speed)
    # Not yet selected a command, and reached "ready" line
    elsif !battler.ready_for_commit? && battler.atp >= COMMIT_ATP
      # Handle overshoot and exit
      battler.atp = COMMIT_ATP
      return
    # Other states
    else
      tick = base_tick(battler.battle_speed, battler.state_atb_modifier, battle_speed)
      if (battler.actor? && battler.holding?)
        battler.atp += tick * HOLD_PERCENT / 100
      else
        battler.atp += tick
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Handle escape failure
  #--------------------------------------------------------------------------
  def self.escape_failure(active_battler)
    # Escaping battler gets ATP 0
    active_battler.atp = 0
    # Set actors back a bit
    $game_party.actors.each do |actor|
      # Ignore if charging a skill or temp
      next if [:ready, :action].include?(actor.atb_state)
      actor.atp -= actor.atp * rand(100) / 100
    end
  end
  #--------------------------------------------------------------------------
  # * Process action ending
  #--------------------------------------------------------------------------
  def self.action_ending(active_battler, input_battler)
    # Increment action count
    active_battler.action_count += 1
    # Reset battler ATB state
    active_battler.atb_reset
    active_battler.countup = true unless active_battler.temp_member
    if active_battler.enemy? && active_battler.current_action.basic == :escape
      active_battler.escape
    end
    active_battler.current_action.clear
    @battlers.each do |member|
      # Temp party members aren't included
      next if member.temp_member
      # Perform revival
      if member.revival
        member.dead_anim = false
        member.atb_reset
        member.countup = true
        member.atb_state = :command
        member.revival = false
      end
      # Mark dead battlers
      if member.dead?
        # Clear the inputting battler if they died
        if input_battler == member
          @input_battler = nil
        end
        # Remove from ATB and set dead
        member.dead_anim = true
        member.atb_reset
        member.current_action.clear
      # Setup valid actors
      else
        # If the actor finished their action (active battler)
        if member == active_battler && member.movable?
          member.countup = true
          if member.actor?
            member.atb_state = :command
          else
            member.generate_roll_atp
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Base Tick
  #--------------------------------------------------------------------------
  # (this is the normal tick for actions, and the base for command state)
  # State offset is constrained to no more than 150 
  def self.base_tick(battler_speed, state_offset, battle_speed)
    # REDACTED
  end
  #--------------------------------------------------------------------------
  # * Calculate Committed Action Tick
  #--------------------------------------------------------------------------
  def self.commit_tick(battler, state_offset, battle_speed)
    tick = base_tick(battler.battle_speed, state_offset, battle_speed)
    # Branch by action type
    case battler.current_action.kind
    when :basic
      if battler.current_action.basic == :guard
        # Guarding enemies tick slower
        return tick * GUARD_PERCENT / 100
      else
        # Basic attack speed scales with agility (max 200%)
        return tick * GUtil.percent_scale(battler.agi, ACTION_MIN_SPEED, ACTION_MAX_SPEED) / 100
      end
    when :skill
      skill = $data_skills[battler.current_action.skill_id]
      if skill.nil?
        GUtil.write_log("Invalid Skill\nBattler: #{battler.name} Action: #{battler.current_action}")
      end
      calc_stat = skill.magic? ? battler.int : battler.dex
      return tick * battler.skill_speed(calc_stat) / 100
    when :item
      return tick * battler.item_speed / 100
    end
  end
end

class Game_Battler
  attr_accessor :atb_state
  attr_accessor :state_atb_modifier
  #--------------------------------------------------------------------------
  # * Initialize ATB values
  #--------------------------------------------------------------------------
  def init_atb
    atb_reset
    @roll_atp = 0
    @state_atb_modifier = 100
    if self.enemy?
      generate_roll_atp
    end
  end
  #--------------------------------------------------------------------------
  # * ATB Initial Bar Placement
  #--------------------------------------------------------------------------
  def atb_start_position
    # Generate a random number (1-10)
    placement_offset = rand(10) + 1
    # Set starting position
    self.atp = 
      if self.enemy?
        @roll_atp / 2 * placement_offset / 10
      else
        ATB::COMMIT_ATP / 2 * placement_offset / 10
      end
  end
  #--------------------------------------------------------------------------
  # * Reset ATB state
  #--------------------------------------------------------------------------
  def atb_reset
    # Active Time Points
    @atp = 0
    @countup = false
    @skilling = false
    @atb_state = :idle #:idle, :command, :commit, :ready, :action
  end
  #--------------------------------------------------------------------------
  # * Set ATP (corrects values out of range)
  #--------------------------------------------------------------------------
  def atp=(n)
    min = self.committed_action? ? ATB::COMMIT_ATP + 1 : 0
    max = self.committed_action? ? ATB::MAX_ATP : ATB::COMMIT_ATP + 1
    @atp = n.clamp(min, max)
  end
  #--------------------------------------------------------------------------
  # * Set ATP to a certain percentage
  # (not used anywhere)
  #--------------------------------------------------------------------------
  def set_atp_percent(percent)
    self.atp = ATB::MAX_ATP * percent / 100
  end
  #--------------------------------------------------------------------------
  # * Generate Commit ATP (Enemy)
  # Determines when an enemy should announce their skill. Unlike actors,
  # enemies need to decide and announce their action a little sooner.
  #
  # TODO - Eventually change how soon enemies decide based on enemy type
  #--------------------------------------------------------------------------
  def generate_roll_atp
    # Exit if the enemy already selected an action
    #return @commit_atp - 10 if self.input_selected? || self.committed_action?
    # Determine if it's appropriate for the enemy to select an input
    @roll_atp = rand(EnemyAI.atb_roll_range(self.id))
    #puts "Battler #{enemy.name} commits at #{value}"
  end
  #--------------------------------------------------------------------------
  # * Calculate ATB gain/loss based on states applied [% change, total %]
  # percent_change: the flat percentage amount that the ATB changes based
  #   on a state. ex: "Stun" reduces the character's ATB by 20%, setting them back
  # total_gain: the percentage in which the ATB tick speed is modulated. 
  #   ex. "Frozen" reduces the speed by 1/2. "Bind" reduces speed to 0. 
  #--------------------------------------------------------------------------
  def apply_atb_state_effects
    if self.states.empty?
      @state_atb_modifier = 100
      return
    end
    # Init gain
    total_gain = 0
    percent_change = 0
    # Modulate battler speed based on states
    # Get all of the states speed modulation values and average them
    # Death overrides all changes
    if self.states.include?(1)
      @state_atb_modifier = 0
      return
    end
    # Then calculate and return the speed modulation
    count = 0
    self.states.each do |state_id|
      state = $data_states[state_id]
      fe = state.atb_flat_change
      percent_change += fe
      # Immediately remove this state once its effect has been applied
      self.remove_state(state_id) if fe != 0
      # Add the total gain based on speed modulation
      total_gain += state.atb_speed_factor
      count += 1
      # Average
      percent_change /= count
      total_gain /= count
    end
    # Flat change
    change = (@atp * percent_change / 100).round
    self.atp += change
    # Overall change
    @state_atb_modifier = total_gain
  end
  #--------------------------------------------------------------------------
  # * Skill Cast Speed
  # Determine stat for calc (:dex or :int)
  #--------------------------------------------------------------------------
  def skill_speed(stat)
    GUtil.percent_scale(stat, ATB::SKILL_MIN_SPEED, ATB::SKILL_MAX_SPEED)
  end
  #--------------------------------------------------------------------------
  # * Item Cast Speed
  #--------------------------------------------------------------------------
  def item_speed
    GUtil.percent_scale(self.agi, ATB::ITEM_MIN_SPEED, ATB::ITEM_MAX_SPEED)
  end
  #--------------------------------------------------------------------------
  # * Ticking / Counting up determinant
  #--------------------------------------------------------------------------
  def ticking?
    @countup
  end
  #--------------------------------------------------------------------------
  # * Input chosen? (Ready to commit)
  #--------------------------------------------------------------------------
  def input_selected?
    @atb_state == :committed
  end
  #--------------------------------------------------------------------------
  # * Committed action (and counting up?)
  #--------------------------------------------------------------------------
  def committed_action?
    @atb_state == :ready
  end
  #--------------------------------------------------------------------------
  # * Ready for action? (Finished committing)
  #--------------------------------------------------------------------------
  def ready_for_action?
    atp_full? && committed_action?
  end
  #--------------------------------------------------------------------------
  # * Ready for commit? (Finished inputting)
  #--------------------------------------------------------------------------
  def ready_for_commit?
    return false unless @atp # Battlers aren't being initialized with atp
    @atp >= ATB::COMMIT_ATP && input_selected?
  end
  #--------------------------------------------------------------------------
  # * Ready for input? (Command permitted)
  #--------------------------------------------------------------------------
  def ready_for_input?
    return false unless @atp # Battlers aren't being initialized with atp
    return false if input_selected?
    return false if @atp >= ATB::COMMIT_ATP
    (self.actor? && @atb_state == :command) || @atp >= @roll_atp
  end
  #--------------------------------------------------------------------------
  # * ATP Full? (End of bar)
  #--------------------------------------------------------------------------
  def atp_full?
    return false unless @atp # Battlers aren't being initialized with atp
    @atp >= ATB::MAX_ATP
  end
end

class Game_Actor < Game_Battler
  alias atb_actor_setup setup
  def setup(actor_id)
    atb_actor_setup(actor_id)
    @speed_plus = 0
  end
  #--------------------------------------------------------------------------
  # * Base Speed (From DB)
  #--------------------------------------------------------------------------
  def base_speed
    $data_actors[@actor_id].base_speed
  end
  #--------------------------------------------------------------------------
  # * Update Auxillary Stats
  # Instead of costly methods every time auxillary stats are fetched (speed_plus, etc.)
  # this method is used to update those stat variables only when necessary,
  # such as on equipment change or actor level up.
  #--------------------------------------------------------------------------
  def update_aux_stats
    # Update speed plus
    # Equipment
    n = 0
    armor1 = $data_armors[@armor1_id]
    armor2 = $data_armors[@armor2_id]
    armor3 = $data_armors[@armor3_id]
    armor4 = $data_armors[@armor4_id]
    n += armor1 != nil ? armor1.speed_plus : 0
    n += armor2 != nil ? armor2.speed_plus : 0
    n += armor3 != nil ? armor3.speed_plus : 0
    n += armor4 != nil ? armor4.speed_plus : 0
    # Essence
    # 
    @speed_plus = n
  end
  #--------------------------------------------------------------------------
  # * Battle Speed
  #--------------------------------------------------------------------------
  def battle_speed
    # REDACTED
  end
  #--------------------------------------------------------------------------
  # * Equipment / essence speed enhancement
  #--------------------------------------------------------------------------
  def speed_plus
    @speed_plus ||= 0
  end
end

class Game_Enemy < Game_Battler
  def base_speed
    $data_enemies[@enemy_id].base_speed

  end
  #--------------------------------------------------------------------------
  # * Battle Speed
  #--------------------------------------------------------------------------
  def battle_speed
    self.base_speed
  end
end