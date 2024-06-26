#==============================================================================
# ■ Sprite_Weapon
#==============================================================================
class Sprite_Weapon < RPG::Sprite
  #--------------------------------------------------------------------------
  # * Include Configuration Module
  #--------------------------------------------------------------------------
  include BattleConfig
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :battler
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(viewport,battler = nil,camera)
    super(viewport, camera)
    @battler = battler
    @action = []
    @move_x = 0
    @move_y = 0
    @move_z = 0
    @plus_x = 0
    @plus_y = 0
    @angle = 0
    @zoom_x = 1
    @zoom_y = 1
    @moving_x = 0
    @moving_y = 0
    @angling = 0
    @zooming_x = 1
    @zooming_y = 1
    @freeze = -1
    @mirroring = false
    @time = ANIME_PATTERN + 1
    weapon_graphics 
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    self.bitmap.dispose if self.bitmap != nil
    super
  end
  #--------------------------------------------------------------------------
  # * Weapon Graphics
  #     Sets the weapon sprite bitmap
  #--------------------------------------------------------------------------
  def weapon_graphics(left = false)
    if @battler.actor?
      weapon = @battler.weapons[0] unless left
      weapon = @battler.weapons[1] if left
    else
      weapon = $data_weapons[@battler.weapon_id]
      @mirroring = true if @battler.action_mirror
    end
    return if weapon == nil
    if weapon.graphic == ""
      self.bitmap = RPG::Cache.icon(weapon.icon_name)
      @weapon_width = @weapon_height = 24
    else
      self.bitmap = RPG::Cache.icon(weapon.graphic)
      @weapon_width = self.bitmap.width
      @weapon_height = self.bitmap.height
    end
  end
  #--------------------------------------------------------------------------
  def freeze(action)
    @freeze = action
  end
  #--------------------------------------------------------------------------
  # * Weapon Action
  #     Animates the weapon sprite 
  #--------------------------------------------------------------------------
  def weapon_action(action,loop)
    if action == ""
      self.visible = false
    elsif @weapon_id == 0
      self.visible = false
    else
      @action = ANIME[action]
      act0 = @action[0] # x-axis distance
      act1 = @action[1] # y-axis distance (neg up, pos down)
      act2 = @action[2] # weapon over/under battler
      act3 = @action[3] # Starting angle
      act4 = @action[4] # Ending angle
      act5 = @action[5] # Rotation origin 
      act6 = @action[6] # weapon horizontally inverted
      act7 = @action[7] # horizontal stretch
      act8 = @action[8] # vertical stretch
      act9 = @action[9] # x pitch
      act10 = @action[10] # y pitch
      time = ANIME_PATTERN 
      # Place weapon above or below actor
      if act2
        self.z = @battler.position_z + 1
      else
        self.z = @battler.position_z - 1
      end
      # Determine if sprite is mirrored
      if act6 || @mirroring || !@battler.actor?
        # Set x axis values based on mirroring
        act0 *= -1
        act3 *= -1
        act4 *= -1
        act9 *= -1
        # If already flipped
        if self.mirror 
          # Reverse
          self.mirror = false
        else
          # Flip sprite horizontally
          self.mirror = true
        end
      end
      # Flip rotation origins if the sprite is mirrored
      if self.mirror
        case act5
        when 1 # Upper left
          act5 = 2
        when 2 # Upper Right
          act5 = 1
        when 3 # Bottom Left
          act5 = 4
        when 4 # Bottom Right
          act5 = 3
        end  
      end    
      # Process sprite movement
      @moving_x = act0 / time
      @moving_y = act1 / time
      @angle = act3
      self.angle = @angle
      @angling = (act4 - act3)/ time
      @angle += (act4 - act3) % time
      @zooming_x = (1 - act7) / time
      @zooming_y = (1 - act8) / time
      case act5
      when 0
        self.ox = @weapon_width / 2
        self.oy = @weapon_height / 2
      when 1
        self.ox = 0
        self.oy = 0
      when 2
        self.ox = @weapon_width
        self.oy = 0
      when 3
        self.ox = 0
        self.oy = @weapon_height
      when 4
        self.ox = @weapon_width
        self.oy = @weapon_height
      end  
      @plus_x = act9
      @plus_y = act10
      @loop = true if loop == 0
      @angle -= @angling
      @zoom_x -= @zooming_x
      @zoom_y -= @zooming_y
      @move_x -= @moving_x
      @move_y -= @moving_y 
      @move_z = 1000 if act2
      if @freeze != -1
        for i in 0..@freeze + 1
          @angle += @angling
          @zoom_x += @zooming_x
          @zoom_y += @zooming_y
          @move_x += @moving_x
          @move_y += @moving_y 
        end
        @angling = 0
        @zooming_x = 0
        @zooming_y = 0
        @moving_x = 0
        @moving_y = 0
      end 
      self.visible = true
    end 
  end  
  #--------------------------------------------------------------------------
  def action_reset
    @moving_x = @moving_y = @move_x = @move_y = @plus_x = @plus_y = 0
    @angling = @zooming_x = @zooming_y = @angle = self.angle = @move_z = 0
    @zoom_x = @zoom_y = self.zoom_x = self.zoom_y = 1
    self.mirror = self.visible = @loop = false
    @freeze = -1
    @action = []
    @time = ANIME_PATTERN + 1
  end 
  #--------------------------------------------------------------------------
  def action_loop
    @angling *= -1
    @zooming_x *= -1
    @zooming_y *= -1
    @moving_x *= -1
    @moving_y *= -1
  end  
  #--------------------------------------------------------------------------
  def mirroring 
    return @mirroring = false if @mirroring
    @mirroring = true
  end  
  #--------------------------------------------------------------------------
  def action
    return if @time <= 0
    @time -= 1
    @angle += @angling
    @zoom_x += @zooming_x
    @zoom_y += @zooming_y
    @move_x += @moving_x
    @move_y += @moving_y 
    if @loop && @time == 0
      @time = ANIME_PATTERN + 1
      action_loop
    end 
  end  
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update
    super
    self.angle = @angle
    self.zoom_x = @zoom_x
    self.zoom_y = @zoom_y
    self.x = @battler.position_x + @move_x + @plus_x
    self.y = @battler.position_y + @move_y + @plus_y
    self.z = @battler.position_z + @move_z - 1
  end
end