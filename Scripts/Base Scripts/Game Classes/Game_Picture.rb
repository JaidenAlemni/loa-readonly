#==============================================================================
# ** Game_Picture
#------------------------------------------------------------------------------
#  This class handles the picture. It's used within the Game_Screen class
#  ($game_screen).
#==============================================================================

class Game_Picture
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :number                   # picture number
  attr_accessor :name                    # file name
  attr_reader   :origin                   # starting point
  attr_reader   :x                        # x-coordinate
  attr_reader   :y                        # y-coordinate
  attr_reader   :zoom_x                   # x directional zoom rate
  attr_reader   :zoom_y                   # y directional zoom rate
  attr_reader   :opacity                  # opacity level
  attr_accessor :blend_type               # blend method
  attr_reader   :tone                     # color tone
  attr_reader   :angle                    # rotation angle
  attr_reader   :mirror  # Mirrors the sprite 
  attr_accessor :color
  attr_accessor :char_id     # ID of the actor that holds the picture sprite (for busts)
  attr_accessor :emotion_id  # ID of the currently displayed emotion
  attr_accessor :bust_active # Flag to determine if a bust is active (and should have its eyes animated)
  EXPONENT = 2 # easing exponent constant
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     number : picture number
  #--------------------------------------------------------------------------
  def initialize(number)
    @number = number
    @name = ""
    @origin = 0
    @x = 0
    @y = 0
    @zoom_x = 100.0
    @zoom_y = 100.0
    @opacity = 255
    @blend_type = 1
    # Initialize target information
    init_target
    @tone = Tone.new(0, 0, 0, 0)
    @tone_target = Tone.new(0, 0, 0, 0)
    @tone_duration = 0
    @angle = 0
    @rotate_speed = 0
    # Additional functions
    @mirror = false
    @color = Color.new()
    @color_target = Color.new()
    @color_duration = 0
    @char_id = 0
    @emotion_id = 0
    @bust_active = false
  end
  #--------------------------------------------------------------------------
  # * Reset target information
  #--------------------------------------------------------------------------
  def init_target
    @target_x = @x
    @target_y = @y
    @target_zoom_x = @zoom_x
    @target_zoom_y = @zoom_y
    @target_opacity = @opacity
    @duration = 0
    @whole_duration = 0
    @ease_type = :ease_out #:linear :ease_in :ease_out
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
  def show(name, origin, x, y, zoom_x, zoom_y, opacity, blend_type, mirror = false)
    @name = name
    @origin = origin
    @x = x.to_f
    @y = y.to_f
    @zoom_x = zoom_x.to_f
    @zoom_y = zoom_y.to_f
    @opacity = opacity.to_f
    @blend_type = blend_type
    init_target
    @tone = Tone.new(0, 0, 0, 0)
    @tone_target = Tone.new(0, 0, 0, 0)
    @tone_duration = 0
    @angle = 0
    @rotate_speed = 0
    @mirror = mirror
  end
  #--------------------------------------------------------------------------
  # * Move Picture
  #     duration   : time
  #     origin     : starting point
  #     x          : x-coordinate
  #     y          : y-coordinate
  #     zoom_x     : x directional zoom rate
  #     zoom_y     : y directional zoom rate
  #     opacity    : opacity level
  #     blend_type : blend method
  #--------------------------------------------------------------------------
  def move(duration, origin, x, y, zoom_x, zoom_y, opacity, blend_type, ease = @ease_type, mirror = false)
    @origin = origin
    @target_x = x.to_f
    @target_y = y.to_f
    @target_zoom_x = zoom_x.to_f
    @target_zoom_y = zoom_y.to_f
    @target_opacity = opacity.to_f
    @blend_type = blend_type
    @duration = duration
    @whole_duration = duration
    @ease_type = ease
    @mirror = mirror
  end
  #--------------------------------------------------------------------------
  # * Change Rotation Speed
  #     speed : rotation speed
  #--------------------------------------------------------------------------
  def rotate(speed)
    @rotate_speed = speed
  end
  #--------------------------------------------------------------------------
  # * Start Change of Color Tone
  #     tone     : color tone
  #     duration : time
  #--------------------------------------------------------------------------
  def start_tone_change(tone, duration)
    @tone_target = tone.clone
    @tone_duration = duration
    if @tone_duration == 0
      @tone = @tone_target.clone
    end
  end
  #--------------------------------------------------------------------------
  # * Start Color Change
  #     color    : color
  #     duration : time
  #--------------------------------------------------------------------------
  def start_color_change(color, duration)
    @color_target = color.clone
    @color_duration = duration
    if @color_duration == 0
      @color = @color_target.clone
    end
  end
  #--------------------------------------------------------------------------
  # * Erase Picture
  #--------------------------------------------------------------------------
  def erase
    @name = ""
  end
  #--------------------------------------------------------------------------
  # * Update movement
  #--------------------------------------------------------------------------
  def update_move
    if @duration > 0
      @x = apply_easing(@x, @target_x)
      @y = apply_easing(@y, @target_y)
      @zoom_x = apply_easing(@zoom_x, @target_zoom_x)
      @zoom_y = apply_easing(@zoom_y, @target_zoom_y)
      @opacity = apply_easing(@opacity, @target_opacity)
      @duration -= 1
    end
  end
  #--------------------------------------------------------------------------
  # ** Easing functions (courtesy of RMMZ)
  #--------------------------------------------------------------------------
  # * Apply easing
  #--------------------------------------------------------------------------
  def apply_easing(current, target)
    d = @duration.to_f
    wd = @whole_duration.to_f
    lt = calc_easing((wd - d) / wd).to_f
    t = calc_easing((wd - d + 1) / wd).to_f
    start = (current - target * lt) / (1 - lt)
    return start + (target - start) * t
  end
  #--------------------------------------------------------------------------
  # * Calculate easing
  #--------------------------------------------------------------------------
  def calc_easing(t)
    self.send(@ease_type, t, EXPONENT)
  end
  #--------------------------------------------------------------------------
  # * Linear
  #--------------------------------------------------------------------------
  def linear(t, _exp)
    return t
  end
  #--------------------------------------------------------------------------
  # * Ease in (slow -> fast)
  #--------------------------------------------------------------------------
  def ease_in(t, exp)
    return t ** exp
  end
  #--------------------------------------------------------------------------
  # * Ease out (fast -> slow)
  #--------------------------------------------------------------------------
  def ease_out(t, exp)
    return 1 - ((1 - t) ** exp)
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    update_move
    if @tone_duration >= 1
      d = @tone_duration
      @tone.red = (@tone.red * (d - 1) + @tone_target.red) / d
      @tone.green = (@tone.green * (d - 1) + @tone_target.green) / d
      @tone.blue = (@tone.blue * (d - 1) + @tone_target.blue) / d
      @tone.gray = (@tone.gray * (d - 1) + @tone_target.gray) / d
      @tone_duration -= 1
    end
    if @rotate_speed != 0
      @angle += @rotate_speed / 2.0
      while @angle < 0
        @angle += 360
      end
      @angle %= 360
    end
    if @color_duration >= 1
      d = @color_duration
      @color.red = (@color.red * (d - 1) + @color_target.red) / d
      @color.green = (@color.green * (d - 1) + @color_target.green) / d
      @color.blue = (@color.blue * (d - 1) + @color_target.blue) / d
      @color.alpha = (@color.alpha * (d - 1) + @color_target.alpha) / d
      @color_duration -= 1
    end
  end
end
