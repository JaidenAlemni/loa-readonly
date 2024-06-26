#=======================================================================
# Manual Interpreter Advancement
# 
# by Jaiden
# August 2019
#=======================================================================
# This is a simple script that adds the "cutscene_pause" method
# to the interpreter to be used in a script call. 
#
# When called, it will pause the advancement of the interpeter and
# display an animation in the bottom right corner of the screen.
#=======================================================================

#=======================================================================
# ** Sprite_TextAdvance
#=======================================================================
class Sprite_TextAdvance < RPG::Sprite
  #---------------------------------------------------------------------
  # * Object initialization
  #---------------------------------------------------------------------
  def initialize
    @viewport = Viewport.new(1152,672,96,48)
    super(@viewport)
    self.bitmap = RPG::Cache.animation("AdvanceTextAnim", 0)
    self.src_rect.set(0,0,96,48)
    @viewport.z = 9999
    @count = 0
  end
  #---------------------------------------------------------------------
  # * Frame update
  #---------------------------------------------------------------------
  def update
    @count = (@count + 1) % 80
    w = self.bitmap.width / 4
    h = self.bitmap.height
    x = (@count / 20) * w
    self.src_rect.set(x, 0, w, h)
  end
end