#==============================================================================
# ** Core Functions
#------------------------------------------------------------------------------
# These are additional RGSS classes/modules that add new functionality or 
# speed up the scriptwriting process
#==============================================================================
#==============================================================================
# ** Delta Module
# Assorted methods for managing Graphics.delta, the time in nanoseconds since
# the last call to Graphics.update.
#------------------------------------------------------------------------------
module Delta
  OFFSET = 60
  def self.time
    Graphics.delta
  end
  def self.ms
    Graphics.delta / 1000.0
  end
end
#==============================================================================
# ** Timer Class
# Created by Jaiden
#------------------------------------------------------------------------------
# Allows the creation of a timer object which keeps time, in seconds
# based on deltaTime
#
class Timer
  attr_reader :counter
  attr_reader :limit
  #--------------------------------------------------------------------------
  # * Initialize
  # limit : time (in seconds) before timer is up
  #--------------------------------------------------------------------------
  def initialize(limit)
    @counter = 0
    @limit = limit
  end
  #--------------------------------------------------------------------------
  # * Frame update
  #--------------------------------------------------------------------------
  def update(speed_mod = 100)
    @counter += (Delta.time * speed_mod / 100.0)
  end
  #--------------------------------------------------------------------------
  # * Get ms
  #--------------------------------------------------------------------------
  def milliseconds
    return @counter * 1000
  end
  #--------------------------------------------------------------------------
  # * Reset timer
  #--------------------------------------------------------------------------
  def reset
    @counter = 0
  end
  #--------------------------------------------------------------------------
  # * Force completion
  #--------------------------------------------------------------------------
  def expire
    @counter = @limit
  end
  #--------------------------------------------------------------------------
  # * Determine if timer finished
  #--------------------------------------------------------------------------
  def finished?
    return @counter >= @limit
  end
end
#==============================================================================
# Easing Module
#
# This is a module with several functions utilized for easing functions
# These functions allow values passed to change in certain ways over time.
#
module Easing
  EXPONENT = 2 # easing exponent constant
  # Default easing method, takes current value, ending value, and duration (in frames)
  # Returns increment
  def self.default(current, ending, speed)
    value = (ending - current).to_f / speed
    return (ending > current ? value.ceil : value.floor)
  end
  # Returns increment
  def self.floating(current, ending, speed)
    value = (ending - current).to_f / speed.to_f
    return value
  end
  #--------------------------------------------------------------------
  # * Apply easing
  # cval, tval = current value, target value
  # ctime, ttime = current duration, total duration
  # Returns value at the given time
  #--------------------------------------------------------------------
  def self.apply(cval, tval, ctime, ttime, function = :linear, exp = EXPONENT)
    d = ctime.to_f
    wd = ttime.to_f
    lt = self.send(function, ((wd - d) / wd).to_f, exp)
    t = self.send(function, ((wd - d + 1) / wd).to_f, exp)
    start = (cval - tval * lt) / (1 - lt)
    start + (tval - start) * t
  end
  #--------------------------------------------------------------------------
  # * Linear
  #--------------------------------------------------------------------------
  def self.linear(t, _exp)
    t
  end
  #--------------------------------------------------------------------------
  # * Quad In
  #--------------------------------------------------------------------------
  def self.quad_in(t, _exp)
    t * t
  end
  #--------------------------------------------------------------------------
  # * Quad out
  #--------------------------------------------------------------------------
  def self.quad_out(t, _exp)
    1 - (1 - t) * (1 - t)
  end
  #--------------------------------------------------------------------------
  # * Ease in (slow -> fast)
  #--------------------------------------------------------------------------
  def self.ease_in(t, exp)
    t ** exp
  end
  #--------------------------------------------------------------------------
  # * Ease out (fast -> slow)
  #--------------------------------------------------------------------------
  def self.ease_out(t, exp)
    1 - ((1 - t) ** exp)
  end
end
#===============================================================================
# Range Class
#===============================================================================
class Range
  #-----------------------------------------------------------------------------
  # * Get length
  # Ruby 2.7 includes a function for this, Range#size
  #-----------------------------------------------------------------------------
  alias length size
end
#==============================================================================
# Circ(le) Class
#
# This is a class to compliment RGSS's Rect class to track circles
#
class Circ
  #--------------------------------------------------------------------------
  # * Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :cx
  attr_accessor :cy
  attr_accessor :radius
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(cx = 0, cy = 0, radius = 0)
    self.set(cx, cy, radius)
  end
  #--------------------------------------------------------------------------
  # * Set parameters
  #--------------------------------------------------------------------------
  def set(cx, cy, radius)
    @cx = cx
    @cy = cy
    @radius = radius
  end
  #--------------------------------------------------------------------------
  # * It can be assumed any time we change x/y, we mean to change the center point
  #--------------------------------------------------------------------------
  alias x cx
  alias y cy
  alias x= cx=
  alias y= cy=

  def to_s
    "CIRC: (#{@cx} #{@cy} #{@radius})"
  end

  def to_ary
    return [self.cx, self.cy, self.radius]
  end
end
#==============================================================================
# ** Line Class
# Easier management of lines for collision checking
#==============================================================================
class Line
  #--------------------------------------------------------------------------
  # * Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :point1
  attr_accessor :point2
  attr_reader :length
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x1, y1, x2, y2)
    @point1 = [x1, y1]
    @point2 = [x2, y2]
    # Calc the length (pixels)
    generate_length
  end
  #--------------------------------------------------------------------------
  # * Set the value of the length
  #--------------------------------------------------------------------------
  def generate_length
    x1, y1 = @point1
    x2, y2 = @point2
    @length = Collision.distance(x1, y1, x2, y2)
  end
  #--------------------------------------------------------------------------
  # * Determine a points distance from a line
  #--------------------------------------------------------------------------
  def point_distance(px, py)
    dist1 = Collision.distance(px, py, @point1[0], @point1[1])
    dist2 = Collision.distance(px, py, @point2[0], @point2[1])
    return dist1, dist2
  end
end
#==============================================================================
# ** HalfRect Class
# A rectangle with a missing corner that forms a triangle
#--------------------------------------------------------------------------
class HalfRect < Rect
  attr_reader :corner
  attr_reader :long_side

  UPPER_LEFT = 7
  UPPER_RIGHT = 9
  BOTTOM_LEFT = 1
  BOTTOM_RIGHT = 3

  def initialize(x, y, width, height, corner)
    super(x,y,width,height)
    @corner = corner
    create_long_side
  end
  # Based on the missing corner, create a line for the "Long" side
  # Re-called on setting any new attribute
  def create_long_side
    # Create
    if @long_side.nil?
      @long_side = 
        case @corner
        when UPPER_LEFT, BOTTOM_RIGHT # Bottom left to top right
          Line.new(self.x, self.y + self.height, self.x + self.width, self.y)
        when UPPER_RIGHT, BOTTOM_LEFT # Top left to bottom right
          Line.new(self.x, self.y, self.x + self.width, self.y + self.height)
        end
    # Update
    else
      case @corner
      when UPPER_LEFT, BOTTOM_RIGHT # Bottom left to top right
        @long_side.point1 = self.x, self.y + self.height
        @long_side.point2 = self.x + self.width, self.y
      when UPPER_RIGHT, BOTTOM_LEFT # Top left to bottom right
        @long_side.point1 = self.x, self.y
        @long_side.point2 = self.x + self.width, self.y + self.height
      end
      @long_side.generate_length
    end
  end
  # Upon setting new coordinates, the hypotenuse's coordinates must be regenerated
  def set(x,y,w,h)
    super(x,y,w,h)
    create_long_side
  end
  def x=(n)
    super(n)
    create_long_side
  end
  def y=(n)
    super(n)
    create_long_side
  end
  def width=(n)
    super(n)
    create_long_side
  end
  def height=(n)
    super(n)
    create_long_side
  end
end
#==============================================================================
# ** Poly(gon) Class
# Polygon object with a variable number of sides
#--------------------------------------------------------------------------
class Poly
  #--------------------------------------------------------------------------
  # * Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :vertices # Verts relative to position
  attr_accessor :real_vertices # Vertices real positions
  attr_reader :num_sides
  attr_reader :sides
  attr_accessor :x
  attr_accessor :y
  #--------------------------------------------------------------------------
  # * Object Initialization
  # verts = vertices, as [x,y]
  #--------------------------------------------------------------------------
  def initialize(*verts)
    # 2d array of vertices, in no order. [[x,y],[x,y],[x,y]...]
    @vertices = verts
    @real_vertices = []
    @num_sides = @vertices.size
    @num_sides.times do |i|
      @real_vertices[i] = [@vertices[i][0], @vertices[i][1]]
    end
    # To-do figure out x/y anchoring (center?)
    @x, @y = 0
    # Loop through the polygon's vertices
    generate_sides
  end

  def generate_sides
    @sides = []
    @num_sides.times do |i|
      # Form a line with each vertex
      current_vert = @real_vertices[i]
      next_vert = @real_vertices[(i + 1) % @num_sides]
      @sides << Line.new(current_vert[0],current_vert[1], next_vert[0], next_vert[1])
    end
  end

  def x=(n)
    @x = n
    @real_vertices.each_with_index do |vert, i|
      vert[0] = @vertices[i][0] + @x
    end
    generate_sides
  end

  def y=(n)
    @y = n
    @real_vertices.each_with_index do |vert, i|
      vert[1] = @vertices[i][1] + @y
    end
    generate_sides
  end

  def to_s
    "#{@real_vertices} #{@vertices}"
  end
end
#==============================================================================
# Collision Module
#
# This is a module that contains functions that can be used for 
# collision checking
#
module Collision
  #--------------------------------------------------------------------------
  # * Get value from distance table
  #--------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  # * Create Distance Table
  #--------------------------------------------------------------------------
  def self.create_distance_table
    #@distance_table = 
  end
  #--------------------------------------------------------------------------
  # * Distance between two points (sx,sy) and (tx,ty)
  #--------------------------------------------------------------------------
  def self.distance(sx, sy, tx, ty)
    # Use the formula sqrt((x1 - x2)^2 + (y1 - y2)^2)
    return Math.sqrt((sx - tx) ** 2 + (sy - ty) ** 2)
  end
  #--------------------------------------------------------------------------
  # * Circle to Circle Collision
  # source : Source circle. Can be a Circ object, or an array [x, y, radius]
  # target : Target circle. Can be a Circ object, or an array [x, y, radius]
  #--------------------------------------------------------------------------
  def self.circ_in_circ?(source, target)
    sx, sy, sr = source
    tx, ty, tr = target
    # If the distance between the points is less than the sum of their radii
    return (distance(sx, sy, tx, ty) <= (sr + tr))
  end
  #--------------------------------------------------------------------------
  # * Rect to Rect Collision
  # Note: Origin of x/y is the top left corner of the rectangle
  # source_rect : Source Rect. Can be Rect object, or an array [x, y, w, h]
  # target_rect : Target Rect. Can be Rect object, or an array [x, y, w, h]
  #--------------------------------------------------------------------------
  def self.rect_in_rect?(source_rect, target_rect)
    # Source rect (SR)
    sr_x, sr_y, sr_w, sr_h = source_rect
    # Target Rect (TR)
    tr_x, tr_y, tr_w, tr_h = target_rect
    # If SR RIGHT edge past TR LEFT
    if (sr_x + sr_w >= tr_x &&
      # If SR LEFT edge past TR RIGHT
      sr_x <= tr_x + tr_w &&
      # If SR TOP edge past TR BOTTOM
      sr_y + sr_h >= tr_y &&
      # If SR BOTTOM edge past TR TOP
      sr_y <= tr_y + tr_h)
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Circle to Rect Collision
  # source : Source circle. Can be a Circ object, or an array [x, y, radius]
  # rect : Target Rect. Can be Rect object, or an array [x, y, w, h]
  #--------------------------------------------------------------------------
  def self.circ_in_rect?(circle, rect)
    # Source circle (SC)
    sc_x, sc_y, sc_r = circle
    # Target Rect (TR)
    tr_x, tr_y, tr_w, tr_h = rect
    check_x = sc_x
    check_y = sc_y
    # Determine edge to check based on circ's position to rect
    # If Circ RIGHT, check RIGHT EDGE, otherwise LEFT EDGE
    if sc_x < tr_x 
      check_x = tr_x
    elsif sc_x >= tr_x + tr_w
      check_x = tr_x + tr_w
    end
    # If Circ TOP, check TOP EDGE, otherwise check BOTTOM EDGE
    if sc_y < tr_y 
      check_y = tr_y
    elsif sc_y >= tr_y + tr_h
      check_y = tr_y + tr_h
    end
    # Pythagorean theorem
    dist_x = sc_x - check_x
    dist_y = sc_y - check_y
    return Math.sqrt(dist_x * dist_x + dist_y * dist_y).round <= sc_r
  end
  #--------------------------------------------------------------------------
  # * Point in Circle
  # circle : Source circle. Can be a Circ object, or an array [x, y, radius]
  #--------------------------------------------------------------------------
  def self.point_in_circ?(px, py, circle)
    sc_x, sc_y, sc_r = circle
    dist_x = px - sc_x
    dist_y = py - sc_y
    return Math.sqrt((dist_x * dist_x) + (dist_y * dist_y)).round <= sc_r
  end
  #--------------------------------------------------------------------------
  # * Point in Rectangle
  # rect : Target Rect. Can be Rect object, or an array [x, y, w, h]
  #--------------------------------------------------------------------------
  def self.point_in_rect?(px, py, rect)
    rx, ry, rw, rh = rect
    # FIXME evenness offset, total monkey patch
    if rw % 2 == 0
      rw -= 1
    end
    if rh % 2 == 0
      rh -= 1
    end
    if (px >= rx && px <= rx + rw && py >= ry && py <= ry + rh)
      return true
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Circle in Line
  # Currently not functional. Need more continuous / faster checks, since its inaccurate.
  #--------------------------------------------------------------------------
  def self.circ_in_line?(circle, line)
    # Get ends of line
    x1, y1 = line.point1
    x2, y2 = line.point2
    length = line.length
    cx = circle.x
    cy = circle.y
    # Check if end of lines are in the circle to quickly bypass additional math
    return if point_in_circ?(x1, y1, circle)
    return if point_in_circ?(x2, y2, circle)
    # Get the dot product of both vectors
    # http://www.jeffreythompson.org/collision-detection/line-circle.php
    dot = (((cx-x1)*(x2-x1)) + ((cy-y1)*(y2-y1))) / (length**2)
    # Determine closest point
    closest_x = x1 + (dot * (x2 - x1))
    closest_y = y1 + (dot * (y2 - y1))
    # Check against line
    on_line = point_in_line?(closest_x, closest_y, line)
    return false if !on_line
    return point_in_circ?(closest_x, closest_y, circle)
  end
  #--------------------------------------------------------------------------
  # * Point in (well, on) line
  #--------------------------------------------------------------------------
  def self.point_in_line?(px, py, line)
    buffer = 0.1
    len = line.length
    # Get the points distance from the lines ends
    x1, y1 = line.point1
    x2, y2 = line.point2
    d1 = distance(px, py, x1, y1)
    d2 = distance(px, py, x2, y2)
    # Determine collision
    #return (d1 + d2 >= len - buffer && d1 + d2 <= len - buffer)
    return (d1 + d2 >= len && d1 + d2 <= len)
  end
  #--------------------------------------------------------------------------
  # * Circle in Polygon
  #--------------------------------------------------------------------------
  def self.circ_in_poly?(circle, poly)
    poly.sides.each do |line|
      return true if circ_in_line?(circle, line)
    end
    return false
  end
  # These are constants assuming tile size is 32x32 and the player is 24x24,
  # to save on Math calls.
  DIAG_CIRC_HYP = 47
  DIAG_LENGTH = 45.25
  #--------------------------------------------------------------------------
  # * Circle in Halfrect (Triangle)
  # We get the missing corner, then determine if a normal rect check can
  # be done based on the circle's position to that corner.
  # Otherwise, we check against an intersection of the line formed by the
  # verticies adjacent to the missing circle.
  # source : Source circle. Can be a Circ object, or an array [x, y, radius]
  # hrect : Target HalfRect. Can be an array [x, y, w, h, corner] or HalfRect object.
  #--------------------------------------------------------------------------
  # TODO: Use a lookup table / alternate for the distance calls to speed things up
  # Refactor method to reduce its length?
  def self.circ_in_halfrect?(circle, hrect)
    # Source circle (SC)
    sc_x, sc_y, sc_r = circle
    # Target Rect (TR)
    tr_x, tr_y, tr_w, tr_h, corner = hrect
    tr_left = tr_x
    tr_right = tr_x + tr_w
    tr_bottom = tr_y + tr_h
    tr_top = tr_y
    l_length = DIAG_LENGTH # hrect.long_side.length
    hyp = DIAG_CIRC_HYP #Math.sqrt((circle.radius * circle.radius) + (l_length * l_length)).round
    # More complex handling based on the "missing corner" (angle of the triangle)
    # Following referred from https://vband3d.tripod.com/visualbasic/tut_mixedcollisions.htm
    # Branch by corner
    case corner
    # ---------- Lower Left \| ------------
    when 1
      # Check if we're on the outer edge of the triangle
      if (sc_x > tr_right || sc_y < tr_top)
        return circ_in_rect?(circle, hrect)
      end
      # Check if we're "inside" the triangle
      # Simplify if our rect is a square
      if tr_w == tr_h
        # If cx is further right, and cy is further up than the sloped line
        if (sc_x - tr_left) >= (sc_y - tr_top)
          return true
        end
      else
        slope_x = (tr_right - tr_left) / (tr_bottom - tr_top)
        slope_y = (tr_bottom - tr_top) / (tr_right - tr_left)
        x_check = (sc_x - tr_left) >= (sc_y - tr_top) * slope_x
        y_check = (sc_y - tr_top) <= (sc_x - tr_left) * slope_y
        if x_check && y_check
          return true
        end
      end
      # Circle approaches the long side
      # If the circle is more than a radius' distance from line
      if distance(sc_x, sc_y, tr_left, tr_top) > hyp && 
        distance(sc_x, sc_y, tr_right, tr_bottom) > hyp
        return false
      end
      # Get start and end points 
      if distance(sc_x, sc_y, tr_left, tr_top) < distance(sc_x, sc_y, tr_right, tr_bottom)
        start_x = tr_left
        start_y = tr_top
        dx = (tr_right - start_x) / l_length
        dy = (tr_bottom - start_y) / l_length
      else
        start_x = tr_right
        start_y = tr_bottom
        dx = (tr_left - start_x) / l_length
        dy = (tr_top - start_y) / l_length
      end 
    # ---------- Lower right |/ ------------
    when 3  
      if (sc_x < tr_left || sc_y < tr_top)
        return circ_in_rect?(circle, hrect)
      end
      # Check if we're "inside" the triangle
      # Simplify if our rect is a square
      if tr_w == tr_h
        # If cx is further left, and cy is further up than the sloped line
        if (tr_right - sc_x) >= (sc_y - tr_top)
          return true
        end
      end
      # Circle approaches the long side
      # If the circle is more than a radius' distance from line
      if distance(sc_x, sc_y, tr_left, tr_bottom) > hyp && 
        distance(sc_x, sc_y, tr_right, tr_top) > hyp
        return false
      end
      # Get start and end points 
      if distance(sc_x, sc_y, tr_left, tr_bottom) < distance(sc_x, sc_y, tr_right, tr_top)
        start_x = tr_left
        start_y = tr_bottom
        dx = (tr_right - start_x) / l_length
        dy = (tr_top - start_y) / l_length
      else
        start_x = tr_right
        start_y = tr_top
        dx = (tr_left - start_x) / l_length
        dy = (tr_bottom - start_y) / l_length
      end 
    # ---------- Upper left  /| ------------
    when 7  
      if (sc_x > tr_right || sc_y > tr_bottom)
        return circ_in_rect?(circle, hrect)
      end
      # Check if we're "inside" the triangle
      # Simplify if our rect is a square
      if tr_w == tr_h
        # If cx is further right, and cy is further below than the sloped line
        if (tr_right - sc_x) < (sc_y - tr_top)
          return true
        end
      end
      # Circle approaches the long side
      # If the circle is more than a radius' distance from line
      if distance(sc_x, sc_y, tr_left, tr_bottom) > hyp && 
        distance(sc_x, sc_y, tr_right, tr_top) > hyp
        return false
      end
      # Get start and end points 
      if distance(sc_x, sc_y, tr_left, tr_bottom) < distance(sc_x, sc_y, tr_right, tr_top)
        start_x = tr_left
        start_y = tr_bottom
        dx = (tr_right - start_x) / l_length
        dy = (tr_top - start_y) / l_length
      else
        start_x = tr_right
        start_y = tr_top
        dx = (tr_left - start_x) / l_length
        dy = (tr_bottom - start_y) / l_length
      end 
    # ---------- Upper right |\ ------------
    when 9 
      if (sc_x < tr_left || sc_y > tr_bottom)
        return circ_in_rect?(circle, hrect)
      end
      # Check if we're "inside" the triangle
      # Simplify if our rect is a square
      if tr_w == tr_h
        # If cx is further left, and cy is further below than the sloped line
        if (sc_x - tr_left) < (sc_y - tr_top)
          return true
        end
      end
      # Circle approaches the long side
      # If the circle is more than a radius' distance from line
      if distance(sc_x, sc_y, tr_left, tr_top) > hyp && 
        distance(sc_x, sc_y, tr_right, tr_bottom) > hyp
        return false
      end
      # Get start and end points 
      if distance(sc_x, sc_y, tr_left, tr_top) < distance(sc_x, sc_y, tr_right, tr_bottom)
        start_x = tr_left
        start_y = tr_top
        dx = (tr_right - start_x) / l_length
        dy = (tr_bottom - start_y) / l_length
      else
        start_x = tr_right
        start_y = tr_bottom
        dx = (tr_left - start_x) / l_length
        dy = (tr_top - start_y) / l_length
      end
    end
    # Check along each point on the line for a collision
    last_dist = -1
    for i in 1...l_length
      cur_x = (start_x + i * dx)
      cur_y = (start_y + i * dy)
      cur_dist = distance(cur_x, cur_y, sc_x, sc_y).round
      if cur_dist < sc_r
        return true
      end
      if last_dist > 0 && cur_dist > last_dist
        return false
      end
      last_dist = cur_dist
    end
    # Collision did not occur
    return false
  end
end
#===============================================================================
# ** NilClass Catches
#===============================================================================
class NilClass
  unless method_defined?(:dispose)
    def dispose
      puts "Warning: Disposed nil object at:"
      p caller
    end
    def disposed?
      puts "Warning: Checking disposed? on nil object"
    end
  end
end