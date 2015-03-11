def parse_equip(player, item_name)
  container = player
  # Get the id of the item from its name
  item = container.items.find { |x| $items[x[0]].name.downcase == item_name.downcase }
  if item
    # Ignore the quantity for now
    item = item[0]
    if $items[item].is_a? Weapon
      if player.weapon
        puts "You put away your #{$items[player.weapon].name} and wield the #{$items[item].name}."
      else
        puts "You wield the #{$items[item].name}"
      end
      player.weapon = item
    elsif $items[item].is_a? Armor
      if player.armor
        puts "You take off the #{$items[player.armor].name} and put on the #{$items[item].name}"
      else
        puts "You put on the #{$items[item].name}"
      end
      player.armor = item
    elsif $items[item].is_a? Item
      parse_examine(player, item_name)
    end
  else
    puts "You don't have that item."
    return :invalid # Ugly way of telling combat mode not to progress
  end
  return nil # More ugly combat mode hacks
end

def parse_examine(player, item_name)
  # Assume item is in the environment
  container = convert_container(player, player.container)

  item = container.items.find { |x| $items[x[0]].name.downcase == item_name.downcase }
  if item
    puts $items[item[0]].description
  else
    # Couldn't find the item in the environment, so try the player's bag
    container = player
    item = container.items.find { |x| $items[x[0]].name.downcase == item_name.downcase }
    if item
      puts $items[item[0]].description
    else
      puts "You can't see a #{item_name.capitalize} anywhere."
      return :invalid
    end
  end
  return nil # Nicer than a nil implicit return?
end

def parse_look(player)
  area = $areas[player.area]
  puts area.description
  unless area.doors.empty?
    print "There is "
    print format_list(area.doors, 'a #{self[0]} to the #{self[1]}') 
    puts " here."
  end
  unless area.creatures.empty?
    print "There is "
    print format_list(area.creatures, 'a #{self[1].name}')
    puts " here."
  end
end

def parse_go(player, dir)
  dir = {"n"=>"north", "e"=>"east", "s"=>"south", "w"=>"west"}[dir] || dir
  index = $areas[player.area].doors.index { |x| x[1].downcase == dir }
  if index
    puts "You head #{dir.capitalize} through the #{$areas[player.area].doors[index][0]}."
    player.area = $areas[player.area].doors[index][2]
    $displayed_description = false
  else
    puts "You cannot go in that direction."
  end
end

def parse_search(player, container_name)
  # Set the active container for the take command
  player.container = container_name || 'here'

  container = convert_container(player, container_name)

  print "There is "
  print "nothing" if container.items.empty?
  print format_list(container.items, 'a #{$items[self[0]].name}')
  puts " here."
end

def parse_take(player, item_name, from = nil, container_name = nil)
  container = convert_container(player, (from ? container_name : player.container))

  item = container.items.find { |x| $items[x[0]].name.downcase == item_name.downcase }
  # index = container.items.index { |x| $items[x[0]].name.downcase == input[1].downcase }
  # if index
  if item
    if container == player
      parse_equip(player, item_name)
    else
      # item = container.items[index][0]
      puts "You take the #{$items[item[0]].name}."
      player.items << [item[0], item[1]]
      container.items.reject! { |x| x == item }
    end
  else
    puts "You can't find that item."
  end
end