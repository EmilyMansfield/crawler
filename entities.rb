class Entity
  attr_reader :description
  def initialize(name = '', description = '', name_plural = nil)
    @name, @name_plural, @description = name, name_plural, description
    @name_plural ||= @name
  end

  def name(quantity = 1)
    if quantity.is_a?(Integer) && quantity > 1
      "#{quantity.to_s} #{@name_plural}"
    else
      @name
    end
  end

  def is_called?(name)
    @name.downcase == name || @name_plural.downcase == name.downcase
  end
end

class Item < Entity
  def initialize(opts)
    opts = { name: '', description: '' }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    super(opts[:name], opts[:description], opts[:name_plural])
  end
end

class Weapon < Item
  attr_reader :damage
  def initialize(opts)
    opts = { damage: '' }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    super(opts)
  end
end

class Armor < Item
  attr_reader :defense
  def initialize(opts)
    opts = { defense: '' }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    super(opts)
  end
end

class Creature < Entity
  attr_reader :xp
  attr_accessor :hp, :hp_max, :strength, :agility, :evasion, :weapon, :armor, :items, :hostile
  def initialize(opts)
    opts = { name: '', description: '', hp: 1, strength: 1, agility: 1,
      evasion: 0, xp: 0, weapon: nil, armor: nil, hostile: false, items: [] }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    @hp_max = @hp
    super(opts[:name], opts[:description], opts[:name_plural])
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
  attr_accessor :area, :container, :enemy, :level, :major_stat
  def initialize(opts)
    opts = { area: 'area_01', description: "It's you", container: 'here',
      enemy: nil, level: 1, major_stat: :strength }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    super(opts)
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
      stats = [
        [:@strength, "Strength", (@major_stat == :strength ? 8 : 6)],
        [:@agility, "Agility", (@major_stat == :agility ? 8 : 6)],
        [:@hp_max, "Health", 6*1.3]
      ]
      stats.each do |x|
        before = self.instance_variable_get(x[0])
        after = (before + 1 + x[2] * Math.tanh(@level / 30.0) * ((@level % 2) + 1)).to_i
        self.instance_variable_set(x[0], after)
        print x[1]
        print ' '*(stats.max{|a,b|a[1].length<=>b[1].length}[1].length-x[1].length+1)
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
  def initialize(opts)
    opts = { description: '', doors: [], items: [], creatures: [] }.merge(opts)
    opts.each { |k,v| instance_variable_set(('@'+k.to_s).to_sym, v) }
    @modified = false
  end
end