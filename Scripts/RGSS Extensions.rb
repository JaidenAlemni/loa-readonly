# Slightly out of order from RMXP Help file; Audio/Graphics/Input modules come first
#===============================================================================
# ** Audio
#===============================================================================
module Audio
  # Switch ID to disable decreasing the game volume when entering a house
  DISABLE_INDOOR_SWITCH = 14
  # Level (as a percentage) to decrease the volume when going indoors.
  # The default value is 20%
  INDOOR_LEVEL_DECREASE = 20
  # Volume index
  MAX_VOL_STEPS = 20

  def self.calc_volume(index)
    ((index / (MAX_VOL_STEPS / 10.0)) ** 2).clamp(0, 100).floor
  end

  # Indexes
  def self.bgm_volume
    $game_options.bgm_master_vol
  end

  def self.bgs_volume
    $game_options.bgs_master_vol
  end

  def self.se_volume
    $game_options.se_master_vol
  end

  def self.bgm_volume=(value)
    $game_options.bgm_master_vol = value
    # Set new BGM if playing
    if $game_system.playing_bgm != nil
      $game_system.bgm_play($game_system.playing_bgm)
    end  
  end
  
  def self.bgs_volume=(value)
    # Set the master BGS volume 
    $game_options.bgs_master_vol = value
    # Set new BGS if playing
    if $game_system.playing_bgs != nil
      $game_system.bgs_play($game_system.playing_bgs)
    end  
  end

  def self.se_volume=(value)
    # Set the master SE volume 
    $game_options.se_master_vol = value
  end
end
#===============================================================================
# ** Graphics
# Methods relevant to camera are in Camera Class Extensions
#===============================================================================
module Graphics
  # This is a fancy pants way of aliasing a module method
  module_function
  class << Graphics
    unless method_defined?(:update_delta_time)
      alias update_delta_time update
    end
  end
  def update
    # update system time
    if $game_system
      $game_system.gameplay_time += Delta.time
    end
    # Run original method
    update_delta_time
  end
end
#===============================================================================
# ** Input
#===============================================================================
module Input
  # Virtual key codes assigned to constants
  # Requires the ex? functions i.e. Input.triggerex?()
  BACKSPACE = 0x08
  ENTER = 0x0D
  SPACE = 0x20
  PGUP = 0x21
  PGDOWN = 0x22
  K_END = 0x23
  HOME = 0x24
  INS = 0x2D
  DEL = 0x2E
  NUM_MINUS = 0x6D
  NUM_PLUS = 0x6B
  F10 = 0x79
  F11 = 0x7A
  KB_START = 0x0D
  PAD_START = 0x0010
  # Classic XP mapping
  XP_TO_KEYS = {
    2 => DOWN, 4 => LEFT, 6 => RIGHT, 8 => UP, 
    11 => A, 12 => B, 13 => C, 14 => X, 15 => Y, 16 => Z, 17 => L, 18 => R,
    21 => SHIFT, 22 => CTRL, 23 => ALT
  }
  # Compatibility with MKXP-Z 2.4+
  def self.joystick?
    Controller.connected?
  end
  # Get controls text
  def self.control_text(const, context = :menu)
    # Get from Localization
    return Localization.localize("&MUI[Input#{const}-#{context.to_s.capitalize}]")
  end
  # Get types
  def self.is_xbox?
    return false unless Controller.connected?
    Controller.name.scan('Xbox') != []
  end
  def self.is_nintendo?
    return false unless Controller.connected?
    Controller.name.scan('Nintendo') != []
  end
  def self.is_sony?
    return false unless Controller.connected?
    Controller.name.scan('Sony') != [] || Controller.name.scan('PS') != []
  end
  def self.is_generic?
    Controller.connected?
  end
  # Get controller name string
  def self.controller_full_name
    return 'Keyboard' if !Controller.connected?
    return 'Xbox Type' if self.is_xbox?
    return 'Nintendo Type' if self.is_nintendo?
    return 'Sony Type' if self.is_sony?
    'Generic'
  end
  # Get button constant binding name
  def self.control_name_from_id(id)
    return Input::Controller::BUTTON_NAMES[:keyboard][id] if  $game_options.kb_override || !Controller.connected?
    return Input::Controller::BUTTON_NAMES[:xbox][id] if self.is_xbox?
    return Input::Controller::BUTTON_NAMES[:nintendo][id] if self.is_nintendo?
    return Input::Controller::BUTTON_NAMES[:sony][id] if self.is_sony?
    Input::Controller::BUTTON_NAMES[:generic][id]
  end
  # Get controls graphic name
  def self.prompt_graphic_name(const)
    if !Controller.connected? || $game_options.kb_override
      ct = 'KB'
    else
      ct =
        if is_sony?
          'Sony'
        elsif is_nintendo?
          'Nintendo'
        else # Generic defaults to xbox too
          'Xbox'
        end
    end
    return 'Prompt/' + const.to_s.upcase + '_' + ct
  end
  def self.tutorial_graphic_suffix
    if !Controller.connected? || $game_options.kb_override
      'KB'
    else
      if is_sony?
        'Sony'
      elsif is_nintendo?
        'Nintendo'
      else # Generic defaults to xbox too
        'Xbox'
      end
    end
  end
  # For advancing cutscenes
  def self.cutscene_graphic_name
    if Controller.connected? && !$game_options.kb_override
      if is_sony?
        'Prompt/C_Sony'
      elsif is_nintendo?
        'Prompt/C_Nintendo'
      else # Generic defaults to xbox too
        'Prompt/C_Xbox'
      end
    else
      'Prompt/C_KB'
    end
  end
  # Get controller type (for battle graphics)
  def self.battle_control_suffix
    if !Controller.connected? || $game_options.kb_override
      :kb
    else
      if is_sony?
        :sony
      elsif is_nintendo?
        :nintendo
      else # Generic defaults to xbox too
        :joystick
      end
    end
  end
  module Controller
    # MXKP returns a number for the button, which then varies
    # based on the controller type. Use this hash to get the right
    # description.
    # Input::Controller::BUTTON_NAMES[:sony][0] -> "Cross"
    BUTTON_NAMES = {
      keyboard: [
        "S","D","Q","W",
        "Back","Guide","Esc",
        "LS","RS","A","C",
        "Up","Down","Left","Right",
        "Misc","Paddle1","Paddle2","Paddle3","Paddle4","Touchpad"
      ],
      generic: [
        "A","B","X","Y",
        "Back","Guide","Start",
        "LS","RS","LB","RB",
        "Up","Down","Left","Right",
        "Misc","Paddle1","Paddle2","Paddle3","Paddle4","Touchpad"
      ],
      xbox: [
        "A","B","X","Y",
        "Back","Guide","Start",
        "LS","RS","LB","RB",
        "Up","Down","Left","Right",
        "Misc","Paddle1","Paddle2","Paddle3","Paddle4","Touchpad"
      ],
      sony: [
        "Cross","Circle","Square","Triangle",
        "Share","PS","Pause",
        "LS","RS","L1","R1",
        "Up","Down","Left","Right",
        "Misc","Paddle1","Paddle2","Paddle3", "Paddle4","Touchpad"
      ],
      nintendo: [
        "B","A","Y","X",
        "Minus","Home","Plus",
        "LS","RS","L","R",
        "Up","Down","Left","Right",
        "Misc","Paddle1","Paddle2","Paddle3", "Paddle4","Touchpad"
      ]
    }
    AXIS_NAMES = {
      generic: [
        "LStick X",
        "LStick Y",
        "RStick X",
        "RStick Y",
        "LT",
        "RT"
      ],
      xbox: [
        "LStick X",
        "LStick Y",
        "RStick X",
        "RStick Y",
        "LT",
        "RT"
      ],
      sony: [
        "LStick X",
        "LStick Y",
        "RStick X",
        "RStick Y",
        "L2",
        "R2"
      ],
      nintendo: [
        "LStick X",
        "LStick Y",
        "RStick X",
        "RStick Y",
        "ZL",
        "ZR"
      ]
    }
  end
end
#===============================================================================
# ** Bitmap
#===============================================================================
class Bitmap
  #-------------------------------------------------------------------------
  # * Name      : Draw Circle
  #   Info      : Draws A Circle
  #   Author    : SephirothSpawn
  #   Call Info : Integer X and Y Define Position Center Pt of Circle
  #               Integer Radius Radius of the Circle to Draw
  #               Color color Color of the circle to draw
  #-------------------------------------------------------------------------
  def draw_circle(x, y, radius, color = Color.new(255, 255, 255, 255))
    # Starts From Left
    for i in (x - radius)..(x + radius)
      # Finds Distance From Center
      sa = (x - i).abs
      # Finds X Position
      x_ = i < x ? x - sa : i == x ? x : x + sa
      # Finds Top Vertical Portion
      y_ = Integer((radius ** 2 - sa ** 2) ** 0.5)
      # Draws Vertical Bar
      self.fill_rect(x_, y - y_, 1, y_ * 2, color)
    end
  end
  #-------------------------------------------------------------------------
  # * Animation complete determinate
  #-------------------------------------------------------------------------
  def loop_complete?
    self.current_frame == self.last_frame
  end
  #-------------------------------------------------------------------------
  # * Get last frame
  #-------------------------------------------------------------------------
  def last_frame
    (self.frame_count - 1)
  end
  #-------------------------------------------------------------------------
  # * Play catch
  #-------------------------------------------------------------------------
  alias play_debug play
  def play
    # Do not allow if the bitmap isn't animated
    unless self.animated?
      puts "attempted play on static bitmap"
      p caller
      return
    end
    play_debug
  end
  #-------------------------------------------------------------------------
  # * Stop catch
  #-------------------------------------------------------------------------
  alias stop_debug stop
  def stop
    # Do not allow if the bitmap isn't animated
    unless self.animated?
      puts "attempted stop on static bitmap"
      p caller
      return
    end
    stop_debug
  end
  #-------------------------------------------------------------------------
  # * Goto and stop catch
  #-------------------------------------------------------------------------
  alias goto_and_stop_debug goto_and_stop
  def goto_and_stop(frame)
    # Do not allow if the bitmap isn't animated
    unless self.animated?
      puts "attempted goto_and_stop on static bitmap"
      p caller
      return
    end
    goto_and_stop_debug(frame)
  end
  # alias initialize_debug initialize
  # def initialize(*args)
  #   initialize_debug(*args)
  #   puts "initialized a bitmap!"
  #   p caller
  #   puts "-------"
  # end
  #-------------------------------------------------------------------------
  # * Invert bitmap
  #-------------------------------------------------------------------------
  # Inverts the colors of the bitmap. 
  # This is a really expensive operation, and will cause significant lag.
  # Use with care.
  #-------------------------------------------------------------------------
  # def invert(cache = false)
  #   # Has this bitmap already been inverted once?
  #   if @_inverted
  #     # Set the raw data
  #     self.raw_data = @_inverted
  #   end
  #   # Get the raw data
  #   bmpstr = self.raw_data
  #   bmpa = bmpstr.unpack('C*')
  #   # Shift each byte, ignore alpha
  #   count = bmpa.length
  #   i = 0
  #   while i < count
  #     # Split colors, do invert operation (255-RGB)
  #     r = bmpa[i]
  #     g = bmpa[i+1]
  #     b = bmpa[i+2]
  #     a = bmpa[i+3]
  #     bmpa[i] = 255 - r 
  #     bmpa[i+1] = 255 - g
  #     bmpa[i+2] = 255 - b
  #     # Iterate
  #     i += 4
  #   end
  #   bmpstr = bmpa.pack('C*')
  #   @_inverted = bmpstr
  #   # Write the raw data, unless we're just caching @_inverted
  #   unless cache
  #     self.raw_data = @_inverted
  #   end
  # end
  # These functions were in Heretic's MMW. The reasoning was that rotation was buggy
  # I'm not sure if this is still true, but leaving these functions here for now.
  attr_accessor :orientation
  #--------------------------------------------------------------------------
  # * Rotation Calculation
  #--------------------------------------------------------------------------
  def rotation(target)
    return if not [0, 90, 180, 270].include?(target) # invalid orientation
    if @rotation != target
      degrees = target - @orientation
      if degrees < 0
        degrees += 360
      end
      rotate(degrees)
    end    
  end
  #--------------------------------------------------------------------------
  # * Rotate Square (Clockwise)
  #--------------------------------------------------------------------------
  def rotate(degrees = 90)
    # method originally by SephirothSpawn
    # would just use Sprite.angle but its rotation is buggy
    # (see http://www.rmxp.org/forums/showthread.php?t=12044)
    return if not [90, 180, 270].include?(degrees)
    copy = self.clone
    if degrees == 90
      # Passes Through all Pixels on Dummy Bitmap
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(width - i - 1, j, copy.get_pixel(j, i))
        end
      end
    elsif degrees == 180
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(width - j - 1, height - i - 1, copy.get_pixel(j, i))
        end
      end      
    elsif degrees == 270
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(i, height - j - 1, copy.get_pixel(j, i))
        end
      end
    end
    @orientation = (@orientation + degrees) % 360
  end
end
#===============================================================================
# ** Font
#===============================================================================
class Font
  #--------------------------------------------------------------------
  # * Hash of font names gathered based on the user's current localization settings
  # Access with Font::NAMES[Locale][Type]
  #--------------------------------------------------------------------
  NAMES = {
    jp: {
      default: {
        default: "Noto Serif CJK JP",
        numbers: "Noto Sans CJK JP",
        speech:  "M PLUS 1p",
        cutscene: "Reggae One",
        monospace: "DM Mono",
        memory: "New Tegomin",
        writing: "Yuji Boku",
        damage: "M PLUS 1p"
      },
      pixel: {
        default: "PixelMplus12", 
        numbers: "PixelMplus12",
        speech: "PixelMplus12",
        cutscene:"PixelMplus12",
        monospace: "PixelMplus12",
        memory: "PixelMplus12",
        writing: "PixelMplus12",
        damage: "PixelMplus12"
      }
    },
    en_us: {
      default: {
        default: "Trykker",
        numbers: "Lato",
        speech:  "Murecho",
        cutscene: "Inknut Antiqua",
        monospace: "DM Mono",
        memory: "New Tegomin",
        writing: "Yuji Boku",
        damage: "Trykker"
      },
      pixel: {
        default: "Pixelva", 
        numbers: "Pixelva",
        speech: "Pixelva",
        cutscene:"Pixelva",
        monospace: "Pixelva",
        memory: "Pixelva",
        writing: "Pixelva",
        damage: "Pixelva"
      }
    }
  }
  # Default size for a given face
  SIZES = {
    jp: {
      default: {
        default: 24,
        numbers: 22,
        speech:  26,
        cutscene: 29,
        monospace: 20,
        memory: 26,
        writing: 26,
        damage: 60
      },
      pixel: {
        default: 22,
        numbers: 22,
        speech:  27,
        cutscene: 27,
        monospace: 20,
        memory: 27,
        writing: 27,
        damage: 60
      }
    },
    en_us: {
      default: {
        default: 23,
        numbers: 22,
        speech:  27,
        cutscene: 28,
        monospace: 20,
        memory: 26,
        writing: 26,
        damage: 60
      },
      pixel: {
        default: 23,
        numbers: 22,
        speech:  27,
        cutscene: 27,
        monospace: 20,
        memory: 26,
        writing: 26,
        damage: 60
      }
    }
  }
  #--------------------------------------------------------------------
  # * Setup font defaults
  #--------------------------------------------------------------------
  def self.setup_defaults
    self.default_name =
      if Localization.culture
        NAMES.dig(Localization.culture, self.style, :default)
      else
        NAMES.dig(Localization.initial_culture, self.style, :default)
      end
    self.default_outline = false
    self.default_shadow = true
    self.default_color = Color.new(255,255,255,255)
    self.default_out_color = Color.new(0,0,0,128)
    @@name_key = :default
  end
  #--------------------------------------------------------------------
  # * Get current name key
  #--------------------------------------------------------------------
  def self.name_key
    @@name_key ||= :default
    @@name_key 
  end
  #--------------------------------------------------------------------
  # * Get current style
  #--------------------------------------------------------------------
  def self.style
    return :default unless $game_options
    $game_options.font_style
    #Localization.culture == :en_us ? :default : $game_options.font_style
  end
  #--------------------------------------------------------------------
  # * Default size varies based on face
  #--------------------------------------------------------------------
  def self.default_size
    SIZES.dig(Localization.culture, self.style, self.name_key)
  end
  #--------------------------------------------------------------------
  # * Get a custom font name by symbol
  #  Possible values: :default, :numbers, :speech, :special, :memory, :monospace
  #--------------------------------------------------------------------
  def self.custom_name(sym, loc = Localization.culture, style = self.style)
    @@name_key = sym
    NAMES.dig(loc, style, self.name_key)
  end
  #--------------------------------------------------------------------
  # * Scale the font based on its current face
  #--------------------------------------------------------------------
  def self.scale_size(percentage)
    current_size = SIZES.dig(Localization.culture, self.style, self.name_key)
    new_size = current_size * percentage / 100
    # I can't explain this
    if self.style == :pixel 
      if (Localization.culture == :jp && new_size % 2 == 0) || 
        (Localization.culture != :jp && new_size % 2 != 0)
        new_size += 1
      end
    end
    new_size
  end
  #--------------------------------------------------------------------
  # * Get the name used for header text and certain list items
  #--------------------------------------------------------------------
  def self.default_name
    @@name_key = :default
    NAMES.dig(Localization.culture, self.style, @@name_key)
  end
  #--------------------------------------------------------------------
  # * Get the name used for general text & numbers
  #--------------------------------------------------------------------
  def self.numbers_name
    @@name_key = :numbers
    NAMES.dig(Localization.culture, self.style, @@name_key)
  end
  #--------------------------------------------------------------------
  # * Get the name used for speech
  #--------------------------------------------------------------------
  def self.speech_name
    @@name_key = :speech
    NAMES.dig(Localization.culture, self.style, @@name_key)
  end
  #--------------------------------------------------------------------
  # * Get the name used for special cutscenes
  #--------------------------------------------------------------------
  def self.cutscene_name
    @@name_key = :cutscene
    NAMES.dig(Localization.culture, self.style, @@name_key)
  end
  #--------------------------------------------------------------------
  # * Get the name used for special cutscenes
  #--------------------------------------------------------------------
  def self.monospace_name
    @@name_key = :monospace
    NAMES.dig(Localization.culture, self.style, @@name_key)
  end
  #--------------------------------------------------------------------
  # * Reset the font state
  # Only valid when called from within a bitmap
  #--------------------------------------------------------------------
  def reset
    self.color = self.default_color
    self.out_color = self.default_out_color
    self.outline = self.default_outline
    self.shadow = self.default_shadow
    self.bold = false
    self.italic = false
    self.name_key = :default
  end
end
#===============================================================================
# ** Color
#===============================================================================
# class Color
# end
#===============================================================================
# ** Plane
# Methods relevant to camera are in Camera Class Extensions
#===============================================================================
# class Plane
# end
#==============================================================================
# ** Rect
#==============================================================================
class Rect
  attr_accessor :relative_x
  attr_accessor :relative_y

  alias collision_rect_initialize initialize
  def initialize(x=0,y=0,width=0,height=0)
    collision_rect_initialize(x,y,width,height)
    @relative_x = x
    @relative_y = y
  end

  def to_ary
    return [self.x, self.y, self.width, self.height]
  end
end
#===============================================================================
# ** Sprite
# Methods relevant to camera are in Camera Class Extensions
#===============================================================================
class Sprite
  #--------------------------------------------------------------------------
  # * Set origin point to common locations
  # :center, :top_left, :bottom_right
  # Sprites are set to top_left on init
  #--------------------------------------------------------------------------
  def set_origin(pos = :top_left)
    # Coords are set based on bitmap, so if there isn't one, exit
    if self.bitmap.nil?
      puts "WARNING: Sprite origin was set without a valid bitmap! Defaulting to top left."
      return
    end
    case pos
    when :center
      self.ox = self.bitmap.width / 2
      self.oy = self.bitmap.height / 2
    when :top_left
      self.ox = 0
      self.oy = 0
    when :bottom_right
      self.ox = self.bitmap.width
      self.oy = self.bitmap.height
    end
  end
end
#===============================================================================
# ** Table
#===============================================================================

#===============================================================================
# ** Tilemap
# Methods relevant to camera are in Camera Class Extensions
#===============================================================================

#===============================================================================
# ** Tone
#===============================================================================

#===============================================================================
# ** Viewport
# Methods relevant to camera are in Camera Class Extensions
#===============================================================================
class Viewport
  attr_accessor :offset_x, :offset_y, :attached_planes
  
  alias zer0_viewport_resize_init initialize
  def initialize(x=0, y=0, width=LOA::SCRES[0], height=LOA::SCRES[1], override=false)
    # Variables needed for Viewport children (for the Plane rewrite); ignore if
    # your game resolution is not larger than 640x480
    #@offset_x = @offset_y = 0
    
    if x.is_a?(Rect)
      # If first argument is a Rectangle, just use it as the argument.
      zer0_viewport_resize_init(x)
    elsif [x, y, width, height] == [0, 0, 640, 480] && !override 
      # Resize fullscreen viewport, unless explicitly overridden.
      zer0_viewport_resize_init(Rect.new(0, 0, LOA::SCRES[0], LOA::SCRES[1]))
    else
      # Call method normally.
      zer0_viewport_resize_init(Rect.new(x, y, width, height))
    end
  end
  
  # def resize(*args)
  #   # Resize the viewport. Can call with (X, Y, WIDTH, HEIGHT) or (RECT).
  #   if args[0].is_a?(Rect)
  #     args[0].x += @offset_x
  #     args[0].y += @offset_y
  #     self.rect.set(args[0].x, args[0].y, args[0].width, args[0].height)
  #   else
  #     args[0] += @offset_x
  #     args[1] += @offset_y
  #     self.rect.set(*args)
  #   end
  # end
end
#===============================================================================
# ** Window
#===============================================================================

#==============================================================================
# ** RPG Module
#==============================================================================
module RPG 
  #------------------------------------------------------------------------------
  # * RPG::Cache
  #------------------------------------------------------------------------------
  module Cache
    MISSING_BMP_REPLACEMENT = 'Graphics/System/MissingGraphic'
    #---------------------------------------------------------------------------
    # * Load Bitmap
    #---------------------------------------------------------------------------
    def self.load_bitmap(folder_name, filename, hue = 0)
      path = folder_name + filename
      from_cache = true
      if !@cache.include?(path) || @cache[path].disposed?
        if filename != ""
          #puts "initialized in cache: #{path}"
          begin
            @cache[path] = Bitmap.new(path)
          rescue Errno::ENOENT
            GUtil.write_log("WARNING: Missing graphic at #{path}")
            puts caller
            @cache[path] = Bitmap.new(MISSING_BMP_REPLACEMENT)
          end
        else
          @cache[path] = Bitmap.new(32, 32)
        end
        from_cache = false
      end
      if hue == 0
        @cache[path]
      else
        key = [path, hue]
        if !@cache.include?(key) || @cache[key].disposed?
          @cache[key] = @cache[path].clone
          @cache[key].hue_change(hue)
        else
          puts "key existed"
        end
        @cache[key]
      end
      if from_cache
        puts "Loaded a bitmap #{path} from cache" if $DEBUG
      else
        puts "Loaded a bitmap #{path} & ADDED TO CACHE" if $DEBUG
      end
      key.nil? ? @cache[path] : @cache[key]
    end
    #---------------------------------------------------------------------------
    # * Collision map
    #---------------------------------------------------------------------------
    def self.collision_maps(filename)
      self.load_bitmap('Graphics/ZPassability/', filename)
    end
    #---------------------------------------------------------------------------
    # * Height map
    #---------------------------------------------------------------------------
    def self.height_map(filename)
      self.load_bitmap('Graphics/ZSurface/', filename)
    end
    #---------------------------------------------------------------------------
    # # Swamp
    #---------------------------------------------------------------------------
    def self.swamp_map(filename)
      self.load_bitmap('Graphics/ZSwamps/', filename)
    end
    #--------------------------------------------------------------------------
    # * Faces
    #--------------------------------------------------------------------------
    def self.faces(filename, hue = 0)
      self.load_bitmap('Graphics/Faces/', filename, hue)
    end
    #--------------------------------------------------------------------------
    # * Patterns
    #--------------------------------------------------------------------------
    def self.pattern(filename)
      self.load_bitmap("Graphics/Patterns/", filename)
    end
    #--------------------------------------------------------------------------
    # * Patterns
    #--------------------------------------------------------------------------
    def self.light(filename)
      self.load_bitmap("Graphics/Lights/", filename)
    end
    #--------------------------------------------------------------------------
    # * Cutscenes
    #--------------------------------------------------------------------------
    # def self.cutscene(filename, scene)
    #   self.load_bitmap("Graphics/Cutscenes/#{scene}/", filename)
    # end
    #--------------------------------------------------------------------------
    # * System graphics
    #--------------------------------------------------------------------------
    def self.system(filename)
      self.load_bitmap("Graphics/System/", filename)
    end
    # Alias the windowskin method to call system instead
    class << self
      alias :windowskin :system
    end
    #--------------------------------------------------------------------------
    # * Tiles
    #--------------------------------------------------------------------------
    def self.tile(filename, tile_id, hue)
      key = [filename, tile_id, hue]
      if not @cache.include?(key) or @cache[key].disposed?
        puts "Created tile" if $DEBUG
        @cache[key] = Bitmap.new(Game_Map::TILE_SIZE, Game_Map::TILE_SIZE)
        x = (tile_id - 384) % 8 * Game_Map::TILE_SIZE
        y = (tile_id - 384) / 8 * Game_Map::TILE_SIZE
        rect = Rect.new(x, y, Game_Map::TILE_SIZE, Game_Map::TILE_SIZE)
        @cache[key].blt(0, 0, self.tileset(filename), rect)
        @cache[key].hue_change(hue)
      end
      @cache[key]
    end
    #--------------------------------------------------------------------------
    # * Setup the damage number cache
    #-------------------------------------------------------------------------- 
    def self.create_damage_cache
      # For each damage color, predraw each sprite and save to a cache
      BattleConfig::DAMAGE_COLORS.keys do |type|
        10.times do |i|
          number = i.to_s
          @cache[[type, number]] = self.create_damage_number(type, number)
        end
        # We need the + and - too
        signs = ['+', '-']
        signs.each do |l|
          @cache[[type, l]] = self.create_damage_number(type, l)
        end
      end
    end
    #--------------------------------------------------------------------------
    # * Create a damage number bitmap
    #--------------------------------------------------------------------------
    def self.create_damage_number(type, number)
      puts "Created damage number" if $DEBUG
      f_size = Font::SIZES.dig(:en_us, Font.style, :damage)
      bw = f_size * 2
      bh = f_size * 2
      bw += 100 if type == :critical
      bitmap = Bitmap.new(bw, bh)
      bitmap.font.name = Font::NAMES.dig(:en_us, Font.style, :damage) # Numbers don't need to be localized
      bitmap.font.size = f_size
      bitmap.font.color.set(0,0,0)
      bitmap.draw_text(-1, -1, bw, bh, number, 1)
      bitmap.draw_text( 1, -1, bw, bh, number, 1)
      bitmap.draw_text(-1, +1, bw, bh, number, 1)
      bitmap.draw_text( 1, +1, bw, bh, number, 1)
      bitmap.font.color = BattleConfig::DAMAGE_COLORS[type]
      bitmap.draw_text(0, 0, bw, bh, number, 1)
      bitmap
    end
    #--------------------------------------------------------------------------
    # * Get a damage number bitmap
    #--------------------------------------------------------------------------
    def self.damage_number(type, number)
      key = [type, number]
      if !@cache.include?(key) || @cache[key].disposed?
        @cache[key] = self.create_damage_number(type, number)
      end
      @cache[key]
    end
  end
  #------------------------------------------------------------------------------
  # * RPG::Sprite
  #------------------------------------------------------------------------------
  class Sprite < ::Sprite
    #--------------------------------------------------------------------------
    def initialize(viewport=nil,camera=nil)
      super(viewport, camera)
      @_cells_max = 0
      @_loop_cells_max = 0
      @_z_order = 0
      @_whiten_duration = 0
      @_appear_duration = 0
      @_escape_duration = 0
      @_collapse_duration = 0
      @_damage_duration = 0 # Unused, old damage duration calculation
      @_animation_duration = 0
      @_blink = false
      @_flow = false
      @_original_zoom_x = self.zoom_x
      @_original_zoom_y = self.zoom_y
      # Array of currently active damage sprites
      @_damage_letters = []
    end
    #--------------------------------------------------------------------------
    def appear
    end
    #--------------------------------------------------------------------------
    def escape
    end
    #--------------------------------------------------------------------------
    def collapse
    end
    #--------------------------------------------------------------------------
    def classic_collapse
      self.blend_type = 1
      self.color.set(255, 64, 64, 255)
      self.opacity = 255
      @_collapse_duration = 48
      @_whiten_duration = 0
      @_appear_duration = 0
      @_escape_duration = 0
    end
    #--------------------------------------------------------------------------
    # Type - :hp, :sp, :both
    def damage(value, critical, type = :hp, color = nil, states=nil)
      dispose_damage_letters
      @_damage_letters = []
      if value.is_a?(Numeric)
        damage_string = value.abs.to_s
        if value > 0
          damage_string.prepend('-')
        elsif value < 0
          damage_string.prepend('+')
        end
      # String
      else
        damage_string = value.to_s
      end
      font_name = Font.custom_name(:damage)
      font_size = Font.scale_size(50)
      # If set to draw each letter separate
      if BattleConfig::MULTI_POP 
        damage_size = damage_string.size
      else
        damage_size = 1
      end
      # For each letter (note that this only runs once if MULTIPOP is disabled)
      for i in 0...damage_size
        # Check multi-pop
        if BattleConfig::MULTI_POP
          letter = damage_string[i]
        else
          letter = damage_string 
        end
        # Determine the type based on value
        if value.is_a?(Numeric) && value < 0
          btype = 
            case type
            when :hp
              :hp_heal
            when :sp
              :sp_heal
            else # both
              :hpsp_heal
            end
        else
          btype = 
            case type
            when :hp
              :hp_dmg
            when :sp
              :sp_dmg
            else # both
              :hpsp_dmg
            end
          btype = :critical if critical
        end
        # Load from bitmap cache
        bitmap = RPG::Cache.damage_number(btype, letter)
        # Critical string init
        if critical && BattleConfig::CRITIC_TEXT && i == 0
          x_pop = (BattleConfig::MULTI_POP ? (damage_string.size - 1) * (BattleConfig::DMG_SPACE / 2) : 0)
          bitmap.font.name = font_name
          bitmap.font.size = font_size
          bitmap.font.color.set(0, 0, 0)
          bitmap.font.outline = true
          bitmap.draw_text(-1 + x_pop, -1, 160, 20, BattleConfig::POP_CRI, 1)
          bitmap.draw_text(+1 + x_pop, -1, 160, 20, BattleConfig::POP_CRI, 1)
          bitmap.draw_text(-1 + x_pop, +1, 160, 20, BattleConfig::POP_CRI, 1)
          bitmap.draw_text(+1 + x_pop, +1, 160, 20, BattleConfig::POP_CRI, 1)
          bitmap.font.color = BattleConfig::CRIT_TXT_COLOR if critical 
          bitmap.draw_text(0 + x_pop, 0, 160, 20, BattleConfig::POP_CRI, 1)
          # Critical string flash
          $game_screen.start_flash(BattleConfig::CRIT_FLASH_COLOR, 20) if BattleConfig::CRITIC_FLASH
        end
        # Create each sprite
        @_damage_letters[i] = create_damage_sprite(bitmap, i)
      end
      # Append states
      if states
        size = @_damage_letters.size
        states.each_with_index do |state, index|
          state_txt = state[0]
          state_color = state[1]
          bitmap = Bitmap.new(320, BattleConfig::DMG_TXT_F_SIZE)
          bitmap.font.name = font_name
          bitmap.font.size = font_size
          bitmap.font.color.set(0, 0, 0)
          bitmap.draw_text(-1, -1, 160, 36, state_txt, 1)
          bitmap.draw_text(+1, -1, 160, 36, state_txt, 1)
          bitmap.draw_text(-1, +1, 160, 36, state_txt, 1)
          bitmap.draw_text(+1, +1, 160, 36, state_txt, 1)
          bitmap.font.color = state_color
          bitmap.draw_text(0, 0,160, 36, state_txt, 1)
          @_damage_letters[size+index] = create_state_sprite(bitmap, index+1)
        end
      end
    end
    #--------------------------------------------------------------------------
    def create_state_sprite(bitmap, i)
      init_x = BattleConfig::DMG_X_MOVE
      init_y = BattleConfig::DMG_X_MOVE
      duration = BattleConfig::DMG_DURATION + i * 2
      sprite = Sprite_Damage.new(self.viewport, init_x, init_y, duration, mirror)
      sprite.bitmap = bitmap
      sprite.ox = 80
      sprite.oy = 36
      sprite.x = Camera.calc_zoomed_x(self.x)
      sprite.y = Camera.calc_zoomed_y(48 * i + (self.y - self.oy / 2))
      sprite.z = BattleConfig::DMG_DURATION + 3000 + i * 2
      return sprite
    end
    #--------------------------------------------------------------------------
    def create_damage_sprite(bitmap, i)
      init_x = BattleConfig::DMG_X_MOVE
      init_y = BattleConfig::DMG_X_MOVE
      duration = BattleConfig::DMG_DURATION + i * 2
      mirror = self.mirror
      sprite = Sprite_Damage.new(self.viewport, init_x, init_y, duration, mirror)
      sprite.bitmap = bitmap
      sprite.ox = 80
      sprite.oy = 20
      sprite.x = Camera.calc_zoomed_x(self.x + i * BattleConfig::DMG_SPACE)
      sprite.y = Camera.calc_zoomed_y(self.y - self.oy / 2)
      #sprite.visible = false
      return sprite
    end
    #--------------------------------------------------------------------------
    def dispose
      dispose_damage_letters
      super
    end
    # Flowing animation (like blink, except with zooming in and out)
    def flow_on
      return if @_flow == true
      @_flow = true
      @_flow_count = 0
      @_original_zoom_x = self.zoom_x
      @_original_zoom_y = self.zoom_y
    end
    def flow_off
      return if @_flow == false
      @_flow = false
      self.zoom_x = @_original_zoom_x
      self.zoom_y = @_original_zoom_y
    end
    def flow?
      @_flow
    end
    #--------------------------------------------------------------------------
    def update
      super
      if @_flow
        # Min -0.5 Max 0.5
        @_flow_count = (@_flow_count + 1) % 50
        if @_flow_count < 25
          zoom = (25 - @_flow_count) / 100.0
        else
          zoom = (@_flow_count - 25) / 100.0
        end
        self.zoom_x = @_original_zoom_x + zoom
        self.zoom_y = @_original_zoom_y + zoom
      end
      # Update classic effect
      if @_collapse_duration > 0
        @_collapse_duration -= 1
        self.opacity = 256 - (48 - @_collapse_duration) * 6
      end
      # If there are active sprites
      if @_damage_letters
        @_damage_letters.each {|s| s.update}
      end
      if @_whiten_duration > 0
        @_whiten_duration -= 1
        self.color.alpha = 128 - (16 - @_whiten_duration) * 10
      end
      if @_blink
        @_blink_count = (@_blink_count + 1) % 32
        if @_blink_count < 16
          alpha = (16 - @_blink_count) * 6
        else
          alpha = (@_blink_count - 16) * 6
        end
        self.color.set(255, 255, 255, alpha)
      end
      #@@_animations.clear
    end
    #--------------------------------------------------------------------------
    def dispose_damage_letters
      return if @_damage_letters.nil?
      @_damage_letters.each do |sprite|
        if sprite && !sprite.disposed?
          sprite.dispose
        end
      end
      @_damage_letters = nil
    end
  end
  #------------------------------------------------------------------------------
  # * RPG::Weather
  #------------------------------------------------------------------------------
  class Weather
    # Rewritten to use sprites instead of manually drawing bitmaps
    # Also supports more sprites based on screen resolution
    def initialize(viewport = nil)
      @type = 0
      @max = 0
      @ox = 0
      @oy = 0
      # Use sprites instead of manually drawing bitmaps
      @rain_bitmap = RPG::Cache.system("ParticleRain")
      @storm_bitmap = RPG::Cache.system("ParticleStorm")
      @snow_bitmap = RPG::Cache.system("ParticleSnow")
      @sprites = []
      # Add more sprites for increased resolution size
      total_sprites = LOA::SCRES[0] * LOA::SCRES[1] / 7680
      for _i in 1..total_sprites
        sprite = Sprite.new(viewport)
        sprite.z = 1000
        sprite.visible = false
        sprite.opacity = 0
        @sprites.push(sprite)
      end
    end
    
    def type=(type)
      return if @type == type
      @type = type
      case @type
      when 1
        bitmap = @rain_bitmap
      when 2
        bitmap = @storm_bitmap
      when 3
        bitmap = @snow_bitmap
      else
        bitmap = nil
      end
      for i in 1..@sprites.size
        sprite = @sprites[i]
        if sprite != nil
          sprite.visible = (i <= @max)
          sprite.bitmap = bitmap
        end
      end
    end
    
    def max=(max)
      return if @max == max;
      @max = [[max, 0].max, @sprites.size].min
      for i in 1..@sprites.size
        sprite = @sprites[i]
        if sprite != nil
          sprite.visible = (i <= @max)
        end
      end
    end
    
    def update
      return if @type == 0
      for i in 1..@max
        sprite = @sprites[i]
        if sprite == nil
          break
        end
        if @type == 1
          sprite.x -= 2
          sprite.y += 16
          sprite.opacity -= 8
        end
        if @type == 2
          sprite.x -= 8
          sprite.y += 16
          sprite.opacity -= 12
        end
        if @type == 3
          sprite.x -= 2
          sprite.y += 8
          sprite.opacity -= 8
        end
        x = sprite.x - @ox
        y = sprite.y - @oy
        if sprite.opacity < 64 || x < -50 || x > LOA::SCRES[0] - 50 || y < -300 || y > LOA::SCRES[0] - 300
          sprite.x = rand(LOA::SCRES[0]) - 50 + @ox
          # FIXME -- Why is this using screen width like this, and not just the height?
          sprite.y = rand(LOA::SCRES[0]) - 300 + @oy
          sprite.opacity = 255
        end
      end
    end
  end
end