#==============================================================================
#  RPG Data Module Extensions
# --------------------------------------
# This includes extensions / modifications to the RPG Module, 
# specifically data structure objects.
#==============================================================================
module RPG
  # REDACTED
  #------------------------------------------------------------------------------
  # * RPG::Enemy
  #------------------------------------------------------------------------------
  class Enemy
    attr_accessor :name_loc_key
    attr_accessor :description_loc_key
    attr_accessor :base_speed
    attr_accessor :atb_roll_range
    attr_accessor :drops

    alias initialize_extension initialize
    def initialize
      initialize_extension
      @name_loc_key = ""
      @description_loc_key = ""
      @base_speed = 55
      @atb_roll_range = 3
      @drops = []
    end
    #------------------------------------------------------------------------------
    # * RPG::Enemy::Action
    #------------------------------------------------------------------------------
    class Action
      attr_accessor :item_id
      attr_accessor :weapon_id
      attr_accessor :behavior
      attr_accessor :condition_custom
      attr_accessor :custom_params
      
      alias initialize_extension initialize
      def initialize
        initialize_extension
        @item_id = 0
        @weapon_id = 0
        @behavior = :default
        @condition_custom = nil
        @custom_params = []
      end
    end
    #------------------------------------------------------------------------------
    # * RPG::Enemy::ItemDrop
    #------------------------------------------------------------------------------
    class ItemDrop
      attr_accessor :type
      attr_accessor :type_id
      attr_accessor :quantity
      attr_accessor :rate

      def initialize
        @type = :item
        @type_id = 0
        @quantity = 1
        @rate = 1000
      end
    end
  end
  # REDACTED
end