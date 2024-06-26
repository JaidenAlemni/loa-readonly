#==============================================================================
# ■ Sprite_MoveAnime
# Moving sprite (spells, projectiles, etc.)
#==============================================================================
class Sprite_MoveAnime < RPG::Sprite
  #--------------------------------------------------------------------------
  attr_accessor :battler
  attr_accessor :base_x
  attr_accessor :base_y
  #--------------------------------------------------------------------------
  def initialize(viewport,battler = nil,camera)
    super(viewport, camera)
    @battler = battler
    self.visible = false
    @base_x = 0
    @base_y = 0
    @move_x = 0
    @move_y = 0
    @moving_x = 0
    @moving_y = 0
    @orbit = 0
    @orbit_plus = 0
    @orbit_time = 0
    @through = false
    @finish = false
    @time = 0
    @angle = 0
    @angling = 0
  end
  #--------------------------------------------------------------------------
  def dispose
    dispose_animation
    super
  end
  #--------------------------------------------------------------------------
  def anime_action(id,mirror,distanse_x,distanse_y,type,speed,orbit,rotation,weapon_graphic,icon_weapon,z_order)
    @time = speed
    @moving_x = distanse_x / speed
    @moving_y = distanse_y / speed
    @through = true if type == 1
    @orbit_plus = orbit
    @orbit_time = @time
    if weapon_graphic != ""
      # It may be beneficial to allow rotation of the whole animation
      # Regardless of weapon, but leaving it as it was for now
      @angle, end_angle, time = rotation
      @angling = (end_angle - @angle)/ time
      self.angle = @angle
      self.mirror = mirror
      if icon_weapon
        self.bitmap = RPG::Cache.icon(icon_index)
        self.ox = 12
        self.oy = 12
      else 
        self.bitmap = RPG::Cache.character(icon_index, 0)
        self.ox = self.bitmap.width / 2
        self.oy = self.bitmap.height / 2
      end  
      self.visible = true
      self.z = 1000
    end
    self.x = @base_x + @move_x
    self.y = @base_y + @move_y + @orbit
    if id != 0 && !icon_weapon
      animation($data_animations[id],true,z_order)
    elsif id != 0 && icon_weapon
      loop_animation($data_animations[id],z_order)
    end
  end  
  #--------------------------------------------------------------------------  
  def action_reset
    @moving_x = @moving_y = @move_x = @move_y = @base_x = @base_y = @orbit = 0
    @orbit_time = @angling = @angle = 0    
    @through = self.visible = @finish = false
    dispose_animation
  end   
  #--------------------------------------------------------------------------
  def finish?
    @finish
  end 
  #--------------------------------------------------------------------------
  def update
    super
    @time -= 1
    if @time >= 0
      @move_x += @moving_x
      @move_y += @moving_y
      if @time < @orbit_time / 2
        @orbit_plus = @orbit_plus * 5 / 4
      elsif @time == @orbit_time / 2
        @orbit_plus *= -1
      else
        @orbit_plus = @orbit_plus * 2 / 3
      end  
      @orbit += @orbit_plus
    end    
    @time = 100 if @time < 0 && @through
    @finish = true if @time < 0 && !@through
    self.x = @base_x + @move_x
    self.y = @base_y + @move_y + @orbit
    if self.x < -200 || self.x > LOA::SCRES[0] + 200 || self.y < -200 || self.y > LOA::SCRES[1] + 200
      @finish = true
    end
    if self.visible
      @angle += @angling
      self.angle = @angle
    end  
  end
end