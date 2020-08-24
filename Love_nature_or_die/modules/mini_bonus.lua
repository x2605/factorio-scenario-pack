local mini_bonus = {}

local bonuses = {
  ['character_inventory_slots_bonus'] = 10,
  --['character_running_speed_modifier'] = 0.3 --antipollution���� �������� �����ϹǷ� �̻��
}

local enable_character_bonus = function(player)
  for k, bonus in pairs(bonuses) do
    player[k] = bonus
  end
end

local on_player_created = function(event)
  local player = game.players[event.player_index]
  enable_character_bonus(player)
end

local on_player_respawned = function(event)
  local player = game.players[event.player_index]
  enable_character_bonus(player)
end

mini_bonus.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
}

return mini_bonus