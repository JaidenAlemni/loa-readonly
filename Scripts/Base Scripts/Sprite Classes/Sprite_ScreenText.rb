#==============================================================================
# ** Sprite_ScreenText
#------------------------------------------------------------------------------
#  A sprite that draws text on the screen, and can fade in / out
#==============================================================================
class Sprite_ScreenText < Sprite
  FADE_FACTOR = 5 # Default factor to fade the sprite in/out
  WHITE = Color.new(255,255,255)
  SHADOW = Color.new(0,0,0,200)
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :display   # Display flag
  attr_accessor :fade_step # Frames per fade step (speed of fade in / out)
  #--------------------------------------------------------------------------
  # * Object initialization
  #--------------------------------------------------------------------------
  def initialize(viewport, text, y, fade_step = FADE_FACTOR)
    super(viewport)
    @text = text
    @display = false
    @fade_step = fade_step
    self.y = y
    self.opacity = 0
    draw
  end
  #--------------------------------------------------------------------------
  # * Draw label text
  #--------------------------------------------------------------------------
  def draw(text = @text, align = 1, font_size = 150, font_name = Font.default_name, color = WHITE, shadow = true)
    bw = (align == 1 ? LOA::SCRES[0] : text.length * font_size)
    # Get actual font size
    afs = Font.scale_size(font_size)
    bh = afs * 2
    # Create the font shadow sprite and set its parameters
    self.bitmap = Bitmap.new(bw,bh)
    self.bitmap.clear
    self.bitmap.font.name = font_name
    if font_size == 100
      self.bitmap.font.size = Font.default_size
    else
      self.bitmap.font.size = Font.scale_size(font_size)
    end
    self.bitmap.font.color = SHADOW
    # Left offset if center or left aligned, otherwise right offset
    self.x = ([0,1].include?(align) ? 0 : LOA::SCRES[0] - bw)
    # Draw and blur string once, then draw regular on top
    # (This is how we get a drop shadow on the sprite)
    if shadow
      self.bitmap.draw_text(1, 1, bw, bh, text, align)
      self.bitmap.blur
      self.bitmap.blur
    end
    self.bitmap.font.color = color
    self.bitmap.draw_text(0, 0, bw, bh, text, align)
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update
    # If the text is to be displayed, and it's opacity isn't full
    if @display && self.opacity < 255
      self.opacity += @fade_step
    # If the text is to be hidden and the opacity isn't at zero
    elsif !@display && self.opacity > 0
      self.opacity -= @fade_step
    end
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    @display = false
    # Dispose the sprites
    super
  end
end
#==============================================================================
# ** Sprite_TitleText
#------------------------------------------------------------------------------
# Child of Sprite_ScreenText, draws the title screen commands, which 
# include a special glow effect.
#==============================================================================
# class Sprite_TitleText < Sprite_ScreenText
#   #--------------------------------------------------------------------------
#   # * Draw method (turns shadows into glow)
#   #--------------------------------------------------------------------------
#   def draw(text = @text, align = 1, font_size = Font.scale_size(150), font_name = Font.default_name, color = WHITE, shadow = SHADOW)
#     bw = LOA::SCRES[0]
#     bh = 64
#     # Create the font shadow sprite and set its parameters
#     self.bitmap = Bitmap.new(bw,bh)
#     self.bitmap.font.name = font_name
#     self.bitmap.font.size = font_size
#     # Set the colors and draw the text
#     # (This is how we get a drop shadow on the sprite)
#     self.bitmap.font.color = shadow
#     self.bitmap.draw_text(0, 0, bw, bh, text, align)
#     self.bitmap.blur
#     self.bitmap.blur
#     self.bitmap.font.color = color
#     self.bitmap.draw_text(0, 0, bw, bh, text, align)
#   end
# end