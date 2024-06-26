#==============================================================================
# ** Window_Base
#------------------------------------------------------------------------------
# This class is for all in-game windows.
#
# Movement methods created by Gameus
#==============================================================================
class Window_Base < Window
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------  
  attr_accessor :dest_x           # Destination X
  attr_accessor :dest_y           # Destination Y
  attr_accessor :move_speed       # Time to move (frames)
  attr_accessor :fixed            # Window move capability
  attr_accessor :window_blank     # Determines if window should be drawn invisible
  attr_accessor :line_height      # Line height for window contents
  # Default move speed
  DEFAULT_SPEED = 8
  # Alignment constants
  ALIGN_LEFT = 0
  ALIGN_CENTER = 1
  ALIGN_RIGHT = 2
  # Color keys (managed in config file)
  COLOR_KEYS = [
    WHITE_COLOR, #0 
    BLUE_COLOR,  #1
    RED_COLOR,   #2
    GREEN_COLOR, #3
    CYAN_COLOR,  #4
    PURPLE_COLOR,#5 
    ORANGE_COLOR,#6
    GREY_COLOR,  #7
    BLACK_COLOR  #8
  ] 
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     x      : window x-coordinate
  #     y      : window y-coordinate
  #     width  : window width
  #     height : window height
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super()
    @windowskin_name = $game_system.windowskin_name
    self.windowskin = RPG::Cache.system(@windowskin_name)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.z = 100
    # Move settings
    self.dest_x = x
    self.dest_y = y
    self.move_speed = DEFAULT_SPEED
    self.fixed = true
    # Additional settings
    self.window_blank = false
    @line_height = 32
    self.padding = 12
    self.opacity = 255
    self.back_opacity = 255
    # Create contents
    create_contents
    # Reset close/open
    @opening = false
    @closing = false
    # Factor for opening/closing windows
    @oc_factor = 48
  end
  # #--------------------------------------------------------------------------
  # # * Override print information for the object (puts)
  # #--------------------------------------------------------------------------
  # def to_s
  #   "=== #{self.class} ===\n 
  #   Width: #{self.width} Height: #{self.height} X: #{self.x} Y: #{self.y} Z: #{self.z}\n
  #   Padding: #{self.padding} Fixed? #{self.fixed}\n
  #   =================="  
  # end
  #--------------------------------------------------------------------------
  # * Calculate Width of Window Contents
  #--------------------------------------------------------------------------
  def contents_width
    width - self.padding * 2
  end
  #--------------------------------------------------------------------------
  # * Calculate Height of Window Contents
  #--------------------------------------------------------------------------
  def contents_height
    height - self.padding * 2
  end
  #--------------------------------------------------------------------------
  # * Calculate Height of Window Suited to Specified Number of Lines
  #--------------------------------------------------------------------------
  def fitting_height(line_number)
    line_number * @line_height + self.padding * 2
  end
  #--------------------------------------------------------------------------
  # * Create Window Contents
  #--------------------------------------------------------------------------
  def create_contents
    contents.dispose
    if contents_width > 0 && contents_height > 0
      self.contents = Bitmap.new(contents_width, contents_height)
    else
      self.contents = Bitmap.new(1, 1)
    end
  end
  #--------------------------------------------------------------------------
  # * Check Color (from Heretic's MMW)
  #     color : color to check
  #--------------------------------------------------------------------------
  def check_color(color)
    if color == "*"
      return KEYWORD_COLOR
    elsif color.is_a?(Color)
      return color
    elsif !(0..9).include?(color.to_i)
      # specified as hexadecimal
      r = color[0..1].hex
      g = color[2..3].hex
      b = color[4..5].hex
      return Color.new(r,g,b)
    else
      # Convert to an integer and get the corresponding code
      return text_color(color.to_i)
    end
    return normal_color
  end
  #--------------------------------------------------------------------------
  # * Get Text Color
  #     n : text color number (0-7)
  # Modified to include custom colors
  #--------------------------------------------------------------------------
  def text_color(c)
    # Convert to key
    if c.is_a?(Integer)
      return COLOR_KEYS[c]
    elsif !c.is_a?(Color)
      return c
    end
  end
  #--------------------------------------------------------------------------
  # * Get Normal Text Color
  #--------------------------------------------------------------------------
  def normal_color
    return WHITE_COLOR
  end
  #--------------------------------------------------------------------------
  # * Get Disabled Text Color
  #--------------------------------------------------------------------------
  def disabled_color
    return DISABLED_COLOR
  end
  #--------------------------------------------------------------------------
  # * Get System Text Color
  #--------------------------------------------------------------------------
  def system_color
    return SYSTEM_COLOR
  end
  #--------------------------------------------------------------------------
  # * Get Crisis Text Color
  #--------------------------------------------------------------------------
  def crisis_color
    return GOLD_COLOR
  end
  #--------------------------------------------------------------------------
  # * Get Knockout Text Color
  #--------------------------------------------------------------------------
  def knockout_color
    return KNOCKOUT_COLOR
  end 
  #--------------------------------------------------------------------------
  # * Reset font to defaults
  #--------------------------------------------------------------------------    
  def reset_font
    self.contents.font.name = Font.default_name
    self.contents.font.size = Font.default_size
    self.contents.font.bold = false
    self.contents.font.italic = false
    self.contents.font.color = normal_color
  end
  #--------------------------------------------------------------------------
  # * Set window fonts to specified values
  #   name: Font name key (:default, :numbers, :speech, etc. see Font class)
  #   size: Font size, in integer percentage
  #--------------------------------------------------------------------------   
  def set_font(name, size = 100, color = WHITE_COLOR)
    self.contents.font.name = Font.custom_name(name)
    self.contents.font.size = Font.scale_size(size)
    self.contents.font.color = color
  end
  #--------------------------------------------------------------------------
  # * Check visibility
  #--------------------------------------------------------------------------
  def visible?
    return self.visible
  end
  #-------------------------------------------------------------------------
  # Enemy show? (0 = not found, 1 = discovered, 2 = inspected) (BESTIARY)
  #--------------------------------------------------------------------------    
  def enemy_shown?(id)
    # If enemy is discovered
    if $game_system.enemies_encountered[id] >= 1
      return 1
    # If enemy is inspected
    elsif $game_system.enemies_inspected.include?(id)
      return 2
    # If neither (not found)
    else 
      return 0
    end
  end
  #--------------------------------------------------------------------------
  # * Set blank windowskin
  #--------------------------------------------------------------------------
  def window_blank=(bool)
    @window_blank = bool
    if bool
      self.windowskin = RPG::Cache.windowskin("Blank")
    else
      self.windowskin = RPG::Cache.system(@windowskin_name)
    end
  end
  #==============================================================================
  # * MOVE METHODS
  #==============================================================================
  #--------------------------------------------------------------------------
  # * Determine movement
  #--------------------------------------------------------------------------  
  def moving?
    #Check if window is allowed to move
    if self.fixed
      return false
    end
    #Check if window is changing coordinates
    return (self.x != self.dest_x || self.y != self.dest_y)
  end
  #--------------------------------------------------------------------------
  # * Initiate Move
  #--------------------------------------------------------------------------
  # dest_x - x value to move to
  # dest_y - y value to move to
  # move_speed - speed in frames to move
  # bypass - whether or not movement is ignored
  #--------------------------------------------------------------------------  
  def move(dest_x, dest_y, move_speed = DEFAULT_SPEED, bypass = false)
    self.dest_x = dest_x
    self.dest_y = dest_y
    self.move_speed = move_speed
    # If animating windows is disabled and this isn't overridden
    return if bypass
    if $game_options.disable_win_anim
      self.x = self.dest_x
      self.y = self.dest_y
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Move windows
  #--------------------------------------------------------------------------
  def update_move
    self.x += Easing.default(self.x, self.dest_x, self.move_speed)
    self.y += Easing.default(self.y, self.dest_y, self.move_speed)
  end
  #--------------------------------------------------------------------------
  # * Set X position
  #--------------------------------------------------------------------------
  def x=(val)
    self.dest_x = val unless moving?
    super(val)
  end
  #--------------------------------------------------------------------------
  # * Set Y position
  #--------------------------------------------------------------------------
  def y=(val)
    self.dest_y = val unless moving?
    super(val)
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    # Dispose if window contents bit map is set
    if self.contents != nil
      self.contents.dispose
    end
    super
  end
  #--------------------------------------------------------------------------
  # * Update Open Processing
  #--------------------------------------------------------------------------
  def update_open
    self.openness += @oc_factor
    @opening = false if open?
  end
  #--------------------------------------------------------------------------
  # * Update Close Processing
  #--------------------------------------------------------------------------
  def update_close
    self.openness -= @oc_factor
    @closing = false if close?
  end
  #--------------------------------------------------------------------------
  # * Open Window
  #--------------------------------------------------------------------------
  def open(factor = 48)
    @oc_factor = factor
    @opening = true unless open?
    @closing = false
    self
  end
  #--------------------------------------------------------------------------
  # * Close Window
  #--------------------------------------------------------------------------
  def close(factor = 48)
    @oc_factor = factor
    @closing = true unless close?
    @opening = false
    self
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    # (MMw) This fixes a Visual Bug where a Windowskin will change on you when
    # a Non Floating Message Window is Fading Out.  The NEXT Message will
    # have the newly set Windowskin applied.
    if $game_system.windowskin_name != @windowskin_name
      # Prevents changing Message Windowskin until Next Message
      if !self.is_a?(Window_Message)
        @windowskin_name = $game_system.windowskin_name
        self.windowskin = RPG::Cache.windowskin(@windowskin_name)
      end
    end
    # Move windows
    update_move if self.moving?
    # Open/Close Windows
    update_open if @opening
    update_close if @closing
  end
  #==============================================================================
  # * DRAW METHODS
  #==============================================================================
  #--------------------------------------------------------------------------
  # * Draw Divider Line
  # Draws a horizontal or vertical line with a shadow
  # x,y coordinates are always top-left
  #--------------------------------------------------------------------------
  def draw_divider_line(x, y, length, vertical = false, thickness = 1, color = WHITE_COLOR)
    # Swap width/height based on vertical or horizontal placement
    if vertical
      w = thickness
      h = length
      shadow_w = 1
      shadow_h = 0
    else # Horizontal
      w = length
      h = thickness
      shadow_w = 0
      shadow_h = 1
    end
    # Draw shadow
    self.contents.fill_rect(x, y, w + shadow_w, h + shadow_h, BLACK_COLOR)
    # Draw line
    self.contents.fill_rect(x, y, w, h, color)
  end
  #--------------------------------------------------------------------------
  # * Draw Graphic
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #--------------------------------------------------------------------------
  def draw_actor_graphic(actor, x, y)
    bitmap = RPG::Cache.character(actor.character_name, actor.character_hue)
    cw = bitmap.width / 4
    ch = bitmap.height / 4
    src_rect = Rect.new(0, 0, cw, ch)
    self.contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
  #--------------------------------------------------------------------------
  # * Draw an actors face graphic
  # type - size
  # 0 - full size (menu)
  # 1 - small square (submenus)
  #--------------------------------------------------------------------------
  def draw_actor_face(actor, x, y, active = false, type = 0, mirror = false, custom_rect = nil)
    data_actor = $data_actors[actor.id]
    # Determine if actor is selected
    opacity = (active ? 255 : 128)
    # Set bitmap based on ko state
    if type == 1
      bitmap = (actor.hp <= 1 ? RPG::Cache.faces("#{data_actor.name}_KO") : RPG::Cache.faces("#{data_actor.name}"))
    else
      bitmap = (actor.hp <= 1 ? RPG::Cache.faces("#{data_actor.name}_MM_KO") : RPG::Cache.faces("#{data_actor.name}_MM"))   
    end
    # If mirrored
    if mirror
      bitmap = RPG::Cache.faces("#{data_actor.name}_MM_Flip")
    end
    cw = bitmap.width
    ch = bitmap.height
    src_rect = Rect.new(0, 0, cw, ch)
    if custom_rect
      src_rect = custom_rect
    end
    self.contents.blt(x, y, bitmap, src_rect, opacity)
  end    
  #--------------------------------------------------------------------------
  # * Draw Name
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #--------------------------------------------------------------------------
  def draw_actor_name(actor, x, y)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 128, 32, actor.name, ALIGN_LEFT)
  end
  #--------------------------------------------------------------------------
  # * Draw Class
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #--------------------------------------------------------------------------
  def draw_actor_class(actor, x, y)
    self.contents.font.color = normal_color
    self.contents.draw_text(x, y, 236, 32, actor.class_name)
  end
  #--------------------------------------------------------------------------
  # * Draw Level
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #--------------------------------------------------------------------------
  def draw_actor_level(actor, x, y)
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 32, 32, "Lv")
    self.contents.font.color = normal_color
    # Special case for Azel
    actor.id == 5 ? level = "??" : level = actor.level.to_s
    self.contents.draw_text(x + 32, y, 24, 32, level, ALIGN_RIGHT)
  end
  #--------------------------------------------------------------------------
  # * Make State Text String for Drawing
  #     actor       : actor
  #     width       : draw spot width
  #     need_normal : Whether or not [normal] is needed (true / false)
  #--------------------------------------------------------------------------
  def make_battler_state_text(battler, width, need_normal)
    # Get width of brackets
    brackets_width = self.contents.text_size("[]").width
    # Make text string for state names
    text = ""
    for i in battler.states
      if $data_states[i].rating >= 1
        if text == ""
          text = $data_states[i].name
        else
          new_text = text + "/" + $data_states[i].name
          text_width = self.contents.text_size(new_text).width
          if text_width > width - brackets_width
            break
          end
          text = new_text
        end
      end
    end
    # If text string for state names is empty, make it [normal]
    if text == ""
      if need_normal
        text = "[Normal]"
      end
    else
      # Attach brackets
      text = "[" + text + "]"
    end
    # Return completed text string
    return text
  end
  #--------------------------------------------------------------------------
  # * Draw State (Icons, by Blizz)
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #     width : draw spot width
  #--------------------------------------------------------------------------
  def draw_actor_state(actor, x, y, width = 120)
    if actor != nil
      # actor.states.each {|id|
      #     if SPECIAL_EFFECTS.include?(id)
      #       text = "[#{$data_states[id].name}]"
      #       self.contents.font.color = actor.dead? ? knockout_color : normal_color
      #       self.contents.draw_text(x, y, width, 32, text)
      #       return
      #     end}
      s = actor.states.find_all {|id| $data_states[id].rating > 0}
      #check if in battle, draw 12x12 _st icons if so
      s.each_index {|i|
      break if i > 9
      icon = RPG::Cache.icon("State/#{$data_states[s[i]].name}")
      self.contents.blt(x+2+i*28, y+4, icon, Rect.new(0, 0, 24, 24))} 
    end
  end
  #--------------------------------------------------------------------------
  # * Draw bar graphic
  # current_val: what value is the bar at (for filled amount)
  # max_val: what value is the bar at its max
  # x / y: coordinates
  # graphic_name = Bar graphic name
  # max rows = number of rows on the graphic (3 usually means special highlighting for full bars)
  #-------------------------------------------------------------------------- 
  def blt_bar_graphic(x, y, current_val, max_val, graphic_name, max_rows = 3)
    skin = RPG::Cache.system(graphic_name)
    # Set vars
    width = skin.width
    height = skin.height / max_rows # Three rows on the sheet
    back_rect = Rect.new(0, 0, width, height)
    # Grab the 3rd row of the sheet for maximum value (brighter)
    if max_rows > 2
      row = (current_val == max_val ? 2 : 1)
    end
    amount = 100 * current_val / max_val
    # Generate the rect based on the values
    front_rect = Rect.new(0, row * height, width * amount / 100, height)
    # Block transfer
    self.contents.blt(x, y, skin, back_rect)
    self.contents.blt(x, y, skin, front_rect)
  end
  #--------------------------------------------------------------------------
  # * Draw an actors HP bar (0 short, 1 long)
  #--------------------------------------------------------------------------  
  def draw_actor_hp(actor, x, y, size = 1)
    # Set coordinates
    bar_x = x 
    bar_y = y + (Font.default_size * 2 / 3) + 4
    # Get graphic
    # Could do something like "#{type}Meter#{size}" in the future. 
    # For now, keep it compatible.
    if $game_temp.in_battle
      graphic_name = "MeterHPSmall"
      bar_width = SMALL_BAR_W
    else
      graphic_name = size == 0 ? "MeterHPMini" : "MeterHP"
      bar_width = size == 0 ? MINI_BAR_W : FULL_BAR_W
    end
    # Values
    current_val = actor.hp
    max_val = actor.maxhp
    # Draw bar
    blt_bar_graphic(bar_x, bar_y, current_val, max_val, graphic_name)
    # Draw everything differently if in battle
    if $game_temp.in_battle
      # Draw "SP" text string
      self.contents.font.bold = true
      self.contents.font.size = Font.scale_size(80)
      self.contents.font.color = system_color
      self.contents.font.name = Font.default_name
      self.contents.draw_text(x + 10, y, 32, 32, '&MUI[LEMini]')
      self.contents.font.color = normal_color
      self.contents.font.bold = false
      self.contents.font.name = Font.numbers_name
      # shorten number width
      hp_x = x + bar_width - 88
      # Draw sp
      self.contents.font.color = actor.hp == 0 ? knockout_color :
      actor.hp <= actor.maxhp / 4 ? crisis_color : normal_color
      self.contents.draw_text(hp_x, y, 38, 32, actor.hp.to_s, ALIGN_RIGHT)
      # Draw Maxsp
      self.contents.font.color = normal_color
      self.contents.draw_text(hp_x + 38, y, 12, 32, "/", ALIGN_CENTER)
      self.contents.draw_text(hp_x + 50, y, 38, 32, actor.maxhp.to_s)
      return
    end
    # Draw "HP" text string
    self.contents.font.name = Font.default_name
    self.contents.font.color = system_color
    self.contents.font.bold = true
    # Draw numbers & determine bar graphic
    case size 
      when 0 # short
        self.contents.draw_text(x + 10, y, 32, 32, '&MUI[LEMini]')
        self.contents.font.bold = false
        self.contents.font.name = Font.numbers_name
        # shorten number width
        hp_x = x + bar_width - 88
        # Draw hp
        self.contents.font.color = actor.hp == 0 ? knockout_color :
        actor.hp <= actor.maxhp / 4 ? crisis_color : normal_color
        self.contents.draw_text(hp_x, y, 38, 32, actor.hp.to_s, ALIGN_RIGHT)
        # Draw Maxhp
        self.contents.font.color = normal_color
        self.contents.draw_text(hp_x + 38, y, 12, 32, "/", ALIGN_CENTER)
        self.contents.draw_text(hp_x + 50, y, 38, 32, actor.maxhp.to_s)
      when 1 # wide
        self.contents.draw_text(x + 12, y - 4, 140, 32, '&MUI[LEShort]')
        self.contents.font.bold = false
        self.contents.font.name = Font.numbers_name
        # Draw hp
        self.contents.font.color = actor.hp == 0 ? knockout_color :
        actor.hp <= actor.maxhp / 4 ? crisis_color : normal_color
        self.contents.draw_text(x + 104, y - 4, 68, 32, actor.hp.to_s, ALIGN_RIGHT)
        # Draw Maxhp
        self.contents.font.color = normal_color
        self.contents.draw_text(x + 174, y - 4, 12, 32, "/", ALIGN_CENTER)
        self.contents.draw_text(x + 186, y - 4, 48, 32, actor.maxhp.to_s) 
    end 
  end
  #--------------------------------------------------------------------------
  # * Draw an actors SP bar (0 short, 1 long)
  #--------------------------------------------------------------------------  
  def draw_actor_sp(actor, x, y, size = 1)
    # Handling for width-based 
    size = 1 if size > 1
    # Set coordinates
    bar_x = x 
    bar_y = y + (Font.default_size * 2 /3) + 4
    # Get graphic
    # Could do something like "#{type}Meter#{size}" in the future. 
    # For now, keep it compatible.
    if $game_temp.in_battle
      graphic_name = "MeterSPSmall"
      bar_width = SMALL_BAR_W
    else
      graphic_name = size == 0 ? "MeterSPMini" : "MeterSP"
      bar_width = size == 0 ? MINI_BAR_W : FULL_BAR_W
    end
    # Values
    current_val = actor.sp
    max_val = actor.maxsp
    # Draw bar
    blt_bar_graphic(bar_x, bar_y, current_val, max_val, graphic_name)
    # Draw everything differently if in battle
    if $game_temp.in_battle
      # Draw "SP" text string
      self.contents.font.bold = true
      self.contents.font.size = Font.scale_size(80)
      self.contents.font.color = system_color
      self.contents.font.name = Font.default_name
      self.contents.draw_text(x + 10, y, 32, 32, '&MUI[MEMini]')
      self.contents.font.color = normal_color
      self.contents.font.bold = false
      self.contents.font.name = Font.numbers_name
      # shorten number width
      sp_x = x + bar_width - 88
      # Draw sp
      self.contents.font.color = actor.sp == 0 ? knockout_color :
      actor.sp <= actor.maxsp / 4 ? crisis_color : normal_color
      self.contents.draw_text(sp_x, y, 38, 32, actor.sp.to_s, ALIGN_RIGHT)
      # Draw Maxsp
      self.contents.font.color = normal_color
      self.contents.draw_text(sp_x + 38, y, 12, 32, "/", ALIGN_CENTER)
      self.contents.draw_text(sp_x + 50, y, 38, 32, actor.maxsp.to_s)
      return
    end
    # Draw "HP" text string
    self.contents.font.name = Font.default_name
    self.contents.font.bold = true
    self.contents.font.color = system_color
    # Draw numbers & determine bar graphic
    case size 
      when 0 # short
        self.contents.draw_text(x + 10, y, 32, 32, '&MUI[MEMini]')
        self.contents.font.bold = false
        self.contents.font.name = Font.numbers_name
        # shorten number width
        sp_x = x + bar_width - 88
        # Draw sp
        self.contents.font.color = actor.sp == 0 ? knockout_color :
        actor.sp <= actor.maxsp / 4 ? crisis_color : normal_color
        self.contents.draw_text(sp_x, y, 38, 32, actor.sp.to_s, ALIGN_RIGHT)
        # Draw Maxsp
        self.contents.font.color = normal_color
        self.contents.draw_text(sp_x + 38, y, 12, 32, "/", ALIGN_CENTER)
        self.contents.draw_text(sp_x + 50, y, 38, 32, actor.maxsp.to_s)
      when 1 # wide
        self.contents.draw_text(x + 12, y - 4, 140, 32, '&MUI[MEShort]')
        self.contents.font.bold = false
        self.contents.font.name = Font.numbers_name
        # Draw sp
        self.contents.font.color = actor.sp == 0 ? knockout_color :
        actor.sp <= actor.maxsp / 4 ? crisis_color : normal_color
        self.contents.draw_text(x + 104, y - 4, 68, 32, actor.sp.to_s, ALIGN_RIGHT)
        # Draw Maxsp
        self.contents.font.color = normal_color
        self.contents.draw_text(x + 174, y - 4, 12, 32, "/", ALIGN_CENTER)
        self.contents.draw_text(x + 186, y - 4, 48, 32, actor.maxsp.to_s) 
    end  
  end
  #--------------------------------------------------------------------------
  # * Draw an actors EXP bar
  #--------------------------------------------------------------------------  
  def draw_actor_exp(actor, x, y)
    bar_x = x
    bar_y = y + (Font.default_size * 2 /3) + 4
    graphic_name = 'MeterEXP'
    current_val = actor.now_exp
    max_val = actor.next_exp
    blt_bar_graphic(bar_x, bar_y, current_val, max_val, graphic_name)
    self.contents.font.bold = true
    self.contents.font.color = system_color
    self.contents.font.name = Font.default_name
    self.contents.draw_text(x + 12, y - 4, 84, 32, "Next Lv", ALIGN_LEFT)
    self.contents.draw_text(x + 76, y - 4, 12, 32, ":", ALIGN_LEFT)
    self.contents.font.bold = false
    self.contents.font.color = normal_color
    self.contents.font.name = Font.numbers_name
    self.contents.draw_text(x + 140, y - 4, 84, 32, actor.next_rest_exp_s, ALIGN_RIGHT)
  end
  #--------------------------------------------------------------------------
  # * Draw an actors Fury bar
  #--------------------------------------------------------------------------  
  def draw_actor_fury(actor, x, y)
    bar_x = x
    bar_y = y + (Font.default_size * 2 /3) + 4
    current_val = actor.overdrive
    max_val = actor.max_overdrive
    graphic_name = $game_temp.in_battle ? 'MeterODSmall' : 'MeterOD'    
    blt_bar_graphic(bar_x, bar_y, current_val, max_val, graphic_name)
    self.contents.font.color = system_color
    self.contents.font.name = Font.default_name
    self.contents.font.bold = true
    self.contents.draw_text(x + 12, y, 84, 32, '&MUI[StatUnleash]')
    self.contents.font.bold = false
    self.contents.font.color = normal_color
    self.contents.font.name = Font.numbers_name
    amount = 100 * actor.overdrive / actor.max_overdrive
    if $game_temp.in_battle
      self.contents.draw_text(x + 82, y, 60, 32, "#{amount}%", ALIGN_RIGHT)
    else
      self.contents.draw_text(x + 142, y - 4, 84, 32, "#{amount}%", ALIGN_RIGHT)
    end
  end
  #--------------------------------------------------------------------------
  # * Draw Parameter
  #     actor : actor
  #     x     : draw spot x-coordinate
  #     y     : draw spot y-coordinate
  #     type  : parameter type (0-6)
  #--------------------------------------------------------------------------
  def draw_actor_parameter(actor, x, y, type)
    case type
    when 0
      parameter_name = $data_system.words.atk
      parameter_value = actor.atk
    when 1
      parameter_name = $data_system.words.pdef
      parameter_value = actor.pdef
    when 2
      parameter_name = $data_system.words.mdef
      parameter_value = actor.mdef
    when 3
      parameter_name = $data_system.words.str
      parameter_value = actor.luk
    when 4
      parameter_name = $data_system.words.dex
      parameter_value = actor.dex
    when 5
      parameter_name = $data_system.words.agi
      parameter_value = actor.agi
    when 6
      parameter_name = $data_system.words.int
      parameter_value = actor.int
    end
    self.contents.font.color = system_color
    self.contents.draw_text(x, y, 120, 32, parameter_name)
    self.contents.font.color = normal_color
    self.contents.draw_text(x + 120, y, 36, 32, parameter_value.to_s, ALIGN_RIGHT)
  end
  #--------------------------------------------------------------------------
  # * Draw Actor Battle Sprite
  #     actor    : actor
  #     viewport : vp sprite is bound to
  #   Returns a sprite object which can then be managed via update
  #--------------------------------------------------------------------------
  def draw_actor_battler(actor, viewport, type=:idle)
    sprite = RPG::Sprite.new(viewport)
    actor_name = $data_actors[actor.id].name
    sprite.zoom_x = 2.0
    sprite.zoom_y = 2.0
    sprite.bitmap = 
      case type
      when :skill
        RPG::Cache.battler("#{actor_name}_Skill", 0)
      else
        RPG::Cache.battler("#{actor_name}_Idle", 0)
      end
    # Offset sprite
    case actor.id
    when 5 # Azel
      sprite.x = -56
      sprite.y = 0
    when 2 # Sarina
      sprite.x = -108
      sprite.y = -64
    when 3 # Arlyn
      sprite.x = type == :idle ? -108 : -56
      sprite.y = -64
    end
    sprite
  end
  #--------------------------------------------------------------------------
  # * Draw Any Battle Sprite
  #     battler  : battler
  #     viewport : vp sprite is bound to
  #   Returns a sprite object which can then be managed via update
  #--------------------------------------------------------------------------
  def draw_battler_sprite(x, y, battler, rect_w=64, type=:idle)
    name = battler.actor? ? $data_actors[battler.id].name : $data_enemies[battler.id].name
    sbitmap = 
      case type
      when :skill
        RPG::Cache.battler("#{name}_Skill", 0).dup
      else
        RPG::Cache.battler("#{name}_Idle", 0).dup
      end
    sbitmap.goto_and_stop(0)
    rx, ry = GUtil.find_center_coords(rect_w,rect_w,sbitmap.width,sbitmap.height)
    rect = Rect.new(-rx,-ry,rect_w,rect_w)
    self.contents.fill_rect(x, y, rect_w, rect_w, Color.new(0,0,0,75))
    self.contents.blt(x, y, sbitmap, rect)
  end
  #--------------------------------------------------------------------------
  # * Draw an item in a list
  #     x   : draw spot x-coordinate
  #     y   : draw spot y-coordinate
  #     obj : item to draw (RPG::Item, ::Armor, ::Weapon, ::Essence)
  #     w   : list width
  #     h   : list height
  #--------------------------------------------------------------------------
  def draw_list_item(obj, x, y, w, h, color = WHITE_COLOR, icon_opacity = 255, bg_color = nil)
    if obj == nil
      return
    end
    if bg_color
      self.contents.fill_rect(Rect.new(x, y, w, h), bg_color)
    end
    draw_icon(x, y, h, obj.icon_name, icon_opacity)
    self.contents.font.name = Font.numbers_name
    self.contents.font.size = Font.default_size
    self.contents.font.color = color
    self.contents.draw_text(x + 28, y, w, h, obj.loc_name)
  end
  #------------------------------------------------------------------------------
  # * Draw Even Text
  # Modified method by blizzard
  #--------------------------------------------------------------------------
  # width : width of text to be drawn
  # height : height of single line to be repeated when drawn
  # align : text alignment
  #------------------------------------------------------------------------------
  def draw_even_text(x, y, width, height, text, align = ALIGN_LEFT)
    # Localize first
    text = Localization.localize(text)
    # Replace all instances of \v[n] to the game variable's value
    text.gsub!(/\\[Vv]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
    text.gsub!(/[\V\v]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
    # Break up the text into lines
    if text["\n"] != nil
      lines = text.split("\n") 
    else
      lines = text.split("\\n")
    end
    result = []
    # For each line generated from \n
    lines.each{|text_line|
      # Divide text into each individual word
      divider = Localization.culture == :jp ? '' : ' '
      words = text_line.split(divider)
      current_text = words.shift
      # If there were less than two words in that line, just push the text
      if words.empty?
        result.push(current_text == nil ? "" : current_text)
        next
      end
      # Evaluate each word and determine when text overflows to a new line
      words.each_index {|i|
        check = Localization.culture == :jp ? "#{current_text}#{words[i]}" : "#{current_text} #{words[i]}"
        if self.contents.text_size(check).width + 2 > width
          result.push(current_text)
          current_text = words[i]
        else
          current_text = check
        end
        result.push(current_text) if i >= words.size - 1
      }
    }
    # Draw results to the window
    result.each_index do |i|
      self.contents.draw_text(x, y + i*height, width, height, result[i], align)
    end
  end
  attr_accessor :grid_columns
  attr_accessor :grid_rows
  attr_accessor :row_height
  attr_accessor :column_width
  #------------------------------------------------------------------------------
  # * Setup grid
  # Values for easier placement of elements
  #------------------------------------------------------------------------------
  def setup_grid(columns: 1, rows: 1)
    @grid_columns = columns # Double-check Window_Selectable on this
    @grid_rows = rows
    @row_height = contents_height / [rows, 1].max
    @column_width = contents_width / [columns, 1].max
  end
  #------------------------------------------------------------------------------
  # * Column Span
  # Get the width of num columns
  #------------------------------------------------------------------------------
  def col_span(num)
    num * @column_width
  end
  #------------------------------------------------------------------------------
  # * Row Span
  # Get the height of num rows
  #------------------------------------------------------------------------------
  def row_span(num)
    num * @row_height
  end
  #------------------------------------------------------------------------------
  # * Draw Icon
  # Emplying DRY to avoid retyping for icons constantly
  # row_height: used for centering the icon horizontally
  # magnify : amount to magnify the icon's size (2, 3, 4 = 2x, 3x, 4x, etc.)
  #--------------------------------------------------------------------------
  def draw_icon(x, y, row_height, filename, opacity = 255, magnify = 1, bg_color = nil)
    unless self.contents
      GUtil.write_log("Tried to draw icon onto nil contents! #{self.inspect}")
      return
    end
    bitmap = RPG::Cache.icon(filename)
    w = bitmap.width * magnify
    h = bitmap.height * magnify
    # Center the icon horizontally (N/A to magnified iocns)
    y_offset = (row_height - h) / 2
    if bg_color
      self.contents.fill_rect(Rect.new(x, y_offset + y, w, h), bg_color)
    end
    init_rect = Rect.new(0, 0, bitmap.width, bitmap.height)
    if magnify > 1
      dest_rect = Rect.new(x, y, w, h)
      self.contents.stretch_blt(dest_rect, bitmap, init_rect, opacity)
    else
      self.contents.blt(x, y_offset + y, bitmap, init_rect, opacity)
    end
  end
  #------------------------------------------------------------------------------
  # * Draw States
  # Type: either, :plus, :minus, or :element
  # obj: Should be skill, item, weapon, or armor
  #--------------------------------------------------------------------------
  def draw_state_icons(x, y, row_height, obj, type, spacing = 28, vertical = false)
    state_ids = 
      case type
      when :plus
        obj.plus_state_set
      when :minus
        obj.is_a?(RPG::Armor) ? obj.guard_state_set : obj.minus_state_set
      when :element
        obj.is_a?(RPG::Armor) ? obj.guard_element_set : obj.element_set
      end
    state_ids.each_with_index do |id, index|
      state = $data_states[id]
      next if state.nil?
      if vertical
        y = y + index * spacing
      else
        x = x + index * spacing
      end
      draw_icon(x, y, row_height, state.icon_name)
    end
  end
  #------------------------------------------------------------------------------
  # * Draw Parameters (Stats)
  # Draws stats for a given object (excludes attack)
  # x/y - start position
  # obj - Actor, Weapon or Armor
  # cols - column restraint
  # x/y_spacing - amount to space elements apart
  # name - draw name next to the stat
  # compare_obj - Object to compare to (for equipping, etc.)
  #--------------------------------------------------------------------------
  def draw_parameters(sx, sy, obj, cols, x_spacing = 74, y_spacing = 26, draw_name = false, compare_obj = nil)
    # This changes based on the columns
    params = 
      if cols == 3
        [:pdef,:dex,:agi,:mdef,:int,:str]
      else
        [:pdef,:mdef,:dex,:int,:agi,:str]
      end
    params.each_with_index do |param, index|
      x, y = GUtil.xy_grid_coordinates(sx, sy, index, cols, x_spacing, y_spacing)
      draw_single_parameter(x, y, x_spacing, y_spacing, obj, param, false, compare_obj)
    end
  end
  #------------------------------------------------------------------------------
  # * Draw Single Parameter (Stat)
  # name - draw name next to the stat
  # compare_obj - Object to compare to (for equipping, etc.)
  #--------------------------------------------------------------------------
  def draw_single_parameter(x, y, width, height, obj, param, draw_name = false, compare_obj = nil)
    self.contents.font.name = Font.numbers_name
    self.contents.font.size = Font.scale_size(60)
    self.contents.font.color = normal_color
    value = parameter_value(obj, param)
    if compare_obj
      if (obj.is_a?(Game_Actor) && !obj.equippable?(compare_obj))
        compare_value = "---"
      else
        compare_value = parameter_value(compare_obj, param)
      end
    end
    name = 
      if [:maxhp, :maxsp].include?(param)
        param == :maxhp ? "&MUI[LEMini]" : "&MUI[MEMini]" 
      else
        $data_system.words.send(param)
      end
    icon = "Menu/#{name}"
    if draw_name # Needs testing
      self.contents.draw_text(x, y, width, height, name, 0)
    end
    draw_icon(x, y, height, icon) unless [:maxhp, :maxsp].include?(param)
    # Draw stat value
    if compare_obj && !compare_value.is_a?(String)
      # Weapons and armors behave a little differently
      if compare_obj.is_a?(RPG::Weapon)
        if param == :atk
          if value > compare_value
            self.contents.font.color = RED_COLOR
          elsif compare_value > value
            self.contents.font.color = GREEN_COLOR
          else
            self.contents.font.color = normal_color
          end
          text = compare_value.to_s
        else
          self.contents.font.color = normal_color
          text = value.to_s
        end
      else
        if obj.is_a?(Game_Actor)
          old_value = value
          new_value = obj.send(param) + compare_value
        else
          old_value = value
          new_value = compare_value
        end
        if old_value > new_value
          self.contents.font.color = RED_COLOR
        elsif new_value > old_value
          self.contents.font.color = GREEN_COLOR
        else
          self.contents.font.color = normal_color
        end
        text = new_value.to_s
      end
    else
      self.contents.font.color = normal_color
      text = compare_obj ? compare_value : value
    end
    self.contents.draw_text(x, y, width - 4, height, text, 2)
  end
  #------------------------------------------------------------------------------
  # * Get parameter value for object
  #--------------------------------------------------------------------------
  def parameter_value(obj, param)
    if obj.respond_to?("base_#{param}") # actors
      obj.send("base_#{param}")
    elsif obj.respond_to?("#{param}_plus") # everything else
      obj.send("#{param}_plus")
    elsif obj.respond_to?(param) # mdef/pdef
      obj.send(param)
    elsif (obj.is_a?(RPG::Armor) && param == :atk) ||
        (obj.is_a?(RPG::Weapon) && [:maxhp, :maxsp].include?(param))

      "---"
    else
      puts "Tried to get param #{param} for invalid obj #{obj}"
    end
  end
end