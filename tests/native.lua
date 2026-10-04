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
  local mode = assert(find(frame, "mode")).parent["ca-mode-always"]
  mode.state = true
  script.get_event_handler(defines.events.on_gui_checked_state_changed){player_index = player.index, element = mode}
  for _, choice in pairs(mode.parent.children) do assert(choice.state == (choice == mode), "Visibility modes must be exclusive") end
  assert(state_for(player.index).lines, "Native always mode didn't draw")
  assert(state_for(player.index).lines[1].players[1].index == player.index,
    "Rendering must be scoped to its player")
  script.get_event_handler("cursor-alignment-toggle"){player_index = player.index}
  assert(not state_for(player.index).lines)
  local footer = frame.children[#frame.children]
  script.get_event_handler(defines.events.on_gui_click){player_index = player.index, element = footer["ca-reset"]}
  assert(prefs["cursor-alignment-mode"].value == "auto")
  assert(not state_for(player.index).muted, "Reset must clear the temporary mute")
  local state=state_for(player.index)
  local surface=player.surface.index
  local function select_reference(e)
    local p=e.cursor_position
    script.get_event_handler(defines.events.on_player_selected_area){player_index=e.player_index,
      item="cursor-alignment-tool", area={left_top=p,right_bottom=p}}
  end
  script.get_event_handler("cursor-alignment-hover"){player_index=player.index}
  assert(player.cursor_stack.name == "cursor-alignment-tool", "Hotkey equips persistent tool")
  script.get_event_handler("cursor-alignment-cancel"){player_index=player.index}
  assert(not player.cursor_stack.valid_for_read, "Right click clears tool")
  script.get_event_handler(defines.events.on_lua_shortcut){player_index=player.index,prototype_name="cursor-alignment-tool"}
  assert(player.cursor_stack.name == "cursor-alignment-tool", "Toolbar equips tool")
  select_reference{player_index=player.index,cursor_position={x=40.1,y=40.1}}
  assert(player.cursor_stack.name == "cursor-alignment-tool", "Tool survives placement")
  select_reference{player_index=player.index,cursor_position={x=40.9,y=40.9}}
  assert(not state.anchors[surface .. ":40.5:40.5"], "Second click removes reference")
  script.get_event_handler("cursor-alignment-escape"){player_index=player.index}
  assert(not player.cursor_stack.valid_for_read, "Escape clears tool")
  player.cursor_stack.set_stack{name="iron-plate",count=1}
  script.get_event_handler("cursor-alignment-cancel"){player_index=player.index}
  assert(player.cursor_stack.name == "iron-plate", "Cancellation preserves other cursor items")
  local key=surface .. ":-0.5:2.5"
  select_reference{player_index=player.index,cursor_position={x=-0.01,y=2.99}}
  select_reference{player_index=player.index,cursor_position={x=7.1,y=9.9}}
  assert(state.anchors[key] and state.anchors[surface .. ":7.5:9.5"])
  assert(state.anchors[key].color_index ~= state.anchors[surface .. ":7.5:9.5"].color_index)
  assert(#state.anchors[key].lines == 6, "Native pin must include root border and center marker")
  player.cursor_stack.set_stack{name="iron-plate",count=1}
  update(player)
  assert(state.anchors[key].lines, "Pins survive tool changes")
  select_reference{player_index=player.index,cursor_position={x=-0.9,y=2.1}}
  assert(not state.anchors[key] and state.anchors[surface .. ":7.5:9.5"])
  prefs["cursor-alignment-enabled"]={value=false}
  update(player)
  assert(not state.anchors[surface .. ":7.5:9.5"].lines)
  select_reference{player_index=player.index,cursor_position={x=20,y=20}}
  assert(not state.anchors[surface .. ":20.5:20.5"])
  prefs["cursor-alignment-enabled"]={value=true}
  update(player)
  assert(state.anchors[surface .. ":7.5:9.5"].lines)
  frame = player.gui.screen["ca-panel"]
  script.get_event_handler(defines.events.on_gui_click){player_index=player.index,element=frame.children[#frame.children]["ca-reset"]}
  assert(state.anchors[surface .. ":7.5:9.5"], "Appearance reset must preserve fixed references")
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
  select_reference{player_index=player.index,cursor_position={x=-0.01,y=3.99}}
  assert(state_for(player.index).anchors[surface .. ":-0.5:3.5"], "Ghost reference must not crash")
  update(player)
  select_reference{player_index=player.index,cursor_position={x=-0.01,y=3.99}}
  assert(not state_for(player.index).anchors[surface .. ":-0.5:3.5"])
  player.cursor_stack.set_stack{name="iron-plate",count=1}
  assert(not has_build_cursor(player), "An actual cursor stack must take precedence over ghost")
  player.cursor_ghost = nil
  player.cursor_stack.set_stack{name="copy-paste-tool", count=1}
  select_reference{player_index=player.index, cursor_position=player.position}
  for _, offset in ipairs({{5,0},{-5,0},{0,5}}) do
    select_reference{
      player_index=player.index,cursor_position={x=player.position.x+offset[1],y=player.position.y+offset[2]}}
  end
  game.take_screenshot{player=player, path="guides.png", show_gui=false, force_render=true}
  panel.open(player)
  game.take_screenshot{player=player, path="panel.png", show_gui=true, force_render=true}
  storage.native_test_done = true
  log("CURSOR ALIGNMENT TESTS PASSED")
end)
