#!/usr/bin/ruby
require 'json'

require_relative 'modes'

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
  attr_reader :name, :description
  attr_accessor :hp, :weapon, :armor, :items, :hostile
  def initialize(name, description, hp, weapon = nil, armor = nil, hostile = false)
    @name, @description, = name, description
    @hp, @weapon, @armor, @hostile = hp, weapon, armor, hostile
    @items = []
  end
end

class Player < Creature
  attr_accessor :area, :container, :enemy
  def initialize(name, hp, area, container = 'here')
    super(name, hp)
    @area, @container, @enemy = area, container, nil
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

$items = File.open("items.json") { |f| JSON.load f }
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

$creatures = File.open("creatures.json") { |f| JSON.load f }
$creatures.each do |k,v|
  $creatures[k] = Creature.new(
    v["name"] || "",
    v["description"] || "",
    v["hp"] || 1,
    v["weapon"],
    v["armor"],
    v["hostile"] || false)
end

$areas = File.open("areas.json") { |f| JSON.load f }
$areas.each do |k,v|
  $areas[k] = Area.new(
    v["description"] || "",
    v["doors"] || [],
    v["items"] || [],
    v["creatures"] || [])
  # Can't use ids because creatures are different across areas, even if they
  # are the same type. Store a new instance of the actual creature instead
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

# Convert the name of a container into the container itself
def convert_container(player, container_name)
  case container_name
  when 'here', 'the area'
    $areas[player.area]
  when 'me', 'myself', 'my bag'
    player
  else
    $areas[player.area]
  end
end

puts "What's your name?"
$player = Player.new(gets.chomp, rand(4)+4, "area_01")

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
    end
    unless $areas[$player.area].creatures.empty?
      if (index = $areas[$player.area].creatures.index { |x| x[1].hostile })
        $player.enemy = $areas[$player.area].creatures[index][0]
        puts "The #{$creatures[$player.enemy].name} attacks!"
        $mode = :combat
        next
      end
    end
    print "> "
    parse_explore($player, gets.chomp!)
  when :combat
    print "~ "
    case parse_combat($player, gets.chomp!)
    when nil
      enemy = $areas[$player.area].creatures.find { |x| x[0] == $player.enemy }[1]
      if rand < 0.9
        damage = (enemy.weapon ? $items[enemy.weapon].damage : 1)
        $player.hp -= damage
        puts "The #{enemy.name} strikes you for #{damage} damage."
      else
        puts "You evade the attack."
      end
      if $player.hp <= 0
        puts "You die."
        exit
      end
    when :enemy_slain
      enemy_index = $areas[$player.area].creatures.index { |x| x[0] == $player.enemy }
      enemy = $areas[$player.area].creatures[enemy_index][1]
      puts "The #{enemy.name} dies."
      $areas[$player.area].creatures.delete_at(enemy_index)
      $mode = :explore
      next
    when :player_slain
      puts "You die."
      exit
    end
  end
end