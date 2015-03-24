class Item
  attr_reader :name, :description
  def initialize(opts)
    opts = {name: '', description: ''}.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
  end
end

class Weapon < Item
  attr_reader :damage
  def initialize(name, description, damage)
    super(name: name, description: description)
    @damage = damage
  end
end

class Armor < Item
  attr_reader :defense
  def initialize(name, description, defense)
    super(name: name, description: description)
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