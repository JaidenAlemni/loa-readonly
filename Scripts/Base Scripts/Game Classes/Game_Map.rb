#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
#  This class handles the map. It includes scrolling and passable determining
#  functions. Refer to "$game_map" for the instance of this class.
#==============================================================================
class Game_Map
  # Tile size constant
  TILE_SIZE = 16
  # Number to multiply for "real" coordinates (this was 128 when going by 32x32 tiles)
  # This is used for rounding movement to prevent choppiness from integer divison
  REAL_FACTOR = TILE_SIZE * 4
  REAL_DIV = 4
  # Min width / height (editor)
  EDITOR_MIN_WIDTH = 20
  EDITOR_MIN_HEIGHT = 15
  # Default zoom ratio for maps
  DEFAULT_ZOOM = 4.0
  HALF_TILE = TILE_SIZE / 2
  # Shape table
  # Index of the 16 "shapes" formed in the editor using the arrows
  PASSAGES = [
    # REDACTED
  ]
  NO_PASS_TILE = [0,0,TILE_SIZE,TILE_SIZE]
  PASS_TILE = [0,0,0,0]
  # Maximum fogs
  MAX_FOGS = 3
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :tileset_name             # tileset file name
  attr_accessor :autotile_names           # autotile file name
  attr_accessor :panorama_name            # panorama file name
  attr_accessor :panorama_hue             # panorama hue
  attr_accessor :fogs                     # array of fogs plane information
  attr_accessor :battleback_name          # battleback file name
  attr_accessor :display_x                # display x-coordinate * Real factor
  attr_accessor :display_y                # display y-coordinate * Real factor
  attr_accessor :need_refresh             # refresh request flag
  attr_reader   :passages                 # passage table
  attr_reader   :priorities               # prioroty table
  attr_reader   :terrain_tags             # terrain tag table
  attr_reader   :events                   # events
  # Character position saving (MMW)
  attr_accessor :last_display_x           # last display x-coord * Real factor
  attr_accessor :last_display_y           # last display y-coord * Real factor
  #
  attr_reader :is_house                   # Determines if the map is a house
  attr_reader   :name                     # Map name
  attr_reader :is_dungeon                 # Flag map as a "dungeon"
  attr_reader :enemy_static_events        # Enemies that do not respond to player movement
  attr_reader :enemy_move_events          # Enemies that respond to player movement  
  attr_accessor :parallax_lock            # Locks parallax from moving
  attr_accessor :pano_ox                  # Panorama ox
  attr_accessor :pano_oy                  # Panorama oy
  # Pixel movement
  attr_accessor :collision_maps           # Array of collision bitmaps (0 tileset, 1+ autotiles)
  attr_accessor :height_map               # saves height-map
  attr_accessor :swamp_map                # saves swamp-map
  attr_accessor :tileset_name
  attr_accessor :autotile_names
  attr_accessor :game_followers           # Caterpillars
  attr_accessor :collision_table          # Table to check collision faster
  attr_accessor :height_table
  attr_accessor :swamp_table
  attr_accessor :waypoints                # Waypoints for pathfinding
  #attr_accessor :collision_data           # 16x16 collision tiles
  attr_reader   :loop_map                 # Determine if map wraps at edges
  attr_reader   :connections_data
  attr_accessor   :display_map_name         # Flag to display the map name
  attr_accessor :jump_tiles               # Array of events that are jump tiles
  attr_reader   :default_zoom
  attr_accessor :current_zoom
  attr_reader   :map_edge
  attr_reader   :screen_center
  attr_accessor   :init_event
  attr_accessor   :lightmap       # Hash with lightmap data
  attr_reader     :last_map
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @map_id = 0
    @display_x = 0
    @display_y = 0
    @name = ""
  end
  #--------------------------------------------------------------------------
  # * Setup
  #     map_id : map ID
  #--------------------------------------------------------------------------
  def setup(map_id)
    # Find the previous map
    @last_map = @map_id
    # Saves tables of the previous map
    #self.save_tables
    # Put map ID in @map_id memory
    @map_id = map_id
    # Load map from file and set @map
    @map = load_data(sprintf("Data/Map%03d.rxdata", @map_id))
    #@map = GameSetup.load_enc_data(sprintf("Data/Map%03d", @map_id))
    # set tile set information in opening instance variables
    tileset = $data_tilesets[@map.tileset_id]
    @tileset_name = tileset.tileset_name.sub('_EDITOR','')
    @autotile_names = tileset.autotile_names.map{|n| n.sub('_EDITOR','')}
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    MapConfig.setup_extra_ttags(@map.tileset_id, @terrain_tags)
    @pano_ox = 0
    @pano_oy = 0
    # Setup Panorama
    @panorama_name, @parallax_lock, @pano_sx, @pano_sy = CustomFogsPanorama.panoramas(@map_id)
    # Initialize displayed coordinates
    @display_x = 0
    @display_y = 0
    # Clear refresh request flag
    @need_refresh = false
    # Clear name display flag
    @display_map_name = false
    # Array of event objects that are jump tiles
    @jump_tiles = []
    # First-run event
    @init_event = nil
    # Set map event data
    @events = {}
    for i in @map.events.keys
      @events[i] = Game_Event.new(@map_id, @map.events[i])
    end
    # Set common event data
    @common_events = {}
    for i in 1...$data_common_events.size
      @common_events[i] = Game_CommonEvent.new(i)
    end
    # Initialize fogs (now an array of hashes)
    # These would be better as a dedicated object, but this is sufficient for now
    @fogs = []
    MAX_FOGS.times do |i|
      @fogs[i] = {
        name: "", zoom: 100, blend_type: 0, sx: 0, sy: 0, ox: 0, oy: 0, 
        tone: Tone.new(0,0,0,0), tone_target: Tone.new(0,0,0,0), tone_duration: 0,
        hue: 0, opacity: 0, opacity_target: 0, opacity_duration: 0
      }
    end
    # Initialize lightmap
    @lightmap = {
      name: "",
      color: Color.new(0,0,0,0),
      color_target: Color.new(0,0,0,0),
      opacity: 255,
      duration: 0,
      blend_type: 2
    }
    # Initialize scroll information
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
    # MMW
    @last_display_x = @display_x
    @last_display_y = @display_y
    # Determine if it's a house
    @is_house = MapConfig.house?(@map)
    # Determine if it's a dungeon
    @is_dungeon = MapConfig.dungeon?(@map)
    # Determine if it is a looping map
    @loop_map = MapConfig.looping?(@map)
    # Store map display name
    #setup_map_name
    # Setup dungeon
    @enemy_static_events = {}
    @enemy_move_events = {}
    setup_dungeon if @is_dungeon
    # Respawn map
    if $game_system.respawn_maps.include?(@map_id) || MapConfig.respawning?(@map)
      respawn_enemies(@map_id)
    end
    # Array of event IDs that are push blocks
    @push_blocks = []
    # Get pushable blocks
    setup_push_blocks
    # Init map connection data
    @connections_data = {}
    # Special map data (first run event, transfers, etc.)
    setup_special_data
    # Basically, if we don't have an init event, make sure the normal transition processes
    $game_temp.transition_processing = true unless @init_event
    # Setup pixelmovement passability maps and tables
    # self.load_bitmaps 
    #self.load_tables
    # loads waypoints for pathfinding
    #self.load_waypoints
    # deletes pathfinding of the player for the old map
    $game_player.pathfinding = Game_Pathfinding.new($game_player)
    # Setup map edge and Center
    setup_map_edge
  end
  #-----------------------------------------------------------------------------
  # * Read the "data" event that contains configuration for the map
  # (Transfers, etc.)
  #-----------------------------------------------------------------------------
  def setup_special_data
    # Iterate
    @events.values.each do |event|
      next if event.nil?
      # Find and tag first-run event
      if event.name.scan('&INIT') != []
        puts "Warning! Additional init event detected!" if @init_event
        @init_event = event
        @init_event.start
      end
      # Find and process data event
      if event.name.scan('&DATA') != []
        event.comments do |comment|
          next if comment[0] == '#'
          # Map Connections 
          # Syntax: MC!dir: map_id, offset, min coord, max coord
          # i.e. MC!2: 42, 10, 4, 25
          if comment[0,3] == 'MC!'
            # Get dir (always 4th character)
            dir = comment[3].to_i
            # Get the string to the right of the :
            raw_data = comment.split(':')[1]
            next if raw_data.nil?
            # Make an array with ","
            raw_data = raw_data.split(',')
            # Strip whitespace and convert to int
            ary = raw_data.map{|e| e.strip!.to_i}
            @connections_data[dir] = ary
          end
          # Trigger Area Logo from direction (SHOW_AREA:ID)
          if comment[0,9] == 'SHOW_AREA'
            from_id = comment.split(':')[1]
            if @last_map == from_id.to_i
              # We can't use Game_Temp's variable, because the spriteset hasn't been
              # created yet. So we use a game map flag to "save it for later"
              @display_map_name = true
            end
          end
        end
      end
    end
    puts "map connections: #{@connections_data}"
  end
  #-----------------------------------------------------------------------------
  # * Setup visual effects
  # Finds and reads the &DATA event, specifically for visual related elements
  # This is called before the map transition runs, which allows for performing
  # tone and zoom changes prior to fade-in
  # spriteset : Spriteset_Map object
  # fade_delay : Number of frames to delay fade in from black screen
  #-----------------------------------------------------------------------------
  def setup_map_effects(spriteset)
    data_event = @events.values.select{|e| e.name == '&DATA'}
    return if data_event == []
    # Refresh event to force page change
    data_event[0].refresh
    data_event[0].comments do |comment|
      # Zoom factor
      if comment.start_with?('ZOOM!')
        args = comment.split('!')[1].split(';')
        zoom = args[0].to_f
        if args.size > 1
          Camera.zoom_to(zoom, args[1].to_f)
        else
          Camera.zoom = zoom
          Graphics.update
        end
        $game_map.current_zoom = zoom
      end
      # Fade amount (time to wait before fading in)
      if comment.start_with?('FADE!')
        $scene.fade_delay = comment.split('!')[1].to_i
      end
      # Lightmap
      if comment.start_with?('LMAP!')
        # Value to the right of ! (determines lightmap type)
        type = comment.split('!')[1][0,1]
        # Arguments, to the right of : comma separated
        args = comment.split(':')[1].strip
        # Solid color LMAP!C:red,green,blue,opacity;blend
        if type == 'C'
          rgb, blend = args.split(';')          
          red, green, blue, opacity = rgb.split(',')
          setup_lightmap("", color: Color.new(red.to_f, green.to_f, blue.to_f, opacity.to_f), opacity: 255, blend: blend.to_i)
        # File LMAP!F:filename;opacity;blend
        elsif type == 'F'
          file, blend = args.split(';')
          setup_lightmap(file, blend: blend.to_i)
        # Map ID LMAP!M:blend
        else
          blend = args[0].to_i
          setup_lightmap("Map#{@map_id}", opacity: 255, blend: blend)
        end
      end
      # Fogs FOG!Index:name;zoom;opacity;blend;sx;sy;r,g,b,g;hue
      if comment.start_with?('FOG!')
        index = comment.split('!')[1][0,1].to_i
        args = comment.split(':')[1].strip
        name, zoom, opacity, blend_type, sx, sy, rgb, hue = args.split(';')
        if rgb
          r, g, b, gr = rgb.split(',')
          tone = Tone.new(r.to_f, g.to_f, b.to_f, gr.to_f)
        end
        fog = $game_map.fogs[index]
        fog[:name] = name
        fog[:zoom] = zoom.to_f if zoom
        fog[:opacity] = fog[:opacity_target] = opacity.to_i if opacity
        fog[:blend_type] = blend_type.to_i if blend_type
        fog[:sx] = sx.to_i if sx
        fog[:sy] = sy.to_i if sy
        fog[:tone] = fog[:tone_target] = tone if tone
        fog[:hue] = hue.to_i if hue
        spriteset.update_fogs
      end
    end
  end
  #-----------------------------------------------------------------------------
  # * Setup lightmap
  #-----------------------------------------------------------------------------
  def setup_lightmap(name, color: Color.new(), opacity: 255, blend: 2, duration: 0)
    @lightmap[:name] = name
    @lightmap[:duration] = duration
    @lightmap[:opacity] = opacity
    @lightmap[:blend_type] = blend
    @lightmap[:color_target] = color.clone
    if duration < 1
      @lightmap[:color] = color.clone
      $scene.spriteset.update_lightmap
    end
    # Also link to battleback
    r = color.red
    g = color.green
    b = color.blue
    if opacity < 255
      r -= r * opacity / 255
      g -= g * opacity / 255
      b -= b * opacity / 255
    end
    if blend == 2
      r *= -1
      g *= -1
      b *= -1
    end
    $game_temp.battleback_tone = Tone.new(r,g,b)
  end
  #-----------------------------------------------------------------------------
  # * Save Collision Tables
  #-----------------------------------------------------------------------------
  def save_tables
    return if self.map_id == 0
    path = sprintf("Data/Pixelmovement/Tables/Map%03dC.rxdata", self.map_id)
    save_data(@collision_table, path)
  end
  #-----------------------------------------------------------------------------
  # Load Collision Tables
  #-----------------------------------------------------------------------------
  def load_tables
    return if self.map_id == 0
    file = sprintf("Map%03dC.rxdata", self.map_id)
    if !Dir.entries('Data/Pixelmovement/Tables/').include?(file)
      # Width (tiles) height (tiles) layers
      @collision_table = Table.new(self.width, self.height, 3)
    else
      path = sprintf("Data/Pixelmovement/Tables/Map%03dC.rxdata", self.map_id)
      @collision_table = load_data(path)
    end
    # After loading, if the tables are still nonexistant, make new ones instead
    if @collision_table.nil?
      @collision_table = Table.new(self.width, self.height, 3)
    end
  end
  #--------------------------------------------------------------------------
  # * Create caterpiller
  #--------------------------------------------------------------------------
  def setup_followers
    # Caterpillar System
    @game_followers_copy = $game_party.actors(:all).clone
    @game_followers = []
    if $game_system.caterpiller_enabled
      for i in 1..$game_party.actors(:all).length
        @game_followers.push(Game_Follower.new(i))
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Setup Dungeon
  # Creates a hash of enemies
  #--------------------------------------------------------------------------
  def setup_dungeon
    @events.values.each do |event|
      next if event.nil?
      event.comments do |comment|
        if comment.scan(DungeonConfig::STATIC_COMMENT)[0]
          @enemy_static_events[event.id] = event
        elsif comment.scan(DungeonConfig::MOVING_COMMENT)[0]
          @enemy_move_events[event.id] = event
        end
      end
    end
    # Reset through
    @enemy_through_wait = nil
    # Create "wait" and "move" move route objects
    @enemy_wait = CustomRoutes.create_route(:wait_forever)
    @enemy_move = CustomRoutes.create_route(:continue)
  end  
  #--------------------------------------------------------------------------
  # * Determine if blocks are pushable
  #--------------------------------------------------------------------------
  def setup_push_blocks
    @events.values.each do |event|
      next if event.nil?
      # Find PUSH_BLOCK comment
      event.comments do |comment|
        if comment.include?('PUSH_BLOCK')
          event.push_block = true
          @push_blocks << event.id
          break
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Setup Map Edge
  # The map edge contains the max X/Y that display_x/y can reach, to prevent
  # scrolling out of bounds. 
  # Irrelevant if the map size + zoom is < current resolution
  #--------------------------------------------------------------------------
  def setup_map_edge
    #@current_zoom = Camera.zoom
    @map_edge = [0,0]
    @screen_center = [
      (LOA::SCRES[0]/2 - HALF_TILE) * 4, 
      (LOA::SCRES[1]/2 - HALF_TILE) * 4
    ]
    min_width = LOA::SCRES[0] / TILE_SIZE
    min_height = LOA::SCRES[1] / TILE_SIZE
    # Scrolling X is permitted
    if self.width > min_width
      @map_edge[0] = ((self.width - min_width) * REAL_FACTOR).round
      @screen_center[0] = (LOA::SCRES[0] / 2 - (TILE_SIZE / 2)) * 4
    end
    # Scrolling Y is permitted
    if self.height > min_height
      @map_edge[1] = ((self.height - min_height) * REAL_FACTOR).round
      @screen_center[1] = (LOA::SCRES[1] / 2 - (TILE_SIZE / 2)) * 4
    end
  end
  #--------------------------------------------------------------------------
  # * Default Zoom factor
  #--------------------------------------------------------------------------
  def default_zoom
    DEFAULT_ZOOM
  end
  #--------------------------------------------------------------------------
  # * Current Zoom factor (For switching Scenes / Saving + Loading)
  #--------------------------------------------------------------------------
  def current_zoom
    @current_zoom ||= DEFAULT_ZOOM
  end
  #--------------------------------------------------------------------------
  # * Get Map ID
  #--------------------------------------------------------------------------
  def map_id
    return @map_id
  end
  #--------------------------------------------------------------------------
  # * Jump Tiles accessor
  #--------------------------------------------------------------------------
  def jump_tiles
    @jump_tiles ||= []
  end
  #--------------------------------------------------------------------------
  # * House determinant
  #--------------------------------------------------------------------------
  def is_house?
    @is_house
  end
  #--------------------------------------------------------------------------
  # * Dungeon determinant
  #--------------------------------------------------------------------------
  def is_dungeon?
    @is_dungeon
  end
  #--------------------------------------------------------------------------
  # * Get Width
  #--------------------------------------------------------------------------
  def width
    @map.width
  end
  #--------------------------------------------------------------------------
  # * Get Height
  #--------------------------------------------------------------------------
  def height
    @map.height
  end
  #--------------------------------------------------------------------------
  # * Get Encounter List
  #--------------------------------------------------------------------------
  def encounter_list
    @map.encounter_list
  end
  #--------------------------------------------------------------------------
  # * Get Encounter Steps
  #--------------------------------------------------------------------------
  def encounter_step
    @map.encounter_step * TILE_SIZE # Pixel movement
  end
  #--------------------------------------------------------------------------
  # * Get Map Data
  #--------------------------------------------------------------------------
  def data
    @map.data
  end
  #--------------------------------------------------------------------------
  # * Get Map Name (pulled in from exdata)
  #--------------------------------------------------------------------------
  def name
    $data_map_exts[@map_id].loc_name
  end
  #--------------------------------------------------------------------------
  # * Automatically Change Background Music and Backround Sound
  #--------------------------------------------------------------------------
  def autoplay
    if @map.autoplay_bgm
      $game_system.bgm_play(@map.bgm)
    end
    if @map.autoplay_bgs
      # Attempt to capture position of currently playing BGS for seemless transition
      pos = Audio.bgs_pos
      $game_system.bgs_play(@map.bgs, pos)
    end
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    # If map ID is effective
    if @map_id > 0
      # Refresh all map events
      for event in @events.values
        event.refresh
      end
      # Refresh all common events
      for common_event in @common_events.values
        common_event.refresh
      end
    end
    # Clear refresh request flag
    @need_refresh = false
    # Get pushable blocks after events have been refreshed
    setup_push_blocks
    # Setup tiles after events have been refreshed
    #setup_event_tiles
  end
  #--------------------------------------------------------------------------
  # * Scroll Down
  #     distance : scroll distance
  #--------------------------------------------------------------------------
  def scroll_down(distance)
    @display_y = [@display_y + distance, @map_edge[1]].min
  end
  #--------------------------------------------------------------------------
  # * Scroll Left
  #     distance : scroll distance
  #--------------------------------------------------------------------------
  def scroll_left(distance)
    if @loop_map
      @display_x = @display_x - distance.round
    else
      @display_x = [@display_x - distance, 0].max
    end
  end
  #--------------------------------------------------------------------------
  # * Scroll Right
  #     distance : scroll distance
  #--------------------------------------------------------------------------
  def scroll_right(distance)
    @display_x = [@display_x + distance, @map_edge[0]].min
  end
  #--------------------------------------------------------------------------
  # * Scroll Up
  #     distance : scroll distance
  #--------------------------------------------------------------------------
  def scroll_up(distance)
    if @loop_map
      @display_y = @display_y - distance.round
    else
      @display_y = [@display_y - distance, 0].max
    end
  end
  #-----------------------------------------------------------------------------
  # Event Collision
  # self_event -> the Game_Character object checking passability
  # bypass_trigger : if the event being checked is "slid" into, don't trigger the event
  # 
  # Returns an integer: 0 passable (no collision), 1 unpassable (collision), 2 unpassable sticky (don't slide)
  #-----------------------------------------------------------------------------
  def event_collision?(x, y, self_event, bypass_trigger = false)
    result = false
    sticky = false
    ([$game_player] + @events.values).each do |event|
      # Skip if nonexistant event
      next if event.nil?
      # Don't check self
      next if event == self_event
      # Skip if event isn't extremely large and not within range
      if event.size_x < TILE_SIZE*6 && event.size_y < TILE_SIZE*6
        next if event.x > (x + TILE_SIZE*6) || event.y > (y + TILE_SIZE*6) || event.x < (x - TILE_SIZE*6) || event.y < (y -TILE_SIZE*6)
      end
      # Don't check jumping or events
      next if event.jumping? 
      # Check against pass height if applicable
      if event.player? || event.check_pass_height
        next if event.pass_height != self_event.pass_height
      end
      char_rect = [x, y, self_event.size_x, self_event.size_y]
      ev_rect = event.bounding_box
      char_rad = self_event.size_rad
      ev_rad = event.size_rad
      # Check tile_id events
      # Remember, event.x and event.y is from the bottom center of the event
      if event.tile_id > 48 && Collision.rect_in_rect?([event.x - HALF_TILE, event.y - TILE_SIZE, TILE_SIZE, TILE_SIZE], char_rect)
        # Map tile passability
        check = event_tile_collision?(x, y, event, self_event)
      else
        # Check for collision
        # We need to create the checking characters bounding box/circle on the fly, for the new coordinates
        check = self_event.on_event?(event, x, y)
      end
      # If a collision occurred
      if check
        result = (event.player? || !event.over_trigger?)
        unless bypass_trigger
          # Event -> Player trigger
          if event.player? && self_event.trigger == 2 && !self_event.trigger_on
            puts "event triggered #{event.id}"
            self_event.triggering_event_id = event.id
            self_event.start
          # Player -> Event trigger
          elsif self_event.player? && event.trigger == 2 && !event.trigger_on
            puts "player triggered #{event.id} #{event.name}"
            # Permit saving if we're on a save event
            if event.name == "[CLONE]:1"
              puts "enabled saving"
              $game_system.save_disabled = false
            end
            event.triggering_event_id = self_event.id
            event.start
          elsif self_event.player? && event.trigger == 1
            # Set sticky value (for now, just trigger == 1)
            sticky = true
          end
        end
        # After triggering events are triggered, override passability
        # With through condition
        result = false if event.through
      end
    end
    # Create a "sticky" collision based on the event type (sticky -> no sliding, like push blocks, etc.)
    if result && sticky
      return 2
    elsif result
      return 1
    else
      return 0
    end
  end
  #--------------------------------------------------------------------------
  # * Determine Valid Coordinates
  #     x          : x-coordinate
  #     y          : y-coordinate
  #--------------------------------------------------------------------------
  def valid?(x, y)
    # Disregard for looping maps
    result = true if @loop_map
    # Pixel compensation
    x /= TILE_SIZE
    # Y >= 20 doesn't allow for events to trigger on the top row of the map, changed to 8. 
    y -= 8
    y /= TILE_SIZE
    result = (x >= 0 && x < width && y >= 0 && y < height)
    return result
  end
  #--------------------------------------------------------------------------
  # * Given a tile ID, return the coordinates of the tile based
  # on several variables
  # 
  # tile_id : ID of the tile within the database tileset
  #           values >= 48 but < 384 are autotiles
  # charactert : Game_Character object checking passability
  #--------------------------------------------------------------------------
  def tile_collision_coordinates(tile_id, character)
    return PASS_TILE if tile_id < 48
    character_height = character.pass_height
    # Determine passage value
    # Passages are the integer value determined by clicking the arrows in the database editor
    # Best to refer to included debug tileset graphics for how this works
    # Counters add 128, and bushes add 64 to this value
    passage_value = @passages[tile_id]
    tt = @terrain_tags[tile_id]
    #puts "tileid: #{tile_id} TT: #{tt} passage value: #{passage_value}, height: #{character.pass_height}"
    if passage_value > 16 && passage_value != 31 # If a bush or counter flag is involved
      # Remove counter & bush
      if passage_value > 192
        passage_value -= 192
      # Remove counter
      elsif passage_value > 128
        passage_value -= 128
      # Remove bush
      else
        passage_value -= 64
      end
    end
    # Autotiles with "square" icon
    # A bit of guesswork here--I couldn't determine any other values than these two
    if passage_value == 16
      passage_value = 1
    elsif passage_value == 31
      passage_value = 15
    end
    # Special case: Events vs TT 6 = No pass ever
    if tt == 6 && !character.player?
      return NO_PASS_TILE
    end
    # Special case: 0 @ TT 1 = Always pass, no Z change
    if tt == 1 && passage_value == 0
      return PASS_TILE
    end
    # From here on, the terrain tag determines the behavior of the passage value
    # This is for differentiating different character "heights"
    # Special passability tiles, overrides the rest
    if ![0,1,2].include?(tt)
      # Terrain tag 3 has some special options
      if tt == 3
        case passage_value
        # Passable all levels, z-below
        when 0
          return PASS_TILE
        # Reverse unpassable lv 1, z-below level 1, z-above level 0
        when 3, 5
          if character_height == 1
            return PASSAGES_INVERTED[passage_value]
          else
            return PASS_TILE
          end
        # Normal passability, regardless of character height
        when 1,2,4,6,7,8,9,11,13,14
          return PASSAGES[passage_value]   
        # Passable all levels, z-below level 1, z-above level 0
        when 15
          return PASS_TILE
        end
      # Terrain tags other than 0-3 are always passable
      else
        return PASS_TILE
      end
    end
    # Dictate by character's height and terrain tags
    if character_height == 1
      # Reverse passability
      if [1,2,3,4,5,8,15].include?(passage_value) && tt == 1
        pass = PASSAGES_INVERTED[passage_value]
      # Normal passability
      elsif tt == 2
        pass = PASSAGES[passage_value]
      # No passability
      else
        pass = NO_PASS_TILE
      end
    else
      # No pass
      if tt == 2
        pass = NO_PASS_TILE
      # Normal passability
      else
        pass = PASSAGES[passage_value]
      end
    end
    if pass.nil?
      return PASS_TILE
    end
    return pass
  end
  #--------------------------------------------------------------------------
  # * Determine if Passable 
  #     x          : x-coordinate (on center)
  #     y          : y-coordinate (on center)
  #     character  : character that called this method
  #--------------------------------------------------------------------------
  def passable?(x, y, character)
    # REDACTED
  end
  #--------------------------------------------------------------------------
  # * Determine if Passable (Event tile IDs)
  # x,y - Coordinate to check
  #--------------------------------------------------------------------------
  def event_tile_collision?(x, y, event, character)
    char_circ = [x, y, character.size_rad]
    base_x, base_y, base_w, base_h, corner = tile_collision_coordinates(event.tile_id, character)
    check_x = base_x + event.x - HALF_TILE
    check_y = base_y + event.y - TILE_SIZE
    # puts "#{x} #{y} #{check_x} #{check_y} #{base_w} #{base_h}"
    # puts "==="
    # if $DEBUG
    #   tile_sp = Sprite.new($scene.spriteset.viewport3)
    #   tile_sp.z = 9999
    #   tile_sp.bitmap = Bitmap.new(TILE_SIZE,TILE_SIZE)
    #   tile_sp.bitmap.fill_rect(0,0,TILE_SIZE,TILE_SIZE,Color.new(100,0,255,5))
    #   tile_sp.x, tile_sp.y = check_x, check_y
    # end
    # If there's a 5th argument, check half tiles
    if !corner.nil? && character.player?
      # Check with logic using real coordinates
      collide = Collision.circ_in_halfrect?(char_circ, [check_x, check_y, base_w, base_h, corner])
    # Treat all other tiles as rects. For NPCs, no sense checking half tiles either.
    else
      # If it's an empty rect, it's passable
      if base_w == 0 && base_h == 0
        return false
      end
      # Determine if the character collides with the specified rect
      collide = Collision.circ_in_rect?(char_circ, [check_x, check_y, base_w, base_h])
    end
    return collide
  end
  # #-----------------------------------------------------------------------------
  # # * Check against collision map table
  # #-----------------------------------------------------------------------------
  # def check_collision_table(x, y, char_elevation)
  #   case @collision_table[x, y]
  #   when 1 # level 1
  #     return (char_elevation == 0 ? false : true)
  #   when 2 # level 2
  #     return (char_elevation == 1 ? false : true)
  #   when 3 # no pass all levels
  #     return false
  #   when 4 # passable
  #     return true
  #   end
  #   return true
  # end
  # #-----------------------------------------------------------------------------
  # # * Write to collision map table
  # #-----------------------------------------------------------------------------
  # def write_collision_table(x, y, pixel, char_elevation)
  #   # Branch by pixel color
  #   case pixel
  #   # Block all heights
  #   when UNPASSABLE_COLOR
  #     @collision_table[x, y] = 3
  #   # Block only level 1
  #   when LEVEL_1_COLOR
  #     @collision_table[x, y] = (char_elevation == 0 ? 1 : 4)
  #   # Block only level 2
  #   when LEVEL_2_COLOR
  #     @collision_table[x, y] = (char_elevation == 1 ? 2 : 4)
  #   end
  #   # Passable
  #   @collision_table[x, y] = 4
  # end
  #-----------------------------------------------------------------------------
  # checks passability from the database
  #-----------------------------------------------------------------------------
  def pass_database(x, y, self_event)
    # checks events with tile graphics, Loop in all events
    for event in events.values
      # If tiles other than self are consistent with coordinates
      next if self_event == nil || event.tile_id < 48 || event == self_event || !self_event.in_rect?(event.x, event.y - event.size_y / 2, event.size_x - 1, event.size_y - 1, x, y) || event.through
      # If obstacle bit is set
      if @passages[event.tile_id] != 0
        return false if !self.obstacle_passable?(x, y, @passages[event.tile_id])
      # If priorities other than that are 0
      elsif @priorities[event.tile_id] == 0
        # passable
        return true
      end
    end
    # Loop searches in order from top of layer
    for i in [2, 1, 0]
      # Get tile ID
      tile_id = data[x / TILE_SIZE, y / TILE_SIZE, i]
      # Tile ID acquistion failure
      if tile_id == nil
        # impassable
        return false
      # If obstacle bit is set
      elsif @passages[tile_id] != 0
        return false if !self.obstacle_passable?(x, y, @passages[tile_id])
      # If priorities other than that are 0
      elsif @priorities[tile_id] == 0
        # passable
        return true
      end
    end
  end
  #-----------------------------------------------------------------------------
  # returns the passability of the current position subject to the 
  # obstacle settings
  #-----------------------------------------------------------------------------
  def obstacle_passable?(x, y, obstacle)
    # what's passable?
    case obstacle
    # left, right, up
    when 1
      return y % TILE_SIZE < 30
    # right, up, down
    when 2
      return x % TILE_SIZE > 8
    # right, up
    when 3
      return (y % TILE_SIZE < 30 && x % TILE_SIZE > 8)
    # left, up, down
    when 4
      return x % TILE_SIZE < 24
    # left, up
    when 5
      return (y % TILE_SIZE < 30 && x % TILE_SIZE < 24)
    # up, down
    when 6
      return (x % TILE_SIZE < 24 && x % TILE_SIZE > 8)
    # up
    when 7
      return (y % TILE_SIZE < 30 && x % TILE_SIZE < 24 && x % TILE_SIZE > 8)
    # left, right, down
    when 8
      return y % TILE_SIZE > 16
    # left, right
    when 9
      return (y % TILE_SIZE < 30 && y % TILE_SIZE > 16)
    # right, down
    when 10
      return (y % TILE_SIZE > 16 && x % TILE_SIZE > 8)
    # right
    when 11
      return (y % TILE_SIZE < 30 && y % TILE_SIZE > 16 && x % TILE_SIZE > 8)
    # left, down
    when 12
      return (y % TILE_SIZE > 16 && x % TILE_SIZE < 24)
    # left
    when 13
      return (y % TILE_SIZE < 30 && y % TILE_SIZE > 16 && x % TILE_SIZE < 24)
    # down
    when 14
      return (y % TILE_SIZE > 16 && x % TILE_SIZE < 24 && x % TILE_SIZE > 8)
    # left, right, up
    when 16
      return y % TILE_SIZE < 30
    # bush
    when 64
      return true
    # nothing
    else
      return false
    end  
  end
  #--------------------------------------------------------------------------
  # * Determine Thicket
  #     x          : x-coordinate
  #     y          : y-coordinate
  #--------------------------------------------------------------------------
  def bush?(x, y)
    # Compensate for PM
    x /= TILE_SIZE
    y /= TILE_SIZE
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return false
        elsif @passages[tile_id] & 0x40 == 0x40
          return true
        end
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Determine Counter
  #     x          : x-coordinate
  #     y          : y-coordinate
  #--------------------------------------------------------------------------
  def counter?(x, y)
    # Offset actual
    y -= TILE_SIZE/4
    # Compensate for PM
    x /= TILE_SIZE
    y /= TILE_SIZE
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return false
        elsif @passages[tile_id] & 0x80 == 0x80
          return true
        end
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Get Terrain Tag
  #     x          : x-coordinate
  #     y          : y-coordinate
  #--------------------------------------------------------------------------
  def terrain_tag(x, y)
    # Offset actual
    y -= TILE_SIZE/4
    # Get actual
    x /= TILE_SIZE
    y /= TILE_SIZE
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return 0
        elsif @terrain_tags[tile_id] > 0
          return @terrain_tags[tile_id]
        end
      end
    end
    return 0
  end
  #--------------------------------------------------------------------------
  # * Get All Terrain Tags (regardless of priority)
  #--------------------------------------------------------------------------
  def all_terrain_tags(x, y)
    # Offset actual
    y -= TILE_SIZE/4
    # Get actual
    x /= TILE_SIZE
    y /= TILE_SIZE
    tags = [0,0,0]
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          next
        elsif @terrain_tags[tile_id] > 0
          tags << @terrain_tags[tile_id]
        end
      end
    end
    tags
  end
  #--------------------------------------------------------------------------
  # * Determine if the target location is a z-order override situation
  # for the character
  # x - character x
  # y - character y
  #--------------------------------------------------------------------------
  def z_override_tile(x, y, pass_height)
    # Offset actual
    y -= TILE_SIZE/4
    # Get actual
    x /= TILE_SIZE
    y /= TILE_SIZE
    override = false
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        next if tile_id == nil || tile_id < 48
        next unless @terrain_tags[tile_id] == 3
        case @passages[tile_id]
        when 0
          override = true
        when 3,5
          override = false
        when 15
          override = (pass_height == 1)
        end
      end
    end
    return override
  end
  #--------------------------------------------------------------------------
  # * Get Designated Position Event ID
  #     x          : x-coordinate
  #     y          : y-coordinate
  #--------------------------------------------------------------------------
  def check_event(x, y)
    tile_rect = [x, y, TILE_SIZE, TILE_SIZE]
    # On the off chance multiple events are on a single tile?
    event_ids = []
    for event in $game_map.events.values
      if Collision.rect_in_rect?(event.bounding_box, tile_rect)
        event_ids << event.id
      end
    end
    return event_ids
  end
  #-----------------------------------------------------------------------------
  # distance between (sx, sy) and (tx, ty)
  #-----------------------------------------------------------------------------
  def distance(sx, sy, tx, ty)
    dist = Collision.distance(sx, sy, tx, ty).round
    # for loop maps
    if @loop_map
      dist2 = Collision.distance(sx, sy, tx-self.width * Game_Map::TILE_SIZE, ty).round
      dist3 = Collision.distance(sx, sy, tx+self.width * Game_Map::TILE_SIZE, ty).round
      if dist > dist2
        sx += self.width
        dist = dist2
      elsif dist > dist3
        sx -= self.width
        dist = dist3
      end
      dist4 = Collision.distance(sx, sy, tx, ty-self.height * Game_Map::TILE_SIZE).round
      dist5 = Collision.distance(sx, sy, tx, ty+self.height * Game_Map::TILE_SIZE).round
      dist = dist4 if dist > dist4
      dist = dist5 if dist > dist5      
    end
    return dist
  end
  #--------------------------------------------------------------------------
  # * Start Scroll
  #     direction : scroll direction
  #     distance  : scroll distance
  #     speed     : scroll speed
  #--------------------------------------------------------------------------
  def start_scroll(direction, distance, speed)
    @scroll_direction = direction
    @scroll_rest = distance * TILE_SIZE*4
    @scroll_speed = speed
  end
  #--------------------------------------------------------------------------
  # * Determine if Scrolling
  #--------------------------------------------------------------------------
  def scrolling?
    return @scroll_rest > 0
  end
  #--------------------------------------------------------------------------
  # * Start Changing Fog Color Tone
  #     tone     : color tone
  #     duration : time
  #     number   : fog index, default to first
  #--------------------------------------------------------------------------
  def start_fog_tone_change(tone, duration, index = 0)
    fog = @fogs[index]
    fog[:tone_target] = tone.clone
    fog[:tone_duration] = duration
    if fog[:tone_duration] == 0
      fog[:tone] = fog[:tone_target].clone
    end
  end
  #--------------------------------------------------------------------------
  # * Start Changing Fog Opacity Level
  #     opacity  : opacity level
  #     duration : time
  #     number   : fog index, default to first
  #--------------------------------------------------------------------------
  def start_fog_opacity_change(opacity, duration, index = 0)
    fog = @fogs[index]
    fog[:opacity_target] = opacity * 1.0
    fog[:opacity_duration] = duration
    if fog[:opacity_duration] == 0
      fog[:opacity] = fog[:opacity_target]
    end
  end
  #--------------------------------------------------------------------------
  # * Respawn enemies
  # Resets all self switches on specified enemies 
  # external - means the map has been loaded as a different object (for external management)
  #--------------------------------------------------------------------------
  def respawn_enemies(map_id)
    @enemy_static_events.values.each do |event|
      next if event.nil?
      # Reset all self switches
      switches = 'ABCD'
      switches.each_char do |c|
        key = [@map_id, event.id, c]
        $game_self_switches[key] = false
      end
    end
    @enemy_move_events.values.each do |event|
      next if event.nil?
      # Reset all self switches
      switches = 'ABCD'
      switches.each_char do |c|
        key = [@map_id, event.id, c]
        $game_self_switches[key] = false
      end
    end
    @need_refresh = true
    $game_system.respawn_maps.delete(map_id)
  end
  #--------------------------------------------------------------------------
  # * Toggle Encounter
  # Temporarily sets all enemies to be transparent
  #--------------------------------------------------------------------------
  def toggle_encounter(bool = true)
    if bool
      $game_temp.escaping_enemies = true
      # Intialize wait time
      @enemy_through_wait = 0
      @enemy_move_events.values.each do |event|
        key = [@map_id, event.id, 'D']
        $game_self_switches[key] = false
        event.refresh
        event.opacity = 100
        # Allow the event to move through other events 
        event.through = true
        event.trigger = 0
      end 
    else
      $game_temp.escaping_enemies = false
      @enemy_move_events.values.each do |event|
        event.opacity = 255
        # Allow the event to move through other events 
        event.through = false
        event.trigger = 2 # Touch trigger
      end 
    end
  end
  #--------------------------------------------------------------------------
  # * Dungeon Update
  #--------------------------------------------------------------------------
  def update_dungeon_enemies
    return unless @is_dungeon
    # Update enemy invisibility
    if !@enemy_through_wait.nil? && @enemy_through_wait < DungeonConfig::WAIT_TIME
      # Update wait count
      @enemy_through_wait += 1 
    elsif !@enemy_through_wait.nil? && @enemy_through_wait >= DungeonConfig::WAIT_TIME
      # Reset through
      @enemy_through_wait = nil
      toggle_encounter(false)
    end
    # If the player moved and the enemy is not in an escaping state
    if $game_player.moving? && @enemy_through_wait.nil?
      # Set enemy move route (one step)
      @enemy_move_events.values.each do |event|
        next if event.nil?
        next if event.enemy_moved
        event.force_move_route(@enemy_move)
        event.enemy_moved = true     
      end
    else
      @enemy_move_events.values.each do |event|
        next if event.nil?
        next if event.release_move_switch?(@map_id)
        event.force_move_route(@enemy_wait)
        event.enemy_moved = false if event.enemy_moved
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Push Block Update
  #--------------------------------------------------------------------------  
  def update_push_blocks
    return if @push_blocks == []
    # If the player isn't moving and the interpreter isn't running
    if !$game_player.moving? && !$game_system.map_interpreter.running?
      # If they're pressing a direction key
      if Input.press?(Input::UP) || Input.press?(Input::DOWN) || Input.press?(Input::LEFT) || Input.press?(Input::RIGHT)
        # Save current pushing block
        current_block = $game_temp.pushing_block
        # Check if they border a push block
        @push_blocks.each do |id|
          if id.nil?
            @push_blocks.delete(id)
            next
          end
          # If they're facing a block and it's different
          if [2, 4, 6, 8].include?($game_player.direction) && $game_player.looks_at?(id) && id != $game_temp.pushing_block
            # Save ID, reset timer, stop looping
            $game_temp.push_timer = 0
            $game_temp.pushing_block = id
            break
          # Facing a block 
          elsif [2, 4, 6, 8].include?($game_player.direction) && $game_player.looks_at?(id) && id == $game_temp.pushing_block
            break
          end
        end
        # If the block is valid
        if $game_temp.pushing_block != nil && $game_temp.pushing_block == current_block
          # If the timer reached max
          if $game_temp.push_timer >= PushBlocks::TIMER
            # Reset timer
            $game_temp.push_timer = 0
            id = $game_temp.pushing_block
            $game_temp.pushing_block = nil
            # Start the event
            $game_map.events[id].start
          else
            # Increment the timer
            $game_temp.push_timer += 1
          end
        end
      end  
    # No Longer pushing
    else
      reset_push_block
    end
  end
  #--------------------------------------------------------------------------
  # * Reset the push block 
  #--------------------------------------------------------------------------
  def reset_push_block
    $game_temp.push_timer = 0 
    $game_temp.pushing_block = nil
  end
  #--------------------------------------------------------------------------
  # * Update extra panorama
  #--------------------------------------------------------------------------
  def update_extra_pano
    if !@parallax_lock
      @pano_ox -= @pano_sx / 8.0
      @pano_oy -= @pano_sy / 8.0
    end
  end
  #--------------------------------------------------------------------------
  # * Update followers
  #--------------------------------------------------------------------------
  def update_followers
    return unless $game_system.caterpiller_enabled
    # If condition of party changed
    if @game_followers_copy != $game_party.actors(:all) 
      @game_followers_copy = $game_party.actors(:all).clone
      # Setup followers again
      setup_followers
    end
    @game_followers.each {|actor| actor.update}
  end
  #--------------------------------------------------------------------------
  # * Update all fogs
  #--------------------------------------------------------------------------
  def update_fogs
    @fogs.each do |fog|
      next if fog[:name] == ""
      # Manage fog scrolling TODO: Clean up this motion
      fog[:ox] -= fog[:sx] / 8.0
      fog[:oy] -= fog[:sy ]/ 8.0
      # Manage change in fog color tone
      if fog[:tone_duration] >= 1
        d = fog[:tone_duration]
        target = fog[:tone_target]
        fog[:tone].red = (fog[:tone].red * (d - 1) + target.red) / d
        fog[:tone].green = (fog[:tone].green * (d - 1) + target.green) / d
        fog[:tone].blue = (fog[:tone].blue * (d - 1) + target.blue) / d
        fog[:tone].gray = (fog[:tone].gray * (d - 1) + target.gray) / d
        fog[:tone_duration] -= 1
      end
      # Manage change in fog opacity level
      if fog[:opacity_duration] >= 1
        d = fog[:opacity_duration]
        fog[:opacity] = (fog[:opacity] * (d - 1) + fog[:opacity_target]) / d
        fog[:opacity_duration] -= 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Refresh map if necessary
    if $game_map.need_refresh
      refresh
    end
    # If scrolling
    if @scroll_rest > 0
      # Change from scroll speed to distance in map coordinates
      distance = 2 ** @scroll_speed
      # Execute scrolling
      case @scroll_direction
      when 2  # Down
        scroll_down(distance)
      when 4  # Left
        scroll_left(distance)
      when 6  # Right
        scroll_right(distance)
      when 8  # Up
        scroll_up(distance)
      end
      # Subtract distance scrolled
      @scroll_rest -= distance
    end
    # Update map event
    for event in @events.values
      event.update
    end
    # Update common event
    for common_event in @common_events.values
      common_event.update
    end
    # Update all fogs
    update_fogs
    # Update additional panorama
    update_extra_pano
    # Update followers
    update_followers
    # Update enemies
    update_dungeon_enemies
    # Update blocks
    update_push_blocks
  end 
end # Class
