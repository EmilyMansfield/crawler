require_relative 'entities'

# Load items, creatures, and areas from the relevant
# JSON files. Yes it uses global variables, forgive me
def load_data
  $items = File.open("items.json") { |f| JSON.load f }
  $items.each do |k,v|
    type = k.split('_')[0].downcase
    if type == 'item'
      # Can't pass the JSON hash directly as the keys must be
      # symbols not strings, we must convert them first
      $items[k] = Item.new(v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v })
    elsif type == 'weapon'
      $items[k] = Weapon.new(v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v })
    elsif type == 'armor'
      $items[k] = Armor.new(v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v })
    end
  end

  $creatures = File.open("creatures.json") { |f| JSON.load f }
  $creatures.each do |k,v|
    $creatures[k] = Creature.new(v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v })
  end

  $areas = File.open("areas.json") { |f| JSON.load f }
  $areas.each do |k,v|
    $areas[k] = Area.new(v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v })
    # Can't use ids because creatures are different across areas, even if they
    # are the same type. Store a new instance of the actual creature instead
    if $areas[k].creatures
      $areas[k].creatures.map! { |x| [x, $creatures[x].dup] }
    end
  end
end

# Load saved data
def load(player_name)
  # Create a new player if that player doesn't exist
  unless File.exist?(player_name + ".json")
    return Player.new(name: player_name, hp: 15, strength: 4, agility: 4,
      evasion: 1.0/64, level: 1, xp: 0, area: "area_01") 
  end
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
      player = Player.new((v.each_with_object({}) { |(k,v),h| h[k.to_sym] = v }).merge!({name: player_name}))
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