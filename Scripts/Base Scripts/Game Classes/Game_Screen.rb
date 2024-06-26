#==============================================================================
# ** Game_Screen
#------------------------------------------------------------------------------
#  This class handles screen maintenance data, such as change in color tone,
#  flashing, etc. Refer to "$game_screen" for the instance of this class.
#==============================================================================

class Game_Screen
  NO_TONE = Tone.new(0, 0, 0, 0)
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :tone                     # color tone
  attr_accessor :previous_tone            # memorize color tone
  attr_reader   :flash_color              # flash color
  attr_reader   :shake                    # shake positioning
  attr_reader   :pictures                 # pictures
  attr_reader   :weather_type             # weather type
  attr_reader   :weather_max              # max number of weather sprites
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @tone = Tone.new(0, 0, 0, 0)
    @tone_target = Tone.new(0, 0, 0, 0)
    # For memorizing changes
    @previous_tone = Tone.new(0, 0, 0, 0)
    @tone_duration = 0
    @flash_color = Color.new(0, 0, 0, 0)
    @flash_duration = 0
    @shake_power = 0
    @shake_speed = 0
    @shake_duration = 0
    @shake_direction = 1
    @shake = 0
    @pictures = [nil]
    for i in 1..100
      @pictures.push(Game_Picture.new(i))
    end
    @weather_type = 0
    @weather_max = 0.0
    @weather_type_target = 0
    @weather_max_target = 0.0
    @weather_duration = 0
    # Heretcs Lightning
    @lightning_duration = 0
    @lightning = 0
  end
  #--------------------------------------------------------------------------
  # * Start Changing Color Tone
  #     tone : color tone
  #     duration : time
  #--------------------------------------------------------------------------
  def start_tone_change(tone, duration)
    @tone_target = tone.clone
    @tone_duration = duration
    if @tone_duration == 0
      @tone = @tone_target.clone
    end
    # Clear any Lightning Flashes - Half of fixing Color Tone Screw Ups
    @lightning_duration = 0
    @lightning = 0
    @last_tone = nil
  end
  #--------------------------------------------------------------------------
  # * Start Flashing
  #     color : color
  #     duration : time
  #--------------------------------------------------------------------------
  def start_flash(color, duration)
    return if $game_options.disable_screen_flash
    @flash_color = color.clone
    @flash_duration = duration
  end
  #--------------------------------------------------------------------------
  # * Start Shaking
  #     power : strength
  #     speed : speed
  #     duration : time
  #--------------------------------------------------------------------------
  def start_shake(power, speed, duration)
    @shake_power = power
    @shake_speed = speed
    @shake_duration = duration
  end
  #--------------------------------------------------------------------------
  # * Set Weather (updated to account for higher res)
  #     type : type
  #     power : strength
  #     duration : time
  #--------------------------------------------------------------------------
  def weather(type, power, duration)
    @weather_type_target = type
    if @weather_type_target != 0
      @weather_type = @weather_type_target
    end
    if @weather_type_target == 0
      @weather_max_target = 0.0
    else
      num = LOA::SCRES[0] * LOA::SCRES[1] / 76800.0
      @weather_max_target = (power + 1) * num
    end
    @weather_duration = duration
    if @weather_duration == 0
      @weather_type = @weather_type_target
      @weather_max = @weather_max_target
    end
  end
  #--------------------------------------------------------------------------
  # * Lightning
  #     duration : time in Frames
  #--------------------------------------------------------------------------
  def lightning(duration=30)
    # If there is no Current Lightning Flash
    if @lightning_duration == 0 or @last_tone.nil?
      # Store Last Tone
      @last_tone = @tone_target.clone
    end
    # Set up Lightning Animation Values (+6 is offset for First Flash)
    @lightning_duration = duration * 2 + 6
    @lightning = duration * 2
  end
  #--------------------------------------------------------------------------
  # * Heretic's Lightning Update
  #--------------------------------------------------------------------------
  def lightning_update
    if $game_options.disable_screen_flash
      @lightning_duration -= 1
      return
    end
    # If Lightning
    if @lightning_duration > 0
      # First Flash - Fully Grayed Out - Tone(R,G,B, Grayscale)
      if @lightning_duration == @lightning
        # Change Tone to Lightning Flash Tone
        @tone = Tone.new(34, 34, 51, 255)
      # End First Flash - Return to Last Color Tone
      elsif @lightning_duration == @lightning - 2
        # Set Tone to Last Tone
        @tone = @last_tone
      # Second Flash - Slightly Grayed Out - Tone(R,G,B, Grayscale)
      elsif @lightning_duration == @lightning - 6
        # Change Tone to Lightning Flash Tone
        @tone = Tone.new(34, 34, 51, 224)       
      # Lightning Flash Fade - Fade from Flash to Tone Target
      # This is half of what fixes Color Tone Screw Ups
      elsif @lightning_duration < @lightning - 6
        d = @lightning_duration
        @tone.red = (@tone.red * (d - 1) + @tone_target.red) / d
        @tone.green = (@tone.green * (d - 1) + @tone_target.green) / d
        @tone.blue = (@tone.blue * (d - 1) + @tone_target.blue) / d
        @tone.gray = (@tone.gray * (d - 1) + @tone_target.gray) / d
      end
      # Countdown
      @lightning_duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    if @tone_duration >= 1
      d = @tone_duration
      @tone.red = (@tone.red * (d - 1) + @tone_target.red) / d
      @tone.green = (@tone.green * (d - 1) + @tone_target.green) / d
      @tone.blue = (@tone.blue * (d - 1) + @tone_target.blue) / d
      @tone.gray = (@tone.gray * (d - 1) + @tone_target.gray) / d
      @tone_duration -= 1
    end
    if @flash_duration >= 1
      d = @flash_duration
      @flash_color.alpha = @flash_color.alpha * (d - 1) / d
      @flash_duration -= 1
    end
    if @shake_duration >= 1 or @shake != 0
      unless $game_options.disable_screen_shake
        delta = (@shake_power * @shake_speed * @shake_direction) / 10.0
        if @shake_duration <= 1 and @shake * (@shake + delta) < 0
          @shake = 0
        else
          @shake += delta
        end
        if @shake > @shake_power * 2
          @shake_direction = -1
        end
        if @shake < - @shake_power * 2
          @shake_direction = 1
        end
      end
      if @shake_duration >= 1
        @shake_duration -= 1
      end
    end
    if @weather_duration >= 1
      d = @weather_duration
      @weather_max = (@weather_max * (d - 1) + @weather_max_target) / d
      @weather_duration -= 1
      if @weather_duration == 0
        @weather_type = @weather_type_target
      end
    end
    if $game_temp.in_battle
      for i in 51..100
        @pictures[i].update
      end
    else
      for i in 1..50
        @pictures[i].update
      end
    end
    lightning_update
  end
end
