#==============================================================================
# Game Setup Module
# 
# This module contains global methods and variables for game configuration
# Primarily, it holds the data save / load methods in one spot
#==============================================================================
module GameSetup
  # Ruby scripts version (Internal Change Testing)
  GAME_VERSION = '0.7.1'
  #--------------------------------------------------------------------------
  # * Startup Tasks
  #--------------------------------------------------------------------------
  def self.startup
    # Setup user (save, config) directory
    @user_directory = CFG["astravia"]["useDataPath"]  ? System.data_directory : "UserData"
    # Load database
    self.load_database
    # Overwrite / load direct from CSV in dev mode
    if $DEBUG
      self.load_database_from_csv
    end
    # Initialize localization
    Localization.init
    # Create caches
    RPG::Cache.create_damage_cache
    # Make each type of game object
    self.init_game_objects
    # Load cloned events
    EventCloner.init_parent_events
    # Copy demo maps for dist if we're in debug mode
    self.copy_demo_maps if $DEBUG
  end
  #--------------------------------------------------------------------------
  # * Create Build Version - Displays on Title
  #--------------------------------------------------------------------------
  def self.generate_build_version
    # REDACTED
  end
  #--------------------------------------------------------------------------
  # * Get user directory
  #--------------------------------------------------------------------------
  def self.user_directory
    @user_directory
  end
  #--------------------------------------------------------------------------
  # * Global Config Management
  # A simple hash that records some necessary global data that isn't covered
  # by Game_System, Options, or Saves.
  # Mostly utilized for checking and fixing data more elegantly across version changes
  #--------------------------------------------------------------------------
  DEFAULT_CONFIG_VALUES = {
    last_rgss_version: GAME_VERSION,
    controller_warning: false,
    old_demo_warning: false
  }
  #--------------------------------------------------------------------------
  def self.check_global_config
    # Create or load the existing file
    load_global_config
    # Check across versions
    update_string = version_update_changes
    # Controller type warning
    check_controls
    # Show version alert
    if update_string && update_string != ""
      show_update_alert(update_string)  
    end
    # Update config
    $GLOBAL_CONFIG[:last_rgss_version] = GAME_VERSION
    save_global_config
  end
  #--------------------------------------------------------------------------
  def self.load_global_config
    file = "#{self.user_directory}/GlobalConfig.rxdata"
    unless FileTest.exist?(file)
      $GLOBAL_CONFIG = DEFAULT_CONFIG_VALUES.dup
      File.open(file, 'wb'){|f| Marshal.dump($GLOBAL_CONFIG, f)}
    else
      File.open(file, 'rb'){|f| $GLOBAL_CONFIG = Marshal.load(f)}
    end
  end
  def self.save_global_config
    file = "#{self.user_directory}/GlobalConfig.rxdata"
    File.open(file, 'wb'){|f| Marshal.dump($GLOBAL_CONFIG, f)}
  end
  #--------------------------------------------------------------------------
  # * Controller notice
  #--------------------------------------------------------------------------
  def self.check_controls
    if !$GLOBAL_CONFIG[:controller_warning] && Input::Controller.connected? && !System.is_linux? # Supress on Steam Deck (and thus all linux) for now
      # Show notice
      str = Localization.localize("&MUI[GameControllerAlert]").sub('!N', "#{Input::Controller.name}")
      alert_proc = GUtil.create_system_modal(str, ["&MUI[GameControllerAlertChoice0]","&MUI[GameControllerAlertChoice1]"], 560, 316, true)
      if alert_proc.call == 1
        $game_options.kb_override = true
        save_options
        str = "&MUI[GameControllerAlertReturn1]"
      else
        str = "&MUI[GameControllerAlertReturn0]"
      end
      alert_proc = GUtil.create_system_modal(str, ["&MUI[CommandOK]"], 560, 180)
      alert_proc.call
      $GLOBAL_CONFIG[:controller_warning] = true
    end
  end
  #--------------------------------------------------------------------------
  # * Manage updates
  #--------------------------------------------------------------------------
  def self.version_update_changes
    return if $GLOBAL_CONFIG[:last_rgss_version].nil?
    return unless $GLOBAL_CONFIG[:last_rgss_version] != GAME_VERSION
    version = $GLOBAL_CONFIG[:last_rgss_version].split("\.")
    major, minor, _patch = version.map{|s| s.to_i}
    alert_string = ""
    # Discard 2022 demo stuff
    if major == 0 && minor < 5
      GUtil.write_log("2022 demo files found!")
      self.load_options(true)
      GUtil.write_log("Successfully overwrote them.")
    end
    # If the current version is newer (1 if newer, -1 if older, 0 if the same)
    if (GAME_VERSION <=> $GLOBAL_CONFIG[:last_rgss_version]) > 0
      alert_string = Localization.localize("&MUI[GameUpdateAlert]")
      alert_string.sub!("!V",GAME_VERSION.to_s)
      if CFG["astravia"]["updateNote"]
        alert_string += "\n\n#{CFG["astravia"]["updateNote"]}"
      end
    end
    alert_string
  end
  #--------------------------------------------------------------------------
  # * Display update alert
  #--------------------------------------------------------------------------
  def self.show_update_alert(str)
    alert_proc = GUtil.create_system_modal(str, ["&MUI[CommandOK]","&MUI[CommandWebsite]"], 560, 316, true)
    if alert_proc.call == 1 && CFG["astravia"]["changeLogUrl"]
      System.launch(CFG["astravia"]["changeLogUrl"])
    end
  end
  #--------------------------------------------------------------------------
  # * Initialize game objects
  #--------------------------------------------------------------------------
  def self.init_game_objects
    $game_temp          = Game_Temp.new
    $game_system        = Game_System.new
    $game_switches      = Game_Switches.new
    $game_variables     = Game_Variables.new
    $game_self_switches = Game_SelfSwitches.new
    $game_screen        = Game_Screen.new
    $game_actors        = Game_Actors.new
    $game_party         = Game_Party.new
    $game_troop         = Game_Troop.new
    $game_map           = Game_Map.new
    $game_player        = Game_Player.new
    $game_busts         = Game_Busts.new
  end
  #--------------------------------------------------------------------------
  # * Load Database Files (Encrypted)
  def self.load_enc_data(path)
    file = File.open(path + '.atd', 'rb')
    rawdata = file.read
    file.close
    first = nil
    rawdata.each_byte {|byte|
      first = byte
      break}
    rawdata[0] = ((first + 128) % 256).chr
    data = Zlib::Inflate.inflate(rawdata)
    file = File.open(GameSetup.temp + 'tmp.rxdata', 'wb')
    file.write(data)
    file.close
    file = File.open(GameSetup.temp + 'tmp.rxdata', 'rb')
    obj = Marshal.load(file)
    file.close
    File.delete(GameSetup.temp + 'tmp.rxdata')
    return obj
  end
  # def self.load_database
  #   $data_actors        = load_enc_data("Data/Actors")
  #   $data_skills        = load_enc_data("Data/Skills")
  #   $data_classes       = load_enc_data("Data/Classes")
  #   $data_items         = load_enc_data("Data/Items")
  #   $data_weapons       = load_enc_data("Data/Weapons")
  #   $data_armors        = load_enc_data("Data/Armors")
  #   $data_enemies       = load_enc_data("Data/Enemies")
  #   $data_troops        = load_enc_data("Data/Troops")
  #   $data_states        = load_enc_data("Data/States")
  #   $data_animations    = load_enc_data("Data/Animations")
  #   $data_tilesets      = load_enc_data("Data/Tilesets")
  #   $data_common_events = load_enc_data("Data/CommonEvents")
  #   $data_system        = load_enc_data("Data/System")
  #   $game_options       = load_enc_data("Data/Options")
  # end
  #--------------------------------------------------------------------------
  # * Load Database Files (Unencrypted)
  #--------------------------------------------------------------------------  
  def self.load_database
    $data_actors        = load_data("Data/Custom/Actors.rxdata")
    $data_classes       = load_data("Data/Custom/Classes.rxdata")
    $data_skills        = load_data("Data/Custom/Skills.rxdata")
    $data_items         = load_data("Data/Custom/Items.rxdata")
    $data_weapons       = load_data("Data/Custom/Weapons.rxdata")
    $data_armors        = load_data("Data/Custom/Armors.rxdata")
    $data_enemies       = load_data("Data/Custom/Enemies.rxdata")
    $data_troops        = load_data("Data/Troops.rxdata")
    $data_states        = load_data("Data/Custom/States.rxdata")
    $data_animations    = load_data("Data/Custom/Animations.rxdata")
    $data_tilesets      = load_data("Data/Tilesets.rxdata")
    $data_common_events = load_data("Data/CommonEvents.rxdata")
    $data_system        = load_data("Data/System.rxdata")
    # CUSTOM 
    $data_essences         = load_data("Data/Custom/Essences.rxdata")
    $data_battle_sequences = load_data("Data/Custom/BattleSequences.rxdata")
    $data_battle_actions   = load_data("Data/Custom/BattleActions.rxdata")
    $data_shops            = load_data("Data/Custom/Shops.rxdata")
    $data_npcs             = load_data("Data/Custom/Npcs.rxdata")
    $data_map_exts         = load_data("Data/Custom/MapExData.rxdata")
    # Load options
    load_options
  end
  #--------------------------------------------------------------------------
  # * Load Options, or regenerate if it does not exist
  #--------------------------------------------------------------------------
  def self.load_options(overwrite = false)
    # Determine existence of Options data
    options_file = "#{self.user_directory}/Options.rxdata"
    if overwrite || !FileTest.exist?(options_file)
      $game_options = Game_Options.new
      File.open(options_file, 'wb'){|f| Marshal.dump($game_options, f)}
    else
      File.open(options_file, 'rb'){|f| $game_options = Marshal.load(f)}
    end
  end
  #--------------------------------------------------------------------------
  # * Save options
  #--------------------------------------------------------------------------
  def self.save_options
    unless $game_options
      puts "Warning: Attempted to save options with none found!"
    end
    options_file = "#{self.user_directory}/Options.rxdata"
    File.open(options_file, 'wb'){|f| Marshal.dump($game_options, f)}
  end
  #--------------------------------------------------------------------------
  # * Make File Name
  #     file_index : save file index (0-3)
  #--------------------------------------------------------------------------
  def self.savefile_name(file_index)
    "#{self.user_directory}/Memory#{file_index}.#{($DEMO ? 'demo' : '')}save"
  end
  #--------------------------------------------------------------------------
  # * Read Save Data
  #     file : file object for reading (opened)
  #--------------------------------------------------------------------------
  def self.read_save_data(file, temporary = false)
    # If temporary load, throw objects into a hash and return
    if temporary
      t_hash = {}
      [:system, :switches, :variables, :self_switches, 
      :screen, :actors, :party, :troop, :map, :player].each do |obj|
        t_hash[obj] = Marshal.load(file)
      end
      return t_hash
    end
    # Read each type of game object
    $game_system        = Marshal.load(file)
    $game_switches      = Marshal.load(file)
    $game_variables     = Marshal.load(file)
    $game_self_switches = Marshal.load(file)
    $game_screen        = Marshal.load(file)
    $game_actors        = Marshal.load(file)
    $game_party         = Marshal.load(file)
    $game_troop         = Marshal.load(file)
    $game_map           = Marshal.load(file)
    $game_player        = Marshal.load(file)
    # If magic number is different from when saving
    # (if editing was added with editor)
    # if $game_system.magic_number != $data_system.magic_number
    #   # Load map
    #   $game_map.setup($game_map.map_id)
    #   $game_player.center($game_player.x, $game_player.y)
    # else
    #   Camera.zoom = $game_map.current_zoom
    # end
    $game_map.setup($game_map.map_id)
    $game_player.center($game_player.x, $game_player.y)
    # Check player name change (EN - JP)
    GameSetup.change_player_name
    # Reload pixelmove data
    load_pixelmove_data
    # Refresh party members
    $game_party.refresh
    Camera.follow($game_player, 0)
  end
  #--------------------------------------------------------------------------
  # * Write Save Data
  #     file : write file object (opened)
  #--------------------------------------------------------------------------
  def self.write_save_data(file)
    # Clear PM Data
    clear_pixelmove_data
    # Increase save count by 1
    $game_system.save_count += 1
    # Save last recorded language
    $game_system.previous_language = Localization.culture
    # Save magic number
    # (A random value will be written each time saving with editor)
    $game_system.magic_number = $data_system.magic_number
    # Write each type of game object
    Marshal.dump($game_system, file)
    Marshal.dump($game_switches, file)
    Marshal.dump($game_variables, file)
    Marshal.dump($game_self_switches, file)
    Marshal.dump($game_screen, file)
    Marshal.dump($game_actors, file)
    Marshal.dump($game_party, file)
    Marshal.dump($game_troop, file)
    Marshal.dump($game_map, file)
    Marshal.dump($game_player, file)
    # Reload pixelmove data
    load_pixelmove_data
  end
  #-----------------------------------------------------------------------------
  # * Clear PM bitmaps and save tables
  #-----------------------------------------------------------------------------
  def self.clear_pixelmove_data
    $game_map.collision_maps = nil
    $game_map.height_map = nil
    $game_map.swamp_map = nil
    # $game_map.save_tables
    $game_map.collision_table = nil
    $game_map.height_table = nil
    $game_map.swamp_table = nil
    $game_map.waypoints = nil
    $game_player.pathfinding = nil
  end
  #-----------------------------------------------------------------------------
  # * Load bitmaps and tables
  #-----------------------------------------------------------------------------
  def self.load_pixelmove_data
    #$game_map.load_bitmaps
    #$game_map.load_tables
    #$game_map.load_waypoints
    $game_player.pathfinding = Game_Pathfinding.new(self)
  end
  #--------------------------------------------------------------------------
  # * Take a Screenshot
  #--------------------------------------------------------------------------
  def self.take_screenshot
    return unless $DEBUG
    ss = Graphics.snap_to_bitmap
    time = Time.now
    time_str = time.strftime("%Y-%m-%d_%H-%M-%S")
    ss.to_file("Screenshots/SS_#{time_str}.png")
  end
  #--------------------------------------------------------------------------
  # * Change player name
  # Changes the player's name when switched between Japanese and English
  #--------------------------------------------------------------------------  
  def self.change_player_name
    #puts $game_system.previous_language
    #puts $game_options.language
    lang_to = $game_options.language
    return unless lang_to != $game_system.previous_language
    #puts "changed player name"
    start_lang = $game_system.name_start_language
    player_name = $game_actors[1].name
    # Special name case
    if MenuConfig::MAIN_CHAR_NAMES[lang_to].has_key?(player_name)
      $game_actors[1].name = MenuConfig::MAIN_CHAR_NAMES[lang_to][player_name]
      return
    end
    # Branch by name start
    new_name = player_name
    if start_lang == :jp
      case lang_to
      when :jp
        # downcase, convert to katakana
        if $game_system.name_is_kana
          new_name = player_name.downcase.roma_to_kata
        end
      when :en_us
        # Is the name even kana to begin with?
        # convert to romaji, capitalize, limit 13
        if player_name.contains_kana?
          #puts "contained kana"
          $game_system.name_is_kana = true
          new_name = player_name.romaji.capitalize[0,12]
        end
      end
    end
    $game_actors[1].name = new_name
  end
end