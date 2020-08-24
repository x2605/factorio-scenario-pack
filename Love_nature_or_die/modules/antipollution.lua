local antipollution = {}

antipollution.on_load = function()
  if not global.antipollution__is_initiated then
    --초기화
    global.antipollution__threshold = 100 --피해가 발생하기 시작하는 최소 공해
    global.antipollution__threshold_count = 0
    global.antipollution__max = 0
    global.antipollution__chunks_to_process_next_tick = {} --데미지 처리 틱 동안 처리할 총버퍼
    global.antipollution__chunks_to_process_next_tick_n = 0 --총버퍼 갯수
    global.antipollution__chunk_unit_count = 0 --총버퍼를 div로 쪼갠 갯수
    global.antipollution__chunk_unit_div = 0 --쪼개진 버퍼 1개당 들어있는 청크 수
    global.antipollution__chunk_unit_i = 0 --청크 번지수
    global.antipollution__chunk_unit_ci = 0 --쪼개진 버퍼 번지수
    global.antipollution__surface = game.surfaces[1] --이 기능을 사용할 지면. 모드에 따라 다른 코드 작성 필요

    --공해를 끈다고? 도로 켜주지. 기본설정보다 쉽게 만들어버렸으면 기본설정으로.
    --일부 설정은 기본과 다르게 고정시킴.
    if not game.map_settings.pollution.enabled then
      game.map_settings.pollution.enabled = true
    end
    if game.map_settings.pollution.diffusion_ratio < 0.02 then
      game.map_settings.pollution.diffusion_ratio = 0.02
    end
    if game.map_settings.pollution.min_to_diffuse < 15 then
      game.map_settings.pollution.min_to_diffuse = 15
    end
    if game.map_settings.pollution.ageing < 1 then
      game.map_settings.pollution.ageing = 1
    end
    if game.map_settings.pollution.expected_max_per_chunk < 50 then
      game.map_settings.pollution.expected_max_per_chunk = 50
    end
    if game.map_settings.pollution.min_pollution_to_damage_trees > 60 then
      game.map_settings.pollution.min_pollution_to_damage_trees = 60
    end
    if game.map_settings.pollution.pollution_with_max_forest_damage < 150 then
      game.map_settings.pollution.pollution_with_max_forest_damage = 150
    end
    if game.map_settings.pollution.pollution_per_tree_damage > 10 then
      game.map_settings.pollution.pollution_per_tree_damage = 10
    end
    if game.map_settings.pollution.pollution_restored_per_tree_damage < 10 then
      game.map_settings.pollution.pollution_restored_per_tree_damage = 10
    end
    if game.map_settings.pollution.max_pollution_to_restore_trees > 20 then
      game.map_settings.pollution.max_pollution_to_restore_trees = 20
    end
    if game.map_settings.pollution.enemy_attack_pollution_consumption_modifier ~= 1
      or game.map_settings.pollution.enemy_attack_pollution_consumption_modifier ~= 0.1 then
      game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1
    end
    --연구 큐를 안켰다고? 켜주지.
    if not game.forces['player'].research_queue_enabled then
      game.forces['player'].research_queue_enabled = true
    end
    --확장 설정 개 에바로 만들어주지. 대신 공해 심할때만 활성화
    if game.map_settings.enemy_expansion.max_expansion_distance < 20 then
      game.map_settings.enemy_expansion.max_expansion_distance = 20
    end
    if game.map_settings.enemy_expansion.settler_group_max_size < 50 then
      game.map_settings.enemy_expansion.settler_group_max_size = 50
    end
    if game.map_settings.enemy_expansion.settler_group_min_size < 20 then
      game.map_settings.enemy_expansion.settler_group_min_size = 20
    end
    game.map_settings.enemy_expansion.min_expansion_cooldown = 600 -- 최소생성시간 10초, 이거 악랄하지않냐
    game.map_settings.enemy_expansion.max_expansion_cooldown = 3600 -- 최대생성시간 60초
      -- cooldown is calculated as follows:
      --   cooldown = lerp(max_expansion_cooldown, min_expansion_cooldown, -e^2 + 2 * e),
      -- where lerp is the linear interpolation function, and e is the current evolution factor.
    game.map_settings.enemy_expansion.friendly_base_influence_radius = 1
    game.map_settings.enemy_expansion.enemy_building_influence_radius = 1
    game.map_settings.enemy_expansion.building_coefficient = 0.001
    game.map_settings.enemy_expansion.other_base_coefficient = 1.0
    game.map_settings.enemy_expansion.neighbouring_chunk_coefficient = 0.005
    game.map_settings.enemy_expansion.neighbouring_base_chunk_coefficient = 0.2
      -- A candidate chunk's score is given as follows:
      --   player = 0
      --   for neighbour in all chunks within enemy_building_influence_radius from chunk:
      --     player += number of player buildings on neighbour
      --             * building_coefficient
      --             * neighbouring_chunk_coefficient^distance(chunk, neighbour)
      --
      --   base = 0
      --   for neighbour in all chunk within friendly_base_influence_radius from chunk:
      --     base += num of enemy bases on neighbour
      --           * other_base_coefficient
      --           * neighbouring_base_chunk_coefficient^distance(chunk, neighbour)
      --
      --   score(chunk) = 1 / (1 + player + base)
      --
      -- The iteration is over a square region centered around the chunk for which the calculation is done,
      -- and includes the central chunk as well. distance is the Manhattan distance, and ^ signifies exponentiation.
    game.map_settings.enemy_expansion.max_colliding_tiles_coefficient = 0.9
    --진화도 재설정
    if not game.map_settings.enemy_evolution.enabled then
      game.map_settings.enemy_evolution.enabled = true
    end
    game.map_settings.enemy_evolution.time_factor = 0.0000001
    if game.map_settings.enemy_evolution.destroy_factor < 0.001 then
      game.map_settings.enemy_evolution.destroy_factor = 0.001
    end
    if game.map_settings.enemy_evolution.pollution_factor < 0.0000009 then
      game.map_settings.enemy_evolution.pollution_factor = 0.0000009
    end
    if game.map_settings.enemy_expansion.enabled then
      game.map_settings.enemy_expansion.enabled = false
    end
    global.antipollution__is_initiated = true
  end
end

antipollution.on_init = function()
  antipollution.on_load()
end

local entity_check = function(entity)
  if entity.prototype.max_health <= 0 then return end
  if not entity.can_be_destroyed() then return end
  if not entity.destructible then return end
  return true
end

local on_tick = function()
  if not global.antipollution__is_initiated then return end
  local tickmod = game.tick % 180
  if tickmod == 0 then
    local pollution = 0
    local fly_damage = 0
    local ground_damage = 0
    local ucount = 0
    global.antipollution__threshold_count = 0
    global.antipollution__max = 0
    global.antipollution__chunks_to_process_next_tick = {}

    for chunk in global.antipollution__surface.get_chunks() do
      pollution = global.antipollution__surface.get_pollution{chunk.x*32, chunk.y*32}

      if pollution > global.antipollution__max then
        global.antipollution__max = pollution
      end

      if pollution > global.antipollution__threshold then
        global.antipollution__threshold_count = global.antipollution__threshold_count + 1
        global.antipollution__chunks_to_process_next_tick[#global.antipollution__chunks_to_process_next_tick + 1] = {chunk.area, pollution}
      end
    end
    ucount = #global.antipollution__chunks_to_process_next_tick
    if ucount ~= 0 then
      global.antipollution__chunk_unit_div = (ucount - ucount % 177)/177 + 1
      global.antipollution__chunk_unit_count = math.ceil(ucount/global.antipollution__chunk_unit_div)
    else
      global.antipollution__chunk_unit_count = 0
    end
    global.antipollution__chunk_unit_i = 0
    global.antipollution__chunk_unit_ci = 0
    global.antipollution__chunks_to_process_next_tick_n = ucount

  elseif tickmod == 90 then
    --공해가 심한 청크의 존재여부에 따라서 적들의 공세와 확장이 극단적으로 변경
    if global.antipollution__threshold_count == 0 then
      --최대 공해 낮을 수록 이동속도 버프 무려 최대 2.25배다
      local modifier = 1.25 * (global.antipollution__threshold - global.antipollution__max)/global.antipollution__threshold
      for _, player in pairs(game.connected_players) do
        if player.character then player.character_running_speed_modifier = modifier end
      end
      if game.map_settings.enemy_expansion.enabled then
        game.map_settings.enemy_expansion.enabled = false
        game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1
        game.map_settings.enemy_evolution.pollution_factor = 0.0000009
        game.print{"antipollution.safe"}
        log{'\n[antipollution] expansion deactivated'}
      end
    else
      --임계치 초과시 이동속도 버프 제거
      for _, player in pairs(game.connected_players) do
        if player.character then player.character_running_speed_modifier = 0 end
      end
      if not game.map_settings.enemy_expansion.enabled then
        game.map_settings.enemy_expansion.enabled = true
        game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.1
        game.map_settings.enemy_evolution.pollution_factor = 0.000018
        game.print{"antipollution.warning"}
        log{'\n[antipollution] expansion activated via high pollution'}
      end
    end

  elseif global.antipollution__chunk_unit_count ~= 0 then
    local i = 0
    global.antipollution__chunk_unit_ci = global.antipollution__chunk_unit_ci + 1
    if global.antipollution__chunk_unit_ci > global.antipollution__chunk_unit_count then
      return
    end
    while i <= global.antipollution__chunk_unit_div do
      i = i + 1
      global.antipollution__chunk_unit_i = global.antipollution__chunk_unit_i + 1
      if global.antipollution__chunk_unit_i > global.antipollution__chunks_to_process_next_tick_n then
        return
      end

      --비행유닛은 30배 데미지. 수리하면서 버티기 힘들게 하겠다.
      fly_damage = 9 + (
          global.antipollution__chunks_to_process_next_tick[global.antipollution__chunk_unit_i][2]
          - global.antipollution__threshold
        )/5.555
      ground_damage = fly_damage / 30

      for _, entity in pairs(global.antipollution__surface.find_entities_filtered{
          area = global.antipollution__chunks_to_process_next_tick[global.antipollution__chunk_unit_i][1],
          type = {'entity-ghost', 'wall', 'gate'},
          force = {'enemy', 'neutral'},
          invert = true
        }) do
        if entity_check(entity) then
          if not entity.prototype.collision_mask then
            entity.damage(fly_damage, 'neutral', 'acid')
          else
            entity.damage(ground_damage, 'neutral', 'acid')
          end
        end
      end
    end
    
  end
end

--공해 경보인 경우, 스포너는 한번에 여러마리를 뱉는다.
local on_entity_spawned = function(event)
  if event.spawner.type ~= 'unit-spawner' then return end
  if not event.entity.valid then return end
  if game.map_settings.enemy_expansion.enabled then
    local i = 1
    while i <= 3 do --3이면 3마리가 추가로 생성
      event.entity.clone{
        position = event.entity.position,
        surface = event.entity.surface,
        force = event.entity.force
      }
      i = i + 1
    end
  end
end

local units = {
  ['small-biter'] = {child = nil, acid = 'acid-stream-spitter-small', range = 0, amount = 0},
  ['medium-biter'] = {child = 'small-biter', acid = 'acid-stream-spitter-small', range = 3, amount = 3},
  ['big-biter'] = {child = 'medium-biter', acid = 'acid-stream-spitter-medium', range = 5, amount = 3},
  ['behemoth-biter'] = {child = 'big-biter', acid = 'acid-stream-spitter-big', range = 7, amount = 4},
  ['small-spitter'] = {child = nil, acid = 'acid-stream-spitter-small', range = 11, amount = 5},
  ['medium-spitter'] = {child = nil, acid = 'acid-stream-spitter-medium', range = 18, amount = 7},
  ['big-spitter'] = {child = nil, acid = 'acid-stream-spitter-big', range = 25, amount = 10},
  ['behemoth-spitter'] = {child = nil, acid = 'acid-stream-spitter-behemoth', range = 40, amount = 13}
}
--공해 경보시 적이 주그면 일어나는 부가효과
local on_entity_died = function(event)
  if not game.map_settings.enemy_expansion.enabled then return end
  if event.entity.type ~= 'unit' then return end
  if units[event.entity.name] then
    local surface = event.entity.surface
    local born = units[event.entity.name]
    local i = 0
    local c = 0
    if born.child then
      i = 0
      c = math.random(2,4)
      while i < c do
        surface.create_entity{
          name = born.child,
          position = event.entity.position,
          force = event.entity.force
        }
        i = i + 1
      end
    end
    if born.acid then
      i = 0
      c = born.amount + math.random(0,2)
      while i < c do
        surface.create_entity{
          name = born.acid,
          position = event.entity.position,
          force = event.entity.force,
          speed = 4,
          max_range = born.range,
          source = event.entity.position,
          target = {
            event.entity.position.x - born.range/2 + math.random()*born.range,
            event.entity.position.y - born.range/2 + math.random()*born.range
          }
        }
        i = i + 1
      end
    end
  end
end

local antipoll_gui = require("modules.antipollution_gui")
antipollution.events = {
  [defines.events.on_tick] = function(event)
    on_tick(event)
    antipoll_gui.events[defines.events.on_tick](event)
  end,
  [defines.events.on_player_created] = function(event)
    antipoll_gui.events[defines.events.on_player_created](event)
  end,
  [defines.events.on_entity_spawned] = on_entity_spawned,
  [defines.events.on_entity_died] = on_entity_died,
}

return antipollution