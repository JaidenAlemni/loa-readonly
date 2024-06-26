#==============================================================================
# ** Scene_Shop
#------------------------------------------------------------------------------
#  This class performs shop screen processing.
#==============================================================================
class Scene_Shop < Scene_Base
  include MenuConfig
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------  
  def initialize(command_index = 0, shop_id)
    super(command_index)
    @command_index = command_index
    @shop_id = shop_id
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def pre_start
    # Create windows
    commands = ["Buy", "Sell", "Equip", "Exit"]
    @command_window = Window_Menu.new(MENU_ORIGIN_X, MENU_ORIGIN_Y, COMMAND_WIN_WIDTH, MENU_WINDOW_HEIGHT, commands, 'Shop')
    # Disable equipping globally for now until its fixed
    @command_window.disable_item(2)
    # Associate windows
    @command_window.help_window = @help_window
    # Set active state
    @command_window.active = true
    @help_window = Window_MenuHelp.new(MENU_ORIGIN_X + @command_window.width, MENU_ORIGIN_Y + MENU_WINDOW_HEIGHT - HELP_HEIGHT_SHORT, MENU_WINDOW_WIDTH, HELP_HEIGHT_SHORT, true)
    @category_window = Window_ShopCategory.new(MENU_ORIGIN_X + @command_window.width, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH * 46 / 100, HELP_HEIGHT_SHORT)
    @category_window.visible = true
    # For list window, create one for each category
    @sell_windows = []
    @list_window = Window_ShopList.new(MENU_ORIGIN_X + @command_window.width, MENU_ORIGIN_Y + @category_window.height, @category_window.width, MENU_WINDOW_HEIGHT - @help_window.height - @category_window.height, 0, @shop_id)
    @list_window.active = false
    @list_window.visible = true
    # Make a 5th window for the sell-only category (0), just in case.
    5.times do |i|
      @sell_windows[i] = Window_ShopList.new(MENU_ORIGIN_X + @command_window.width, MENU_ORIGIN_Y + @category_window.height, @category_window.width, MENU_WINDOW_HEIGHT - @help_window.height - @category_window.height, i)
      @sell_windows[i].active = false
      @sell_windows[i].visible = false
    end
    # Associate help window and make first window visible
    @list_window.help_window = @help_window
    @sell_windows.each {|win| win.help_window = @help_window}
    @info_window = Window_ShopInfo.new(MENU_ORIGIN_X + @command_window.width + @list_window.width, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH - @category_window.width, MENU_WINDOW_HEIGHT * 36 / 100)
    @party_window = Window_ShopParty.new(MENU_ORIGIN_X + @command_window.width + @list_window.width, MENU_ORIGIN_Y + @info_window.height, MENU_WINDOW_WIDTH - @category_window.width, MENU_WINDOW_HEIGHT - @info_window.height - @help_window.height)
    @number_window = Window_ShopNumber.new(MENU_ORIGIN_X + @command_window.width + @list_window.width, MENU_ORIGIN_Y + @info_window.height, MENU_WINDOW_WIDTH - @category_window.width, @party_window.height)
    @number_window.active = false
    @number_window.visible = false
    # Set Shop Screen Flag
    $scene_shop = true
    @buy_mode = false
    @sell_mode = false
    @help_window.set_text(MenuDescriptions.shop_command(@command_window.index))
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super  
    @sell_windows.each {|win| win.update}
    # If command window is active: call update_command
    if @command_window.active
      update_command
      return
    end
    # If quantity input window is active: call update_number
    if @number_window.active
      update_number
      return
    end
    # If buy window is active: call update_buy
    if @buy_mode
      update_buy
      return
    end
    # If sell window is active: call update_sell
    if @sell_mode
      update_sell
      return
    end
  end
  #--------------------------------------------------------------------------
  # * A method for pre-exit tasks
  #-------------------------------------------------------------------------- 
  def cleanup
    # Initialize temp window array
    windows = []
    # Set all windows to move & add them to temp array (For update)
    @sell_windows.each do |win|
      windows << win
      win.move(WINDOW_OFFSCREEN_RIGHT, win.y, WIN_ANIM_SPEED)
    end
    windows << @command_window
    @command_window.move(WINDOW_OFFSCREEN_LEFT, @command_window.y, WIN_ANIM_SPEED)
    super(windows)
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    @sell_windows.each {|win| win.dispose}
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when command window is active)
  #--------------------------------------------------------------------------
  def update_command
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      close_scene
      return
    end
    # If cursor moved
    if @command_window.cursor_moved?
      @help_window.set_text(MenuDescriptions.shop_command(@command_window.index))
      # Branch by index
      case @command_window.index
      when 1 # sell
        # Make sell windows visible
        @list_window.visible = false
        # Set the window whose category matches the current item category visible
        @category_window.category = 1
        @sell_windows[@category_window.category].visible = true
      else # all other cases
        # Make buy windows visible
        @sell_windows.each{|win| win.visible = false}
        @category_window.category = 0
        # Set the window whose category matches the current item category visible
        @list_window.visible = true
      end
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Branch by command window cursor position
      case @command_window.index
      when 0  # buy
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Change windows to buy mode
        @command_window.active = false
        @buy_mode = true
        @list_window.active = true
        @list_window.index = 0
        @list_window.update_help
        @info_window.item = @list_window.item
        @party_window.item = @list_window.item
      when 1  # sell
        # Play decision SE
        $game_system.se_play($data_system.decision_se)
        # Change windows to sell mode
        @command_window.active = false
        @category_window.category = 1
        @sell_mode = true
        set_active_window
      when 2 # equip
        # TODO : Remove once available
        $game_system.se_play($data_system.buzzer_se)
        return
        $game_system.se_play($data_system.decision_se)
        @command_index = @command_window.index
        $scene = Scene_Equip.new
      when 3  # quit
        close_scene
        $scene_shop = false
      end
      return
    end
  end  
  #--------------------------------------------------------------------------
  # * Frame Update (when buy window is active)
  #--------------------------------------------------------------------------
  def update_buy
    if @list_window.cursor_moved?
      @info_window.item = @list_window.item
      @party_window.item = @list_window.item
    end
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Change windows to initial mode
      @list_window.active = false
      @command_window.active = true
      @buy_mode = false
      @help_window.set_text(MenuDescriptions.shop_command(@command_window.index))
      @info_window.item = nil
      @party_window.item = nil
      return
    end
    if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::R)
      # Go forward a category
      next_category
      return
    end
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::L)
      # Go back a category
      prev_category
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Get item
      @item = @list_window.item
      # If item is invalid, or price is higher than money possessed
      if @item == nil or @item.price > $game_party.gold
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Get items in possession count
      case @item
      when RPG::Item
        number = $game_party.item_number(@item.id)
      when RPG::Weapon
        number = $game_party.weapon_number(@item.id)
      when RPG::Armor
        number = $game_party.armor_number(@item.id)
      end
      # If 99 items are already in possession
      if number == 99
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Calculate maximum amount possible to buy
      max = @item.price == 0 ? 99 : $game_party.gold / @item.price
      max = [max, 99 - number].min
      # Change windows to quantity input mode
      @list_window.active = false
      @party_window.visible = false
      @number_window.set(@item, max, @item.price, 0)
      @number_window.active = true
      @number_window.visible = true
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when sell window is active)
  #--------------------------------------------------------------------------
  def update_sell
    if @sell_windows[@category_window.category].cursor_moved?
      @info_window.item = @sell_windows[@category_window.category].item
      @party_window.item = @sell_windows[@category_window.category].item
    end
    if Input.trigger?(Input::R)
      # Go forward a category
      next_category
      return
    end
    if Input.trigger?(Input::L)
      # Go back a category
      prev_category
      return
    end
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Change windows to initial mode
      @sell_windows[@category_window.category].active = false
      @command_window.active = true
      @sell_mode = false
      # Erase help text
      @help_window.set_text(MenuDescriptions.shop_command(@command_window.index))
      @info_window.item = nil
      @party_window.item = nil
      return
    end
    if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::R)
      # Go forward a category
      next_category
      return
    end
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::L)
      # Go back a category
      prev_category
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Get item
      @item = @sell_windows[@category_window.category].item
      # If item is invalid, or item price is 0 (unable to sell)
      if @item == nil or @item.price == 0
        # Play buzzer SE
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Play decision SE
      $game_system.se_play($data_system.decision_se)
      # Get items in possession count
      case @item
      when RPG::Item
        number = $game_party.item_number(@item.id)
      when RPG::Weapon
        number = $game_party.weapon_number(@item.id)
      when RPG::Armor
        number = $game_party.armor_number(@item.id)
      end
      # Maximum quanitity to sell = number of items in possession
      max = number
      # Change windows to quantity input mode
      @sell_windows[@category_window.category].active = false
      @party_window.visible = false
      @number_window.set(@item, max, @item.price / 2, 1)
      @number_window.active = true
      @number_window.visible = true
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when quantity input window is active)
  #--------------------------------------------------------------------------
  def update_number
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Set quantity input window to inactive / invisible
      @number_window.active = false
      @number_window.visible = false
      # Branch by command window cursor position
      case @command_window.index
      when 0 # buy
        # Change windows to buy mode
        @list_window.active = true
        @party_window.visible = true
        @category_window.category = 0
      when 1 # sell
        # Change windows to sell mode
        @sell_windows[@category_window.category].active = true
        @party_window.visible = true
        @category_window.visible = true
      end
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Play shop SE
      $game_system.se_play($data_system.shop_se)
      # Set quantity input window to inactive / invisible
      @number_window.active = false
      @number_window.visible = false
      @party_window.visible = true
      # Branch by command window cursor position
      case @command_window.index
      when 0  # buy
        # Buy process
        $game_party.lose_gold(@number_window.number * @item.price)
        case @item
        when RPG::Item
          $game_party.gain_item(@item.id, @number_window.number)
        when RPG::Weapon
          $game_party.gain_weapon(@item.id, @number_window.number)
        when RPG::Armor
          $game_party.gain_armor(@item.id, @number_window.number)
        end
        # Refresh each window
        @list_window.refresh
        @info_window.refresh
        @command_window.refresh
        # Change windows to buy mode
        @list_window.active = true
        @category_window.category = 0
      when 1  # sell
        # Sell process
        $game_party.gain_gold(@number_window.number * (@item.price / 2))
        case @item
        when RPG::Item
          $game_party.lose_item(@item.id, @number_window.number)
        when RPG::Weapon
          $game_party.lose_weapon(@item.id, @number_window.number)
        when RPG::Armor
          $game_party.lose_armor(@item.id, @number_window.number)
        end
        # Refresh each window
        @sell_windows[@category_window.category].refresh
        @info_window.refresh
        @command_window.refresh
        # Change windows to sell mode
        @sell_windows[@category_window.category].active = true
        @category_window.visible = true
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Next item category
  #--------------------------------------------------------------------------
  def next_category
    return if @list_window.active?
    @category_window.category = (@category_window.category + 1) % 5
    @category_window.category = 1 if @category_window.category == 0
    set_active_window
  end
  #--------------------------------------------------------------------------
  # * Previous item category
  #--------------------------------------------------------------------------
  def prev_category
    return if @list_window.active?
    @category_window.category = (@category_window.category - 1) % 5
    @category_window.category = 1 if @category_window.category == 0
    set_active_window
  end
  #--------------------------------------------------------------------------
  # * Set the active window
  #--------------------------------------------------------------------------
  def set_active_window
    @category_window.refresh
    # Determine if buy or sell windows are active
    if @sell_windows.any? {|win| win.visible?}
      # Set correct window visible
      @sell_windows.each{|win|
        win.visible = false
        win.active = false
      }
      @sell_windows[@category_window.category].visible = true
      # Set active if selling
      if @sell_mode
        @sell_windows[@category_window.category].index = 0 if @sell_windows[@category_window.category].index == -1
        @sell_windows[@category_window.category].active = true
        @info_window.item = @sell_windows[@category_window.category].item
        @party_window.item = @sell_windows[@category_window.category].item
      end
    end
  end
end #scene shop