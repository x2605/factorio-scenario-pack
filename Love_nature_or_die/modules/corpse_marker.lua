local corpse_marker = {}
--시체 마커

local on_player_died = function(event)
  local player = game.players[event.player_index]
  local cause_message = ''
  if event.cause then
    cause_message = ' by ' .. event.cause.name
  end
  log('\n[PLAYER-DIE] ' .. player.name .. ' is dead' .. cause_message .. '.')
  player.force.add_chart_tag(
    player.surface,
    {
        icon = {
          type = 'item',
          name = 'heavy-armor'
        },
        position = player.position,
        text = '[font=default-tiny-bold]' .. player.name .. '  [/font]'
    }
  )
end

--시체 마커가 달은 지도 태그인지 검사
local is_valid_tag = function(tag, pname)
	if not tag.icon then
    return false
  end
	if tag.icon.type ~= 'item' then
    return false
  end
	if tag.icon.name ~= 'heavy-armor' then
    return false
  end
	if tag.text == '[font=default-tiny-bold]' .. pname .. '  [/font]' then
    return true
  else
    return false
  end
end


--시체 남이 열어보는거 알려주는 기능은 좋다고 생각해서 추가
local on_character_corpse_expired = function(event)
  if event.corpse.character_corpse_player_index then
    if event.corpse.character_corpse_player_index > #game.players then return end
    local player = game.players[event.corpse.character_corpse_player_index]
    for _, tag in pairs(player.force.find_chart_tags(
      event.corpse.surface,
      {
        {event.corpse.position.x - 0.5, event.corpse.position.y - 0.5},
        {event.corpse.position.x + 0.5, event.corpse.position.y + 0.5}
      })) do
      if is_valid_tag(tag, player.name) then
        tag.destroy()
        break
      end
    end
  end
end

local on_pre_player_mined_item = function(event)
  if event.entity.name ~= 'character-corpse' then
    return
  end
  if event.entity.character_corpse_player_index then
    if event.entity.character_corpse_player_index > #game.players then return end
    local player = game.players[event.entity.character_corpse_player_index]
    for _, tag in pairs(player.force.find_chart_tags(
      event.entity.surface,
      {
        {event.entity.position.x - 0.5, event.entity.position.y - 0.5},
        {event.entity.position.x + 0.5, event.entity.position.y + 0.5}
      })) do
      if is_valid_tag(tag, player.name) then
        tag.destroy()
        break
      end
    end
  end
  if #event.entity.get_inventory(defines.inventory.character_corpse) == 0 then
    return
  end
  local iopener = event.player_index
  local icorpse = event.entity.character_corpse_player_index
  if iopener ~= icorpse then
    game.print{"corpse_marker.note_thief", game.players[iopener].name, game.players[icorpse].name}
    log('\n[CORPSE-THIEF] ' .. game.players[iopener].name .. ' has looted ' .. game.players[icorpse].name .. '\'s corpse.')
  end
end

local on_gui_opened = function(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  if event.entity.name ~= 'character-corpse' then return end
  if event.entity.character_corpse_player_index > #game.players then return end
  local iopener = event.player_index
  local icorpse = event.entity.character_corpse_player_index
  if iopener ~= icorpse then
    game.print{"corpse_marker.note_suspect", game.players[iopener].name, game.players[icorpse].name}
    log('\n[CORPSE-SUSPECT] ' .. game.players[iopener].name .. ' is opening ' .. game.players[icorpse].name .. '\'s corpse.')
  end
end

corpse_marker.events ={
  [defines.events.on_player_died] = on_player_died,
  [defines.events.on_character_corpse_expired] = on_character_corpse_expired,
  [defines.events.on_pre_player_mined_item] = on_pre_player_mined_item,
  [defines.events.on_gui_opened] = on_gui_opened,
}

return corpse_marker