#==============================================================================
# ■ Window_Controls
# Window that displays control information
#==============================================================================
class Window_Controls < Window_Base
  attr_accessor :expand_speed
  attr_reader :state
  X_OFFSET = 0
  ICON_RECT = Rect.new(0,0,32,32)
  #--------------------------------------------------------------------------
  def initialize(x, y, width = 800)
    super(x, y, width, 64)
    self.fixed = false
    self.contents = Bitmap.new(width - 24, height - 24)
    self.z = 5200
    self.back_opacity = 128
    self.windowskin = RPG::Cache.windowskin("Blank")
    self.opacity = 0
    @dest_opacity = 0
    @expand_speed = 8
    @sprites = []
    @inputs = {}
    setup_grid(columns: 7, rows: 1)
  end
  #--------------------------------------------------------------------------
  # * Create an array of inputs and their icons based on the provided state
  # Then set the # of columns and draw into the window accordingly
  #--------------------------------------------------------------------------
  def setup_inputs(menu, state, *params)
    # {name: [button, description], name2: [button, description]}
    #@input[] = ["",""]
    @inputs = {} # :none
    @sprites.each{|s| s.dispose} if @sprites
    @sprites = []
    case menu
    when :alert
      @inputs[:confirm] = ["C","&MUI[Confirm]"]
      @inputs[:cancel] = ["B","&MUI[Cancel]"]
      @inputs[:move] = ["M", "&MUI[InputCursorMove]"]
    when :battle
      defending, switch, committed = params
      if committed
        @inputs[:pause] = ["P", "&MUI[InputStart]"]
        @inputs[:fast_forward] = ["R", "&MUI[InputR-Battle]"]
      else
        @inputs[:pause] = ["P", "&MUI[InputStart]"]
        if switch
          @inputs[:switchl] = ["A", ""] 
          @inputs[:switchr] = ["Z", "&MUI[Input-SwitchChar]"] 
        end
        @inputs[:fast_forward] = ["R", "&MUI[InputR-Battle]"]
        dstr = defending ? "&MUI[InputHold-Inactive]" : "&MUI[InputHold-Active]"
        @inputs[:defend] = ["L", dstr]
        case state
        when :attack, :skill, :item
          @inputs[:confirm] = ["C","&MUI[Confirm]"]
          @inputs[:cancel] = ["B","&MUI[Back]"]
        else
          @inputs[:choose] = ["M", "&MUI[InputBattleAction]"]
          # @inputs[:attack] = ["2","&MUI[InputC-Battle]"]
          # @inputs[:skill] = ["4","&MUI[InputX-Battle]"]
          # @inputs[:item] = ["8","&MUI[InputY-Battle]"]
        end
      end
    when :name
      @inputs[:confirm] = ["C","&MUI[Confirm]"]
      @inputs[:cancel] = ["B","&MUI[Back]"]
      @inputs[:move] = ["M", "&MUI[InputCursorMove]"]
    when :book
      @inputs[:cancel] = ["B","&MUI[Back]"]
      @inputs[:prev] = ["8","&MUI[InputL-Menu]"]
      @inputs[:next] = ["2","&MUI[InputR-Menu]"]
    else # All other menus
      @inputs[:confirm] = ["C","&MUI[Confirm]"]
      @inputs[:cancel] = ["B","&MUI[Back]"]
      if [:equip, :essence, :status].include?(menu) && state != :command && params[0]
        @inputs[:prev] = ["A", "&MUI[InputA]"]
        @inputs[:next] = ["Z", "&MUI[InputZ]"]
      end
      if menu == :essence
        str = Localization.localize("&MUI[InputSort]") + " / " + Localization.localize("&MUI[InputSkills]")
        @inputs[:sortl] = ["4", ""] 
        @inputs[:sortr] = ["6", str] 
      end
    end
    # Resize
    if !@inputs.empty?
      if menu == :battle
        setup_grid(columns: 7, rows: 1)
      else
        setup_grid(columns: 8, rows: 1)
      end
    end
    # Refresh?
    refresh
  end
  #--------------------------------------------------------------------------
  # * Draw single input
  #--------------------------------------------------------------------------
  def draw_input(key, index)
    prompt, input_desc = @inputs[key]
    # Localize the string to get our width
    str = Localization.localize(input_desc)
    tpadding = str == "" ? 0 : 20
    text_rect = self.contents.text_size(str)
    iw = ICON_RECT.width + 12
    ih = ICON_RECT.height 
    x = @last_x 
    y = (contents_height - ih) / 2
    bmp = RPG::Cache.icon(Input.prompt_graphic_name(prompt))
    if ['2','4','6','8'].include?(prompt) && (Input::Controller.connected? && !$game_options.kb_override) || prompt == 'M'
      bmp.play
      bmp.frame_rate = 2
      sprite = Sprite.new
      sprite.bitmap = bmp
      sprite.x = self.x + x + bmp.width / 2
      sprite.y = self.y + y + 12
      sprite.z = self.z + 10
      @sprites << sprite
    else
      self.contents.blt(x, y, bmp, ICON_RECT)
    end
    self.contents.draw_text(x + iw, y, text_rect.width + tpadding, ih, str)
    @last_x = x + text_rect.width + iw + tpadding
  end
  #--------------------------------------------------------------------------
  # * Set Input Info
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    return if @inputs.empty?
    self.contents.font.name = Font.numbers_name
    self.contents.font.size = Font.scale_size(90)
    i = 0
    @last_x = 0
    @inputs.keys.each do |key|
      draw_input(key, i)
      i += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Dispose window
  #--------------------------------------------------------------------------
  def dispose
    super
    @sprites.each{|s| s.dispose}
  end
  #--------------------------------------------------------------------------
  # * Move help window from behind actor
  #--------------------------------------------------------------------------
  def appear(opacity = 255)
    self.opacity = 0
    expand(opacity)
    @sprites.each{|s| s&.opacity = opacity}
    #self.y = @start_y
    #move(self.x, @end_y)
  end
  #--------------------------------------------------------------------------
  # * Move help window behind actor
  #--------------------------------------------------------------------------
  def disappear
    expand(0)
    @sprites.each{|s| s&.opacity = 0}
    #move(self.x, @start_y)
  end
  #------------------------------------------------------------------------------
  # Window Expansion Methods
  #------------------------------------------------------------------------------
  def expanding?
    return (self.opacity != @dest_opacity)
  end
  #------------------------------------------------------------------------------
  def expand(dest_o, speed = 8)
    @dest_opacity = dest_o
    self.expand_speed = speed
  end
  #------------------------------------------------------------------------------
  def expand_win
    dw = (@dest_opacity - self.opacity).to_f / self.expand_speed
    dw = @dest_opacity > self.opacity ? dw.ceil : dw.floor
    self.opacity += dw
  end
  #------------------------------------------------------------------------------
  def opacity=(val)
    @dest_opacity = val unless expanding?
    self.contents_opacity = val
    #self.back_opacity = val * 3 / 4
    super(val)
  end
  #------------------------------------------------------------------------------    
  def update
    super
    expand_win if self.expanding?
  end
end