#===============================================================================
# * Game Pathfinding (Inactive)
# Handles finding a path from a to b
#===============================================================================
class Game_Pathfinding
  attr_accessor :active
  attr_reader :target_x
  attr_reader :target_y
  attr_reader :coords
  
  #-----------------------------------------------------------------------------
  # initialising method
  #-----------------------------------------------------------------------------
  def initialize(event)   
    @walk = true
    @radius = 0
    @active = false
    @event = event
    @find_short_ways = false
    @find_waypoint_ways = false
  end
    
  #-----------------------------------------------------------------------------
  # starts the finding process
  #-----------------------------------------------------------------------------
  def find_path(target_x, target_y, walk = true, radius = 0)    
    if @find_waypoint_ways || @find_short_ways || $game_map.waypoints == nil
      return false
    end
    
    # For Isometric Movement
    div_x = 2
    
    @start_x = @event.x / div_x * div_x
    @start_y = @event.y / 2 * 2
    @target_x = target_x / div_x * div_x
    @target_y = target_y / 2 * 2
    @event.moveto(@start_x, @start_y)
    
    @walk = walk
    @active = true
    @radius = radius.round
    self.path_normal
    
    return true
    
  end
  
  #-----------------------------------------------------------------------------
  # fast pathfinding
  #-----------------------------------------------------------------------------
  def path_normal

    # sorts wayponts: distance to start
    cos = []
    dist = 0
    while cos.size == 0
      dist += 32
      $game_map.waypoints.keys.each do |co|
        next if $game_map.distance(@start_x, @start_y, co[0], co[1]) > dist
        cos.push(co)
      end
    end
    
    cos.sort! do |a, b|
      aa = $game_map.distance(@start_x, @start_y, a[0], a[1])
      bb = $game_map.distance(@start_x, @start_y, b[0], b[1])
      aa <=> bb
    end

    # sorts wayponts: distance to target (only the first two)
    cos = cos[0..1] if cos.length > 1
    cos.sort! do |a, b|
      aa = $game_map.distance(@target_x, @target_y, a[0], a[1])
      bb = $game_map.distance(@target_x, @target_y, b[0], b[1])
      aa <=> bb
    end

    # takes the best fitting waypoint for the start
    @coords_start_way = {[cos[0][0], cos[0][1]] => Game_Path.new(cos[0][0], 
                        cos[0][1], [[cos[0][0], cos[0][1], 0, 'normal']], 0)}
    @coords_start = [[cos[0][0], cos[0][1]]]

    # sorts waypoints: distance to target
    cos = $game_map.waypoints.keys
    cos = []
    dist = 0
    while cos.size == 0
      dist += 32
      $game_map.waypoints.keys.each do |co|
        next if $game_map.distance(@target_x, @target_y, co[0], co[1]) > dist
        cos.push(co)
      end
    end
    
    cos.sort! do |a, b|
      aa = $game_map.distance(@target_x, @target_y, a[0], a[1])
      bb = $game_map.distance(@target_x, @target_y, b[0], b[1])
      aa <=> bb
    end

    # sorts waypoints: distance to start (only the first two)
    cos = cos[0..1] if cos.length > 1
    cos.sort! do |a, b|
      aa = $game_map.distance(@start_x, @start_y, a[0], a[1])
      bb = $game_map.distance(@start_x, @start_y, b[0], b[1])
      aa <=> bb
    end
    dist = $game_map.distance(@target_x, @target_y, cos[0][0], cos[0][1])
    @radius = [@radius, dist].max

    # takes the best fitting waypoint for the target
    @coords_target_way = {[cos[0][0], cos[0][1]] => Game_Path.new(cos[0][0], 
                         cos[0][1], [[cos[0][0], cos[0][1], 0, 'normal']], 0)}
    @coords_target = [[cos[0][0], cos[0][1]]]
    
    # if the way is real short..
    if @coords_start == @coords_target
      @new_way = []
      self.path_fast(@start_x, @start_y, @coords_target[0][0], 
                     @coords_target[0][1], 96, 0)
      @new_way.push(@way)
      self.path_fast(@coords_start[0][0], @coords_start[0][1], @target_x, 
                     @target_y, 96, @radius)
      @new_way.push(@way)
      self.execute_way
      return
    end

  
    @ende = false
    @find_waypoint_ways = true
  end
  
  #-----------------------------------------------------------------------------
  # update method
  #-----------------------------------------------------------------------------
  def update    
    
    self.find_waypoint_ways_update if @find_waypoint_ways
    self.find_short_ways_update if @find_short_ways
    
  end
  
  #---------------------------------------------------------------------------
  # finds a way using the waypoints
  #---------------------------------------------------------------------------
  def find_waypoint_ways_update(again = true)
    
    time_start = Time.new # start time of finding ways
    way_count = @coords_start.length + @coords_target.length
    
    @ende = true if @coords_start == @coords_target
    
    # structure of the coords: [x, y, length, type, dir]
    while Time.new - time_start < 0.015 && !@ende

      # for every existing way      
      @coords_start.each do |coords|
        next if @coords_start_way[coords] == []
        way = @coords_start_way[coords]
        
        # tries every direction && adds the new position if useful
        for coords in $game_map.waypoints[way.path.last[0..1]] do
          next if coords[3] == 'iso' && !$pixelmovement.isometric
          next if coords[3] == 'diag' && $pixelmovement.isometric
          next if coords[3] == 'diag' && $pixelmovement.movement_type=='dir4'
          if coords[3]=='normal' && $pixelmovement.movement_type=='dir4diag'
            next
          end
            
          # if the coordinates exists: is the new way shorter than the old one?
          if @coords_start.include?(coords[0..1])
            next if @coords_start_way[coords[0..1]] == []
            distance = way.length + coords[2]
            next if @coords_start_way[coords[0..1]].length <= distance
          end
          
          # adds possible way
          distance = way.length + coords[2]
          @coords_start_way[coords[0..1]] = Game_Path.new(coords[0], coords[1], 
                                    way.path + [coords], distance)
                                    
          # adds coordinates
          if !@coords_start.include?(coords[0..1])
            @coords_start.push(coords[0..1])
          end

          # if way has been found
          if @coords_target.include?(coords[0..1]) ||(@radius >= 24 && $game_map.distance(@target_x, @target_y, coords[0], coords[1]) <= @radius)
            @ende = true
          end
          
        end
        
        # break?
        @coords_start_way[@coords_start_way.index(way)] = []
        break if @ende || Time.new - time_start >= 0.015
      end
      
      # sorts ways
      @coords_start.sort! do |a, b|
        @coords_start_way[a].length <=> @coords_start_way[b].length
      end
      
      if @radius < 24
      
        # for every existing way
        @coords_target.each do |coords|
          next if @coords_target_way[coords] == []
          way = @coords_target_way[coords]
          
          # tries every direction && adds the new position if useful
          for coords in $game_map.waypoints[way.path.last[0..1]] do
            next if coords[3] == 'iso' && !$pixelmovement.isometric
            next if coords[3] == 'diag' && $pixelmovement.isometric
            next if coords[3] == 'diag' && $pixelmovement.movement_type=='dir4'
            if coords[3]=='normal' && $pixelmovement.movement_type=='dir4diag'
              next
            end
            
            # if the coordinates exists:is the new way shorter than the old one?
            if @coords_target.include?(coords[0..1])
              next if @coords_target_way[coords[0..1]] == []
              distance = way.length + coords[2]
              next if @coords_target_way[coords[0..1]].length <= distance
            end
            
            # adds possible way
            distance = way.length + coords[2]
            @coords_target_way[coords[0..1]] = Game_Path.new(coords[0],
                                       coords[1], way.path + [coords], distance)
                                      
            # adds coordinates
            if !@coords_target.include?(coords[0..1])
              @coords_target.push(coords[0..1])
            end
            
            # if way has been found
            @ende = true if @coords_start.include?(coords[0..1])
          end
          
          # break?
          @coords_target_way[@coords_target_way.index(way)] = []
          break if @ende || Time.new - time_start >= 0.015
        end
        
        # sorts ways
        @coords_target.sort! do |a, b|
          @coords_target_way[a].length <=> @coords_target_way[b].length
        end
              
      end
      
      # if way has been found
      break if @ende

      # if way can!be found: new way with a bigger radius is searched
      
      if way_count == @coords_start.length + @coords_target.length
        self.find_waypoint_ways_update(false) if again
        if way_count == @coords_start.length + @coords_target.length
          @find_waypoint_ways = false
          if @radius < 256
            self.find_path(@target_x, @target_y, @walk, 
                          (@radius < 8 ? 24 : @radius + 16))
          end
        end
        break
      end
            
    end
    
    #---------------------------------------------------------------------------
    # p both ways together
    #---------------------------------------------------------------------------
    return if !@ende
        
    # sorts ways
    @way = nil
    @coords_start.sort! do |a, b|
      @coords_start_way[a].length <=> @coords_start_way[b].length
    end
    
    # if the radius is big (so only one way exists start->target)
    if @radius >= 24
      @coords_start.each do |co|
        s = @coords_start_way[co]
        next if s == []
        if $game_map.distance(@target_x, @target_y, s.path.last[0], 
        s.path.last[1]) <= @radius
          @way = [[@start_x, @start_y, 32, 'normal']] + s.path
          break
        end
      end    
      
    #otherwise: connects the two ways (start->middle, target->middle)
    else
      @coords_target.sort! do |a, b|
        @coords_target_way[a].length <=> @coords_target_way[b].length
      end
      
      # creates && sorts a [start, target] array (length)
      coords_start_target = []
      @coords_start.each do |start|
        @coords_target.each do |target|
          coords_start_target.push([start, target])
        end
      end
      coords_start_target.sort! do |a, b|
        la = @coords_start_way[a[0]].length + @coords_target_way[a[1]].length
        lb = @coords_start_way[b[0]].length + @coords_target_way[b[1]].length
        la <=> lb
      end

      coords_start_target.each do |coords|
        break if @way != nil
        s = @coords_start_way[coords[0]]
        z = @coords_target_way[coords[1]]
        if s == []
          if coords[0] == @coords_start[0]
            path = [coords[0] + [0] + ['normal']]
            s = Game_Path.new(coords[0][0], coords[0][1], path)
          else
            next
          end
        end
        if z == []
          if coords[1] == @coords_target[0]
            path = [coords[1] + [0] + ['normal']]
            z = Game_Path.new(coords[1][0], coords[1][1], path)
          else
            next
          end
        end
        sco = []
        zco = []
        s.path.each {|co| sco.push(co[0..1])}
        z.path.each {|co| zco.push(co[0..1])}
        if sco.include?(z.path.last[0..1]) || zco.include?(s.path.last[0..1])
          w_s = [[@start_x, @start_y, 32, 'normal']] + s.path
          w_z = [[@target_x, @target_y, 32, 'normal']] + z.path
          @way = w_s - [w_s.last] + w_z.reverse
          break
        end
      end   
    end
    
    @find_short_ways = true
    @find_waypoint_ways = false
    @new_way = []
    @old_way = @way
    @counter = 0    
  end
  
  #---------------------------------------------------------------------------
  # creates connections between the waypoints
  #---------------------------------------------------------------------------
  def find_short_ways_update
    time_start = Time.new # start time of finding ways
    
    # deletes events, which have to be ignored
    events = $game_map.events.clone
    $game_map.events.each do |id, event| 
      $game_map.events.delete(id) if $game_map.events[id].move_type != 0
    end

    while @counter < @old_way.length - 1 && Time.new - time_start < 0.015
      
      # sets maximum steps
      if @counter > 0 && (@coords.last[0] != @old_way[@counter][0] || 
      @coords.last[1] == @old_way[@counter][1])
        ms = [@old_way[@counter + 1][2] + @old_way[@counter][2] / 2, 4].max
      else
        ms = [@old_way[@counter + 1][2] * 3 / 4, 4].max
      end
      
      # connects two waypoints
      if @counter >= @old_way.length - 2
        self.path_fast(@coords.last[0], @coords.last[1], @target_x, @target_y, 
                       ms, @radius)
      elsif @counter > 0 
        self.path_fast(@coords.last[0], @coords.last[1], 
                       @old_way[@counter + 1][0], 
                       @old_way[@counter + 1][1], ms)
      else
        self.path_fast(@old_way[0][0], @old_way[0][1], 
                       @old_way[1][0], @old_way[1][1], ms)
      end

      @new_way.push(@way)
      @counter += 1
    end
    
    if Graphics.frame_count % 4 == 0 || @counter >= @old_way.length - 1
      self.correct_short_ways
    end
    
    # reloads events which had to be ignored
    $game_map.events = events
    
    #---------------------------------------------------------------------------
    # saves the way
    #---------------------------------------------------------------------------
    return if @counter < @old_way.length - 1
    
    self.execute_way

  end
  
  #-----------------------------------------------------------------------------
  # corrects way if the event has moved
  #-----------------------------------------------------------------------------
  def correct_short_ways
    div_x = $pixelmovement.isometric ? 4 : 2
    if @start_x == @event.x / div_x * div_x && @start_y == @event.y / 2 * 2
      return
    end

    # sorts waypoints (so the best connection between the new start point and
    # the route can be found)
    start_x = @event.x / div_x * div_x
    start_y = @event.y / 2 * 2
    cos = @old_way.clone
    cos.sort! do |a, b|
      taa = $game_map.distance(@target_x, @target_y, a[0], a[1])
      tbb = $game_map.distance(@target_x, @target_y, b[0], b[1])
      taa <=> tbb
    end
    cos.length.times do
      dist = $game_map.distance(start_x, start_y, cos[0][0], cos[0][1])
      if dist <= 64
        break
      else
        temp = cos[0]
        cos.delete_at(0)
        cos.push(temp)
      end
    end
    
    # returns if the best waypoint hasnt been connected with a route yet
    ind = @old_way.index(cos[0])
    return if ind >= @counter
 
    @start_x = @event.x / div_x * div_x
    @start_y = @event.y / 2 * 2
    @new_way = @new_way[ind..@new_way.length - 1]
    @old_way = @old_way[ind..@old_way.length - 1]
    co = @coords.clone
    dist = $game_map.distance(@start_x, @start_y, cos[0][0], cos[0][1])
    
    # if the distance the the route is short: simple connection
    if dist <= 32
      @old_way.unshift([@start_x, @start_y, dist.round, 'normal'])
      self.path_fast(@start_x,@start_y,cos[0][0],cos[0][1],[dist*2/3,4].max)
      @new_way.unshift(@way)
      
    # if the distance is bigger: creates a waypoint between start and route
    else
      $game_map.waypoints.each do |coords, wps|
        dist = $game_map.distance(start_x, start_y, coords[0], coords[1])
        start_found = dist <= 32
        target_found = false
        target_wp = nil
        
        wps.each do |wp|
          if wp[0..1] == cos[0][0..1]
            target_found = true
            target_wp = wp
            break
          end
        end
        
        if start_found && target_found
          @old_way.unshift([coords[0], coords[1], dist.round, 'normal'])
          @old_way.unshift([@start_x, @start_y, dist.round, 'normal'])
          self.path_fast(coords[0], coords[1], target_wp[0], target_wp[1],
                         target_wp[2])
          @new_way.unshift(@way)
          self.path_fast(@start_x, @start_y, coords[0], coords[1], 
                         [dist * 2 / 3, 4].max)
          @new_way.unshift(@way)
          break
        end
        
      end
    end
    
    @counter = @new_way.length
    @coords = co
    
  end
  
  #-----------------------------------------------------------------------------
  # finishes pathfinding, executes way
  #-----------------------------------------------------------------------------
  def execute_way
    
    @way = @new_way.flatten
    @find_short_ways = false
    
    # initializes event's move route
    return if !@walk
    
    codes = [nil, 5, 1, 6, 2, nil, 3, 7, 4, 8]
    route = RPG::MoveRoute.new
    route.repeat = false
    route.skippable = false  
    i = 0
    
    speed = @event.move_speed
    max = [(2 ** (speed - 1)).round, 2].max

    while i < @way.length
      steps = 0
      while @way[i] == @way[i + steps] && steps < max
        steps += 1
      end
      route.list.push(RPG::MoveCommand.new(codes[@way[i]], [steps * 2]))
      i += steps
    end
    
    route.list.push(route.list[0])
    route.list.delete_at(0)
    @event.force_move_route(route)
  end
  
  #-----------------------------------------------------------------------------
  # fast pathfinding
  #-----------------------------------------------------------------------------
  def path_fast(start_x = @start_x, start_y = @start_y, target_x = @target_x, 
                target_y = @target_y, max = 512, radius = 0)
                
    @coords = [] # done coords
    @way_old = nil
    max = max.round
    radius = radius.round
    counter = 0
    
    # For Isometric Movement
    start_x = start_x / 4 * 4 if $pixelmovement.isometric
    target_x = target_x / 4 * 4 if $pixelmovement.isometric
    
    # for looped maps
    if MapConfig.looping?($game_map)
      dist1 = Math.sqrt((start_x - target_x) ** 2 + (start_y - target_y) ** 2)
      
      dist2 = Math.sqrt((start_x - target_x - $game_map.width * 32) ** 2 + 
                        (start_y - target_y) ** 2)
      dist3 = Math.sqrt((start_x - target_x + $game_map.width * 32) ** 2 + 
                        (start_y - target_y) ** 2)
      target_x += $game_map.width * 32 if dist1 > dist2
      target_x -= $game_map.width * 32 if dist1 > dist3
      
      dist4 = Math.sqrt((start_x - target_x) ** 2 + 
                        (start_y - target_y - $game_map.height * 32) ** 2)
      dist5 = Math.sqrt((start_x - target_x) ** 2 + 
                        (start_y - target_y + $game_map.height * 32) ** 2)
      target_y += $game_map.height * 32 if dist1 > dist4
      target_y -= $game_map.height * 32 if dist1 > dist5
    end
  
    # creates way
    @way = Game_Path.new(start_x, start_y, [])
    @coords += [[start_x, start_y]]
        
    loop do
                
      # adds a possible way
      @way_old = @way
      self.add_ways(target_x, target_y)
      
      # deletes unusable things
      if @way.path.length % 128 == 0
        for i in 1..9
          self.delete_unusable(i, 10 - i)
        end       
      end
      
      # if no direction is possible anymore, one step back
      if @way_old == @way
        
        case @way.path.last
        when 1
          @way.x += ($pixelmovement.isometric ? 4 : 2)
          @way.y -= 2
        when 2
          @way.y -= 2
        when 3
          @way.x -= ($pixelmovement.isometric ? 4 : 2)
          @way.y -= 2
        when 4
          @way.x += ($pixelmovement.isometric ? 4 : 2)
        when 6
          @way.x -= ($pixelmovement.isometric ? 4 : 2)
        when 7
          @way.x += ($pixelmovement.isometric ? 4 : 2)
          @way.y += 2
        when 8
          @way.y += 2
        when 9
          @way.x -= ($pixelmovement.isometric ? 4 : 2)
          @way.y += 2
        end
        @way.path.pop
        
      end
      
      counter += 1

      # If target is found
      if @coords.include?([target_x, target_y]) || @way.path.length >= max || counter >= max * 3 || Math.sqrt((target_x - @way.x) ** 2 + (target_y - @way.y) ** 2) <= radius
        
        # if the target hasnt been found
        dist2 = Math::sqrt((target_x - @coords.last[0])**2 + 
                           (target_y - @coords.last[1])**2)
        if dist2 > radius
          distx = []
          @coords.each do |cos|
            distx.push(Math::sqrt((target_x-cos[0])**2 + (target_y-cos[1])**2))
          end
          distmin = (distx.sort {|a, b| a <=> b})[0]
          @coords = @coords[0..distx.index(distmin)]
          if distx.index(distmin) - 1 < 0
            @way.path = []
          else
            @way.path = @way.path[0..distx.index(distmin) - 1]
          end
          
        end
        
        for i in 1..9
          self.delete_unusable(i, 10 - i, 8)
        end     
        @way = @way.path
        
        return dist2 <= radius
      end
      
    end
  end
  
  #-----------------------------------------------------------------------------
  # deletes unusable things (like 2,8,2,8,2,8)
  #-----------------------------------------------------------------------------
  def delete_unusable(d1 = 2, d2 = 8, ab = 8, count = 3)  
    return if @way.path == []
    count = ab - 2 if count >= ab - 1
    i = ab
    
    while i <= @way.path.length - 1 - ab
      if (@way.path[(i - ab)..(i - 1)] - [d1]).length <= count && (@way.path[(i + 1)..(i + ab)] - [d2]).length <= count
        
        j = 0
        while @way.path[i + j] != d1
          j -= 1
        end
        j_old = j
        while @way.path[i + j] == d1
          j -= 1
        end
        if j_old - j <= count
          while @way.path[i + j] != d1
          j -= 1
          end
          while @way.path[i + j] == d1
            j -= 1
          end
        end
        
        k = 0
        while @way.path[i + k] != d2
          k += 1
        end
        k_old = k
        while @way.path[i + k] == d2
          k += 1
        end
        if k - k_old <= count
          while @way.path[i + k] != d2
            k += 1
          end
          k_old = k
          while @way.path[i + k] == d2
            k += 1
          end
        end
        j += 1
        k -= 1
        
        while @way.path[i + j] == d1 && @way.path[i + k] == d2
          @way.path.delete_at(i + k)
          @way.path.delete_at(i + j)
          k -= 2
        end
        
      end
      i += 1
    end

  end
  
  #-----------------------------------------------------------------------------
  # adds new way (fast Pathfinding)
  # tries to find the direct way to the target (e.g. if the target is below the
  # start point, it tries to go down
  #-----------------------------------------------------------------------------
  def add_ways(target_x, target_y)
    
    if @way.y < target_y
      if @way.x > target_x # left/down
        if self.go_left_down(target_x, target_y)
        elsif self.go_right_down(target_x, target_y)
          while (!self.go_left_down(target_x, target_y)) && self.go_right_down(target_x, target_y) do
          end
        elsif self.go_left_up(target_x, target_y)
          while (!self.go_left_down(target_x, target_y)) && self.go_left_up(target_x, target_y) do
          end
        else self.go_right_up(target_x, target_y)
          while (!self.go_left_down(target_x, target_y)) && self.go_right_up(target_x, target_y) do
          end
        end
        
      elsif @way.x < target_x # right/down
        if self.go_right_down(target_x, target_y)
        elsif self.go_left_down(target_x, target_y)
          while (!self.go_right_down(target_x, target_y)) && self.go_left_down(target_x, target_y) do
          end
        elsif self.go_right_up(target_x, target_y)
          while (!self.go_right_down(target_x, target_y)) && self.go_right_up(target_x, target_y) do
          end
        else self.go_left_up(target_x, target_y)     
          while (!self.go_right_down(target_x, target_y)) && self.go_left_up(target_x, target_y) do
          end
        end
        
      else # down
        if self.go_down(target_x, target_y)
        elsif self.go_left(target_x, target_y)
          while (!self.go_down(target_x, target_y)) && self.go_left(target_x, target_y) do
          end
        elsif self.go_right(target_x, target_y)    
          while (!self.go_down(target_x, target_y)) && self.go_right(target_x, target_y) do
          end
        else self.go_up(target_x, target_y)
          while (!self.go_down(target_x, target_y)) && self.go_up(target_x, target_y) do
          end
        end
      end
      
    elsif @way.y > target_y
      if @way.x > target_x # left/up
        if self.go_left_up(target_x, target_y)
        elsif self.go_left_down(target_x, target_y)
          while (!self.go_left_up(target_x, target_y)) && self.go_left_down(target_x, target_y) do
          end
        elsif self.go_right_up(target_x, target_y)  
          while (!self.go_left_up(target_x, target_y)) && self.go_right_up(target_x, target_y) do
          end
        else self.go_right_down(target_x, target_y)
          while (!self.go_left_up(target_x, target_y)) && self.go_right_down(target_x, target_y) do
          end
        end
        
      elsif @way.x < target_x # right/up
        if self.go_right_up(target_x, target_y)  
        elsif self.go_left_up(target_x, target_y)
          while (!self.go_right_up(target_x, target_y)) && self.go_left_up(target_x, target_y) do
          end
        elsif self.go_right_down(target_x, target_y)
          while (!self.go_right_up(target_x, target_y)) && self.go_right_down(target_x, target_y) do
          end
        else self.go_left_down(target_x, target_y)
          while (!self.go_right_up(target_x, target_y)) && self.go_left_down(target_x, target_y) do
          end
        end
        
      else # up
        if self.go_up(target_x, target_y)
        elsif self.go_right(target_x, target_y)
          while (!self.go_up(target_x, target_y)) && self.go_right(target_x, target_y) do
          end
        elsif self.go_left(target_x, target_y)
          while (!self.go_up(target_x, target_y)) && self.go_left(target_x, target_y) do
          end
        else self.go_down(target_x, target_y)
          while (!self.go_up(target_x, target_y)) && self.go_down(target_x, target_y) do
          end
        end
      end
      
    elsif @way.x > target_x # left
      if self.go_left(target_x, target_y)
      elsif self.go_up(target_x, target_y)
        while (!self.go_left(target_x, target_y)) && self.go_up(target_x, target_y) do
        end
      elsif self.go_down(target_x, target_y)
        while (!self.go_left(target_x, target_y)) && self.go_down(target_x, target_y) do
        end
      else self.go_right(target_x, target_y)
        while (!self.go_left(target_x, target_y)) && self.go_right(target_x, target_y) do
        end
      end
      
    elsif @way.x < target_x  # right
      if self.go_right(target_x, target_y)
      elsif self.go_up(target_x, target_y)
        while (!self.go_right(target_x, target_y)) && self.go_up(target_x, target_y) do
        end
      elsif self.go_down(target_x, target_y)
        while (!self.go_right(target_x, target_y)) && self.go_down(target_x, target_y) do
        end
      else self.go_left(target_x, target_y)
         while (!self.go_right(target_x, target_y)) && self.go_left(target_x, target_y) do
         end
      end
    end        
   
  end
  
  #-----------------------------------------------------------------------------
  # tries to go left and up
  # if not possible: tries to go up or left
  #-----------------------------------------------------------------------------
  def go_left_up(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x - steps_x, @way.y - steps_y, 7)
      if !self.add_way(@way.x - steps_x, @way.y, 4)
        if !self.add_way(@way.x, @way.y - steps_y, 8)
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go left and down
  # if !possible: tries to go down or left
  #-----------------------------------------------------------------------------
  def go_left_down(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x - steps_x, @way.y + steps_y, 1)
      if !self.add_way(@way.x - steps_x, @way.y, 4)
        if !self.add_way(@way.x, @way.y + steps_y, 2)
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go right and up
  # if not possible: tries to go up or right
  #-----------------------------------------------------------------------------
  def go_right_up(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x + steps_x, @way.y - steps_y, 9)
      if !self.add_way(@way.x + steps_x, @way.y, 6)
        if !self.add_way(@way.x, @way.y - steps_y, 8)   
          return false
        end
      end
    end      
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go right and down
  # if not possible: tries to go down or right
  #-----------------------------------------------------------------------------
  def go_right_down(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x + steps_x, @way.y + steps_y, 3)
      if !self.add_way(@way.x + steps_x, @way.y, 6)
        if !self.add_way(@way.x, @way.y + steps_y, 2)  
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go left
  # if not possible: tries to go upper left or lower left
  #-----------------------------------------------------------------------------
  def go_left(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x - steps_x, @way.y, 4)
      if !self.add_way(@way.x - steps_x, @way.y + steps_y, 1)
        if !self.add_way(@way.x - steps_x, @way.y - steps_y, 7)
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go right
  # if not possible: tries to go upper right or lower right
  #-----------------------------------------------------------------------------
  def go_right(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x + steps_x, @way.y, 6)
      if !self.add_way(@way.x + steps_x, @way.y + steps_y, 3)
        if !self.add_way(@way.x + steps_x, @way.y - steps_y, 9)  
          return false
        end
      end
    end
    return true
  end

  #-----------------------------------------------------------------------------
  # tries to go up
  # if not possible: tries to upper left or upper right
  #-----------------------------------------------------------------------------
  def go_up(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x, @way.y - steps_y, 8)   
      if !self.add_way(@way.x - steps_x, @way.y - steps_y, 7)
        if !self.add_way(@way.x + steps_x, @way.y - steps_y, 9)     
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # tries to go down
  # if !possible: tries to lower left or lower right
  #-----------------------------------------------------------------------------
  def go_down(target_x, target_y)
    steps_x = $pixelmovement.isometric ? 4 : 2
    steps_y = 2
    
    if !self.add_way(@way.x, @way.y + steps_y, 2)  
      if !self.add_way(@way.x - steps_x, @way.y + steps_y, 1)
        if !self.add_way(@way.x + steps_x, @way.y + steps_y, 3)
          return false
        end
      end
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # adds new way (finally, if passable, and the new position hasnt been used
  #-----------------------------------------------------------------------------
  def add_way(x, y, d)
    if @event.passable?(@way.x, @way.y, d, 2) && !@coords.include?([x, y])
      @way = Game_Path.new(x, y, @way.path + [d])
      @coords += [[x, y]]
      return true
    else
      return false
    end
  end
  
end

#===============================================================================
# Class to save a Pathfinding path (including the path itself and the current
# position
#===============================================================================
class Game_Path
  attr_accessor :x
  attr_accessor :y
  attr_accessor :path
  attr_accessor :length
  
  def initialize (x, y, path, length = 0)
    @x = x
    @y = y
    @path = path
    @length = length
  end  
end