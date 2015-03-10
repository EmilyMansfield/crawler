#!/usr/bin/ruby
require 'json'

class Item
  attr_reader :name, :description
  def initialize(name, description)
    @name = name
    @description = description
  end
end

class Weapon < Item
  attr_reader :damage
  def initialize(name, description, damage)
    super(name, description)
    @damage = damage
  end
end

class Armor < Item
  attr_reader :defense
  def initialize(name, description, defense)
    super(name, description)
    @defense = defense
  end
end

class Creature
  attr_reader :name
  attr_accessor :hp, :weapon, :armor, :items, :hostile
  def initialize(name, hp, weapon = nil, armor = nil, hostile = false)
    @name, @hp, @weapon, @armor, @hostile = name, hp, weapon, armor, hostile
    @items = []
  end
end

# Description - String containing a description of the area
# without it's interactable contents
# Doors - Array containing all doors in the area which have
# the structure [description, location, target], where target is a
# string id for another area and location is a cardinal direction
# Items - Array of arrays of form [id, quantity]
# Creatures - Array of actual creatures in the area, NOT ids
class Area
  attr_reader :description, :doors, :items, :creatures
  def initialize(description, doors, items, creatures)
    @description, @doors, @items, @creatures = description, doors, items, creatures
  end
end

$items = JSON.load(File.open("items.json", "r"))
$items.each do |k,v|
  type = k.split('_')[0].downcase
  if type == 'item'
    $items[k] = Item.new(v["name"], v["description"] || "")
  elsif type == 'weapon'
    $items[k] = Weapon.new(v["name"], v["description"] || "", v["damage"])
  elsif type == 'armor'
    $items[k] = Armor.new(v["name"], v["description"] || "", v["defense"])
  end
end

$creatures = JSON.load(File.open("creatures.json", "r"))
$creatures.each do |k,v|
  $creatures[k] = Creature.new(
    v["name"] || "",
    v["hp"] || 1,
    v["weapon"],
    v["armor"],
    v["hostile"] || false)
end

$areas = JSON.load(File.open("areas.json", "r"))
$areas.each do |k,v|
  $areas[k] = Area.new(
    v["description"] || "",
    v["doors"] || [],
    v["items"] || [],
    v["creatures"] || [])
  if $areas[k].creatures
    $areas[k].creatures.map! { |x| [x, $creatures[x].dup] }
  end
end

# Prints the contents of the array using the format string fmt_str but adds
# natural english connectives. fmt_str must use self as the interpolation
# variable, and should be escaped accordingly
def format_list(array, fmt_str)
  str = ""
  array.each.with_index do |x, i|
    if array.length == 1
      x.instance_eval("str << \"#{fmt_str}\"")
    elsif i == array.length - 1
      x.instance_eval("str << \"and #{fmt_str}\"")
    else
      x.instance_eval("str << \"#{fmt_str}, \"")
    end
  end
  str
end

def parse_container(container, player = $player)
  case container
  when 'here', 'the area'
    $areas[player[1]]
  when 'me', 'myself', 'my bag'
    player[0]
  else
    $areas[player[1]]
  end
end

def parse_equip(item_name, player = $player)
  container = player[0]
  # Get the id of the item from its name
  item = container.items.find { |x| $items[x[0]].name.downcase == item_name.downcase }
  if item
    # Ignore the quantity for now
    item = item[0]
    if $items[item].is_a? Weapon
      if player[0].weapon
        puts "You put away your #{$items[player[0].weapon].name} and wield the #{$items[item].name}."
      else
        puts "You wield the #{$items[item].name}"
      end
      player[0].weapon = item
    elsif $items[item].is_a? Armor
      if player[0].armor
        puts "You take off the #{$items[player[0].armor].name} and put on the #{$items[item].name}"
      else
        puts "You put on the #{$items[item].name}"
      end
      player[0].armor = item
    elsif $items[item].is_a? Item
      parse_examine(item, player)
    end
  else
    puts "You don't have that item."
  end
end


def parse_examine(item, player = $player)
  puts $items[item].description
end

def parse_look(player = $player)
  area = $areas[player[1]]
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

def parse_go(dir, player = $player)
  dir = {"n"=>"north", "e"=>"east", "s"=>"south", "w"=>"west"}[dir] || dir
  index = $areas[player[1]].doors.index { |x| x[1].downcase == dir }
  if index
    puts "You head #{dir.capitalize} through the #{$areas[player[1]].doors[index][0]}."
    player[1] = $areas[player[1]].doors[index][2]
    $displayed_description = false
  else
    puts "You cannot go in that direction."
  end
end

def parse_explore(input, player = $player)
  # Can't figure out the single regex with no internet so I'm cheating and
  # splitting it up. Besides, it works well enough
  input = input.downcase.split(/(search|take|quit|examine|inspect|equip|wield|wear|look|go|n)\s+?(.*)/).delete_if { |x| x.empty? }
  input[-1] = input[-1].split(/\s+(from)\s+(.*)/).delete_if { |x| x.empty? }
  input.flatten!
  area = $areas[player[1]]

  # search <container> - Lists items in the container
  if input[0] == 'search'

    container = parse_container(input[1], player)

    # Set the active container for the take command
    player[2] = input[1] || 'here'

    print "There is "
    print "nothing" if container.items.empty?
    print format_list(container.items, 'a #{$items[self[0]].name}')
    puts " here."
  # take <item> - Take the specified item, if it is there
  elsif input[0] == "take"
    container = parse_container(player[2], player)
    container = parse_container(input[3], player) if input[2] && input[2] == "from" && input[3]

    unless input[1]
      puts "Take what?"
      return
    end

    index = container.items.index { |x| $items[x[0]].name.downcase == input[1].downcase }
    if index
      if container == player[0]
        item = container.items[index][0]
        parse_equip(item, player)
      else
        item = container.items[index][0]
        puts "You take the #{$items[item].name}."
        player[0].items << [item, container.items[index][1]]
        container.items.reject!.with_index { |x,i| i == index }
      end
    else
      puts "You can't find that item."
    end
  # wield/equip/wear <item> - Equip the specified item, assuming its
  # the right type
  elsif input[0] == "wield" || input[0] == "equip" || input[0] == "wear"
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return
    end
    parse_equip(input[1], player)
  # examine/inspect <item> - Print a description of the item
  elsif input[0] == "examine" || input[0] == "inspect"
    # Assume item is in the environment
    container = parse_container(player[2], player)

    unless input[1]
      puts "#{input[0].capitalize} what?"
      return
    end
    item = container.items.find { |x| $items[x[0]].name.downcase == input[1].downcase }
    if item
      parse_examine(item[0], player)
    else
      # Couldn't find the item in the environment, so try the player's bag
      container = player[0]
      item = container.items.find { |x| $items[x[0]].name.downcase == input[1].downcase }
      if item
        parse_examine(item[0], player)
      else
        puts "You can't see a #{input[1].capitalize} anywhere."
        return
      end
    end
  # Go <direction> - Go through the door in the specified cardinal direction
  elsif input[0] == "go"
    parse_go(input[1], player)
  # Look - Show the description of the current area
  elsif input[0] == "look"
    parse_look(player)
  # quit - Exit the game
  elsif input[0] == 'quit'
    puts "Goodbye!"
    exit
  else
    puts "Invalid command."
  end
end

def parse_combat(input, player = $player)
  input = input.downcase.split(/(attack|strike|equip|wield|examine|wear)\s+?(.*)/).delete_if { |x| x.empty? }
  enemy = $areas[player[1]].creatures.find { |x| x[0] == player[3] }[1]

  outcome = nil

  if input[0] ==  "attack" || input[0] == "strike"
    if rand < 0.9
      damage = (player[0].weapon ? $items[player[0].weapon].damage : 1)
      enemy.hp -= damage
      puts "You strike the #{enemy.name} for #{damage} damage."
    else
      puts "The #{enemy.name} evades your attack."
    end
  elsif input[0] == "equip" || input[0] == "wield" || input[0] == "wear" || input[0] == "examine"
    unless input[1]
      puts "#{input[0].capitalize} what?"
      return :invalid
    end
    index = player[0].items.index { |x| $items[x[0]].name.downcase == input[1].downcase }
    if index
      parse_equip(player[0].items[index][0])
    else
      puts "You don't have that item."
      return :invalid
    end
  else
    puts "Invalid command."
    outcome = :invalid
  end

  if enemy.hp <= 0
    outcome = :enemy_slain
  elsif player[0].hp <= 0
    outcome = :player_slain
  end

  return outcome
end

puts "What's your name?"
# [class, current area, last container, last enemy id]
# Note here we use an enemy ID not the enemy itself, this id is relative to
# the current area
$player = [Creature.new(gets.chomp, rand(4)+4), "area_01", "here", nil]

# explore - Movement and environment interaction
# combat - Fighting an enemy
$mode = :explore

$displayed_description = false
loop do
  case $mode
  when :explore
    unless $displayed_description
      puts '-'*40
      parse_look($player)
      $displayed_description = true
      unless $areas[$player[1]].creatures.empty?
        if (index = $areas[$player[1]].creatures.index { |x| x[1].hostile })
          $player[3] = $areas[$player[1]].creatures[index][0]
          puts "The #{$creatures[$player[3]].name} attacks!"
          $mode = :combat
          next
        end
      end
    end
    print "> "
    parse_explore(gets.chomp!)
  when :combat
    print "~ "
    case parse_combat(gets.chomp!)
    when nil
      enemy = $areas[$player[1]].creatures.find { |x| x[0] == $player[3] }[1]
      if rand < 0.9
        damage = (enemy.weapon ? $items[enemy.weapon].damage : 1)
        $player[0].hp -= damage
        puts "The #{enemy.name} strikes you for #{damage} damage."
      else
        puts "You evade the attack."
      end
      if $player[0].hp <= 0
        puts "You die."
        exit
      end
    when :enemy_slain
      enemy = $areas[$player[1]].creatures.find { |x| x[0] == $player[3] }[1]
      puts "The #{enemy.name} dies."
      $areas[$player[1]].creatures.delete_if { |x| x[0] == $player[3] }
      $mode = :explore
      next
    when :player_slain
      puts "You die."
      exit
    end
  end
end