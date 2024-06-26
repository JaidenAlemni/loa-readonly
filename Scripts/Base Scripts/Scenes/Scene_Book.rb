class Scene_Book < Scene_Base
  #--------------------------------------------------------------------------
  # * Object initialization
  #--------------------------------------------------------------------------        
  def initialize(book_name)
    super
    @book_name = book_name
  end

  def pre_start
    @book_window = Window_BookContent.new
    @book_window.load_book(@book_name)
    @title_window = Window_BookTitle.new(@book_window.data[:title])
    super
  end

  def update
    super
    if Input.trigger?(Input::B)
      # Exit scene
      close_scene
    end
  end
end