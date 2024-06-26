#==============================================================================
# ** Sprite_Damage
# This is an individual sprite for the damage letters, responsible for the
# "bounce" physics effect. 
#==============================================================================
class Sprite_Damage < Sprite
  attr_reader :duration
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(viewport, init_x_speed, init_y_speed, duration, mirror)
    super(viewport)
    self.opacity = 255
    self.z = 3000
    @damage_mirror = mirror
    @now_x_speed = init_x_speed
    @now_y_speed = init_y_speed
    @potential_x_energy = 0.0
    @potential_y_energy = 0.0
    @duration = duration
  end
  #--------------------------------------------------------------------------
  # * X Method
  # Aliased to tie the coordinates to the camera as if zoomed
  #--------------------------------------------------------------------------
  alias sprite_damage_x x=
  def x=(n)
    sprite_damage_x(n)
    @x = Camera.calc_zoomed_x(n)
  end
  #--------------------------------------------------------------------------
  # * Y Method
  # Aliased to tie the coordinates to the camera as if zoomed
  #--------------------------------------------------------------------------
  alias sprite_damage_y y=
  def y=(n)
    sprite_damage_y(n)
    @y = Camera.calc_zoomed_y(n)
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    return if self.disposed?
    @duration -= 1
    return unless @duration <= BattleConfig::DMG_DURATION # compensate for frames
    super
    n = self.oy + @now_y_speed
    if n <= 0
      @now_y_speed *= -1
      @now_y_speed /=  2
      @now_x_speed /=  2
    end
    self.oy  = [n, 0].max
    @potential_y_energy += BattleConfig::DMG_GRAVITY
    speed = @potential_y_energy.floor
    @now_y_speed        -= speed
    @potential_y_energy -= speed
    if BattleConfig::POP_MOVE
      @potential_x_energy += @now_x_speed if @damage_mirror 
      @potential_x_energy -= @now_x_speed if !@damage_mirror
    end
    speed = @potential_x_energy.floor
    self.ox             += speed
    @potential_x_energy -= speed
    case @duration
    when 1..10
      self.opacity -= 25
    when 0
      self.visible = false
    end
  end
end