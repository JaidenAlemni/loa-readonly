#==============================================================================
# ** Essence Controller
#------------------------------------------------------------------------------
#  Configuration and helper functions
#==============================================================================
module Essence
  # For State Applying Essences
  EFFECTIVENESS_TABLE = [0,30,60,90]
  # For Fork Damage Reduction (0 index unused)
  FORK_DAMAGE = [100,50,65,85]

  def self.state_hit?(level)
    rand(100) < EFFECTIVENESS_TABLE[level]
  end

  def self.fork_damage(damage, level)
    damage * FORK_DAMAGE[level] / 100
  end

  def self.channel_amount(damage, level)
    [-(damage * (level * 15) / 100), -10].min
  end
end