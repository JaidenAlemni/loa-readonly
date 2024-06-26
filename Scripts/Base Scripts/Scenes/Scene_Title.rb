#==============================================================================
# ** Map Title Screen
# Created by Jaiden, based on Heretic's Animated Title Screen
#------------------------------------------------------------------------------
# Inherits the map scene to create a custom title screen that acts like a map. 
# It contains special functions that the map scene does not
class Scene_Title < Scene_Map
  #===============================================================================
  # * Configuration
  #===============================================================================
  TITLE_MAP_ID = 4                       # Map ID to move Player to
  TITLE_MAP_X = 7                        # X coordinate on Title Map
  TITLE_MAP_Y = 7                        # Y coordinate on Title Map
  TITLE_MAP_PLAYER_DIRECTION = 2         # Direction to start Player
  TITLE_WINDOW_MAP_IDS = [4, 5, 80]   # Map ID's allowed to display Window
  TITLE_HIDE_PLAYER = true               # Set Player Graphic to None if True
  TITLE_MAP_WINDOW_FADE_RATE = 10
  TITLE_MENU_TIMEOUT = 10 # Seconds
  COMMAND_WIN_XY = [16,320]
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :command_window  # Window for New Game / Continue / etc
  attr_accessor :message_window  # Allows Closing with 'terminate_message'
  attr_accessor :fade_out_title_menu # Flag to begin fade out the title menu
  attr_accessor :title_menu_timer 
  attr_accessor :menu_index
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(menu_index = 0)
    # Platform support
    # if (!System.is_windows? && !System.is_mac?) #|| System.is_wine?
    #   raise RuntimeError, "Legends of Astravia is not supported on this platform.\nThe game will now shut down.", ""
    # end
    # Don't bother with first startup procedure if we're testing battle
    first_start if !$BTEST
    # Check if continue is enabled
    MenuConfig::MAX_SAVEFILES.times do |i|
      if FileTest.exist?(GameSetup.savefile_name(i))
        @continue_enabled = true
      end
    end
    @menu_index = @continue_enabled ? 1 : menu_index
  end
  #--------------------------------------------------------------------------
  # * First-time setup for the scene (doesn't apply if switching back from menus)
  #--------------------------------------------------------------------------  
  def first_start
    # Terminate Any Audio - needed after a restart
    Audio.bgm_stop
    Audio.bgs_stop
    Audio.me_stop
    # Initialize Globals
    @fade_out_title_menu = false
    @title_menu_timer = nil
    # Disable Menu Access
    $game_system.menu_disabled = true       
    # Set up initial party
    $game_party.setup_starting_members
    # Set up initial map position
    $game_map.setup(TITLE_MAP_ID)
    # Move player to initial position
    $game_player.moveto(TITLE_MAP_X, TITLE_MAP_Y)
    $game_player.direction = TITLE_MAP_PLAYER_DIRECTION
    # If the option to Hide the Player is set, set Opacity to Zero
    if TITLE_HIDE_PLAYER
      $game_party.actors(:all)[0].character_name = ''
    end
    # Refresh player
    $game_player.refresh
    # Hide the title menu
    $game_temp.display_title_menu = false
    $game_temp.hide_title_menu = true
  end
  #--------------------------------------------------------------------------
  # * Main Processing 
  #--------------------------------------------------------------------------
  def main
    # Abort for battle testing
    if $BTEST
      battle_test
      return
    end
    # Run automatic change for BGM and BGS set with map
    $game_map.autoplay
    # Update map (run parallel process event)
    $game_map.update
    # Declare that this is a Title Scene.  This variable is false during play
    $game_temp.title_screen = true
    # Make the command window visible if it exists already
    @command_window&.visible = true
    # Create timer for debug launch function
    @launch_timer = Timer.new(10)
    @launch_timer.expire
    # Call Scene_Map#main
    super
    # Upon scene disposal
    dispose_command_window
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Production user folder launch
    if !$DEBUG && Input.trigger?(Input::F6) && @launch_timer.finished?
      System.launch(GameSetup.user_directory)
      @launch_timer.reset
    end
    @launch_timer.update
    # Update game map
    super
    # Update the timer
    @title_menu_timer&.update
    # If we're on the title screen
    if $game_temp.title_screen
      # If this is a map that allows title display
      if TITLE_WINDOW_MAP_IDS.include?($game_map.map_id)
        #-------------------------------------------------------- 
        # If player pressed enter or inactive time
        if $game_temp.display_title_menu && !@command_window && !$game_temp.hide_title_menu
          # Prevent the window from disappearing
          $game_temp.display_title_menu = false
          @fade_out_title_menu = false
          # Create the command window
          create_command_window
          # Show the command window
          show_command_window
          # Prevents Triggering Inactive Timeout
          @title_menu_timer&.reset
        #--------------------------------------------------------  
        # If command window exists, is inactive and called by script (display_title_menu) 
        # OR player button presss when valid
        elsif @command_window && !command_active? && !$game_temp.hide_title_menu && $game_temp.display_title_menu 
          # Set command window as visible && active
          show_command_window
          # Prevent Hiding
          $game_temp.display_title_menu = false
          @fade_out_title_menu = false
          # Prevents Triggering Inactive Timeout
          @title_menu_timer&.reset 
        #-------------------------------------------------------- 
        # Window not created, and Player hits a Key when allowed to display menu
        elsif !@command_window && !$game_temp.hide_title_menu
          # Force Title Menu to be Created - Above
          $game_temp.display_title_menu = true
          # Prevent Hiding        
          @fade_out_title_menu = false
          # Prevents Triggering Inactive Timeout
          @title_menu_timer&.reset
        #-------------------------------------------------------- 
        # If we need to Hide the Menu or Force it off the Screen
        elsif @fade_out_title_menu || $game_temp.hide_title_menu
          # If the command window is valid
          if @command_window
            # Make it inactive 
            @command_window.active = false if command_active?
            # Fade out
            if @command_window.opacity > 0
              @command_window.opacity -= TITLE_MAP_WINDOW_FADE_RATE
            else
              # End fade
              @fade_out_title_menu = false
            end
          end
        #-------------------------------------------------------- 
        # Window is Active, Update for Player Input
        elsif @command_window && command_active?
          # Update command window
          update_command_window
        end
      # The player is escaping (title cutscene?) 
      elsif $game_system.map_interpreter.title_escape_keys? && $game_map.map_id != TITLE_MAP_ID
        # Prepare for transition
        Graphics.freeze
        # Scrap command window
        dispose_command_window
        # Restart
        $scene = Scene_Title.new
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Create the copyright text sprite
  #--------------------------------------------------------------------------
  def draw_copyright
    fsize = 80
    vp = Viewport.new
    vp.z = 9999
    @copyright_sprite = Sprite_ScreenText.new(vp, '', LOA::SCRES[1]-30)
    @version_sprite = Sprite_ScreenText.new(vp, '', LOA::SCRES[1]-30) 
    @controls_sprite = Sprite_ScreenText.new(vp, '', LOA::SCRES[1]-30)  
    # Lord forgive me for this one
    confirm_key = "(" + Input.control_name_from_id(0) + ")"
    cancel_key = "(" + Input.control_name_from_id(1) + ")"
    fullscreen = ''#System.is_mac? ? '' : '[Alt]+[Enter] ' + Localization.localize('&MUI[TitleFullscreen]')
    @copyright_sprite.draw("  © #{Time.now().year} Studio Alemni", 0, fsize, Font.numbers_name)
    str = "#{confirm_key} " + Localization.localize('&MUI[Confirm]') + "      #{cancel_key} " + Localization.localize('&MUI[Cancel]') + "      #{fullscreen}"
    @controls_sprite.draw(str, 1, fsize, Font.numbers_name)
    @version_sprite.draw($BUILD_VERSION + '  ', 2, fsize, Font.numbers_name)
    @copyright_sprite.opacity = 150
    @version_sprite.opacity = 150
    @controls_sprite.opacity = 150
  end
  #--------------------------------------------------------------------------
  # * Destroy the copyright text sprite
  #--------------------------------------------------------------------------
  def dispose_copyright
    return if @copyright_sprite.nil?
    @copyright_sprite.dispose
    @copyright_sprite = nil
    @version_sprite.dispose
    @version_sprite = nil
    @controls_sprite.dispose
    @controls_sprite = nil
  end
  #--------------------------------------------------------------------------
  # * Create the command window
  #--------------------------------------------------------------------------
  def create_command_window
    # Draw the text if we haven't yet
    draw_copyright unless @copyright_sprite
    commands = ["New Game", "Continue", "Options", "Credits", "Exit"]
    @command_window = Window_TitleCommand.new(commands)
    @command_window.x, @command_window.y = COMMAND_WIN_XY
    # Create the title menu timer
    @title_menu_timer = Timer.new(TITLE_MENU_TIMEOUT)
    @command_window.disable_item(1) unless @continue_enabled
  end
  #--------------------------------------------------------------------------
  # * show the command window
  #--------------------------------------------------------------------------
  def show_command_window
    # Assign menu index if it exists
    @command_window.index = @menu_index
    @command_window.active = true
    @command_window.visible = true
  end
  #--------------------------------------------------------------------------
  # * Dispose of the command window
  #--------------------------------------------------------------------------
  def dispose_command_window
    # Get rid of the copyright sprites too
    dispose_copyright
    @command_window.dispose
    @command_window = nil
    # Clear the title menu timer
    @title_menu_timer = nil
  end
  #--------------------------------------------------------------------------
  # * Command window active determinant
  #--------------------------------------------------------------------------
  def command_active?
    return @command_window.active
  end
  #--------------------------------------------------------------------------
  # * Update the command window
  #--------------------------------------------------------------------------
  def update_command_window
    # If Command Window isnt being Hidden
    if command_active?
      # If Key was pressed, reset Inactivity Frame Counter
      if $game_system.map_interpreter.title_escape_keys? 
        # Store the Frame Counter for when this window was Displayed
        # This prevents the Window from Fading out from Inactivity
        @title_menu_timer&.reset
      # Title timed out
      elsif @title_menu_timer&.finished?
        # Hide the Title Menu
        $game_temp.hide_title_menu = true
        $game_temp.display_title_menu = false
        @fade_out_title_menu = true
        # Reset Frame Inactivity Counter
        @title_menu_timer.reset
      end
    end
    @command_window.update
    # If C button was pressed
    if Input.trigger?(MenuConfig::MENU_INPUT[:Confirm]) && command_active?
      # Branch by command window cursor position
      case @command_window.index
      when 0  # New game
        title_new_game
        return
      when 1  # Continue
        title_continue
        return
      when 2  # options
        title_options
        return
      when 3  # Credits
        title_credits
        return
      when 4 # shutdown
        title_shutdown
        return
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Title: New Game
  #--------------------------------------------------------------------------
  def title_new_game
    # Dispose of command window
    dispose_command_window
    # Declare that Gameplay is NOT a Title Scene
    $game_temp.title_screen = false   
    # Play decision SE
    $game_system.se_play(RPG::AudioFile.new(MenuConfig::START_SFX))
    # Stop BGM
    Audio.bgm_stop
    # Stop BGS
    Audio.bgs_stop    
    # Make each type of game object
    GameSetup.init_game_objects
    # Set up initial party
    $game_party.setup_starting_members
    # Set up initial map position
    $game_map.setup($data_system.start_map_id)
    # Move player to initial position
    $game_player.moveto($data_system.start_x * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE/2, $data_system.start_y * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE - 2) 
    # Refresh player
    $game_player.refresh
    # Run automatic change for BGM and BGS set with map
    $game_map.autoplay
    # Update map (run parallel process event)
    $game_map.update
    # Switch to map screen
    $scene = Scene_Map.new
    # Re-enable Menu Access since it was Disabled for Demo Titles
    $game_system.menu_disabled = false
  end
  #--------------------------------------------------------------------------
  # * Command: Continue
  #--------------------------------------------------------------------------
  def title_continue
    # If continue is disabled
    unless @continue_enabled
      # Play buzzer SE
      $game_system.se_play($data_system.buzzer_se)
      return
    end
    # Prepare for transition
    Graphics.freeze
    # Save current index
    @command_window.visible = false
    @menu_index = @command_window.index
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Switch to load screen
    $scene = Scene_SaveLoad.new(:load)
  end
  #--------------------------------------------------------------------------
  # * Command: Options
  #--------------------------------------------------------------------------
  def title_options
    # Prepare for transition
    Graphics.freeze
    # Save current index
    @command_window.visible = false
    @menu_index = @command_window.index
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Switch to load screen
    $scene = Scene_Options.new
  end
  #--------------------------------------------------------------------------
  # * Command: Shutdown
  #--------------------------------------------------------------------------
  def title_shutdown
    # Fade out BGM, BGS, and ME
    Audio.bgm_fade(500)
    Audio.bgs_fade(500)
    Audio.me_fade(500)
    # Play decision SE
    $game_system.se_play(RPG::AudioFile.new(MenuConfig::START_SFX))
    # Dispose of command window
    dispose_command_window
    # Shutdown
    $scene = nil
  end  
  #--------------------------------------------------------------------------
  # * Command: Credits
  #--------------------------------------------------------------------------
  def title_credits
    # Play decision SE
    $game_system.se_play($data_system.decision_se)
    # Modal
    sys_proc = GUtil.create_system_modal("&MUI[GameCreditsWeb]", ["&MUI[Cancel]","OK"], 360, 128)
    if sys_proc.call == 1
      # Launch browser
      System.launch("https://www.studioalemni.com/loa-credits")
    end
  end  
  #--------------------------------------------------------------------------
  # * Battle Test
  # This needs to be reworked
  #--------------------------------------------------------------------------
  def battle_test
    # Load database (for battle test)
    $data_actors        = load_data("Data/BT_Actors.rxdata")
    $data_classes       = load_data("Data/BT_Classes.rxdata")
    $data_skills        = load_data("Data/BT_Skills.rxdata")
    $data_items         = load_data("Data/BT_Items.rxdata")
    $data_weapons       = load_data("Data/BT_Weapons.rxdata")
    $data_armors        = load_data("Data/BT_Armors.rxdata")
    $data_enemies       = load_data("Data/BT_Enemies.rxdata")
    $data_troops        = load_data("Data/BT_Troops.rxdata")
    $data_states        = load_data("Data/BT_States.rxdata")
    $data_animations    = load_data("Data/BT_Animations.rxdata")
    $data_tilesets      = load_data("Data/BT_Tilesets.rxdata")
    $data_common_events = load_data("Data/BT_CommonEvents.rxdata")
    $data_system        = load_data("Data/BT_System.rxdata")
    # Always init game options
    $game_options = Game_Options.new
    # Make each game object
    GameSetup.create_icon_cache
    GameSetup.init_game_objects
    # Set up party for battle test
    $game_party.setup_battle_test_members
    # Set troop ID, can escape flag, and battleback
    $game_temp.battle_troop_id = $data_system.test_troop_id
    $game_temp.battle_can_escape = true
    $game_map.battleback_name = $data_system.battleback_name
    # Play battle start SE
    $game_system.se_play($data_system.battle_start_se)
    # Play battle BGM
    $game_system.bgm_play($game_system.battle_bgm)
    # Switch to battle screen
    $scene = Scene_Battle.new
  end
end


class Interpreter
  # Pressing any of the Keys here will make this return true
  def title_escape_keys?
    # Only works if this is a Title Scene
    if $game_temp.title_screen
      # If the Player hit any of the B, C, Up or Down Keys
      return (Input.trigger?(:B) || Input.trigger?(:C) ||
         Input.trigger?(:UP) || Input.trigger?(:DOWN) || 
         Input.trigger?(:LEFT) || Input.trigger?(:RIGHT))
    end
  end

  # This displays the Title Menu - MUST BE CALLED TO MAKE TITLE MENU APPEAR!
  def display_title_menu
    if $game_temp.title_screen
      $game_temp.hide_title_menu = false      
      $game_temp.display_title_menu = true
    end
  end
  
  # This prevents the Title Menu from being displayed on Key Press
  def hide_title_menu
    if $game_temp.title_screen
      $game_temp.hide_title_menu = true
      $game_temp.display_title_menu = false
    end
  end  
end