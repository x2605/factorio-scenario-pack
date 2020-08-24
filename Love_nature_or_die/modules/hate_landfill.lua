local hate_landfill = {}

local on_built_tile = function(event)
  --¸Å¸³ÇÏ¸é ¶¥¹ú·¹°¡ ±â¾î³ª¿Â´Ù
  if not event.tile then
    return
  end
  if event.tile.name ~= 'landfill' then
    return
  end
  local surface = game.surfaces[event.surface_index]
  local evolution = game.forces['enemy'].evolution_factor
  local enemy = nil
  if evolution >= 0.9 then
    enemy = 'behemoth-worm-turret'
  elseif evolution >= 0.5 then
    enemy = 'big-worm-turret'
  elseif evolution >= 0.2 then
    enemy = 'medium-worm-turret'
  else
    enemy = 'small-worm-turret'
  end
  for _, tile in pairs(event.tiles) do
    if math.random() <= 0.15 then --15%È®·ü
      surface.create_entity{
        name = enemy,
        position = {tile.position.x + 0.5, tile.position.y + 0.5},
        force = 'enemy'
      }
    end
  end
end

hate_landfill.events = {
  [defines.events.on_player_built_tile] = on_built_tile,
  [defines.events.on_robot_built_tile] = on_built_tile,
}

return hate_landfill