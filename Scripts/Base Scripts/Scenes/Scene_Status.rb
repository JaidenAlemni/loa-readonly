class Scene_Status < Scene_Base
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
    @help_window = Window_MenuHelp.new(x_origin, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_SHORT), MENU_WINDOW_WIDTH, HELP_HEIGHT_SHORT, true)
    setup_command_window
    @sub_command_window.index = @actor_index
    @status_window = Window_Status.new(x_origin, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH, MENU_WINDOW_HEIGHT-HELP_HEIGHT_SHORT, @actor)
    #@skill_window = Window_StatusAwakening.new(x_origin + 392, MENU_ORIGIN_Y + 230, 380, 200, @actor)
    @stats_window = Window_StatusStats.new(x_origin + 346, MENU_ORIGIN_Y + 8, 460, 160, @actor)
    # Associate help  window
    @stats_window.help_window = @help_window
    #@skill_window.help_window = @help_window
    # Make initial window active
    if $game_party.actors(:all).size > 1
      @sub_command_window.active = true
      @stats_window.active = false
    else
      @sub_command_window.active = false
      @stats_window.active = true
    end
    @help_window.set_text(MenuDescriptions.stat_description(@stats_window.index))
    super
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    clear_command_window
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------  
  def update
    super
    # Input Updates
    if @sub_command_window.active
      update_command
    # elsif @skill_window.active
    #   update_skills
    elsif @stats_window.active
      update_stats
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
  # * Frame Update
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
      @stats_window.active = true
      @stats_window.index = 0
      return
    end
  end  
  #--------------------------------------------------------------------------
  # * Frame Update (awakening window active)
  #-------------------------------------------------------------------------- 
  def update_skills
    # Move to next window
    if @skill_window.window_switch
      $game_system.se_play($data_system.cursor_se)
      @stats_window.window_switch = false
      @stats_window.index = 7
      @stats_window.active = true
      @skill_window.index = -1
      @skill_window.active = false
      @help_window.set_text(MenuDescriptions.stat_description(@stats_window.index))
      return
    end
    # Cancel input
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @skill_window.index = -1
        @skill_window.active = false
      else
        close_scene
      end
      return
    end
  end  
  #--------------------------------------------------------------------------
  # * Frame Update (stats window active)
  #-------------------------------------------------------------------------- 
  def update_stats
    # Move to next window
    if @stats_window.window_switch
      $game_system.se_play($data_system.cursor_se)
      # @skill_window.window_switch = false
      # @skill_window.index = 0
      # @skill_window.active = true
      @stats_window.index = -1
      @stats_window.active = false
      @help_window.set_text(MenuDescriptions.stat_description(@stats_window.index))
      return
    end
    # Cancel input
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @stats_window.index = -1
        @stats_window.active = false
      else
        close_scene
      end
      return
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
      # Update windows
      #@skill_window.refresh(@actor)
      @status_window.refresh(@actor)
      @stats_window.refresh(@actor)
      # Return to status window
      # @skill_window.active = false
      # @skill_window.index = -1
      @stats_window.active = true if !@sub_command_window.active
      @stats_window.index = 0 if !@sub_command_window.active
    end
  end
end