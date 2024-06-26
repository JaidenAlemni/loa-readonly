#require 'json'
require 'cgi'
#==============================================================================
# ** G(ame)Util(ity) Module
#------------------------------------------------------------------------------
# Miscellanous methods and reusable functions that can speed up development tasks
# As well as special dev functions that can be used at runtime
#==============================================================================
module GUtil
  #-------------------------------------------------------------------------
  # * Get Grid coordinates
  # For drawing items in a grid
  # start_x/y : Offset for drawing
  # index : Index of item to draw, i.e.:
  #     0 1 2
  #     3 4 5
  # columns : Number of columns in the grid.
  # x/y_spacing : Basically the grid size (total space, not additional)
  #--------------------------------------------------------------------------
  def self.xy_grid_coordinates(start_x, start_y, index, columns, x_spacing, y_spacing)
    x = start_x + index % columns * x_spacing
    y = start_y + index / columns * y_spacing
    [x, y]
  end
  #--------------------------------------------------------------------------
  # * Find center coordinates in a container (returns [x,y])
  # cw/h: Container w/h
  # ow/h: Object w/h
  #--------------------------------------------------------------------------
  def self.find_center_coords(cw, ch, ow, oh)
    return [(cw - ow) / 2, (ch - oh) / 2]
  end
  #--------------------------------------------------------------------------
  # * Percent Scale Calulation
  # Takes a minimum / maximum value and scales it based on the provided stat
  # For example, a minimum value of 10 and a maximum of 90 would return 
  # 10 if the battler has the lowest stat value, and 90 if they have the max
  # stat value. Useful for scaling algorithms in a fair way.
  # value - value in
  # min - minimum possible return value
  # max - maximum possible return value
  # value_cap - maximum the input value (usually a stat) can be
  #--------------------------------------------------------------------------
  def self.percent_scale(value, min, max, value_cap = 999)
    return min + (max - min) * value / value_cap
  end
  #--------------------------------------------------------------------------
  # * (W)eighted (R)andom (Select)ion
  # Credit: KK20
  # Takes an array of non-negative integers (weights) and performs
  # a random selection, returning the index
  #--------------------------------------------------------------------------
  def self.wr_select(varray)
    selected_index = 0
    wt = rand(varray.sum)
    varray.each_with_index do |v, i|
      wt = wt - v
      if wt < 0
        selected_index = i
        break
      end
    end
    selected_index
  end
  #--------------------------------------------------------------------------
  # * Create System Modal
  # string: Text to display
  # height: Window height
  #--------------------------------------------------------------------------
  def self.create_system_modal(string, commands = ["&MUI[CommandOK]"], width = 560, height = 316, show_help = false)
    Proc.new {
      win = Window_SystemModal.new(string, commands, width, height)
      if show_help
        controls = Window_Controls.new(win.x, win.y+win.height)
        controls.setup_inputs(:alert, nil)
        controls.opacity = 255
      end
      loop do
        Graphics.update
        Input.update
        win.update
        # Exit conditions
        if Input.trigger?(Input::C)
          $game_system.se_play($data_system.decision_se)
          choice = win.index
          win.dispose
          win = nil
          controls.dispose if show_help
          controls = nil if show_help
          break(choice)
        elsif Input.trigger?(Input::B)
          $game_system.se_play($data_system.cancel_se)
          # Cancel should always be first index (hopefully!)
          win.dispose
          win = nil
          controls.dispose if show_help
          controls = nil if show_help
          break(0)
        end    
      end
     }
  end
  #--------------------------------------------------------------------------
  # * Timed Wait
  # Stops all processing and just performs a graphics update (input optional)
  # and optional block update for the specified number of seconds
  #
  # seconds: time in seconds to wait
  # input: update the input module
  # update_block: pass a block and execute (each frame)
  #--------------------------------------------------------------------------
  def self.wait(seconds, input = false, &update_block)
    frames = (seconds * 60).to_i
    while frames >= 0 do
      Graphics.update
      Input.update if input
      update_block.call if block_given?
      frames -= 1
    end
  end
  #--------------------------------------------------------------------------
  # * Autotile constants
  #--------------------------------------------------------------------------
  INDEX  = 
  [
    26, 27, 32, 33,     4, 27, 32, 33,   26,  5, 32, 33,     4,  5, 32, 33,
    26, 27, 32, 11,     4, 27, 32, 11,   26,  5, 32, 11,     4,  5, 32, 11,
    26, 27, 10, 33,     4, 27, 10, 33,   26,  5, 10, 33,     4,  5, 10, 33,
    26, 27, 10, 11,     4, 27, 10, 11,   26,  5, 10, 11,     4,  5, 10, 11, 
    24, 25, 30, 31,    24,  5, 30, 31,   24, 25, 30, 11,    24,  5, 30, 11,   
    14, 15, 20, 21,    14, 15, 20, 11,   14, 15, 10, 21,    14, 15, 10, 11, 
    28, 29, 34, 35,    28, 29, 10, 35,    4, 29, 34, 35,     4, 29, 10, 35,
    38, 39, 44, 45,     4, 39, 44, 45,   38,  5, 44, 45,     4,  5, 44, 45,
    24, 29, 30, 35,    14, 15, 44, 45,   12, 13, 18 ,19,    12, 13, 18, 11,
    16, 17, 22, 23,    16, 17, 10, 23,   40, 41, 46, 47,     4, 41, 46, 47,
    36, 37, 42, 43,    36,  5, 42, 43,   12, 17, 18, 23,    12, 13, 42, 43,
    36, 41, 42, 47,    16, 17, 46, 47,   12, 17, 42, 47,     0,  1,  6,  7
  ]
  X = [0, 1, 0, 1]
  Y = [0, 0, 1, 1]
  #-----------------------------------------------------------------------------
  # * Create autotile collisionmaps for every tileset
  #-----------------------------------------------------------------------------
  def self.generate_at_maps
    puts "Generating autotile collisionmaps..."
    autotile_list = self.get_filelist('Graphics/ZPassability')
    autotile_list.each do |file|
      puts file
      autotile = RPG::Cache.collision_maps(file)
      width = 8 * 32
      height = 6 * 32
      bitmap = Bitmap.new(width, height)   
      for pos in 0...48
        for corner in [0,1,2,3]
          h = 4 * pos + corner
          yy = INDEX[h] / 6 
          xx = INDEX[h] % 6
          y = pos / 8
          x = pos % 8
          src_rect = Rect.new(xx * 16, yy * 16, 16, 16)
          bitmap.blt(x * 32 + X[corner] * 16, y * 32 + Y[corner] * 16, autotile, src_rect)
        end
      end      
      bitmap.to_file("Graphics/ZPassability/Autotiles/#{file}.png")
      bitmap.dispose
    end
    puts "Done!!"
  end
  #-----------------------------------------------------------------------------
  # * Creates tables for Pixel Movement
  # Probably a good idea just to call this in main, don't call from in-game.
  #-----------------------------------------------------------------------------
  def self.create_pm_tables(list)
    puts "Creating PM tables, this could take a bit..."
    # We need to do some light startup tasks first
    Localization.init
    GameSetup.load_database
    GameSetup.init_game_objects
    EventCloner.init_parent_events
    # loading bar is loaded
    bar = Sprite.new
    bar.bitmap = Bitmap.new(640, 64)
    bar.bitmap.fill_rect(0, 0, 640, 64, Color.new(255, 0, 0))
    bar.y = 480 - 128
 
    # loads map ids
    load_maps = list
    for i in 1..999
      load_maps.push(i)
    end
    
    ids = load_data("Data/MapInfos.rxdata").keys
    load_maps.clone.each {|map_id| load_maps -= [map_id] if !ids.include?(map_id)}
    
    # loads waypoint
    load_maps.each do |map_id|
      puts "Working on map ID #{map_id}"
      bar.x = -640 + (load_maps.index(map_id) + 1) * 640 / load_maps.length
      Graphics.update
      $game_map.setup(map_id)
      time = Time.new
      for x in 0..$game_map.width * 32
        if Time.new - time > 5
          time = Time.new
          Graphics.update
        end
        for y in 0..$game_map.width * 32
          $game_map.pass_tileset(x, y, $game_player)
          # if $game_map.swamp_map != nil
          #   px = $game_map.swamp_map.get_pixel(x, y).red
          #   $game_map.swamp_table[x, y] = px
          # end
          # if $game_map.height_map != nil
          #   z = $game_map.height_table[x - 1, y - 1]
          #   $game_map.height_table[x - 1, y - 1] = z
          # end
        end
      end
      $game_map.save_tables
    end
    puts "Done!!"
    # Wait a couple seconds.
    180.times{Graphics.update}
    # # Exit Game
    $scene = nil
  end
  #-----------------------------------------------------------------------------
  # * Get a list of files for a particular directory (assets)
  # dir - Directory to load from. Must be local, i.e. 'Graphics/Fogs'
  #-----------------------------------------------------------------------------
  def self.get_filelist(dir)
    # Search "Fogs", "Panoramas", and "Pictures" folder for files.
    files = Dir.entries(dir)
    # Iterate through combined folders, and omit all non-image files.
    files.each do |f| 
      # Remove file extensions
      f.gsub!(/(.png)|(.jpg)|(.ogg)|(.gif)|(.txt)/) {''}
    end
    files.delete("Autotiles")
    files.delete("..")
    files.delete(".")
    # Remove nil elements
    files.compact!
    # Return the array of files to load
    return files
  end
  #-----------------------------------------------------------------------------
  # * Dump character stats
  #-----------------------------------------------------------------------------
  def self.dump_actor_stats
    $data_actors.each do |actor|
      next if actor.nil? || actor.name == ""
      filename = "Export/" + actor.name + '.txt'
      file = File.open(filename, 'wb')
      # Write "header"
      file.write("level,dex,int,agi,luk,hp,mp\n")
      100.times do |level|
        level += 1
        hp = actor.parameters[0, level]
        mp = actor.parameters[1, level]
        dex = actor.parameters[3, level]
        int = actor.parameters[5, level]
        agi = actor.parameters[4, level]
        luk = actor.parameters[2, level]
        file.write("#{level},#{dex},#{int},#{agi},#{luk},#{hp},#{mp}\n")
      end
      file.close
    end
  end
  #-----------------------------------------------------------------------------
  # * Write to a system log
  #-----------------------------------------------------------------------------
  def self.write_log(str)
    logdir = "#{GameSetup.user_directory}/Problems.log"
    puts str
    file = File.open(logdir, 'a')
    # Don't permit the log file to get unreasonable (10mb)
    if File.size?(file) && (File.size(file).to_f / 1024000) > 10
      file.close
      file = File.open(logdir, 'w')
    end
    file.write("#{Time.now.ctime} : #{str}\n")
    file.close
  end
  #-----------------------------------------------------------------------------
  # * Open bug report form and GET the current crash data
  #-----------------------------------------------------------------------------
  def self.open_bug_report(traceback)
    # Try to get the OS
    platform = 
      if System.is_windows?
        "Windows"
      elsif System.is_mac?
        "macOS"
      elsif System.is_linux?
        "Linux"
      else
        "Linux" # IDK
      end
    qs = "?platform=#{platform}&buildversion=#{CGI.escape($BUILD_VERSION)}&traceback=#{CGI.escape(traceback)}"
    base = CFG["astravia"]["bugReportUrl"]
    return if base.nil?
    str = base + qs
    System.launch(str)
  end
  #-----------------------------------------------------------------------------
  # * Dump JSON object to file
  # (to_hash fix must be enabled below, but it breaks shit)
  #-----------------------------------------------------------------------------
  def self.obj_to_json(obj, write_file = true)
    if obj.nil?
      puts "Object does not exist!"
      return
    end
    # Write a file to the root dir
    #str = JSON.pretty_generate(obj.to_hash)
    str = HTTPLite::JSON.stringify(obj.to_hash)
    if write_file && $DEBUG
      file = "objdump.json"
      File.open(file, 'w'){|f| f.write(str)}
    end
    str
  end
end
__END__
# For some reason, this breaks Localization
#==============================================================================
# ** Object Class
#------------------------------------------------------------------------------
# Parent class to all objects.
#==============================================================================
class Object
  #-----------------------------------------------------------------------------
  # * to_hash
  # Converts an object's attributes to hash format, for readability / json dumps
  #-----------------------------------------------------------------------------
  unless method_defined?(:to_hash)
    def to_hash
      hash = {}
      instance_variables.each do |var|
        val = instance_variable_get(var)
        if !val.nil? && !val.is_a?(Fixnum) && !val.is_a?(Array) && !val.is_a?(Hash) && !val.is_a?(TrueClass) && !val.is_a?(FalseClass) && !val.is_a?(String)
          if val.respond_to?(:to_hash)
            val = val.to_hash
          else
            val = val.inspect
          end
        end
        hash[var.to_s.delete('@')] = val
      end
      hash
    end
  end
end
