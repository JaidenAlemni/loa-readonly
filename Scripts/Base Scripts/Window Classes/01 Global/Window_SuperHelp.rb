#==============================================================================
# ** Window_SuperHelp
#------------------------------------------------------------------------------
#  This window displays Essence/Weapon/Item details
#==============================================================================
class Window_SuperHelp < Window_Base
  #------------------------------------------------------------------------------
  # Object initialization
  #------------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(MenuConfig::WINDOW_OFFSCREEN_RIGHT + (x - MenuConfig::MENU_ORIGIN_X), y, width, height)
    move(x, y)
    self.fixed = false
    self.opacity = MenuConfig::MENU_WINDOW_OPACITY
    @obj = nil
    @string = ""
  end
  #--------------------------------------------------------------------------
  # * Set Text
  #  obj: object to draw
  #--------------------------------------------------------------------------
  def set_text(obj, string = "")
    # If the obj doesn't exist
    if obj.nil?
      # Clear contents & set font default
      self.contents.clear
      self.contents.font.name = Font.numbers_name
      self.contents.font.size = Font.default_size
      # There's a string to draw
      if string != ""
        #return if string == @string
        # Draw the help icon
        bitmap = RPG::Cache.icon("Menu/Help")
        self.contents.blt(0, 6, bitmap, Rect.new(0, 0, 24, 24), opacity)
        # Draw the string
        self.contents.font.color = normal_color
        string = Localization.localize(string)
        line1, line2 = string.split("\\n")
        self.contents.draw_text(32, 2, self.width - 56, 32, line1, 0)
        self.contents.draw_text(32, 34, self.width - 56, 32, line2, 0)
        @string = string
      end
      # Exit
      @obj = obj
      return
    end
    # Exit if the obj didn't change
    #return if obj == @obj
    # Clear contents & set font default
    self.contents.clear
    self.contents.font.name = Font.numbers_name
    self.contents.font.size = Font.default_size
    if obj.id == 102
      self.contents.font.name = 'Elemental'
      self.contents.font.size = 32
    end
    # Draw icon
    bitmap = RPG::Cache.icon(obj.icon_name)
    width = bitmap.width
    height = bitmap.height
    src_rect = Rect.new(0, 0, width, height)
    dest_rect = Rect.new(0, 0, width * 3, height * 3)
    self.contents.stretch_blt(dest_rect, bitmap, src_rect)
    # Branch by object type
    case obj
    when RPG::Item
      text = obj.loc_description
      extext = MenuDescriptions.items(obj)
      if obj.occasion == 2
        extext = extext + "&MUI[ItemMenuUseOnly]"
      end
    when RPG::Weapon, RPG::Armor
      text = obj.loc_description
      extext = ""
    when RPG::Essence
      text, extext = obj.loc_description.split("\\n")
      type = obj.passive? ? Localization.localize("&MUI[EssenceTypePassive]") : Localization.localize("&MUI[EssenceTypeActive]")
      level = "[Max: #{obj.max_level}]"
      text = type + " " + level + " " + text if !text.nil?
      text = "" if text.nil?
      extext = "" if extext.nil?
    when RPG::Skill
      text, extext = obj.loc_description.split("\\n")
      # Awakening text sub
      if text && text.scan(/!N(\d)/) != []
        text = text.sub(/!N\d/, $game_actors[Integer($1)].name)
      end
      text = "" if text.nil?
      extext = "" if extext.nil?
    else
      text = ""
      extext = ""
    end
    # Draw descriptive text
    self.contents.font.color = normal_color
    draw_even_text(80, 0, self.width - 32, 32, text, 0)
    # Draw additional text
    self.contents.font.color = system_color
    #self.contents.font.bold = true if Localization.culture != :jp
    #self.contents.font.name = Font.default_name
    self.contents.draw_text(80, 32, self.width - (24 + 80), 32, extext, 0)
    #self.contents.font.bold = false
    #self.contents.font.size = Font.default_size
    @obj = obj
  end  
end