#==============================================================================
# ** Scene_Cutscene
# Specialized scene for displaying picture-based cutscenes
#==============================================================================
class Scene_Cutscene
  attr_reader :pictures    # Game_Picture array
  attr_reader :texts       # Array of text sprites
  attr_reader :planes      # Array of plane sprites
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(scene_list)
    # Get the command list array from the Cutscene module
    @commands = Cutscene.command_list(scene_list)
    # Set a variable for the scene type
    @cutscene_name = scene_list
    # Reset the index
    @command_index = 0
    @wait = 0
    @wait_for_input = false
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------   
  def main 
    # Scene start (prepare for loop)
    start
    # Scene loop
    main_loop
    # Scene exit
    terminate
  end
  #--------------------------------------------------------------------------
  # * A method for additional scene startup taks
  #--------------------------------------------------------------------------     
  def start
    # Set screen tone
    $game_screen.start_tone_change(Tone.new(-255,-255,-255), 30)
    # Wait
    i = 0
    while i < 60
      Graphics.update
      $game_screen.update
      i += 1
    end
    # Create pictures
    @pictures = [nil]
    50.times do |i|
      @pictures.push(Game_Picture.new(i + 1))
    end
    # Create plane parameters
    @planes = []
    # Create texts array for text management, each index is a position
    # 0 - screen center
    # 1, 2, 3 - bottom lines
    @texts = []
    # Create spriteset
    @spriteset = Spriteset_Cutscene.new
    # Setup font
    Font.default_shadow = false
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
      # Frame update
      if Input.triggerex?(:F11)
        GameSetup.take_screenshot
      end
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end    
  end
  #--------------------------------------------------------------------------
  # * Show Picture
  #     name       : file name
  #     origin     : starting point
  #     x          : x-coordinate
  #     y          : y-coordinate
  #     zoom_x     : x directional zoom rate
  #     zoom_y     : y directional zoom rate
  #     opacity    : opacity level
  #     blend_type : blend method
  #--------------------------------------------------------------------------
  def show_picture
    # Get parameters (sym is unused--setting for ease)
    _sym, number, filename, origin, x, y, zoom_x, zoom_y, opacity, blend_type = @action
    # Do the thing
    # Load from cutscene folder
    filename = "Cutscene/" + filename
    @pictures[number].show(filename, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
  end
  #--------------------------------------------------------------------------
  # * Move Picture
  #     duration   : time (passed in seconds, so we need to convert to frames)
  #     origin     : starting point
  #     x          : x-coordinate
  #     y          : y-coordinate
  #     zoom_x     : x directional zoom rate
  #     zoom_y     : y directional zoom rate
  #     opacity    : opacity level
  #     blend_type : blend method
  #--------------------------------------------------------------------------
  def move_picture
    # Get parameters (sym is unused--setting for ease)
    _sym, number, dur, origin, x, y, zoom_x, zoom_y, opacity, blend_type, ease_type = @action
    # Do the thing
    @pictures[number].move((dur * Delta::OFFSET).round, origin, x, y, zoom_x, zoom_y, opacity, blend_type, ease_type)
  end
  #--------------------------------------------------------------------------
  # * Make the specified plane visible
  #--------------------------------------------------------------------------
  def show_plane
    pos = @action[1]
    parameters = Cutscene.plane_data(@cutscene_name)[pos]
    @planes[pos].bitmap = RPG::Cache.picture("Cutscene/" + parameters[0])
    @planes[pos].blend_type = parameters[1]
    @planes[pos].z = parameters[4]
    @planes[pos].visible = true
  end
  #--------------------------------------------------------------------------
  # * Move picture plane
  #--------------------------------------------------------------------------
  def hide_plane
    @planes[@action[1]].visible = false
  end
  #--------------------------------------------------------------------------
  # * Change border
  #--------------------------------------------------------------------------
  def change_border
    @spriteset.change_border(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Start Screenshake
  #--------------------------------------------------------------------------
  def shake_screen
    dur = @action[1]
    power = @action[2]
    $game_temp.shake_maxdur = (dur * Delta::OFFSET).round
    $game_temp.shake_dur = (dur * Delta::OFFSET).round
    $game_temp.shake_power = power
  end
  #--------------------------------------------------------------------------
  # * Change Screen Tone
  # duration - in seconds, needs to be converted to frames
  #--------------------------------------------------------------------------
  def change_screen_tone
    # Tone, Duration
    dur = @action[2]
    $game_screen.start_tone_change(@action[1], (dur * Delta::OFFSET).round)
  end
  #--------------------------------------------------------------------------
  # * Flash Screen
  # duration - in frames
  #--------------------------------------------------------------------------
  def flash_screen
    # Color, Duration
    dur = @action[2]
    $game_screen.start_flash(@action[1], dur)
  end
  #--------------------------------------------------------------------------
  # * Special lightning effect with sound
  # duration - in frames
  #--------------------------------------------------------------------------
  def thunder
    dur = @action[1] 
    # Flash
    $game_screen.start_flash(Color.new(255,200,255,100), dur)
    # Play Sound
    volume = (100 - rand(20))
    pitch = (80 + rand(50))
    $game_system.se_play(RPG::AudioFile.new(Cutscene::THUNDER_SE, volume, pitch))
  end
  #--------------------------------------------------------------------------
  # * Play sound effect
  #--------------------------------------------------------------------------
  def play_se
    $game_system.se_play(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Play Music
  #--------------------------------------------------------------------------
  def play_bgm
    $game_system.bgm_play(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Play BGS
  #--------------------------------------------------------------------------
  def play_bgs
    $game_system.bgs_play(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Fade out music
  #--------------------------------------------------------------------------
  def fade_bgm
    $game_system.bgm_fade(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Fade out bgs
  #--------------------------------------------------------------------------
  def fade_bgs
    $game_system.bgs_fade(@action[1])
  end
  #--------------------------------------------------------------------------
  # * Assign and display text at position
  #--------------------------------------------------------------------------
  def show_text
    position = @action[1]
    @texts[position].draw(@action[2], 1, 100, Font.cutscene_name, Cutscene::FONT_COLOR, false)
    @texts[position].display = true
  end
  #--------------------------------------------------------------------------
  # * Hide text at position
  #--------------------------------------------------------------------------
  def hide_text
    @texts[@action[1]].display = false
  end
  #--------------------------------------------------------------------------
  # * Wait
  #-------------------------------------------------------------------------- 
  def wait
    @wait = @action[1]
  end
  #--------------------------------------------------------------------------
  # * Wait for input
  #-------------------------------------------------------------------------- 
  def input_wait
    @wait_for_input = true
    @spriteset.show_wait_sprite = true
  end
  #--------------------------------------------------------------------------
  # * End the scene
  #--------------------------------------------------------------------------  
  def end_scene
    # Go to next scene
    $scene = Scene_Map.new
    # Change screen color back
    $game_screen.start_tone_change(Tone.new(), 60)
    # Clear command list and action
    @action = nil
    @commands = nil
    @cutscene_name = ""
  end
  #--------------------------------------------------------------------------
  # * Parse the command
  #--------------------------------------------------------------------------  
  def parse_command
    # Call the command symbol (first index in the returned array)
    @action = @commands[@command_index]
    self.send(@action[0])
    # Advance the main index
    @command_index += 1
  end
  #--------------------------------------------------------------------------
  # * Update special plane image ox/oy
  #--------------------------------------------------------------------------
  def update_scrolling
    # Don't bother if we don't have any planes to update
    return if Cutscene.plane_data(@cutscene_name).empty?
    # Update each plane
    @planes.each_with_index do |plane, index|
      # Get the parameters for the plane from the cutscene module
      name, _blend, scroll_x, scroll_y = Cutscene.plane_data(@cutscene_name)[index]
      # Skip if the name doesn't exist
      next if name == ""
      # Update
      plane.ox += scroll_x
      plane.oy += scroll_y
    end
  end
  #--------------------------------------------------------------------------
  # * Update
  #--------------------------------------------------------------------------  
  def update
    # Debug exit
    if Input.trigger?(MenuConfig::MENU_INPUT[:Back]) && $DEBUG
      @action[1] = 1
      fade_bgm
      end_scene
      return
    end
    # Update pictures
    for i in 1..50
      @pictures[i].update
    end
    # Update game screen
    $game_screen.update
    # Update plane scrolling
    update_scrolling
    # Update spriteset
    @spriteset.update
    # Wait
    if @wait > 0
      @wait -= Delta.time
      @wait = 0 if @wait < 0
      return
    end
    # If we're waiting for player input
    if @wait_for_input
      # Wait until the player does something to proceed
      if Input.trigger?(MenuConfig::MENU_INPUT[:Confirm]) || Input.trigger?(MenuConfig::MENU_INPUT[:Back])
        @wait_for_input = false
        @spriteset.show_wait_sprite = false
      end
      return
    end
    # Call the next command
    parse_command
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    # Prepare for transition
    Graphics.freeze
    # Dispose
    @spriteset.dispose
    # Reset font
    Font.default_shadow = true
  end
end