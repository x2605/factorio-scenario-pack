local revenge_tree = {}

--나무의 복수
local avenger = function(entity, whodid)
  if entity.type ~= 'tree' then
    return
  end
  local target = nil
  local name = nil
  local valid = false
  local pforce = 'neutral'
  if whodid then
    if whodid.valid then
      if whodid.force.name == 'enemy' then
        return
      elseif whodid.prototype.max_health > 0
        and whodid.can_be_destroyed()
        and whodid.destructible then
        valid = true
      end
    end
  end
  if valid then
    valid = math.sqrt((entity.position.x-whodid.position.x)^2 + (entity.position.y-whodid.position.y)^2) < 130
  end
  if valid then
    name = 'rocket'
    target = whodid
  else
    --name = 'explosive-rocket' 기지 다 뿌수는건 좀 아니다 생각했음 ㅋㅋ
    name = 'rocket'
    target = entity.surface.find_entities_filtered{
      position = entity.position,
      radius = 130,
      name = {'character', 'flamethrower-turret'},
      --개체 name 구분없었는데, 추가
      force = 'player'
    }
    if #target > 0 then
      local valid_targets = {}
      for _, t in pairs(target) do
        if t.prototype.max_health > 0
          and t.can_be_destroyed()
          and t.destructible then
          --주변에 화염방사 가능한 넘을 찾아서 요격
          if t.name == 'character' then
            local maininv = t.get_inventory(defines.inventory.character_main)
            local guninv = t.get_inventory(defines.inventory.character_guns)
            if maininv.find_item_stack('flamethrower')
              or maininv.find_item_stack('tank-flamethrower')
              or maininv.find_item_stack('flamethrower-ammo')
              or guninv.find_item_stack('flamethrower')
              or guninv.find_item_stack('tank-flamethrower')
              or t.get_inventory(defines.inventory.character_ammo).find_item_stack('flamethrower-ammo')
              then
              valid_targets[#valid_targets + 1] = t
            end
          elseif t.name == 'flamethrower-turret' then
            local fluid = t.get_fluid_contents()
            if fluid['crude-oil'] or fluid['light-oil'] or fluid['heavy-oil'] then
              valid_targets[#valid_targets + 1] = t
            end
          end
        end
      end
      if #valid_targets > 0 then
        --target = entity.surface.get_closest(entity.position, valid_targets)
        target = valid_targets[math.random(#valid_targets)]
      else
        target = {entity.position.x - 25 + math.random(0, 50), entity.position.y - 25 + math.random(0, 50)}
        name = 'distractor-capsule'
        pforce = 'enemy'
      end
    else
      target = {entity.position.x - 25 + math.random(0, 50), entity.position.y - 25 + math.random(0, 50)}
      name = 'distractor-capsule'
      pforce = 'enemy'
    end
  end
  local new=entity.surface.create_entity{
    name = name,
    position = entity.position,
    force = pforce,
    source = entity.position,
    target = target,
    speed = 0.1,
    max_range = 130
  }
end

local on_player_mined_entity = function(event)
  avenger(event.entity, game.players[event.player_index].character)
end

local on_robot_mined_entity = function(event)
  avenger(event.entity, event.robot)
end

local on_entity_died = function(event)
  avenger(event.entity, event.cause)
end


revenge_tree.events = {
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_robot_mined_entity] = on_robot_mined_entity,
  [defines.events.on_entity_died] = on_entity_died,
}

return revenge_tree