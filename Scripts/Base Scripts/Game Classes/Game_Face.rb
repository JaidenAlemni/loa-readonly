#==============================================================================
# ** Game_Face
#------------------------------------------------------------------------------
#  Class used for managing an animated face sprite
#  methods exist to allow modulation of the sprite's emotions and character
#  Primarily used within the Window_Message class
#==============================================================================
class Game_Face
  attr_reader :emotion
  attr_reader :name
  NAME_Y_OFFSET = 128
  EMOTIONS = [
    'default', #0
    'smile',   #1
    'focused', #2
    'worry',   #3
    'annoyed',   #4
    'sad',     #5
    'relief',  #6
    'sigh',    #7
    'angry',    #8
    'surprise', #9
    'shock',   #10
    'blush',   #11
    'misc1',   #12
    'misc2',   #13
    'misc3',   #14
    'misc4',   #15
    # Sheet 2
    'think',   #16 (-16)
    'chuckle', #17
    'blush2',  #18
    'happy2',   #19
    'dazed'    #20
  ]
  # Sprite width / height
  DEFAULT_WIDTH = 156
  DEFAULT_HEIGHT = 156
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     actor : Determines face sheet graphic
  #     emotion : Face sheet column % 8
  #--------------------------------------------------------------------------
  def initialize(actor_id, emotion)
    # Create the face sprite
    emotion_id = EMOTIONS.index(emotion)
    @actor_id = actor_id
    @emotion = emotion
    create_sprite
    set_name("")
  end
  #--------------------------------------------------------------------------
  # NPC Determinant
  #--------------------------------------------------------------------------
  def npc?
    @actor_id > 1000
  end
  #--------------------------------------------------------------------------
  # Manage X Position
  #--------------------------------------------------------------------------
  def x=(n)
    @face_sprite.x = n
    @bg_sprite.x = n
    @name_sprite.x = n
  end
  #--------------------------------------------------------------------------
  # Manage Y Position
  #--------------------------------------------------------------------------
  def y=(n)
    @face_sprite.y = n
    @bg_sprite.y = n
    @name_sprite.y = n + NAME_Y_OFFSET
  end
  #--------------------------------------------------------------------------
  # Manage Z Position
  #--------------------------------------------------------------------------
  def z=(n)
    @face_sprite.z = n
    @bg_sprite.z = n
    @name_sprite.z = n
  end
  #--------------------------------------------------------------------------
  # Get the width
  #--------------------------------------------------------------------------
  def width
    @face_sprite.width
  end
  #--------------------------------------------------------------------------
  # Get face visibility
  #--------------------------------------------------------------------------
  def visible
    @face_sprite.visible
  end
  #--------------------------------------------------------------------------
  # Manage face visibility
  #--------------------------------------------------------------------------
  def visible=(bool)
    @face_sprite.visible = bool
    @bg_sprite.visible = bool
    @name_sprite.visible = bool
  end
  #--------------------------------------------------------------------------
  # Get face opacity
  #--------------------------------------------------------------------------
  def opacity
    @face_sprite.opacity
  end
  #--------------------------------------------------------------------------
  # Manage face opacity
  #--------------------------------------------------------------------------
  def opacity=(n)
    @face_sprite.opacity = n
    @bg_sprite.opacity = n
    @name_sprite.opacity = n
  end
  #--------------------------------------------------------------------------
  # Manage face mirroring
  #--------------------------------------------------------------------------
  def mirror=(bool)
    @face_sprite.mirror = bool
    @bg_sprite.mirror = bool
  end
  #--------------------------------------------------------------------------
  # Change actor face graphic
  #--------------------------------------------------------------------------
  def actor=(actor_id)
    prev_id = @actor_id
    @actor_id = actor_id
    # Need to recreate sprite if NPC vs Actor
    if (prev_id - @actor_id).abs >= 1000
      create_sprite
    else
      @face_sprite.actor_id = @actor_id
    end
  end
  #--------------------------------------------------------------------------
  # Change dispayed emotion
  #--------------------------------------------------------------------------
  def emotion=(emotion)
    @emotion = emotion
    @face_sprite.emotion_id = self.emotion_id
  end
  #--------------------------------------------------------------------------
  # Get emotion ID from emotion
  #--------------------------------------------------------------------------
  def emotion_id
    EMOTIONS.index(@emotion).nil? ? 0 : EMOTIONS.index(@emotion)
  end
  #--------------------------------------------------------------------------
  # Recreate sprite
  #--------------------------------------------------------------------------
  def create_sprite
    erase
    if npc?
      @face_sprite = Sprite_FaceStatic.new(@actor_id, self.emotion_id)
    else
      @face_sprite = Sprite_Face.new(@actor_id, self.emotion_id)
    end
    @bg_sprite = Sprite.new() if @bg_sprite.nil? 
    @name_sprite = Sprite.new() if @name_sprite.nil? 
  end
  #--------------------------------------------------------------------------
  # Change name
  #--------------------------------------------------------------------------
  def set_name(name, mirror = false)
    @name = name
    draw_name(mirror)
  end
  #--------------------------------------------------------------------------
  # Toggle Blink
  #--------------------------------------------------------------------------
  def disable_blink=(bool)
    @face_sprite.no_blink = bool
  end
  #--------------------------------------------------------------------------
  # Draw the Character Name
  #--------------------------------------------------------------------------
  def draw_name(mirror)
    # Exit if invalid
    return if @face_sprite.nil?
    # Draw components if they don't exist
    @bg_sprite.bitmap = RPG::Cache.faces("Name_Box")
    @bg_sprite.z = @face_sprite.z + 50
    @bg_sprite.x = @face_sprite.x 
    @bg_sprite.y = @face_sprite.y

    @name_sprite.bitmap = Bitmap.new(156,28)
    @name_sprite.z = @face_sprite.z + 100
    @name_sprite.x = @face_sprite.x 
    @name_sprite.y = @face_sprite.y + NAME_Y_OFFSET

     # Clear name if it doesn't exist
    if @name == ""
      @bg_sprite.visible = false
      @name_sprite.visible = false
    # Draw the name
    else
      @name_sprite.bitmap.clear 
      @name_sprite.bitmap.font.color = Window_Base::GOLD_COLOR
      if mirror
        align = 2
        x = 0
      else
        align = 0
        x = 4
      end
      @name_sprite.bitmap.draw_text(x, 0, 156, 28, @name, align)
      @bg_sprite.visible = true
      @name_sprite.visible = true
    end
  end
  #--------------------------------------------------------------------------
  # Frame Update
  #--------------------------------------------------------------------------
  def update
    if @actor_id != @face_sprite.actor_id
      @face_sprite.actor_id = @actor_id
    end
    # Did the emotion change?
    if self.emotion_id != @face_sprite.emotion_id
      @face_sprite.emotion_id = self.emotion_id 
    end
    # Update the sprite
    @face_sprite&.update unless @face_sprite.static?
  end
  #--------------------------------------------------------------------------
  # Erase sprite
  #--------------------------------------------------------------------------
  def erase
    @bg_sprite&.dispose if !@bg_sprite.disposed?
    @bg_sprite = nil
    @name_sprite&.dispose if !@name_sprite.disposed?
    @name_sprite = nil
    @face_sprite&.dispose if !@face_sprite.disposed?
    @face_sprite = nil
  end
end