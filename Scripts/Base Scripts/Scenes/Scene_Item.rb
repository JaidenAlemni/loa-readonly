#==============================================================================
# ** Scene_Item
# Item screen processing
#==============================================================================
class Scene_Item < Scene_Base
  # Include menu config
  include MenuConfig
  #--------------------------------------------------------------------------
  # * A method for initial scene startup tasks
  #--------------------------------------------------------------------------     
  def pre_start
    # Create windows
    @help_window = Window_SuperHelp.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_TALL), MENU_WINDOW_WIDTH, HELP_HEIGHT_TALL)
    setup_command_window
    # Create an array of item windows for each category
    @item_windows = []
    for i in 0...ITEM_COMMANDS.size
      @item_windows[i] = Window_Item.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH, MENU_WINDOW_HEIGHT - @help_window.height, i)
      @item_windows[i].active = false
      @item_windows[i].visible = false
    end
    @target_window = Window_ItemParty.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH / 2, MENU_WINDOW_HEIGHT - @help_window.height)
    # Associate help window
    @item_windows.each {|win| win.help_window = @help_window}
    @item_windows[0].visible = true
    @target_window.active = false
    @target_window.visible = false
    super
  end  
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------  
  def update
    super
    @item_windows.each {|win| win.update}
    # Input Updates
    if @sub_command_window.active
      update_command
    elsif @target_window.active
      update_target
    else # Item windows are active
      update_item
    end
  end
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  #-------------------------------------------------------------------------- 
  def cleanup
    # Initialize temp window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    @item_windows.each do |win|
      windows << win
      win.move(WINDOW_OFFSCREEN_RIGHT, win.y, WIN_ANIM_SPEED)
    end
    super(windows)
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    clear_command_window
    @item_windows.each {|win| win.dispose}
  end
  #--------------------------------------------------------------------------
  # * Frame Update (command window active)
  #--------------------------------------------------------------------------
  def update_command
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      @item_windows.each {|win| win.visible = false}
      @item_windows[@sub_command_window.index].visible = true
    end
    if Input.trigger?(MENU_INPUT[:Back])
      close_scene
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.decision_se)
      @sub_command_window.active = false
      @item_windows[@sub_command_window.index].active = true
      @item_windows[@sub_command_window.index].update_help
      @item_windows[@sub_command_window.index].index = 0
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (item window active)
  #--------------------------------------------------------------------------
  def update_item
    if Input.trigger?(MENU_INPUT[:Back])
      $game_system.se_play($data_system.cancel_se)
      @sub_command_window.active = true
      @item_windows.each do |window|
        window.active = false
        window.index = -1
      end
      @sub_command_window.update_help
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Get current item window (for categories) 
      item_win = @item_windows[@sub_command_window.index]
      # Get selected item
      @item = item_win.item
      # If not a usable item
      if !@item.is_a?(RPG::Item) || !$game_party.item_can_use?(@item.id, true)
        $game_system.se_play($data_system.buzzer_se)
        return
      else # Usable
        $game_system.se_play($data_system.decision_se)
        # If the scope is an ally
        if @item.scope >= 3
          # Activate target window
          item_win.active = false
          @target_window.active = true
          # Set target window position based on item selected (even = left side)
          @target_window.x = (item_win.index % 2 == 0 ? @target_window.right_x : @target_window.left_x)
          @target_window.visible = true
          # Determine cursor position
          if @item.scope == 4 || @item.scope == 6 #all
            @target_window.index = -1
          else
            @target_window.index = 0
          end
          return
        else
          # If command event is valid
          if @item.common_event_id > 0
            # Command event call reservation
            $game_temp.common_event_id = @item.common_event_id
            # Play item use SE
            $game_system.se_play(@item.menu_se)
            # If consumable
            if @item.consumable
              # Decrease used items by 1
              $game_party.lose_item(@item.id, 1)
              # Refresh item window
              item_win.refresh
            end
            # Switch to map screen
            $scene = Scene_Map.new
            return
          end
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (party window active)
  #--------------------------------------------------------------------------
  def update_target
    if Input.trigger?(MENU_INPUT[:Back])
      $game_system.se_play($data_system.cancel_se)
      @item_windows[@sub_command_window.index].active = true
      @target_window.active = false
      @target_window.visible = false
      @target_window.index = -2
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      # If items are used up
      if $game_party.item_number(@item.id) == 0
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # If target is all
      if @target_window.index == -1
        # Apply item effects to entire party
        used = false
        for i in $game_party.actors(:all)
          used |= i.item_effect(@item)
        end
      end
      # If target is single
      if @target_window.index >= 0
        # Apply item use effects to target actor
        target = $game_party.actors(:all)[@target_window.index]
        used = target.item_effect(@item)
      end
      # If the item was used
      if used
        # Play item use SE
        $game_system.se_play(@item.menu_se)
        # If consumable
        if @item.consumable
          # Decrease used items by 1
          $game_party.lose_item(@item.id, 1)
          # Redraw item window item
          @item_windows[@sub_command_window.index].refresh
        end
        # Remake target window contents
        @target_window.refresh
        # If all party members are dead
        if $game_party.all_dead?
          # Switch to game over screen
          $scene = Scene_Gameover.new
          return
        end
        # If we used the last one of this item
        if $game_party.item_number(@item.id) < 1
          # Return to item window
          @item_windows[@sub_command_window.index].active = true
          @item_windows[@sub_command_window.index].update_help
          @target_window.active = false
          @target_window.visible = false
          @target_window.index = -2
          return
        end
      end
      # If the item wasn't used
      unless used
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
      end
      return
    end
  end
end