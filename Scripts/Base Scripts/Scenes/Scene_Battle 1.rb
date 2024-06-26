#==============================================================================
# Sideview Battle System Version 3.0xp
# Custom system designed by Jaiden
# Based on SBS by Enu, ported by Atoa
#--------------------------------------
# Scene Battle Part 1:
# Battle initialization and main battle loop
#==============================================================================
class Scene_Battle
  ### Include configuration ###
  include BattleConfig
  # Constants for escaping
  WIN = 0
  ESCAPE = 1
  LOSE = 2
  #--------------------------------------------------------------------------
  # * Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :spriteset
  attr_accessor :message_window
  attr_accessor :actor_command_window
  attr_accessor :battle_speed
  attr_accessor :prev_battle_speed
  #--------------------------------------------------------------------------
  # * Main scene processing
  #--------------------------------------------------------------------------
  def main
    # Begin battle
    start
    # Setup ATB
    setup_atb
    # Process the transition into battle
    process_transition
    40.times do 
      Graphics.update
    end
    Graphics.freeze
    # Create the viewport (and windows)
    create_viewport
    # Process the transition into battle
    process_transition
    # Begin first phase
    prebattle_start
    # Main battle update loop
    loop do
      Graphics.update
      Input.update
      # Call main frame update
      if Input.triggerex?(:F11)
        GameSetup.take_screenshot
      end
      update
      break if $scene != self
    end
    # Terminate battle and determine if victory or map scene
    terminate
  end
  #--------------------------------------------------------------------------
  # * Begin battle processing
  #--------------------------------------------------------------------------
  def start
    # Flag start
    @phase = 1
    # For modulating speed
    @battle_speed = $game_options.battle_speed
    @prev_battle_speed = $game_options.battle_speed
    # Fast forward factor
    @ff_factor = 
      if $game_options.battle_speed < 100
        5
      elsif $game_options.battle_speed == 100
        4
      else
        3
      end 
    # Set temporary variables
    $game_temp.battle_turn = 0
    $game_temp.battle_actions = 1 # We need to start at one, since enemies aren't supposed to act until turn 1
    $game_temp.in_battle = true
    $game_temp.battle_event_flags.clear
    $game_temp.battle_abort = false
    $game_temp.battle_main_phase = false
    $game_temp.battleback_name = $game_map.battleback_name
    $game_temp.forcing_battler = nil
    @switch_actor = false # Flag for swapping actors
    # Initialize battle event interpreter
    $game_system.battle_interpreter.setup(nil, 0)
    # Load game troops
    @troop_id = $game_temp.battle_troop_id
    $game_troop.setup(@troop_id)
    # Check if they're immortal 
    for enemy in $game_troop.enemies
      enemy.true_immortal = enemy.immortal
    end
    all_battlers.each{|b| b.reset}
    # Setup turn counting
    @battler_count = (all_battlers.size / 2).round
    # Timer for input timeout
    @input_timer = nil
    @conditions_timer = 0
    # Center camera
    zoom, cam_x, cam_y = $game_troop.camera_setup
    # A bit silly, but allows for the "zoom in" effect from outside of battle?
    Camera.zoom = zoom #(zoom == 2.0 ? 3.0 : 2.0) 
    Camera.unfollow
    Camera.x = cam_x
    Camera.y = cam_y
  end
  #--------------------------------------------------------------------------
  # * Initialize ATB
  #--------------------------------------------------------------------------      
  def setup_atb
    # Clear all actions
    $game_party.clear_actions
    $game_troop.clear_actions 
    # Setup indexes, these never change
    $game_party.actors.each_with_index do |actor, index|
      actor.actor_index = index
    end
    # Init ATB Controller
    ATB.setup
    # Init update variables
    @prev_party_size = $game_party.actors.size
  end
  #--------------------------------------------------------------------------
  # * Create the battle view
  #--------------------------------------------------------------------------
  def create_viewport
    @pop_window = Window_BattlePop.new
    # Make status windows
    create_status_windows
    # Create message window (used for messages in battle)
    @message_window = Window_Message.new
    # Create sprite set
    @spriteset = Spriteset_Battle.new(@status_windows)
    # Set wait count (frames)
    @wait_count = 0
    Camera.update_sprites
  end
  #--------------------------------------------------------------------------
  # * Recreate status windows
  #--------------------------------------------------------------------------
  def create_status_windows
    @status_windows.each{|win| win&.dispose} if @status_windows
    @help_window.dispose if @help_window
    @controls_window.dispose if @controls_window
    @status_windows = []
    $game_party.actors.each_with_index do |actor, i|
      party_size = $game_party.actors.size
      w = 960
      segment = w / 3
      edge = 320
      x = edge + (w - (segment * party_size)) / 2 + (segment * i)
      @status_windows[i] = Window_BattleStatus.new(x, 464, 260, 288, actor)
    end
    @help_window = Window_BattleHelp.new
    @controls_window = Window_Controls.new(0, LOA::SCRES[1] - 216)
    @target_window = Window_BattleTarget.new
  end
  #--------------------------------------------------------------------------
  # * Transistion into battle
  #--------------------------------------------------------------------------
  def process_transition
    if $data_system.battle_transition == ""
      Graphics.transition(20)
    else
      Graphics.transition(40, "Graphics/Transitions/" + $data_system.battle_transition)
    end
  end
  #--------------------------------------------------------------------------
  # * Cleanup
  #--------------------------------------------------------------------------
  def terminate
    # Prepare for transition
    Graphics.freeze
    # Not sure why this is here but
    #@message_window.update if @message_window
    # Dispose of windows  
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar&.dispose if ivar.is_a?(Window)
    end   
    @status_windows.each{|win| win.dispose}
    @actor_command_window&.dispose
    # Dispose sprite set
    @spriteset.dispose
    # Clear timers if they exist
    #@escape_timer = nil
    # Switching to map (Escaped)
    if $scene.is_a?(Scene_Map)
      # Refresh map
      $game_map.refresh
      # Recall sounds
      resume_sound_post_battle unless $game_temp.continue_map_bgm_battle
      $game_temp.continue_map_bgm_battle = false
    # Game over or victory?
    elsif !$scene.is_a?(Scene_Victory)
      # Not sure what else it is but just stop audio 
      $game_system.bgm_stop
      $game_system.bgs_stop
    end
  end
  #--------------------------------------------------------------------------
  # * Resume sound after battle exit
  #--------------------------------------------------------------------------
  def resume_sound_post_battle
    #Play BGM
    if $game_system.memorized_bgm != nil && $game_system.memorized_bgm != ''
      $game_system.bgm_restore
    else
      $game_system.bgm_stop
    end
    # Play bgs
    if $game_system.memorized_bgs != nil && $game_system.memorized_bgs != ''
      $game_system.bgs_restore
    else
      $game_system.bgs_stop
    end
  end
  #--------------------------------------------------------------------------
  # * Battle Event Setup
  #
  # (This has been rewritten in Heretic's Unlimited Battle Conditions)
  #--------------------------------------------------------------------------
  # def setup_battle_event
  #   # If battle event is already running
  #   if $game_system.battle_interpreter.running?
  #     return
  #   end
  #   # Search for all battle event pages
  #   for index in 0...$data_troops[@troop_id].pages.size
  #     # Get event pages
  #     page = $data_troops[@troop_id].pages[index]
  #     # Make event conditions possible for reference with c
  #     c = page.condition
  #     # Go to next page if no conditions are appointed
  #     unless c.turn_valid or c.enemy_valid or
  #            c.actor_valid or c.switch_valid
  #       next
  #     end
  #     # Go to next page if action has been completed
  #     if $game_temp.battle_event_flags[index]
  #       next
  #     end
  #     # Confirm turn conditions
  #     if c.turn_valid
  #       n = $game_temp.battle_turn
  #       a = c.turn_a
  #       b = c.turn_b
  #       if (b == 0 and n != a) or
  #          (b > 0 and (n < 1 or n < a or n % b != a % b))
  #         next
  #       end
  #     end
  #     # Confirm enemy conditions
  #     if c.enemy_valid
  #       enemy = $game_troop.enemies[c.enemy_index]
  #       if enemy == nil or enemy.hp * 100.0 / enemy.maxhp > c.enemy_hp
  #         next
  #       end
  #     end
  #     # Confirm actor conditions
  #     if c.actor_valid
  #       actor = $game_actors[c.actor_id]
  #       if actor == nil or actor.hp * 100.0 / actor.maxhp > c.actor_hp
  #         next
  #       end
  #     end
  #     # Confirm switch conditions
  #     if c.switch_valid
  #       if $game_switches[c.switch_id] == false
  #         next
  #       end
  #     end
  #     # Set up event
  #     $game_system.battle_interpreter.setup(page.list, 0)
  #     # If this page span is [battle] or [turn]
  #     if page.span <= 1
  #       # Set action completed flag
  #       $game_temp.battle_event_flags[index] = true
  #     end
  #     return
  #   end
  # end
  #--------------------------------------------------------------------------
  # * Basic graphics update (when action animations are occurring)
  # This is a separate update loop from Scene_Battle#update
  #--------------------------------------------------------------------------
  def update_basic
    Graphics.update
    if $DEBUG
      Input.update
      if Input.triggerex?(:F11)
        GameSetup.take_screenshot
      end
    end
    # We don't want the player to be able to update input,
    # but vibration needs to run properly. 
    #Input.update_vibration 
    $game_system.update
    $game_screen.update
    @spriteset.update
    update_windows
  end
  #--------------------------------------------------------------------------
  # * Update all windows
  #--------------------------------------------------------------------------
  def update_windows
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar.update if ivar.is_a?(Window) && ivar
    end
    @status_windows.each{|win| win&.update}
    # Update the abxy wheel sprite(s)
    @actor_command_window&.update
    # Determine pop window visibility 
    # if @pop_timer != nil
    #   @pop_timer -= Delta.seconds
    #   if @pop_timer <= 0
    #     @pop_timer = nil
    #   end
    # end      
  end
  #--------------------------------------------------------------------------
  # * Refresh all windows
  #--------------------------------------------------------------------------
  def refresh_windows
    @status_windows.each{|win| win.refresh}
    @target_window.refresh
  end
  #--------------------------------------------------------------------------
  # * Determine wait time (seconds)  
  #   frames : toggle calculating time in frames instead
  #--------------------------------------------------------------------------
  def wait(duration, add_wait = false, frames = false)
    duration = (duration * 60).round unless frames
    if add_wait
      # Add wait duration to battler (this stops sequences from continuing)
      @spriteset.set_wait(duration)
    end
    loop do
      # Call basic graphics update (input forbidden)
      update_basic
      duration -= 1
      #duration = [duration - $deltaTime, 0].max
      break if duration <= 0
    end
  end
  #---------------------------------------------------------------------------
  # * Main battle frame update 
  #---------------------------------------------------------------------------
  def update
    # If battle event is running
    if $game_system.battle_interpreter.running?
      # Update interpreter
      $game_system.battle_interpreter.update
      # If a battler which is forcing actions doesn't exist
      if $game_temp.forcing_battler == nil
        # If battle event has finished running
        unless $game_system.battle_interpreter.running?
          # Rerun battle event set up if battle is not over
          unless judge
            setup_battle_event
            # After setting up the battle event, check for battler leave/join event
            check_party_change
          end
        end
      end
    end
    # Update system (timer) and screen
    $game_system.update
    $game_screen.update
    # If timer has reached 0
    if $game_system.timer_working && $game_system.timer == 0
      # Abort battle
      $game_temp.battle_abort = true
    end
    # Update timers
    @input_timer&.update(@battle_speed)
    #@escape_timer&.update
    # Update windows
    update_windows
    # Update sprite set
    @spriteset.update
    # If transition is processing (into battle)
    if $game_temp.transition_processing
      # Clear transition processing flag
      $game_temp.transition_processing = false
      # Execute transition
      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" +
          $game_temp.transition_name)
      end
    end
    # If message window is showing
    if $game_temp.message_window_showing
      return
    end
    # If sprite effect is showing
    # (A battler is collapsing, appearing, whiten, escaping, damaged, or animation)
    if @spriteset.effect?
      return
    end
    # If game over
    if $game_temp.gameover
      wait(1)
      Audio.bgm_fade(2000)
      wait(2)
      # Switch to game over screen
      $scene = Scene_Gameover.new
      Camera.zoom = $game_map.default_zoom
      return
    end
    # If returning to title screen
    if $game_temp.to_title
      # Switch to title screen
      $scene = Scene_Title.new
      return
    end
    # If battle is aborted
    if $game_temp.battle_abort
      # Return to BGM used before battle started
      #$game_system.bgm_play($game_temp.map_bgm)
      # Battle ends (escape)
      battle_end(ESCAPE)
      return
    end
    # If waiting
    if @wait_count > 0
      # Decrease wait count
      @wait_count -= 1
      return
    end
    # If battler forcing an action doesn't exist,
    # and battle event is running
    # FIXME what is the point of this exactly? 
    if $game_temp.forcing_battler == nil && $game_system.battle_interpreter.running?
      # Exit method
      return
    end
    # Branch according to phase
    case @phase
    when 1  # pre-battle phase
      update_prebattle
    when 2  # main battle phase
      update_battle
    when 3  # action performance phase
      update_actions
    # No longer a phase "4", so if we're continuing to updating here, 
    # something went wrong
    when 4 
      puts "updated phase 4!!"
    end
  end
  #--------------------------------------------------------------------------
  # * Update battler states
  # !!! No longer used here?
  #--------------------------------------------------------------------------
  def update_state_anim
    for battler in all_battlers
      if battler.exist?
        battler_sprite = @spriteset.actor_sprites[battler.index] if battler.actor?
        battler_sprite = @spriteset.enemy_sprites[battler.index] if battler.is_a?(Game_Enemy)
        # Update state animation id
        battler_sprite.update_state_anim
      end
    end
  end
  #--------------------------------------------------------------------------
  # *  Get all battlers
  #--------------------------------------------------------------------------
  def all_battlers
    $game_party.actors + $game_troop.enemies
  end
  #--------------------------------------------------------------------------
  # * Set text in the help window 
  # pause - determines if the help window updating should pause the game screen
  # THIS WILL IMPACT ACTIONS - ensure "spriteset.set_action" calls come AFTER
  #--------------------------------------------------------------------------
  def pop_help(text, wait_time = 1.5, pause = false, battler = @active_battler)
    @pop_window.set_text(text, battler)
    #@pop_timer = wait_time
    refresh_windows
    if pause
      wait(wait_time, true)
    end
  end
end