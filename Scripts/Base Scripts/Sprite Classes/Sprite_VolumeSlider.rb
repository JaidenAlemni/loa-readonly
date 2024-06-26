#==============================================================================
# ** Sprite_VolumeSlider
#------------------------------------------------------------------------------
#  Sprite for options bars display
#==============================================================================
class Sprite_VolumeSlider < Sprite
  #--------------------------------------------------------------------------
  # * Object Initialization
  # volume - current volume setting
  #--------------------------------------------------------------------------
  def initialize(viewport, volume, y)
    super(viewport)
    @volume = volume
    @bar_bitmap = RPG::Cache.windowskin('VolBar')
    @width = @bar_bitmap.width
    @height = @bar_bitmap.height / 2
    self.bitmap = Bitmap.new(@width, @height)
    self.opacity = 0
    self.y = y
    self.visible = false
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------  
  def refresh(volume)
    @volume = volume
    if self.bitmap.nil?
      self.bitmap = Bitmap.new(@width, @height)
    end
    self.bitmap.clear
    self.bitmap.blt(0, 0, @bar_bitmap, Rect.new(0, 0, @width, @height))
    amount = @width * @volume / 100
    self.bitmap.blt(0, 0, @bar_bitmap, Rect.new(0, @height, amount, @height))
  end
  #--------------------------------------------------------------------------
  # * Update x y
  #--------------------------------------------------------------------------
  def update(val)
    self.x = val
    if self.opacity == 0
      self.opacity = 255
    end
  end     
end
