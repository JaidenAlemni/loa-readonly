#==============================================================================
# ■ Class for individual ATB sprites
#==============================================================================
class Sprite_ATB < RPG::Sprite
  attr_accessor :battler
  # Object Initialize ---------------------------------------------------------
  def initialize(battler, viewport)
    super(viewport)
    # Determine if enemy or actor
    iconname = nil
    if battler.is_a?(Game_Actor)
      iconname = ATB::Config.actor_icon(battler.id)
    else
      iconname = ATB::Config.enemy_icon(battler.id)
      # Append letter sprite (if valid)
      if battler.plural
        lettername = battler.letter.slice(1)
        @lsprite = Sprite.new(viewport)
        @lsprite.bitmap = RPG::Cache.icon("ATB/#{lettername}")
        @lsprite.ox = @lsprite.bitmap.height / 2
        @lsprite.oy = @lsprite.bitmap.height / 2
        @lsprite.z = 1100
      end
    end
    @battler = battler
    self.bitmap = RPG::Cache.icon("ATB/#{iconname}")
    self.oy = self.bitmap.height / 2
    self.ox = self.bitmap.width / 2
    self.z = 1001
    @explode = false
  end 
  # Set z -------------------------------------------------------------------
  def z=(n)
    @lsprite.z = n + 100 unless @lsprite.nil?
    super(n)
  end
  # Set x -------------------------------------------------------------------
  def x=(n)
    @lsprite.x = n unless @lsprite.nil?
    super(n)
  end
  # Set y -------------------------------------------------------------------
  def y=(n)
    @lsprite.y = n unless @lsprite.nil?
    super(n)
  end
  # Set visibility ----------------------------------------------------------
  def visible=(bool)
    @lsprite.visible = bool unless @lsprite.nil?
    super(bool)
  end
  # Set opacity  ------------------------------------------------------------
  def opacity=(n)
    @lsprite.opacity = n unless @lsprite.nil?
    super(n)
  end
  # Set update sprites ------------------------------------------------------
  def update
    if @explode && self.opacity > 0
      self.zoom_x += 0.1
      self.zoom_y += 0.1
      self.opacity -= 15
      if @lsprite
        @lsprite.zoom_x += 0.1
        @lsprite.zoom_y += 0.1
        @lsprite.opacity -= 15
      end
    elsif @explode == false
      @explode = nil
      self.opacity = 255
      self.zoom_x = 1.0
      self.zoom_y = 1.0
      if @lsprite
        @lsprite.opacity = 255
        @lsprite.zoom_x = 1.0
        @lsprite.zoom_y = 1.0
      end
    end
    super
  end
  # Set explode effect --------------------------------------------------------
  def explode=(bool)
    @explode = bool
  end
  # Set blink effect --------------------------------------------------------
  def blink=(bool)
    bool ? self.blink_on : self.blink_off
  end
  # Dispose sprite ----------------------------------------------------------
  def dispose
    @lsprite.dispose unless @lsprite.nil?
    super
  end
end