#==============================================================================
# ** Game_Event
#------------------------------------------------------------------------------
#  This class deals with events. It handles functions including event page 
#  switching via condition determinants, and running parallel process events.
#  It's used within the Game_Map class.
#==============================================================================

class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :list                     # list of event commands
  #--------------------------------------------------------------------------
  # Event Trigger
  # 0: Action Button - The player presses a button while in range to activate
  # 1: Activate On Delay (Touch) - Activated after the player presses
  # against the object for a set amount of time. Action button forbidden.
  # Also disables sliding around objects on collision.
  # 2: Activate On Collision - Activates once the player collides with the
  # the object. Cannot be triggered again until the player is out of a range
  # greater than the original object collision box. 
  # 3: Autorun - Same as vanilla RMXP
  # 4: Parallel process - Same as vanilla RMXP
  #--------------------------------------------------------------------------
  attr_reader   :trigger                  
  attr_reader   :starting            # starting flag
  attr_accessor :push_block          # Event that responds to pushing
  # Dungeon enemies
  attr_accessor :enemy_moved         # Flag to determine enemy moved one step
  attr_reader   :page                # Reader for page property
  attr_accessor :opacity             # Allows page graphic opacity to be get/set
  # Pixel Movement
  attr_accessor :tile_col_set        # Determines if an event's tile ID has had its collision set
  attr_accessor :trigger_on          # A flag that is toggled to prevent rapid double-activation of a touch event
  attr_accessor :triggering_event_id # A linked event used to determine the trigger toggle
  attr_accessor :erased
  attr_reader   :check_pass_height   # Flag to determine if the event cannot be triggered at different heights
  attr_accessor :hide_graphic        # Overrides sprite visibility - used for events only visible in editor
  attr_accessor :turn_on_trigger     # Flag to turn character towards event when triggered
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     map_id : map ID
  #     event  : event (RPG::Event)
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
    super()
    @map_id = map_id
    @event = event
    @id = @event.id
    @erased = false
    @starting = false
    @through = true
    @enemy_moved = false
    @push_block = false
    @tile_col_set = 0
    # Flag to determine if the player is currently triggering a touch event (2)
    @trigger_on = true 
    @triggering_event_id = nil
    @check_pass_height = false
    @turn_on_trigger = true
    # Z index related
    @z_flat = false
    @z_add = 0
    @hide_graphic = false
    check_flat_sprites(event)
    # Load default event size
    create_event_hitbox
    # Move to starting position
    # Subtract 1 from Y value due to a weird off-by-1 error
    moveto(@event.x * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE/2 - 1, @event.y * Game_Map::TILE_SIZE + Game_Map::TILE_SIZE - 1)
    # Extra setup based on name
    setup_event_template
    refresh
    # Foot forward checks
    check_no_auto_ff(event)
    check_no_mc(event)
  end
  #--------------------------------------------------------------------------
  # * Get Name
  #--------------------------------------------------------------------------
  def name
    return @event.name
  end
  #--------------------------------------------------------------------------
  # * Set trigger
  #--------------------------------------------------------------------------
  def trigger=(n)
    @trigger = n
  end
  #--------------------------------------------------------------------------
  # * Set through
  #--------------------------------------------------------------------------
  def through=(bool)
    @through = bool
  end
  #--------------------------------------------------------------------------
  # * Starting Determinent
  #--------------------------------------------------------------------------
  def starting?
    @starting
  end
  #--------------------------------------------------------------------------
  # * Clear Starting Flag
  #--------------------------------------------------------------------------
  def clear_starting
    @starting = false
  end
  #--------------------------------------------------------------------------
  # Check for no Auto Foot Forward Off - In the event of Animation Problems...
  #--------------------------------------------------------------------------
  def check_no_auto_ff(event)
    event.name.gsub(/\\no_ff/i) {@no_ff = true}
  end
  #--------------------------------------------------------------------------
  # Check for no MC - 'M'ove 'C'ontinue - Restores Original Move Route...
  #--------------------------------------------------------------------------
  def check_no_mc(event)
    event.name.gsub(/\\no_mc/i) {@no_mc = true}
  end
  #--------------------------------------------------------------------------
  # * Determine if Over Trigger
  # Events without graphics are through by default
  #--------------------------------------------------------------------------
  def over_trigger?
    # If a nonpassable tile
    if @character_name == "" && @tile_id >= 384 && !@through
      return false
    end
    # If not through situation with character as graphic
    if @character_name != "" && !@through
      return false
    end
    # # If this position on the map is impassable
    # if !$game_map.pixel_passable?(@x, @y, self)
    #   puts "over trigger not passable"
    #   return false
    # end
    # Starting determinant is same position
    return true
  end
  #--------------------------------------------------------------------------
  # * Start Event
  #--------------------------------------------------------------------------
  def start
    # Event was triggered by the player
    if @trigger == 0 && !@through && @triggering_event_id == 0 # Action button
      # Turn the player towards this event
      $game_player.turn_toward_event(@id) if @turn_on_trigger
      @triggering_event_id = nil
    end
    # Flag that the event has been triggered (for touch events)
    @trigger_on = true
    # If list of event commands is not empty
    if @list.size > 1
      @starting = true
    end
  end
  #--------------------------------------------------------------------------
  # * Temporarily Erase
  #--------------------------------------------------------------------------
  def erase
    @erased = true
    refresh
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    # Initialize local variable: new_page
    new_page = nil
    # If not temporarily erased
    unless @erased
      # Check in order of large event pages
      for page in @event.pages.reverse
        # Make possible referrence for event condition with c
        c = page.condition
        # Switch 1 condition confirmation
        if c.switch1_valid
          if $game_switches[c.switch1_id] == false
            next
          end
        end
        # Switch 2 condition confirmation
        if c.switch2_valid
          if $game_switches[c.switch2_id] == false
            next
          end
        end
        # Variable condition confirmation
        if c.variable_valid
          if $game_variables[c.variable_id] < c.variable_value
            next
          end
        end
        # Self switch condition confirmation
        if c.self_switch_valid
          key = [@map_id, @event.id, c.self_switch_ch]
          if $game_self_switches[key] != true
            next
          end
        end
        # Custom page script condition
        if script_condition_valid?(page)
          if check_script_condition(page) == false
            next
          end
        end
        # Set local variable: new_page
        new_page = page
        # Remove loop
        break
      end
    end
    # If event page is the same as last time
    if new_page == @page
      # End method
      return
    end
    # Set @page as current event page
    @page = new_page
    # Clear starting flag
    clear_starting
    # If no page fulfills conditions
    if @page == nil
      # Set each instance variable
      @tile_id = 0
      @character_name = ""
      @character_hue = 0
      @move_type = 0
      @through = true
      @trigger = nil
      @list = nil
      @interpreter = nil
      @triggering_event_id = nil
      @trigger_on = false
      @shadow = false
      @light[:name] = ""
      # End method
      return
    end
    # Set each instance variable
    @tile_id = @page.graphic.tile_id
    @character_name = @page.graphic.character_name
    @character_hue = @page.graphic.character_hue
    if @original_direction != @page.graphic.direction
      @direction = @page.graphic.direction
      @original_direction = @direction
      @prelock_direction = 0
    end
    if @original_pattern != @page.graphic.pattern
      @pattern = @page.graphic.pattern
      @original_pattern = @pattern
    end
    @opacity = @page.graphic.opacity
    @blend_type = @page.graphic.blend_type
    @move_type = @page.move_type
    @move_speed = @page.move_speed
    @move_frequency = @page.move_frequency
    @move_route = @page.move_route
    @move_route_index = 0
    @move_route_forcing = false
    @walk_anime = @page.walk_anime
    @step_anime = @page.step_anime
    @direction_fix = @page.direction_fix
    @through = @page.through
    @always_on_top = @page.always_on_top
    @trigger = @page.trigger
    @list = @page.list
    @interpreter = nil
    @triggering_event_id = nil
    @trigger_on = false
    # Initial sprite reset
    @shadow = false
    @light[:name] = ""
    sprite_reset
    # Setup pixel movement settings
    apply_pm_settings
    # Setup placeholder graphic
    check_placeholder_graphic
    # Override opacity if necessary
    check_hidden_graphic
    @opacity = 0 if @hide_graphic
    # If trigger is [parallel process]
    if @trigger == 4
      # Create parallel process interpreter
      @interpreter = Interpreter.new
    end
    # Auto event start determinant
    check_event_trigger_auto
  end
  #-----------------------------------------------------------------------------
  # * Block for returning each comment in an event page
  #-----------------------------------------------------------------------------
  def comments
    i = 0
    # Loop in page
    while @page != nil && @page.list[i] != nil && (@page.list[i].code == 108 || @page.list[i].code == 408)
      yield @page.list[i].parameters[0]
      i += 1
    end
  end
  #-----------------------------------------------------------------------------
  # * Check comments for change to Pixel Movement related settings
  #-----------------------------------------------------------------------------
  def apply_pm_settings 
    # If the page is valid
    if @page != nil && @page.list != nil
      # Load Comments
      self.comments do |comment_check|
        # Check event teleport
        if comment_check.downcase.include?('teleport:')
          bla = comment_check.split(':')[1].split(',')
          self.moveto(bla[0].to_i,bla[1].to_i)
        # Check standing frame order
        elsif comment_check.downcase.include?('stand_order:')
          @stand_frame_order=comment_check.split(':')[1].split(',')
          @stand_frame_order.collect! {|y| y.to_i}
        # Check moving frame order
        elsif comment_check.downcase.include?('frame_order:')
          @frame_order = comment_check.split(':')[1].split(',')
          @frame_order.collect! {|x| x.to_i}
        # ???
        elsif comment_check.downcase.include?('frame_number:')
          numframes = comment_check.split(':')[1].to_i
          @frame_order = []
          for i in 1..numframes
            @frame_order << i
          end
        # Check standing frame speed
        elsif comment_check.downcase.include?('frame_speed:')
          @frame_speed = comment_check.split(':')[1].to_i
        # Check moving stand speed
        elsif comment_check.downcase.include?('stand_speed:')
          @stand_frame_speed = comment_check.split(':')[1].to_f
        # Check order of directions
        elsif comment_check.downcase.include?('direction_order:')
          @direction_order = comment_check.split(':')[1].split(',')
          @direction_order.collect! {|z| z.to_i}
        # Check event graphic x shift
        elsif comment_check.downcase.include?('shift_x:')
          @shift_x = comment_check.split(':')[1].to_i
        # Check event graphic y ship
        elsif comment_check.downcase.include?('shift_y:')
          @shift_y = comment_check.split(':')[1].to_i
        # Check collide type change
        elsif comment_check.downcase.include?('collide_type:')
          @collide_type = comment_check.split(':')[1].strip.to_sym
        # Check if the event should have a different passability height. If not, match the players
        elsif comment_check.downcase.include?('pass_height:')
          @pass_height = comment_check.split(':')[1].strip.to_i
          @check_pass_height = true
        # Shadow and light options -- here for now because its easier
        elsif comment_check.downcase.include?('shadow:')
          @shadow = comment_check.downcase.split(':')[1].strip == "true" ? true : false
          sprite_reset
        elsif comment_check.downcase.include?('shadow_offset:')
          x, y = comment_check.split(':')[1].strip.split(',')
          @shadow_offset = [x.to_i, y.to_i]
          sprite_reset
        # TODO: Clean up
        elsif comment_check.downcase.include?('light:')
          file = comment_check.split(':')[1].strip
          @light[:name] = file
          sprite_reset
        elsif comment_check.downcase.include?('light_size:')
          x, y = comment_check.split(':')[1].strip.split(',')
          @light[:size] = [x.to_i, y.to_i]
          sprite_reset
        elsif comment_check.downcase.include?('light_offset:')
          x, y = comment_check.split(':')[1].strip.split(',')
          @light[:offset] = [x.to_i, y.to_i]
          sprite_reset
        elsif comment_check.downcase.include?('light_opacity:')
          op = comment_check.downcase.split(':')[1].strip
          @light[:opacity] = op.to_i
          sprite_reset
        elsif comment_check.downcase.include?('light_anim:')
          an = comment_check.downcase.split(':')[1].strip
          @light[:animation] = an.to_sym
          sprite_reset
        end
        #jump_tile = comment_check.include?('JUMP_TILE')
        # Flag jump tiles
        if comment_check.include?('JUMP_TILE')
          unless $game_map.jump_tiles.include?(self)
            $game_map.jump_tiles << self
          end
        else
          unless $game_map.jump_tiles.include?(self)
            $game_map.jump_tiles.delete(self)
          end
        end
        $game_map.jump_tiles.compact!
      end
      # Set standing frame order
      @stand_frame_order = [] if @stand_frame_order == [0]
      #---------------------------------------------------------------------------
      # Update bounding box coords
      update_bounding_coords
      # Recreate collision circle
      create_collision_circle
      #---------------------------------------------------------------------------
      # Check for event size override (Now a percentage of a tile instead)
      self.comments do |comment_check|
        if comment_check.downcase.include?('event_size:')
          size_percent = comment_check.split(':')[1].split(',')
          # Rect
          if !size_percent[1].nil? 
            w, h = size_percent
          # Square
          else
            w = h = size_percent[0]
          end
          resize_hitbox(w, h)
          # No need to continue searching
          break
        end
      end
    end
    # Setup step anime
    @step_anime = true if @stand_frame_order.length > 1 
  end
  #--------------------------------------------------------------------------
  # * Resize event hitbox using given percentage of a tile
  # i.e., 16x16 tiles, 100, 50 -> 16x8 hitbox
  #--------------------------------------------------------------------------
  def resize_hitbox(w, h = width)
    w = [Game_Map::TILE_SIZE * w.to_i / 100, 4].max
    h = [Game_Map::TILE_SIZE * h.to_i / 100, 4].max
    self.size_x = w
    self.size_y = h
    self.size_rad = w / 2
    update_bounding_coords
    create_collision_circle
  end
  #--------------------------------------------------------------------------
  # * Touch Event Starting Determinant
  #--------------------------------------------------------------------------
  # def check_event_trigger_touch(x, y)
  #   puts "EVENT"
  #   # If event is running
  #   if $game_system.map_interpreter.running?
  #     return
  #   end
  #   # Determine collision
  #   collision = 
  #     case @collide_type
  #     when :rect
  #       $game_player.in_rect?(self.bounding_box)
  #     when :circ
  #       $game_player.in_circle?(self.bounding_circ)
  #     else
  #       false
  #     end
  #   # If trigger is [touch from event] and consistent with player coordinates
  #   if @trigger == 2 && collision
  #     # If the event is not jumping, not on top of the player, and not already triggered once
  #     if !jumping? && over_trigger? && !@trigger_on
  #       @trigger_on = true
  #       start
  #     end
  #   end
  #   puts "---"
  # end
  #--------------------------------------------------------------------------
  # * Automatic Event Starting Determinant
  #--------------------------------------------------------------------------
  def check_event_trigger_auto
    # If trigger is [auto run] and an event isn't already running
    if @trigger == 3 && !$game_system.map_interpreter.running?
      start
    end
  end
  #--------------------------------------------------------------------------
  # * Checks if the configured switch is active, then ignores wait commands
  # Requires the current map for self switch management
  #--------------------------------------------------------------------------
  def release_move_switch?(map_id)
    key = [map_id, self.id, DungeonConfig::ANTI_WAIT_SWITCH]
    if !$game_self_switches[key].nil?
      return $game_self_switches[key]
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # MMW called for this at the top of Game_Character#update
    # but Pixel Movement uses it differently in Game_Player
    # For now, update here on Events.
    @last_real_x = @real_x
    @last_real_y = @real_y
    # Call superclass update method
    super
    # Automatic event starting determinant
    check_event_trigger_auto
    # If parallel process is valid
    if @interpreter != nil
      # If not running
      unless @interpreter.running?
        # Set up event
        @interpreter.setup(@list, @event.id)
      end
      # Update interpreter
      @interpreter.update
    end
    # If this event was triggered and the triggerer exists, determine if it is out of range and
    # Reset trigger (to prevent double activation of the same event)
    if @trigger_on && @triggering_event_id != nil && !@starting
      # Differentiate player
      trig_event = @triggering_event_id == 0 ? $game_player : $game_map.events[@triggering_event_id]
      # Branch by collision type
      if self.collide_type == :circ
        # We want to make sure the triggering event is a little outside
        # the actual bounding circle
        test_circ = self.bounding_circ.dup
        test_circ.radius *= 2
        if trig_event.collide_type == :circ
          inside = Collision.circ_in_circ?(trig_event.bounding_circ, test_circ)
        else
          inside = Collision.circ_in_rect?(test_circ, trig_event.bounding_box)
        end
        if !inside
          puts "RESET TRIGGER! (circ #{self.id})"
          # Disable saving if we're on a save event
          if self.name == "[CLONE]:1"
            puts "disabled saving game event"
            $game_system.save_disabled = true
          end
          @trigger_on = false
          @triggering_event_id = nil
        end
      else
        # FIXME - Consider storing this instead of recreating every time
        test_rect = self.bounding_box.dup
        # To account for long rects, we only want to double the length of the SHORT
        # side, and then increase the long side by the same amount. 
        # Note that events so long that they are off screen will be affected by anti-lag
        # and need to have /noeal in their name.
        tx = test_rect.x
        ty = test_rect.y
        tw = test_rect.width
        th = test_rect.height
        if tw <= th
          th += tw
          tw *= 2
        else
          tw += th
          th *= 2
        end
        # Readjust coords to support new size
        tx = tx - (tw - test_rect.width) / 2
        ty = ty - (th - test_rect.height) / 2
        if trig_event.collide_type == :circ
          inside = Collision.circ_in_rect?(trig_event.bounding_circ, [tx,ty,tw,th])
        else
          inside = Collision.rect_in_rect?(trig_event.bounding_box, [tx,ty,tw,th])
        end
        if !inside
          puts "RESET TRIGGER! (rect #{self.id})"
          @trigger_on = false
          @triggering_event_id = nil
        end
      end
    end
  end
  # ----------------------------------------------------------------------------
  #          Event Z-Index Controller by Heretic
  # This script allows you to make large sprites look like they are laying flat
  # on the ground. All EVENTS cover flat sprites. Non priority tiles will appear
  # beneath a Flat Sprite Event.
  # EV001\z_flat
  # EV001\z_flat[32]
  # EV001\z_add[32]
  #
  # NOTE: \z_add[0] will NOT be treated as a request for a FLAT SPRITE.
  #
  # To make an event always render as flat, add to its nane "\z_flat".
  #
  # To make an event always have an adjusted Z-Index, add to its name
  # "\z_add[Int]".
  #
  # To make an event always render as flat, but with an altered Z-Index,
  # add to its name "\z_flat[Int]" (this is an equivalent to using \z_flat and
  # \z_add[Int] together). Imagine having one graphic that has flat parts and
  # other parts that should be standing.
  #----------------------------------------------------------------------------
  # * Checks each event for a \z_flat and \z_add flag.
  #----------------------------------------------------------------------------
  def check_flat_sprites(event)
    # Initialize
    @z_flag = false
    @z_add = 0
    # Check z_flat and use z_add if necessary
    @z_flat = (event.name.clone.sub!(/\\z_flat\[[-]{0,1}(\d+)\]/i) {@z_add = $1.to_i} != nil)
    # If z_flat was not defined with optional z
    if !@z_flat
      # Check default z_flat
      @z_flat = (event.name.match(/\\z_flat/i) != nil)
      # Check default z_add
      event.name.sub(/\\z_add\[[-]{0,1}(\d+)\]/i) {@z_add = $1.to_i}
    end
  end
  #----------------------------------------------------------------------------
  # * Sets a sprite's flat render attribute and optionally the z_add value.
  # This is useful for when changing graphics of events.
  #
  # To specify a higher or lower Z-Index, use the optional parameter:
  # such as "set_z_flat(Bool, Int)".
  #----------------------------------------------------------------------------
  def set_z_flat(new_z_flat, new_z_add = nil)
    # Always Render as Flat regardless of size
    @z_flat = new_z_flat
    # Set optional Z-Index override
    @z_add = new_z_add if new_z_add != nil
  end
  #----------------------------------------------------------------------------
  # * Sets the Z-Index of an event via a script instead of a name.
  #
  # To make a manual adjustment to a sprite's Z-Index, use set_z_add(Int)
  # and I recommend incrementing/decrementing the Int by 32.
  #----------------------------------------------------------------------------
  def set_z_add(new_z_add)
    @z_add = new_z_add
  end
  #----------------------------------------------------------------------------
  # * Resets the Z-Index of an event via a script to the map's default.
  #----------------------------------------------------------------------------
  def reset_z_index
    check_flat_sprites(@event)
  end 
  #----------------------------------------------------------------------------
  # * Clears all Z-Index related properties. Resets when the map is reloaded.
  #----------------------------------------------------------------------------
  def clear_z_index
    @z_flat = false
    @z_add = 0
  end
  #----------------------------------------------------------------------------
  # * Redefines screen_z for altered Z-Index
  #----------------------------------------------------------------------------
  def screen_z(height = 0, _camera = true)
    # Just skip the whole thing if always-on-top is on
    return super(height) if @always_on_top
    # If using z_flat or z_add
    if @z_flat || @z_add != 0
      # Consider the Sprites Size and Adjust for it, check nil for no graphic
      height = (height != 0 && height != nil) ? height : 0
    end
    z = super(height)
    # Add flat correction value if using z_flat
    z = 0 if @z_flat
    # Add Z-Index adjustment
    z += @z_add
    # Make sure those Characters stay Visible, < 0 they Disappear!
    [0, z].max
  end
  #----------------------------------------------------------------------------
  # * Check for Hidden Graphic
  #----------------------------------------------------------------------------
  def check_hidden_graphic
    @hide_graphic = false
    self.comments do |comment_check|
      if comment_check.scan("!HIDE_GRAPHIC") != []
        @hide_graphic = true
        break
      end
    end   
  end
  #----------------------------------------------------------------------------
  # * Check for Placeholder Graphic
  #----------------------------------------------------------------------------
  def check_placeholder_graphic
    self.comments do |comment_check|
      if comment_check.scan("!PLACEHOLDER") != []
        @character_name = "#{@character_name}16"
        break
      end
    end   
  end
  #----------------------------------------------------------------------------
  # * Setup template from name
  # Event setup called based on the event's name
  # Next best thing to a common event that allows for common setup across multiple
  # event types that contain the same function
  #
  # Easily overridden by comment checks, as it is called before refresh
  #----------------------------------------------------------------------------
  def setup_event_template
    type = name.split('$')[1]
    return if type.nil?
    case type
    when 'NPC'
      resize_hitbox(80, 80)
      @direction_order = PixelMove::NPC_DIRECTION_ORDER
      @frame_order = PixelMove::NPC_FRAME_ORDER
      @stand_frame_order = PixelMove::NPC_IDLE_FRAME_ORDER
      @shadow = true
      sprite_reset
    # Event that spans two tiles -- automatically centered
    when '2XTILE'
      @collide_type = :rect
      resize_hitbox(200,100)
      @x += Game_Map::HALF_TILE
    when 'MAINCHAR'
      resize_hitbox(80, 80)
      @direction_order = PixelMove::PLAYER_DIRECTION_ORDER
      @frame_order = PixelMove::PLAYER_FRAME_ORDER
      @stand_frame_order = PixelMove::PLAYER_IDLE_FRAME_ORDER
      @shadow = true
      sprite_reset
    end
    # Uncomment and use as needed
    #this_char.frame_order = [1,2,3,4]
    #this_char.stand_frame_order = [1,2,3,4]
    #this_char.shift_x = 0
    #this_char.shift_y = 0
  end
end
