#==============================================================================
# ** Battle Tutorial
#------------------------------------------------------------------------------
# Special methods for handling the battle tutorial, which is uniquely scripted
# Also includes the "select battle type" graphics and update methods
#==============================================================================
class Scene_Battle
  def start_battle_type_select
    @option_sprites = []
    @option_text_sprites = []
    @text_sprites = []
    @options_index = 0
    # Freeze and blur
    @temp_bg = Sprite.new(@spriteset.viewport4)
    @temp_bg.bitmap = Graphics.snap_to_bitmap
    @temp_bg.bitmap.blur
    @temp_bg.bitmap.blur
    @temp_bg.color = Color.new(50,10,0,200)
    @temp_bg.opacity = 0
    @prompt_sprite = Sprite.new(@spriteset.viewport4)
    @prompt_sprite.visible = false
    @prompt_sprite.bitmap = RPG::Cache.icon("Prompt/LR_KB.gif")
    @prompt_sprite.bitmap.play
    @prompt_sprite.bitmap.frame_rate = 2.5
    @prompt_sprite.set_origin(:center)
    @prompt_sprite.x = LOA::SCRES[0] / 2
    @prompt_sprite.y = LOA::SCRES[1] / 2 - 64
    # Overlay graphics
    2.times do |i|
      # Graphic sprites
      s = Sprite.new(@spriteset.viewport4)
      s.z += 100
      i == 0 ? s.opacity = 0 : s.visible = false
      # Branch by controller type
      suffix = Input.tutorial_graphic_suffix
      s.bitmap = RPG::Cache.system("Tutorial/BattleType#{i}_#{suffix}")
      @option_sprites << s
      # Graphics text overlay
      t = Sprite.new(@spriteset.viewport4)
      t.bitmap = Bitmap.new(360,424)
      t.y = 56
      t.z += 150
      t.opacity = 0
      @option_text_sprites << t
    end
    @option_text_sprites[0].x = 160
    @option_text_sprites[1].x = 760
    redraw_battle_type_text
    # Create the window
    texts = Localization.localize("&MUI[BattleTypePrompt]").split("\\n")
    texts.each_with_index do |line, i|
      @text_sprites[i] = Sprite_ScreenText.new(@spriteset.viewport4, "", 540 + (40 * i), 10)
      @text_sprites[i].draw(line, 1, 125, Font.speech_name)
    end
    #$game_options = load_data("Data/Options.rxdata")
    update_battle_type_graphics(:fade_in)
  end

  def redraw_battle_type_text(disabled_index = 1)
    # Draw text to bitmaps based on loc
    @option_text_sprites.each_with_index do |sprite, i|
      bw = sprite.bitmap.width
      bh = sprite.bitmap.height
      sprite.bitmap.clear
      # Title
      sprite.bitmap.font.size = Font.scale_size(175)
      sprite.bitmap.font.name = Font.default_name
      sprite.bitmap.font.color = disabled_index == i ? Window_Base::DISABLED_COLOR : Window_Base::WHITE_COLOR
      sprite.bitmap.draw_text(0, 0, bw, 64, "&MUI[BattleTypeTitle#{i}]", 1)
      # Controls
      sprite.bitmap.font.color = disabled_index == i ? Window_Base::DISABLED_COLOR : Window_Base::GOLD_COLOR
      sprite.bitmap.font.name = Font.numbers_name
      text = Localization.localize("&MUI[BattleTypeControls]")
      lines = text.split("\n")
      lines.each_with_index do |line, j|
        sprite.bitmap.draw_text(j * (bw / 3), 300, (bw / 3), 32, line, 1)
      end
      # Description, split by newlines
      sprite.bitmap.font.color = disabled_index == i ? Window_Base::DISABLED_COLOR : Window_Base::WHITE_COLOR
      text = Localization.localize("&MUI[BattleTypeExplain#{i}]")
      lines = text.split("\n")
      lines.each_with_index do |line, j|
        sprite.bitmap.draw_text(8, 346 + 24 * j, bw, 24, line, 0)
      end
    end

  end

  def update_battle_type_select
    Graphics.update
    Input.update
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      $game_system.se_play($data_system.cursor_se)
      redraw_battle_type_text(@options_index)
      @options_index = (@options_index + 1) % 2
      @option_sprites.each_with_index{|s, i| s.visible = (@options_index == i)}
    end
    if Input.trigger?(MenuConfig::MENU_INPUT[:Confirm])
      case @options_index
      when 0
        $game_options.battle_ab_style = false
      when 1
        $game_options.battle_ab_style = true
      end
      $game_system.se_play($data_system.decision_se)
      $game_temp.battle_tutorial = true
    end
  end

  def update_battle_type_graphics(direction, time = 90)
    case direction
    when :fade_in
      interval = (255 / time) + 1
      @text_sprites.each{|ts| ts.display = true}
    when :fade_out
      interval = -(255 / time) + 1
      @text_sprites.each{|ts| ts.display = false}
    end
    time.times do |i|
      Graphics.update
      @option_sprites.each{|s| s.opacity += interval}
      @temp_bg.opacity += interval
      @text_sprites.each{|s| s.opacity += interval} if direction == :fade_out
      @prompt_sprite.opacity += interval if direction == :fade_out
      @option_text_sprites.each{|s| s.opacity += interval}
    end
    if direction == :fade_in
      90.times do |i|
        Graphics.update
        if i < 30
          @text_sprites[0].update
        elsif i < 60
          # Do nothing
        else
          @text_sprites[1].update
          @prompt_sprite.opacity += 10
        end
      end
      @prompt_sprite.visible = true
    end
  end

  def end_battle_type_select
    # Fade out graphics
    update_battle_type_graphics(:fade_out, 30)
    # Save to options
    GameSetup.save_options
    # Dispose of all graphics, windows, variables
    @option_sprites.each{|s| s.dispose}
    @text_sprites.each{|s| s.dispose}
    @option_text_sprites.each{|s| s.dispose}
    @temp_bg.dispose
    @prompt_sprite.dispose
    @temp_bg = nil
    @option_sprites = nil
    @text_sprites = nil
    @option_text_sprites = nil
  end
end