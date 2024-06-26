#==============================================================================
# ** Sprite_Face
#------------------------------------------------------------------------------
#  A square face sprite that displays character's faces
#  can be used within the menu or in a text box
#==============================================================================
class Sprite_Face < Sprite
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :actor_id # ID of the actor to display 
  attr_reader   :emotion_id  # Emotion ID to display
  attr_accessor :frame    # Marker for blink frame
  attr_accessor :no_blink # Flag for blink animation
  #--------------------------------------------------------------------------
  # * Private Constants
  #--------------------------------------------------------------------------
  # Number of frames to setup/hold blink 
  PRE_BLINK_FRAMES = 6
  BLINK_FRAMES = 10
  SHEET_WIDTH = 8
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(actor_id, emotion)
    super()
    @frame = 0
    @blink_timer = rand(2..11) * 30
    # Flag to determine if blink should be updated
    @no_blink = false
    @actor_name = ""
    self.actor_id = actor_id
    self.emotion_id = emotion
    update
  end
  #--------------------------------------------------------------------------
  # * Set Actor ID
  #--------------------------------------------------------------------------   
  def actor_id=(actor_id)
    @actor_id = actor_id
    # Normal actor
    if @actor_id < 1000
      @actor_name = $data_actors[@actor_id].name
    # NPC
    else
      @actor_name = $data_npcs[@actor_id - 1000].name
    end
    @blink_timer = 0
  end
  #--------------------------------------------------------------------------
  # * Set Emotion ID
  #--------------------------------------------------------------------------   
  def emotion_id=(value)
    @emotion_id = value
    sheet_index = 0
    if @emotion_id > 15
      sheet_index = @emotion_id / 16
    end
    self.bitmap = RPG::Cache.faces("#{@actor_name}_Sheet#{sheet_index == 0 ? "" : sheet_index}")
    @blink_timer = 0
    update
  end
  #--------------------------------------------------------------------------
  # * Calculate blink frame
  #--------------------------------------------------------------------------   
  def update_blink_frame
    return unless @blink_timer
    # Reset blink
    if @blink_timer == 0
      # 25% chance for triggering a second blink, skip if we already did
      if rand(4) == 0 && !@double_blink
        # Flag so we don't double blink multiple times
        @double_blink = true
        @blink_timer = 20
        return
      end
      @frame = 0
      @blink_timer = rand(2..11) * 30
      @double_blink = false
    # Blinking
    elsif @blink_timer <= PRE_BLINK_FRAMES
      @frame = 2 
      @blink_timer -= 1
    # Starting blink
    elsif @blink_timer <= BLINK_FRAMES
      @frame = 1 
      @blink_timer -= 1
    # Waiting to blink
    else
      @frame = 0
      @blink_timer -= 1
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------   
  def update
    # Update blink
    unless @no_blink
      update_blink_frame
    else
      # Ensure face isn't mid-blink
      @frame = 0 if @frame != 0
    end
    # Since emotion index higher than 7 wraps, we need to use a little modulo math
    # ((index + 8 cells) * blink frame (0,1,2))
    eid = @emotion_id > 15 ? @emotion_id - 16 : @emotion_id
    x = (eid % SHEET_WIDTH) * Game_Face::DEFAULT_WIDTH
    row = (eid / SHEET_WIDTH * 3) * Game_Face::DEFAULT_HEIGHT
    y = row + (@frame * Game_Face::DEFAULT_HEIGHT)
    self.src_rect.set(x, y, Game_Face::DEFAULT_WIDTH, Game_Face::DEFAULT_HEIGHT)
  end
  #--------------------------------------------------------------------------
  # * Static determinant
  #--------------------------------------------------------------------------   
  def static?
    return false
  end
end
#==============================================================================
# ** Sprite_FaceStatic
#------------------------------------------------------------------------------
#  A face sprite that does not blink
#  Sheets are single row, emotions by column index
#   1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
#==============================================================================
class Sprite_FaceStatic < Sprite
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :actor_id # ID of the actor to display 
  attr_reader :emotion_id  # Emotion ID to display
  attr_accessor :npc_id
  SHEET_WIDTH = 8
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(actor_id, emotion)
    super
    @emotion_id = emotion
    self.actor_id = actor_id
    update
  end
  #--------------------------------------------------------------------------
  # * Set Actor ID
  #--------------------------------------------------------------------------   
  def actor_id=(actor_id)
    @actor_id = actor_id
    @emotion_id ||= 0
    # Get the name
    name = $data_npcs[@actor_id - 1000].name
    # Change the bitmap to the appropriate sheet
    self.bitmap = RPG::Cache.faces("NPC_#{name}")
    update
  end
  #--------------------------------------------------------------------------
  # * Set Emotion ID
  #--------------------------------------------------------------------------   
  def emotion_id=(emotion_id)
    @emotion_id = emotion_id
    update
  end
  #--------------------------------------------------------------------------
  # * Calculate blink frame
  #--------------------------------------------------------------------------   
  def update_blink_frame

  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------   
  def update
    x = (@emotion_id % SHEET_WIDTH) * Game_Face::DEFAULT_WIDTH
    y = (@emotion_id / SHEET_WIDTH) * Game_Face::DEFAULT_WIDTH
    self.src_rect.set(x, y, Game_Face::DEFAULT_WIDTH, Game_Face::DEFAULT_HEIGHT)
  end
  #--------------------------------------------------------------------------
  # * Static determinant
  #--------------------------------------------------------------------------   
  def static?
    return true
  end
end