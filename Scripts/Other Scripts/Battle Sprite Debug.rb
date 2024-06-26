#==============================================================================
# ** Battle Animation Debugger
#------------------------------------------------------------------------------
# Allows testing of battle animations
#==============================================================================
class Window_BattleDebug < Window_Selectable
  attr_accessor :state
  attr_accessor :last_index

  def initialize(x, y, width, height)
    super(x, y, width, height)
    @top_menu_commands = [
      "Set Enemy Troop", 
      "Set Actor", 
      "Reload Data", 
      "Test Action (Actor)",
      "Test Sequence (Actor)", 
      "Test Action (Enemy)",
      "Test Sequence (Enemy)", 
      "Exit"
    ]
    @column_max = 1
    @last_index = 0
    @state = :top
    self.z = 9999
  end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    # Initialize data array
    @data = []

    case @state
    when :top
      # Draw top menu
      @data = @top_menu_commands.dup
    when :troop
      # Draw troop list
      $data_troops.each{|troop| @data << troop}
    when :actor
      # Draw actor list
      $data_actors.each{|actor| @data << actor}
    when :action
      @data = $data_battle_actions.keys
    when :sequence
      # Draw sequence list
      @data = $data_battle_sequences.keys
    end

    @item_max = @data.size
    self.height = [720, 32 + row_max * line_height].min
    self.contents = Bitmap.new(width - 32, row_max * line_height)
    draw_list
  end

  def active=(value)
    super(value)
    self.opacity = value ? 255 : 50
  end

  def draw_list
    @data.each_with_index do |item, i|
      case @state
      when :top
        text = @data[i]
      when :troop, :actor
        text = @data[i].nil? ? "[None]" : @data[i].name
      when :action, :sequence
        text = @data[i].to_s
      end
      ir = item_rect(i)
      self.contents.draw_text(ir.x, ir.y, ir.width, ir.height, text)
    end
  end

  def item
    @data[self.index]
  end

  def dispose
    super
  end
end

class Scene_BattleDebug
  attr_accessor :spriteset

  DEFAULT_TROOP_ID = 33
  DEFAULT_ACTOR_ID = 1

  def initialize
    load_main_data
    @command_window = Window_BattleDebug.new(0,0,360,200)
    @command_window.refresh
    @command_window.active = true
    @command_window.index = 0
    setup_actor(DEFAULT_ACTOR_ID)
    setup_troop(DEFAULT_TROOP_ID)
    $game_map.setup(1)
  end

  def setup_active_battlers(type)
    case type
    when :actor
      @spriteset.set_target(true, 0, [$game_troop.enemies[0]])
    when :enemy
      @spriteset.set_target(false, 0, [$game_party.actors[0]])
    end
  end

  def update
    if @command_window.active?
      @command_window.update
      if Input.trigger?(Input::C)
        case @command_window.state
        when :top
          case @command_window.index
          when 0
            # Troop
            @command_window.state = :troop
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 1
            # Actor
            @command_window.state = :actor
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 2
            # Reload Data
            reload_data
            puts "Reloaded data!"
            return
          when 3
            # Test Action (Actor)
            @active_battler_type = :actor
            setup_active_battlers(:actor)
            @command_window.state = :action
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 4
            # Test Sequence (Actor)
            @active_battler_type = :actor
            setup_active_battlers(:actor)
            @command_window.state = :sequence
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 5
            # Test Action (enemy)
            @active_battler_type = :enemy
            setup_active_battlers(:enemy)
            @command_window.state = :action
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 6
            # Test Sequence (enemy)
            @active_battler_type = :enemy
            setup_active_battlers(:enemy)
            @command_window.state = :sequence
            orig_index = @command_window.index
            @command_window.index = @command_window.last_index
            @command_window.last_index = orig_index
          when 7
            # Exit
            $scene = nil
            return
          end
          @command_window.refresh
          return
        when :troop
          troop = @command_window.item
          if troop.nil?
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          setup_troop(troop.id)
          puts "set troop to #{troop.id}"
          @command_window.state = :top
          orig_index = @command_window.index
          @command_window.index = @command_window.last_index
          @command_window.last_index = orig_index
          @command_window.refresh
        when :actor
          actor = @command_window.item
          if actor.nil?
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          puts "set actor to #{actor.name}"
          setup_actor(actor.id)
          @command_window.state = :top
          orig_index = @command_window.index
          @command_window.index = @command_window.last_index
          @command_window.last_index = orig_index
          @command_window.refresh
        when :action
          action_key = @command_window.item
          if action_key.nil?
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          @command_window.active = false
          play_action(action_key, (@active_battler_type == :actor))
          return
        when :sequence
          sequence_key = @command_window.item
          if sequence_key.nil?
            $game_system.se_play($data_system.buzzer_se)
            return
          end
          @command_window.active = false
          play_sequence(sequence_key, (@active_battler_type == :actor))
        end
      elsif Input.trigger?(Input::B)
        if @command_window.state != :top
          orig_index = @command_window.index
          @command_window.index = @command_window.last_index
          @command_window.last_index = orig_index
          @command_window.state = :top
          @command_window.refresh
          return
        end
      end
    else
      @spriteset.update
      if Input.trigger?(Input::B)
        clear_action
        @command_window.active = true
      end
    end
  end

  def load_main_data
    GameSetup.load_database
    GameSetup.init_game_objects
    $game_options = Game_Options.new
  end
  
  def reload_data
    CSVLoader.load_sequence_data
    CSVLoader.load_action_data
  end
  
  def setup_troop(id)
    return if id.nil?
    $game_troop.setup(id)
    create_spriteset if @spriteset
  end

  def setup_actor(id)
    return if id.nil?
    10.times do |i|
      i += 1
      $game_party.remove_actor(i)
    end
    $game_party.add_actor(id)
    create_spriteset if @spriteset
  end
  
  def create_spriteset
    $game_temp.battleback_name = "_TESTBACK"
    @spriteset.dispose if @spriteset
    @spriteset = nil
    @spriteset = Spriteset_Battle.new(nil, true)
    @spriteset.center_camera
    @spriteset.default_zoom = 2.0
    60.times{ Graphics.update; @spriteset.update }
  end

  def clear_action
    @spriteset.set_stand_by_action(true, 0)
  end

  def play_action(action_key, actor = true)
    action = Game_BattleSequence.new(:temp_action, [:repeat_off,action_key,90,:repeat_on,'RESET_COORD'])
    @spriteset.set_action(actor, 0, action)
  end  

  def play_sequence(sequence_key, actor = true)
    @spriteset.set_action(actor, 0, sequence_key)
  end

  def main
    Graphics.transition
    create_spriteset
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end    
    terminate
  end

  def terminate
    @spriteset.dispose if @spriteset
    @spriteset = nil
    Graphics.freeze
    $scene = nil
  end
end