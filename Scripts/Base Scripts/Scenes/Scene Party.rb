#==============================================================================
# ** Scene_Party
#------------------------------------------------------------------------------
# Party Scene Processing
# Characters can be swapped in and out of battle.
#==============================================================================
class Scene_Party < Scene_Base
  include MenuConfig
  #--------------------------------------------------------------------------
  # * A method for initial scene startup tasks
  #--------------------------------------------------------------------------     
  def pre_start
    # Create windows
    @help_window = Window_SuperHelp.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_SHORT), MENU_WINDOW_WIDTH, HELP_HEIGHT_SHORT)
    create_title_windows

    winw = MENU_WINDOW_WIDTH / 2
    winh = MENU_WINDOW_HEIGHT - (HELP_HEIGHT_SHORT * 2)
    @active_member_window = Window_PartyActive.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y + HELP_HEIGHT_SHORT, winw, winh)
    @standby_member_window = Window_PartyStandby.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH + @active_member_window.width, MENU_ORIGIN_Y + HELP_HEIGHT_SHORT, winw, winh)
  end
  #--------------------------------------------------------------------------
  # * Create Title Windows
  #--------------------------------------------------------------------------
  def create_title_windows
    # Active Characters
    @active_title_window = Window_Base.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH / 2, HELP_HEIGHT_SHORT)
    text = "Active Characters"
    @active_title_window.contents.draw_text(0, 0, @active_title_window.width, @active_title_window.height - 32, text, 1)
    # Standby Characters
    @standby_title_window = Window_Base.new(MENU_ORIGIN_X + COMMAND_WIN_WIDTH + @active_title_window.width, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH / 2, HELP_HEIGHT_SHORT)
    text = "Standby Characters"
    @standby_title_window.contents.draw_text(0, 0, @standby_title_window.width, @standby_title_window.height - 32, text, 1)
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------  
  def update
    super
    # Input Updates
    if @standby_member_window.active
      update_standby
    else # Item windows are active
      update_active
    end
  end
  #--------------------------------------------------------------------------
  # * Update Active Members
  #--------------------------------------------------------------------------
  def update_active
    # Exit
    if Input.trigger?(MENU_INPUT[:Back])
      close_scene
      @@command_window.active = true
      return
    end
    # Choose actor
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Prevent Oliver change
      if @active_member_window.index == 0
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        @help_window.set_text(nil, "Oliver cannot be removed from the party!")
        return
      end
      # No actors to select
      # if $game_party.standby_actors.size < 1
      #   # Play buzzer SE
      #   $game_system.se_play($data_system.buzzer_se)
      #   @help_window.set_text(nil, "There are other characters to select!")
      #   return
      # end
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Switch to window
      @standby_member_window.active = true
      @active_member_window.active = false
    end
  end
  #--------------------------------------------------------------------------
  # * Update Standby Members
  #--------------------------------------------------------------------------
  def update_standby
    # Go Back
    if Input.trigger?(MENU_INPUT[:Back])
      # Play decision SE
      $game_system.se_play($data_system.cancel_se)
      # Switch to window
      @standby_member_window.active = false
      @active_member_window.active = true
      return
    end
    # Choose actor
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      process_party_change
      @standby_member_window.active = false
      @active_member_window.active = true
    end
  end
  #--------------------------------------------------------------------------
  # * Change actors
  #--------------------------------------------------------------------------
  def process_party_change
    standby_character = @standby_member_window.actor
    active_character = @active_member_window.actor
    # Remove the active character
    $game_party.remove_battle_char(active_character)
    if !standby_character.nil?
      # If the standby character is not nil, add in new character
      $game_party.add_battle_char(standby_character)
    end
    @active_member_window.refresh
    @standby_member_window.refresh
    # Move the cursor to match sorting
    if !standby_character.nil?
      @active_member_window.index = @active_member_window.actor_index(standby_character)
    end
  end
end