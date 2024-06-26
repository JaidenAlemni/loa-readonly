#==============================================================================
# ** Scene_Name
#------------------------------------------------------------------------------
#  This class performs name input screen processing.
#==============================================================================
class Scene_Name < Scene_Base
  include MenuConfig
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def pre_start
    # Get actor
    @actor = $game_actors[$game_temp.name_actor_id]
    # Record the language
    $game_system.name_start_language = Localization.culture
    # Make windows
    x_origin = (LOA::SCRES[0] - 800) / 2
    @edit_window = Window_NameEdit.new(x_origin, MENU_ORIGIN_Y, 800, 96, @actor, $game_temp.name_max_char)
    @input_window = Window_NameInput.new(x_origin, MENU_ORIGIN_Y + @edit_window.height, 800, 600 - @edit_window.height, @actor)
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def set_actor_name
    new_name = @edit_window.name
    # Normalize
    # if Localization.culture == :jp && !MAIN_CHAR_NAMES[Localization.culture].has_value?(new_name)
    #   new_name = @edit_window.name.zen_to_han
    # end
    # Change actor name
    @actor.name = new_name
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    # If B button was pressed
    if Input.repeat?(MENU_INPUT[:Back])
      # If cursor position is at 0
      if @edit_window.index == 0
        return
      end
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Delete text
      @edit_window.back
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # If cursor position is at [OK]
      if @input_window.character == nil
        # If name is empty 
        if @edit_window.name == "" || @edit_window.name == " "
          # Return to default name
          @edit_window.restore_default
          # If name is empty
          if @edit_window.name == ""
            # Play buzzer SE
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          # Play decision SE
          $game_system.se_play($data_system.decision_se)
          return
        end
        set_actor_name
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Switch to map screen
        $scene = Scene_Map.new
        return
      end
      # If changing to a japanese table
      if @input_window.table_max > 0
        $game_system.se_play($data_system.decision_se)
        case @input_window.character
        when "カナ" # Switch to katakana
          @input_window.char_table = 1 
          @input_window.refresh
          return
        when "英数" # Switch to fw english
          @input_window.char_table = 2 
          @input_window.refresh
          return
        end
      end
      # If cursor position is at maximum
      if @edit_window.index == $game_temp.name_max_char
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # If text character is empty
      if ["　", "", " "].include?(@input_window.character)
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Add text character
      @edit_window.add(@input_window.character)
      return
    end
  end
end
