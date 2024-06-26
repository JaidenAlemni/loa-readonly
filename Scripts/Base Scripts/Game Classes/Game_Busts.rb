#==============================================================================
# ** Game_Busts
# 
# Class for displaying busts on screen. Busts are picture sprites 
# and borrow methods from that class to be displayed.
#
# Accessed via the $game_busts variable. 
#
# Note about positions:
# 2 characters - [ 1     2 ]
# 4 characters - [5 3   4 6]
#==============================================================================
class Game_Busts
  #--------------------------------------------------------------------------
  # * Constants
  #--------------------------------------------------------------------------
  MOVE_DURATION = 10
  FADE_DURATION = 10
  ACTIVE_TONE = Tone.new()
  INACTIVE_TONE = Tone.new(25,10,0,50)
  ACTIVE_COLOR = Color.new()
  INACTIVE_COLOR = Color.new(0,0,0,150)
  # Origin and Y values are always fixed for now
  ORIGIN = 2
  Y = LOA::SCRES[1]
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :busts
  attr_reader :speaker # Active bust position number
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    # Set bust positions
    # Note that the picture ID pertains to the position
    @busts = [nil]
    for i in 1..6
      @busts.push(Game_Picture.new(i))
    end
    @speaker = 0 # Active bust position number
  end
  #--------------------------------------------------------------------------
  # * Position Setup
  #
  # Note that 2 is actually the default position, so mirroring
  # applies to the left side of the screen
  #    SCREEN
  # [ 1      2 ]
  # [5 3    4 6]
  #--------------------------------------------------------------------------
  def position_setup(pos)
    # Sets the x and mirror values based on these positions
    case pos
    when 1 # Left
      x = 0
      mirror = true
    when 2 # Right
      x = LOA::SCRES[0]
      mirror = false
    when 5 # LL
      x = -100
      mirror = true
    when 3 # LR
      x = 60
      mirror = true
    when 4 # RL
      x = LOA::SCRES[0] - 60
      mirror = false
    when 6 # RR
      x = LOA::SCRES[0] + 100
      mirror = false
    end
    return [x, mirror]
  end
  #--------------------------------------------------------------------------
  # * Set Off-screen Coordinates
  #--------------------------------------------------------------------------
  def set_offscreen(pos)
    case pos
    when 1,3
      x = -100
      mirror = true
    when 5
      x = -200
      mirror = true
    when 2,4
      x = LOA::SCRES[0] + 100
      mirror = false
    when 6
      x = LOA::SCRES[0] + 200
      mirror = false
    end
    return [x, mirror]
  end
  #--------------------------------------------------------------------------
  # * Set Bust Character
  # position - Bust at position #
  # character - ID of actor / NPC to set 
  # emotion - Emotion to set, default if not set
  #--------------------------------------------------------------------------
  def set_bust(pos, character, emotion = 0)
    # Update instance variables
    @speaker = pos
    @busts[pos].char_id = character.to_i
    @busts[pos].emotion_id = emotion.to_i
    # Get file
    char_id = character.to_i
    if char_id < 100
      name = $data_actors[char_id].name
    else
      name = MessageSystem.npc_table(char_id)
    end
    emotion = MessageSystem.emotion(emotion.to_i)
    filename = "Busts/#{name}_#{emotion}"
    # Get Coordinates based on pos
    x, mirror = set_offscreen(pos)
    # Setup the picture sprite
    @busts[pos].show(filename, ORIGIN, x, Y, 100.0, 100.0, 0, 0, mirror)
  end
  #--------------------------------------------------------------------------
  # * Change the emotion of the specified bust
  #--------------------------------------------------------------------------
  def change_emotion(pos, emote_id)
    # Update instance variable
    @busts[pos].emotion_id = emote_id
    # Grab the character's name
    current_name = @busts[pos].name
    current_name.slice!(/_.+/)
    current_name.delete_prefix!('Busts/')
    # Get the emotion
    emotion = MessageSystem.emotion(emote_id.to_i)
    @busts[pos].name = "Busts/#{current_name}_#{emotion}"
  end
  #--------------------------------------------------------------------------
  # * Make Bust Active
  # position - Bust at position #
  #--------------------------------------------------------------------------
  def make_active(pos, emotion = nil)
    # Other busts should be made inactive
    for i in 1..6
      next if i == pos
      make_inactive(i)
    end
    # Make bust active
    @busts[pos].start_tone_change(ACTIVE_TONE, FADE_DURATION)
    @busts[pos].start_color_change(ACTIVE_COLOR, FADE_DURATION)
    @busts[pos].bust_active = true
    @speaker = pos
    # If there's also an emotion change
    if emotion
      change_emotion(pos, emotion)
    end
  end
  #--------------------------------------------------------------------------
  # * Make Bust Inactive
  # position - Bust at position #
  #--------------------------------------------------------------------------
  def make_inactive(pos)
    @busts[pos].start_tone_change(INACTIVE_TONE, FADE_DURATION)
    @busts[pos].start_color_change(INACTIVE_COLOR, FADE_DURATION)
    @busts[pos].bust_active = false
  end
  #--------------------------------------------------------------------------
  # * Hide Bust
  # Move the bust off screen 
  # position - Bust at position #
  #--------------------------------------------------------------------------
  def hide_bust(pos)
    x, mirror = set_offscreen(pos)
    @busts[pos].move(MOVE_DURATION, ORIGIN, x, Y, 100.0, 100.0, 0, 0, mirror)
  end
  #--------------------------------------------------------------------------
  # * Show bust
  # Move the bust on screen
  # position - Bust at position #
  #--------------------------------------------------------------------------
  def show_bust(pos)
    x, mirror = position_setup(pos)
    @busts[pos].move(MOVE_DURATION, ORIGIN, x, Y, 100.0, 100.0, 255, 0, mirror)
  end
  #--------------------------------------------------------------------------
  # * Clear bust
  # position - Bust at position #
  #--------------------------------------------------------------------------
  def clear_bust(pos)
    @busts[pos].erase
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Update each bust sprite
    for i in 1..6
      @busts[i].update
    end
  end
end