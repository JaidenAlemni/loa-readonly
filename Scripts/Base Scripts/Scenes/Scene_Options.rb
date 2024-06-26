#==============================================================================
# ** Scene_Options
#------------------------------------------------------------------------------
#  This class performs options screen processing.
#==============================================================================
class Scene_Options < Scene_Base
  # Include menu config module
  include MenuConfig
  #--------------------------------------------------------------------------
  # * A method for initial scene startup tasks
  #--------------------------------------------------------------------------
  def pre_start
    # Load options data
    GameSetup.load_options
    # Setup windows
    @help_window = Window_SuperHelp.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_TALL), MENU_WINDOW_WIDTH, HELP_HEIGHT_TALL)
    # If we came from the title screen, manually setup the command window
    if @previous_scene.is_a?(Scene_Title)
      # Create the sub command window
      commands = MenuConfig::MAINMENU_SUB_COMMANDS['Options']
      @sub_command_window = Window_Menu.new(MENU_ORIGIN_X, MENU_ORIGIN_Y, COMMAND_WIN_WIDTH, MENU_WINDOW_HEIGHT, commands, 'Options')
      # Associate windows
      @sub_command_window.help_window = @help_window
      # Set active state
      @sub_command_window.active = true
    else
      setup_command_window
    end
    # Create an array of windows for each category
    @option_windows = []
    for i in 0...OPTION_COMMANDS.size
      @option_windows[i] = Window_Options.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH, MENU_WINDOW_HEIGHT - @help_window.height, OPTION_COMMANDS[i].downcase.to_sym)
      @option_windows[i].active = false
      @option_windows[i].visible = false
    end
    # Associate help window
    @option_windows.each {|win| win.help_window = @help_window}
    @option_windows[0].visible = true
    # Controller graphic
    @controller_graphic = Sprite.new(LOA::SCRES[0], LOA::SCRES[1])
    @controller_graphic.z = 9999
    @controller_graphic.opacity = 0
    super
  end
  #--------------------------------------------------------------------------
  # * Change language
  #-------------------------------------------------------------------------- 
  def change_language
    # Determine current locale 
    if Localization.culture == :jp
      new_lang = :en_us
    else
      new_lang = :jp
    end
    # Switch to other
    $game_system.previous_language = Localization.culture
    Localization.culture = new_lang
    # Write to options
    $game_options.language = new_lang
    # Refresh
    $game_system.se_play($data_system.cursor_se)
    @option_windows.each {|win| win.refresh}
    @option_windows[@sub_command_window.index].refresh
    @option_windows[@sub_command_window.index].update_help
    @@command_window&.refresh('Options')
  end 
  #--------------------------------------------------------------------------
  # * Update
  #--------------------------------------------------------------------------
  def update
    super
    @option_windows.each {|win| win.update}
    # Input Updates
    if @controller_graphic.opacity == 255
      update_controls
    elsif @sub_command_window.active
      update_command
    else # Item windows are active
      update_options
    end
  end
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  #-------------------------------------------------------------------------- 
  def cleanup
    # Initialize temp window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    @option_windows.each do |win|
      windows << win
      win.move(WINDOW_OFFSCREEN_RIGHT, win.y, WIN_ANIM_SPEED)
    end
    @sub_command_window.move(WINDOW_OFFSCREEN_LEFT, @sub_command_window.y, WIN_ANIM_SPEED)
    windows << @sub_command_window
    super(windows)
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    clear_command_window
    @controller_graphic.dispose
    @option_windows.each {|win| win.dispose}
  end
  #--------------------------------------------------------------------------
  # * Update controls overlay
  #--------------------------------------------------------------------------  
  def update_controls
    if Input.trigger?(MENU_INPUT[:Back]) || Input.trigger?(MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.cancel_se)
      hide_controls
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (command window active)
  #--------------------------------------------------------------------------
  def update_command
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      @option_windows.each {|win| win.visible = false}
      windex = @sub_command_window.index
      @option_windows[windex].visible = true
      if windex == 1
        @option_windows[1].show_vol_bars
      else
        @option_windows[1].hide_vol_bars
      end
    elsif Input.trigger?(MENU_INPUT[:Back])
      # Change player name if previous scene != title
      if !@previous_scene.is_a?(Scene_Title)
        GameSetup.change_player_name
      end
      # Save data on exit
      GameSetup.save_options
      # Switch to menu screen
      close_scene
      return
    elsif Input.trigger?(MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.decision_se)
      @sub_command_window.active = false
      @option_windows[@sub_command_window.index].active = true
      @option_windows[@sub_command_window.index].update_help
      @option_windows[@sub_command_window.index].index = 0
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Show controls "window"
  #--------------------------------------------------------------------------
  def show_controls
    # Setup bitmap
    type = (!Input::Controller.connected? || $game_options.kb_override) ? "Keyboard" : "Controller"
    graphic_name = "Controls/#{type}_#{Localization.culture}"
    @controller_graphic.bitmap = RPG::Cache.system(graphic_name)
    @option_windows[@sub_command_window.index].active = false
    fade_step = 15
    fade_step.times do
      @controller_graphic.opacity += (255 / fade_step)
      Graphics.update
    end
    @controller_graphic.opacity = 255
  end
  #--------------------------------------------------------------------------
  # * Hide controls "window"
  #--------------------------------------------------------------------------
  def hide_controls
    fade_step = 15
    fade_step.times do
      @controller_graphic.opacity -= (255 / fade_step)
      Graphics.update
    end
    @controller_graphic.opacity = 0
    @option_windows[@sub_command_window.index].active = true
  end
  #--------------------------------------------------------------------------
  # * Go to Feedback Form
  #--------------------------------------------------------------------------
  def feedback_form
    sys_proc = GUtil.create_system_modal("&MUI[GameCreditsWeb]", ["&MUI[Cancel]","OK"], 360, 128)
    if sys_proc.call == 1
      # Launch browser
      System.launch("https://www.studioalemni.com/demo-feedback")
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (Options windows)
  #--------------------------------------------------------------------------
  def update_options
    # If B (cancel) was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      $game_system.se_play($data_system.cancel_se)
      @sub_command_window.active = true
      @option_windows.each do |window|
        window.active = false
        window.index = -1
      end
      @sub_command_window.update_help
      return
    end
    opt = @option_windows[@sub_command_window.index]
    # View options
    if opt.type == :gameplay && opt.item == :view_controls
      if Input.trigger?(MENU_INPUT[:Confirm])
        $game_system.se_play($data_system.decision_se)
        show_controls
        return
      end
    elsif opt.type == :gameplay && opt.item == :feedback_form
      if Input.trigger?(MENU_INPUT[:Confirm])
        $game_system.se_play($data_system.decision_se)
        feedback_form
        return
      end
    # Audio
    elsif opt.type == :system && opt.index < 3
      if Input.repeat?(Input::LEFT)
        process_volume_change(opt.item, :reduce)
        return
      elsif Input.repeat?(Input::RIGHT)
        process_volume_change(opt.item, :increase)
        return
      end
    # Others
    elsif Input.trigger?(MENU_INPUT[:Confirm]) || Input.trigger?(Input::RIGHT)
      process_option_change(opt.item)
    elsif Input.trigger?(Input::LEFT)
      process_option_change(opt.item, :decrease)
    end
  end
  #--------------------------------------------------------------------------
  # * Change the audio volume
  #  option : Symbol representing $game_options attribute
  #--------------------------------------------------------------------------
  def process_volume_change(option, dir)
    # Get the method
    option = $game_options.options(option)
    prev_vol = Audio.send(option)
    # Change "bgm_volume" to "change_bgm_vol", etc.
    command = (option.to_s + '=').to_sym
    case dir
    when :reduce
      Audio.send(command, prev_vol - 1)
    when :increase
      Audio.send(command, prev_vol + 1)
    end
    new_vol = Audio.send(option)
    if prev_vol != new_vol
      @option_windows[@sub_command_window.index].refresh
      $game_system.se_play($data_system.cursor_se) if option == :se_volume
    end
  end
  #--------------------------------------------------------------------------
  # * Change a setting
  #  option : Symbol representing $game_options attribute
  #  dir    : Increase or decrease, if applicable
  #--------------------------------------------------------------------------
  def process_option_change(option, dir = :increase)
    if option == :language
      change_language
      return
    end
    # Get the possible options
    possible_values = $game_options.options(option)
    command = option.to_s.concat('=').to_sym
    # Get the current value
    current_value = $game_options.send(option)
    # Set to the "index" of the current value
    current_index = possible_values.index(current_value)
    # Case by dir, if applicable
    case dir
    when :increase
      possible_values.rotate!(1)
    when :decrease
      possible_values.rotate!(-1)
    end
    # Set to the new value
    $game_options.send(command, possible_values[current_index])
    # If the value changed
    new_val = $game_options.send(option)
    if new_val != current_value
      $game_system.se_play($data_system.cursor_se)
      @option_windows[@sub_command_window.index].refresh
      @option_windows[@sub_command_window.index].update_help
      @controls_window.refresh
    end
  end
end
