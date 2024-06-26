#==============================================================================
# ** Scene_Essence
#------------------------------------------------------------------------------
#  This class performs essence screen processing.
#==============================================================================
class Scene_Essence < Scene_Base
  include MenuConfig
  LIST_CATEGORIES = [:party, :actor, :skills]
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     actor_index : actor index
  #--------------------------------------------------------------------------
  def initialize(actor_index = 0)
    super
    @actor_index = actor_index
    @list_category = :party #actor skills
  end
  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def pre_start
    # Get actor
    @actor = $game_party.actors(:all)[@actor_index]
    # Create windows
    x_origin = MENU_ORIGIN_X + COMMAND_WIN_WIDTH
    @help_window = Window_SuperHelp.new(x_origin, MENU_ORIGIN_Y + (MENU_WINDOW_HEIGHT-HELP_HEIGHT_TALL), MENU_WINDOW_WIDTH, HELP_HEIGHT_TALL)
    setup_command_window
    @sub_command_window.index = @actor_index
    @title_window = Window_EssenceTitle.new(x_origin, MENU_ORIGIN_Y, 320, HELP_HEIGHT_SHORT)
    @actor_list_window = Window_EssenceList.new(x_origin, MENU_ORIGIN_Y + @title_window.height, @title_window.width, MENU_WINDOW_HEIGHT - @title_window.height - @help_window.height, @actor.id, @actor)
    @party_list_window = Window_EssenceList.new(x_origin, MENU_ORIGIN_Y + @title_window.height, @title_window.width, MENU_WINDOW_HEIGHT - @title_window.height - @help_window.height, @actor.id)
    @actor_info_window = Window_ActorEssence.new(x_origin + @title_window.width, MENU_ORIGIN_Y, MENU_WINDOW_WIDTH - @title_window.width, MENU_WINDOW_HEIGHT - @help_window.height, @actor)
    @skill_info_window = Window_EssenceDetail.new(x_origin, MENU_ORIGIN_Y + @title_window.height, @title_window.width, MENU_WINDOW_HEIGHT - @title_window.height - @help_window.height, @actor)
    @prompt_window = Window_EssencePrompt.new
    # Associate help window
    @actor_list_window.help_window = @help_window
    @party_list_window.help_window = @help_window
    @skill_info_window.help_window = @help_window
    # Make initial window active
    @party_list_window.visible = true
    @party_list_window.index = 0
    if $game_party.actors(:all).size > 1
      @sub_command_window.active = true
      @party_list_window.active = false
    else
      @sub_command_window.active = false
      @party_list_window.active = true
      @party_list_window.update_help
    end
    #@info_window.refresh(@actor_window.ability)
    super
  end
  #--------------------------------------------------------------------------
  # * Terminate Scene
  #--------------------------------------------------------------------------  
  def terminate
    super
    clear_command_window
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Update windows
    super
    # Input update
    if @sub_command_window.active
      update_command
    elsif @skill_info_window.active
      update_skill_list
    elsif @actor_list_window.active
      update_actor_list
    elsif @party_list_window.active
      update_party_list
    end
    return if @sub_command_window.active
    category_switch = false
    # If R button was pressed
    if Input.trigger?(MENU_INPUT[:Actor_Forward])
      # To next actor
      actor_switch(@actor_index = (@actor_index + 1) % $game_party.actors(:all).size)
      return
    # If L button was pressed
    elsif Input.trigger?(MENU_INPUT[:Actor_Back])
      # Go to prev actor
      actor_switch(@actor_index = (@actor_index - 1) % $game_party.actors(:all).size)
      return
    # If the cursor was moved (category switch)
    elsif Input.trigger?(Input::LEFT)
      @title_window.index = (@title_window.index + 1) % LIST_CATEGORIES.size
      category_switch = true
    elsif Input.trigger?(Input::RIGHT)
      @title_window.index = (@title_window.index - 1) % LIST_CATEGORIES.size
      category_switch = true
    end
    if category_switch
      # Play SFX
      $game_system.se_play(RPG::AudioFile.new(PAGE_SFX,100,100))
      @list_category = LIST_CATEGORIES[@title_window.index]
      case @list_category
      when :party
        @title_window.refresh
        @actor_list_window.active = false
        @actor_list_window.index = -1
        @actor_list_window.visible = false
        @party_list_window.active = true
        @party_list_window.index = 0
        @party_list_window.visible = true
        @party_list_window.update_help
        @skill_info_window.active = false
        @skill_info_window.visible = false
        @skill_info_window.index = 0
      when :actor
        @title_window.refresh(@actor)
        @party_list_window.active = false
        @party_list_window.index = -1
        @party_list_window.visible = false
        @actor_list_window.active = true
        @actor_list_window.index = 0
        @actor_list_window.visible = true
        @actor_list_window.update_help
        @skill_info_window.active = false
        @skill_info_window.visible = false
        @skill_info_window.index = 0
      when :skills
        @title_window.refresh
        @party_list_window.active = false
        @party_list_window.index = -1
        @party_list_window.visible = false
        @actor_list_window.active = false
        @actor_list_window.index = 0
        @actor_list_window.visible = false
        @actor_list_window.update_help
        @skill_info_window.active = true
        @skill_info_window.visible = true
        @skill_info_window.index = 0
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (sub command window active)
  #-------------------------------------------------------------------------- 
  def update_command
    if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
      actor_switch(@sub_command_window.index)
    end
    if Input.trigger?(MENU_INPUT[:Back])
      close_scene
      return
    end
    if Input.trigger?(MENU_INPUT[:Confirm])
      $game_system.se_play($data_system.decision_se)
      @sub_command_window.active = false
      # Determine visible window
      case @list_category
      when :actor
        @actor_list_window.active = true
        @actor_list_window.index = 0
      when :skills
        @skill_info_window.active = true
        @skill_info_window.index = 0
      else
        @party_list_window.active = true
        @party_list_window.index = 0
      end
      return
    end
  end  
  #--------------------------------------------------------------------------
  # * Frame Update (if skill info window is active)
  #--------------------------------------------------------------------------
  def update_skill_list
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @skill_info_window.index = -1
        @skill_info_window.active = false
      else
        close_scene
      end
      return
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (if actor list window is active)
  #--------------------------------------------------------------------------
  def update_actor_list
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @actor_list_window.index = -1
        @actor_list_window.active = false
      else
        close_scene
      end
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Invalid selection
      if @actor_list_window.essence_at_index.nil?
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      essence_id = @actor_list_window.essence_at_index.id
      owner_id = @actor_list_window.owner_at_index
      actor = $game_party.actors(:all)[@actor_index]
      # Unequip
      if owner_id == actor.id
        # Unequip
        $game_system.se_play(RPG::AudioFile.new(MenuConfig::ESSENCE_UNEQUIP_SFX))
        actor.unequip_essence(essence_id)
        # Refresh windows
        @actor_list_window.refresh(actor.id, actor)
      # Invalid case
      else
        # Exit
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # If the current index is invalid
      if @actor_list_window.essence_at_index.nil?
        @actor_list_window.index = 0
      end
      # Refresh all windows
      @party_list_window.refresh(actor.id)
      @actor_info_window.refresh
      @skill_info_window.refresh
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update (when party list is active)
  #--------------------------------------------------------------------------
  def update_party_list
    # If B button was pressed
    if Input.trigger?(MENU_INPUT[:Back])
      # Switch to sub command window if the party is larger than 1
      if $game_party.actors(:all).size > 1
        # Play cancel SE
        $game_system.se_play($data_system.cancel_se)
        @sub_command_window.active = true
        @party_list_window.index = -1
        @party_list_window.active = false
      else
        close_scene
      end
      return
    end
    # If C button was pressed
    if Input.trigger?(MENU_INPUT[:Confirm])
      # Invalid selection
      if @party_list_window.essence_at_index.nil?
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      owner_id = @party_list_window.owner_at_index
      essence_id = @party_list_window.essence_at_index.id
      actor = $game_party.actors(:all)[@actor_index]
      # If this actor isn't able to equip the specified essence
      equip_result = actor.essence_equippable?(essence_id)
      if equip_result != true && actor.id != owner_id 
        # Exit (specify reason!)
        @help_window.set_text(nil, Localization.localize("&MUI[EssenceEquipError#{equip_result}]"))
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      # Branch by essence owner
      case owner_id
      # If the essence is free to equip
      when 0
        # Equip to active actor
        actor.equip_essence(@party_list_window.essence_at_index.id)
        $game_system.se_play(RPG::AudioFile.new(MenuConfig::ESSENCE_EQUIP_SFX))
        # Redraw this line
        @party_list_window.redraw_item(actor.id)
      # If we're just unequipping from this actor
      when actor.id
        # Unequip
        actor.unequip_essence(essence_id)
        $game_system.se_play(RPG::AudioFile.new(MenuConfig::ESSENCE_UNEQUIP_SFX))
        # Refresh windows
        @party_list_window.redraw_item(0)
      # Invalid case
      when nil
        # Exit
        $game_system.se_play($data_system.buzzer_se)
        return
      # If the essence is owned by another actor
      else
        # Prompt removal
        if prompt_essence_unequip(owner_id, essence_id)
          # Equip to new actor
          actor.equip_essence(@party_list_window.essence_at_index.id)
          $game_system.se_play(RPG::AudioFile.new(MenuConfig::ESSENCE_EQUIP_SFX))
          # Redraw item
          @party_list_window.redraw_item(actor.id)
        end
      end
      # Refresh all windows
      @actor_list_window.refresh(actor.id, actor)
      @actor_info_window.refresh
      @skill_info_window.refresh(actor)
    end
  end
  #--------------------------------------------------------------------------
  # * Prompt essence removal from another actor
  #--------------------------------------------------------------------------
  def prompt_essence_unequip(other_actor_id, essence_id)
    # Make the prompt window active and wait for player input
    @prompt_window.active = true
    @prompt_window.visible = true
    @prompt_window.refresh(other_actor_id, $game_party.actors(:all)[@actor_index])
    result = false
    loop do
      Graphics.update
      Input.update
      @prompt_window.update
      # Confirm input
      if Input.trigger?(MENU_INPUT[:Confirm]) && @prompt_window.index == 0
        # Unequip from other actor (equipping to current actor comes after the proc)
        $game_actors[other_actor_id].unequip_essence(essence_id)
        result = true
        break
      # Cancel
      elsif Input.trigger?(MENU_INPUT[:Back]) || Input.trigger?(MENU_INPUT[:Confirm])
        # Do nothing
        result = false
        break
      end
    end
    @prompt_window.active = false
    @prompt_window.visible = false
    return result
  end
  #--------------------------------------------------------------------------
  # * Switch actors
  # direction - determines if next (1) or previous (0)
  #--------------------------------------------------------------------------
  def actor_switch(index)
    @actor_index = index
    @sub_command_window.index = index if !@sub_command_window.active
    # Save old actor
    prev_actor = @actor
    # Set actor
    @actor = $game_party.actors(:all)[index]
    # Do stuff if the actor changed
    if @actor != prev_actor 
      # Play cursor SE
      $game_system.se_play(RPG::AudioFile.new(PAGE_SFX,100,100))
      # Update all windows
      @actor_list_window.refresh(@actor.id, @actor)
      @actor_info_window.refresh(@actor)
      @party_list_window.refresh(@actor.id)
      @title_window.refresh(@actor) if @actor_list_window.visible
      @skill_info_window.refresh(@actor)
      # Move to the top of the current window's list
      return if @sub_command_window.active
      if @party_list_window.active
        @party_list_window.index = 0
        @party_list_window.update_help
      elsif @actor_list_window.active
        @actor_list_window.index = 0
      elsif @skill_info_window.active
        @skill_info_window.index = 0
      end
    end
  end
end
