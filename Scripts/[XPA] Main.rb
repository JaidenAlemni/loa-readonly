#==============================================================================
# ** Main
#------------------------------------------------------------------------------
#  After defining each class, actual processing begins here.
#==============================================================================
# Modifies the error message raised to show the full traceback path.
def traceback_report
  backtrace = $!.backtrace.clone
  backtrace.each{ |bt|
    bt.sub!(/{(\d+)}/) {"[#{$1}]#{$RGSS_SCRIPTS[$1.to_i][1]}"}
  }
  return $!.message.clone + "\n\n" + backtrace.join("\n")
end

def raise_traceback_error
  # Vomit some stuff into the GLOG
  $GLOG&.dump_state if [1,2].include?(CFG["astravia"]["gameSessionLog"])
  $GLOG&.close if [1,2].include?(CFG["astravia"]["gameSessionLog"])
  str = traceback_report
  if $DEBUG
    if $!.message.size >= 900
      File.open('traceback.log', 'w') { |f| f.write(str) }
      raise 'Traceback is too big. Output in traceback.log'
    else
      raise str
    end
  else
    msgbox_p Localization.localize("&MUI[GameCriticalError]")
    System.launch(GameSetup.user_directory) unless System.is_linux? # Supress on Steam Deck (and thus all linux) for now
    GUtil.write_log(str)
    GUtil.open_bug_report(str)
    raise
  end
end

alias puts_mod puts
def puts(*args)
  callstr = caller[0].gsub(':','|').sub('in ','').sub('\'',"").sub('`','')
  #callstr = '%-40.40s' % callstr
  args[0] = "#{callstr} : #{args[0]}\n"
  puts_mod(args)
end

begin
  # Generate pixel movement tables and exit.
  # GUtil.create_pm_tables
  # Enable to flag the game as beta 
  $BETA = true
  # Enable to flag game as demo
  $DEMO = true
  # Only permit debug mode in a beta state
  $DEBUG = $BETA ? $TEST : false
  # Create game version data
  GameSetup.generate_build_version
  # Initial game setup
  GameSetup.startup
  # Resizes the internal game screen
  Graphics.resize_screen(LOA::SCRES[0], LOA::SCRES[1])
  # Set font defaults
  Font.setup_defaults
  # Check configuration
  GameSetup.check_global_config
  Graphics.fullscreen = $game_options.fullscreen
  Graphics.show_cursor = false
  # Start logging
  $GLOG = GameLogger.new
  # Prepare for transition
  Graphics.freeze
  # Call title screen
  if ARGV.include?("animtest") && $DEBUG
    $scene = Scene_BattleDebug.new
  else
    $scene = Scene_Title.new
  end
  #$scene = Scene_Test.new
  # Call main method as long as $scene is effective
  $scene.main while $scene != nil
  # Close log gracefully
  $GLOG.write_line("Player quit normally.")
  $GLOG.close if CFG["astravia"]["gameSessionLog"]  == 2
  # Game exit
  Graphics.transition(30)
  # Wait for the transition before finalizing
  GUtil.wait(0.25)
rescue SyntaxError
  #$!.message.sub!($!.message, traceback_report)
  raise_traceback_error
rescue SystemExit, Interrupt
  # Close log gracefully
  $GLOG&.write_line("Player force quit.")
  $GLOG&.close if CFG["astravia"]["gameSessionLog"] == 2
rescue
  #$!.message.sub!($!.message, traceback_report)
  raise_traceback_error
end