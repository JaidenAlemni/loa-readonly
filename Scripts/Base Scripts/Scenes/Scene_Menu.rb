#==============================================================================
# ** Scene_Menu
#------------------------------------------------------------------------------
#  This class performs menu screen processing.
#==============================================================================
class Scene_Menu < Scene_Base
  include MenuConfig
  attr_accessor :menu_index
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(menu_index = 0)
    super
    @menu_index = menu_index
  end
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def pre_start
    # Make command window
    menu_commands = MAINMENU_COMMANDS
    if @@command_window == nil    
      @@command_window = Window_Menu.new(MENU_ORIGIN_X, MENU_ORIGIN_Y, COMMAND_WIN_WIDTH, MENU_WINDOW_HEIGHT, menu_commands)
    end
    @@command_window.index = @menu_index
    @@command_window.z = 1000
    # Determine animation direction
    reverse = @previous_scene.is_a?(Scene_Map)
    # Make status window
    @status_window = Window_MenuStatus.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH, 536, reverse)
    # Make Help Window
    @help_window = Window_SuperHelp.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y + @status_window.height, MENU_WINDOW_WIDTH, HELP_HEIGHT_SHORT)
    # BETAONLY Temporarily disable some menu items for the beta
    @disabled = [4]
    if $DEMO
      @disabled << 5
    end
    # If there are no party members
    if $game_party.actors.size == 0
      # Disable items, skills, equipment, and status
      4.times{|i| @disabled << i}
    end
    @disabled.each do |index|
      @@command_window.disable_item(index)
    end
    # Associate help window
    @@command_window.help_window = @help_window
    super
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------  
  def update
    super
    @@command_window.update
    if @@command_window.active
      update_command
    elsif @status_window.active
      update_status
    end
  end
  #--------------------------------------------------------------------------
  # * Cleanup windows
  #--------------------------------------------------------------------------  
  def cleanup
    # Save current menu index
    @menu_index = @@command_window.index
    @@command_window.help_window = nil
    #@@command_window.visible = false
    @status_window.index = -1
    super
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    # Dispose window
    if $scene.is_a?(Scene_Map)
      @@command_window.dispose
    end
  end
  #--------------------------------------------------------------------------
  # * Update command window
  #--------------------------------------------------------------------------  
  def update_command
    if Input.trigger?(MENU_INPUT[:Back]) || Input.trigger?(MENU_INPUT[:Pause])
      close_scene
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      return if @@command_window.moving?
      if @disabled.include?(@@command_window.index)#$game_party.actors.size == 0 && @@command_window.index < 4
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Branch by command window cursor position
    case @@command_window.index
      when 0 #items
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to item screen
        $scene = Scene_Item.new
      when 1 #skills
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        #@@command_window.active = false
        # Go right to skills with actor index
        $scene = Scene_Essence.new(0)
      when 2 #equipment
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        #@@command_window.active = false
        # Go right to equipment with actor index
        $scene = Scene_Equip.new(0)   
      when 3 #status
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Make status window active
        #@@command_window.active = false
        # Go right to status with actor index
        $scene = Scene_Status.new(0)       
    when 4 #quests
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to journal scene
        $scene = Scene_Journal.new
    when 5 # party
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      @@command_window.active = false
      # Switch to journal scene
      $scene = Scene_Party.new
    when 6 #save
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      @@command_window.active = false
      $scene = Scene_SaveLoad.new(:both)
    when 7 #options
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      @@command_window.active = false
      $scene = Scene_Options.new
    when 8 # Exit game
      $game_system.se_play($data_system.decision_se)
      # Create a proc to confirm quit
      confirm_proc = Proc.new {
        @help_window.set_text(nil, '&MUI[GameExitConfirm]')
        window = Window_Command.new(160, ['&MUI[Cancel]', '&MUI[ToTitle]','&MUI[TitleExitGame]'], 1)
        window.x = 560
        window.y = 280
        window.z = 9999
        window.windowskin = RPG::Cache.windowskin("No_Corners")
        loop { Graphics.update; Input.update; window.update
          if Input.trigger?(MENU_INPUT[:Confirm])
            result = window.index
            window.dispose
            break(result)
          elsif Input.trigger?(MENU_INPUT[:Back])
            result = 0
            window.dispose
            break(result)
          end
        }
      }
      case confirm_proc.call
      when 0
        $game_system.se_play($data_system.cancel_se)
        return
      when 1
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Title.new
      when 2
        # Play decision SE
        $game_system.se_play(RPG::AudioFile.new(MenuConfig::START_SFX))
        # Fade out BGM, BGS, and ME
        Audio.bgm_fade(800)
        Audio.bgs_fade(800)
        Audio.me_fade(800)
        # Shutdown
        $scene = nil
      end
      @help_window.set_text(nil, '')
    end
    return
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when status window is active)
  #--------------------------------------------------------------------------
  def update_status
    if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN) || Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      @status_window.refresh
    end
    if Input.trigger?(MENU_INPUT[:Back])
      $game_system.se_play($data_system.cancel_se)
      @@command_window.active = true
      @status_window.active = false
      @status_window.index = -1
      @status_window.refresh
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      case @@command_window.index
      when 1
        if $game_party.actors[@status_window.index].restriction >= 2
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Essence.new(@status_window.index)
      when 2
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Equip.new(@status_window.index)
      when 3
        $game_system.se_play($data_system.decision_se)
        $scene = Scene_Status.new(@status_window.index)
      end
      return
    end
  end
end