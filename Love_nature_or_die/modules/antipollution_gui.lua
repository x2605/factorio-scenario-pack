local mod_gui = require("mod-gui")
local antipoll_gui = {}

pollution_report = function(player)
  local gui = mod_gui.get_button_flow(player)
  local frame = gui.add{
    type = 'frame',
    name = 'antipoll_gui_frame',
    direction = 'horizontal'
  }
  frame.style.use_header_filler = false
  frame.style.padding = 1
  return frame
end

update_gui = function(player)
  local gui = mod_gui.get_button_flow(player).antipoll_gui_frame
  if not gui then
    gui = pollution_report(player)
  end

  gui.clear()
  if not global.antipollution__is_initiated then return end

  local text = nil
  if global.antipollution__max > global.antipollution__threshold then
    text = 'max = [font=default-bold][color=orange]' .. math.floor(global.antipollution__max) .. '[/color][/font], area = [font=default-bold][color=yellow]' .. global.antipollution__threshold_count .. '[/color][/font]'
  else
    text = 'max = [font=default-bold][color=0,1,0]' .. math.floor(global.antipollution__max) .. '[/color][/font], area = [font=default-bold][color=0,1,0]' .. global.antipollution__threshold_count .. '[/color][/font]'
  end
  local inner = gui.add{
    type = 'frame',
    style = 'inside_shallow_frame',
    direction = 'horizontal'
  }
  inner.style.left_padding = 4
  inner.style.right_padding = 4
  inner.add{
    type = 'label',
    caption = text,
    tooltip = {"antipollution.tooltip", global.antipollution__threshold}
  }
end

on_player_created = function(event)
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  update_gui(player)
end

on_tick = function(event)
  if game.tick % 180 == 178 then
    for _, player in pairs (game.players) do
      update_gui(player)
    end
  end
end

antipoll_gui.events = {
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_tick] = on_tick,
}

return antipoll_gui