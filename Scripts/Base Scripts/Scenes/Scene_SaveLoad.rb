#==============================================================================
# * Scene_SaveLoad
# This scene handles file management
#==============================================================================
class Scene_SaveLoad < Scene_Base
  include MenuConfig
  #------------------------------------------------------------------------------
  # Object Initialization
  #------------------------------------------------------------------------------
  def initialize(state)
    super
    @state = state
    # # Timestamp selects new file
    # $game_temp.last_file_index = 0
    # latest_time = Time.at(0)
    # # Test file existence
    # MAX_SAVEFILES.times do |i|
    #   filename = GameSetup.savefile_name(i)
    #   if FileTest.exist?(filename)
    #     file = File.open(filename, "r")
    #     if file.mtime > latest_time
    #       latest_time = file.mtime
    #       $game_temp.last_file_index = i
    #     end
    #     file.close
    #   end
    # end
    # # Set index and help
    # @file_index = $game_temp.last_file_index
  end
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def pre_start
    # If we're coming from the menu, saving and loading is allowed
    if @state == :both
       # Create sub command window
      setup_command_window
      x_origin = MENU_ORIGIN_X + @sub_command_window.width
      if $game_system.save_disabled
        @sub_command_window.disable_item(0)
      end
    else
      x_origin = (LOA::SCRES[0] - 800) / 2
    end
    # Create help window
    @help_window = Window_MenuHelp.new(x_origin, MENU_ORIGIN_Y + MENU_WINDOW_HEIGHT - HELP_HEIGHT_SHORT, MENU_WINDOW_WIDTH, HELP_HEIGHT_SHORT, true)
    @help_text =
      case @state
      when :both
        ""
      when :save
        '&MUI[MemoriesMenuDesc0]'
      when :load
        '&MUI[MemoriesMenuDesc1a]'
      end
    @help_window.set_text(@help_text)
    # Create file window (this also loads save data)
    @file_window = Window_Saves.new(x_origin, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH, MENU_WINDOW_HEIGHT - HELP_HEIGHT_SHORT)
    # Set the index accordingly if we're in the load state
    if @state != :both
      @file_window.active = true
    end
    @file_window.index = $game_temp.last_file_index if @file_window.active
    super
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    clear_command_window if @@command_window && $scene.is_a?(Scene_Menu)
  end
  #--------------------------------------------------------------------------
  # * Load File
  #--------------------------------------------------------------------------
  def load_file(filename)
    # If file doesn't exist
    if @file_window.data.nil? || @file_window.data == "LOADERROR"
      # Play buzzer SE
      $game_system.se_play($data_system.buzzer_se)
      return
    end
    # Remake temporary object
    $game_temp = Game_Temp.new
    # Play load SE
    $game_system.se_play($data_system.load_se)
    # Read save data
    file = File.open(filename, "rb")
    GameSetup.read_save_data(file)
    file.close
    # Restore BGM and BGS
    # FIXME This should be in Game_Map so it's caught by magic number reloads?
    begin
      $game_system.bgm_play($game_system.playing_bgm)
      $game_system.bgs_play($game_system.playing_bgs)
    rescue Errno::ENOENT
      # Just don't load any music for now until this is sorted out
    end
    # Update map (run parallel process event)
    $game_map.update
    # Trigger the save event without calling the save screen
    $game_map.events.values.each do |event|
      if event.name == "[CLONE]:1"
        $game_system.save_disabled = true
        event.triggering_event_id = 0
        event.trigger_on = true
      end
    end
    # Flag the map area display
    $game_temp.display_map_name = true
    # Switch to map screen
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # * Save File
  #--------------------------------------------------------------------------
  def save_file(filename)
    # Play save SE
    $game_system.se_play($data_system.save_se)
    # Write save data
    # TODO: Create overwrite warning proc
    file = File.open(filename, "wb")
    GameSetup.write_save_data(file)
    file.close
    # Confirm
    @file_window.refresh
    @help_window.set_text('&MUI[SaveConfirm]')
  end
  #--------------------------------------------------------------------------
  # * Delete File
  #--------------------------------------------------------------------------
  def delete_file(filename)
    # If file doesn't exist
    unless FileTest.exist?(filename)
      # Play buzzer SE
      $game_system.se_play($data_system.buzzer_se)
      return
    end
    # Confirm proc
    confirm_proc = Proc.new {
      @help_window.set_text('&MUI[SaveDeleteWarn]')
      window = Window_Command.new(160, ['&MUI[Confirm]', '&MUI[Cancel]'])
      window.x = @file_window.x + 320
      window.y = @file_window.y + 60
      window.z = 9999
      loop { Graphics.update; Input.update; window.update
        if Input.trigger?(MENU_INPUT[:Confirm]) || Input.trigger?(MENU_INPUT[:Back])
          result = (Input.trigger?(MENU_INPUT[:Confirm]) && window.index == 0)
          $game_system.se_play($data_system.cancel_se) unless result
          window.dispose
          break(result)
        end
      }
    }
    # Delete File
    if confirm_proc.call
      $game_system.se_play($data_system.save_se)
      File.delete(filename)
      @file_window.refresh
      @help_window.set_text('&MUI[MemoriesMenuDesc2]')
    end
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------  
  def update
    super
    # Update windows
    @@bg.opacity -= 10 if @@bg && @@bg.opacity > 200
    # Determine input
    if @sub_command_window && @sub_command_window.active
      update_command
    else 
      update_files
    end
  end 
  #--------------------------------------------------------------------------
  # * Update command window
  #--------------------------------------------------------------------------  
  def update_command
    # If select button is pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      if @sub_command_window.index == 0 && $game_system.save_disabled
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Update help window text
      @help_text = "&MUI[MemoriesMenuDesc#{@sub_command_window.index}]"
      $game_system.se_play($data_system.decision_se)
      @help_window.set_text(@help_text, 1)
      # Make file windows active
      @sub_command_window.active = false
      # Expand current window
      @file_window.active = true
      return
    end
    # If cancel button is pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # If called from event
      $game_temp.save_calling = false
      # Exit scene
      close_scene
    end
  end
  #--------------------------------------------------------------------------
  # * Update file windows
  #--------------------------------------------------------------------------  
  def update_files
    # Confirm
    if Input.trigger?(MENU_INPUT[:Confirm])
      file_action
      return
    elsif Input.trigger?(MENU_INPUT[:Back])
      # If called from event
      if $game_temp.save_calling
        # Clear save call flag
        $game_temp.save_calling = false
        # Switch to map screen
        $scene = Scene_Map.new
        return
      else
        case @state
        when :both
          @help_text = ""
          @help_window.set_text(@help_text, 1)
          @file_window.active = false
          @sub_command_window.active = true 
          $game_system.se_play($data_system.cancel_se)
          return
        else
          $game_temp.save_calling = false
          close_scene
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Update file windows
  #--------------------------------------------------------------------------   
  def file_action
    filename = GameSetup.savefile_name(@file_window.index)
    # If we are permmitted to do both, branch by index
    case @state
    when :both
      # Branch by command window index
      case @sub_command_window.index
      when 0 # Save
        save_file(filename)
        $game_temp.last_file_index = @file_index
        # @help_text = ""
        # @help_window.set_text(@help_text, 1)
        # @file_windows[@file_index].selected = false
        # @sub_command_window.active = true
      when 1 # Load
        load_file(filename)
      when 2 # Delete
        delete_file(filename)
      end
    when :save
      save_file(filename)
      $game_temp.last_file_index = @file_index
    when :load
      load_file(filename)
    end
    # Reload file data
    # for i in 0...@file_windows.size
    #   @file_windows[i].get_file(i, GameSetup.savefile_name(i))
    #   @file_windows[i].refresh
    # end
    # Close the scene if we called from the map
    if $game_temp.save_calling
      # Clear save call flag
      $game_temp.save_calling = false
      # Wait a bit, then auto close
      GUtil.wait(0.75)
      @file_window.active = false
      # Switch to map screen
      $scene = Scene_Map.new
      return
    end
  end
end

