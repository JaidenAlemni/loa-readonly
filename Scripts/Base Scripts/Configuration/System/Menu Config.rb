#==============================================================================
# * MenuConfig
# This module contains menu configuration values
#==============================================================================
module MenuConfig
  #------------------------------------------------------------------------------
  # * Primary Configuration
  #
  # Set screensize (this should match XPA Tilemap)
  SCREENSIZE = [1280,720]
  # Set menu origin point based on resolution
  MENU_ORIGIN_X = (SCREENSIZE[0] - 1040) / 2
  MENU_ORIGIN_Y = (SCREENSIZE[1] - 600) / 2
  # Default window opacity
  MENU_WINDOW_OPACITY = 230
  MENU_WINDOW_WIDTH = 800
  MENU_WINDOW_HEIGHT = 600
  COMMAND_WIN_WIDTH = 240
  # X Coordinates for "off screen"
  WINDOW_OFFSCREEN_LEFT = -400
  WINDOW_OFFSCREEN_RIGHT = SCREENSIZE[1] + 400
  # Help Window
  HELP_HEIGHT_SHORT = 64
  HELP_HEIGHT_TALL = 96
  # Maximum number of savefiles
  MAX_SAVEFILES = 49
  # Animation speed in frames - lower = faster.
  WIN_ANIM_TIME  = 24
  WIN_ANIM_SPEED = 8 # Time to compete the animation (how long the animation cycles for)
  WIN_FADE_SPEED = 16 # Time to complete the fade out (generally faster than the move)

  #------------------------------------------------------------------------------
  # * Graphic File Names
  #
  GOLD_ICON = 'Menu/Silver'
  MAP_ICON = 'Menu/Location'
  XP_ICON = 'Menu/XP'

  BLANK_SKIN = 'Blank'
  DEFAULT_SKIN = 'Default'
  
  #------------------------------------------------------------------------------
  # * Sound Effects
  #
  PAGE_SFX = 'MUI_PageTurn1'
  START_SFX = 'MUI_NewGame'
  UNEQUIP_SFX = 'MUI_Unequip'
  ESSENCE_EQUIP_SFX = 'MUI_EssenceOn'
  ESSENCE_UNEQUIP_SFX = 'MUI_EssenceOff'

  #------------------------------------------------------------------------------
  # * Commands
  # These strings are used in code, and are localized elsewhere.
  MAINMENU_COMMANDS = ['Items', 'Essence', 'Equipment', 'Status', 'Journal', 'Party', 'Memories', 'Options', 'Quit Game']
  # Essence, Equipment, and Status all use the actor list as a submenu
  ITEM_COMMANDS = ['Consumables', 'Materials', 'Key Items']
  #STATUS_COMMANDS = ['Status Effects', 'Awakening', 'Stat Info']
  COLLECT_COMMANDS = ['Quests', 'Bestiary', 'Recipes', 'Books']
  SAVE_COMMANDS = ['Save', 'Recall', 'Erase']
  OPTION_COMMANDS = ['Gameplay','System','Display']
  # The main menu utilizes a hash/key system to properly maintain the index of menus and submenus
  # Map main menu submenus
  MAINMENU_SUB_COMMANDS = {
    MAINMENU_COMMANDS[0] => ITEM_COMMANDS,
    MAINMENU_COMMANDS[1] => :actors,
    MAINMENU_COMMANDS[2] => :actors,
    MAINMENU_COMMANDS[3] => :actors,
    MAINMENU_COMMANDS[4] => COLLECT_COMMANDS,
    MAINMENU_COMMANDS[5] => nil,
    MAINMENU_COMMANDS[6] => SAVE_COMMANDS,
    MAINMENU_COMMANDS[7] => OPTION_COMMANDS,
    MAINMENU_COMMANDS[8] => nil
  }    
  #------------------------------------------------------------------------------
  # * Stat symbols
  #
  STATS = [
    :atk, 
    :eva,
    :pdef, 
    :mdef, 
    :dex, 
    :int, 
    :agi, 
    :str
  ]
  #------------------------------------------------------------------------------
  # Keys
  #
  MENU_INPUT = {
    Confirm: Input::C,
    Back: Input::B,
    Actor_Back: Input::A,
    Actor_Forward: Input::Z,
    Extra: Input::X,
    Pause: Input::PAUSE
  }

  CONTROLS = [:Confirm, :Cancel, :Aux, :Move, :Switch_L, :Switch_R]

  # Map controls to variables
  # def self.assign_control_vars
  #   CONTROLS.each_with_index do |sym, i|
  #     $game_variables[51 + i] = self.control_text(sym, Input.joystick)
  #   end
  # end

  # $game_variables[n] = MenuConfig.control_text(:Confirm,Input.controller_connected?(0))

  #MenuConfig::CONTROLS[:Confirm][0]
  #Input.controller_connected?(0)

  #--------------------------------------------------------------------------  
  # Special names for converting
  MAIN_CHAR_NAMES = {
    # Language converting TO
    jp: {
      "Oliver" => "オリバー",
    },
    en_us: {
      "オリバー" => "Oliver",
    }
  }

end
#==============================================================================
# * MenuDescriptions
# This module contains various strings for special menu descriptions
#==============================================================================
module MenuDescriptions
  #------------------------------------------------------------------------------
  # * Stat Descriptions
  #------------------------------------------------------------------------------
  def self.stat_description(stat)
    # Just grab from the localization file now
    return Localization.localize("&MUI[StatDesc#{stat}]")
  end
  #------------------------------------------------------------------------------
  # * State Descriptions
  #------------------------------------------------------------------------------
  def self.state_description(state_id, _actor)
    Localization.localize("&MUI[StateDesc#{state_id}]")
    # case state_id
    #   when 1 then "#{actor} is on the verge of death..."
    #   when 2 then "#{actor} is stunned and cannot move."
    #   when 3 then "#{actor} is poisoned and will continue to lose Life Energy until healed."
    #   when 4 then "#{actor}'s capacity to connect attacks is severely reduced."
    #   when 5 then "#{actor} cannot cast spells or use abilities."
    #   when 6 then "#{actor} does not know friends from enemies."
    #   when 7 then "#{actor} is having a nap...now isn't the time!"
    #   when 8 then "#{actor} cannot move at all."
    #   when 9 then "#{actor}'s Power is reduced."
    #   when 10 then "#{actor}'s Aptitude is reduced."
    #   when 11 then "#{actor}'s Swiftness is reduced."
    #   when 12 then "#{actor}'s Focus is reduced."
    #   when 13 then "#{actor}'s Attack power is increased"
    #   when 14 then "#{actor}'s Endurance is increased."
    #   when 15 then "#{actor}'s Willpower is increased."
    #   when 16 then "#{actor}'s combat skills are increased."
    #   when 24 then "#{actor} has temporary protection from death."
    #   #... add more
    #   else ''
    # end
  end  
  #------------------------------------------------------------------------------
  # * Item additional descriptions
  #------------------------------------------------------------------------------
  def self.items(item)
    # Get the ID
    item_id = item.id
    # Determine if the item heals HP, MP, or Both
    # I'm sorry to anyone who has to behold this monstrosity
    # text = 
    #   # Single states for now
    #   if item.plus_state_set.size == 1
    #     Localization.localize('&MUI[ItemStat_StatePlus]').sub!('!S', $data_states[item.plus_state_set[0]].loc_name.to_s)
    #   elsif item.minus_state_set.size == 1
    #     Localization.localize('&MUI[ItemStat_StateMinus]').sub!('!S', $data_states[item.minus_state_set[0]].loc_name.to_s)
    #   elsif item.recover_hp > 0 && item.recover_sp > 0 && item.recover_hp == item.recover_sp # HP + SP recovery
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_HPMPPlus]').sub!('!N', item.recover_hp.to_s)
    #   elsif item.recover_hp > 0
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_HPPlus]').sub!('!N', item.recover_hp.to_s)
    #   elsif item.recover_sp > 0
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_MPPlus]').sub!('!N', item.recover_sp.to_s)
    #   elsif item.recover_hp_rate != 0 && item.recover_sp_rate != 0 && item.recover_hp_rate == item.recover_sp_rate
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_HPMPRate]').sub!('!N', item.recover_hp_rate.to_s)
    #   elsif item.recover_hp_rate != 0
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_HPRate]').sub!('!N', item.recover_hp_rate.to_s)
    #   elsif item.recover_sp_rate != 0
    #     # Get the recovery amount and sub for value
    #     Localization.localize('&MUI[ItemStat_MPRate]').sub!('!N', item.recover_sp_rate.to_s)
    #   else # Print by ID
    #     Localization.localize("&MUI[ItemStat#{item_id}]")
    #   end
    text = Localization.localize("&MUI[ItemStat#{item_id}]")
    # # Substitute placeholder text for blank
    # text = '' if text == 'NODATA'
    return text
  end
  #------------------------------------------------------------------------------
  # * Journal command descriptions
  #------------------------------------------------------------------------------
  def self.journal_command(index)
    case index
    when 0; "View quests, including those in progress and those which have been completed."
    when 1; "Explore enemies in detail, such as their maximum health, weaknesses, and drops."
    when 2; "View available recipes for synthesizing items based on visited shops. (Currently Disabled)"
    when 3; "Read books that have been obtained."
    when 4; "Return to the previous screen."
    end
  end
  #------------------------------------------------------------------------------
  # * Options menu descriptions
  #------------------------------------------------------------------------------
  def self.options_command(index)
    case index
    when 0..4
      "&MUI[OptionsMenuDesc#{index}]"
    when 5
      if $game_options.battle_list_wait
        '&MUI[OptionsMenuDesc5a]'
      else
        '&MUI[OptionsMenuDesc5b]'
      end
    when 6
      if $game_options.battle_ab_style
        '&MUI[OptionsMenuDesc6a]'
      else
        '&MUI[OptionsMenuDesc6b]'
      end
    when 7..11
      "&MUI[OptionsMenuDesc#{index}]"
    else
      ""
    end
  end
  #------------------------------------------------------------------------------
  # * Shop command descriptions
  #------------------------------------------------------------------------------  
  def self.shop_command(index)
    "&MUI[ShopMenuDesc#{index}]"
  end
  #------------------------------------------------------------------------------
  # * Shop command descriptions
  #------------------------------------------------------------------------------  
  def self.blacksmith(index)
    case index
    when 0 then return "Construct an item using various materials."
    when 1 then return "Extract materials from an item."
    when 2 then return "Use materials to perform an enchantment on an item and increase its effects."
    when 3 then return "Go to the equipment screen to manage party member's equipment."
    when 4 then return "Exit the shop."
    end
  end
end
