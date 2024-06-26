#==============================================================================
# ** Scene_Equip
#------------------------------------------------------------------------------
#  This class performs equipment screen processing.
#==============================================================================
class Scene_Equip < Scene_Base
  include MenuConfig
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     actor_index : actor index
  #--------------------------------------------------------------------------
  def initialize(actor_index = 0)
    super
    @actor_index = actor_index
  end
  #--------------------------------------------------------------------------
  # * A method for initial scene startup tasks
  #--------------------------------------------------------------------------     
  def pre_start
    # Get actor
    @actor = $game_party.actors(:all)[@actor_index]
    # Create windows
    x_origin = MENU_ORIGIN_X + COMMAND_WIN_WIDTH
    @help_window = Window_SuperHelp.new(x_origin, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_TALL), MENU_WINDOW_WIDTH, HELP_HEIGHT_TALL)
    setup_command_window
    @sub_command_window.index = @actor_index
    @actor_window = Window_EquipActor.new(x_origin, MENU_ORIGIN_Y, 480, 248, @actor)
    @title_window = Window_EquipTitle.new(x_origin + @actor_window.width, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH - @actor_window.width, HELP_HEIGHT_SHORT)
    @status_window = Window_EquipInfo.new(x_origin, MENU_ORIGIN_Y + @actor_window.height, @actor_window.width, MENU_WINDOW_HEIGHT - @help_window.height - @actor_window.height, @actor)
    @list_windows = []
    for i in 0..5
      @list_windows[i] = Window_EquipList.new(x_origin + @actor_window.width, MENU_ORIGIN_Y + @title_window.height, @title_window.width, MENU_WINDOW_HEIGHT - @help_window.height - @title_window.height, @actor, i)
      @list_windows[i].active = false
      @list_windows[i].visible = false  
    end
    # Associate help window
    @list_windows.each {|win| win.help_window = @help_window}
    @actor_window.help_window = @help_window
    @list_windows[0].visible = true
    @title_window.set_text(@actor_window.index)
    # Make initial window active
    @actor_window.index = 0
    if $game_party.actors(:all).size > 1
      @sub_command_window.active = true
      @actor_window.active = false
    else
      @sub_command_window.active = false
      @actor_window.active = true
    end
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------  
  def update
    super
    @list_windows.each {|win| win.update}
    # Input Updates
    if @sub_command_window.active
      update_command
    elsif @actor_window.active
      update_actor
    else 
      update_list
    end
    return if @sub_command_window.active
    # If R button was pressed
    if Input.trigger?(MENU_INPUT[:Actor_Forward])
      # To next actor
      actor_switch((@actor_index + 1) % $game_party.actors(:all).size)
      return
    # If L button was pressed
    elsif Input.trigger?(MENU_INPUT[:Actor_Back])
      # Go to prev actor
      actor_switch((@actor_index - 1) % $game_party.actors(:all).size)
      return
    end
  end
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  #-------------------------------------------------------------------------- 
  def cleanup
    # Initialize temp window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    @list_windows.each do |win|
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
    @list_windows.each {|win| win.dispose}
  end
  #--------------------------------------------------------------------------
  # * Frame Update (sub command window active)
  #-------------------------------------------------------------------------- 
  def update_command
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      actor_switch(@sub_command_window.index)
    end
    if Input.trigger?(MENU_INPUT[:Back])
      close_scene
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.decision_se)
      @sub_command_window.active = false
      @actor_window.active = true
    end
  end  
  #--------------------------------------------------------------------------
  # * Frame Update (actor window active)
  #-------------------------------------------------------------------------- 
  def update_actor
    # Cancel input
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @actor_window.active = false
      else
        close_scene
      end
      return
    end
    # Confirm input
    if Input.trigger?(MENU_INPUT[:Confirm])
      # If equipment is fixed
      if @actor.equip_fix?(@actor_window.index)
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Activate item window
      @actor_window.active = false
      @list_windows[@actor_window.index].active = true
      @list_windows[@actor_window.index].index = 0
      @status_window.refresh(@actor, @actor_window.index, @list_windows[@actor_window.index].item, true)
      return
    end
    # If cursor move
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      @list_windows.each {|win| win.visible = false}
      @list_windows[@actor_window.index].visible = true
      @status_window.refresh(@actor, @actor_window.index, @actor_window.item)
      @title_window.set_text(@actor_window.index)
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (list window active)
  #-------------------------------------------------------------------------- 
  def update_list
    # Cancel input
    if Input.trigger?(MENU_INPUT[:Back])
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Activate actor window
      @actor_window.active = true
      @list_windows[@actor_window.index].active = false
      @list_windows[@actor_window.index].index = -1
      @status_window.refresh(@actor, @actor_window.index, @actor_window.item)
      return
    end
    # Confirm input
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Get currently selected data on the item window
      item = @list_windows[@actor_window.index].item
      # Change equipment
      # Determine if the item exists, or if we're unequipping
      if item.nil?
        # Unequip
        $game_system.se_play(RPG::AudioFile.new(MenuConfig::UNEQUIP_SFX))
        equip_id = 0
      else
        # Equip
        $game_system.se_play($data_system.equip_se)
        equip_id = item.id
      end
      @actor.equip(@actor_window.index, equip_id)
      # Activate right window
      @actor_window.active = true
      @list_windows[@actor_window.index].active = false
      @list_windows[@actor_window.index].index = -1
      # Remake window contents
      @actor_window.refresh
      # Check if accessory, refresh windows
      if @actor_window.index >= 4
        @list_windows[4].refresh
        @list_windows[5].refresh
      else
        @list_windows[@actor_window.index].refresh
      end
      @status_window.refresh(@actor, @actor_window.index, @actor_window.item)
      return
    end
    # If cursor move
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      # Compare equipment
      @status_window.refresh(@actor, @actor_window.index, @list_windows[@actor_window.index].item, true)
    end
  end
  #--------------------------------------------------------------------------
  # * Switch actors
  # direction - determines if next (1) or previous (0)
  #--------------------------------------------------------------------------
  def actor_switch(index)
    @actor_index = index
    @sub_command_window.index = index if !@sub_command_window.active
    # Save old actor
    prev_actor = @actor
    # Set actor
    @actor = $game_party.actors(:all)[index]
    # Do stuff if the actor changed
    if @actor != prev_actor
      # Play cursor SE
      $game_system.se_play(RPG::AudioFile.new(PAGE_SFX,100,100))
      # Update all windows
      @actor_window.refresh(@actor)
      @status_window.refresh(@actor)
      @list_windows.each {|win| win.refresh(@actor)}
      # Return to actor window
      @actor_window.active = true unless @sub_command_window.active
      @actor_window.update_help
      @list_windows[@actor_window.index].active = false
      @list_windows[@actor_window.index].index = -1
    end
  end
end
