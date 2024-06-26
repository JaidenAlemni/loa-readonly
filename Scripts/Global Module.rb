#==============================================================================
# GLOBAL CONSTANTS
# These constants and methods are not tied to any one class, used generally
# for IDs or variables across various classes
#--------------------------------------------------------------------------
module LOA
  SQRT_2 = Math.sqrt(2)
  # Switch to disable certain functions in game due to cutscenes
  CUTSCENE_SW = 19
  # Internal game resolution (default screen size)
  # Most game screen elements are calculated with these values
  # Name is shortened for readability in related formulas
  SCRES = [1280, 720]
end
