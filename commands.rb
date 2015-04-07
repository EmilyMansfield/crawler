require_relative 'utility'
require_relative 'saving'

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
  parse_look(player, true, item_name)
end

def parse_look(player, at = nil, look_target = 'here')
  target = (at ? convert_command_target(player, look_target) : $areas[player.area])
  # If the player asked for the current area, display
  # a description for the area along with the doors
  # and the creatures
  if target == $areas[player.area]
    puts target.description
    unless target.doors.empty?
      print "There is "
      print format_list(target.doors, 'a #{self[0]} to the #{self[1]}')
      puts " here."
    end
    unless target.creatures.empty?
      print "There is "
      print format_list(target.creatures, 'a #{self[1].name}')
      puts " here."
    end
  elsif target != nil
    puts target.description
  else
    puts "You can't see a #{look_target} anywhere"
    return :invalid
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

def parse_search(player, container_name = nil)
  # Set the active container for the take command
  player.container = container_name || 'here'

  container = convert_command_target(player, container_name, true)

  if container.items.empty?
    puts "There is nothing here."
  else
    print "There #{container.items[0][1] == 1 ? 'is ' : 'are '}"
    print "nothing" if container.items.empty?
    print format_list(container.items, '#{self[1] == 1 ? "a " : ""}#{$items[self[0]].name(self[1])}')
    puts " here."
  end
end

def parse_take(player, item_name, from = nil, container_name = 'here')
  container = convert_command_target(player, container_name, true)
  item = container.items.find { |x| $items[x[0]].is_called? item_name }
  if item
    if container == player
      parse_equip(player, item_name)
    else
      puts "You take the #{$items[item[0]].name(item[1])}."
      player.items << item
      container.items.reject! { |x| x == item }
    end
  else
    puts "You can't find that item."
  end
end

def parse_exit(player)
  puts "Goodbye!"
  save(player)
  exit
end

def parse_strike(player)
  enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]
  damage = player.strike(enemy)
  if damage && damage > 0
    puts "You strike the #{enemy.name} for #{damage} damage."
  else
    puts "The #{enemy.name} evades your attack."
  end
end

def parse_flee(player)
  enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]
  if player.agility * rand >= enemy.agility * rand * 0.75
    # Choose a random exit
    door = $areas[player.area].doors.sample
    if door
      puts "You flee #{door[1].capitalize} through the #{door[0]}!"
      player.area = door[2]
      $displayed_description = false
      $mode = :explore # Less hacky way of doing this?
      :change_mode
    else
      puts "There's nowhere to run!"
    end
  else
    puts "The enemy blocks the way!"
  end
end