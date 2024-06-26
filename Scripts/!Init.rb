#================================================================================
# Libraries
# In the distributed version of the game, any calls here would need to be
# moved to main in the non-compressed scripts.
#================================================================================
$:.push(File.join(Dir.pwd, "Ruby/3.1.0")) unless System.is_mac?
# Localization
require 'csv'
require_relative "Ruby/mojinizer"