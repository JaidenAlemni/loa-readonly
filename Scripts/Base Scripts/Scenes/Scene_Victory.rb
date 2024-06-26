#==============================================================================
# * Battle Victory Scene
# Jaiden Alemni
# May 7th, 2022
#--------------------------------------
# Handles victory processing after battle.
#==============================================================================
class Scene_Victory 
  include BattleConfig
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize
    # Set the battle scene as a background
    @bg = Sprite.new
    @bg.bitmap = Graphics.snap_to_bitmap
    @bg.bitmap.blur
    @bg.z = 1
    @bg.visible = false
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #-------------------------------------------------------------------------- 
  def main
    # Initial Startup
    start
    # Execute transition
    Graphics.transition
    # Scene Loop
    loop do
      Graphics.update
      Input.update
      update
      break if $scene != self
    end
    # Clear windows
    cleanup
    # End scene
    terminate
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #-------------------------------------------------------------------------- 
  def start
    @bg.visible = true
    @results_updating = 0
    # Tracking finished exp gain
    @actors_finished_exp = []
    @all_max = false
    # Setup results
    setup_results
  end
  #--------------------------------------------------------------------------
  # * 
  #-------------------------------------------------------------------------- 
  def cleanup
    # If animating windows isn't disabled
    return if $game_options.disable_win_anim
    # Setup window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    (@result_windows + @sub_result_windows).each do |win| 
      win.move(MenuConfig::WINDOW_OFFSCREEN_RIGHT, win.y, MenuConfig::WIN_ANIM_SPEED)
      windows << win
    end
    @exp_result.move(MenuConfig::WINDOW_OFFSCREEN_LEFT, @exp_result.y, MenuConfig::WIN_ANIM_SPEED)
    @result_window.move(MenuConfig::WINDOW_OFFSCREEN_LEFT, @result_window.y, MenuConfig::WIN_ANIM_SPEED)
    @results_help.move(MenuConfig::WINDOW_OFFSCREEN_RIGHT, @results_help.y, MenuConfig::WIN_ANIM_SPEED)
    windows.push(@result_window, @results_help, @exp_result)
    # Animate windows
    MenuConfig::WIN_ANIM_TIME.times do |i|
      Graphics.update
      windows.each do |window|
        window.update
        if i > MenuConfig::WIN_ANIM_TIME / 4
          window.opacity -= (255 / MenuConfig::WIN_FADE_SPEED + 1)
          window.contents_opacity -= (255 / MenuConfig::WIN_FADE_SPEED + 1) * 2
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * 
  #-------------------------------------------------------------------------- 
  def terminate
    # Prepare for transition
    Graphics.freeze
    # Dispose of windows  
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      ivar.dispose if ivar.is_a?(Window)
      ivar = nil
    end
    @result_windows.each{|w| w&.dispose; w = nil}
    @level_windows.each{|w| w&.dispose; w = nil}
    @sub_result_windows.each{|w| w&.dispose; w = nil}
    @sub_level_windows.each{|w| w&.dispose; w = nil}
    # Dispose of background
    @bg.dispose
  end
  #--------------------------------------------------------------------------
  # * 
  #-------------------------------------------------------------------------- 
  def close_scene
    # Add enemies to the bestiary and revive dead players
    $game_troop.enemies.each do |enemy|
      $game_system.encounter_enemy(enemy.id)
    end
    # Clear enemies
    $game_troop.enemies.clear
    # Call battle callback (win/lose/escape branches)
    if $game_temp.battle_proc != nil
      $game_temp.battle_proc.call(0) # 0 = WIN
      $game_temp.battle_proc = nil
    end
    # Move to map scene
    $game_map.refresh
    # Recall sounds
    resume_sound_post_battle unless $game_temp.continue_map_bgm_battle
    $game_temp.continue_map_bgm_battle = false
    # Reset camera
    $scene = Scene_Map.new
  end
  #--------------------------------------------------------------------------
  # * 
  #-------------------------------------------------------------------------- 
  def update
    # Fade out bg
    @bg.opacity -= 10 if @bg.opacity > 200
    # Update Windows
    instance_variables.each do |varname|
      ivar = instance_variable_get(varname)
      if ivar.is_a?(Window)
        ivar.update
      end
    end  
    # Result screen windows
    @result_windows.each{|win| win.update} if @result_windows
    @level_windows.each{|win| win.update} if @level_windows
    @sub_result_windows.each{|win| win.update} if @sub_result_windows
    # Move windows
    if @result_window.moving?
      return
    end
    if @results_updating == 0
      @results_updating = 1
      #Check each actor in party
      for actor in $game_party.actors(:all)
        #If the actor can get EXP
        unless actor.cant_get_exp?
          #Set old EXP to the actor's EXP
          actor.old_exp = actor.exp
          #Set the max exp to the actors EXP + their exp again?
          actor.max_exp = actor.exp + @gained_exp
          #Set plus_exp to the actors EXP to the next level * filling speed?
          actor.plus_exp = [actor.next_exp * EXP_FILL_SPEED / 250.0, 1].max.to_i
        end
      end
    end
    update_result_window
    # Player input
    if (Input.trigger?(BATTLE_INPUT[:Confirm]) || Input.trigger?(BATTLE_INPUT[:Back]))
      # If exp bars are counting up
      if @results_updating == 1
        # stop results
      else
        close_scene
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Resume sound after battle exit
  #--------------------------------------------------------------------------
  def resume_sound_post_battle
    #Play BGM
    if $game_system.memorized_bgm != nil && $game_system.memorized_bgm != ''
      $game_system.bgm_restore
    else
      $game_system.bgm_stop
    end
    # Play bgs
    if $game_system.memorized_bgs != nil && $game_system.memorized_bgs != ''
      $game_system.bgs_restore
    else
      $game_system.bgs_stop
    end
  end
  #--------------------------------------------------------------------------
  # * Create result windows
  #--------------------------------------------------------------------------
  def setup_results
    # Local window variables
    x_origin = MenuConfig::MENU_ORIGIN_X
    y_origin = MenuConfig::MENU_ORIGIN_Y
    help_height = MenuConfig::HELP_HEIGHT_TALL
    treasure_win_width = 320
    # Get enemy treasure, exp and gold
    treasures = []
    gold = 0
    exp = 0
    $game_troop.enemies.each do |enemy|
      next if enemy.hidden
      exp = enemy.exp
      gold += enemy.gold
    end
    treasures = enemy_item_drops
    # Gain EXP
    @gained_exp = exp
    # Add treasure/gold to party inventory
    $game_party.gain_battle_spoil(gold, treasures)
    # Create treasure window
    @result_window = Window_BattleTreasure.new(x_origin, y_origin, treasure_win_width, MenuConfig::MENU_WINDOW_HEIGHT - help_height, treasures)
    @result_window.treasures = treasures
    # Create exp/gold window
    exp_gold = [@gained_exp, gold]
    @exp_result = Window_BattleExpGold.new(x_origin, y_origin + @result_window.height, 240, help_height, exp_gold)
    # Create active actor windows
    @result_windows = []
    @level_windows = []
    ww = 360
    wh = (MenuConfig::MENU_WINDOW_HEIGHT - help_height) / 2
    3.times do |i|
      x = @result_window.width + x_origin + i % 2 * ww
      y = y_origin + i / 2 * wh
      @result_windows[i] = Window_BattleResult.new(x, y, ww, wh, $game_party.actors[i])
      @level_windows[i] = Window_LevelUp.new(x + 188, y + 160)
    end
    # Create inactive actor windows
    @sub_result_windows = []
    @sub_level_windows = []
    sub_wh = wh / 3
    3.times do |i|
      x = x_origin + @result_window.width + ww
      y = y_origin + wh + i * sub_wh
      # TODO This is a little dicey, needs to be rewritten
      @sub_result_windows[i] = Window_SubBattleResult.new(x, y, ww, sub_wh, $game_party.standby_actors[i])
      @sub_level_windows[i] = Window_LevelUp.new(x + 200, y + 10)
    end
    # Create help window
    @results_help = Window_SuperHelp.new(x_origin + @exp_result.width, y_origin + MenuConfig::MENU_WINDOW_HEIGHT - help_height, MenuConfig::MENU_WINDOW_WIDTH, help_height)
    @results_help.z = 9000
    @results_help.opacity = 255
    # Associate help
    @result_window.help_window = @results_help
  end
  #--------------------------------------------------------------------------
  # * Update Result Window
  #--------------------------------------------------------------------------
  def update_result_window
    return unless @results_updating == 1
    # Loop in actors
    $game_party.actors.each_with_index do |actor, i|
      # Gain actor EXP, and determine if they're done
      done = update_actor_exp(actor, i, false)
      # Skip check
      if Input.trigger?(BATTLE_INPUT[:Confirm])
        for index in 0...$game_party.actors.size
          battler = $game_party.actors[index]
          done = update_actor_exp(battler, index, true)
        end
        @all_max = true
      elsif actor.level == 99
        done = update_actor_exp(actor, i, true)
      end
      # Done gaining check
      if done
        @actors_finished_exp << true
        if @actors_finished_exp.size == $game_party.actors.size
          @all_max = true
          break
        end
      end
    end
    if @all_max
      @results_updating = 2
    end
  end
  #----------------------------------------------------------------
  # * Update actor exp
  #     actor : actor
  #     index : index
  #     skip  : skip flag
  #  Returns finished filling state
  #----------------------------------------------------------------
  def update_actor_exp(actor, index, skip)
    finished = false
    #If the actor can gain EXP and their current EXP is less than their max
    if actor.cant_get_exp? == false && actor.exp < actor.max_exp
      last_level = actor.level
      if actor.exp + actor.plus_exp > actor.max_exp || skip
        actor.exp = actor.max_exp
        finished = true
      else
        actor.exp += actor.plus_exp
        finished = false
      end
      if actor.level > last_level 
        #Recover SP + HP
        #actor.hp = actor.maxhp
        #actor.sp = actor.maxsp
        $game_system.se_play(RPG::AudioFile.new(LEVEL_UP_SFX, 80, 100))
        @level_windows[index]&.refresh
        #@sub_level_windows[index].refresh
        actor.plus_exp =  [actor.next_exp * EXP_FILL_SPEED / 250.0, 1].max.to_i
      end
      @level_windows[index]&.update
      #@sub_level_windows[index].update
      # TODO This could be optimized better
      @result_windows[index]&.refresh
    else
      finished = true
    end
    return finished
  end
  #--------------------------------------------------------------------------
  # * Get enemy drops (vanilla method, unused)
  #--------------------------------------------------------------------------
  # def treasure_drop(enemy)
  #   if rand(100) < enemy.treasure_prob
  #     treasure = $data_items[enemy.item_id] if enemy.item_id > 0
  #     treasure = $data_weapons[enemy.weapon_id] if enemy.weapon_id > 0
  #     treasure = $data_armors[enemy.armor_id] if enemy.armor_id > 0
  #   end
  #   return treasure
  # end
  #--------------------------------------------------------------------------
  # * Add extra item drops 
  #--------------------------------------------------------------------------
  def enemy_item_drops
    drop_items = []
    $game_troop.enemies.each do |enemy|
      $data_enemies[enemy.id].drops.each do |drop|
        next unless (rand(1000) < drop.rate)
        drop.quantity.times do
          drop_items << case drop.type
                        when :item then $data_items[drop.type_id] 
                        when :armor then $data_armors[drop.type_id] 
                        when :weapon then $data_weapons[drop.type_id]
                        when :essence then $data_essences[drop.type_id]
                        end
          end
      end
    end
    drop_items.flatten!
    drop_items.sort! {|a, b| a.id <=> b.id}
    drop_items.sort! do |a, b|
      a_class = a.is_a?(RPG::Item) ? 0 : a.is_a?(RPG::Weapon) ? 1 : 2
      b_class = b.is_a?(RPG::Item) ? 0 : b.is_a?(RPG::Weapon) ? 1 : 2
      a_class <=> b_class
    end
    return drop_items
  end
end
