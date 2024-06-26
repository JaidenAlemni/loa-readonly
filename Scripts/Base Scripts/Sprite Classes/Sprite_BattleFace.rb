#==============================================================================
# ■ Sprite_BattleFace
# Displays character faces and updates with battler
#==============================================================================
class Sprite_BattleFace < RPG::Sprite
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(actor, x, y)
    x -= 106
    y += 104
    super(nil)
    @dead = false
    @hit = false
    @time = 0
    @new_x = x
    @active = false
    # Cache the faces
    @face_normal = RPG::Cache.battler($data_actors[actor.id].name, 0)
    @face_hit = RPG::Cache.battler("#{$data_actors[actor.id].name}_Hit", 0)
    @inactive_tone = Tone.new(0,0,0,255)
    @inactive_color = Color.new(0,0,0,100)
    @dead_tone = Tone.new(0,0,0,255)
    @dead_color = Color.new(175,20,0,80)
    @width = @face_normal.width
    @height = @face_hit.height
    # Set to normal face
    self.bitmap = @face_normal
    @original_x = x
    self.x = x
    self.y = y
    self.z = 5700
  end
  #--------------------------------------------------------------------------
  # * Make active
  #--------------------------------------------------------------------------
  def active
    return if @dead
    @active = true
    self.tone = Tone.new()
    self.color = Color.new()
    self.z = 5700
  end
  #--------------------------------------------------------------------------
  # * Make inactive
  #--------------------------------------------------------------------------
  def inactive
    @active = false
    self.tone = @inactive_tone
    self.color = @inactive_color if !@dead
  end
  #--------------------------------------------------------------------------
  # * Check active
  #--------------------------------------------------------------------------
  def active?
    return @active
  end
  #--------------------------------------------------------------------------
  # * Show hit
  #--------------------------------------------------------------------------
  def hit
    @hit = true
    self.bitmap = @face_hit
    @time = 30
  end
  #--------------------------------------------------------------------------
  # * Set dead
  #--------------------------------------------------------------------------
  def dead=(bool)
    @dead = bool
    # Set dead face
    if @dead
      self.bitmap = @face_hit
      self.color = @dead_color
      self.tone = @dead_tone
      inactive
    else # Set normal face, unless currently processing a hit
      if !@hit
        self.bitmap = @face_normal
        self.color = Color.new()
        self.tone = Tone.new()
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move
  #--------------------------------------------------------------------------
  def move(x)
    #@new_x = @original_x + x
  end
  #--------------------------------------------------------------------------
  # * Check movement
  #--------------------------------------------------------------------------
  def moving?
    return (self.x != @new_x)
  end  
  #--------------------------------------------------------------------------
  # * Set x
  #--------------------------------------------------------------------------
  def x=(val)
    @new_x = val unless moving?
    super(val)
  end
  #--------------------------------------------------------------------------
  # * Show hit
  #--------------------------------------------------------------------------
  def update
    super
    # Move faces
    # if self.moving?
    #   dx = (@new_x - self.x).to_f / 8
    #   dx = @new_x > self.x ? dx.ceil : dx.floor
    #   self.x += dx
    #   # Last frame of move
    #   if !self.moving?
    #     # Set z order based on activity
    #     self.z = 5100 if !self.active?
    #   end
    # end
    # Animate hit
    if @hit
      @time -= 1
      if @time < 0
        @hit = false
        old_tone = self.tone
        self.bitmap = @face_normal unless @dead
        self.tone = old_tone
        @time = 0
        return
      end
    end
  end
end