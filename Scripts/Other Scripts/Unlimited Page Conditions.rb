#==============================================================================
# * Unlimited Page Conditions
#
# Created by Jaiden Alemni
# For exclusive use in Legends of Astravia Only
# 
# Loosely Based on Heretic's Unlimited Event Page Conditions 
# https://forum.chaos-project.com/index.php/topic,15478.0.html
#
# History:
# August 21, 2022 
#  - Initial Creation
#
# Notes:
# Permits checking an additional attribute on an event page, by making the first
# comment of the events "Condition: [whatever]"
# The condition must return a boolean value, and the condition will only 
# evaluate on a refresh (as vanilla page conditions do)
# 
# This means selectively calling $game_map.needs_refresh may be required
# for checking certain conditions (such as player map height)
#==============================================================================
class Game_Event < Game_Character
  CONDITION_REGEX = /^CONDITION:(.*)/i
  #-----------------------------------------------------------------------------
  # * Determine Script Condition Evaluation
  #-----------------------------------------------------------------------------
  def script_condition_valid?(page)
    # Must be a comment and it must be the first command
    # Revised syntax credit: KK20
    return false if page&.list&.at(0)&.code != 108
    !!(page.list[0].parameters[0] =~ CONDITION_REGEX)
  end
  #-----------------------------------------------------------------------------
  # * Evaluate Script Condition
  # Note: We've already used the above method to ensure the page,
  # its list, and the script are valid and not nil.
  #-----------------------------------------------------------------------------
  def check_script_condition(page)
    puts "Checking script conditions"
    script = nil
    page.list[0].parameters[0].scan(CONDITION_REGEX){ script = $1.strip }
    p script
    # Loop through the rest of this comment
    i = 1
    while page.list[i] != nil && page.list[i].code == 408
      script << "\n" + page.list[i].parameters[0]
      i += 1
    end
    # Evaluate the condition and return the result
    result = eval(script)
    if result.is_a?(TrueClass) || result.is_a?(FalseClass)
      return result
    else
      puts "Invalid condition script!!! #{script} (Returned: #{result})"
      return false  
    end
  end
end