#+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
# Localization
# Author: Jaiden Alemni
# 
# Version: 2.0 - 9/3/21
# - Initial Release
#
# Based on ForeverZer0 and KK20's localization script,
# Reads CSV files and saves the strings to an easily-accessible hash.
#
# [How to Use]
# Place the Ruby CSV library files in the root of your project, or redesignate
# the directory below.
# 
# Localization is split into two types of files, menu/ui and text.
# 
# Menu/UI is separate from text because it prevents the files from getting too
# large, but also prevents constantly reloading the files for performance.
#
# When setting a culture, use a symbol i.e. :en_us. In the CSV file, they do
# NOT need the colon.
#
# Your CSV file should look something like this:
#     "key"    | "en_us" | "jp"       | ...
# "KeyName001" | "Hello" | "こんにちは" |  ...
#
# [Example] 
# If I have "&MUI[KeyName001]" in a draw_text function or text box...
# If my culture is :en_us, it will look in the MUI.csv file for the row
# containing "KeyName001" in the key column, then return whatever is in 
# the en_us column. In this case: "Hello"
# 
# Be sure to tweak the constants for column separators, row separators, etc.
# to match the layout of your CSV file.
#
#+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
# LIB_DIRECTORY = 'Ruby/3.0.0' # Enter the directory in which the external
#                              # Ruby library files will be stored.
# require_relative "#{LIB_DIRECTORY}/csv" # Load Ruby's CSV feature
#                                         # Note that each file must be changed to
#                                         # use 'require_relative` if you will be
#                                         # including the files in your project folder.
#===============================================================================
# ** Localization
#-------------------------------------------------------------------------------
# Static module for reading localized strings from language files.
#===============================================================================
module Localization
  #-----------------------------------------------------------------------------
  # * Constants / Configuration
  #-----------------------------------------------------------------------------
  # Directory in which localization files are stored.
  DIRECTORY = 'Data/Localization'
  # The default culture to load on game start 
  #DEFAULT_CULTURE = :jp
  # List of files to load, which will be placed in the $game_text hash
  FILE_KEYS = [
    'MUI','A1S','A1E','QJ1'
  ]
  # Column separator for the CSV file (generally a comma, pipes are safer)
  COL_SEP = ','
  # Row separator. Generally a newline. Default is :auto. 
  # Changing this option hasn't been tested.
  ROW_SEP = :auto
  # Quote character. Default is double-quotes, set to nil to disable.
  # Changing this option hasn't been tested.
  QUOTE_CHAR = '"'
  # Comment character. If a csv line starts with this character, it will be ignored.
  COMMENT_CHAR = '#'
  # The Regexp text pattern used when Localizing a string.
  # Currently set to &CCC[KEY] where C is any letter or digit.
  # For example, setting a string to &P1A[Items001] will look in the P1A.csv file
  # for the key "Items001" in the column of whatever culture is currently active.
  TEXT_PATTERN = /&(\w{3})\[(.+)\]/
  #
  # END OF CONFIGURABLE VALUES
  #-----------------------------------------------------------------------------
  # * Initialize the localization module
  #-----------------------------------------------------------------------------
  def self.init
    # Global hash containing game text hashes
    $game_text = {}
    # Load files
    self.culture = $game_options.language
  end
  #-----------------------------------------------------------------------------
  # * Set up the language for the first time based on user's computer language
  #-----------------------------------------------------------------------------
  def self.initial_culture
    if System.user_language == 'ja_JP'
      return :jp
    else
      return :en_us
    end
  end
  #-----------------------------------------------------------------------------
  # * Get the culture
  #-----------------------------------------------------------------------------
  def self.culture
    @culture
  end
  #-----------------------------------------------------------------------------
  # * Setup the key/string hash
  #-----------------------------------------------------------------------------
  def self.setup_hash(filename)
    # Initilize the hash
    hash_obj = Hash.new
    # Create the temporary table object
    #temp_table = self.open_csv("#{DIRECTORY}/#{filename}.csv").by_col!
    # For each localization key, fetch the appropriate string
    # based on the culture
    culture_s = @culture.to_s
    CSV.foreach("#{DIRECTORY}/#{filename}.lang", col_sep: COL_SEP, row_sep: ROW_SEP,
      quote_char: QUOTE_CHAR, skip_lines: COMMENT_CHAR, headers: true) {|row|
      key = row.field('key')
      next if key.nil?
      hash_obj[key.to_sym] = row.field(culture_s)
    }
    # temp_table[:key].each_with_index do |key, row|
    #   next if key.nil?
    #   hash_obj[key.to_sym] = temp_table[@culture][row]
    # end
    hash_obj
  end
  #-----------------------------------------------------------------------------
  # * Load a new text file and place it in the hash
  #-----------------------------------------------------------------------------
  def self.load_file(key)
    $game_text[key] = self.setup_hash(key)
  end
  #-----------------------------------------------------------------------------
  # * Set the current culture
  #-----------------------------------------------------------------------------
  def self.culture=(value)
    # Set the culture and write to config file
    @culture = value
    # Reload the files
    FILE_KEYS.each{|key| self.load_file(key) }
    # We must reset the default font
    Font.setup_defaults
  end
  #-----------------------------------------------------------------------------
  # * Read the string with the given ID of the current culture
  #-----------------------------------------------------------------------------
  def self.read(filekey, id)
    text = $game_text.dig(filekey, id.to_sym)
    # Sub for empty string if one doesnt exist
    text = (text.nil? ? '' : text)
    if text == '' && $DEBUG
      GUtil.write_log("No string defined! File: #{filekey} Key: \"#{id}\" Culture: \"#{@culture}\"")
      # str = ""
      # PP.pp($game_text, str)
      # GUtil.write_log(str)
    end
    return text
  end
  #-----------------------------------------------------------------------------
  # * Parses a string for localization codes and returns it
  #-----------------------------------------------------------------------------
  def self.localize(string)
    if string != nil
      return string.gsub(TEXT_PATTERN) { self.read($1, $2) }
    end
  end
end
#===============================================================================
# ** Game_Temp
#===============================================================================
class Game_Temp
  #-----------------------------------------------------------------------------
  # * Overrides the setter for message text to localize the "Show Text" command
  # If you use MMW, you will need to find the patch for this.
  #-----------------------------------------------------------------------------
  def message_text=(string)
    @message_text = Localization.localize(string)
  end
end
#===============================================================================
# ** Bitmap
#===============================================================================
class Bitmap
  #-----------------------------------------------------------------------------
  # * Replaces text based on the current culture
  #-----------------------------------------------------------------------------
  alias localized_draw_text draw_text
  def draw_text(*args)
    args.each_index do |i| 
      args[i] = Localization.localize(args[i]) if args[i].is_a?(String) 
    end
    localized_draw_text(*args)
  end
end
# Initialize the module to set the default culture.
# Note that this will also initially load a default menu/ui and text file.
#Localization.init