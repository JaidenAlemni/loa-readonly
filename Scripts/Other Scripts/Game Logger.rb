require 'pp'
#===============================================================================
# ** Game Logger
# Logs a player's game session for debugging and analysis purposes
#===============================================================================
class GameLogger

  def initialize
    # If we don't want to log anything ignore this and all functions
    @disabled = (CFG["astravia"]["gameSessionLog"] == 0)
    # This is written to the file on close
    @filename = "sesh_#{Time.now.strftime('%Y-%m-%d_%H%M%S%L')}"
    @buffer = ""
    @footer = ""
    return if @disabled
    @buffer << header
    # Go ahead and just always write the header to the log
    GUtil.write_log(header)
  end
  
  def write_line(str, timestamp = true)
    return if @disabled
    if timestamp
      @buffer << "#{Time.now} : " + str + "\n"
    else
      @buffer << ": " + str + "\n"
    end
  end

  # Just toss everything in there
  def dump_state
    @buffer << $scene.inspect + "\n"
    @buffer << $game_party.inspect + "\n"
    @buffer << $game_troop.inspect + "\n"
    @buffer << $game_temp.inspect + "\n"
  end

  def close
    return if @disabled
    total_sec = System.uptime
    hour = total_sec / 60 / 60
    min = total_sec / 60 % 60
    sec = total_sec % 60
    time_string = sprintf("%02d:%02d:%02d", hour, min, sec)
    self.write_line("Session time: #{time_string}")
    file = "#{GameSetup.user_directory}/#{@filename}"
    data = @buffer + @footer
    File.open(file, 'w') { |f| f.write(data) }
  end

  # String methods (push these to the buffer directly)
  def header
%Q(
=========================================================
** #{Time.now} - GAME START **
---------------------------------------------------------
  DEMO? #{$DEMO} BETA? #{$BETA} STEAM? #{$IS_STEAM} DEBUG? #{$DEBUG}
  ARGV: #{ARGV}
  Language: #{System.user_language}
  Platform: #{System.platform}
  Version: #{$BUILD_VERSION}
---------------------------------------------------------
* Current Options
  #{$game_options.inspect}
* MKXP Config
  #{CFG.to_hash}
)
  end

  def battle_state(note = "Unspecified")
    str = %Q(
=========================================================
** #{Time.now} - STATE CHECK : #{note}
Battle Speed: #{$game_options.battle_speed} | Camera: [#{Camera.x},#{Camera.y}]
Input State [#{$scene.input_state}] | Active Window: #{$scene.active_window}
ATB Battlers: #{ATB.battlers.map{|b| b.name + " " + b.atb_state.to_s}}
)
    $game_party.actors.each do |actor|
      str << actor.to_s
    end
    $game_troop.enemies.each do |enemy|
      str << enemy.to_s
    end
    str
  end

  def battle_start
    str = %Q(
=========================================================
** #{Time.now} - BATTLE START
TROOP ID: #{$game_temp.battle_troop_id}
)
    $game_party.actors.each do |actor|
      str << actor.detailed_p
    end
    $game_troop.enemies.each do |enemy|
      str << enemy.detailed_p
    end
    str
  end

  # Damage at each step of the formula
  def damage_step(step, amount, *params)
    return if !$DEBUG || @disabled
    str = 
      case step
      when :start
        "Start damage calc (type: #{params[0]} perfect? #{params[1]}) - "
      when :hit
        "Hit chance (luk adjust: #{params[0]}) - "
      when :base_formula
        "After base calc (formula: #{params[0]}) - "
      when :variance
        "After variance (amt: #{params[0]}) - "
      when :ee
        "After EE (multiplier: #{params[0]}) - "
      when :defense
        "After defense (reduction: #{params[0]}%) - "
      when :guard
        "After guard (blocked: #{params[0]}) - "
      when :crit
        "Crit chance (roll: #{params[0]}) 0.1% - "
      when :crit_damage
        "After crit (%: #{params[0]}) - "
      when :evasion
        "Evasion % - "
      when :essence
        "After essence - "
      when :damage
        "Apply damage (type: #{params[0]} effective: #{params[1]}) - "
      when :states
        ""
      else
        ""
      end
    str += (amount.nil? ? "NIL!" : amount.to_s)
    puts str if $DEBUG
    self.write_line(str)
  end
end
#-----------------------------------------------------------------------------
# * Print Methods and Class Overrides
#-----------------------------------------------------------------------------
class Game_Battler
  def to_s
%Q(
  --------------------------------------------------
  ** ACTOR ##{@actor_id} : #{self.name}
  LE : #{self.hp}/#{self.maxhp} | ME : #{self.sp}/#{self.maxsp} | Unleash: #{@overdrive} ATK: #{self.atk} DEX: #{self.dex} INT: #{self.int} PDEF: #{self.pdef} MDEF: #{self.mdef} AGI: #{self.agi} LUK: #{self.luk}
  --------------------------------------------------
  * Battle State
  Exist? #{self.exist?} | Dead? #{self.dead?} | Movable? #{self.movable?} | Immortaling? #{self.immortal} | Action Ready? #{self.ready_for_action?} | Commit Ready? #{self.ready_for_commit?} | Input Ready? #{self.ready_for_input?}"
  Speed: #{self.base_speed} | ATP: #{@atp} (Com: #{ATB::COMMIT_ATP} Act: #{ATB::MAX_ATP}) | State: #{@atb_state} | Counting: #{@countup}
  Current Action: #{self.current_action&.to_s}
  Last Target: #{self.last_target&.name} | Targets: #{self.targets.map{|t| t&.name}}
) 
  end
end

class Scene_Map
  alias glog_call_battle call_battle
  def call_battle
    glog_call_battle
    $GLOG.write_line("Called battle")
  end

  alias glog_call_menu call_menu
  def call_menu
    glog_call_menu
    $GLOG.write_line("Called menu")
  end

  alias glog_player_map_transfer player_map_transfer
  def player_map_transfer(map_to, offset, t_dir)
    $GLOG.write_line("Changed maps")
    $GLOG.write_line("Game Temp: #{$game_temp.inspect}",false)
    glog_player_map_transfer(map_to, offset, t_dir)
  end

end

class Scene_SaveLoad
  alias glog_load_file load_file
  def load_file(filename)
    glog_load_file(filename)
    $GLOG.write_line("Loaded save: #{filename}")
  end

  alias glog_save_file save_file
  def save_file(filename)
    glog_save_file(filename)
    $GLOG.write_line("Saved a file: #{filename}")
  end
end

class Scene_Battle
  alias glog_battle_start start
  def start
    glog_battle_start
    $GLOG.write_line($GLOG.battle_start, false)
  end

  alias glog_end_action_phase end_action_phase
  def end_action_phase
    glog_end_action_phase
    $GLOG.write_line($GLOG.battle_state("Action Ending"), false)
  end

  alias glog_update update
  def update
    @last_log_time = 0 if @last_log_time.nil?
    if System.uptime.round - @last_log_time >= 20
      $GLOG.write_line($GLOG.battle_state("Battle 20 Second Check"), false)
      @last_log_time = System.uptime.round
    end
    glog_update
  end
end

class Game_Actor
  def detailed_p
%Q(
  ==================================================
  ** ACTOR ##{@actor_id} : #{self.name}

  Team Index: #{self.index} | Party Index: #{$game_party.actors(true)&.index(self)} | Level: #{self.level} 

  LE : #{self.hp}/#{self.maxhp} | ME : #{self.sp}/#{self.maxsp} | Unleash: #{@overdrive}
  ATK: #{self.atk} DEX: #{self.dex} INT: #{self.int} PDEF: #{self.pdef} MDEF: #{self.mdef} AGI: #{self.agi} LUK: #{self.luk}

  --------------------------------------------------
  * Equipment

  Wep: #{$data_weapons[@weapon_id].nil? ? "NONE" : $data_weapons[@weapon_id].name}
  Arm: #{$data_armors[@armor1_id].nil? ? "NONE" : $data_armors[@armor1_id].name}
  Hnd: #{$data_armors[@armor2_id].nil? ? "NONE" : $data_armors[@armor2_id].name}
  Acc: #{$data_armors[@armor3_id].nil? ? "NONE" : $data_armors[@armor3_id].name}
  Rng: #{$data_armors[@armor4_id].nil? ? "NONE" : $data_armors[@armor4_id].name}
  --------------------------------------------------
  * Essence

  #{@essences.map{|id| $data_essences[id]&.name}}
  --------------------------------------------------
  * Skills

  #{@skills.map{|id| $data_skills[id]&.name}}
)
  end
end

class Game_Enemy
  def detailed_p
str = %Q(
  ==================================================
  ** ENEMY ##{@enemy_id} : #{self&.name}

  Troop Index: #{self&.index} 
  LE : #{self.hp}/#{self.maxhp} | ME : #{self.sp}/#{self.maxsp}
  ATK: #{self.atk} DEX: #{self.dex} INT: #{self.int} PDEF: #{self.pdef} MDEF: #{self.mdef} AGI: #{self.agi} LUK: #{self.luk}
    )

str << %Q(
  --------------------------------------------------
  * Actions
)
      self.actions.each{|a| str << a.to_s}
str << %Q(
  --------------------------------------------------
  * Battle State

  Exist? #{self.exist?} | Dead? #{self.dead?} | Movable? #{self.movable?} | Immortaling? #{self.immortal}
  Speed: #{self.base_speed} | ATP: #{self.atp} (Com: #{ATB::COMMIT_ATP} Act: #{ATB::MAX_ATP}) | State: #{self.atb_state} | Counting: #{self.countup}
  Action Ready? #{self.ready_for_action?} | Commit Ready? #{self.ready_for_commit?} | Input Ready? #{self.ready_for_input?}"
  Action Count: #{self.action_count} | Current Action: 
  #{self.current_action&.to_s}
  Last Target: #{self.last_target&.name} | Targets: #{self.targets.map{|t| t&.name}}
)
str
  end
end

module RPG
  class Enemy
    class Action
      def to_s
        return %Q(
      -----------------------------------------------
      * RPG::Enemy::Action - Rating: #{self.rating}
      Kind: #{self.kind} | Basic: #{self.basic} | Skill ID: #{self.skill_id} | Item ID: #{self.item_id} | Weapon ID: #{self.weapon_id}
      Every #{self.condition_turn_a} + #{self.condition_turn_b}X Actions
      Behavior: #{self.behavior} | Custom: #{self.condition_custom} #{self.custom_params}
        )
      end
    end
  end
end

# Weird pp thing -- supposed to pull from IO but using .pretty_inspect
# looks for it in the string.
class String
  def winsize
    80
  end
end