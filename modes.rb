require_relative 'commands'

def parse_explore(input, player = $player)
  # Can't figure out the single regex with no internet so I'm cheating and
  # splitting it up. Besides, it works well enough
  input = input.downcase.split(/(search|take|quit|examine|inspect|equip|wield|wear|look|go|n)\s+?(.*)/).delete_if { |x| x.empty? }
  input[-1] = input[-1].split(/\s+(from)\s+(.*)/).delete_if { |x| x.empty? }
  input.flatten!
  area = $areas[player.area]

  # search <container> - Lists items in the container
  if /search/ =~ input[0]
    parse_search(input[1], player)
  # take <item> - Take the specified item, if it is there
  elsif /take/ =~ input[0]
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return
    end

    container = convert_container(player.container, player)
    container = convert_container(input[3], player) if input[2] && input[2] == "from" && input[3]

    index = container.items.index { |x| $items[x[0]].name.downcase == input[1].downcase }
    if index
      if container == player
        parse_equip(input[1], player)
      else
        item = container.items[index][0]
        puts "You take the #{$items[item].name}."
        player.items << [item, container.items[index][1]]
        container.items.reject!.with_index { |x,i| i == index }
      end
    else
      puts "You can't find that item."
    end
  # wield/equip/wear <item> - Equip the specified item, assuming its
  # the right type
  elsif /wield|equip|wear/ =~ input[0]
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return
    end
    parse_equip(input[1], player)
  # examine/inspect <item> - Print a description of the item
  elsif /examine|inspect/ =~ input[0]
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return
    end
    parse_examine(input[1], player)
  # Go <direction> - Go through the door in the specified cardinal direction
  elsif /go/ =~ input[0]
    parse_go(input[1], player)
  # Look - Show the description of the current area
  elsif /look/ =~ input[0]
    parse_look(player)
  # quit - Exit the game
  elsif /quit|exit/ =~ input[0]
    puts "Goodbye!"
    exit
  else
    puts "Invalid command."
  end
end

def parse_combat(input, player = $player)
  input = input.downcase.split(/(attack|strike|equip|wield|examine|wear)\s+?(.*)/).delete_if { |x| x.empty? }
  enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]

  outcome = nil

  if /attack|strike/ =~ input[0]
    if rand < 0.9
      damage = (player.weapon ? $items[player.weapon].damage : 1)
      enemy.hp -= damage
      puts "You strike the #{enemy.name} for #{damage} damage."
    else
      puts "The #{enemy.name} evades your attack."
    end
  elsif /equip|wield|wear/ =~ input[0]
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return :invalid
    end
    outcome = parse_equip(input[1], player)
  elsif /examine|inspect/ =~ input[0]
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return :invalid
    end
    outcome = parse_examine(input[1], player)
  else
    puts "Invalid command."
    outcome = :invalid
  end

  if enemy.hp <= 0
    outcome = :enemy_slain
  elsif player.hp <= 0
    outcome = :player_slain
  end

  return outcome
end