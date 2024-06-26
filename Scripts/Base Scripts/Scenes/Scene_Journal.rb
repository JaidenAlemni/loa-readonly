#==============================================================================
# ** Scene_Journal
#------------------------------------------------------------------------------
#  This menu screen allows the user to select various guide-related items
#==============================================================================
class Scene_Journal < Scene_Base
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     menu_index : command cursor's initial position
  #--------------------------------------------------------------------------
  def initialize(menu_index = 0)
    @menu_index = menu_index
    super
  end
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def pre_start
    # Make windows
    @command_window = Window_JournalCommand.new(MenuConfig::MENU_ORIGIN_X, MenuConfig::MENU_ORIGIN_Y, 800, 64)
    @status_window = Window_Collection.new(MenuConfig::MENU_ORIGIN_X, MenuConfig::MENU_ORIGIN_Y + @command_window.height, 800, 472)
    @help_window = Window_MenuHelp.new(MenuConfig::MENU_ORIGIN_X, MenuConfig::MENU_ORIGIN_Y + @status_window.height + @command_window.height, 800, 64)
    @playtime_window = Window_PlayTime.new(MenuConfig::MENU_ORIGIN_X + 623, MenuConfig::MENU_ORIGIN_Y + 195)
    # Associate help
    @command_window.help_window = @help_window
    @command_window.index = @menu_index
    @help_window.set_text(MenuDescriptions.journal_command(@command_window.index))
  end
  #--------------------------------------------------------------------------
  # * Cleanup windows
  #--------------------------------------------------------------------------  
  def cleanup
    # Save current menu index
    @menu_index = @command_window.index
    super 
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @playtime_window.update
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Branch by command window cursor position
      case @command_window.index
      when 0 # Quests
        $game_system.se_play($data_system.decision_se)       
        $scene = Scene_Quest.new 
      when 1 # Bestiary
        $game_system.se_play($data_system.decision_se)       
        $scene = Scene_Bestiary.new 
      when 2 # Recipes
      when 3 # Books
        $game_system.se_play($data_system.decision_se)       
        $scene = Scene_Book.new 
      when 4 # Exit
        $game_system.se_play($data_system.cancel_se)
        # Switch to menu screen
        close_scene
        return
      end
    end
    # Cancel input
    if Input.trigger?(MENU_INPUT[:Back])
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Switch to menu screen
      close_scene
      return
    end
  end
end #class