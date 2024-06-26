#==============================================================================
# ** Game_Troop
#------------------------------------------------------------------------------
#  This class deals with troops. Refer to "$game_troop" for the instance of
#  this class.
#==============================================================================

class Game_Troop
  #--------------------------------------------------------------------------
  # * Public instance variables
  #--------------------------------------------------------------------------
  attr_reader   :name_counts              # hash for enemy name appearance
  #--------------------------------------------------------------------------
  # * Characters to be added to the end of enemy names
  #--------------------------------------------------------------------------
  LETTER_TABLE = [' A',' B',' C',' D',' E',' F',' G',' H',' I',' J',
                  ' K',' L',' M',' N',' O',' P',' Q',' R',' S',' T',
                  ' U',' V',' W',' X',' Y',' Z']
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    # Create enemy array
    @enemies = []
  end
  #--------------------------------------------------------------------------
  # * Get Enemies
  #--------------------------------------------------------------------------
  def enemies
    return @enemies
  end
  #--------------------------------------------------------------------------
  # * Get id
  #--------------------------------------------------------------------------
  def id
    return @troop_id
  end
  #--------------------------------------------------------------------------
  # * Get name
  #--------------------------------------------------------------------------
  def name
    @name
  end
  #--------------------------------------------------------------------------
  # * Setup
  #     troop_id : troop ID
  #--------------------------------------------------------------------------
  def setup(troop_id)
    # Set array of enemies who are set as troops
    @enemies = []
    @troop_id = troop_id
    troop = $data_troops[troop_id]
    @name = troop.name
    for i in 0...troop.members.size
      enemy = $data_enemies[troop.members[i].enemy_id]
      if enemy != nil
        @enemies.push(Game_Enemy.new(troop_id, i))
      end
    end
    # Get all the enemy names
    make_unique_names
    # Set all positions
    setup_positions
  end
  #--------------------------------------------------------------------------
  # * Add letters (ABC, etc) to enemy characters with the same name
  #--------------------------------------------------------------------------
  def make_unique_names
    @names_count = {}
    @enemies.each do |enemy|
      next if enemy.dead?
      next unless enemy.letter.empty?
      n = @names_count[enemy.original_name] || 0
      enemy.letter = LETTER_TABLE[n % LETTER_TABLE.size]
      @names_count[enemy.original_name] = n + 1
    end
    @enemies.each do |enemy|
      n = @names_count[enemy.original_name] || 0
      enemy.plural = true if n >= 2
    end
  end
  #--------------------------------------------------------------------------
  # * Setup positions
  #--------------------------------------------------------------------------
  def setup_positions
    layout = positions.dup
    @enemies.each do |enemy|
      enemy.start_position[0] = BattleConfig::BATTLEFIELD_CENTER[0] + layout[enemy.index][0] + POS_X_OFFSET
      enemy.start_position[1] = BattleConfig::BATTLEFIELD_CENTER[1] + layout[enemy.index][1] + POS_Y_OFFSET
    end
  end
  #--------------------------------------------------------------------------
  # * Clear actions
  # Clear all enemy actions
  #--------------------------------------------------------------------------
  def clear_actions
    for enemies in @enemies
      enemies.current_action.clear
    end
  end
  #--------------------------------------------------------------------------
  # * Random Selection of a Target Enemy
  #     hp0 : limited to enemies with 0 HP
  #--------------------------------------------------------------------------
  def random_target_enemy(hp0 = false)
    # Initialize roulette
    roulette = []
    # Loop
    for enemy in @enemies
      # If it fits the conditions
      if (not hp0 and enemy.exist?) or (hp0 and enemy.hp0?)
        # Add an enemy to the roulette
        roulette.push(enemy)
      end
    end
    # If roulette size is 0
    if roulette.size == 0
      return nil
    end
    # Spin the roulette, choose an enemy
    return roulette[rand(roulette.size)]
  end
  #--------------------------------------------------------------------------
  # * Random Selection of a Target Enemy (HP 0)
  #--------------------------------------------------------------------------
  def random_target_enemy_hp0
    return random_target_enemy(true)
  end
  #--------------------------------------------------------------------------
  # * Smooth Selection of a Target Enemy
  #     enemy_index : enemy index
  #--------------------------------------------------------------------------
  def smooth_target_enemy(enemy_index)
    # Get an enemy
    enemy = @enemies[enemy_index]
    # If an enemy exists
    if enemy != nil and enemy.exist?
      return enemy
    end
    # Loop
    for enemy in @enemies
      # If an enemy exists
      if enemy.exist?
        return enemy
      end
    end
  end
end
