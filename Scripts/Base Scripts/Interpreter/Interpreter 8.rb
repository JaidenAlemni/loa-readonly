#==============================================================================
# ** Interpreter (part 8)
# Additional functions
#------------------------------------------------------------------------------
#  This interpreter runs event commands. This class is used within the
#  Game_System class and the Game_Event class.
#==============================================================================
class Interpreter
  #==============================================================================
  # Event Range Conditions
  # Author: ForeverZer0
  # Date: 5.1.2011
  # Version: 1.1
  #
  #   Allows you to set up conditional branches in events that will be based off
  #   the event's coordinates in relation to the player's coordinates without 
  #   having to create any variables for the X and Y of each.
  #
  #   Remember that if you use a range condition with a parallel trigger, it will
  #   continue to execute as long as the condition is met and if the player cannot
  #   move during the event's code, the game will effectively be stuck.
  #
  #--------------------------------------------------------------------------
  #   range?(RANGE, EVENT_ID) - Will be true if player is anywhere in the radius
  #                             defined by RANGE from the event with EVENT_ID
  def range?(range = 4, id = @event_id)
    e = $game_map.events[id]
    radius = (Math.hypot((e.x - $game_player.x), (e.y - $game_player.y))).abs
    return (radius <= range)
  end
  #--------------------------------------------------------------------------
  #   on_screen?(EVENT_ID)    - Will be true if the event with EVENT_ID is within
  #                             the visible screen
  def on_screen?(id = @event_id)
    return (($game_map.events[id].screen_x(false)).between?(-128, LOA::SCRES[0] + 128) && ($game_map.events[id].screen_y(false)).between?(-128, LOA::SCRES[1] + 128))
    #x, y = $game_map.events[id].real_x, $game_map.events[id].real_y
    #return ((x - $game_map.display_x + 64) / 4).between?(0, LOA::SCRES[0]) && ((y - $game_map.display_y) / 4).between?(0, LOA::SCRES[1])
  end
  #--------------------------------------------------------------------------
  #   x_dist?(DIST, EVENT_ID) - Returns true if the player's x/y is within DIST
  #            OR               of event's x/y with EVENT_ID. These are absolute
  #   y_dist?(DIST, EVENT_ID)   values, meaning it doesn't matter which direction,
  #                             it just uses the total distance in tiles for that
  #                             axis. Use a DIST of 0 to check if that axis is 
  #                             equal.
  #
  def x_dist?(distance = 0, id = @event_id)
    x_dif = ($game_map.events[id].x - $game_player.x).abs
    return (x_dif <= distance)
  end
  #--------------------------------------------------------------------------
  def y_dist?(distance = 0, id = @event_id)
    y_dif = ($game_map.events[id].y - $game_player.y).abs
    return (y_dif <= distance)
  end
  #--------------------------------------------------------------------------
  #   player_above?(EVENT_ID) - Returns true when player is above event.
  #   player_below?(EVENT_ID) - Returns true when player is below event.
  #   player_right?(EVENT_ID) - Returns true when player is right of the event.
  #   player_left?(EVENT_ID)  - Returns true when player is left of the event.
  #
  def player_above?(id = @event_id)
    return ($game_map.events[id].y > $game_player.y)
  end
  #--------------------------------------------------------------------------
  def player_below?(id = @event_id)
    return ($game_map.events[id].y < $game_player.y) 
  end
  #--------------------------------------------------------------------------
  def player_right?(id = @event_id)
    return ($game_map.events[id].x < $game_player.x) 
  end
  #--------------------------------------------------------------------------
  def player_left?(id = @event_id)
    return ($game_map.events[id].x > $game_player.x) 
  end
  #--------------------------------------------------------------------------
  # Checks to see if the player is adjacent to and facing the event
  #
  def facing?(id = @event_id)
    return false unless $game_map.events[id]
    case $game_player.direction
    when 2
      ($game_map.events[id].y == $game_player.y + 1) && ($game_map.events[id].x == $game_player.x)
    when 4
      ($game_map.events[id].x == $game_player.x - 1) && ($game_map.events[id].y == $game_player.y) 
    when 6
      ($game_map.events[id].x == $game_player.x + 1) && ($game_map.events[id].y == $game_player.y)
    when 8
      ($game_map.events[id].y == $game_player.y - 1) && ($game_map.events[id].x == $game_player.x)
    end
  end
  #=======================================================================
  # * Cutscene Pause
  # When called, it will pause the advancement of the interpeter and
  # display an animation in the bottom right corner of the screen.
  # *** Unused for now
  #---------------------------------------------------------------------
  def cutscene_pause
    #csprite = Sprite_TextAdvance.new
    until Input.trigger?(Input::C) do
      #csprite.update
      $game_screen.update
      $scene.spriteset_update
      Graphics.update
      Input.update
    end
    #csprite.dispose
    return false
  end
  #===============================================================================
  # * Heretic's Lightning 
  #--------------------------------------------------------------------------
  # * Lightning
  #     duration : time in Frames
  #--------------------------------------------------------------------------
  def lightning(duration)
    # Call Game Screen for Command Execution
    $game_screen.lightning(duration)
  end
  #--------------------------------------------------------------------------
  # * Thunder
  #     volume : Numeric Value between 0 and 100 at which SE will Play
  #     pitch  : Numeric Value that SE will Play.  100 for Normal Pitch
  #     file   : Sound Effect File Name in SE Database
  #
  #   - Plays Thuder Sound Effect with Variations on Volume and Pitch
  #--------------------------------------------------------------------------
  def se_thunder(volume=100, pitch=100, file='MAP_ThunderClap')
    # Call Game Screen for Command Execution (order is different than args)
    thunder = RPG::AudioFile.new(file, volume, pitch)
    # Play Sound
    $game_system.se_play(thunder)
  end
  #==============================================================================
  # * Heretic's Easy Chests for MMW
  #
  #--------------------------------------------------------------------------
  # * Facing Chest? - Returns True if Player is close to the chest 
  #--------------------------------------------------------------------------
  def facing_chest?
    # Player
    plr = $game_player
    # Chest Event from Map
    e = $game_map.events[@event_id]
     # ensure they are on the same level
    return true if (plr.pass_height == e.pass_height)
                  #  && ((plr.y <= e.y && e.direction == 8) ||
                  #  (plr.y >= e.y && e.direction == 2) ||
                  #  (plr.x <= e.x && e.direction == 4) ||
                  #  (plr.x >= e.x && e.direction == 6))
    # Not Facing Chest
    return false
  end
  #--------------------------------------------------------------------------
  # * Open Chest
  #     delay : wait time between Frames of Animation
  #
  #   - Creates a Move Route for the Chest to show the Open Animation
  #--------------------------------------------------------------------------
  def open_chest(delay = 4)
    # Create an RPG::MoveRoute Object
    route = CustomRoutes.create_route(:cycle_anim_forward, delay)
    # Use the Move Route to give the Chest the Open Animation
    $game_map.events[@event_id].force_move_route(route)
  end
  #--------------------------------------------------------------------------
  # * Close Chest
  #     delay : wait time between Frames of Animation
  #
  #   - Creates a Move Route for the Chest to show the Close Animation
  #   - Used when Quantity of Items in Party Inventory in addition to
  #     the Quantity of Items in the Chest being more than 99, which
  #     causes Items to be wasted and NOT given to the Player.
  #--------------------------------------------------------------------------
  def close_chest(delay = 4)
    # Create an RPG::MoveRoute Object
    route = CustomRoutes.create_route(:cycle_anim_back, delay)
    # Use the Move Route to give the Chest the Open Animation
    $game_map.events[@event_id].force_move_route(route)
  end
  #--------------------------------------------------------------------------
  # * Icon Msg (ID)
  #     ID : Item ID in $game_temp.easy_chest_items[] array
  #
  #   - Creates Text to send to M.M.W. for dispalying Name and Icon
  #--------------------------------------------------------------------------
  def icon_msg(item)
    # Text to be shown in a M.M.W. Window
    text = ''
    # Branch by Type
    case item
    when RPG::Item
      text = "  \\I&N[I#{item.id}]" #+ Localization.localize("&MUI[ExploreSuffixItem]")
    when RPG::Weapon
      text = "  \\I&N[W#{item.id}]" #+ Localization.localize("&MUI[ExploreSuffixWeapon]")
    when RPG::Armor
      text = "  \\I&N[A#{item.id}]" #+ Localization.localize("&MUI[ExploreSuffixArmor]")
    when RPG::Essence
      text = "  \\I&N[E#{item.id}]" + Localization.localize("&MUI[ExploreSuffixEssence]")
    end
    # Return value of Text
    return text
  end
  #--------------------------------------------------------------------------
  # * Have Room for Items?
  #   - Used in Conditional Branch
  #   - Checks to see if Quantity of Any Items in Chest plus what is in
  #     the Party's Inventory exceeds Limit causing Item Waste
  #--------------------------------------------------------------------------
  def have_room_for_items?
    # Default
    have_room = true
    # Iterate through each Item in the Easy Chest Items array
    for i in 0...$game_temp.easy_chest_items.size
      # Item to be checked
      item = $game_temp.easy_chest_items[i][0]
      # Number of this type of Item in the Chest
      quantity = $game_temp.easy_chest_items[i][1]
      # Branch by Item Type
      case item
      when RPG::Item
        # Check this Item Quantity for Item Waste
        if $game_party.item_number(item.id) + quantity > 999
          # No Room
          have_room = false
          # Dont bother checking other Items
          break
        end
      when RPG::Weapon
        # Check this Weapon for Item Waste
        if $game_party.weapon_number(item.id) + quantity > 99
          # No Room
          have_room = false
          # Dont bother checking other Items
          break
        end        
      when RPG::Armor
        # Check Armor for Item Waste
        if $game_party.armor_number(item.id) + quantity > 99
          # No Room
          have_room = false
          # Dont bother checking other Items
          break
        end        
      end      
    end
    # True or False if there is room in the Inventory
    return have_room
  end
  #--------------------------------------------------------------------------
  # * Clear Chest Items
  #   - Prevents other chests from getting items that don't belong to it.
  #--------------------------------------------------------------------------
  def clear_chest_items
    # Empty the Array
    $game_temp.easy_chest_items = []
  end
  #--------------------------------------------------------------------------
  # * Chest Items to Party
  #   - Takes all the Items in the Chest and p them in the Party's 
  #     Inventory with proper count of each Item
  #--------------------------------------------------------------------------
  def chest_items_to_party
    $game_temp.easy_chest_items.each do |item, qty|
      case item
      when RPG::Item
        $game_party.gain_item(item.id, qty)
      when RPG::Weapon
        $game_party.gain_weapon(item.id, qty)
      when RPG::Armor
        $game_party.gain_armor(item.id, qty)
      when RPG::Essence
        $game_party.gain_essence(item.id, qty)
      end
    end
    $game_temp.easy_chest_items = []
  end
  #--------------------------------------------------------------------------
  # * Add Chest Item
  #     item_id   : ID from Database
  #     item_type : Specify Database 0 - Item, 1 - Weapon, 2 - Armor
  #     quantity  : Quantity of Item to be given to Player
  #
  #   - This creates a List of Items stored in $game_temp.easy_chest_items
  #     so that we can later check that all of the Items in the Chest will
  #     fit into the Party's Inventory without any Item Waste.
  #--------------------------------------------------------------------------
  def add_chest_item(item_type, item_id, quantity = 1)
    # Branch by Item Type
    case item_type
      when :item # Item
        item = $data_items[item_id]
      when :weapon # Weapon
        item = $data_weapons[item_id]
      when :armor # Armor
        item = $data_armors[item_id]
      when :essence # Essence
        item = $data_essences[item_id]
    end
    if item
      # Add the Item and Quantity to Array as Array
      $game_temp.easy_chest_items.push([item, quantity])
    end    
  end  
  #--------------------------------------------------------------------------
  # * Show Chest Text
  #--------------------------------------------------------------------------
  def setup_chest_text
    # Get items
    items = $game_temp.easy_chest_items
    text = Localization.localize("&MUI[ExploreChestGet]")
    text += "\\D[3]" # Wait a bit
    # If there is gold
    if $game_variables[20] != 0
      text += "  \\I&N[I100] × #{$game_variables[20]}\n"
    end
    # Append to the string each item
    items.each_with_index do |item, i|
      text += icon_msg(item[0])
      if item[1] > 1
        text += " × " + item[1].to_s
      end
      if item == items.last
        text += "!"
      else
        text += "\n"
      end
    end
    $game_temp.message_text = text
  end
  #--------------------------------------------------------------------------
  # * Setup Pickup Text
  #--------------------------------------------------------------------------
  def setup_pickup_text
    str = Localization.localize('&MUI[ExploreGet]')
    # If there is gold
    if $game_variables[20] != 0
      subval = "\\I&N[I100] × #{$game_variables[20]}"
    else
      msg, qty = $game_temp.easy_chest_items[0]
      if qty < 2
        subval = "\\C[*]#{icon_msg(msg)}\\C[0]"
      else
        subval = "\\C[*]#{icon_msg(msg)}\\C[0] × #{qty}"  
      end
    end
    str.sub!('!N', subval)
    $game_temp.message_text = "\\P[0]" + str
  end
  #--------------------------------------------------------------------------
  # * Show Chest Text
  #--------------------------------------------------------------------------
  def show_chest_text
    return unless $game_temp.message_text
    # Set message end waiting flag and callback
    # Play SE

    @message_waiting = true
    $game_temp.message_proc = Proc.new { @message_waiting = false }
  end
  #==============================================================================
  # * Multiple Message Windows
  #
  def message
    $game_system.message
  end

  def within_range?(range = 4, id = @event_id)
    e = $game_map.events[id]
    radius = (Math.hypot((e.x - $game_player.x), (e.y - $game_player.y))).abs
    return (radius <= range)
  end

  # Not sure if this will be useful, leaving undocumented for now
  def event_move_continue(event_id)
    $game_map.events[event_id].event_move_continue(event_id, true)
  end  
  
  def number_cancelled?
    return $game_system.number_cancelled
  end
  
  # def set_multi
  #   # Setting these two variables causes the Next Message to be displayed.
  #   @multi_message = true
  #   @message_waiting = false
  # end

  def set_max_dist(dist, save = true)
    return if not $scene.is_a?(Scene_Map)
    $game_map.events[@event_id].dist_kill = dist if dist.is_a?(Numeric)
    # If Max Distance is 0 and Location is NOT Passable when triggered
    if $game_map.events[@event_id].dist_kill == 0 and
       (!$game_map.passable?($game_map.events[@event_id].x,
                           $game_map.events[@event_id].y,
                           0) or
       ($game_map.events[@event_id].character_name != "" and
       !$game_map.events[@event_id].through))
      # Bump it up to 1 because 0 doesnt work for non passable triggers
      $game_map.events[@event_id].dist_kill = 1
    end
    
    # Prevent closing at a distance for other NPC's that might be speaking...
    #@max_dist_id = event_id
    # Save MMW Configuration in case of a Walk Away...
    save_mmw_vars if save
  end
  
  def clear_max_dist
    return if not $scene.is_a?(Scene_Map)
    # Leaves MMW Settings Intact and unsets Variable that causes End Commands
    $game_map.events[@event_id].dist_kill = nil
  end  
  #==============================================================================
  # * Shake Screen
  # duration - length (in frames) to shake
  # power - how much 
  #--------------------------------------------------------------------------   
  def shake_screen(duration, power)
    $game_temp.shake_maxdur = duration
    $game_temp.shake_dur = duration
    $game_temp.shake_power = power
    # Continue
    return true
  end
  #==============================================================================
  # * Get Self Switch(ch, id) - Interpreter
  #       ch     : A, B, C, or D
  #       id     : Event ID (Default to self.id)
  #       map_id : (Optional) Current or Specified Map ID  
  #
  #   - Returns True if a Switch is ON, False if Switch is OFF
  #   - This is NOT called from Move Route - Script
  #--------------------------------------------------------------------------  
  def get_self_switch(ch, id = nil, map_id = $game_map.map_id)
    # If we have A, B, C, or D, and the Event exists on same Map
    if ch.is_a?(String) && "ABCD".include?(ch.upcase) && 
       id && (map_id != $game_map.map_id || $game_map.events[id])
      # Make a Key for the Hash in a Key / Value Pair
      key = [map_id, id, ch.upcase]
      # Return the boolean value of the Self Switch
      return $game_self_switches[key]
    else
      if $DEBUG
        print "Warning: get_self_switch expects Two Arguments\n",
              "The First Argument should be the Letter of\n",
              " the Self Switch you are Checking, A, B, C, or D\n",        
              "The Second Argument should be the Event's ID\n",
              "Example: get_self_switch('B', 23)\n\n",
              "Note: The call that generated this error",
              "was NOT called from a Move Route\n ",
              "just an Event Script\n\n",
              "Your Script: Event -> Script get_self_switch('",ch,"','",id,"')" 
        # Explain the Problem of No ID
        if id.nil?
          print "The Event ID: ", id, " isn't set in your script call"
        # If on the Same Map and Event doesn't exist, explain the Problem
        elsif map_id == $game_map.map_id and not $game_map.events[id]
          print "The Event ID: ", id, " doesn't exist on this map"
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Set Self Switch(ch, value, id) - Interpreter
  #     ch     : A, B, C, or D
  #     value  : true, false
  #     id     : Event ID (default self.id)
  #     map_id : (Optional) Current Map ID or Specified Map ID
  #
  #   - Change a Self Switch for any Event from another Event -> Script
  #   - Use this ONLY to change a Self Switch for another Event.  The
  #     game engine already has a button for changing Self Switches.  
  #   - This is NOT called from Move Route - Script
  #--------------------------------------------------------------------------  
  def set_self_switch(ch, value, id = @event_id, map_id = $game_map.map_id)
    # # Valid Values
    # value_valid = [true, false, 0, 1, 'on','off']
    # if value.is_a?(String)
    #   value = true if value.to_s.downcase == 'on'
    #   value = false if value.to_s.downcase == 'off'
    # elsif value.is_a?(Integer)
    #   value = true if value == 1
    #   value = false if value == 0
    # end
    if ch.is_a?(String) && "ABCD".include?(ch.upcase) && id &&
       (map_id != $game_map.map_id || $game_map.events[id])
      # If event ID is valid
      if id > 0 && !id.nil?
        # Make Upper Case for Key
        ch = ch.to_s.upcase
        # Make a Key for the Hash in a Key / Value Pair
        key = [map_id, id, ch]
        # Set the boolean value of the Self Switch (true / false)
        $game_self_switches[key] = value
      end
      # Refresh map
      $game_map.need_refresh = true
      # Continue
      return true
    else
      if $DEBUG
        print "Warning: set_self_switch expects THREE Arguments\n",
              "The First Argument should be the letter A, B, C, or D\n",
              "The Second Argument should be either True or False\n",
              "The 3rd Argument is used to specify an Event ID\n\n",
              "Example: set_self_switch('B','Off', 32)\n\n",
              "Note: The call that generated this error ",
              "was NOT called from a Move Route\n",
              "just an Event Script\n\n",
              "set_self_switch in MOVE ROUTES => SCRIPT expect TWO Arguments,",
              "THIRD Optional\n",
              "set_self_switch in EVENT => SCRIPT expects THREE Arguments\n\n",
              "Your Script: Event -> Script set_self_switch('",ch,"','",value,
              "','",id,"')"              
        # Explain the Error to the User
        if id.nil?
          print "The Event ID: ", id, " isn't set in your script call"
        # If on the Same Map and Event doesn't exist, explain the Problem
        elsif map_id == $game_map.map_id and not $game_map.events[id]
          print "The Event ID: ", id, " doesn't exist current Map"
        end              
      end
    end
  end    
  #==============================================================================    
  # * Force action
  # Used to send forced actions via a script call in the battle interpreter
  # is_actor - true = actor, false = enemy
  # key - action sequence name
  #--------------------------------------------------------------------------
  def force_battle_action(sym, index, key)
    # Get out of here if it's not battle
    return unless $scene.is_a?(Scene_Battle)
    # Pass the action to the spriteset
    is_actor = (sym == :actor ? true : false)
    $scene.spriteset.set_action(is_actor, index, key)
    # Advance index
    return true
  end
  #--------------------------------------------------------------------------
  # * Queue a battle wait
  #--------------------------------------------------------------------------
  def battle_wait(seconds)
    # Get out of here if it's not battle
    return unless $scene.is_a?(Scene_Battle)
    $scene.wait(seconds)
    # Advance index
    return true
  end
  #==============================================================================    
  # * Call Shop
  # Used to call a shop with the specified ID
  #--------------------------------------------------------------------------
  def call_shop(id)
    # Set battle abort flag
    $game_temp.battle_abort = true
    # Set shop calling flag
    $game_temp.shop_calling = true
    # Set goods list on new item
    $game_temp.shop_id = id
    # Stop advancing the index to break to the map transfer loop
    return false
  end
  #==============================================================================    
  # Character Bust Management
  # ---
  # Allows manipulation of Game_Busts class
  #--------------------------------------------------------------------------
  # * Setup Cutscene
  # Calls the given cutscene and make the chosen character active
  #--------------------------------------------------------------------------
  def setup_messages(sym)
    # Set message settings
    $game_system.message.setup(sym)
    # # Setup positions, save given arrangement to an array
    # positions = BustConfig.setup_cutscene(id)
    # # Show each bust in the array
    # positions.each do |pos|
    #   $game_busts.show_bust(pos)
    # end
    # # Make the first position active
    # active_char = (active ? active : positions[0])
    # $game_busts.make_active(active_char)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Show Bust
  # Display the character at given pos(ition)
  #--------------------------------------------------------------------------
  def show_bust(pos)
    $game_busts.show_bust(pos)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Hide Bust
  # Hide the character at the given position
  #--------------------------------------------------------------------------
  def hide_bust(pos)
    $game_busts.hide_bust(pos)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Hide All Busts
  # Hide the character at the given position
  #--------------------------------------------------------------------------
  def hide_all_busts
    for i in 1..6
      $game_busts.hide_bust(i)
    end
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Make Active
  # Make the character at the given position active
  # emotion - specifies an emotion change
  #--------------------------------------------------------------------------
  def make_bust_active(pos, emotion = nil)
    $game_busts.make_active(pos, emotion)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Change Emotion
  # Change the emotion of the character at the given pos(ition)
  #--------------------------------------------------------------------------
  def change_bust_emotion(pos, emotion)
    $game_busts.change_emotion(pos, emotion)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Clear All Busts
  # Called at the end of a cutscene, erases all of the busts at each position
  #--------------------------------------------------------------------------
  def clear_all_busts
    for i in 1..6
      $game_busts.clear_bust(i)
    end
  end
  #==============================================================================    
  # Custom Move Routes
  # ---
  # A series of pre-made move routes for character sprites
  #--------------------------------------------------------------------------
  # * Custom move route
  # id - character ID (-1 player, 0 this event, 1+ event ID)
  # route - custom route method symbol
  # parameters - parameters, which can vary based on the route type
  #--------------------------------------------------------------------------
  def custom_move_route(id, route_sym, *params)
    # Get character
    character = get_character(id)
    # If no character exists
    if character == nil
      # Continue
      return true
    end
    # Get the custom route
    route = CustomRoutes.create_route(route_sym, character, *params)
    # Force move route
    character.force_move_route(route)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Reset character
  # Returns the specified character ID to its original settings
  #--------------------------------------------------------------------------
  def reset_character_graphic(id = 0)
    # Get character
    character = get_character(id)
    # If no character exists
    if character == nil
      # Continue
      return true
    end
    # Get the route
    route = CustomRoutes.create_route(:reset_graphic, character)
    # Force move route
    character.force_move_route(route)
    # Continue
    return true
  end
  #--------------------------------------------------------------------------
  # * Reset Event Trigger
  # Forces an event back to it's untriggered state, even if the character is still within range
  # Useful for things like opening doors, etc. that need a "double trigger"
  #--------------------------------------------------------------------------
  def reset_event_trigger
    # Get this event
    character = get_character(0)
    # If no character exists
    if character == nil
      # Continue
      return true
    end
    character.trigger_on = false
    character.triggering_event_id = nil
    true
  end
  #--------------------------------------------------------------------------
  # * Show Map Name
  # Enables the flag to display the map name on screen
  #--------------------------------------------------------------------------
  def show_map_name
    # Enable flag
    $game_temp.display_map_name = true
    # Continue
    true
  end
  #--------------------------------------------------------------------------
  # * Set Camera Zoom
  # Sets the map zoom level, and records it
  #--------------------------------------------------------------------------
  def camera_zoom(f, zoom_to = nil)
    if zoom_to
      Camera.zoom_to(f, zoom_to)
    else
      Camera.zoom = f
      Graphics.update
    end
    if $scene.is_a?(Scene_Map)
      $game_map.current_zoom = f
    end
    true
  end
  #--------------------------------------------------------------------------
  # * Setup fogs
  # Sets map fog objects
  # Required: name
  # Optional: index, opacity, zoom, blend type, scroll x / y, tone, hue
  #--------------------------------------------------------------------------
  def add_map_fog(name, index: 0, zoom: 100, opacity: 64, blend_type: 0, sx: 0, sy: 0, tone: Tone.new(0,0,0,0), hue: 0)
    fog = $game_map.fogs[index]
    fog[:name] = name
    fog[:zoom] = zoom
    fog[:opacity] = fog[:opacity_target] = opacity
    fog[:blend_type] = blend_type
    fog[:sx] = sx
    fog[:sy] = sy
    fog[:tone] = fog[:tone_target] = tone
    fog[:hue] = hue
    true
  end
  #--------------------------------------------------------------------------
  # * Remove fog
  # Clears a fog specified by index
  #--------------------------------------------------------------------------
  def remove_map_fog(index)
    $game_map.fogs[index][:name] = ""
    $game_map.fogs[index][:opacity] = 0
    true
  end
  #--------------------------------------------------------------------------
  # * Clear map fogs
  # Remove all fogs
  #--------------------------------------------------------------------------
  def clear_map_fogs
    $game_map.fogs.each do |fog|
      fog[:name] = ""
      fog[:opacity] = 0
    end
    true
  end
  #--------------------------------------------------------------------------
  # * Memorize Screen Tone
  # Saves the screen tone to a temporary variable and resets it
  #   time : time in frames to process tone change
  #   new_tone : tone to transition to, default clears tone
  #--------------------------------------------------------------------------
  def memorize_screen_tone(time = 20, new_tone = Tone.new(0,0,0,0))
    $game_screen.previous_tone = $game_screen.tone.dup
    $game_screen.start_tone_change(new_tone, time)
    true
  end
  #--------------------------------------------------------------------------
  # * Restore Screen Tone
  # Restores the screen tone
  #   time : time in frames to process tone change
  #--------------------------------------------------------------------------
  def restore_screen_tone(time = 20)
    $game_screen.start_tone_change($game_screen.previous_tone, time)
    true
  end
  #--------------------------------------------------------------------------
  # * Setup Lightmap
  # Creates and applies a lightmap to the map
  #   name : name of file in Fogs/Lightmaps folder, or a Color
  #   blend_mode : 0 normal, 1 add, 2 subtract, 3 multiply (experimental)
  #   fade_time : when set, frames to transition color
  #--------------------------------------------------------------------------
  def setup_lightmap(name, color = Color.new(), opacity = 255, blend_mode = 2, fade_time = 0)
    return true if $game_temp.in_battle
    $game_map.setup_lightmap(name, color: color, opacity: opacity, blend: blend_mode, duration: fade_time)
    true
  end
  #--------------------------------------------------------------------------
  # * Finished dialogue
  # Enables the flag to indicate a character has nothing new to say
  #--------------------------------------------------------------------------
  def finished_dialogue(bool = true)
    event = $game_map.events[@event_id]
    return true if event.nil?
    return true if event.no_new_dialogue == bool
    event.no_new_dialogue = bool
    event.refresh
    # Continue
    true
  end
  #--------------------------------------------------------------------------
  # * Actor Join Flag
  # Sets game message text for a party member to join (localizes)
  #--------------------------------------------------------------------------
  def actor_join_text(id)
    str = Localization.localize('&MUI[PartyJoin]')
    str.sub!('!N', $game_actors[id].name)
    $game_temp.message_text = str
    @book_waiting = true
    $game_temp.message_proc = Proc.new { @book_waiting = false }
    true
  end
  #--------------------------------------------------------------------------
  # * Player Graphic Type Macro for Pixel Movement
  #   type = 4dir or 8dir
  #--------------------------------------------------------------------------
  def setup_player_graphic(type, event_id=0)
    obj = event_id != 0 ? $game_map.events[event_id] : $game_player
    case type
    when :dir8
      obj.frame_order = PixelMove::PLAYER_FRAME_ORDER
      obj.direction_order = PixelMove::PLAYER_DIRECTION_ORDER
      obj.stand_frame_order = PixelMove::PLAYER_IDLE_FRAME_ORDER
      obj.sprite_reset
      #PixelMove.turn_step_by_step = true
    when :dir4
      obj.frame_order = [1,2,3,4]
      obj.direction_order = [2,4,6,8]
      obj.stand_frame_order = [1,2,3,4]
      obj.sprite_reset
      #PixelMove.turn_step_by_step = false
    end
    true
  end
  #--------------------------------------------------------------------------
  # * Load a book
  #--------------------------------------------------------------------------
  def show_book(book_name)
    # Set shop calling flag
    $game_temp.book_calling = true
    # Set goods list on new item
    $game_temp.book_name = book_name
    true
  end
end # Class