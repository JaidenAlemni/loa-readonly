#==============================================================================
# ** Scene_Base
# Parent class for all menu scenes
#==============================================================================
class Scene_Base
  include MenuConfig
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(_index = 0)
    # Set the previous scene
    @previous_scene = $scene
    # Create background
    if @previous_scene.is_a?(Scene_Map) || @previous_scene.is_a?(Scene_Gameover)
      # Init command window
      @@command_window = nil
      @@bg = Sprite.new
      @@bg.bitmap = Graphics.snap_to_bitmap
      @@bg.bitmap.blur
      @@bg.z = 1
    end
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------   
  def main 
    # Initial startup 
    pre_start
    # Scene start (prepare for loop)
    start
    # Scene loop
    main_loop
    # Cleanup
    cleanup
    # Scene exit
    terminate
  end
  #--------------------------------------------------------------------------
  # * A method for initial scene startup tasks
  #--------------------------------------------------------------------------     
  def pre_start
    # Create help window
    cx = (@sub_command_window || $scene.is_a?(Scene_Menu)) ? MENU_ORIGIN_X : (LOA::SCRES[0] - 800) / 2
    @controls_window = Window_Controls.new(cx, MENU_ORIGIN_Y + MENU_WINDOW_HEIGHT, 1200)
    @controls_window.setup_inputs(self.sym_from_scene, nil, ($game_party.actors.size > 1))
    @controls_window.fixed = true
    @controls_window.appear(200)
  end
  #--------------------------------------------------------------------------
  # * Get controls window symbol for this scene
  #-------------------------------------------------------------------------- 
  def sym_from_scene
    # oh yeah, meta time
    str = $scene.class.to_s.split("_")[1]
    if str
      str = str.downcase
      str = str.to_sym
    end
    str
  end
  #--------------------------------------------------------------------------
  # * Create the sub command window
  #--------------------------------------------------------------------------   
  def setup_command_window
    # Create the sub command window
    commands = MAINMENU_SUB_COMMANDS[@@command_window.command_name]
    # If the sub command window is actors, make a list of actors in the party
    if commands == :actors
      commands = []
      # Fill with party indexes
      $game_party.actors(:all).each do |actor|
        commands << actor.name
      end
    end
    @sub_command_window = Window_Menu.new(@@command_window.x, @@command_window.y + (@@command_window.index + 1) * 32, 240, 200, commands, @@command_window)
    @sub_command_window.z = @@command_window.z + 200
    # Associate windows
    @@command_window.sub_menu = @sub_command_window
    @sub_command_window.help_window = @help_window
    # Update the parent menu's spacing
    @@command_window.refresh(MAINMENU_COMMANDS[@@command_window.index])
    # Set active state
    @@command_window.active = false
    @sub_command_window.active = true
  end
  #--------------------------------------------------------------------------
  # * Clear the sub command window
  #--------------------------------------------------------------------------  
  def clear_command_window
    @sub_command_window = nil
    return if @@command_window&.disposed?
    @@command_window&.sub_menu = nil
    @sub_command_window = nil
    @@command_window&.active = true
    @@command_window&.refresh
  end
  #--------------------------------------------------------------------------
  # * A method for additional scene startup taks
  #--------------------------------------------------------------------------     
  def start
    # Execute transition
    Graphics.transition
  end
  #--------------------------------------------------------------------------
  # * Main Loop
  #--------------------------------------------------------------------------  
  def main_loop
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Check screenshots
      if Input.triggerex?(:F11)
        GameSetup.take_screenshot
      end
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end    
  end
  #--------------------------------------------------------------------------
  # * Update
  #--------------------------------------------------------------------------  
  def update
    @@bg.opacity -= 10 if @@bg.opacity > 125
    #@@bgoverlay.opacity += 5 if @@bgoverlay.opacity < 255
    # Update Windows
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Window)
        ivar.update
      end
    end  
  end
  #--------------------------------------------------------------------------
  # * Exit Scene
  #-------------------------------------------------------------------------- 
  def close_scene
    #@controls_window&.disappear
    $game_system.se_play($data_system.cancel_se)
    #$game_system.bgm_restore if $game_system.memorized_bgm != nil
    $scene = @previous_scene
  end 
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  # windows: existing windows array from another method
  #-------------------------------------------------------------------------- 
  def cleanup(windows = [])
    # Exit if animating windows is disabled
    if $game_options.disable_win_anim
      windows = nil
      return
    end
    # Set all individual windows to move & add them to temp array (For update)
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Window) && !windows.include?(ivar)
        windows << ivar 
        ivar.move(WINDOW_OFFSCREEN_RIGHT, ivar.y, WIN_ANIM_SPEED)
      end
    end
    # Clear command window if we're moving to the map
    if $scene.is_a?(Scene_Map) && @@command_window
      @@command_window.move(WINDOW_OFFSCREEN_LEFT - @@command_window.width, @@command_window.y, WIN_ANIM_SPEED)
      windows << @@command_window
    end
    # Animate windows
    WIN_ANIM_TIME.times do |i|
      Graphics.update
      windows.each do |window|
        window.update
        @@bg.opacity += 2 if $scene.is_a?(Scene_Map)
        if i > WIN_ANIM_TIME / 4
          next if window.is_a?(Window_Menu) && !$scene.is_a?(Scene_Map)
          window.opacity -= (255 / WIN_FADE_SPEED + 1)
          window.contents_opacity -= (255 / WIN_FADE_SPEED + 1) * 2
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    # Prepare for transition
    Graphics.freeze
    # Dispose of windows  
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar.dispose if ivar.is_a?(Window)
    end
    # Dispose of background
    if $scene.is_a?(Scene_Map) || $scene.is_a?(Scene_Gameover)
      #puts "disposed scene bg"
      @@bg.dispose 
      @@command_window.dispose if @@command_window
      #@@bgoverlay.dispose if @@bgoverlay
    end
  end
end