
class Window_FontTest < Window_Base
  DEFAULT_SIZES = [8,12,16,24,32,48]

  def initialize
    width, height = LOA::SCRES
    super(0,0,width,height)
    @font_sizes = DEFAULT_SIZES.dup
    refresh
  end

  def refresh(font_adjust = nil)
    self.contents.clear
    if font_adjust
      @font_sizes.map!{|s| s.send(font_adjust, 0.5)}
    end
    rh = 600 / 8
    puts @font_sizes
    str =
      if Localization.culture == :jp
        "キミにとっても安全なはずだ。"
      else
        "The quick brown fox jumps over the lazy dog."
      end
    @font_sizes.each_with_index do |size, i|
      self.contents.font.name = Font.default_name
      self.contents.font.size = [size, 6].max
      self.contents.font.color = Color.new(0,0,0)
      self.contents.draw_text(size / 12, i * rh + size / 12, contents_width, rh, str)
      self.contents.font.color = Color.new(255,255,255)
      self.contents.draw_text(0, i * rh, contents_width, rh, str)
    end
  end

  def set_outline(bool)
    self.contents.font.out_color = Color.new(255,255,255,255)
    self.contents.font.outline = bool
    refresh
  end
end

class Scene_Test
  def initialize
    init_font_test
  end

  def main
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
    end
    Graphics.freeze
  end

  def update
    if Input.trigger?(Input::UP)
      @font_window.refresh(:+)
    elsif Input.trigger?(Input::DOWN)
      @font_window.refresh(:-)
    elsif Input.trigger?(Input::C)
      @font_window.set_outline(true)
    elsif Input.trigger?(Input::B)
      @font_window.set_outline(false)
    end
    #test_1(@sprite)
    #test_2(@sprite2)
  end

  def init_font_test
    @font_window = Window_FontTest.new
  end

  def init_apple_zoom
    @sprite = Sprite.new
    @sprite.bitmap = RPG::Cache.icon("Itm_Apple")
    #@sprite.bitmap.fill_rect(Rect.new(0,0,32,32), Color.new(255,255,255))
    @sprite.x = LOA::SCRES[0] / 2 - 200
    @sprite.y = LOA::SCRES[1] / 2
    @sprite.ox = @sprite.bitmap.width / 2
    @sprite.oy = @sprite.bitmap.height / 2
    @sprite2 = Sprite.new
    @sprite2.bitmap = RPG::Cache.icon("Itm_Apple")
    #@sprite.bitmap.fill_rect(Rect.new(0,0,32,32), Color.new(255,255,255))
    @sprite2.x = LOA::SCRES[0] / 2 + 200
    @sprite2.y = LOA::SCRES[1] / 2
    @sprite2.ox = @sprite2.bitmap.width / 2
    @sprite2.oy = @sprite2.bitmap.height / 2
    @direction = 0
    @direction2 = 0
    @zoom_int = 100
  end

  def test_1(sprite)
    if @direction == 0
      sprite.zoom_x += 64
      sprite.zoom_y += 64
      @direction = 1 if sprite.zoom_x >= 8000
    elsif @direction == 1
      sprite.zoom_x -= 64
      sprite.zoom_y -= 64
      @direction = 0 if sprite.zoom_x <= 1000
    end
    #puts "1: #{sprite.zoom_x}, #{sprite.zoom_y}"
  end

  def test_2(sprite)
    if @direction2 == 0
      @zoom_int += 10
      sprite.zoom_x = (@zoom_int / 100.0)
      sprite.zoom_y = (@zoom_int / 100.0)
      @direction2 = 1 if @zoom_int >= 800
    elsif @direction2 == 1
      @zoom_int -= 10
      sprite.zoom_x = (@zoom_int / 100.0)
      sprite.zoom_y = (@zoom_int / 100.0)
      @direction2 = 0 if @zoom_int <= 100
    end
    puts "2: #{sprite.zoom_x}, #{sprite.zoom_y}"
  end
end

__END__
#==============================================================================
# ** Scene Test
#------------------------------------------------------------------------------
# For testing miscellanous things
class Scene_Test
#--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(index = 0)
    # Set the previous scene
    @previous_scene = $scene
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
    @bg = Sprite.new
    @bg.bitmap = Bitmap.new("Graphics/Battlebacks/VFieldBB.png")
    @sp = Sprite.new
    @actions = ["Graphics/Battlers/Oliver_Idle.gif","Graphics/Battlers/Oliver_Skill.gif"]
    @index = 0
    @sp.bitmap = Bitmap.new(@actions[@index])
    @sp.bitmap.looping = true
    @sp.bitmap.play
    @sp.zoom_x = 3.0
    @sp.zoom_y = 3.0
    @sp.x = 20
    @sp.y = 20
    @sp.z += 100
    ## pattern test
    @sp.pattern = RPG::Cache.pattern('debris')
    @sp.pattern_tile = true
    @sp.pattern_zoom_x = 0.25
    @sp.pattern_zoom_y = 0.25
    @sp.pattern_blend_type = 2
    # === Animation Debugging ===
    # @animation = ['None', 0]
    # @commands = ['Name', 'Blend-Type', 'Play Animation']
    
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
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar.update if ivar.is_a?(Window)
    end
    @sp.pattern_scroll_x += 1
    @sp.pattern_scroll_y -= 1
    if Input.trigger?(Input::UP)
      #@sp.bitmap.frame_rate += 1
      @sp.zoom_x += 0.5
      @sp.zoom_y += 0.5
    elsif Input.trigger?(Input::DOWN)
      #@sp.bitmap.frame_rate -= 1
      @sp.zoom_x -= 0.5
      @sp.zoom_y -= 0.5
    elsif Input.trigger?(Input::RIGHT)
      @index = (@index - 1) % 2
      @sp.bitmap = Bitmap.new(@actions[@index])
      @sp.bitmap.play
    elsif Input.trigger?(Input::LEFT)
      @index = (@index + 1) % 2
      @sp.bitmap = Bitmap.new(@actions[@index])
      @sp.bitmap.play
    elsif Input.trigger?(Input::X)
      @sp.pattern_blend_type = (@sp.pattern_blend_type + 1) % 3
      puts @sp.pattern_blend_type
    elsif Input.trigger?(Input::C)
      @sp.pattern_opacity = @sp.pattern_opacity == 200 ? 0 : 200
    elsif Input.trigger?(Input::B)
      close_scene
    end
  end
  #--------------------------------------------------------------------------
  # * Exit Scene
  #-------------------------------------------------------------------------- 
  def close_scene
    $game_system.se_play($data_system.cancel_se)
    cleanup
    $scene = @previous_scene
  end 
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  #-------------------------------------------------------------------------- 
  def cleanup
    # Exit if animating windows is disabled
    return if $game_options.disable_win_anim
    # Initialize temp window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Window)
        windows << ivar
        ivar.move(MenuConfig::WINDOW_OFFSCREEN_RIGHT, ivar.y, 8)
      end
    end
    # Animate windows
    16.times do
      Graphics.update
      windows.each do |window|
        window.update
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
  end
end