#==============================================================================
# ** Sprite_Picture
#------------------------------------------------------------------------------
#  This sprite is used to display the picture.It observes the Game_Character
#  class and automatically changes sprite conditions.
#==============================================================================

class Sprite_Picture < Sprite
  # Access picture
  attr_reader :picture
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     viewport : viewport
  #     picture  : picture (Game_Picture)
  #--------------------------------------------------------------------------
  def initialize(viewport, picture)
    super(viewport)
    @picture = picture
    update
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    if self.bitmap != nil
      self.bitmap.dispose
    end
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    # If picture file name is different from current one
    if @picture_name != @picture.name
      # Remember file name to instance variables
      @picture_name = @picture.name
      # If file name is not empty
      if @picture_name != ""
        # Get picture graphic
        self.bitmap = RPG::Cache.picture(@picture_name)
      end
    end
    # If file name is empty
    if @picture_name == ""
      # Set sprite to invisible
      self.visible = false
      return
    end
    # Set sprite to visible
    self.visible = true
    # Set mirroring
    self.mirror = @picture.mirror
    # Set transfer starting point
    # Modified to allow additional origin
    if @picture.origin == 0
      self.ox = 0
      self.oy = 0
    elsif @picture.origin == 2 # bottom right (or left)
      # Set origin to bottom left if mirroring
      if @picture.mirror
        self.ox = 0
        self.oy = self.bitmap.height
      else # Origin bottom right
        self.ox = self.bitmap.width
        self.oy = self.bitmap.height
      end
    else #center
      self.ox = self.bitmap.width / 2
      self.oy = self.bitmap.height / 2
    end
    # Set sprite coordinates
    self.x = @picture.x
    self.y = @picture.y
    self.z = @picture.number
    # Set zoom rate, opacity level, and blend method
    self.zoom_x = @picture.zoom_x / 100.0
    self.zoom_y = @picture.zoom_y / 100.0
    self.opacity = @picture.opacity
    self.blend_type = @picture.blend_type
    # Set rotation angle and color tone
    self.angle = @picture.angle
    self.tone = @picture.tone
    self.color = @picture.color
  end
end
