#==============================================================================
# ■ Battle Animation Sequence Class
#------------------------------------------------------------------------------
# Handling of battle animation sequences
#==============================================================================
class Game_BattleSequence
  
    attr_accessor :actions
    attr_reader :key
    attr_reader :index
    attr_reader :count
  
    def initialize(key, actions = [])
      @key = key
      @actions = actions
      @index = 0
      @count = 0
      @lock = false
    end
  
    def length
      @actions.size
    end
  
    def reset
      @lock = false
      @index = 0
      @count = 0
      @finished = false
    end
  
    def advance(amt = 1)
      return if @lock || length == 0
      @index = (@index + amt) % length
      # If we advanced back to the start, the action has finished
      if @index == 0 && @count != 0
        @finished = true
      end
      @count += amt
    end
  
    def rewind(amt = 1)
      return if @lock || length == 0
      @index = (@index - amt) % length
      @count -= amt
    end
  
    def current_action
      act_key = @actions[@index]
      if act_key.is_a?(Integer)
        return act_key
      end
      action = $data_battle_actions.dig(act_key)
      # Nil actions are sent for non-existant battlers? Why?
      if act_key != nil && action.nil?
        puts "Invalid action! #{act_key}"
        return $data_battle_actions[:no_action]
      end
      action
    end
  
    # Prevent advancing / rewinding
    def lock
      @lock = true
    end
  
    def unlock
      @lock = false
    end

    def locked?
      @lock
    end
  
    def finished?
      @finished
    end
  
    # Early termination
    def terminate
      @finished = true
    end
  
    def to_s
      "Sequence #{@key} - #{@actions} (#{@index}:#{@count})"
    end
  
    def last_index
      @data.size - 1
    end
  end
  