#==============================================================================
# ■ CSV Data Importer
#------------------------------------------------------------------------------
# Loading and handling of data from CSV files
# Written by Jaiden Alemni for exclusive use in Legends of Astravia
#==============================================================================
#==============================================================================
# * GameSetup Module
#==============================================================================
module GameSetup
  # Load direct from CSV, overwrites prior loaded objects
  def self.load_database_from_csv
    # Load Battle Animations
    CSVLoader.load_sequence_data
    CSVLoader.load_action_data
    # Load database
    CSVLoader.load_database_objects
  end
  # Battle Animation Data Files (TODO)
  def self.load_battle_animations # As data
    #$data_battleactions = types.each{|name| load_data("Data/Custom/#{name}.rxdata")
  end
end
#==============================================================================
# * CSV Loader
#==============================================================================
module CSVLoader

  # CSV Files Go Here
  INPUT_DIR = "Data/Import/"
  # RXData Files Go Here
  OUTPUT_DIR = "Data/Custom/"
  # CSV Files to Load
  TEMP_DATABASE_OBJECTS = [
    "!AnimationTimings","!ClassElementRanks","!ClassStateRanks",
    "!EnemyActions","!EnemyDrops","!EnemyElementRanks",
    "!EnemyStateRanks","!StatScaling"
  ]
  CUSTOM_DATABASE_OBJECTS = [
    "Actors","Animations","Armors","Classes","Enemies",
    "Essences","Items","Skills","States","Weapons",
    "Npcs","Shops","MapExData"
  ]
  # Special conversion
  EVAL_FIELD = lambda{|field|
    if field.nil?
      ""
    else
      if field.casecmp("true").zero?
        true
      elsif field.casecmp("false").zero?
        false
      elsif field.start_with?(":") && field.respond_to?(:to_sym)
        field.delete_prefix!(":")
        field.to_sym
      elsif (field.start_with?("[") && field.end_with?("]")) || 
              (field.start_with?("{") && field.end_with?("}"))
        eval(field)
      # Eval all others
      elsif field.start_with?("$")
        field.delete_prefix!("$")
        eval(field)
      else
        try_int = Integer(field, exception: false)
        if try_int.nil?
          field
        else
          try_int
        end
      end
    end
  }

  # def self.dump_to_rxdata(filename)
  #   File.open( OUTPUT_DIR + File.basename("#{filename}", ".csv") + ".rxdata", "w+" ) do |rxdatafile|
  #     next if fname.start_with?("!")
  #     puts "Preparing to dump #{fname} to RXData : \n#{data}"
  #     Marshal.dump( data, rxdatafile )
  #   end
  # end

  def self.load_database_objects
    @temp_tables = {}
    logstr = ""
    # Make temp tables
    TEMP_DATABASE_OBJECTS.each do |temp|
      fname = temp + ".csv"
      File.open(INPUT_DIR + fname){|csvfile| create_temporary_table(csvfile, temp.delete_prefix("!"))}
    end
    # Create objects
    CUSTOM_DATABASE_OBJECTS.each do |obj|
      data = nil 
      fname = obj + ".csv"
      File.open(INPUT_DIR + fname) do |file| 
        data = parse_csv_data(file)
        # Dump to RXDATA
        rxdatafile = OUTPUT_DIR + obj + ".rxdata"
        save_data(data, rxdatafile)
        logstr << "Dumped #{obj} to RXDATA :\n"
        PP.pp(data, logstr)
        logstr << "==========================\n"
        # Load directly into objects
        eval("$data_#{obj.downcase} = load_data('#{rxdatafile}')")
        puts "Loaded #{fname} from CSV"
      end
    end
    File.write("CSVImport.log", logstr)
  end

  # Take the CSV Data from the opened file and parse it
  def self.parse_csv_data(csvfile)
    obj_name = File.basename(csvfile, ".csv")
    data = []
    CSV.foreach(csvfile, headers: true, header_converters: [:downcase], converters: [EVAL_FIELD]) do |row|
      if row['id'] == 0
        data << nil
      else
        data << create_object(obj_name, row)
      end
    end
    data
  end

  def self.create_object(obj_name, csvrow)
    name = 
      case obj_name
      when "Classes" 
        obj_name.delete_suffix("es")
      when "Enemies"
        "Enemy"
      else
        obj_name.delete_suffix("s")
      end
    begin
      obj = eval("RPG::#{name}.new")
    rescue
      raise "Attempted to convert unsupported object: #{obj_name}"
    end
    csvrow.each{|key, value| obj.send("#{key}=", value)}
    obj
  end

  def self.create_temporary_table(csvfile, table_name)
    table = CSV.parse(csvfile, headers: true, header_converters: [:symbol], converters: [EVAL_FIELD])
    @temp_tables[table_name] = table
  end

  def self.parse_learnings(learnings)
    field_data = []
    learnings.each do |level, skill_id|
      learning = RPG::Class::Learning.new
      learning.level = level
      learning.skill_id = skill_id
      field_data << learning
    end
    field_data
  end

  def self.parse_enemy_actions(enemy_id)
    # Get info from EnemyActions table
    field_data = []
    @temp_tables['EnemyActions'].each do |row|
      next unless row[:enemy_id] == enemy_id
      action = RPG::Enemy::Action.new
      action.kind = row[:kind].to_sym
      action.basic = row[:basic].to_sym
      action.skill_id = row[:skill_id]
      action.condition_turn_a = row[:condition_turn_a]
      action.condition_turn_b = row[:condition_turn_b]
      action.condition_hp = row[:condition_hp]
      action.condition_level = row[:condition_level]
      action.condition_switch_id = row[:condition_switch_id]
      action.rating = row[:rating]
      action.item_id = row[:item_id]
      action.weapon_id = row[:weapon_id]
      action.behavior = row[:behavior].to_sym
      action.condition_custom = (row[:condition_custom].empty? ? nil : row[:condition_custom].to_sym)
      action.custom_params = row[:custom_params]
      field_data << action
    end
    field_data
  end

  def self.parse_enemy_drops(enemy_id)
    field_data = []
    @temp_tables['EnemyDrops'].each do |row|
      next unless row[:enemy_id] == enemy_id
      drop = RPG::Enemy::ItemDrop.new
      drop.type = row[:type]
      drop.type_id = row[:type_id]
      drop.quantity = row[:quantity]
      drop.rate = row[:rate]
      field_data << drop
    end
    field_data
  end

  def self.parse_animation_timings(anim_id)
    # Get info from EnemyActions table
    field_data = []
    @temp_tables['AnimationTimings'].each do |row|
      next unless row[:animation_id] == anim_id
      timing = RPG::Animation::Timing.new
      timing.frame = row[:frame]
      timing.se = eval(row[:se]) # RPG::AudioFile.new
      timing.flash_scope = row[:flash_scope]
      timing.flash_color = eval(row[:flash_color]) # Color.new
      timing.condition = row[:condition]
      timing.shake_power = row[:shake_power]
      timing.shake_duration = row[:shake_duration]
      field_data << timing
    end
    field_data
  end

  # Convert values for a Table object, usually by getting values from a temporary table
  def self.parse_table(table_name, object_name, *params)
    case object_name
    when :actor_params
      # Parameters setup
      # TODO: Support level > 99 if this ever changes
      field_value = Table.new(6,100)
      100.times do |level|
        hp, sp, str, dex, agi, int = params[0] # FIXME: Why bother with splat if you're gunna do this??
        field_value[0,level] = @temp_tables[table_name][level][hp]
        field_value[1,level] = @temp_tables[table_name][level][sp]
        field_value[2,level] = @temp_tables[table_name][level][str]
        field_value[3,level] = @temp_tables[table_name][level][dex]
        field_value[4,level] = @temp_tables[table_name][level][agi]
        field_value[5,level] = @temp_tables[table_name][level][int]
      end
    when :class_ranks, :enemy_ranks
      # Element / State Rank setup
      tmax = @temp_tables[table_name].size - 1
      field_value = Table.new(tmax)
      column = params[0]
      tmax.times do |id|
        field_value[id] = @temp_tables[table_name][id][column]
      end
    when :actor_exp
      field_value = [0, 0]
      max_level, exp_curve = params[0]
      for level in 2..max_level
        field_value[level] = @temp_tables[table_name][level][exp_curve]
      end
    end
    field_value
  end
  # Battle Sequences
  BATTLE_INPUT = 'Data/Import/BattleAnime'
  # Sequences allow nil and are flattened
  SEQUENCE_FIELD = lambda{|field|
    if !field.nil?
      if field.start_with?(":") && field.respond_to?(:to_sym)
        field.delete_prefix!(":")
        field.to_sym
      else
        try_int = Integer(field, exception: false)
        if try_int.nil?
          field
        else
          try_int
        end
      end
    else
      field
    end
  }
  # Create single action object from CSV Row
  def self.create_action_object(type, row)
    obj = eval("BattleAnime::SingleAction::#{type}.new('#{row[:key]}')")
    row.each{|key, value| obj.send("#{key}=", value)}
    obj
  end
  # Load sequence data from CSV file
  def self.load_sequence_data
    sequences = {}
    logstr = ""
    filepath = "#{BATTLE_INPUT}/ActionSequences.csv"
    CSV.foreach(filepath, converters: [SEQUENCE_FIELD]) do |row|
      row.compact!
      key = row.shift.to_sym
      sequences[key] = BattleAnime::Sequence.new(key)
      sequences[key].actions = row
    end
    # Dump to RXDATA
    rxdatafile = OUTPUT_DIR + "BattleSequences.rxdata"
    save_data(sequences, rxdatafile)
    logstr << "Dumped ActionSequences to RXDATA :\n"
    PP.pp(sequences, logstr)
    logstr << "==========================\n"
    # Load directly into objects
    $data_battle_sequences = load_data(rxdatafile)
    puts "Loaded ActionSequences from CSV"
  end
  # Load single action data from CSV files
  def self.load_action_data
    data = {}
    logstr = ""
    BattleAnime::SingleAction.constants.each do |type|
      next if type == :SingleActionBase
      type = type.to_s
      filepath = "#{BATTLE_INPUT}/#{type}.csv"
      CSV.foreach(filepath, headers: true, nil_value: '', header_converters: [:symbol], converters: [EVAL_FIELD]) do |row|
        anim = create_action_object(type, row)
        if data.has_key?(anim.key)
          puts "Warning!!! Duplicate key #{anim.key} detected in Battle Animations! Old key was overwritten. Animation:"
          p anim
          puts "--------"
        end
        data[anim.key] = anim
      end
    end
    data.merge!(BattleAnime::DIRECTIVES)
    # Dump to RXDATA
    rxdatafile = OUTPUT_DIR + "BattleActions.rxdata"
    save_data(data, rxdatafile)
    logstr << "Dumped BattleActions to RXDATA :\n"
    PP.pp(data, logstr)
    logstr << "==========================\n"
    # Load directly into objects
    $data_battle_actions = load_data(rxdatafile)
    puts "Loaded SingleActions from CSV"
  end
end