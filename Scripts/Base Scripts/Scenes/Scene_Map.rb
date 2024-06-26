#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
#  This class performs map screen processing.
#==============================================================================
class Scene_Map
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :spriteset
  attr_accessor :notif_window
  attr_accessor :choice_window
  attr_accessor :message_window
  attr_accessor :fade_delay
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def main
    # Make sprite set
    @spriteset = Spriteset_Map.new
    Camera.unlock
    Camera.reset_bounds
    Camera.zoom = $game_map.current_zoom
    Camera.follow($game_player,0) unless Scene_Title::TITLE_WINDOW_MAP_IDS.include?($game_map.map_id)
    # Setup any effects
    @fade_delay = 0
    # Update camera
    #Camera.update_sprites_zoom
    # One frame for camera update
    Graphics.update
    # Make message window
    @message_window = Window_Message.new
    # Transition run
    Graphics.transition
    # Main loop
    #RubyProf.start
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Screenshot check
      if Input.triggerex?(:F11)
        GameSetup.take_screenshot
      end
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    #prof_result = RubyProf.stop
    #printer = RubyProf::FlatPrinter.new(prof_result)
    #printer.print(STDOUT, {})
    # Prepare for transition
    Graphics.freeze
    # Dispose of sprite set
    @spriteset.dispose
    # Dispose of message window
    @message_window.dispose
    # Dispose of choice window
    if @choice_window != nil
      @choice_window.dispose
      @choice_window = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Update Notification Window
  #--------------------------------------------------------------------------
  def update_notif_window
    # Check windows existence, then update
    if @notif_window != nil
      @notif_window.update
      # Keep the window displayed for a short period
      @notif_wait_time -= 1
      # Check if the timer has run out
      if @notif_wait_time == 0 
        # Set window to move back up
        @notif_window.move(MenuConfig::SCREENSIZE[0] / 2 - 240, -65)
        @notif_wait_time = -1
      end
      if @notif_window.y == -65
        # Terminate
        terminate_notif_window
      end
    end
    # Check keypresses if window is visible & exists
    if @notif_window != nil
      # If the notif window is currently displayed and the player presses "B"
      if @notif_window.visible? && Input.press?(MenuConfig::MENU_INPUT[:Back])
        @notif_window.visible = false
        # If event isn't running, or menu is not forbidden
        unless $game_system.map_interpreter.running? || $game_system.menu_disabled
          $game_player.straighten
          if $game_temp.quest_updated
            Notification.clear
            $scene = Scene_Quest.new
            return
          elsif $game_temp.bestiary_updated
            Notification.clear
            $scene = Scene_Bestiary.new
            return
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Terminate Notification Window
  #--------------------------------------------------------------------------
  def terminate_notif_window
    @notif_wait_time = Notification::WAIT_TIME
    @notif_window.dispose
    @notif_window = nil
  end
  #--------------------------------------------------------------------------
  # * Update Choice Window
  #--------------------------------------------------------------------------
  def update_choice_window
    if Input.trigger?(MenuConfig::MENU_INPUT[:Back])
      unless $game_temp.choice_cancel_type
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      Input.update
      $game_system.se_play($data_system.cancel_se)
      $game_variables[Choices::Variable_ID] = 0
      terminate_choice_window
    elsif Input.trigger?(MenuConfig::MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.decision_se)
      $game_variables[Choices::Variable_ID] = @choice_window.command_at_index
      terminate_choice_window
    end
  end
  #--------------------------------------------------------------------------
  # * Terminate Choice Window
  #--------------------------------------------------------------------------
  def terminate_choice_window
    $game_system.map_interpreter.message_waiting = false
    @choice_window.dispose
    @choice_window = nil
  end
  #---------------------------------------------------------------------
  # * Spriteset Update
  # Force an update with $scene.spriteset_update (Only on the map!)
  #---------------------------------------------------------------------
  def spriteset_update
    @spriteset.update
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Loop
    loop do
      # Update map, interpreter, and player order
      # (this update order is important for when conditions are fulfilled 
      # to run any event, and the player isn't provided the opportunity to
      # move in an instant)
      $game_map.update
      $game_system.map_interpreter.update
      $game_player.update
      # Check map transfer
      check_map_transfer
      # Update system (timer), screen, character busts
      $game_system.update
      $game_screen.update
      # Abort loop if player isn't place moving
      unless $game_temp.player_transferring
        break
      end
      # Run place move
      transfer_player
      # Abort loop if transition processing
      if $game_temp.transition_processing
        break
      end
    end
    # After transitioning, check for and display the game map name if applicable
    if $game_map.display_map_name
      $game_temp.display_map_name = true
      $game_map.display_map_name = false
    end
    # Update sprite set
    @spriteset.update
    # Update choice window
    if @choice_window != nil && @choice_window.active
      @choice_window.update
      update_choice_window
    end
    # Update message window
    @message_window.update
    # Update character busts
    #$game_busts.update
    # If game over
    if $game_temp.gameover
      # Switch to game over screen
      $scene = Scene_Gameover.new
      return
    end
    # If returning to title screen
    if $game_temp.to_title
      # Change to title screen
      $scene = Scene_Title.new
      return
    end
    # If transition processing
    if $game_temp.transition_processing
      @fade_delay = 0
      # Setup any effects
      $game_map.setup_map_effects(@spriteset)
      # Clear transition processing flag
      $game_temp.transition_processing = false
      # Wait before fading back in
      @fade_delay.times do
        Graphics.update
      end
      # Execute transition
      if $game_temp.transition_name == ""
        Graphics.fadein(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" + $game_temp.transition_name)
      end
    end
    # If showing message window
    if $game_temp.message_window_showing
      return
    end
    # If encounter list isn't empty, and encounter count is 0
    if $game_player.encounter_count == 0 and $game_map.encounter_list != []
      # If event is running or encounter is not forbidden
      unless $game_system.map_interpreter.running? or
             $game_system.encounter_disabled
        # Confirm troop
        n = rand($game_map.encounter_list.size)
        troop_id = $game_map.encounter_list[n]
        # If troop is valid
        if $data_troops[troop_id] != nil
          # Set battle calling flag
          $game_temp.battle_calling = true
          $game_temp.battle_troop_id = troop_id
          $game_temp.battle_can_escape = true
          $game_temp.battle_can_lose = false
          $game_temp.battle_proc = nil
        end
      end
    end
    # If B button was pressed
    if Input.trigger?(MenuConfig::MENU_INPUT[:Pause]) || Input.trigger?(Input::X) || Input.trigger?(Input::Y) || Input.trigger?(Input::B)
      # If event is running, or menu is not forbidden
      unless $game_system.map_interpreter.running? ||
             $game_system.menu_disabled ||
             $game_switches[LOA::CUTSCENE_SW] == true
        # Set menu calling flag or beep flag
        $game_temp.menu_calling = true
        $game_temp.menu_beep = true
      end
    end
    # If debug mode is ON and F9 key was pressed
    if $DEBUG && Input.press?(Input::F9)
      # Set debug calling flag
      $game_temp.debug_calling = true
    end
    # If player is not moving
    unless $game_player.moving?
      # Run calling of each screen
      if $game_temp.battle_calling
        call_battle
      elsif $game_temp.shop_calling
        call_shop
      elsif $game_temp.book_calling
        call_book
      elsif $game_temp.name_calling
        call_name
      elsif $game_temp.menu_calling
        call_menu
      elsif $game_temp.save_calling
        call_save
      elsif $game_temp.debug_calling
        call_debug
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Battle Call
  #--------------------------------------------------------------------------
  def call_battle
    # Clear battle calling flag
    $game_temp.battle_calling = false
    # Clear menu calling flag
    $game_temp.menu_calling = false
    $game_temp.menu_beep = false
    # Make encounter count
    $game_player.make_encounter_count
    # Check and setup preemptive/ambush battles
    check_preemptive_ambushed
    # Memorize map BGM and stop BGM
    unless $game_temp.continue_map_bgm_battle
      $game_system.bgm_memorize
      $game_system.bgs_memorize
    end
    # Play battle start SE
    $game_system.se_play($data_system.battle_start_se)
    # Straighten player position
    #$game_player.straighten
    # Switch to battle screen
    $scene = Scene_Battle.new
  end
  #--------------------------------------------------------------------------
  # * Shop Call
  #--------------------------------------------------------------------------
  def call_shop
    # Clear shop call flag
    $game_temp.shop_calling = false
    # Straighten player position
    $game_player.straighten
    # Switch to shop screen
    $scene = Scene_Shop.new($game_temp.shop_id)
  end
  #--------------------------------------------------------------------------
  # * Book Call
  #--------------------------------------------------------------------------
  def call_book
    # Clear shop call flag
    $game_temp.book_calling = false
    # Straighten player position
    $game_player.straighten
    # Switch to shop screen
    $scene = Scene_Book.new($game_temp.book_name)
  end
  #--------------------------------------------------------------------------
  # * Name Input Call
  #--------------------------------------------------------------------------
  def call_name
    # Clear name input call flag
    $game_temp.name_calling = false
    # Straighten player position
    $game_player.straighten
    # Switch to name input screen
    $scene = Scene_Name.new
  end
  #--------------------------------------------------------------------------
  # * Menu Call
  #--------------------------------------------------------------------------
  def call_menu
    # Clear menu call flag
    $game_temp.menu_calling = false
    # If menu beep flag is set
    if $game_temp.menu_beep
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Clear menu beep flag
      $game_temp.menu_beep = false
    end
    # Straighten player position
    #$game_player.straighten
    # Switch to menu screen
    $scene = Scene_Menu.new
  end
  #--------------------------------------------------------------------------
  # * Save Call
  #--------------------------------------------------------------------------
  def call_save
    # Straighten player position
    $game_player.straighten
    # Switch to save screen
    $scene = Scene_SaveLoad.new(:save)
  end
  #--------------------------------------------------------------------------
  # * Debug Call
  #--------------------------------------------------------------------------
  def call_debug
    # Clear debug call flag
    $game_temp.debug_calling = false
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Straighten player position
    $game_player.straighten
    # Switch to debug screen
    $scene = Scene_Debug.new
  end
  #--------------------------------------------------------------------------
  # Check Player Coords (For map transfer)
  # dir : direction the player is transferring (determines bounds)
  # bounds : [min, max] bound to check coords
  #--------------------------------------------------------------------------
  def trigger_map_transfer?(mapid, offset, dir, min, max)
    # Branch by transfer direction
    case dir
    when 2 # down
      bound_check = $game_player.x(true)
      map_check = $game_player.y(true) >= ($game_map.height - 1)
      max = $game_map.width if max == 0
    when 4 # left
      bound_check = $game_player.y(true)
      map_check = $game_player.x <= Game_Map::TILE_SIZE / 2
      max = $game_map.height if max == 0
    when 6 # right
      bound_check = $game_player.y(true)
      map_check = $game_player.x >= $game_map.width * Game_Map::TILE_SIZE - Game_Map::TILE_SIZE / 2
      max = $game_map.height if max == 0
    when 8 # up
      bound_check = $game_player.x(true)
      map_check = $game_player.y(true) <= 0
      max = $game_map.width if max == 0
    end
    # Coordinate check
    return map_check && (bound_check > min && bound_check < max)
  end
  #--------------------------------------------------------------------------
  # * Determine Map border transfer
  #--------------------------------------------------------------------------
  def check_map_transfer
    # Skip if the map has no connections
    return if $game_map.connections_data.empty?
    # Skip if the player is not facing a cardinal direction
    return unless $game_player.direction % 2 == 0
    current_dir = $game_player.direction
    # (i * 2 + 2) results in a cardinal direction (2,4,6,8)
    # The reverse gives us an index (current_dir - 2) / 2
    # Skip if there is no connection for this particular direction
    return if $game_map.connections_data[current_dir].nil?
    # Setup variables
    to_map_id, offset, min, max = $game_map.connections_data[current_dir]
    # Check if player coordinates are consistent with a transfer
    # Bounds /could/ be added here, if neccessary.
    if trigger_map_transfer?(to_map_id, offset, current_dir, min, max)
      # Initiate the transfer
      player_map_transfer(to_map_id, offset, current_dir)
    end
  end
  #--------------------------------------------------------------------------
  # Pixel movement special transfer
  # ---
  # Assigns the player's map x and y and adds an offset to transfer to the 
  # next map, specifically meant for edge transfers
  # --
  # map_to : map id
  # offset_x, offset_y : offsets player map coordinate in tiles, can be +/-
  # alternatively use :zero to set to 0 and :edge to set to map edge 
  # t_dir: target transfer direction
  #
  # Example: 
  # player_map_transfer(34, -10, :edge)
  # Will transfer the player to map 34, offset them 10 tiles to the left, 
  # place them at the map's boundary and face them up. 
  #--------------------------------------------------------------------------
  def player_map_transfer(map_to, offset, t_dir)
    # If transferring player, showing message, or processing transition
    if $game_temp.player_transferring || $game_temp.message_window_showing || $game_temp.transition_processing
      # End
      return false
    end
    # Set transferring player flag
    $game_temp.player_transferring = true
    # Change players direction
    $game_temp.player_new_direction = t_dir
    # Get map
    $game_temp.player_new_map_id = map_to
    map = load_data(sprintf('Data/Map%03d.rxdata', $game_temp.player_new_map_id))
    # Exit if map invalid
    if map.nil?
      return false 
    end  
    # Setup coordinates based on transfer direction and offset
    case t_dir
    when 4 # left
      # Always x edge
      $game_temp.player_new_x = map.width * Game_Map::TILE_SIZE - Game_Map::TILE_SIZE / 2
      # Apply offset
      $game_temp.player_new_y = $game_player.y + (offset * Game_Map::TILE_SIZE)
    when 6 # right
      # Always "zero"
      $game_temp.player_new_x = Game_Map::TILE_SIZE / 2
      # Apply offset
      $game_temp.player_new_y = $game_player.y + (offset * Game_Map::TILE_SIZE)
    when 8 # up
      # Apply offset
      $game_temp.player_new_x = $game_player.x + (offset * Game_Map::TILE_SIZE)
      # Always y edge
      $game_temp.player_new_y = map.height * Game_Map::TILE_SIZE - Game_Map::TILE_SIZE / 2
    when 2 # down
      # Apply offset
      $game_temp.player_new_x = $game_player.x + (offset * Game_Map::TILE_SIZE)
      # Always "zero"
      $game_temp.player_new_y = Game_Map::TILE_SIZE
    end
    # # Freeze current graphics
    # Graphics.freeze
    # # Set transition processing flag 
    $game_temp.transition_processing = true
    $game_temp.transition_name = ""
    # End (success)
    return true
  end
  #--------------------------------------------------------------------------
  # * Player Place Move
  #--------------------------------------------------------------------------
  def transfer_player
    # Clear player place move call flag
    $game_temp.player_transferring = false
    Graphics.fadeout(20)
    #$game_temp.transition_processing = false
    # If move destination is different than current map
    if $game_map.map_id != $game_temp.player_new_map_id
      # Set up a new map
      $game_map.setup($game_temp.player_new_map_id)
    end
    # Set up player position
    $game_player.moveto($game_temp.player_new_x, $game_temp.player_new_y)
    Camera.follow($game_player, 0)
    # Set player direction
    case $game_temp.player_new_direction
    when 2  # down
      $game_player.turn_down
    when 4  # left
      $game_player.turn_left
    when 6  # right
      $game_player.turn_right
    when 8  # up
      $game_player.turn_up
    end
    # Straighten player position
    $game_player.straighten
    # If the speed factor had been changed on the last map
    if $game_player.speed_factor != 1.0
      $game_player.move_speed /= $game_player.speed_factor
      $game_player.speed_factor = 1.0
    end
    # Update map (run parallel process event)
    $game_map.update
    # Remake spriteset and update camera
    @spriteset.dispose
    @spriteset = Spriteset_Map.new
    Graphics.update
    # Run automatic change for BGM and BGS set on the map
    $game_map.autoplay
    # Check if BGM changing is disabled
    unless $game_switches[Audio::DISABLE_INDOOR_SWITCH]
      # Setup house bgm
      $game_system.setup_house_bgm
    end
    # Frame reset
    Graphics.frame_reset
    # Update input information
    Input.update
  end
  # #--------------------------------------------------------------------------
  # # * Start a map transition to black
  # #--------------------------------------------------------------------------
  # def start_map_transition
  #   # Freeze current graphics
  #   Graphics.freeze
  #   # Dispose of the spriteset (force transition to black)
  #   @spriteset.dispose
  #   # Execute transition
  #   Graphics.transition(15)
  # end
  # #--------------------------------------------------------------------------
  # # * End a map transition 
  # #--------------------------------------------------------------------------
  # def end_map_transition
  #   # Freeze current graphics
  #   Graphics.freeze
  #   # Remake sprite set
  #   @spriteset = Spriteset_Map.new
  #   # 1 Frame (Sets camera)
  #   Graphics.update
  #   # Execute transition
  #   Graphics.transition(15)
  # end
  #--------------------------------------------------------------------------
  # * Battle ambush / preemptive determination
  # Flags are cleared partway through battle. 
  #--------------------------------------------------------------------------
  def check_preemptive_ambushed
    # Reset flags, in case missed in previous battle
    $game_temp.battle_preemptive = false
    $game_temp.battle_ambushed = false
    # Get the average agility between both groups
    enemies_agi = 0
    for enemy in $game_troop.enemies
      enemies_agi += enemy.agi
    end
    enemies_agi /= [$game_troop.enemies.size, 1].max
    actors_agi = 0
    for actor in $game_party.actors
      actors_agi += actor.agi
    end
    actors_agi /= [$game_party.actors.size, 1].max
    # Get extra rate from equipment
    addl_preempt_rate = preemptive_plus
    # Roll the dice
    if actors_agi >= enemies_agi
      percent_preemptive = BattleConfig::PREEMPTIVE_RATE * (addl_preempt_rate ? 3 : 1)
      percent_back_attack = BattleConfig::BACK_ATTACK_RATE / 2
    else
      percent_preemptive = (BattleConfig::PREEMPTIVE_RATE / 2) * (addl_preempt_rate ? 3 : 1)
      percent_back_attack = BattleConfig::BACK_ATTACK_RATE
    end
    if rand(100) < percent_preemptive
      $game_temp.battle_preemptive = true
    elsif rand(100) < percent_back_attack
      $game_temp.battle_ambushed = true
    end
    # Special overrides
    $game_temp.battle_ambushed = special_ambushed_conditions
    $game_temp.battle_preemptive = special_preemptive_conditions
    # Preemptive always trumps ambush, check config.
    if !BattleConfig::BACK_ATTACK || $game_temp.battle_preemptive
      $game_temp.battle_ambushed = false
    end
    if !BattleConfig::PREEMPTIVE
      $game_temp.battle_preemptive = false
    end
  end
  #--------------------------------------------------------------------------
  # * Determine ambushed conditions
  #--------------------------------------------------------------------------
  def special_ambushed_conditions
    # Check switches
    return true if $game_switches[BattleConfig::BACK_ATTACK_SWITCH]
    return false if $game_switches[BattleConfig::NO_BACK_ATTACK_SWITCH]
    # Check equipment
    $game_party.actors.each do |actor|
      BattleConfig::NON_BACK_ATTACK_ARMOR_IDS.each do |id|
        # If any armor equipped has its ID included in the list
        if [actor.armor1_id, actor.armor2_id, actor.armor3_id, actor.armor4_id].include?(id)
          return false
        end
      end
      # Check skills
      BattleConfig::NON_BACK_ATTACK_SKILLS.each do |id|
        return false if actor.skill_id_learn?(id)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Determine preemptive conditions
  #--------------------------------------------------------------------------
  def special_preemptive_conditions
    return true if $game_switches[BattleConfig::PREEMPTIVE_SWITCH]
    return false if $game_switches[BattleConfig::NO_PREEMPTIVE_SWITCH]
  end
  #--------------------------------------------------------------------------
  # * Boost preemptive for Equipment
  #--------------------------------------------------------------------------
  def preemptive_plus
    # Check equipment
    $game_party.actors.each do |actor|
      BattleConfig::PREEMPTIVE_ARMOR_IDS.each do |id|
        # If any armor equipped has its ID included in the list
        if [actor.armor1_id, actor.armor2_id, actor.armor3_id, actor.armor4_id].include?(id)
          return true
        end
      end
      # Check skills
      BattleConfig::PREEMPTIVE_SKILLS.each do |id|
        return true if actor.skill_id_learn?(id)
      end
    end
    return false
  end
end
