local nbo_res = {}

local allowed_types = {
        'resource',
        'transport-belt',
        'underground-belt',
        'electric-pole',
        'mining-drill',
        'pipe',
        'pipe-to-ground',
        'car',
        'locomotive',
        'cargo-wagon',
        'fluid-wagon',
        'artillerty-wagon',
        'construction-robot',
        'logistic-robot',
}

local spill_item_stack = function(inv, player)
  if inv then
    for name, count in pairs(inv.get_contents()) do
      player.surface.spill_item_stack(player.position, {name = name, count = count}, true, player.force, false)
    end
  end
end

local on_built_entity = function(event)
  local entity = event.created_entity
  local area = entity.bounding_box
  if area.left_top == area.right_bottom then
    return
  end

  local count = entity.surface.count_entities_filtered{
    area = area,
    type = 'resource',
    limit = 1
  }
  if count < 1 then
    return
  end

  local type = entity.type
  local is_ghost = false
  if type == 'entity-ghost' then
    type = entity.ghost_type
    is_ghost = true
  end
  local is_allowed = false
  if is_ghost then
    for _, v in pairs(allowed_types) do
      if entity.ghost_type == v then
        is_allowed = true
        break
      end
    end
  else
    for _, v in pairs(allowed_types) do
      if entity.type == v then
        is_allowed = true
        break
      end
    end
  end

  if is_allowed then
    return
  end

  local player = game.players[event.player_index]
  if not is_ghost and not is_allowed then
    local inv = {}
    local item = entity.prototype.items_to_place_this
    if item == nil then
      return
    end
    local name = item[1].name
    local count = item[1].count
    --오토필 모드 사용 대비
    if type == 'ammo-turret' then
      inv = entity.get_inventory(defines.inventory.turret_ammo)
      spill_item_stack(inv, player)
    elseif type == 'artillery-turret' then
      inv = entity.get_inventory(defines.inventory.artillery_turret_ammo)
      spill_item_stack(inv, player)
    elseif type == 'assembling-machine' or type == 'rocket-silo' then
      inv = entity.get_inventory(defines.inventory.assembling_machine_input)
      spill_item_stack(inv, player)
      inv = entity.get_inventory(defines.inventory.assembling_machine_modules)
      spill_item_stack(inv, player)
    elseif type == 'furnace' then
      inv = entity.get_inventory(defines.inventory.fuel)
      spill_item_stack(inv, player)
      inv = entity.get_inventory(defines.inventory.furnace_source)
      spill_item_stack(inv, player)
      inv = entity.get_inventory(defines.inventory.furnace_modules)
      spill_item_stack(inv, player)
    elseif type == 'boiler' then
      inv = entity.get_inventory(defines.inventory.fuel)
      spill_item_stack(inv, player)
    elseif type == 'lab' then
      inv = entity.get_inventory(defines.inventory.lab_input)
      spill_item_stack(inv, player)
      inv = entity.get_inventory(defines.inventory.lab_modules)
    elseif type == 'beacon' then
      inv = entity.get_inventory(defines.inventory.beacon_modules)
      spill_item_stack(inv, player)
    elseif type == 'container' or type == 'logistic-container' then
      inv = entity.get_inventory(defines.inventory.chest)
      spill_item_stack(inv, player)
    end

    if player.can_insert{name = name, count = count} then
      player.insert{name = name, count = count}
    else
      player.surface.spill_item_stack(player.position, {name = name, count = count}, true, player.force, false)
    end
  end
  if not is_allowed then
    player.print({"no_base_on_resource.inform2"})
    player.surface.create_entity{
      name = 'flying-text',
      position = entity.position,
      text = {"no_base_on_resource.inform"},
      color = {0.5, 1, 1, 1},
      render_player_index = event.player_index
    }
    entity.destroy()
  end
end

nbo_res.events = {
  [defines.events.on_built_entity] = on_built_entity,
}

return nbo_res