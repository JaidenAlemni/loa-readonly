#==============================================================================
# ■ Battle Animation Data Module
#------------------------------------------------------------------------------
# Loading and handling of battle animation sequence data
# Sequence|Action system derived from Tankantai SBS by Enu
# Rewritten and refactored by Jaiden Alemni for Legends of Astravia
#==============================================================================
module BattleAnime
  #==============================================================================
  # ■ Action Sequences
  #------------------------------------------------------------------------------
  # The Sequence class is just a glorified array for battle sequences
  # This can be expanded in the future
  #==============================================================================
  class Sequence
    attr_accessor :key
    attr_accessor :actions

    def initialize(key, actions = [])
      @key = key
      @actions = actions
    end

    def to_s
      "BattleAnime::Sequence #{@key} - #{@actions}"
    end
  end
  #==============================================================================
  # ■ Single Action Engine
  #------------------------------------------------------------------------------
  # These are utilized by sequenced actions and have no utility alone.
  #==============================================================================
  class SingleAction
    #--------------------------------------------------------------------------
    # Base class, defines key and calling method for each type of single action
    #--------------------------------------------------------------------------
    class SingleActionBase
      attr_accessor :key
      attr_reader :sprite_method

      def initialize(key, sprite_method = nil)
        @key = key
        if sprite_method
          @sprite_method = sprite_method
        else
          @sprite_method = self.class.to_s.split('::').last.underscore.to_sym
        end
      end
    end
    #--------------------------------------------------------------------------
    # ● Base Animation
    # These actions serve as the base animation for most actions, referencing
    # a battlers graphic and display information
    #--------------------------------------------------------------------------
    # suffix - The file suffix used for the loaded gif (i.e. Oliver_Idle, Oliver_Attack1, etc.)
    # speed - The speed (FPS) at which the animation plays. Supports floats. Default is 10
    # loop_type - Whether or not the animation should repeatly loop or just play once
    #        Supports 4 values: :repeat, :play_from, :play_to, :static
    #        :repeat    - The action will repeatly loop from start to finish. 
    #                     Specified frame has no effect
    #        :play_once - The action will loop one time
    #        :static    - The action will stay frozen on the specified frame
    #         
    # loop_hold_frame- Based on the loop value set prior, this is the frame used.
    #                   If "Loop" is set to :repeat, this value has no effect.
    # loop_delay  - Delay, in frames, before the animation loops again. Will not apply
    #          if the "Loop" attribute is not :repeat
    # z_add    - Battler's Z-order priority. Default is 0. 
    # shadow - Set true to display battler shadow during animation; false to hide.
    #--------------------------------------------------------------------------
    class BaseAnimation < SingleActionBase
      attr_accessor :suffix
      attr_accessor :speed
      attr_accessor :loop_type
      attr_accessor :loop_hold_frame
      attr_accessor :loop_delay
      attr_accessor :z_add
      attr_accessor :shadow

      def initialize(key)
        super(key)
        @suffix = ''
        @speed = 0
        @loop_type = :play_once
        @loop_hold_frame = 0
        @loop_delay = 0
        @z_add = 0
        @shadow = true
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Movement
    #--------------------------------------------------------------------------
    # Defines a battlers position and movement on the battlefield
    # origin - Defines the origin of movement based on an (x,y) coordinate plane.
    #          1 unit = 1 pixel
    #             [0: Battler's Current Position] 
    #             [1: Battler's Selected Target] 
    #             [2: Screen; (0,0) is at upper-left of screen] 
    #             [3: Battle Start Position]
    # x - X-axis pixels from origin.
    # y - Y-axis pixels from origin.  Please note that the Y-axis is 
    #     inverted. This means negative values move up, positive values move down.
    # time - Travel time.  Larger numbers are slower.  The distance is 
    #        divided by one frame of movement.
    # accel - Positive values accelerates frames.  Negative values decelerates.
    # jump - Negative values produce a jumping arc.  Positive values produce
    #        a reverse arc.  [0: No jump] 
    # base_anim_key - Battler Animation utilized during movement.
    #--------------------------------------------------------------------------
    class Movement < SingleActionBase
      attr_accessor :origin
      attr_accessor :x
      attr_accessor :y
      attr_accessor :time
      attr_accessor :accel
      attr_accessor :jump
      attr_accessor :base_anim_key

      def initialize(key)
        super(key)
        @origin = 0
        @x = 0
        @y = 0
        @time = 1
        @accel = 0
        @jump = 0
        @base_anim_key = ''
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Float Animations
    #--------------------------------------------------------------------------
    # These types of single-actions defines the movement of battlers from their
    # own shadows.  Please note that it is not possible to move horizontally
    # while floating from a shadow.
    #
    # start_height - Negative values move up. Positive values move down.
    # ebd_height - This height is maintained until another action.
    # time - Duration of movement from point A to point B
    # base_anim_key - Specifies the Battler Animation to be used.
    #--------------------------------------------------------------------------
    class Hover < SingleActionBase
      attr_accessor :start_height
      attr_accessor :end_height
      attr_accessor :duration
      attr_accessor :base_anim_key

      def initialize(key)
        super(key)
        @start_height = 0
        @end_height = 0
        @duration = 1
        @base_anim_key = ''
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Position Reset
    #-------------------------------------------------------------------------- 
    # These types of single-actions define when a battler's turn is over and
    # will reset the battler back to its starting coordinates.  This type of
    # single-action is required in all sequences.  
    # 
    # Please note that after a sequence has used this type of single-action, 
    # no more damage can be done by the battler since its turn is over.
    #
    # time - Time it takes to return to starting coordinates.  Movement speed
    #        fluctuates depending on distance from start coordinates.
    # accel - Positive values accelerate.  Negative values decelerate.
    # jump - Negative values produce a jumping arc.  Positive values produce
    #        a reverse arc.  [0: No jump] 
    # base_anim_key - Specifies the Battler Animation to be used.
    #--------------------------------------------------------------------------
    class PositionReset < SingleActionBase
      attr_accessor :time
      attr_accessor :accel
      attr_accessor :jump
      attr_accessor :base_anim_key

      def initialize(key)
        super(key)
        @time = 1
        @accel = 0
        @jump = 0
        @base_anim_key = ''
      end
    end
    #--------------------------------------------------------------------------
    # ● Forced Battler Actions
    #--------------------------------------------------------------------------
    # These types of single-actions allow forced control of other battlers
    # that you define.
    #
    # type - Specifies action type, :single or :sequence
    #
    # object_id -    The battler that will execute the action defined under Action 
    #          Name. 0 is for selected target, and any other number is a State 
    #          number (1~999), and affects all battlers with the State on them.  
    #             By adding a - (minus sign) followed by a Skill ID number (1~999),
    #          it will define the actors that know the specified skill, besides 
    #          the original actor.
    #             If you want to designate an actor by their index ID number, 
    #          add 1000 to their index ID number. If the system cannot designate 
    #          the index number(such as if actor is dead or ran away), it will 
    #          select the nearest one starting from 0.  If a response fails, 
    #          the action will be canceled. (Example: Ylva's actor ID is 4.  A
    #          value of 1004 would define Ylva as the Object.)
    #
    # pos_reset_key- Specifies action that returns the battler to its original
    #                 location.
    # action_key - Specifies action used.  If Type is :single, the Action Name
    #               must be a single-action function.  If Type is  :sequence,
    #               the Action Name must an action sequence name.
    #--------------------------------------------------------------------------
    class Forced < SingleActionBase
      attr_accessor :type
      attr_accessor :object_id
      attr_accessor :pos_reset_key
      attr_accessor :action_key

      def initialize(key)
        super(key)
        @type = :single
        @object_id = 0
        @pos_reset_key = ''
        @action_key = ''
      end
    end
    #--------------------------------------------------------------------------
    # ● Target Modification
    #--------------------------------------------------------------------------
    # Changes battler's target in battle.  Original target will still be stored.  
    # Current battler is the only battler capable of causing damage.
    #
    # object_id - The battler that will have its target modified.  0 is selected 
    #          target, any other number is a State ID number (1~999), and 
    #          changes all battlers with that state on them to target the new 
    #          designated target.
    #             If you want to designate an actor by their index ID number, 
    #          add 1000 to their index ID number. If the system cannot designate 
    #          the index number(such as if actor is dead or ran away), it will 
    #          select the nearest one starting from 0.  If a response fails, 
    #          the action will be canceled. (Example: Ylva's actor ID is 4.  A
    #          value of 1004 would define Ylva as the Object.)
    #
    # new_target_id - [0=Self]  [1=Self's Target]
    #                 [2=Self's Target After Modification]
    #                 [3=Reset to Previous Target (if 2 was used)]
    #--------------------------------------------------------------------------
    class TargetChange < SingleActionBase
      attr_accessor :object_id
      attr_accessor :new_target_id

      def initialize(key)
        super(key)
        @object_id = 0
        @new_target_id = 0
      end
    end
    #--------------------------------------------------------------------------
    # ● Skill Linking
    #--------------------------------------------------------------------------
    # Linking to the next skill will stop any current action.  Linking to the 
    # next skill will also require and consume MP/HP cost of that skill.
    #
    # chance - Chance, in percent, to link to the defined skill ID. (0~100)
    # require_learn - true: actor does not require Skill ID learned to link.
    #                 false: actor requires Skill ID learned.
    # skill_id - ID of the skill that will be linked to.
    #--------------------------------------------------------------------------
    class LinkSkill < SingleActionBase
      attr_accessor :chance
      attr_accessor :require_learn
      attr_accessor :skill_id

      def initialize(key)
        super(key)
        @chance = 100
        @require_learn = false
        @skill_id = 1
      end
    end
    #--------------------------------------------------------------------------
    # ● Action Conditions
    #--------------------------------------------------------------------------
    # If the condition is not met, remaining sequence actions are canceled.
    #
    # object_id - Object that Condition refers to. [0=Self] [1=Target] 
    #                                           [2=All Enemies] [3=All Allies]
    # type - :state, :parameter, :switch, :variable, :skill
    # type_id - This value is determined by the value you set for Content.
    #       State: State ID
    #       Parameter: [0=Current HP] [1=Current MP] [2=ATK] [3=DEX] [4=AGI] [5=INT]
    #       Switch: Game Switch Number
    #       Variable: Game Variable Number
    #       Skill: Skill ID
    #
    # value - Value for the Condition as defined above.
    # State: Amount required.  If number is positive, the condition is how 
    #        many have the state, while a negative number are those who 
    #        don't have the state.
    # Parameter: If Object is more than one battler, average is used.
    #            Success if Parameter is greater than value.  If Value
    #            is negative, then success if lower.
    # Switch: [true: Switch ON succeeds] [false: Switch OFF succeeds]
    # Variable: Game variable value used to determine if condition is met.  If
    #           supplement value is positive, Game Variable must have more
    #           than the defined amount to succeed.  If supplement value has a
    #           minus symbol (-) attached, Game Variable must have less than
    #           the defined amount to succeed.  (Ex: -250 means the Game
    #           Variable must have a value less than 250 to succeed.)
    # Skill: Required amount of battlers that have the specified skill ID learned.
    #--------------------------------------------------------------------------
    class Condition < SingleActionBase
      attr_accessor :object_id
      attr_accessor :type
      attr_accessor :type_id
      attr_accessor :value

      def initialize(key)
        super(key)
        @object_id = 0
        @type = :state #, :parameter, :switch, :variable, :skill
        @type_id = 1
        @value = 1
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Rotation
    #--------------------------------------------------------------------------
    # Rotates battler image (do GIFs support this?)
    #
    # duration - Duration duration of rotation animation in frames.
    # start_angle - 0-360 degrees.  Can be negative.
    # end_agngle - 0-360 degrees.  Can be negative.
    # reset - true: End of rotation is the same as end of duration.
    #         false: Rotation animation as defined.
    #--------------------------------------------------------------------------
    class Rotation < SingleActionBase
      attr_accessor :duration
      attr_accessor :start_angle
      attr_accessor :end_angle
      attr_accessor :reset

      def initialize(key)
        super(key)
        @duration = 1
        @start_angle = 0
        @end_angle = 360
        @reset = false
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Zoom
    #--------------------------------------------------------------------------
    # Stretch and shrink battler sprites (needs re-evaluation with Camera)
    #
    # duration - Duration of zoom animation in frames.
    # x_scale - Stretches battler sprite horizontally by a factor of X.
    #           100 is normal size, 50 is half size.
    # y_scale - Stretches battler sprite vertically by a factor of Y.
    #           100 would be normal size, 50 would be half size.
    # reset - true: End of rotation is the same as end of duration.
    #         false: Zoom animation as defined.
    #--------------------------------------------------------------------------
    class ZoomChange < SingleActionBase
      attr_accessor :duration
      attr_accessor :x_scale
      attr_accessor :y_scale
      attr_accessor :reset

      def initialize(key)
        super(key)
        @duration = 1
        @x_scale = 100
        @y_scale = 100
        @reset = false
      end
    end
    #--------------------------------------------------------------------------
    # ● Damage and Database-Assigned Animations
    #--------------------------------------------------------------------------
    # These single-actions deal with animations, particularly with those assigned 
    # in the Database for Weapons, Skills and Items.  These are what causes
    # any damage/healing/state/etc. application from Weapons, Skills and Items. 
    #
    # A difference between object animations and effect animations is that 
    # object animations will move with the Object on the screen.  The
    # Z-axis of animations will always be over battler sprites. 
    #
    # id - (-1): Uses assigned USER animation from game Database (items, skills, and attack)
    #      (-2): Uses assigned TARGET animation from game Database (items, skills, and attack)
    #      (-3): Always uses the weapon animation as assigned in the Database.
    #   (1~999): Database Animation ID.
    # object_id - [0=Self] [1=Target] 
    # invert - If set to true, the animation is inverted horizontally.
    # wait - true: Sequence will not continue until animation is completed.
    #        false: Sequence will continue regardless of animation length.
    # apply_damage - true: Will calculate damage based on skill/item
    #                false: Will only display the animation
    #--------------------------------------------------------------------------
    class ObjectAnimation < SingleActionBase
      attr_accessor :id
      attr_accessor :object_id
      attr_accessor :invert
      attr_accessor :wait
      attr_accessor :apply_damage

      def initialize(key)
        super(key)
        @id = 0
        @object_id = 0
        @invert = false
        @wait = false
        # @alt_object_type = nil
        # @alt_object_id = 0
        @apply_damage = false
      end
    end
    #--------------------------------------------------------------------------
    # ● Movement and Display of Animation Effects
    #--------------------------------------------------------------------------
    # These single-actions provide motion options for animations used for 
    # effects such as long-ranged attacks and projectiles.  Weapon sprites
    # may also substitute animations.
    #
    # A difference between EffectAnimation and ObjectAnimation is that EffectAnimations
    # animations will stay where the Object was even if the Object moved.
    #
    # animation_id - 1~999: Database Animation ID
    #                    0: No animation displayed.
    # object_id - Animation's target. [0=Target] [1=Enemy's Area] 
    #                                 [2=Party's Area] [3=Self]
    # pass_through - [false: Animation stops when it reaches the Object.] 
    #                [true: Animation passes through the Object and continues.] 
    # duration - Duration of animation travel time and display.  Larger values
    #            decrease travel speed.  Increase this value if the animation
    #            being played is cut short (Must not be 0)
    # arc - Trajectory - Positive values produce a low arc. 
    #                    Negative values produce a high arc.
    #                    [0: No Arc]
    # x_pitch - This value adjusts the initial X coordinate of the 
    #           animation. Enemy calculation will be automatically inverted.
    # y_pitch - This value adjusts the initial X coordinate of the animation.
    # origin_id - Defines origin of animation movement.
    #             [0=Self] [1=Target] [2=No Movement] 
    # z_add - amount to add to sprite's z value. zero defaults to over battler sprite
    # rotation - Parameters for weapon rotation, [start angle, end angle, speed]
    # show_weapon - Whether or not weapon sprite should be included in animation
    #--------------------------------------------------------------------------
    class EffectAnimation < SingleActionBase
      attr_accessor :animation_id
      attr_accessor :object_id
      attr_accessor :pass_through
      attr_accessor :duration
      attr_accessor :arc
      attr_accessor :x_pitch
      attr_accessor :y_pitch
      attr_accessor :origin_id
      attr_accessor :z_add
      attr_accessor :rotation
      attr_accessor :show_weapon

      def initialize(key)
        super(key)
        @animation_id = 0
        @object_id = 0
        @pass_through = false
        @duration = 1
        @arc = 0
        @x_pitch = 0
        @y_pitch = 0
        @origin_id = 0
        @z_add = 0
        @rotation = [0,0,0] # start angle, end angle, rotation speed
        @show_weapon = false
      end
    end
    #--------------------------------------------------------------------------
    # ● Show Picture
    #--------------------------------------------------------------------------
    # Display and move screen pictures. Only one image can be displayed at a time.
    #
    # start_x - Image's starting X-coordinate.
    # start_y - Starting Y-coordinate.
    # end_x - Ending X-coordinate.
    # end_y - Ending Y-coordinate.
    # speed - Move speed. Lower is faster.
    # z_add - amount to add to image Z order. 0 will default to 3500
    # filename - File name from .Graphics\Pictures folder. If battler_unique is true,
    #            this instead defines a subfolder in Graphics\Picture, and the filename
    #            is the battler's name
    # battler_unique - Picture is unique to the battler, where filename is the folder
    #                  in Graphics\Pictures where they're loaded from
    #--------------------------------------------------------------------------
    class Picture < SingleActionBase
      attr_accessor :start_x
      attr_accessor :start_y
      attr_accessor :end_x
      attr_accessor :end_y
      attr_accessor :speed
      attr_accessor :z_add
      attr_accessor :filename
      attr_accessor :battler_unique

      def initialize(key)
        super(key)
        @start_x = 0
        @start_y = 0
        @end_x = 0
        @end_y = 0
        @speed = 1
        @z_add = 0
        @filename = ''
        @battler_unique = false # when true, file is a folder with filenames as battler names
      end
    end
    #--------------------------------------------------------------------------
    # ● State Granting / Removal Effects
    #--------------------------------------------------------------------------
    # object_id - [0=Self] [1=Target] [2=All Enemies] [3=All Allies] 
    #          [4=All Allies (excluding user)]
    # state_id - State ID to be granted.
    # apply - true adds state, false removes it
    #--------------------------------------------------------------------------
    class StateChange < SingleActionBase
      attr_accessor :object_id
      attr_accessor :state_id
      attr_accessor :apply

      def initialize(key)
        super(key)
        @object_id = 0
        @state_id = 0
        @apply = true # false removes state
      end
    end
    #--------------------------------------------------------------------------
    # ● Battler Sprite Change
    #--------------------------------------------------------------------------
    # Modifies the battler sprite
    #
    # type - :graphic, :bitmap, :tone
    # tone - Tone to set, no effect unless :tone
    # bitmap_method - Bitmap method to call (:stop, :play), no effect unless :bitmap
    # graphic - filename of the battler graphic to load, no effect unless :graphic
    # battler_transform - Whether or not to apply the graphic to the whole battler
    #                     until the end of battle
    # permanent_graphic_change - Whether or not the graphic change should affect
    #                            the character out of battle (no effect unless 
    #                            :graphic and battler is an actor)  
    #--------------------------------------------------------------------------
    class SpriteChange < SingleActionBase
      attr_accessor :type
      attr_accessor :graphic
      attr_accessor :tone
      attr_accessor :bitmap_method
      attr_accessor :battler_transform
      attr_accessor :permanent_graphic_change

      def initialize(key)
        super(key)
        @type = :bitmap #, :tone, :graphic
        @graphic = ''
        @tone = Tone.new() # No effect unless type is tone
        @bitmap_method = :play #,:stop # No effect unless type is bitmap
        @battler_transform = false # Graphic applies to whole battler until end of battle
        @permanent_graphic_change = false # (Actor only) graphic change applies out of battle
      end
    end
    #--------------------------------------------------------------------------
    # ● Camera Change
    #--------------------------------------------------------------------------
    # Manipulates the battle camera
    #   action - :zoom_to, :center, :focus
    #   zoom_factor - zoom percent as integer, i.e. 100 = 1.0, 50 = 0.5 (only valid if :zoom_to)
    #   zoom_speed - speed to reach target zoom, 0 means instant (only valid if :zoom_to)
    #--------------------------------------------------------------------------
    class CameraChange < SingleActionBase
      attr_accessor :action
      attr_accessor :zoom_factor
      attr_accessor :zoom_speed

      def initialize(key)
        super(key)
        @action = :center #, :zoom_to, :focus_user, :focus_target, :follow_user, :follow_target
        # Only effective for :zoom_to
        @zoom_factor = 0
        @zoom_speed = 0
      end
    end
    #--------------------------------------------------------------------------
    # ● Screen Change
    #--------------------------------------------------------------------------
    # Manipulate $game_srceen object.
    #
    # type - :tone, :flash, :shake
    # tone - Screen / flash tone (no effect with :shake)
    # shake_power - Strength of shake effect (only valid if :shake)
    # duration - Duration in frames of effet
    #--------------------------------------------------------------------------
    class ScreenChange < SingleActionBase
      attr_accessor :action
      attr_accessor :tone
      attr_accessor :shake_power
      attr_accessor :duration

      def initialize(key)
        super(key)
        @action = :tone #, :flash, :shake
        @tone = Tone.new()
        @shake_power = 0 # only valid for :shake
        @duration = 5
      end
    end
    #--------------------------------------------------------------------------
    # ● Game Switch Change
    #--------------------------------------------------------------------------
    # switch_id - Switch number from the game database.
    # state - [true:Switch ON] [false:Switch OFF]
    #--------------------------------------------------------------------------
    class SwitchChange < SingleActionBase
      attr_accessor :switch_id
      attr_accessor :state

      def initialize(key)
        super(key)
        @switch_id = 0
        @state = true # on, off
      end
    end
    #--------------------------------------------------------------------------
    # ● Game Variable Change
    #--------------------------------------------------------------------------
    # variable_id - Variable number from the game database.
    # operation - :set, :add, :sub, :mult, :div, :mod
    # value - Value to apply with operation
    #--------------------------------------------------------------------------
    class VariableChange < SingleActionBase
      attr_accessor :variable_id
      attr_accessor :operation
      attr_accessor :value

      def initialize(key)
        super(key)
        @variable_id = 0
        @operation = :set 
        @value = 0
      end
    end
  end # SingleAction
  # Directives are special methods called during a sequence that modify
  # the battler sprite's state
  DIRECTIVES = {
    mirage_on: SingleAction::SingleActionBase.new(:mirage_on,:mirage_on),
    mirage_off: SingleAction::SingleActionBase.new(:mirage_off,:mirage_off),
    mirror_on: SingleAction::SingleActionBase.new(:mirror_on, :mirror_on),
    mirror_off: SingleAction::SingleActionBase.new(:mirror_off, :mirror_off),
    repeat_on: SingleAction::SingleActionBase.new(:repeat_on, :repeat_on),
    repeat_off: SingleAction::SingleActionBase.new(:repeat_off, :repeat_off),
    allow_collapse: SingleAction::SingleActionBase.new(:allow_collapse, :allow_collapse),
    individual: SingleAction::SingleActionBase.new(:individual, :individual),
    individual_end: SingleAction::SingleActionBase.new(:individual_end, :individual_end),
    start_pos_change: SingleAction::SingleActionBase.new(:start_pos_change, :start_pos_change),
    start_pos_return: SingleAction::SingleActionBase.new(:start_pos_return, :start_pos_return),
    cancel_action: SingleAction::SingleActionBase.new(:cancel_action, :cancel_action),
    anime_finish: SingleAction::SingleActionBase.new(:anime_finish, :anime_finish),
    no_action: SingleAction::SingleActionBase.new(:no_action, :no_action)
  }
end # Module
#==============================================================================
# * String
#==============================================================================
class String
  # Method to convert CamelCasedWord to underscore_cased_word 
  # Yoinked from Ruby on Rails
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end