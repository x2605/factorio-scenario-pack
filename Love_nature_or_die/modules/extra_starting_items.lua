local util = require("util")

local extra_starting_items = {}

local on_player_created = function(event)
  util.insert_safe(game.players[event.player_index], {
    ["iron-plate"] = 80,
    ["wood"] = 200,
    ["coal"] = 200,
    ["pistol"] = 1,
    ["firearm-magazine"] = 100,
    ["burner-mining-drill"] = 10,
    ["stone-furnace"] = 10,
  })
end

local on_player_respawned = function(event)
  util.insert_safe(game.players[event.player_index], {
    ["pistol"] = 1,
    ["firearm-magazine"] = 10,
    ["wood"] = 10,
  })
end

extra_starting_items.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_respawned] = on_player_respawned,
}

return extra_starting_items