#==============================================================================
# ** Scene_Gameover
#------------------------------------------------------------------------------
#  This class performs game over screen processing.
#==============================================================================

class Scene_Gameover < Scene_Base
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def main
    @move_window = false
    # Make game over graphics
    @over_bg = Sprite.new
    @over_bg.bitmap = RPG::Cache.system("GO_Back")
    @over_bg.z = 9800
    @text = Sprite.new
    @text.bitmap = RPG::Cache.system("GO_Text")
    @text.opacity = 0
    @text.z = 9900
    # Make Command window
    commands = ["&MUI[TitleContinue]", "&MUI[ToTitle]"]
    @command_window = Window_Command.new(180, commands, 1)
    @command_window.z = 9999
    # If we're returning from loading, don't run animations again
    if $game_temp.return_to_gameover
      @command_window.visible = true
      @command_window.active = true
      @move_window = false
      @text.y = -180
      @text.opacity = 255
    else
      @command_window.visible = false 
      @command_window.active = false
    end
    @command_window.x = LOA::SCRES[0] / 2 - @command_window.width / 2
    @command_window.y = LOA::SCRES[1] / 2 - @command_window.height / 2
    # If we're returning from loading, don't stop / re-init music
    unless $game_temp.return_to_gameover
      $game_system.bgm_stop
      $game_system.bgs_stop
      # Play game over ME (if we're not returning)
      $game_system.bgm_play($data_system.gameover_me)
    end
    # Execute transition
    if $game_temp.return_to_gameover
      Graphics.transition(20)
    else
      Graphics.transition(120)
    end
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of game over graphic
    @over_bg.dispose
    @text.dispose
    @command_window.dispose
    @command_window = nil
    # If battle test
    if $BTEST
      $scene = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    @command_window.update
    # If we just got back from the previous 
    # Display the text
    if @text.opacity < 255
      @text.opacity += 1
      return
    end
    if @move_window
      if @text.y > -180
        @text.y -= 4
        return
      elsif @text.y <= -180
        @command_window.visible = true
        @command_window.active = true
        @move_window = false
        return
      end
    end
    # If the command window isn't visible yet
    if @command_window.visible == false && !@move_window
      # Make the command window visible
      @move_window = true
      return
    end
    # If C button was pressed
    if Input.trigger?(MenuConfig::MENU_INPUT[:Confirm])
      # Branch by index
      case @command_window.index 
      when 0 # Continue
        $game_system.se_play($data_system.decision_se)
        $game_system.save_disabled = true
        # Flag in case the player cancels loading a file
        $game_temp.return_to_gameover = true
        @command_window.visible = false
        $scene = Scene_SaveLoad.new(:load)
      when 1 # To title
        $game_system.se_play($data_system.decision_se)
        $game_temp.return_to_gameover = false
        $scene = Scene_Title.new
        $game_temp.gameover = false
      end
    end
  end
end
