#============================================================================
# Clone Events
# Based on the VX ACE Script by Shaz
#----------------------------------------------------------------------------
# This script allows you to clone events from one map to another.
# Customization options allow you to have all clone (source) events on the
# same map, or to specify which map should be used each time, and to
# use either event names or ids to indicate which event should be cloned
#----------------------------------------------------------------------------
# To Install:
# Copy and paste into a new script slot in Materials.  This script aliases
# existing methods, so can go below all other custom scripts.
#----------------------------------------------------------------------------
# To Use:
#
# Set CLONE_MAP to the map that will contain the parent events. 
# Cloning from other maps is not permitted, and IDs must be used
#
# To clone an event, on the game map, create a new event, and change the name
# to the following:

#   [CLONE]:ID

# Note - the event created will NOT get the same event id as the source.  It 
# will keep the event id of the 'dummy' event that has the <clone ...> comment.
# This means you can have several events on the same map that are all clones
# of the same original event.
# It also means you can use multiple event pages and self switches on your
# original event, and the self switches will refer to the correct map and
# event id, so they don't get mixed up.
#----------------------------------------------------------------------------
# Terms:
# Use in free or commercial games
# Credit Shaz
#============================================================================
#==============================================================================
# ** EventCloner Module
#==============================================================================
module EventCloner
  # This is the map id that contains the source events to be cloned
  CLONE_MAP_ID = 99
  # Pattern to search in the event name
  NAME_PATTERN = /(\[clone\])\:(\d+)/i # "[clone]:id" (case insensitive)
  # Create the initial hash of parent events used to be cloned into 
  # other maps. This should be called whenever game data is loaded.
  def self.init_parent_events
    # Init clone hash
    $data_event_clones = {}
    # Load clone map
    clone_map = load_data(sprintf("Data/Map%03d.rxdata", CLONE_MAP_ID))
    # Save cloned events
    clone_map.events.values.each do |event|
      $data_event_clones[event.id] = event.dup
    end
  end
end
#==============================================================================
# ** Game_Event
#==============================================================================
class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     map_id : map ID
  #     event  : event (RPG::Event)
  #--------------------------------------------------------------------------
  alias clone_events_initialize initialize
  def initialize(map_id, event)
    clone_events_initialize(map_id, event)
    check_clone
  end
  #--------------------------------------------------------------------------
  # * Check for Cloned event
  #--------------------------------------------------------------------------
  def check_clone
    # If the event exists and the name is consistent with a clone pattern
    if @event && @event.name.scan(EventCloner::NAME_PATTERN) != []
      # Grab the ID (second capture) and ensure it is an integer
      cloned_id = $2.strip.to_i
      # Set the event's page data to a clone of the matching clone event
      @event.pages = Array.new($data_event_clones[cloned_id].pages.dup)
      # Clear the page and refresh the event
      @page = nil
      refresh
    end
  end
end