#==============================================================================
# ** Game_Options
#------------------------------------------------------------------------------
# This class handles system settings stored by the player, such as
# game volume, battle speed, etc. 
#
# On game startup, it checks for existance. If it does not exist, the data
# is initialized. Otherwise, it is loaded.
#
# It is only saved to a file when the player exits the options menu. 
#==============================================================================
class Game_Options
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battle_speed
  attr_accessor :battle_list_wait
  attr_accessor :battle_hardmode
  attr_accessor :message_text_speed 
  attr_accessor :message_text_sound
  attr_accessor :disable_win_anim
  attr_accessor :disable_battle_camera
  attr_accessor :bgm_master_vol  # store bgm volume
  attr_accessor :bgs_master_vol  # store sfx volume
  attr_accessor :se_master_vol   # store se volume
  attr_accessor :language
  attr_accessor :kb_override     # forces kb prompts even with a controller connected
  attr_accessor :fullscreen
  attr_accessor :disable_screen_shake
  attr_accessor :disable_screen_flash
  attr_accessor :view_controls  # Doesn't actually change anything
  attr_accessor :battle_defend_toggle # Toggle or Hold (now "Hold") makes sense
  attr_accessor :feedback_form
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @battle_speed = ATB::DEFAULT_SPEED
    @battle_list_wait = ATB::LIST_WAIT
    @battle_hardmode = ATB::HARDMODE
    @message_text_speed = 0
    @message_text_sound = true
    @disable_win_anim = false
    @bgm_master_vol = 60 * Audio::MAX_VOL_STEPS / 100
    @bgs_master_vol = 50 * Audio::MAX_VOL_STEPS / 100
    @se_master_vol = 60 * Audio::MAX_VOL_STEPS / 100
    @language = Localization.initial_culture
    @kb_override = false
    @fullscreen = false
    @disable_screen_shake = false
    @disable_screen_flash = false
    @disable_battle_camera = false
    @view_controls = nil
    @feedback_form = nil
    @scaling = 0
    @battle_defend_toggle = false
    @font_style = :default
  end
  #--------------------------------------------------------------------------
  # * Options as they are arranged in the menu
  #--------------------------------------------------------------------------
  def menu_arrangement(submenu)
    case submenu
    when :system
      [:bgm_master_vol, :bgs_master_vol, :se_master_vol, :message_text_speed, :message_text_sound, :language, :font_style]
    when :display
      [:fullscreen, :scaling, :vsync, :disable_win_anim, :disable_battle_camera, :disable_screen_flash, :disable_screen_shake]
    when :gameplay
      [:battle_speed, :battle_list_wait, :battle_defend_toggle, :kb_override, :view_controls, :feedback_form]
    end
  end
  #--------------------------------------------------------------------------
  # * Possible options for each option
  #--------------------------------------------------------------------------
  def options(sym)
    case sym
    when :bgm_master_vol # Audio is handled a little differently
      :bgm_volume
    when :bgs_master_vol
      :bgs_volume
    when :se_master_vol
      :se_volume
    when :battle_speed
      ATB::BATTLE_SPEEDS.dup
    when :message_text_speed
      [50,0,-50]
    when :language
      [:en_us, :jp]
    when :scaling
      [0,1,2]
    when :font_style
      [:default, :pixel]
    # Reverse logic
    when :disable_win_anim, :disable_screen_flash, :disable_screen_shake, :disable_battle_camera
      [false, true]
    when :view_controls
      :view_controls
    when :feedback_form
      :feedback_form
    else # All others true/false toggle
      [true, false]
    end
  end
  #--------------------------------------------------------------------------
  # * mkxp json options
  #--------------------------------------------------------------------------
  def scaling=(n)
    case n
    when 0 # Pixel Perfect
      CFG["smoothScaling"] = false
      Graphics.smooth_scaling = false
      CFG["integerScalingActive"] = true
      Graphics.integer_scaling = true
    when 1 # Smooth
      CFG["smoothScaling"] = true
      Graphics.smooth_scaling = true
      CFG["integerScalingActive"] = false
      Graphics.integer_scaling = false
    when 2 # Sharp
      CFG["smoothScaling"] = false
      Graphics.smooth_scaling = false
      CFG["integerScalingActive"] = false
      Graphics.integer_scaling = false
    end
    @scaling = n
  end
  def vsync
    CFG["vsync"] ||= false
    CFG["vsync"]
  end
  def vsync=(bool)
    CFG["vsync"] = bool
  end
  #--------------------------------------------------------------------------
  # * Compatibility with existing files
  #--------------------------------------------------------------------------
  def battle_speed
    @battle_speed = ATB::DEFAULT_SPEED if ATB::BATTLE_SPEEDS.index(@battle_speed).nil?
    @battle_speed
  end
  #--------------------------------------------------------------------------
  def battle_speed=(n)
    if ATB::BATTLE_SPEEDS.index(n).nil?
      puts "Invalid battle speed #{n}"
      @battle_speed = ATB::DEFAULT_SPEED
    else
      @battle_speed = n
    end
  end
  #--------------------------------------------------------------------------
  def battle_defend_toggle
    @battle_defend_toggle ||= false
    @battle_defend_toggle
  end
  #--------------------------------------------------------------------------
  def language
    @language ||= :en_us
    @language
  end
  #--------------------------------------------------------------------------
  def fullscreen=(bool)
    @fullscreen = bool
    Graphics.fullscreen = bool
  end
  #--------------------------------------------------------------------------
  def scaling 
    @scaling ||= 0
  end
  def bgm_master_vol
    @bgm_master_vol.clamp(0, Audio::MAX_VOL_STEPS)
  end 
  def bgs_master_vol
    @bgs_master_vol.clamp(0, Audio::MAX_VOL_STEPS)
  end  
  def se_master_vol
    @se_master_vol.clamp(0, Audio::MAX_VOL_STEPS)
  end 
  #--------------------------------------------------------------------------
  def font_style 
    @font_style ||= :default
    @font_style
  end
  #--------------------------------------------------------------------------
  def font_style=(value)
    Font.default_name = Font::NAMES.dig(Localization.culture, value, :default)
    @font_style = value
  end

end