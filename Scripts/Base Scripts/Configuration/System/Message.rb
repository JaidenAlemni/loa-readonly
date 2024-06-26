#==============================================================================
# Message System Configuration and Settings
#==============================================================================
# * Message Module
# This module contains all of the necessary configuration settings and default
# settings for messages. 
#------------------------------------------------------------------------------
module MessageSystem
  # Used for sound calc
  PUNCTUATION = ['.','...','?',',','？','…','。','、']
  PAUSE_CHARS =  ['\. ', '\? ', ', ', '？', '…', '。', '、', '! ']
  PAUSE_SUBBED = ['. ', '? ', ', ', '？', '…', '。', '、', '! ']
  # Seconds to delay on pause, depending on the punctuation type
  AUTO_PUNCT_DELAY = {
    '. ' => 0.2, 
    '? ' => 0.2, 
    ', ' => 0.03, 
    '？' => 0.2, 
    '…' => 0.3, 
    '。' => 0.2, 
    '、' => 0.03, 
    '! ' => 0.2
  } 
  # Various substitution patterns used when parsing text
  # SUB_PATTERNS = {
  #   text_variable: /\\[V]\[[T]([0-9]+)\]/,
  #   variable: /\\[Vv]\[([0-9]+)\]/,
  #   newline: /\\[n]/,

  # }
  # Delay (in milliseconds) to draw each character
  TEXT_SPEEDS = [
    0, # Will be used to skip through entirely
    0, # 1
    5, # 2
    12, # 3 (Default)
    24, # 4 
    36, # 5
    64, # 6
    96, # 7
    158, # 8
    256  # 9
  ] 
  #------------------------------------------------------------------------------
  # Window and default font configuration
  #------------------------------------------------------------------------------
  SPEECH_WINSKIN_FILENAME = "Speech"
  FLOATING_WINSKIN_FILENAME = "Floating"
  TEXT_FONT_COLOR = Color.new(255,255,255)
  # For speech (bottom weighted windows)
  #SPEECH_FONT_NAME = "Merriweather Sans"
  #SPEECH_FONT_SIZE = 26
  # For floating (small windows above characters)
  FLOATING_FONT_SIZE = 24
  # Additional modifications for "thoughts" (a variation on floating windows)
  THOUGHT_FONT_COLOR = Color.new(200,200,200)
  THOUGHT_FONT_ITALIC = true
  # Window opacity defaults
  FLOATING_WIN_OPACITY = 220
  SPEECH_WIN_OPACITY = 240
  # Window size defaults
  DEFAULT_WIDTH = 640
  DEFAULT_HEIGHT = 180
  DEFAULT_X = (LOA::SCRES[0] - DEFAULT_WIDTH) / 2
  DEFAULT_Y = LOA::SCRES[1] - (DEFAULT_HEIGHT + 140)
  # Constant for choices indentation
  CHOICE_INDENT = 24
  #------------------------------------------------------------------------------
  # Default message configuration settings
  #------------------------------------------------------------------------------
  # Show one letter at a time \L
  LETTER_BY_LETTER = true
  # Default text speed \S[n]  
  TEXT_SPEED = 3
  # Can messages be skipped to the end?            
  SKIPPABLE = true
  # Messages are automatically resized based on message length?
  RESIZE = true               
  # Windows are floating above the player? \P[n]
  FLOATING = true           
  # Text is centered automatically?
  AUTOCENTER = true           
  # Display waiting for input graphic
  SHOW_PAUSE = true           
  # Allow player movement while message is displayed
  MOVE_DURING = false       
  # Default location for floating window (8: top)
  DEFAULT_LOCATION = 8        
  # Pause on ,.?! \A
  AUTO_COMMA_PAUSE = true      
  # Skip ,.?! when skipping through messages
  COMMA_SKIP_DELAY = true    
  # Display text letter by letter even when fading in
  UPDATE_TEXT_FADING = true   
  # Reset foot-foreward stance on auto-close
  AUTO_FF_RESET = true        
  # Continue move route when speaking event goes off screen
  AUTO_MOVE_CONTINUE = true   
  # Close window if distance from speaker is too great
  DISTANCE_EXIT = true     
  # Distance player can walk (in pixels) before closing
  DISTANCE_MAX = 256          
  # Allow messsages to float off screen instead of flipping
  ALLOW_OFFSCREEN = false                   
  # Enable text sounds in letter-by-letter
  ENABLE_SOUND = true      
  # Default SFX
  SOUND_AUDIO = 'MUI_TextMid'  
  # Sound volume
  SOUND_VOLUME = 90          
  # Pitch variation
  SOUND_PITCH = 90            
  # Randomly vary pitch 
  SOUND_VARY_PITCH = true     
  # Factor in which pitch is randomly varied
  SOUND_PITCH_RANGE = 5       
  # Frequency (letters) a sound is played
  SOUND_FREQUENCY = 4
  #----------------------------------------------------------------------------
  # * Emotions
  # Returns a string for the specified ID
  #----------------------------------------------------------------------------
  # def self.emotion(id)
  #   case id
  #   when 0;  'Default'
  #   when 1;  'Smile'
  #   when 2;  'Focused'
  #   when 3;  'Troubled'
  #   when 4;  'Angry'
  #   when 5;  'Sad'
  #   when 6;  'Sigh'
  #   when 7;  'Relief'
  #   when 8;  'Shock'
  #   when 9;  'Pain'
  #   # Uncategorized emotions / vary per character
  #   when 10; 'Misc_1'
  #   when 11; 'Misc_2'
  #   when 12; 'Misc_3'
  #   else
  #     return 'Default'
  #   end
  # end
  #----------------------------------------------------------------------------
  # * Setup Name
  # Determine if a name should be an actor name, NPC name from the table below,
  # or a custom name inserted directly into the text.
  #----------------------------------------------------------------------------
  def self.setup_name(id)
    # Normal actor
    if id < 1000
      name = $game_actors[id].name
    # NPC
    else
      name = $data_npcs[id - 1000].loc_name
    end
    name
  end
  #----------------------------------------------------------------------------
  # * Set voice
  # Sets the sound and pitch of text noises for the speaking character
  #----------------------------------------------------------------------------
  def self.set_voice(actor_id)
    # TODO Just load the SE normally
    if actor_id > 1000
      data_actor = $data_npcs[actor_id-1000]
    else
      data_actor = $data_actors[actor_id]
    end
    $game_system.message.sound_audio = data_actor.text_se.name
    $game_system.message.sound_pitch = data_actor.text_se.pitch
  end
  #----------------------------------------------------------------------------
  # * Calculate message delay
  # Converts range (1-9) to a 0.XXX second delay
  #----------------------------------------------------------------------------
  def self.calc_delay(text_speed)
    spd = TEXT_SPEEDS[text_speed]
    spd = 0 if spd.nil?
    # Further modulated by options (+/- 50)
    spd += spd * $game_options.message_text_speed / 100
    spd / 1000.0
  end
end

class Game_Message
  #------------------------------------------------------------------------------
  # * Load pre-set settings for certain event types
  #------------------------------------------------------------------------------
  def setup(sym)
    # Reset defaults first before overriding
    @font_color = nil
    @font_name = nil
    @move_during = false
    @resize = false
    @floating = false
    @font_name = Font.speech_name
    @font_size = Font.default_size
    @letter_by_letter = true
    @sound = false
    case sym
    when :cutscene
      @sound = $game_options.message_text_sound
      @autocenter = false
      @floating = false
    when :npc
      #@move_during = true
      @autocenter = true
      @floating = true
      @resize = true
    when :pickup
      @font_name = Font.numbers_name
      size = Localization.culture == :en_us ? 115 : 100
      @font_size = Font.scale_size(size)
      @letter_by_letter = false
      @autocenter = true
      @floating = true
      @resize = true
    when :explore
      @font_name = Font.numbers_name
      size = Localization.culture == :en_us ? 115 : 100
      @font_size = Font.scale_size(size)
      @letter_by_letter = true
      @autocenter = true
      @floating = true
      @resize = true
      #@move_during = true
    when :sign
      @autocenter = true
      @font_color = Color.new(210,210,210)
    when :chest
      @autocenter = false
    when :intro
      @autocenter = true
      @font_name = Font.default_name
      @font_size = Font.default_size
    when :memory
      @autocenter = true
      #@sound = $game_options.message_text_sound
      @font_name = Font.default_name
      @font_size = Font.default_size
      @font_color = Color.new(220,225,240)
    when :info
      @autocenter = false
    end
  end
end