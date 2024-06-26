#==============================================================================
# ** Game_Temp
#------------------------------------------------------------------------------
#  This class handles temporary data that is not included with save data.
#  Refer to "$game_temp" for the instance of this class.
#==============================================================================

class Game_Temp
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :map_bgm                  # map music (for battle memory)
  attr_accessor :message_text             # message text
  attr_accessor :message_proc             # message callback (Proc)
  attr_accessor :choice_start             # show choices: opening line
  attr_accessor :choice_max               # show choices: number of items
  attr_accessor :choice_cancel_type       # show choices: cancel
  attr_accessor :choice_proc              # show choices: callback (Proc)
  attr_accessor :num_input_start          # input number: opening line
  attr_accessor :num_input_variable_id    # input number: variable ID
  attr_accessor :num_input_digits_max     # input number: digit amount
  attr_accessor :message_window_showing   # message window showing
  attr_accessor :common_event_id          # common event ID
  attr_accessor :in_battle                # in-battle flag
  attr_accessor :battle_calling           # battle calling flag
  attr_accessor :battle_troop_id          # battle troop ID
  attr_accessor :battle_can_escape        # battle flag: escape possible
  attr_accessor :battle_can_lose          # battle flag: losing possible
  attr_accessor :battle_proc              # battle callback (Proc)
  attr_accessor :battle_turn              # number of battle turns (now explicitly for incrementing interpreter)
  attr_accessor :battle_actions           # number of total actions that have occurred
  attr_accessor :battle_event_flags       # battle event flags: completed
  attr_accessor :battle_abort             # battle flag: interrupt
  attr_accessor :battle_main_phase        # battle flag: main phase
  attr_accessor :battleback_name          # battleback file name
  attr_accessor :battleback_tone          # tone applied to battleback
  attr_accessor :forcing_battler          # battler being forced into action
  attr_accessor :shop_calling             # shop calling flag
  attr_accessor :shop_id                  # id of shop to call
  attr_accessor :book_calling
  attr_accessor :book_name
  attr_accessor :name_calling             # name input: calling flag
  attr_accessor :name_actor_id            # name input: actor ID
  attr_accessor :name_max_char            # name input: max character count
  attr_accessor :menu_calling             # menu calling flag
  attr_accessor :menu_beep                # menu: play sound effect flag
  attr_accessor :save_calling             # save calling flag
  attr_accessor :debug_calling            # debug calling flag
  attr_accessor :player_transferring      # player place movement flag
  attr_accessor :player_new_map_id        # player destination: map ID
  attr_accessor :player_new_x             # player destination: x-coordinate
  attr_accessor :player_new_y             # player destination: y-coordinate
  attr_accessor :player_new_direction     # player destination: direction
  attr_accessor :transition_processing    # transition processing flag
  attr_accessor :transition_name          # transition file name
  attr_accessor :gameover                 # game over flag
  attr_accessor :to_title                 # return to title screen flag
  attr_accessor :last_file_index          # last save file no.
  attr_accessor :debug_top_row            # debug screen: for saving conditions
  attr_accessor :debug_index              # debug screen: for saving conditions
  #--------------------------------------------------------------------------
  # Battle
  attr_accessor :battle_end               # battle flag: battle is ending
  #attr_accessor :battle_victory           # battle flag: battle was won
  attr_accessor :battle_ambushed          # battle flag: enemy advantage
  attr_accessor :battle_preemptive        # battle flag: party advantage
  attr_accessor :battle_tutorial
  # Screen
  attr_accessor :shake_maxdur             # screen max duration
  attr_accessor :shake_power              # screen shake power
  attr_writer   :shake_dur                # screen current duration
  # Messages
  attr_accessor :message_face # Display face in a message window
  # Heretic notes the flags below are "a bad way to do things" 
  # may want to reevaluate. It deals with loss of data when 
  # showing a number input with multiple windows displayed
  attr_accessor :num_input_variable_id_backup  # prevents variable loss
  attr_accessor :input_in_window               # prevents window closures
  attr_accessor :choices_text                  # array of text choices
  # Journal
  attr_accessor :bestiary_updated # Flag for journal update
  attr_accessor :quest_updated    # Flags quest menu for notification
  attr_accessor :push_timer       # Push block timer 
  attr_accessor :pushing_block    # Flag for push block
  # Title
  attr_accessor :title_screen
  attr_accessor :display_title_menu
  attr_accessor :hide_title_menu
  attr_accessor :return_to_gameover
  # Map
  attr_accessor :escaping_enemies         # indicates escape on map
  attr_accessor :easy_chest_items         # items within an easy chest
  attr_accessor :display_map_name         # Flag to display the map name graphic on the screen
  attr_accessor :continue_map_bgm_battle  # Flag to continue playing the bgm in battle (also applies to bgs)
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @map_bgm = nil
    @message_text = nil
    @message_proc = nil
    @choice_start = 99
    @choice_max = 0
    @choices_text = nil
    @choice_cancel_type = 0
    @choice_proc = nil
    @num_input_start = 99
    @num_input_variable_id = 0
    @num_input_digits_max = 0
    @message_window_showing = false
    @common_event_id = 0
    @in_battle = false
    @battle_calling = false
    @battle_troop_id = 0
    @battle_can_escape = false
    @battle_can_lose = false
    @battle_ambushed = false
    @battle_preemptive = false
    @battle_proc = nil
    @battle_turn = 0
    @battle_actions = 0
    @battle_event_flags = {}
    @battle_abort = false
    @battle_main_phase = false
    @battleback_name = ''
    @battleback_tone = Tone.new()
    @forcing_battler = nil
    @shop_calling = false
    @shop_id = 0
    @book_calling = false
    @book_name = nil
    @name_calling = false
    @name_actor_id = 0
    @name_max_char = 0
    @menu_calling = false
    @menu_beep = false
    @save_calling = false
    @debug_calling = false
    @player_transferring = false
    @player_new_map_id = 0
    @player_new_x = 0
    @player_new_y = 0
    @player_new_direction = 0
    @transition_processing = false
    @transition_name = ""
    @gameover = false
    @to_title = false
    @last_file_index = 0
    @debug_top_row = 0
    @debug_index = 0
    @battle_end = false
    #@battle_victory = false
    @escaping_enemies = false
    @battle_tutorial = false
    @easy_chest_items = []
    # See note in PIVs above
    @message_face = false
    @num_input_variable_id_backup = 0
    @input_in_window = false
    # Journal
    @bestiary_updated = false
    @quest_updated = false
    # Reset push block timer
    @push_timer = 0
    @pushing_block = nil
    # Title
    @title_screen = false
    @hide_title_menu = false
    @display_title_menu = false
    # Map
    @display_map_name = false
    @continue_map_bgm_battle = false
    @return_to_gameover = false
  end
  #--------------------------------------------------------------------------
  # * Screen Shake Duration (TheoAllen)
  # Defined this way because it is defined before Game Temp is initialized. 
  #--------------------------------------------------------------------------
  def shake_dur
    @shake_dur ||= 0
  end
end
