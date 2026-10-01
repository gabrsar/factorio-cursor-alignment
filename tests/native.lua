-- Integration tests appended only to the disposable test mod.
script.on_nth_tick(30, function(event)
  if event.tick < 120 then return end
  if storage.native_test_done then return end
  local player = assert(game.players[1], "Client test requires a real player")
  player.set_controller{type=defines.controllers.god}
  local prefs = settings.get_player_settings(player)
  panel.ensure_button(player)
  panel.open(player)
  assert(player.gui.screen["ca-panel"].valid, "Native settings frame missing")
  local function find(root, key)
    if root.tags.ca and root.tags.key == key then return root end
    for _, child in pairs(root.children) do
      local result = find(child, key)
      if result then return result end
    end
  end
  local frame = player.gui.screen["ca-panel"]
  local red = assert(find(frame, "red"))
  red.slider_value = 128
  script.get_event_handler(defines.events.on_gui_value_changed){player_index = player.index, element = red}
  assert(math.abs(prefs["cursor-alignment-color"].value.r - 128/255) < 0.0001)
  local mode = assert(find(frame, "mode"))
  mode.selected_index = 3
  script.get_event_handler(defines.events.on_gui_selection_state_changed){player_index = player.index, element = mode}
  assert(state_for(player.index).lines, "Native always mode didn't draw")
  assert(state_for(player.index).lines[1].players[1].index == player.index,
    "Rendering must be scoped to its player")
  script.get_event_handler("cursor-alignment-toggle"){player_index = player.index}
  assert(not state_for(player.index).lines)
  local footer = frame.children[#frame.children]
  script.get_event_handler(defines.events.on_gui_click){player_index = player.index, element = footer["ca-reset"]}
  assert(prefs["cursor-alignment-mode"].value == "auto")
  assert(not state_for(player.index).muted, "Reset must clear the temporary mute")
  player.cursor_stack.set_stack{name="copy-paste-tool", count=1}
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index, cursor_position={x=-0.01,y=2.99}}
  assert(state_for(player.index).anchor.position.x == -0.5)
  local first = state_for(player.index).lines[1]
  update(player)
  assert(first.id == state_for(player.index).lines[1].id, "Stable reference must not recreate rendering")
  prefs["cursor-alignment-grid-only"] = {value=true}
  update(player)
  assert(state_for(player.index).lines, "Native grid filter must allow fixed reference")
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index, cursor_position={x=7.1,y=9.9}}
  assert(not state_for(player.index).anchor)
  assert(not state_for(player.index).lines, "Grid-only must hide the free cursor after releasing anchor")
  prefs["cursor-alignment-mode"] = {value="manual"}
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index, cursor_position={x=7.1,y=9.9}}
  assert(state_for(player.index).lines, "Explicit reference must activate in manual mode")
  script.get_event_handler(defines.events.on_player_cursor_stack_changed){player_index=player.index, name=defines.events.on_player_cursor_stack_changed}
  assert(state_for(player.index).anchor, "Stack events for the same tool must preserve the reference")
  player.cursor_stack.set_stack{name="iron-plate", count=1}
  script.get_event_handler(defines.events.on_player_cursor_stack_changed){player_index=player.index, name=defines.events.on_player_cursor_stack_changed}
  assert(not state_for(player.index).anchor, "Changing tool must release the reference")
  prefs["cursor-alignment-enabled"] = {value=false}
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index, cursor_position={x=7.1,y=9.9}}
  assert(not state_for(player.index).anchor, "Disabled mod must ignore reference input")
  prefs["cursor-alignment-enabled"] = {value=true}
  frame = player.gui.screen["ca-panel"]
  script.get_event_handler(defines.events.on_gui_closed){player_index = player.index, element = frame}
  assert(not player.gui.screen["ca-panel"], "Escape must close the panel")
  prefs["cursor-alignment-mode"] = {value="auto"}
  prefs["cursor-alignment-grid-only"] = {value=false}
  player.cursor_stack.clear()
  player.cursor_ghost = {name="transport-belt", quality="normal"}
  assert(type(player.cursor_ghost.name) ~= "string", "Use the real API ghost representation")
  update(player)
  assert(has_build_cursor(player), "Native ghost must activate contextual guides")
  assert(guide_for(player, state_for(player.index)).kind == "build-cursor")
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index,cursor_position={x=-0.01,y=3.99}}
  assert(state_for(player.index).anchor.position.x == -0.5, "Ghost reference must not crash")
  update(player)
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index,cursor_position={x=-0.01,y=3.99}}
  assert(not state_for(player.index).anchor)
  player.cursor_stack.set_stack{name="iron-plate",count=1}
  assert(not has_build_cursor(player), "An actual cursor stack must take precedence over ghost")
  player.cursor_ghost = nil
  player.cursor_stack.set_stack{name="copy-paste-tool", count=1}
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index, cursor_position=player.position}
  game.take_screenshot{player=player, path="guides.png", show_gui=false, force_render=true}
  panel.open(player)
  game.take_screenshot{player=player, path="panel.png", show_gui=true, force_render=true}
  storage.native_test_done = true
  log("CURSOR ALIGNMENT TESTS PASSED")
end)
