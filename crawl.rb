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
  attr_reader :name, :description, :xp
  attr_accessor :hp, :strength, :agility, :evasion, :weapon, :armor, :items, :hostile
  def initialize(name, description, hp, strength, agility, evasion, xp, weapon = nil, armor = nil, hostile = false)
    @name, @description = name, description
    @hp, @strength, @agility, @evasion, @xp = hp, strength, agility, evasion, xp
    @weapon, @armor, @hostile = weapon, armor, hostile
    @items = []
  end

  # Attack the target creature. Returns the damage done, or nil for a miss
  def strike(target)
    return nil unless target.is_a? Creature
    if rand > target.evasion
      attack = @strength + (@weapon ? $items[@weapon].damage : 0)
      defense = target.agility + (target.armor ? $items[target.armor].defense : 0)
      if rand(32) != 0
        damage_base = (attack - defense / 2.0)
        damage = rand((damage_base / 4)..(damage_base / 2)).to_i
        damage = rand(2) if damage < 1
      else
        damage = rand((attack/2)..(attack))
      end
      target.hp -= damage
      damage
    else
      nil
    end
  end
end

class Player < Creature
  attr_accessor :area, :container, :enemy, :level
  def initialize(name, hp, strength, agility, evasion, level, xp, area, container = 'here')
    super(name, "It's me", hp, strength, agility, evasion, xp)
    @area, @container, @enemy = area, container, nil
    @level = level
  end

  def increase_xp(xp)
    @xp += xp
    loop do
      break if @xp < 1.5*@level**3
      # Enough xp to level up
      @level += 1
      # This assignment is necessary as blocks/procs can't access their arguments
      # within themselves and we need to know the length of the longest
      # stat to tabulate correctly
      stats = [[:@strength, 6], [:@agility, 6], [:@hp, 6*1.3]]
      stats.each do |x|
        before = self.instance_variable_get(x[0])
        after = (before + 1 + x[1] * Math.tanh(@level / 30.0) * ((@level % 2) + 1)).to_i
        self.instance_variable_set(x[0], after)
        print x[0].to_s[1..-1].capitalize
        print ' '*(stats.max{|a,b|a[0].length<=>b[0].length}[0].length-x[0].length+1)
        puts "#{before}\t-> #{after}"
      end
    end
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
  attr_reader :description, :doors
  attr_accessor :items, :creatures, :modified
  def initialize(description, doors, items, creatures)
    @description, @doors, @items, @creatures = description, doors, items, creatures
    @modified = false
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
    v["strength"] || 1,
    v["agility"] || 1,
    v["evasion"] || 0,
    v["xp"] || 1,
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

# Load saved data
def load(player_name)
  # Create a new player if that player doesn't exist
  return Player.new(player_name, 15, 4, 4, 1.0/64, 1, 0, "area_01") unless File.exist?(player_name + ".json")
  player = nil
  $save_data = File.open(player_name + ".json") { |f| JSON.load f }
  $save_data.each do |k, v|
    if $areas.has_key? k
      # It's an area so modify the area with the data
      $areas[k].items = v["items"] if v["items"]
      $areas[k].creatures = v["creatures"].map { |x| [x, $creatures[x].dup] } if v["creatures"]
    elsif k == "player"
      # It's the player so create the player from the data
      # We use "player" as the key and not player_name to stop
      # id conflicts (accidental or deliberate)
      player = Player.new(
        player_name,
        v["hp"] || 15,
        v["strength"] || 4,
        v["agility"] || 4,
        v["evasion"] || 1.0/64,
        v["level"] || 1,
        v["xp"] || 0,
        v["area"] || "area_01")
      player.items = v["items"] if v["items"]
      player.weapon = v["weapon"] if v["weapon"]
      player.armor = v["armor"] if v["armor"]
    end
  end
  return player
end

# Save modified areas
def save(player)
  save_data = {}
  # Add the modified areas
  $areas.each do |k, v|
    save_data[k] = {"items" => v.items, "creatures" => v.creatures.map { |x| x[0] }} if v.modified
  end
  # Add the player
  save_data["player"] = {
    "hp" => player.hp,
    "strength" => player.strength,
    "agility" => player.agility,
    "evasion" => player.evasion,
    "level" => player.level,
    "xp" => player.xp,
    "area" => player.area,
    "items" => player.items
  }
  save_data["player"]["weapon"] = player.weapon if player.weapon
  save_data["player"]["armor"] = player.armor if player.armor
  File.open(player.name + ".json", "w") { |f| f.write(JSON.generate(save_data)) }
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

# Convert the command target into an actual object
def convert_command_target(player, target, containers_only = false)
  case target
  when 'here', 'the area', 'my surroundings'
    $areas[player.area]
  when 'me', 'myself', 'my bag'
    player
  else
    return $areas[player.area] if containers_only
    # Target type priority is
    # - Creature in the area
    # - Item in the player's surroundings
    # - Item in the player's current container
    # If still the target is not found, return nil
    if (creature = $areas[player.area].creatures.find { |x| x[1].name.downcase == target })
      creature[1]
    elsif (item = $areas[player.area].items.find { |x| $items[x[0]].name.downcase == target  })
      $items[item[0]]
    elsif (item = player.items.find { |x| $items[x[0]].name.downcase == target })
      $items[item[0]]
    else
      $areas[player.area]
    end
  end
end

puts "What's your name?"
$player = load(gets.chomp)
# explore - Movement and environment interaction
# combat - Fighting an enemy
$mode = :explore

$displayed_description = false
loop do
  if $player.hp <= 0
    puts "You die."
    exit
  end

  case $mode
  when :explore
    unless $displayed_description
      puts '-'*40
      parse_look($player)
      $areas[$player.area].modified = true
      $displayed_description = true
    end
    unless $areas[$player.area].creatures.empty?
      if (index = $areas[$player.area].creatures.index { |x| x[1].hostile })
        # Get the ID of enemy
        $player.enemy = $areas[$player.area].creatures[index][0]
        puts "The #{$creatures[$player.enemy].name} attacks!"
        $mode = :combat
        next
      end
    end
    print "> "
    redo if $mode_explore.parse($player, gets.chomp!) == :invalid
  when :combat
    print "~ "
    redo if $mode_combat.parse($player, gets.chomp!) == :invalid
    enemy_index = $areas[$player.area].creatures.index { |x| x[0] == $player.enemy }
    enemy = $areas[$player.area].creatures[enemy_index][1]
    # Enemy dies
    if enemy.hp <= 0
      puts "The #{enemy.name} dies."
      # Grant experience
      puts "You gain #{enemy.xp} experience."
      $player.increase_xp(enemy.xp)
      # Remove the dead enemy
      $areas[$player.area].creatures.delete_at(enemy_index)
      $mode = :explore
      next
    # Combat still ongoing
    else
      # Enemy attacks the player so deal damage
      damage = enemy.strike($player)
      if damage
        puts "The #{enemy.name} strikes you for #{damage} damage."
      else
        puts "You evade the attack."
      end
    end
  end
end