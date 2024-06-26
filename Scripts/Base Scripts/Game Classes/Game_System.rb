#==============================================================================
# ** Game_System
#------------------------------------------------------------------------------
#  This class handles data surrounding the system. Backround music, etc.
#  is managed here as well. Refer to "$game_system" for the instance of 
#  this class.
#==============================================================================
class Game_System
  #--------------------------------------------------------------------------
  # * Constants
  #--------------------------------------------------------------------------
  # Factors to adjust the maximum level of audio.
  # This allows for a "master balancing" between BGM, BGS, and SE.
  # BGM_FACTOR = 
  # BGS_FACTOR = 
  # SE_FACTOR = 
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :map_interpreter          # map event interpreter
  attr_reader   :battle_interpreter       # battle event interpreter
  attr_accessor :timer                    # timer
  attr_accessor :timer_working            # timer working flag
  attr_accessor :save_disabled            # save forbidden
  attr_accessor :menu_disabled            # menu forbidden
  attr_accessor :encounter_disabled       # encounter forbidden
  attr_accessor :message_position         # text option: positioning
  attr_accessor :message_frame            # text option: window frame
  attr_accessor :save_count               # save count
  attr_accessor :magic_number             # magic number
  # Audio
  attr_accessor :memorized_bgs
  attr_accessor :memorized_bgm
  attr_accessor :saved_bgm_vol   # Saves the BGM volume
  attr_accessor :saved_bgs_vol   # Saves the BGS volume
  attr_accessor :playing_bgm
  attr_accessor :playing_bgs
  attr_accessor :bgm_position
  attr_accessor :bgs_position
  # MMW
  attr_accessor  :number_cancelled   # Allows detection if a Number Input Cancel
  attr_accessor  :mmw_text           # Holds Strings to show in Msgs \v[Tn]
  attr_reader    :message            # Shortcut, allows message without $game_
  # Journal items
  attr_accessor  :books              # Array: Stores the IDs of all unlocked books.
  attr_reader :enemies_encountered   # Array of enemies # of times encountered
  attr_reader :enemies_inspected     # Array of enemies encountered >10 times
  attr_reader :enemies_killed        # Integer containing # of enemies killed
  attr_reader :bestiary_max          # Maximum completion value
  attr_reader :enemy_bestiary_list   # Total list of enemy IDs
  attr_accessor :bestiary_current    # Current completion value
  attr_accessor :astri_pieces     # Determine collected pieces
  attr_accessor :total_gold       # Total gold gained throughout the whole game
  attr_accessor :gameplay_time    # Total time
  # Pixel Movement
  attr_accessor :caterpiller_enabled
  attr_accessor :turn_step_by_step
  attr_accessor :turn_step_by_step_duration
  #
  attr_accessor :respawn_maps
  attr_accessor :name_start_language # The locale that was active upon name input.
  attr_accessor :name_is_kana # Flag to determine if original name was in katakana
  attr_accessor :previous_language # Tracking language changes across save loads
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @map_interpreter = Interpreter.new(0, true)
    @battle_interpreter = Interpreter.new(0, false)
    @timer = 0
    @timer_working = false
    @save_disabled = false
    @menu_disabled = false
    @encounter_disabled = false
    @message_position = 2
    @message_frame = 0
    @save_count = 0
    @magic_number = 0
    @memorized_bgm = nil
    @saved_bgm_vol = nil
    @saved_bgs_vol = nil
    @playing_bgm = nil
    @bgs_position = 0
    @bgm_position = 0
    @battle_bgm = nil
    @battle_bgm_position = 0.0
    # MMW
    @message = Game_Message.new
    @number_cancelled = false
    @mmw_text = []
    # Journal
    @books = []
    @astri_pieces = 0
    @total_gold = 0
    @gameplay_time = 0
    # Inilalize bestiary list
    @enemy_bestiary_list = []
    @respawn_maps = []
    # Fill with enemy IDs
    for i in 0...$data_enemies.size
      # Skip if enemy is nil
      next if $data_enemies[i].nil? 
      # Skip iteration if ID is excluded from bestiary
      next if Bestiary::ENEMY_EXCLUDE.include?(i)
      # Skip iteration if enemy has no name
      next if $data_enemies[i].name == ""
      # Add enemy to list
      @enemy_bestiary_list << i
    end
    # Initialize enemies value
    @enemies_killed = 0
    # Initialize enemy encounter array
    @enemies_encountered = Array.new($data_enemies.size, 0)
    # Initialize list of inspected enemy IDs
    @enemies_inspected = []  
    @bestiary_max = @enemy_bestiary_list.size
    @caterpiller_enabled = PixelMove::ENABLE_CATERPILLER
    @turn_step_by_step = PixelMove::TURN_STEP_BY_STEP
    @turn_step_by_step_duration = PixelMove::TURN_SBS_DURATION
    @name_start_language = nil
    @previous_language = Localization.culture
    @name_is_kana = false
    # Start Dynamic Music System
    #$dms = Music_Variations.new
  end
  #--------------------------------------------------------------------------
  # * Play Background Music
  #     bgm : background music to be played (includes options)
  #--------------------------------------------------------------------------
  def bgm_play(bgm, position = 0.0)
    position ||= 0.0 # Set to 0 if nil
    if bgm != nil && bgm.name != ""
      begin
        Audio.bgm_play("Audio/BGM/" + bgm.name, bgm.volume * Audio.calc_volume($game_options.bgm_master_vol) / 100, bgm.pitch, position)
      rescue Errno::ENOENT
        GUtil.write_log("Failed to play audio file #{bgm.name}!")
        Audio.bgm_stop
      end
    else
      Audio.bgm_stop
    end
    @playing_bgm = bgm
    # Set variation for DMS
    #DMS.set_variation(0)
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Stop Background Music
  #--------------------------------------------------------------------------
  def bgm_stop
    Audio.bgm_stop
    @playing_bgm = nil
    @memorized_bgm = nil
  end
  #--------------------------------------------------------------------------
  # * Fade Out Background Music
  #     time : fade-out time (in seconds)
  #--------------------------------------------------------------------------
  def bgm_fade(time, clear_mem = true)
    Audio.bgm_fade(time * 1000)
    @playing_bgm = nil
    if clear_mem
      @memorized_bgm = nil
    end
  end
  #--------------------------------------------------------------------------
  # * Background Music Memory
  #--------------------------------------------------------------------------
  def bgm_memorize
    return unless @playing_bgm
    @memorized_bgm = @playing_bgm
    @bgm_position = Audio.bgm_pos
    Audio.bgm_stop
  end
  #--------------------------------------------------------------------------
  # * Background Music Memory (For Pausing in Battle - Reserves Map BGM)
  #--------------------------------------------------------------------------
  def battle_pause_memorize
    return unless @playing_bgm
    @battle_bgm = @playing_bgm
    @battle_bgm_position = Audio.bgm_pos
    Audio.bgm_stop
  end
  #--------------------------------------------------------------------------
  # * Background Music Memory (For Pausing in Battle - Reserves Map BGM)
  #--------------------------------------------------------------------------
  def battle_pause_restore
    bgm_play(@battle_bgm, @battle_bgm_position)
    @battle_bgm = nil
    @battle_bgm_position = 0.0
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Restore Background Music
  #--------------------------------------------------------------------------
  def bgm_restore
    bgm_play(@memorized_bgm, @bgm_position)
    @memorized_bgm = nil
    @bgm_position = 0.0
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Play Background Sound
  #     bgs : background sound to be played
  #--------------------------------------------------------------------------
  def bgs_play(bgs, position = 0.0)
    position ||= 0.0 # Set to 0 if nil
    if bgs != nil && bgs.name != ""
      begin
        Audio.bgs_play("Audio/BGS/" + bgs.name, bgs.volume * Audio.calc_volume($game_options.bgs_master_vol) / 100, bgs.pitch, position)
      rescue Errno::ENOENT
        GUtil.write_log("Failed to play audio file #{bgs.name}!")
        Audio.bgs_stop
      end
    else
      Audio.bgs_stop
    end
    @playing_bgs = bgs
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Stop Background Sound
  #--------------------------------------------------------------------------
  def bgs_stop
    Audio.bgs_stop
    @playing_bgs = nil
    @memorized_bgs = nil
  end
  #--------------------------------------------------------------------------
  # * Fade Out Background Sound
  #     time : fade-out time (in seconds)
  #--------------------------------------------------------------------------
  def bgs_fade(time)
    Audio.bgs_fade(time * 1000)
    @playing_bgs = nil
    @memorized_bgs = nil
  end
  #--------------------------------------------------------------------------
  # * Background Sound Memory
  #--------------------------------------------------------------------------
  def bgs_memorize
    return unless @playing_bgs
    @memorized_bgs = @playing_bgs
    @bgs_position = Audio.bgs_pos
    Audio.bgs_stop
  end
  #--------------------------------------------------------------------------
  # * Restore Background Sound
  #--------------------------------------------------------------------------
  def bgs_restore
    bgs_play(@memorized_bgs, @bgs_position)
    @memorized_bgs = nil
    @bgs_position = 0.0
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Play Music Effect
  #     me : music effect to be played
  #--------------------------------------------------------------------------
  def me_play(me)
    if me != nil and me.name != ""
      Audio.me_play("Audio/ME/" + me.name, me.volume * Audio.calc_volume($game_options.se_master_vol) / 100, me.pitch)
    else
      Audio.me_stop
    end
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Play Sound Effect
  #     se : sound effect to be played
  #--------------------------------------------------------------------------
  def se_play(se)
    if se != nil and se.name != ""
      begin
        Audio.se_play("Audio/SE/" + se.name, se.volume * Audio.calc_volume($game_options.se_master_vol) / 100, se.pitch)
      rescue Errno::ENOENT
        GUtil.write_log("Failed to play audio file #{se.name}!")
        Audio.se_stop
      end
    end
    Graphics.frame_reset
  end
  #--------------------------------------------------------------------------
  # * Stop Sound Effect
  #--------------------------------------------------------------------------
  def se_stop
    Audio.se_stop
  end
  #--------------------------------------------------------------------------
  # * Automatically Change Background Music and Background Sound
  #--------------------------------------------------------------------------
  def setup_house_bgm
    # If the map is indoors
    if $game_map.is_house?
      # And we didn't already reduce the volume
      if @saved_bgm_vol.nil? 
        # Save the current volume
        @saved_bgm_vol = $game_options.bgm_master_vol
        # Decrease the volume
        Audio.bgm_volume = Audio.bgm_volume - Audio::INDOOR_LEVEL_DECREASE
      end
    # If the map is not outdoors
    elsif
      # And there is a saved volume
      unless @saved_bgm_vol.nil?
        # Set the master volume to the saved volume
        Audio.bgm_volume = @saved_bgm_vol
        # Clear the saved volume
        @saved_bgm_vol = nil
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Get Windowskin File Name
  #--------------------------------------------------------------------------
  def windowskin_name
    if @windowskin_name == nil
      return $data_system.windowskin_name
    else
      return @windowskin_name
    end
  end
  #--------------------------------------------------------------------------
  # * Set Windowskin File Name
  #     windowskin_name : new windowskin file name
  #--------------------------------------------------------------------------
  def windowskin_name=(windowskin_name)
    @windowskin_name = windowskin_name
  end
  #--------------------------------------------------------------------------
  # * Get Battle Background Music
  #--------------------------------------------------------------------------
  def battle_bgm
    if @battle_bgm == nil
      return $data_system.battle_bgm
    else
      return @battle_bgm
    end
  end
  #--------------------------------------------------------------------------
  # * Set Battle Background Music
  #     battle_bgm : new battle background music
  #--------------------------------------------------------------------------
  def battle_bgm=(battle_bgm)
    @battle_bgm = battle_bgm
  end
  #--------------------------------------------------------------------------
  # * Get Background Music for Battle Ending
  #--------------------------------------------------------------------------
  def battle_end_me
    if @battle_end_me == nil
      return $data_system.battle_end_me
    else
      return @battle_end_me
    end
  end
  #--------------------------------------------------------------------------
  # * Set Background Music for Battle Ending
  #     battle_end_me : new battle ending background music
  #--------------------------------------------------------------------------
  def battle_end_me=(battle_end_me)
    @battle_end_me = battle_end_me
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # reduce timer by 1
    if @timer_working and @timer > 0
      @timer -= 1
    end
  end
  #--------------------------------------------------------------------------
  # * Enemy encounters (count)
  # Called at the end of battle on each enemy. 
  #--------------------------------------------------------------------------
  def encounter_enemy(id)
    # Add defeated enemy to counter
    @enemies_killed += 1
    return if Bestiary::ENEMY_EXCLUDE.include?(id)
    # Check for nil, then increment.
    @enemies_encountered[id] += 1
    # Inspect if seen more than 10 times
    if @enemies_encountered[id] >= 10
      inspect_enemy(id)
    end
    # Flag for notification update
    if @enemies_encountered[id] == 1 || @enemies_encountered[id] == 10
      $game_temp.bestiary_updated = true
    end
  end
  #--------------------------------------------------------------------------
  # * Inspect an enemy
  #--------------------------------------------------------------------------
  def inspect_enemy(id)
    # Add enemy ID to "inspected" list
    if @enemies_inspected.include?(id)
      return
    else
      @enemies_inspected.push(id)
    end
  end
  #--------------------------------------------------------------------------
  # * Current bestiary completion
  #--------------------------------------------------------------------------
  def bestiary_current
    @enemies_inspected.size
  end
  #--------------------------------------------------------------------------
  # * Get bestiary complete rate
  #--------------------------------------------------------------------------
  def enemy_bestiary_percent_complete
    e_max = @bestiary_max
    e_now = bestiary_current
    e_now * 100 / e_max
  end
  #--------------------------------------------------------------------------
  # * Get quest completion rate
  #--------------------------------------------------------------------------
  def quests_percent_complete
    e_max = QuestData::TotalQuests
    e_now = $game_party.quests_completed.size
    e_now * 100 / e_max
  end
  #--------------------------------------------------------------------------
  # * Get respawn maps
  #--------------------------------------------------------------------------
  def respawn_maps
    @respawn_maps ||= []
  end
  #--------------------------------------------------------------------------
  # * Kana name flag
  #--------------------------------------------------------------------------
  def name_is_kana
    @name_is_kana ||= false
  end
  #--------------------------------------------------------------------------
  # * Language (tracking differences when loading saves, i.e. changed at title)
  #--------------------------------------------------------------------------
  def previous_language
    @previous_language ||= Localization.culture
  end
end
