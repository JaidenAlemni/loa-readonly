#==============================================================================
# ** Sprite_MapName
#------------------------------------------------------------------------------
#  A sprite that draws map text on the map when called and fades in and out
#==============================================================================
class Sprite_MapName < Sprite
  HOLD_TIME = 1.5 # Time, in seconds, to hold the title up
  FADE_FACTOR = 5 # Factor to fade the sprite in/out
  #--------------------------------------------------------------------------
  # * Object initialization
  #--------------------------------------------------------------------------
  def initialize(viewport, name)
    super(viewport)
    @name = name
    @hold_timer = nil
    # Draw the name (sprites)
    draw_name
  end
  #--------------------------------------------------------------------------
  # * Draw label text
  #--------------------------------------------------------------------------
  def draw_name
    # Set the text
    text = "- #{@name} -"
    bw = LOA::SCRES[0]
    bh = 64
    # Create the font shadow sprite and set its parameters
    self.bitmap = Bitmap.new(bw,bh)
    self.bitmap.font.name = Font.default_name
    self.bitmap.font.size = Font.scale_size(200)
    self.opacity = 0
    self.y = LOA::SCRES[1] / 2 - 32
    # Set the colors and draw the text
    # (This is how we get a drop shadow on the sprite)
    self.bitmap.font.color = Color.new(20,20,30,200)
    self.bitmap.draw_text(1, 1, bw, bh, text, 1)
    self.bitmap.blur
    self.bitmap.blur
    self.bitmap.font.color = Color.new(255,255,255)
    self.bitmap.draw_text(0, 0, bw, bh, text, 1)
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update
    # If the "hold at full opacity" timer doesn't exist... 
    if @hold_timer == nil
      # Fade in until at full opacity
      if self.opacity < 255
        self.opacity += FADE_FACTOR
        return
      # Once opacity is full, create the hold timer
      elsif self.opacity == 255
        @hold_timer = Timer.new(HOLD_TIME)
        return
      end
    # If the hold timer reached its limit
    elsif @hold_timer.finished?
      # Fade out until opacity is 0
      if self.opacity > 0
        self.opacity -= FADE_FACTOR
        return
      # Once sprite is invisible, turn off update and kill the timer
      elsif self.opacity == 0
        $game_temp.display_map_name = false
        @hold_timer = nil
        return
      end
    # We must be at full opacity if the timer exists, update it
    else
      # Update the hold timer
      @hold_timer.update
    end
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    # Get rid of the timer
    @hold_timer = nil
    # Disable the flag
    $game_temp.display_map_name = false
    # Dispose the sprites
    super
  end
end