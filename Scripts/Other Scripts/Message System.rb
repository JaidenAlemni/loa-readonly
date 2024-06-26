#==============================================================================
# ** Message System
#
# Created by Jaiden Alemni
# For exclusive use in Legends of Astravia Only
#
#------------------------------------------------------------------------------
# This is a rewrite of Heretic's Multiple Message system, which 
# was originally created by Wachunga in 2006
#
# It offers some of the same functionality with a few extra features (faces)
# and some of the original code cleaned up. It removes the "multiple" message
# window function, which was ultimately a buggy implementation anyway.
# Version history:
# ------------------
# 1.0 March 2021
#   - Initial creation
# 
#==============================================================================

#==============================================================================
# Instructions 
#------------------------------------------------------------------------------
=begin
  Full list of options:

  (Note that all are case *insensitive*.)
  
  =============================================================================
   Local (specified in message itself and resets at message end)
  =============================================================================
  - \L = letter-by-letter mode toggle
  - \A = auto-pause mode toggle for ,.?! characters
  - \S[n] = set speed at which text appears in letter-by-letter mode
  - \D[n] = set delay (in frames) before next text appears
  - \P[n] = position message over event with id n
            * use n=0 for player
            * in battle, use n=a,b,c,d for actors (e.g. \P[a] for first actor)
              and n=1,...,n for enemies (e.g. \P[1] for first enemy)
              where order is actually the reverse of troop order (in database)
  - \P[Cn] = Tie-In with Caterpillar.  Positions Message over Cat Actor
              in n Position of Caterpillar.  1 for First Cat Actor, etc...
            * example: \P[C2] for 2nd Cat Actor, or 3rd Actor in Caterpillar
            * n excludes Player
  - \P = position message over current event (default for floating messages)
  - \^ = message appears directly over its event
  - \v = message appears directly below its event
  - \< = message appears directly to the left of its event
  - \> = message appears directly to the right of its event
  - \$ = message appears above actor unless facing up, then appears below  
  - \% = message appears behind actor relative to direction
  - \B = bold text
  - \I = italic text
  - \C[#xxxxxx] = change to color specified by hexadecimal (eg. ffffff = white)
  - \C = change color back to default
  - \! = message autoclose
  - \? = wait for user input before continuing
  - \@ = thought balloon
  - \N[En] = display name of enemy with id n (note the "E")
  - \N[In] = display name of item with id n (note the "I")
  - \N[Wn] = display name of weapon with id n (note the "W")
  - \N[An] = display name of armor with id n (note the "A")
  - \N[Sn] = display name of skill with id n (note the "S")
  - \I[In] = display icon of item with id n (note the "I")
  - \I[Wn] = display icon of weapon with id n (note the "W")
  - \I[An] = display icon of armor with id n (note the "A")
  - \I[Sn] = display icon of skill with id n (note the "S")
  - \I[En] = display icon of essence with id n (note the "E")
  - \I&N[In] = display icon and name of item with id n (note the "I")
  - \I&N[Wn] = display icon and name of weapon with id n (note the "W")
  - \I&N[An] = display icon and name of armor with id n (note the "A")
  - \I&N[Sn] = display icon and name of skill with id n (note the "S")
  - \MAP = display the name of the current map

  * Foot Forward Notes * - Sprite Sheets only have 16 total Frames of Animation
    and of which, 4 are duplicates.  Foot Forward Options allow access to
    ALL of the frames of animation available in Default Sprite Sheets.
    
  - \F+  = character p their Foot Forward
  - \F*  = character p their Other Foot Forward
  - \F-  = character resets their Foot Forward
  
  *NOTE* - Foot Forward Animation will RESET if the event is moved off screen.
         - Change @auto_ff_reset if this feature causes you trouble with
           character animations.
    
    It also ONLY works with the following conditions
    - Direction Fix is OFF
    - Move Animation is ON
    - Stop Animation is OFF (technically thats Step, they typo'd)
    - @auto_ff_reset is TRUE
    - * These settings are the DEFAULT when a New Event is created
    
    You can disable the "Auto Foot Forward Off" feature by adding \no_ff
    to an Event's Name.  IE: Bill\no_ff
 
  ---- Resets ----
  
  These occur when the player walks away from a Speaking NPC
  
  Put these strings in an Event's Name to use!
           
  \no_ff - If you don't want a specific event to be RESET, you can add
           \no_ff to the Event's Name.  EV041\no_ff and Event will
           not be affected by Foot Forward Reset when Player Walks off screen
           
  \no_mc - No Move Continue - In the event you dont want a specific event to
           continue its Move Route from where it left off when it is moved
           off-screen, put \no_mc in the Event's Name.  I.E. EV12\no_mc    

  These are, of course, in addition to the default options:
  - \V[n]  = display value of variable n
  - \V[Tn] = display value of text variable n
  - \N[n] = display name of actor with id n
  - \C[n] = change color to n
  - \G  = display gold window - Screen Opposite of Player's Position
  - \G+ = display gold window at the Top of the Screen
  - \G- = display gold window at the Bottom of the Screen
  - \\ = show the '\' character
  
  =============================================================================
   Global (specified below or by Call Script and persist until changed)
  =============================================================================
  Miscellaneous:
  - message.move_during = true/false
    * allow/disallow player to move during messages
  - message.show_pause = true/false
    * show/hide "waiting for player" pause graphic
  - message.autocenter = true/false
    * enable/disable automatically centering text within messages
  - message.auto_comma_pause = true/false
    * inserts a delay before the next character after these characters ,!.?
    * expects correct punctuation.  One space after a comma, the rest 2 spaces
  - message.comma_skip_delay = true/false
    * allows skipping delays inserted by commans when Player skips to end of msg
  - message.auto_comma_delay = n
    * changes how long to wait after a pausable character
  - message.auto_ff_reset = true/false
    * resets a Foot Forward stance if a message wnidow is closed for off-screen
    * set to false if it causes animation problems, or, dont use Foot Forward
      on a specific NPC or Event
  - message.auto_move_continue = true/false
    * when moving an event off screen while speaking, resets previous move route
  - message.dist_exit = true/false
    * close messages if the player walks too far away
  - message.dist_max = n
    * the distance away from the player before windows close
  - message.reposition_on_turn = true / false
    * Repeat Turn Toward Player NPC's Reorient Message Windows if they Turn
  - message.sticky
    * If Message was Repositioned, next message will go to that Location
    
  Auto Repositioning Message Windows
  - Cannot be Player
  - NPC MUST have some form of Repeating Turn, usually toward Player
  - NPC MUST NOT MOVE.  Turning is Fine, but cant MOVE
  
  - set_max_dist(n)
    * Useful for allowing player to walk away from signs
    * Saves your MMW Config in case of a Walk-Away Closure
    * call from Event Editor => Scripts
  
  Speech/thought balloon related:
  - message.resize = true/false
    * enable/disable automatic resizing of messages (only as big as necessary)
  - message.floating = true/false
    * enable/disable positioning messages above current event by default
      (i.e. equivalent to including \P in every message)
  - message.location = TOP, BOTTOM, LEFT or RIGHT
    * set default location for floating messages relative to their event
  - message.show_tail = true/false
    * show/hide message tail for speech/thought balloons

  Letter-by-letter related:
  - message.letter_by_letter = true/false
    * enable/disable letter-by-letter mode (globally)
  - message.text_speed = 0-8
    * set speed at which text appears in letter-by-letter mode (globally)
  - message.skippable = true/false
    * allow/disallow player to skip to end of message with button press

  Font:
  - message.font_name = font
    * set font to use for text, overriding all defaults
      (font can be any TrueType from Windows/Fonts folder)
  - message.font_size = size
    * set size of text  (default 18), overriding all defaults
  - message.font_color = color
    * set color of text, overriding all defaults
    * you can use same 0-7 as for \C[n] or "#xxxxxx" for hexadecimal
    
  Set Move Route:
  - foot_forward_on (frame)
    * Optional Parameter - frame
    * foot_forward_on(0) is default, treated as just foot_forward_on
    * foot_forward_on(1) p the "Other" Foot Forward
  - foot_forward_off

  Note that the default thought and shout balloon windowskins don't
  stretch to four lines very well (unfortunately).
=end
#==============================================================================

#==============================================================================
# * Game_Message Class
# This class contains all of the window data, which is as an instance
# of Game_System (@message). This allows easy access from various
# parts of the game, including system options.
#------------------------------------------------------------------------------
class Game_Message
  include MessageSystem
  #------------------------------------------------------------------------------
  # * Public Instance Variables
  #------------------------------------------------------------------------------
  attr_accessor :move_during                # Walk around while speaking
  attr_accessor :letter_by_letter           # Display msg letter by letter
  attr_accessor :text_speed                 # How fast text is displayed
  attr_accessor :skippable                  # Msg can be skipped
  attr_accessor :resize                     # Resizes Message Window
  attr_accessor :floating                   # Messages are Speech Bubbles
  attr_accessor :autocenter                 # Centers Text in Window
  attr_accessor :show_pause                 # Shows Icon to press a button
  attr_accessor :location                   # Relative to Speaker Top Bottom etc
  attr_accessor :font_name                  # Name of Font to be used
  attr_accessor :font_size                  # Size of Font
  attr_accessor :font_color                 # Color of Font
  attr_accessor :speech_windowskin          # Windowskin override
  attr_accessor :auto_comma_pause           # Pauses on these characters ?,.!
  attr_accessor :auto_comma_delay           # How many Frames to Delay
  attr_accessor :comma_skip_delay           # Ignore Auto Comma Pause on Skip
  attr_accessor :auto_ff_reset              # Foot Forward Animation reset
  attr_accessor :auto_move_continue         # Continues Previous Move Route  
  attr_accessor :update_text_while_fading   # Update Text while Fading In
  attr_accessor :dist_exit                  # Auto Close Window if true
  attr_accessor :dist_max                   # Dist Max Player from Speaker
  attr_accessor :allow_offscreen            # Allows Msg Windows Off Screen
  attr_accessor :allow_cancel_numbers       # Allow or deny number inputs
  # Sound Related
  attr_accessor :sound                      # Enables or Disables Text Sounds  
  attr_accessor :sound_audio                # Audio SE (in DB) to play
  attr_accessor :sound_volume               # Text Sound Volume
  attr_accessor :sound_pitch                # Text Sound Pitch
  attr_accessor :sound_pitch_range          # How Much to vary the Pitch
  attr_accessor :sound_vary_pitch           # Whether to Vary the Pitch or not
  attr_accessor :sound_frequency            # Plays a sound this many letters
  #------------------------------------------------------------------------------
  # * Object initialization
  #------------------------------------------------------------------------------
  def initialize
    set_default_values
  end
  #------------------------------------------------------------------------------
  # * Reset to defaults
  #------------------------------------------------------------------------------
  def reset
    set_default_values
  end
  #------------------------------------------------------------------------------
  # * Set Dist Max
  # n: Max distance Player from Speaker (px) before window closes
  #------------------------------------------------------------------------------
  def dist_max=(n)
    n = 1 if n < 1
    @dist_max = n 
  end
  #------------------------------------------------------------------------------
  # * Set default values
  # Resets all values to the defaults set in the configuration module
  #------------------------------------------------------------------------------
  def set_default_values
    @move_during = MOVE_DURING
    @letter_by_letter = LETTER_BY_LETTER              
    @skippable = SKIPPABLE           
    @resize = RESIZE
    @floating = FLOATING
    @autocenter = AUTOCENTER
    @show_pause = SHOW_PAUSE
    @location = DEFAULT_LOCATION
    # Used for overriding
    @font_name = nil
    @font_size = nil
    @font_color = nil
    @speech_windowskin = SPEECH_WINSKIN_FILENAME
    @auto_comma_pause = AUTO_COMMA_PAUSE
    @auto_comma_delay = 0
    @comma_skip_delay = COMMA_SKIP_DELAY
    @auto_ff_reset = AUTO_FF_RESET
    @auto_move_continue = AUTO_MOVE_CONTINUE
    @text_speed = TEXT_SPEED
    @update_text_while_fading = UPDATE_TEXT_FADING
    @dist_exit = DISTANCE_EXIT
    @dist_max = DISTANCE_MAX
    @allow_offscreen = ALLOW_OFFSCREEN
    # Sound Related          
    @sound = ENABLE_SOUND         
    @sound_audio = SOUND_AUDIO
    @sound_volume = SOUND_VOLUME
    @sound_pitch = SOUND_PITCH
    @sound_pitch_range = SOUND_PITCH_RANGE
    @sound_vary_pitch = SOUND_VARY_PITCH
    @sound_frequency = SOUND_FREQUENCY
  end
end
#==============================================================================
# Module for Sentence Parsing
#------------------------------------------------------------------------------
# by Jaiden
#
# This module is responsible for parsing strings and splitting them up
# into syllable chunks. 
#
# The draw text method then uses this to draw it in syllable chunks
# and play a sound for each one.
#==============================================================================
module DialogueParser
  # Vowels array
  VOWELS = ['a','e','i','o','u','A','E','I','O','U']
  #----------------------------------------------------------------------------
  # Takes a string and returns an array of syllables
  # Spaces must be maintained.
  #----------------------------------------------------------------------------
  def self.get_syllables(string)
    # Array of syllables
    syl_array = []
    # The final string is split every x characters
    split_points = [0]
    # Sub out MMW commands
    subbed_str = string.gsub(/-/, ' ')
    subbed_str.gsub!(/\n/, ' ')
    subbed_str.gsub!(/(\.\.\.)/, ' ')
    subbed_str.gsub!(/,\.!\?/, '')
    subbed_str.gsub!(/[^\w\d\s\[\]]/, '')
    subbed_str.gsub!(/(\[[\s\S]{1,9}\])/, '')
    subbed_str.strip
    #p subbed_str
    # Create an array with each word
    words_ary = subbed_str.split
    char_counter = 0
    # Loop through each word
    words_ary.each do |word|
      # Consecutive vowel flag
      repeat_vowel = false
      word_length = 0
      # Loop through each letter
      word.each_char do |char|
        char_counter += 1
        word_length += 1
        # Vowel check
        if VOWELS.include?(char)
          # Was there already a vowel?
          if repeat_vowel
            # Flip
            repeat_vowel = false
          else
            # Flag for syllable / vowel
            split_points << (char_counter - 1) if word_length > 3
            repeat_vowel = true
          end
        elsif repeat_vowel
          # Flip
          repeat_vowel = false
        end
      end
      # Exceptions
      if word.end_with?('es','ed','e') && !word.end_with?('le')
        split_points.pop
      end
      # Account for spaces
      char_counter += 1
      # Split at the word
      split_points << char_counter
    end
    # p split_points
    # p "---"
    prev_num = 0
    # Split the string at each syllable
    split_points.each do |num|
      syl_array << string.slice(prev_num...num)
      prev_num = num
    end
    # p syl_array
    # p "==="
    return split_points
    #return syl_array
  end
end
#==============================================================================
# ** Window_Message
#------------------------------------------------------------------------------
#  This message window is used to display text.
#==============================================================================
class Window_Message < Window_Selectable
  # Include configuration module
  include MessageSystem
  # Access the ID of the speaker
  attr_reader :float_id
  #--------------------------------------------------------------------------
  # * Constants
  #--------------------------------------------------------------------------
  UP = 8
  DOWN = 2
  LEFT = 4
  RIGHT = 6
  DIRECTIONS = [UP, RIGHT, DOWN, LEFT]
  CHARACTERS = [('a'..'z'),('0'..'9')].map{|i| i.to_a}.flatten
  #--------------------------------------------------------------------------
  # * Get choice window index
  #--------------------------------------------------------------------------
  def index
    @choices_window != nil ? @choices_window.index : -1
  end
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super((LOA::SCRES[0] - 480) / 2, LOA::SCRES[1] - (160 + 16), MessageSystem::DEFAULT_WIDTH, MessageSystem::DEFAULT_HEIGHT)
    create_contents
    self.visible = false
    self.z = 9000
    @fade_in = false
    @fade_out = false
    @contents_showing = false
    @cursor_width = 0
    @prompt_sprites = [Sprite.new, Sprite.new]
    @prompt_sprites.each{|s| s.z = self.z + 100}
    self.active = false
    self.index = -1
    # Setup message parameters
    setup_parameters
    # Flag to update text
    @update_text = true
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    terminate_message
    $game_temp.message_window_showing = false
    if @input_number_window != nil
      @input_number_window.dispose
    end
    if @choices_window != nil
      @choices_window.dispose
    end
    @prompt_sprites.each{|s| s.dispose}
    $game_temp.message_face = false
    super
  end
  #--------------------------------------------------------------------------
  # * Terminate Message
  #--------------------------------------------------------------------------
  def terminate_message
    self.active = false
    self.pause = false
    self.index = -1
    self.contents.clear
    # Clear showing flag
    @contents_showing = false
    # Call message callback
    if $game_temp.message_proc != nil
      $game_temp.message_proc.call
    end
    # Battle pause
    if $game_temp.in_battle && @float_id
      # Same idea as above
      $scene.spriteset.actor_sprites.each do |actsp|
        if actsp.battler == $game_party.actors[@float_id]
          actsp.bitmap.play
        end
      end
    end
    # Clear variables related to text, choices, and number input
    @float_id = nil
    $game_temp.message_text = nil
    $game_temp.message_proc = nil
    $game_temp.choice_start = 99
    $game_temp.choice_max = 0
    $game_temp.choice_cancel_type = 0
    $game_temp.choice_proc = nil
    $game_temp.choices_text = nil
    $game_temp.num_input_start = 99
    $game_temp.num_input_variable_id = 0
    $game_temp.num_input_digits_max = 0
    @prompt_sprites.each do |s| 
      s.visible = false
      s.bitmap.dispose if !s.bitmap.nil?
      s.bitmap = nil
    end
    # Open gold window
    if @gold_window != nil
      @gold_window.dispose
      @gold_window = nil
    end
    # Reset text update flag
    @update_text = true
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    @x = @y = 0
    @cursor_width = 0
    @line_widths = nil
    @max_y = 4
    # Setup message parameters (refresh)
    setup_parameters
    # If waiting for a message to be displayed
    if $game_temp.message_text != nil
      # Parse string
      refresh_text
      # Resize window
      resize
      # Draw face
      draw_face
      # Determine window position
      if @float_id != nil
        reposition
      end
      # If there are choices
      if $game_temp.choice_max > 0
        # Create the choice window based on window coordinates
        # Hidden until they appear in update
        setup_choices
      end
      self.contents.font.name = @font_name
      self.contents.font.size = @font_size
      self.contents.font.color = @font_color
      self.windowskin = RPG::Cache.windowskin(@windowskin)
      # autocenter first line if enabled
      # (subsequent lines are done as "\n" is encountered)
      if $game_system.message.autocenter && @text != ""
        # Width of the window - Width of the text / 2
        @x = (self.contents_width - @line_widths[0]) / 2
      end
      # Parse to syllables
      #@text = DialogueParser.get_syllables(@text)
      #@syl_sounds = DialogueParser.get_syllables(@text)
    end
  end
  #--------------------------------------------------------------------------
  # * Parse Text (on Refresh)
  # Determine the various escape sequences for text color, etc.
  # and parse before the string is refreshed
  #--------------------------------------------------------------------------
  def refresh_text
    @text = $game_temp.message_text # now an instance variable
    # Control text processing
    begin
      last_text = @text.clone
      @text.gsub!(/\\[V]\[[T]([0-9]+)\]/) { $game_system.mmw_text[$1.to_i] }        
      @text.gsub!(/\\[Vv]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
    end until @text == last_text
    # Insert a new line
    @text.gsub!(/\\[n]/) { "\n" }
    # Set actor name
    @text.gsub!(/\\[N]\[([0-9]+)\]/) do
      $game_actors[$1.to_i] != nil ? $game_actors[$1.to_i].name : ""
    end
    # Sub quotes
    @text.gsub!(/\'\'/) { "\"" }
    # Change "\\\\" to "\000" for convenience
    @text.gsub!(/\\\\/) { "\000" }
    # Gold Window at TOP
    @text.gsub!(/\\[Gg][\+]/) { "\023" } 
    # Gold Window at Bottom
    @text.gsub!(/\\[Gg][\-]/) { "\024" } 
    # Gold Window Auto, based on Player Loc
    @text.gsub!(/\\[Gg]/) { "\002" }
    # display icon of item, weapon, armor or skill
    @text.gsub!(/\\[Ii]\[([IiWwAaSsEe][0-9]+)\]/) { "\013[#{$1}]" }
    # display a button prompt \B[const]
    @text.gsub!(/\\[Bb]\[([ABCXYZLRPM2468])\]/) { "\026[#{$1}]" }
    # display name of enemy, item, weapon, armor or skill
    @text.gsub!(/\\[Nn]\[([EeIiWwAaSs])([0-9]+)\]/) do
      case $1.downcase
        when "e"
          entity = $data_enemies[$2.to_i]
        when "i"
          entity = $data_items[$2.to_i]
        when "w"
          entity = $data_weapons[$2.to_i]
        when "a"
          entity = $data_armors[$2.to_i]
        when "s"
          entity = $data_skills[$2.to_i]
      end
      entity != nil ? entity.loc_name : ""
    end
    # display icon and name of item, weapon, armor or skill
    @text.gsub!(/\\[Ii]&[Nn]\[([IiWwAaSsEe])([0-9]+)\]/) do
      case $1.downcase
        when "i"
          entity = $data_items[$2.to_i]
        when "w"
          entity = $data_weapons[$2.to_i]
        when "a"
          entity = $data_armors[$2.to_i]
        when "s"
          entity = $data_skills[$2.to_i]
        when "e"
          entity = $data_essences[$2.to_i]
      end
      entity != nil ? "\013[#{$1+$2}] " + entity.loc_name : ""
    end    
    # display name of current map
    @text.gsub!(/\\[Mm][Aa][Pp]/) { $game_map.name }
    # change font color
    @text.gsub!(/\\[Cc]\[([0-9]+|[0-9A-Fa-f]{6,6})\]/) { "\001[#{$1}]" }
    # return to default color
    @text.gsub!(/\\[Cc]/) { "\001" }
    # toggle letter-by-letter mode
    @text.gsub!(/\\[Ll][Ll]/) { "\003" }
    # toggle auto_comma_pause mode
    @text.gsub!(/\\[Aa]/) { "\016" }

    # Face management \DF[actor,emote,right side]
    if @text.gsub!(/\\[Dd][Ff]\[([0-9]+!?),([\w]+),?([Rr])?\]/, "") != nil
      # Get vars
      # If the name flagged to be hidden (! following actor ID)
      @hide_name = $1.end_with?('!')
      $1.chomp('!') if @hide_name
      @actor_id = $1.to_i
      MessageSystem.set_voice(@actor_id)
      # FIXME this is bad
      @sound_pitch = $game_system.message.sound_pitch
      @emotion = $2.to_s.downcase
      if $3 == 'R' || $3 == 'r'
        @face_mirror = true
      else
        @face_mirror = false
      end
      # Set flag
      $game_temp.message_face = true
    else
      # Clear face
      $game_temp.message_face = false
    end

    # trigger Foot Forward Animation
    @text.gsub!(/\\[Ff]\+/) { "\020" }
    # trigger Foot Forward Animation Alter Frame
    @text.gsub!(/\\[Ff]\*/) { "\022" }        
    # trigger Reset Foot Forward Animation
    @text.gsub!(/\\[Ff]\-/) { "\021" }        
    # change text speed (for letter-by-letter)
    @text.gsub!(/\\[Ss]\[([0-9]+)\]/) { "\004[#{$1}]" }
    # insert delay
    @text.gsub!(/\\[Dd]\[([0-9]+)\]/) { "\005[#{$1}]" }
    # insert delays for commas, periods, questions and 
    MessageSystem::PAUSE_CHARS.each_with_index do |c, i|
      # When we sub out escaped characters '\.' in regex, the replacement
      # needs the slash removed. Using a second array with the index is just easier.
      # This sucks, its the only way to deal with the goofy ahh choice logic
      # and also prevent the next character after the delay from being writetn
      @text.gsub!(/#{c}/) { "#{MessageSystem::PAUSE_SUBBED[i]}\015" }
      @auto_comma_delay = AUTO_PUNCT_DELAY[c]
    end
    # self close message
    @text.gsub!(/\\[!]/) { "\006" }
    # wait for button input
    @text.gsub!(/\\[?]/) { "\007" }
    # bold
    @text.gsub!(/\\[Bb]/) { "\010" }
    # italic
    @text.gsub!(/\\[Ii]/) { "\011" }
    # add msg with \*
    @text.gsub!(/\\[*]/) { "\014" }      
    # thought balloon
    if @text.gsub!(/\\[@]/, "") != nil
      @font_color = MessageSystem::THOUGHT_FONT_COLOR
    end
    # Get rid of "\+" (multiple messages)
    #@text.gsub!(/\\[+]/, "")
    # Get rid of "\*" (multiple messages)
    @text.gsub!(/\\[*]/, "")      
    # Get rid of "\\^", "\\v", "\\<", "\\>" (relative message location)
    if @text.gsub!(/\\\^/, "") != nil
      @location = 8
    elsif @text.gsub!(/\\[Vv]/, "") != nil
      @location = 2
    elsif @text.gsub!(/\\[<]/, "") != nil
      @location = 4
    elsif @text.gsub!(/\\[>]/, "") != nil
      @location = 6
    end
    # Get rid of "\\P" (position window to given character)
    if @text.gsub!(/\\[Pp]\[([0-9]+)\]/, "") != nil
      @float_id = $1.to_i
    elsif @text.gsub!(/\\[Pp]\[([a-zA-Z])\]/, "") != nil && $game_temp.in_battle
      @float_id = $1.downcase
    # Tie-In with Caterpillar, use \P[Cn] for a Cat Actor or Follower \P[C1]
    elsif @text.gsub!(/\\[Pp]\[[Cc]([0-9]+)\]/, "") != nil && !$game_temp.in_battle && Interpreter.method_defined?(`get_cat_position_id`)
      # This only works with Heretic's Caterpillar
      if $1.to_i == 0
        @float_id = 0 # Player
      elsif $1.to_i > 0 && $1.to_i <= $game_system.caterpillar.actors.size
        # temporary shortuct to keep on one line
        s = $game_system.map_interpreter
        # Returns the Event ID of the Cat Actor in that position          
        @float_id = s.get_cat_position_id($1.to_i - 1)
      end        
    elsif @text.gsub!(/\\[Pp]/, "") != nil ||
          ($game_system.message.floating && $game_system.message.resize) &&
          !$game_temp.in_battle
      # Just assigns the Event ID of the \P[x] Event
      @float_id = $game_system.map_interpreter.event_id
    end
    # Clear float ID if not floating window
    @float_id = nil if $game_system.message.floating == false && !$game_temp.in_battle
    # Calculate length of lines
    text = @text.clone
    temp_bitmap = Bitmap.new(1,1)
    temp_bitmap.font.name = @font_name
    temp_bitmap.font.size = @font_size
    @line_widths = [0,0,0,0]
    for i in 0..3
      line = text.split(/\n/)[3-i]
      if line == nil
        next
      end
      line.gsub!(/[\001-\007](\[[A-Fa-f0-9]+\])?/, "")          
      line.gsub!(/\013\[[IiWwAaSs][0-9]+\]/, "\013")
      line.gsub!(/\026\[[ABCXYZLRPM2468]\]/, "\026")
      line.chomp.split(//).each do |c|
        # C for Characters in Size of Message Bubble
        case c
        when "\000"
          c = "\\"
        when "\010"
          # bold
          temp_bitmap.font.bold = !temp_bitmap.font.bold
          c = '' # Set character artifacts to a non character
          next
        when "\011"
          # italics
          temp_bitmap.font.italic = !temp_bitmap.font.italic
          c = '' # Set character artifacts to a non character
          next
        when "\013"
          # icon
          @line_widths[3-i] += 28
          next
        when "\026"
          # prompt
          @line_widths[3-i] += 32
          next
        when "\014","\015","\016","\017","\020","\021","\022","\023","\024"
          # Featres Heretic added, causes garbage to appear
          next
        end
        @line_widths[3-i] += temp_bitmap.text_size(c).width
      end
    end
    temp_bitmap.dispose
  end      
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    # Terminate the window if speaker invalid
    if @float_id != nil && $scene.is_a?(Scene_Map)
      char = (@float_id == 0 ? $game_player : $game_map.events[@float_id])
      if char != nil
        # This will call terminate_message if speaker is off screen
        check_close(char)
      end
    end
    # If the window is fading in
    if @fade_in
      self.contents_opacity += 24
      @face&.opacity += 24
      # Stop fading in once we've reached max opacity
      if self.contents_opacity == 255
        @fade_in = false
      end
      # allow text to be updated while window is fading in
      return if !$game_system.message.update_text_while_fading
    end
    # if the window is fading out 

    # If message is being displayed
    if @contents_showing
      # Face sprite update?
      @face&.update
      # Confirm or cancel finishes waiting for input or message
      if Input.trigger?(Input::C) || Input.repeat?(Input::B)
        if @wait_for_input
          @wait_for_input = false
          self.pause = false
        elsif $game_system.message.skippable
          @player_skip = true
        end
        # Dont close the window if waiting for choices to be displayed
        # if $game_temp.message_text != nil && !$input_window_wait
        #   # wait until next input to confirm any choices
        #   $input_window_wait = true
        #   return 
        # else
        #   $input_window_wait = false          
        # end
      end      
      # Message window moved
      if need_reposition?
        reposition # update message position for character/screen movement
        # Record old map coordinates
        $game_map.last_display_x = $game_map.display_x
        $game_map.last_display_y = $game_map.display_y
        if @contents_showing == false
          # i.e. if char moved off screen
          return 
        end
      end
      # Text is updating 
      if @update_text && !@wait_for_input
        if @delay <= 0
          @delay = 0
          update_text
        else
          @delay -= Delta.time
        end
        return
      end
      # If choice isn't being displayed, show pause sign
      if !self.pause && ($game_temp.choice_max == 0 || @wait_for_input)
        self.pause = true unless !$game_system.message.show_pause
      end
      # If a choice is being displayed
      if @choices_window&.active?
        # Fade out the original window contents
        if self.contents_opacity > 165
          self.contents_opacity -= 15
        end
        # Update choices
        @choices_window.update
        # If an input was selected 
        if @choices_window.input_selected?
          # Erase choices window and continue
          @choices_window.dispose
          @choices_window = nil
          terminate_message
        end
      # If a number window is being displayed
      elsif @input_number_window
        @input_number_window.update
        # Confirm
        if Input.trigger?(Input::C)
          # play sound effect
          $game_system.se_play($data_system.decision_se)
          # Set Variable to identify the Number Window was Cancelled
          $game_system.number_cancelled = false        
          # if variable_id was lost, refer to backup
          if $game_temp.num_input_variable_id == 0
            $game_variables[$game_temp.num_input_variable_id_backup] = @input_number_window.number
          else
            $game_variables[$game_temp.num_input_variable_id] = @input_number_window.number
          end
          # Refresh the events
          $game_map.need_refresh = true
          # Dispose of number input window
          @input_number_window.dispose
          @input_number_window = nil  
          terminate_message
        # Cancel, if allowed
        # *NOTE* - use "number_cancelled?" to checks if Cancel Button was pushed
        elsif Input.trigger?(Input::B)
          if $game_system.message.allow_cancel_numbers
            # play cancel sound effect
            $game_system.se_play($data_system.cancel_se)
            # Set Variable to identify the Number Window was Cancelled
            $game_system.number_cancelled = true
            # Dispose of number input window
            @input_number_window.dispose
            @input_number_window = nil        
            terminate_message
          else
            # Cancelling not allowed
            $game_system.se_play($data_system.buzzer_se)
          end
        end
      # Normal message window input
      else
        # Input terminates the message
        if Input.trigger?(Input::C) || Input.repeat?(Input::B)
          terminate_message
        end
      end
      return      
    end
    # If display wait message or choice exists when not fading out
    if @fade_out == false && $game_temp.message_text != nil
      @contents_showing = true
      $game_temp.message_window_showing = true
      reset_window
      refresh
      Graphics.frame_reset
      self.visible = true
      @face&.visible = true
      self.contents_opacity = 0
      @fade_in = true
      return
    end
    # If message which should be displayed is not shown, but window is visible
    if self.visible
      @fade_out = true
      self.opacity -= 96
      @face&.opacity -= 96
      if need_reposition?
        # update message position for character/screen movement        
        reposition 
        # Record old map coordinates
        $game_map.last_display_x = $game_map.display_x
        $game_map.last_display_y = $game_map.display_y
      end
      if self.opacity == 0 
        self.visible = false
        @fade_out = false
        @face&.visible = false
        $game_temp.message_window_showing = false  
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Text Update
  #--------------------------------------------------------------------------
  def update_text
    # If we have a string
    if @text != nil
      
      # Get 1 text character in c (loop until unable to get text)
      while ((c = @text.slice!(/./m)) != nil) 
        # If \\
        if c == "\000"
          # Return to original text
          c = "\\"
        end

        # If \C[n] or \C[#xxxxxx] or \C
        if c == "\001"
          # Change text color
          @text.sub!(/\[([0-9]+|[0-9A-Fa-f]{6,6}|[*])\]/, "")
          if $1 != nil
            self.contents.font.color = check_color($1)
          else
            # return to default color
            if $game_system.message.font_color != nil
              color = check_color($game_system.message.font_color)
            # elsif $game_system.message.floating && $game_system.message.resize
            #   color = check_color(0)
            else
              # use defaults
              color = Font.default_color
            end
            self.contents.font.color = color
          end
          # go to next text
          next
        end
        # If \G+ (Gold Window at the Top)
        if c == "\023"
          # Make gold window
          if @gold_window == nil
            @gold_window = Window_Gold.new
            @gold_window.x = 560 - @gold_window.width
            if $game_temp.in_battle
              @gold_window.y = 192
            else
              @gold_window.y = 32
            end
            @gold_window.opacity = self.opacity
            @gold_window.back_opacity = self.back_opacity
          end
          # Dont take up space in window, next character
          next
        end
        # If \G- (Gold Window at the Bottom)
        if c == "\024"
          # Make gold window
          if @gold_window == nil
            @gold_window = Window_Gold.new
            @gold_window.x = 560 - @gold_window.width
            if $game_temp.in_battle
              @gold_window.y = 192
            else
              @gold_window.y = 384
            end
            @gold_window.opacity = self.opacity
            @gold_window.back_opacity = self.back_opacity
          end
          # Dont take up space in window, next character
          next
        end
        # If \G
        if c == "\002"
          # Make gold window
          if @gold_window == nil
            @gold_window = Window_Gold.new
            @gold_window.x = 560 - @gold_window.width
            if $game_temp.in_battle
              @gold_window.y = 192
            else
              @gold_window.y = self.y >= 128 ? 32 : 384
            end
            @gold_window.opacity = self.opacity
            @gold_window.back_opacity = self.back_opacity
          end
          # go to next text
          next
        end
        # If \L
        if c == "\003"
          # toggle letter-by-letter mode
          @letter_by_letter = !@letter_by_letter
          # go to next text
          next
        end
        # If \S[n]
        if c == "\004"
          @text.sub!(/\[([0-9]+)\]/, "")
          speed = $1.to_i
          if speed >= 0
            @text_speed = speed
            # reset player skip after text speed change
            @player_skip = false            
          end
          return
        end
        # If \D[n]
        if c == "\005"
          @text.sub!(/\[([0-9]+)\]/, "")
          delay = $1.to_i / 10.0
          if delay >= 0
            @delay += delay
            # reset player skip after delay
            @player_skip = false
          end
          return
        end   
        # If \!
        if c == "\006"
          # close message and return from method
          terminate_message
          return
        end
        # If \?
        if c == "\007"
          @wait_for_input = true
          return
        end
        # If \B or \b
        if c == "\010"
          # bold
          self.contents.font.bold = !self.contents.font.bold
          #return - removed, glitches when letter_by_letter is false
          next
        end
        # If \I or \i
        if c == "\011"
          # italics
          self.contents.font.italic = !self.contents.font.italic
          #return - removed, glitches when letter_by_letter is false
          next
        end
        if c == "\013"
          # display icon of item, weapon, armor or skill
          @text.sub!(/\[([IiWwAaSsEe])([0-9]+)\]/, "")
          case $1.downcase
            when "i"
              item = $data_items[$2.to_i]
            when "w"
              item = $data_weapons[$2.to_i]
            when "a"
              item = $data_armors[$2.to_i]
            when "s"
              item = $data_skills[$2.to_i]
            when "e"
              item = $data_essences[$2.to_i]
          end
          if item == nil
            next
          end
          draw_character(item, :icon)
          @x += 22
          #self.contents.draw_text(x + 28, y, 212, 32, item.name)
          next
        end
        # Display a button prompt
        if c == "\026"
          @text.sub!(/\[([ABCXYZLRPM2468])\]/, "")
          button = $1
          next if button.nil?
          draw_character(button, :prompt)
          @x += 32
          next
        end
        # if \* - Display the next message !!!
        if c == "\014"
          # if $scene.is_a?(Scene_Battle)
          #   # Set Variables in the Battle Interpreter to display Next Window
          #   $game_system.battle_interpreter.set_multi
          # elsif $scene.is_a?(Scene_Map)
          #   # Set Variables in the Map Interpreter to display Next Window
          #   $game_system.map_interpreter.set_multi
          # end
          return
        end
        # if ", " or ".  " or "!  " or "?  " characters with spaces
        if c == "\015"
          if @auto_comma_pause && @letter_by_letter == true &&
             (!@player_skip || (@player_skip && !@comma_skip_delay))
            delay = MessageSystem.calc_delay(@text_speed) + @auto_comma_delay
            if delay >= 0
              @delay += delay
              # reset player skip after delay
              @player_skip = false
            end
          end
          # FIXME: We need an early return to ensure the actual punctuation is what 
          # is paused and not the following character. This is a dirty fix
          # and also may cause issues with other things.
          return 
        end
        # if \A (Auto Pause for Commas, Periods, Exclamation and Question Marks)
        if c == "\016"
          # toggle auto comma pause
          @auto_comma_pause = !@auto_comma_pause
          next
        end
        # if \F+ (Foot Forward Animation On)
        if c == "\020" && @float_id
          speaker = (@float_id > 0) ? $game_map.events[@float_id] : $game_player
          speaker.foot_forward_on
          # Dont take up space in window, next character
          next
        end
        # if \F- (Foot Forward Animation Off)  
        if c == "\021" && @float_id
          speaker = (@float_id > 0) ? $game_map.events[@float_id] : $game_player
          speaker.foot_forward_off
          # Dont take up space in window, next character
          next
        end
        # if \F* (Foot Forward Animation On "Other" Foot)
        if c == "\022" && @float_id
          speaker = (@float_id > 0) ? $game_map.events[@float_id] : $game_player
          speaker.foot_forward_on(frame = 1)
          # Dont take up space in window, next character
          next
        end          
        # If new line text !!! WindowCoords
        if c == "\n"
          # We've reached the choices
          if @y >= $game_temp.choice_start
            # Activate the choices window
            activate_choice_win = true
          end
          # Add 1 to y
          @y += 1
          if $game_system.message.autocenter && @text != ""
            @x = (self.contents_width - @line_widths[@y]) / 2
          else
            @x = 0
          end
          # go to next text
          next
        end
        # # Plays Sounds for each Letter, Numbers and Spaces Excluded
        # if @sound && @letter_by_letter && !@player_skip
        #   # Increment for each letter played
        #   if @sound_counter < 1 
        #     play_text_sound(c.downcase)
        #   elsif @sound_counter == @syl_sounds[0]
        #     play_text_sound(c.downcase)
        #     @syl_sounds.delete_at(0)
        #   end
        #   @sound_counter += 1
        # end


        if @sound && @letter_by_letter && !@player_skip && 
          ((Localization.culture != :jp && CHARACTERS.include?(c.downcase)) || Localization.culture == :jp)
          # Increment for each Letter Sound Played
          @sound_counter += 1
          # Prevents Division by Zero, allows 0 to play a sound every letter
          frequency = (@sound_frequency == 0) ? @sound_counter : @sound_frequency
          if Localization.culture == :jp
            frequency /= 2
          end
          # Play Sound for each New Word or if Remainder is 0
          # If the message speed is fast, only play 5 sounds per sentence
          case $game_system.message.text_speed
          when 0
            frequency *= 2
            if (@sound_counter % frequency == 0 || @sound_counter == 1)
              play_text_sound(c.downcase)
            end
          else
            if (@sound_counter % frequency == 0 || @sound_counter == 1)
              # Play correct sound for each letter
              play_text_sound(c.downcase)
            end
          end
        else
          case $game_system.message.text_speed
          when 0
            @sound_counter = 0 if [".","?","!","\n"].include?(c)
          else
            @sound_counter = 0
          end
        end   

        # -------------------------------------------------------------------
        # Draw the text
        draw_character(c)
        # Add x to drawn text width
        @x += self.contents.text_size( c ).width
        # add text speed to time to display next character
        @delay += MessageSystem.calc_delay(@text_speed) unless !@letter_by_letter || @player_skip
        #puts "drawing #{c} with #{@delay}"
        return if @letter_by_letter && !@player_skip
      end
    end
    # If there are choices and we reached the line where choices start
    if @choices_window && activate_choice_win
      @choices_window.active = true
      @choices_window.visible = true
      @choices_window.update_text = true
      @choices_window.index = 0
    # If number input
    elsif $game_temp.num_input_variable_id > 0
      setup_number_input
    end
    # We've gotten through the string
    @update_text = false
  end
  #--------------------------------------------------------------------------
  # * Draw a single character (or item icon)
  #--------------------------------------------------------------------------
  def draw_character(c, type = :text)
    add_face_x = 0      
    # Floating messages are handled a lot differently
    if $game_system.message.floating
      line_h = 28
      add_x = 8
      add_y = 4
    else
      line_h = 34
      add_x = 24
      add_y = 12
    end
    add_x = 0 if $game_system.message.autocenter
    # If the message window is not floating
    if !$game_system.message.floating
      # Offset the face
      if $game_temp.message_face
        add_face_x = (@face_mirror ? 0 : 156)
      end
      # Calculate starting y based on number of lines
      # Centering vertically disabled if choices are displayed
      if $game_temp.choice_max > 0
        add_y = 12
      else
        # total height - num lines  * line_height / 2
        add_y = ((line_h * 4) - (@max_y * line_h)) / 2 + 8
      end
    end
    # Use the formula to draw an icon instead
    case type
    when :icon
      bitmap = RPG::Cache.icon(c.icon_name)
      iy_offset = $game_system.message.floating ? 2 : 4
      self.contents.blt(add_face_x + add_x + @x, add_y + line_h * @y + iy_offset, bitmap, Rect.new(0, 0, 24, 24))
    when :prompt
      path = Input.prompt_graphic_name(c)
      bitmap = RPG::Cache.icon(path)
      active_sprite = 
        if @prompt_sprites[0].bitmap.nil?
          @prompt_sprites[0]
        else
          @prompt_sprites[1]
        end
      active_sprite.bitmap = bitmap
      active_sprite.x = self.x + add_face_x + add_x + @x + self.padding
      active_sprite.y = self.y + add_y + line_h * @y + self.padding
      active_sprite.bitmap.frame_rate = 2
      active_sprite.visible = true
      @prompt_sprites.each{|s| s.bitmap&.stop ; s.bitmap&.play}
      #self.contents.blt(add_face_x + add_x + @x, add_y + line_h * @y, bitmap, Rect.new(0, 0, 32, 32))
    else #text
      self.contents.draw_text(add_face_x + add_x + @x, add_y + line_h * @y, 38, line_h, c)
    end
  end
  #--------------------------------------------------------------------------
  # * Cursor Rectangle Update
  #--------------------------------------------------------------------------
  def update_cursor_rect
    # # If there is an index (choices)
    # if @index >= 0
    #   n = $game_temp.choice_start + @index
    #   if $game_system.message.autocenter
    #     x = 4 + (self.width-40)/2 - @cursor_width/2
    #   else
    #     x = 8
    #   end
    #   self.cursor_rect.set(x, n * 28, @cursor_width, 28)
    # else
    #   self.cursor_rect.empty
    # end
  end
  #--------------------------------------------------------------------------
  # * Text Sound
  #--------------------------------------------------------------------------  
  def play_text_sound(c)
    return if MessageSystem::PUNCTUATION.include?(c)
    # Grab a random sound if it's an array
    if $game_system.message.sound_audio.is_a?(Array)
      sound = $game_system.message.sound_audio.sample
    else
      sound = $game_system.message.sound_audio
    end
    volume = @sound_volume
    if @sound_vary_pitch && @sound_pitch
      # Prevent Negative Numbers...
      sound_pitch_range = (@sound_pitch_range > @sound_pitch) ? @sound_pitch : @sound_pitch_range      
      # If we want to Randomize the Sounds
      # if @sound_vary_pitch
      #   # Random within the Range
      #   pitch = rand(sound_pitch_range * 2) + @sound_pitch - sound_pitch_range
      # Vary Sound Pitch to be based on Letter Sounds
      # Note to Self - Reorganize based on actual Letter Sounds, not so Random
      if ['l','m','n','q','u','w','2'].include?(c)
        pitch = @sound_pitch - sound_pitch_range
      elsif ['a','f','h','j','k','o','r','x','1','4','7','8'].include?(c)
        pitch = @sound_pitch - sound_pitch_range / 2
      elsif ['b','c','d','e','g','p','t','v','z','0','3','6'].to_a.include?(c)
        pitch = @sound_pitch
      elsif ['s','7'].to_a.include?(c)
        pitch = @sound_pitch + sound_pitch_range / 2
      elsif ['i','y','5','9'].to_a.include?(c)
        pitch = @sound_pitch + sound_pitch_range
      else
        pitch = rand(@sound_pitch_range * 2) + @sound_pitch
      end
    else
      pitch = (@sound_pitch && @sound_pitch.is_a?(Numeric)) ? @sound_pitch : 100
    end
    # Play the Sound
    $game_system.se_play(RPG::AudioFile.new(sound, volume, pitch))
  end
  #--------------------------------------------------------------------------
  # * On Screen? 
  # x,y - Alternative coordinates to check against
  #--------------------------------------------------------------------------
  def on_screen?(x = self.x, y = self.y)
    return self.height + y < LOA::SCRES[1] && y > 0 &&
           self.width + x < LOA::SCRES[0] && x > 0
  end
  #--------------------------------------------------------------------------
  # * Repositioning Determination
  #--------------------------------------------------------------------------
  def need_reposition?
    # If not in battle, the window is floating, resizing is enabled, and the float id is valid
    if !$game_temp.in_battle && $game_system.message.floating &&
        $game_system.message.resize && @float_id != nil
      if $game_system.message.move_during && $game_player.moving?
          # player with floating message moved
          # (note that relying on moving? leads to "jumpy" message boxes)
          return true
      elsif ($game_map.last_display_y != $game_map.display_y) || ($game_map.last_display_x != $game_map.display_x)
        # player movement or scroll event caused the screen to scroll
        return true
      else
        char = $game_map.events[@float_id]
        if char != nil && ((char.last_real_x != char.real_x) || (char.last_real_y != char.real_y))
          # character moved
          return true
        end
      end    
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Setup window choices
  #--------------------------------------------------------------------------
  def setup_choices
    # Choices should always use the speech fonts
    f_name = :speech
    f_size = 90
    # If the message window is floating
    # Choices window will be smaller?
    if $game_system.message.floating
      cw_x = self.x + self.padding * 2
      cw_y = self.y + line_height * 2
      # This line looks a little crazy, but the window size is halved if there are 3+ choices
      half_size = ($game_temp.choice_max < 3 ? 2 : 1)
      cw_w = (self.width - (MessageSystem::CHOICE_INDENT * 2)) / half_size
      # Center window if there are < 3 choices
      if $game_temp.choice_max < 3
        cw_x += self.width / 4 - self.padding
      end
      cw_h = (self.height / 2) + self.padding * 2
      @choices_window = Window_Choices.new(cw_x,cw_y,cw_w,cw_h,$game_temp.choices_text)
      @choices_window.set_font(f_name, f_size, @font_color)
      @choices_window.align = ALIGN_CENTER
      @choices_window.refresh
      @choices_window.z = self.z + 500
    # Displays like a speech system
    else
      # Face offset
      face_offset = (@face.nil? ? 0 : @face.width)
      cw_x = self.x + face_offset + self.padding + MessageSystem::CHOICE_INDENT
      cw_y = self.y + line_height * 2.5
      # This line looks a little crazy, but the window size is halved if there are 3+ choices
      half_size = ($game_temp.choice_max < 3 ? 2 : 1)
      cw_w = (self.width - (CHOICE_INDENT * 2) - face_offset) / half_size
      cw_h = (self.height / 2) + self.padding * 2
      @choices_window = Window_Choices.new(cw_x,cw_y,cw_w,cw_h,$game_temp.choices_text)
      @choices_window.set_font(f_name, f_size, @font_color)
      @choices_window.align = ALIGN_LEFT
      @choices_window.refresh
      @choices_window.z = self.z + 500
    end
  end
  #--------------------------------------------------------------------------
  # * Setup number input
  #--------------------------------------------------------------------------
  def setup_number_input
    # If the message window is floating
    # Choices window will be smaller?
    if $game_system.message.floating

    # Displays like a speech system
    else
      # Face offset
      face_offset = (@face.nil? ? 0 : @face.width)
      iw_x = self.x + face_offset
      iw_y = self.y + ($game_temp.num_input_start * line_height)
      @input_number_window = Window_InputNumber.new($game_temp.num_input_digits_max)
      @input_number_window.set_font(Font.name_key, @font_size * 100 / Font.default_size, @font_color)
      @input_number_window.number = $game_variables[$game_temp.num_input_variable_id]
      @input_number_window.x = iw_x
      @input_number_window.y = iw_y
      @input_number_window.z = self.z + 500
    end
  end
  #--------------------------------------------------------------------------
  # * Setup window parameters
  #--------------------------------------------------------------------------
  def setup_parameters
    # Avoid constantly calling for this variable :)
    m_settings = $game_system.message
    # Setup Windowskin
    if m_settings.floating
      @windowskin = FLOATING_WINSKIN_FILENAME
      @font_name = Font.numbers_name
      @font_size = Font.default_size
    else
      @windowskin = m_settings.speech_windowskin
      @font_name = Font.speech_name
      @font_size = Font.default_size
    end
    @font_color = TEXT_FONT_COLOR
    # Font overrides
    if m_settings.font_name != nil
      @font_name = m_settings.font_name
    end
    if m_settings.font_color != nil
      @font_color = m_settings.font_color
    end
    if m_settings.font_size != nil
      @font_size = m_settings.font_size
    end
    @letter_by_letter = m_settings.letter_by_letter
    @text_speed = m_settings.text_speed
    @float_id = nil
    @location = m_settings.location
    @auto_comma_pause = m_settings.auto_comma_pause
    @auto_comma_delay = 0
    @comma_skip_delay = m_settings.comma_skip_delay   
    @allow_cancel_numbers = m_settings.allow_cancel_numbers
    @update_text_while_fading = m_settings.update_text_while_fading     
    @auto_ff_reset = m_settings.auto_ff_reset
    @auto_move_continue = m_settings.auto_move_continue
    @dist_exit = m_settings.dist_exit
    @dist_max = m_settings.dist_max
    @auto_orient = false
    @delay = MessageSystem.calc_delay(@text_speed)
    @player_skip = false
    # Sound related
    if m_settings.sound
      # Don't play sounds for floating message windows
      @sound = !m_settings.floating
    else
      @sound = false
    end
    @sound_audio = m_settings.sound_audio
    @sound_volume = SOUND_VOLUME
    @sound_pitch = m_settings.sound_pitch
    @sound_pitch_range = m_settings.sound_pitch_range
    @sound_vary_pitch = m_settings.sound_vary_pitch
    @sound_frequency = m_settings.sound_frequency
    @sound_counter = 0
    @word_counter = 0
  end
  #--------------------------------------------------------------------------
  # * Draw Message Face (And Name)
  #--------------------------------------------------------------------------
  def draw_face
    # If the message should have a face graphic
    if $game_temp.message_face
      # Set parameters if it already exists
      if @face
        @face.actor = @actor_id
        @face.emotion = @emotion
        # @face.mirror = @face_mirror
        # if @face_mirror
        #   @face.x = self.x + self.width - @face.width - 12
        # else
        #   @face.x = self.x + 12
        # end
      # Recreate face object 
      else
        @face = Game_Face.new(@actor_id, @emotion)
      end
      @face.x = self.x + 12
      @face.y = self.y + 12
      @face.z = self.z + 200
      # Setup name
      name = (@hide_name ? "??????" : MessageSystem.setup_name(@actor_id))
      @face.set_name(name, @face_mirror)
    # Clear it
    else
      @face&.erase
      @face = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Resize window
  #--------------------------------------------------------------------------
  def resize
    # If the window is floating above characters
    if $game_system.message.floating
      max_x = @line_widths.max
      @max_y = 4
      @line_widths.each do |line|
        @max_y -= 1 if line == 0 && @max_y > 1
      end
      bottom_padding = 0
      # Determine the width based on the largest choice
      if $game_temp.choice_max > 0
        bottom_padding = 12
        # Gather up widths of choice strings
        choice_widths = Array.new($game_temp.choice_max)
        $game_temp.choices_text.each_with_index do |choice, i|
          temp_bitmap = Bitmap.new(1,1)
          choice_widths[i] = temp_bitmap.text_size(choice).width
        end
        # Four choices -- wider
        if $game_temp.choice_max > 2
          # If the two largest widths are greater than the current line width
          if choice_widths.max(2).sum > max_x
            max_x = choice_widths.max(2).sum
          end
        # Two choices, only need to check 1 width
        else
          if choice_widths.max > max_x 
            max_x = choice_widths.max
          end
        end
        # Always have 4 lines
        @max_y = 4
      end
      new_width = max_x + 64
      self.width = new_width
      self.height = @max_y * 28 + 32 + bottom_padding
    # Window is not floating, displays like a text system
    else
      # Fixed width, but adjust height based on number of lines
      # Adjust for face
      self.width = DEFAULT_WIDTH
      self.width += 140 if $game_temp.message_face
      self.width += 74 if $game_options.font_style == :pixel && Localization.culture == :en_us
      @max_y = 4
      # Max_y based on # of lines if no face or choices to display
      if $game_temp.choice_max == 0 || !$game_temp.message_face
        @line_widths.each do |line|
          @max_y -= 1 if line == 0 && @max_y > 1
        end
      end
      # Adjust the height of the window
      if $game_system.message.resize
        self.height = @max_y * 32 + 52
      else
        self.height = DEFAULT_HEIGHT
      end
      self.x = (LOA::SCRES[0] - self.width) / 2 # center
      # Set window position
      y_offset = 16 # offset from top/bottom of screen
      self.y =
      case $game_system.message_position # (0 top, 1 middle, 2 bottom)
      when 0; y_offset
      when 1; (LOA::SCRES[1]/2) - (self.height / 2)
      when 2; LOA::SCRES[1] - (self.height + y_offset)
      end
    end
    # Create window contents
    create_contents
  end
  #--------------------------------------------------------------------------
  # * Reposition window
  #--------------------------------------------------------------------------
  def reposition
    # If we're not on the map or in battle...
    if !$scene.is_a?(Scene_Map) && !$scene.is_a?(Scene_Battle)
      self.x = DEFAULT_X
      self.y = DEFAULT_Y
      return
    end
    # If we're in battle, message window is fixed to the 
    # bottom of the screen, regardless of floating.
    if $game_temp.in_battle
      sprite = nil
      # Might put the sprite that displays (...) next to the battler
      # So worth still keeping track of them
      # Heretic used abcd for party members and numbers for troops
      # Totally should be the opposite. Weirdo
      if @float_id.is_a?(String)
        # Check enemy.letter here
        $game_troop.enemies.each do enemy
          # Enemy is valid
          if enemy.letter == @float_id
            # Find the sprite (this is gross)
            # Should just flag the battler instead and 
            # Manage from the scene itself
            $scene.spriteset.enemy_sprites.each do |ensp|
              if ensp.battler == enemy
                sprite = ensp
              end
            end
          end
        end
      elsif @float_id != nil
        # Same idea as above
        $scene.spriteset.actor_sprites.each do |actsp|
          if actsp.battler == $game_party.actors[@float_id]
            sprite = actsp
            actsp.bitmap.stop
          end
        end
      end
      # Set x and y
      if sprite != nil && !sprite.disposed?
        char_height = sprite.height
        char_width = sprite.width
        char_x = sprite.x
        char_y = sprite.y - char_height/2
      end
      return
    # We're on the map
    else
      # Set char
      char = (@float_id == 0 ? $game_player : $game_map.events[@float_id])
      if char == nil
        # no such character
        @float_id = nil
        return 
      end
      # Compatibility for pixel movement / camera
      char_height = RPG::Cache.character(char.character_name,0).height / char.direction_order.length
      char_width  = RPG::Cache.character(char.character_name,0).width  / 4
      char_x = Camera.calc_zoomed_x(char.screen_x)
      char_y = Camera.calc_zoomed_y(char.screen_y)
    end
    params = [char_height, char_width, char_x, char_y]
    # position window and message tail
    x, y = new_position(params)
    # Screen boundaries (left, up, right, down)
    hh = self.height / 2
    hw = self.width / 2
    screen_bounds = {left:16, top:hh, right:LOA::SCRES[0] - 16, bottom:LOA::SCRES[1] - hh}
    # adjust windows if near edge of screen
    if !$game_system.message.allow_offscreen || $game_temp.in_battle
      if x < screen_bounds[:left]
        x = screen_bounds[:left]
      elsif x > screen_bounds[:right]
        x = screen_bounds[:right]
      end
      if y < screen_bounds[:top]
        y = screen_bounds[:top]
      elsif y > screen_bounds[:bottom]
        y = screen_bounds[:bottom]
      # elsif $game_temp.in_battle && @location == 2 && (y > (320 - self.height))
      #   # when in battle, prevent enemy messages from overlapping battle status
      #   # (note that it could still happen from actor messages, though)
      #   y = 320 - self.height
      end
    end
    # finalize positions
    self.x = x
    self.y = y
  end
  #--------------------------------------------------------------------------
  # * Check close
  # Check if the window should be closed. True if:
  # - Character walks off screen
  # - Dist exit is enabled and character walks outside of the range
  # - The message is not allowed off-screen and it goes off screen
  #--------------------------------------------------------------------------
  def check_close(char)
    # Initialize result
    close = false
    # Did the speaker walk off screen?
    if !char.on_screen? 
      close = true
    end
    # if @dist_exit && char.allow_flip && @float_id > 0 && !char.within_range?(@dist_max, @float_id)
    if @dist_exit && char.is_a?(Game_Event) && !char.within_range?(@dist_max, $game_player)
      close = true
    end
    # # Is the window off screen?
    # if !$game_system.message.allow_offscreen && !self.on_screen?
    #   close = true
    # end
    # Evaluate message termination
    if close
      # Moved Off Screen or out of range so close Window
      terminate_message
      # 115 Breaks Event Processing
      $game_system.map_interpreter.command_115
      # reset foot forward on speak stance
      if @auto_ff_reset && !char.no_ff
        char.foot_forward_off 
      end
      # reset 'M'ove 'C'ontinue
      if @auto_move_continue && !char.no_mc
        char.event_move_continue(@float_id, true) 
      end
      # Instanced for this Msg Window, prevents calling Resets multiple times
      @auto_ff_reset = false
      # Turn off the Triggered Flag
      # char.allow_flip = false
      # char.preferred_loc = nil
      # Load the Default Sound Settings because Player walked away
      #$game_system.message.load_sound_settings
    end
    # Return result
    return close
  end
  #--------------------------------------------------------------------------
  # * Need Flip? - Prevent Player from walking under Message Bubbles
  # event_id - ID of event to check against (0 is player)
  # loc - Location of bubble (top, left, right, bottom)
  # x, y - Window position
  # params - Character position
  #--------------------------------------------------------------------------
  # def need_flip?(event_id, loc, x, y, params = nil)
  #   return false if !@auto_orient ||
  #                   @fade_out ||
  #                   event_id.nil? || 
  #                   (event_id != 0 &&
  #                   $game_map.events[event_id].erased) ||
  #                   $game_temp.in_battle ||
  #                   !$game_system.message.reposition_on_turn ||
  #                   !$game_system.message.move_during
  #   # vars for speaker
  #   event = (event_id > 0) ? $game_map.events[event_id] : $game_player
  #   dir = event.direction
  #   # if an argument is passed called params and not allowed offscreen   
  #   if params && !$game_system.message.allow_offscreen
  #     # Flip the location
  #     new_loc = DIRECTIONS[(DIRECTIONS.index(loc) + 2) % 4]
  #     # check what the new coordinates of a repositioned window will be  
  #     new_x, new_y = new_position(params, new_loc)
  #     # return false if not allowed off screen and new position is off screen
  #     if !on_screen?(new_x, new_y) 
  #       return false 
  #     end
  #   end
  #   # default result
  #   result = false
  #   # if the window is allowed to auto orient
  #   if @auto_orient
  #     if event.is_a?(Game_Event)
  #       # If Auto Orient Any Direction, try to put preference on top / bottom
  #       # Top / Bottom Preference was made for readability of Msgs
  #       # because it is easier to go off screen left and right
  #       if dir == loc ||
  #          ((dir == 2 || dir == 8) && (loc == 4 || loc == 6))
  #         result = true
  #       end
  #     elsif event.is_a?(Game_Player) && $game_player.allow_flip
  #       # if Game Player Message is Sticky
  #       if $game_player.sticky &&
  #          ((dir == 2 && loc != 8) ||
  #          (dir == 8 && loc != 2) ||
  #          (
  #            (!$game_player.preferred_loc) &&
  #            ((dir == 4 && loc != 6) || (dir == 6 && loc != 4))
  #           )
  #          )
  #         # Return that Message needs to be Flipped
  #         result = true
  #       # If Game Player Non Sticky Message not behind Player   
  #       elsif !$game_player.sticky &&
  #          ((dir == 2 && loc != 8) ||
  #          (dir == 4 && loc != 6) ||
  #          (dir == 6 && loc != 4) ||
  #          (dir == 8 && loc != 2))
  #         # Return that Message needs to be Flipped
  #         result = true
  #       end
  #     end
  #   end
  #   return result
  # end  
  #--------------------------------------------------------------------------
  # * Determine New Window Position
  # Takes in an array of coordinates and the window location and returns the position
  #--------------------------------------------------------------------------  
  def new_position(params, location = @location)
    char_height = params[0] *= Camera.zoom
    char_width = params[1] *= Camera.zoom
    char_x = params[2]
    char_y = params[3]
    half_width = self.width / 2
    half_height = self.height / 2
    offset = 12
    case location
    when UP
      x = char_x - half_width
      y = char_y - char_height - self.height
    when DOWN
      # bottom
      x = char_x - half_width
      y = char_y + char_height
    when LEFT
      x = char_x - half_width - self.width
      y = char_y - half_height
    when RIGHT
      x = char_x + half_width
      y = char_y - half_height
    end
    return [x,y]
  end
  #--------------------------------------------------------------------------
  # * Reset window to default values
  #--------------------------------------------------------------------------
  def reset_window
    case $game_system.message_position
    when 0  # up
      self.y = 16
    when 1  # middle
      self.y = (LOA::SCRES[1] - self.height) / 2
    when 2  # down
      self.y = LOA::SCRES[1] - (self.height + 28)
    end
    if $game_system.message_frame == 0
      self.opacity = 255
    else
      self.opacity = 0
    end
    # transparent speech balloons don't look right, so keep opacity at 255
    self.back_opacity = 
      if $game_temp.in_battle
        255
      else
        ($game_system.message.floating ? FLOATING_WIN_OPACITY : SPEECH_WIN_OPACITY)
      end
  end
end
#=============================================================================
# Custom Handling for premature window closing when making a choice selection
# Credit: KK20
#=============================================================================
class Game_Temp
  attr_accessor :after_choices_dir_input
  
  alias init_choices_dir_input initialize
  def initialize
    @after_choices_dir_input = 0
    init_choices_dir_input
  end
end

class Window_Message < Window_Selectable
  alias get_last_dir4_after_choices terminate_message
  def terminate_message
    if $game_temp.choice_max > 0
      $game_temp.after_choices_dir_input = Input.dir4
    end
    get_last_dir4_after_choices
  end
end

# class Game_Map
#   #--------------------------------------------------------------------------
#   # * Display X/Y Set
#   #--------------------------------------------------------------------------
#   alias map_display_x_after display_x
#   def display_x=(n)
#     @last_display_x = @display_x
#     map_display_x_after=(n)
#   end
#   #--------------------------------------------------------------------------
#   alias map_display_y_after display_y
#   def display_y=(n)
#     @last_display_y = @display_y
#     map_display_y_after=(n)
#   end
# end

# class Game_Player
#   alias check_if_dir4_changed_after_choices update
#   def update
#     if $game_temp.after_choices_dir_input > 0
#       if $game_temp.after_choices_dir_input == Input.dir4
#         return wachunga_mmw_game_player_update
#       else
#         $game_temp.after_choices_dir_input = 0
#       end
#     end
#     check_if_dir4_changed_after_choices
#   end
# end

#==============================================================================
# ** Window_Choices
#------------------------------------------------------------------------------
#  Specialized window for drawing and selecting choices
#  Is drawn invisible on top of the message window
#==============================================================================
class Window_Choices < Window_Selectable
  attr_accessor :input_selected # Flags whether an input has been chosen
  attr_accessor :update_text    # Flag to update text
  attr_accessor :align          # Choices alignment
  DRAW_DELAY = 6
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     z : window z value
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height, choices)
    super(x, y, width, height)
    @item_max = $game_temp.choice_max
    @choices = choices
    # Use integer division, 2 choices 1 column, 3 choices 2 columns, etc.
    @column_max = ($game_temp.choice_max + 1) / 2 
    @index = -1
    # Initialize cursor offset values
    @cursor_start_x = 0
    @cursor_start_y = 0
    @new_index = 0
    @spacing = 8
    @align = ALIGN_LEFT
    self.visible = false
    self.active = false
    self.input_selected = false
    self.window_blank = true
    self.update_text = false
    self.contents_opacity = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # * Check if player made a choice
  #--------------------------------------------------------------------------
  def input_selected?
    return @input_selected
  end
  #--------------------------------------------------------------------------
  # * Refresh window (and draw choices)
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    self.contents.font.color = GOLD_COLOR
    @choices.each_with_index do |choice, i|
      rect = item_rect_for_text(i)
      rect.x += 8
      rect.width -= 12
      self.contents.draw_text(item_rect_for_text(i), choice, @align)
    end
  end
  #--------------------------------------------------------------------------
  # * Draw choices in a delayed fashion
  #--------------------------------------------------------------------------
  def update_text
    i = 0
    # while i < ($game_temp.choice_max * DRAW_DELAY)
    #   if i % DRAW_DELAY == 0
    #     self.contents.draw_text(item_rect_for_text(i/DRAW_DELAY), @choices[i/DRAW_DELAY])
    #   end
    #   self.contents_opacity += (255 / DRAW_DELAY)
    #   Graphics.update
    #   i += 1
    # end
    while i < DRAW_DELAY
      self.contents_opacity += (255 / DRAW_DELAY)
      Graphics.update
      i += 1
    end
    @update_text = false
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update
    super
    # If we haven't finished drawing the text
    if @update_text
      update_text
    else
      # Cancel
      if Input.trigger?(Input::B)
        if $game_temp.choice_cancel_type > 0
          # Play Sound Effect
          $game_system.se_play($data_system.cancel_se)
          # Process the Choice
          $game_temp.choice_proc.call($game_temp.choice_cancel_type - 1)
          # Hide the window and make it inactive
          self.active = false
          self.visible = false
          self.input_selected = true
        else
          $game_system.se_play($data_system.buzzer_se)
        end
      # Confirm
      elsif Input.trigger?(Input::C)
        # Choose current choice        
        $game_system.se_play($data_system.decision_se)
        $game_temp.choice_proc.call(@index)
        self.active = false
        self.visible = false
        self.input_selected = true
      end
    end
  end
end