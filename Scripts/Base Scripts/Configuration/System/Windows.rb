class Window_Base < Window
  #--------------------------------------------------------------------------
  # * Window Colors
  #--------------------------------------------------------------------------
  BLACK_COLOR =  Color.new(  0,   0,   0)
  WHITE_COLOR =  Color.new(255, 255, 255)
  BLUE_COLOR =   Color.new(110, 170, 235)
  RED_COLOR =    Color.new(230,  80,  80)
  GREEN_COLOR =  Color.new( 75, 255, 120)
  CYAN_COLOR =   Color.new( 25, 227, 217)
  PURPLE_COLOR = Color.new(118,  33, 128)
  GOLD_COLOR =   Color.new(247, 204,  47)
  ORANGE_COLOR = Color.new(250,  95,   5)
  GREY_COLOR =   Color.new(210, 210, 210)
  SYSTEM_COLOR = Color.new(181, 223, 255)
  KEYWORD_COLOR =  Color.new(255, 205, 25)
  DISABLED_COLOR = Color.new(180, 180, 180, 128)
  KNOCKOUT_COLOR = Color.new(230,  30,  30, 128)
  UNLEASH_COLOR  = Color.new(235, 125, 255)
  # For faces/busts
  ACTIVE_TONE = Tone.new()
  INACTIVE_TONE = Tone.new(25,10,0,50)
  ACTIVE_COLOR = Color.new()
  INACTIVE_COLOR = Color.new(0,0,0,150)
  # Meter lengths
  MINI_BAR_W = 122
  SMALL_BAR_W = 148
  FULL_BAR_W = 240
end