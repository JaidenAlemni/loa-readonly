#==============================================================================
# * Cutscene Module
# Configuration module for cutscenes, which also contains the list of commands
# to be processed in the cutscene's update loop.
# ----------------------------------------------------------------------------
# Available commands:
# [:end_scene]
#   Defaults to the map for now, if more scenes are 
#   needed later that can be addressed.
# [:wait, SECONDS]
# [:input_wait]
# [:show_picture, number, filename, origin, x, y, zoom_x, zoom_y, opacity, blend_type]
# [:move_picture, number, SECONDS, origin, x, y, zoom_x, zoom_y, opacity, blend_type]
# [:show_plane, number (0-3)]
# [:hide_plane, number (0-3)]
# [:shake_screen, SECONDS, power]
# [:change_screen_tone, Tone.new(), SECONDS]
# [:flash_screen, Color.new(), FRAMES]
# [:thunder, FRAMES]
#   We use frames for flashes/thunder since frame precision is required.
# [:play_se, RPG::AudioFile.new(name, vol, pitch)]
# [:play_bgm, RPG::AudioFile.new(name, vol, pitch)]
# [:play_bgs, RPG::AudioFile.new(name, vol, pitch)]
# [:fade_bgs, SECONDS]
# [:fade_bgm, SECONDS]
# [:show_text, position, 'string']
# [:hide_text, position]
# 
#==============================================================================
module Cutscene
  # Thunder sound effect
  THUNDER_SE = 'MAP_ThunderClap'
  FONT_COLOR = Color.new(220,220,220)#Color.new(20,15,25)
  # Frame sprite
  FRAME_SPRITE = 'Intro_Frame'
  # Tones
  BLACK_TONE = Tone.new(102,64,31)
  NORMAL_TONE = Tone.new(0,0,0)
  # Screen center coordinates
  SC_X = LOA::SCRES[0] / 2
  SC_Y = LOA::SCRES[1] / 2
  #--------------------------------------------------------------------------
  # * Plane configuration
  # Array of planes with configuration values (similar to fogs)
  #--------------------------------------------------------------------------  
  def self.plane_data(scene)
    case scene
    when :cataclysm
      [
        # ["Name",Blend (0:norm, 1:add, 2:sub), scroll x, scroll y, z_index]
        ["Cataclysm/Part1_Clouds", 0, 1, 0, 3],
        ["Cataclysm/Part2_Debris1", 1, 0, -1, 7],
        ["Cataclysm/Part2_Debris2", 1, -1, -1, 8],
        ["", 0, 0, 0, 0]
      ]
    end
  end
  #--------------------------------------------------------------------------
  # * Get command from file
  #--------------------------------------------------------------------------
  def self.command_list(list)
    case list
    when :cataclysm
      return CATACLYSM
      # begin
      #   contents = File.read("Data/Cutscenes/INTRODUCTION")
      # rescue
      #   raise("Could not open cutscene file.")
      # end
      # ary = Kernel.eval(contents)
    end
    #return ary
  end   
  #--------------------------------------------------------------------------
  # * Scene command lists
  #--------------------------------------------------------------------------   
  CATACLYSM = [
    # Make screen black
    [:show_picture, 22, "Intro_Frame_2",  0, 0,   0, 100, 100,0, 0],
    [:show_picture, 21, "Intro_Frame",  0, 0,   0, 100, 100,0, 0],
    [:show_picture, 23, "Frame_Cover",    0, 0,   0, 100, 100,255, 0],
    # Prepare all of the pictures and assign them appropriately
    [:show_picture, 1, "Cataclysm/Part1_BG",        0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 2, "Cataclysm/Part1_Mtns",      0, 0, 520, 100, 100, 0, 0],
    [:show_picture, 4, "Cataclysm/Part1_Lightning", 0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 5, "Cataclysm/Part2_BG",        0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 6, "Cataclysm/Part2_Mtn",       0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 9, "Cataclysm/Part2_People",    0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 10, "Cataclysm/Part3_BG",       0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 11, "Cataclysm/Part3_Light",    1, SC_X, SC_Y,   0,   0, 0, 0],
    [:show_picture, 12, "Cataclysm/Part3_Mtn",      0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 13, "Cataclysm/Part3_Shadows",  0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 14, "Cataclysm/Part4_BG",       0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 15, "Cataclysm/Part4_Plant",    0, 0, 200, 100, 100, 0, 0],
    [:show_picture, 16, "Cataclysm/Part4_Vine",     0, 0, 200, 100, 100, 0, 0],
    [:show_picture, 20, "Cataclysm/Part4_Plant2",   0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 17, "Cataclysm/Part4_Shadows",  0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 18, "Cataclysm/Part4_Shield",   0, 0,   0, 100, 100, 0, 0],
    [:show_picture, 19, "Cataclysm/Part5_BG",       0, 0,   0, 100, 100, 0, 0],
    #[:show_picture, 20, "Part5_Essence",  1, SC_X, SC_Y, 100, 100, 0, 0],
    [:change_screen_tone, NORMAL_TONE, 6.0],
    [:wait, 0.25],
    [:play_bgm, RPG::AudioFile.new('1M_SCE_Cataclysm', 75, 100)],
  # Show the BG of the first scene
    [:move_picture, 1, 4.0, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:show_plane, 0],
    [:wait, 4.0],
    [:move_picture, 2, 1.0, 0, 0, 520, 100, 100, 255, 0, :ease_out],
    [:move_picture, 3, 1.0, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:wait, 2.0],
    # Fade in graphics
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 0, 0, :linear], # Fade in
    [:wait, 1.0],
    # "Fated to perish..."
    [:show_text, 1, '&A1S[PrologueIntro_002]'],
    [:wait, 3.0],
    #[:thunder, 5],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:wait, 0.1],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 0, 0, :ease_out],
    [:wait, 1.0],
    #[:thunder, 4],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:wait, 0.1],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 0, 0, :ease_out],
    [:wait, 1.0],
    # Shake mountain, flash lightning
    # "Watched in terror, ground quaked..."
    [:show_text, 2, '&A1S[PrologueIntro_003]'],
    [:wait, 2.0],
    [:shake_screen, 5.5, 5],
    #[:play_bgs, RPG::AudioFile.new('Quake', 80, 80)],
    [:move_picture, 2, 5.0, 0, 0,-400, 100, 100, 255, 0, :ease_in],
    [:wait, 1.0],
    [:move_picture, 23, 4.0, 0, 0, 0, 100, 100, 255, 0, :linear], # Fade out
    #[:thunder, 4],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:wait, 0.1],
    [:move_picture, 4, 0.1, 0, 0, 0, 100, 100, 0, 0, :ease_out],
    [:wait, 4.0],
    [:fade_bgs, 1.0],
    [:hide_plane, 0],
    [:show_plane, 1],
    [:show_plane, 2],
    [:wait, 1.0],
    # Fade in new bg
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 0, 0, :linear], # Fade in
    #[:play_bgs, RPG::AudioFile.new('Quake2', 80, 100)],
    [:move_picture, 5, 2.0, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:move_picture, 6, 2.0, 0, 0, 0, 100, 100, 200, 0, :ease_out],
    [:wait, 0.1],
    [:move_picture, 9, 2.0, 0, 0, 0, 100, 100, 255, 0, :ease_out],
    [:wait, 1.5],
    # Part 1 B
    [:show_text, 3, '&A1S[PrologueIntro_004]'],
    [:wait, 3.0],
    [:input_wait],
    [:move_picture, 23, 4.0, 0, 0, 0, 100, 100, 255, 0, :linear], # Fade out
    [:fade_bgs, 1.0],
    [:wait, 1.5],
    [:hide_text, 1],
    [:hide_text, 2],
    [:hide_text, 3],
    [:wait, 3.0],
    [:show_text, 0, '&A1S[PrologueIntro_005]'],
    [:wait, 1.5],
    [:hide_plane, 1],
    [:hide_plane, 2],
    [:input_wait],
    [:hide_text, 0],
    # Part 2 (10-13)
    [:move_picture, 10, 0.1,  0, 0,   0, 100, 100, 255, 0, :ease_out], #BG
    [:move_picture, 11, 0.1,  1, SC_X, SC_Y,   0,   0, 255, 0, :ease_out], #Light
    [:move_picture, 12, 0.1,  0, 0,   0, 100, 100, 255, 0, :ease_out], #MTN
    [:move_picture, 13, 0.1,  0, 0,   0, 100, 100, 255, 0, :ease_out], #Shadows
    [:move_picture, 21, 0.1,  0, 0,   0, 100, 100, 255, 0, :linear], #Border old
    [:wait, 3.0],
    [:change_border, ""], # Hide border
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 0, 0, :linear], # Fade in
    [:wait, 1.0],
    # "It was then two figures appeared"...
    [:show_text, 1, '&A1S[PrologueIntro_006]'],
    [:wait, 2.5],
    [:show_text, 2, '&A1S[PrologueIntro_007]'],
    #[:play_se, RPG::AudioFile.new('Ice7', 100, 80)],
    [:wait, 2.0],
    [:move_picture, 21, 3.0, 0, 0, 0, 100, 100, 0, 0, :linear],
    [:move_picture, 22, 3.0, 0, 0, 0, 100, 100, 255, 0, :linear],
    [:move_picture, 11, 5.0,  1, SC_X, SC_Y,  100,  100, 255, 0, :ease_out],
    [:wait, 3.0],
    [:show_text, 3, '&A1S[PrologueIntro_008]'],
    [:wait, 3.0],
    [:input_wait],
    # Fade out old border and fade in new one
    [:move_picture, 23, 4.0, 0, 0, 0, 100, 100, 255, 0, :ease_out], # Fade out
    [:wait, 1.5],
    [:hide_text, 1],
    [:hide_text, 2],
    [:hide_text, 3],
    [:wait, 3.0],
    # "Order returned once more"...
    [:show_text, 0, '&A1S[PrologueIntro_009]'],
    # Swap out border
    #[:move_picture, 22, 0.5, 0, 0, 0, 100, 100, 0, 0],
    [:change_border, "Intro_Frame_2"],
    [:wait, 1.5],
    [:input_wait],
    [:hide_text, 0],
    # Part 3 (14-18)
    [:move_picture, 14, 1.0, 0, 0,   0, 100, 100, 255, 0, :ease_out], # BG
    [:move_picture, 15, 1.0, 0, 0, 200, 100, 100, 255, 0, :ease_out], # Plant
    [:move_picture, 16, 1.0, 0, 0, 200, 100, 100, 255, 0, :ease_out], # Vine
    [:move_picture, 17, 1.0, 0, 0,   0, 100, 100, 255, 0, :ease_out], # Shadows
    [:show_picture, 21, "Cataclysm/Part5_Essence",  1, SC_X, SC_Y, 100, 100, 0, 0],
    [:wait, 1.0],
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 0, 0, :linear], # Fade in
    [:wait, 5.0],
    [:show_text, 1, '&A1S[PrologueIntro_010]'],
    [:wait, 3.0],
    [:move_picture, 15, 2.0, 0, 0,   0, 100, 100, 255, 0, :ease_out],
    [:move_picture, 16, 2.0, 0, 0,   0, 100, 100, 255, 0, :ease_in],
    [:wait, 1.5],
    [:show_text, 2, '&A1S[PrologueIntro_011]'],
    [:wait, 2.5],
    [:show_text, 3, '&A1S[PrologueIntro_012]'],
    [:wait, 0.5],
    [:move_picture, 18, 1.0, 0, 0,   0, 100, 100, 255, 0, :ease_out],
    [:wait, 2.0],
    [:move_picture, 20, 2.0, 0, 0,  0, 100, 100, 255, 0, :ease_in],
    [:move_picture, 16, 2.0, 0, 0, 0, 100, 100, 0, 0, :ease_out],
    [:wait, 1.0],
    [:input_wait],
    [:hide_text, 1],
    [:hide_text, 2],
    [:hide_text, 3],
    [:wait, 2.0],
    [:show_text, 2, '&A1S[PrologueIntro_013]'],
    [:move_picture, 17, 2.0, 0, 0,   0, 100, 100, 0, 0, :ease_out],
    [:wait, 3.0],
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 255, 0,:linear], # Fade out
    [:wait, 1.5],
    [:hide_text, 2],
    [:wait, 1.5],
    # "And their magic was lost..."
    [:show_text, 0, '&A1S[PrologueIntro_014]'],
    [:wait, 1.5],
    [:input_wait],
    [:hide_text, 0],
    [:move_picture, 19, 1.0, 0, 0,   0, 100, 100, 255, 0, :ease_out],
    [:move_picture, 21, 1.0, 1, SC_X, SC_Y, 100, 100, 255, 0, :ease_out],
    [:move_picture, 20, 0.1, 0, 0,  0, 100, 100, 0, 0, :ease_in],
    [:wait, 2.0],
    # Part 4 (19-21)
    [:move_picture, 23, 4.5, 0, 0, 0, 100, 100, 0, 0, :linear], # Fade in
    [:wait, 5.0],
    [:show_text, 1, '&A1S[PrologueIntro_015]'],
    [:wait, 3.0],
    [:move_picture, 21, 15.0, 1, SC_X, SC_Y, 60, 60, 255, 0, :ease_out],
    [:show_text, 2, '&A1S[PrologueIntro_016]'],
    [:wait, 4.5],
    [:show_text, 3, '&A1S[PrologueIntro_017]'],
    [:wait, 2.0],
    [:input_wait],
    [:fade_bgm, 8.0],
    [:hide_text, 1],
    [:hide_text, 2],
    [:hide_text, 3],
    [:move_picture, 23, 6.0, 0, 0, 0, 100, 100, 255, 0, :linear], # Fade out
    # END
    [:wait, 4.0],
    [:change_screen_tone, Tone.new(-255,-255,-255), 3.0],
    [:wait, 4.0],
    [:end_scene]
  ]
end