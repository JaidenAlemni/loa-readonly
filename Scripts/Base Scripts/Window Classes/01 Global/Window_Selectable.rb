#==============================================================================
# ** Window_Selectable
#------------------------------------------------------------------------------
#  This window class contains cursor movement and scroll functions.
#==============================================================================

class Window_Selectable < Window_Base
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :index                    # cursor position
  attr_reader   :help_window              # help window
  attr_accessor :cursor_start_x           # Determine where the cursor starts
  attr_accessor :cursor_start_y
  attr_accessor :cursor_fix               # fix cursor flag
  attr_accessor :cursor_all               # select all cursors flag
  attr_accessor :spacing
  attr_accessor :item_max
  attr_accessor :column_max
  attr_accessor :line_height              # height of window item
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     x      : window x-coordinate
  #     y      : window y-coordinate
  #     width  : window width
  #     height : window height
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    @item_max = 1
    @column_max = 1
    super(x, y, width, height)
    @index = -1
    # Initialize cursor offset values
    @cursor_start_x = 0
    @cursor_start_y = 0
    @new_index = 0
    @spacing = 32
  end
  #--------------------------------------------------------------------------
  # * Set Cursor Position
  #     index : new cursor position
  #--------------------------------------------------------------------------
  def index=(index)
    @index = index
    # Update Help Text (update_help is defined by the subclasses)
    if self.active and @help_window != nil
      update_help
    end
    # Update cursor rectangle
    update_cursor_rect
  end
  #--------------------------------------------------------------------------
  # * Select Item
  #--------------------------------------------------------------------------
  def select(index)
    self.index = index if index
  end
  #--------------------------------------------------------------------------
  # * Determine if active
  #--------------------------------------------------------------------------
  def active?
    return self.active
  end
  #--------------------------------------------------------------------------
  # * Determine if index changed
  #--------------------------------------------------------------------------
  def cursor_moved?
    if @new_index != @index
      @new_index = @index
      return true
    else
      return false
    end
  end
  #--------------------------------------------------------------------------
  # * Get Item Width
  #--------------------------------------------------------------------------
  def item_width
    (width - self.padding * 2 + @spacing) / @column_max - @spacing
  end
  #--------------------------------------------------------------------------
  # * Get Item Height
  #--------------------------------------------------------------------------
  def item_height
    @line_height
  end
  #--------------------------------------------------------------------------
  # * Get Column Count
  #--------------------------------------------------------------------------
  def col_max
    @column_max
  end
  #--------------------------------------------------------------------------
  # * Get Item
  #--------------------------------------------------------------------------
  def item_max
    @item_max
  end
  #--------------------------------------------------------------------------
  # * Get Row Count
  #--------------------------------------------------------------------------
  def row_max
    # Compute rows from number of items and columns
    [(item_max + col_max - 1) / col_max, 1].max
  end
  #--------------------------------------------------------------------------
  # * Calculate Height of Window Contents
  #--------------------------------------------------------------------------
  def contents_height
    init_height = super
    # Unsure as to why the bottom is being trimmed so much here
    #[init_height - init_height % item_height, row_max * item_height].max
    [init_height, row_max * item_height].max
  end
  #--------------------------------------------------------------------------
  # * Update Bottom Padding
  #--------------------------------------------------------------------------
  def update_padding_bottom
    surplus = (height - self.padding * 2) % item_height
    self.padding_bottom = padding + surplus
  end
  #--------------------------------------------------------------------------
  # * Get Current Line
  #--------------------------------------------------------------------------
  def row
    index / @column_max
  end
  #--------------------------------------------------------------------------
  # * Get Top Row
  #--------------------------------------------------------------------------
  def top_row
    # Divide y-coordinate of window contents transfer origin by 1 row
    # height of 32
    return self.oy / @line_height
  end
  #--------------------------------------------------------------------------
  # * Set Top Row
  #     row : row shown on top
  #--------------------------------------------------------------------------
  def top_row=(row)
    # If row is less than 0, change it to 0
    if row < 0
      row = 0
    end
    # If row exceeds row_max - 1, change it to row_max - 1
    if row > row_max - 1
      row = row_max - 1
    end
    # Multiply 1 row height by 32 for y-coordinate of window contents
    # transfer origin
    self.oy = row * @line_height
  end
  #--------------------------------------------------------------------------
  # * Get Number of Rows Displayable on 1 Page
  #--------------------------------------------------------------------------
  def page_row_max
    # Subtract a frame height of 32 from the window height, and divide it by
    # 1 row height of 32
    (height - padding - padding_bottom) / item_height
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items Displayable on 1 Page
  #--------------------------------------------------------------------------
  def page_item_max
    # Multiply row count (page_row_max) times column count (@column_max)
    return page_row_max * @column_max
  end
  #--------------------------------------------------------------------------
  # * Determine Horizontal Selection
  #--------------------------------------------------------------------------
  def horizontal?
    page_row_max == 1
  end
  #--------------------------------------------------------------------------
  # * Get Bottom Row
  #--------------------------------------------------------------------------
  def bottom_row
    top_row + page_row_max - 1
  end
  #--------------------------------------------------------------------------
  # * Set Bottom Row
  #--------------------------------------------------------------------------
  def bottom_row=(row)
    self.top_row = row - (page_row_max - 1)
  end
  #--------------------------------------------------------------------------
  # * Set Help Window
  #     help_window : new help window
  #--------------------------------------------------------------------------
  def help_window=(help_window)
    @help_window = help_window
    # Update help text (update_help is defined by the subclasses)
    if self.active and @help_window != nil
      update_help
    end
  end
  #--------------------------------------------------------------------------
  # * Get Rectangle for Drawing Items
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new
    rect.width = item_width
    rect.height = item_height
    rect.x = @cursor_start_x + index % col_max * (item_width + spacing)
    rect.y = @cursor_start_y + index / col_max * item_height
    rect
  end
  #--------------------------------------------------------------------------
  # * Get Rectangle for Drawing Items (for Text)
  #--------------------------------------------------------------------------
  def item_rect_for_text(index)
    rect = item_rect(index)
    rect.x += 4
    rect.width -= 8
    rect
  end
  #--------------------------------------------------------------------------
  # * Determine if Cursor is Moveable
  #--------------------------------------------------------------------------
  def cursor_movable?
    active && open? && !@cursor_fix && !@cursor_all && item_max > 0
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Down
  #--------------------------------------------------------------------------
  def cursor_down(wrap = false)
    if index < item_max - col_max || (wrap && col_max == 1)
      select((index + col_max) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Up
  #--------------------------------------------------------------------------
  def cursor_up(wrap = false)
    if index >= col_max || (wrap && col_max == 1)
      select((index - col_max + item_max) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Right
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    if col_max >= 2 && (index < item_max - 1 || (wrap && horizontal?))
      select((index + 1) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Left
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    if col_max >= 2 && (index > 0 || (wrap && horizontal?))
      select((index - 1 + item_max) % item_max)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Cursor One Page Down
  #--------------------------------------------------------------------------
  def cursor_pagedown
    if top_row + page_row_max < row_max
      self.top_row += page_row_max
      select([@index + page_item_max, item_max - 1].min)
    end
  end
  #--------------------------------------------------------------------------
  # * Move Cursor One Page Up
  #--------------------------------------------------------------------------
  def cursor_pageup
    if top_row > 0
      self.top_row -= page_row_max
      select([@index - page_item_max, 0].max)
    end
  end
  #--------------------------------------------------------------------------
  # * Cursor Movement Processing
  #--------------------------------------------------------------------------
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    if Input.repeat?(:DOWN)
      cursor_down(Input.trigger?(:DOWN))
    elsif Input.repeat?(:UP)
      cursor_up(Input.trigger?(:UP))
    elsif Input.repeat?(:RIGHT)
      cursor_right(Input.trigger?(:RIGHT))
    elsif Input.repeat?(:LEFT)
      cursor_left(Input.trigger?(:LEFT))
    elsif Input.trigger?(:L)
      cursor_pageup
    elsif Input.trigger?(:R)
      cursor_pagedown
    end
    $game_system.se_play($data_system.cursor_se) if @index != last_index
  end
  #--------------------------------------------------------------------------
  # * Update Cursor
  #--------------------------------------------------------------------------
  def update_cursor
    if @cursor_all
      cursor_rect.set(0, 0, contents.width, row_max * item_height)
      self.top_row = 0
    elsif @index < 0
      cursor_rect.empty
    else
      ensure_cursor_visible
      cursor_rect.set(item_rect(@index))
    end
  end
  # Alias
  alias update_cursor_rect update_cursor
  #--------------------------------------------------------------------------
  # * Update Help 
  # Usually defined by the subclasses, a catch just for safety.
  #--------------------------------------------------------------------------
  def update_help
    
  end
  #--------------------------------------------------------------------------
  # * Scroll Cursor to Position Within Screen
  #--------------------------------------------------------------------------
  def ensure_cursor_visible
    self.top_row = row if row < top_row
    self.bottom_row = row if row > bottom_row
  end
  #--------------------------------------------------------------------------
  # * Change window active state
  #--------------------------------------------------------------------------  
  alias window_base_active_set active=
  def active=(value)
    window_base_active_set(value)
    # Bandaid for now
    return if self.is_a?(Window_Message)
    if !$scene.is_a?(Scene_Map) || !$scene.is_a?(Scene_Battle)
      # FIXME: This can be less ass 
      if value
        # Set windowskin to active cursor
        if self.window_blank
          self.windowskin = RPG::Cache.windowskin("Blank")
        else
          self.windowskin = RPG::Cache.windowskin("Default")
        end
      else
        # Set windowskin to inactive cursor
        if self.window_blank
          self.windowskin = RPG::Cache.windowskin("Blank_Inactive")
        else
          self.windowskin = RPG::Cache.windowskin("Default_Inactive")
        end
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    process_cursor_move
  end
end
