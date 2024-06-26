#=======================
# * Dependencies / Mods
#=======================
# GAME CLASSES:
# ----------------
# > Game_System
# > Game_Temp
#=======================
# WINDOW CLASSES:
# ----------------
# > Window_Notification
#=======================
# SPRITE CLASSES: 
# -------------
# > 
#=======================
# OTHER NOTES:
# ----------------
# > Utilized by Quests and Bestiary
# > Called on Scene_Map
#

#==============================================================================
# Journal Menu
# by Jaiden
# ---
# Referenced scripts by ForeverZer0 and KK20
#==============================================================================
# Displays a menu for selecting various guide items
# v1.0 - March 13th, 2018
#  * Initial version
# v2.0 - October 18th, 2018
#  * Adds notification system
#==============================================================================

#==============================================================================
# ** Map notification system module
#------------------------------------------------------------------------------
#  Flags menus for update
#  Called in an event by using Notification.update(menu) or Notifiaction.clear(menu)
#  Menus are assigned IDs:
#  * Quest - 1
#  * Bestiary - 2
#==============================================================================
module Notification
  #--------------------------------------------------------------------------
  # * Configuration
  #--------------------------------------------------------------------------
  # Icon that will display next to menu items that are updated
  NOTIF_ICON = "notif"
  # Number of frames to wait for window to move back up
  WAIT_TIME = 180
  #--------------------------------------------------------------------------
  # * Flag menu items for notification update
  #--------------------------------------------------------------------------
  def self.update(menu)
    case menu
    # Set flags
    when 1
      $game_temp.quest_updated = true
      self.call_window
    when 2
      $game_temp.bestiary_updated = true
      self.call_window
    end
  end
  #--------------------------------------------------------------------------
  # * Clear all notifications
  #--------------------------------------------------------------------------
  def self.clear
    $game_temp.quest_updated = false
    $game_temp.bestiary_updated = false
  end 
  #--------------------------------------------------------------------------
  # * Call the notification Window
  #--------------------------------------------------------------------------
  def self.call_window(custom_text = nil)
    # Only display on the map
    return unless $scene.is_a?(Scene_Map)
    $scene.notif_window = Window_Notification.new(custom_text)
  end
end



# #==============================================================================
# # ** Scene_Map
# #------------------------------------------------------------------------------
# #  Map screen processing
# #==============================================================================
# class Scene_Map
#   #--------------------------------------------------------------------------
#   # * Main (not sure this belongs here really)
#   #--------------------------------------------------------------------------
#   alias jaiden_journal_notif_main main
#   def main
#     # If bestiary calls for an update (post battle)
#     if $game_temp.bestiary_updated
#       # Call the notification window (bestiary)
#       Notification.update(2)
#     end
#     # Initialize wait time (for window display timer)
#     @notif_wait_time = Notification::WAIT_TIME
#     # Call original
#     jaiden_journal_notif_main 
#   end

#   # View Scene_Map for update methods
# end
#==============================================================================
# ** Window_Journal
#------------------------------------------------------------------------------
#  Journal command menu
#==============================================================================
=begin
class Window_Journal < Window_Command
  def refresh
    super
    bitmap = RPG::Cache.icon(Notification::NOTIF_ICON)
    # Quest
    # This will need to be handled differently if we want these icons to 
    # remain after the player saves and quits
    if $game_temp.quest_updated
      # Draw icon
      self.contents.blt(x + 130, y + 4, bitmap, Rect.new(0,0,24,24), 255)
    end
    # Bestiary
    if $game_temp.bestiary_updated
      # Draw icon
      self.contents.blt(x + 130, y + 36, bitmap, Rect.new(0,0,24,24), 255)
    end
  end
end
=end





