-- Test harness appended only to the disposable copy, not the deliverable.
script.on_init(function()
  initialize()
  local inventory = game.create_inventory(1)
  local player = {index = 1, surface = game.surfaces[1], cursor_stack = inventory[1]}
  player.is_cursor_blueprint = function() return false end
  player.clear_cursor = function() inventory[1].clear(); player.cursor_ghost = nil end
  player.teleport = function(_, surface) player.surface = surface end
  update(player)
  assert(not state_for(player.index).lines, "Empty hand should hide guides")
  local state = state_for(player.index)
  toggle_hover(player, {x=-0.01,y=3.99})
  toggle_hover(player, {x=7.1,y=9.9})
  assert(state.anchors["1:-0.5:3.5"] and state.anchors["1:7.5:9.5"], "Multiple references")
  assert(state.anchors["1:-0.5:3.5"].lines[1].width == 32)
  assert(#state.anchors["1:-0.5:3.5"].lines == 6, "Root marker must accompany both bands")
  assert(state.anchors["1:-0.5:3.5"].color_index ~= state.anchors["1:7.5:9.5"].color_index)
  local first_objects = state.anchors["1:-0.5:3.5"].lines
  local second_color = state.anchors["1:7.5:9.5"].tint
  local old_id = state.anchors["1:7.5:9.5"].lines[1].id
  update(player)
  assert(state.anchors["1:7.5:9.5"].lines[1].id == old_id)
  player.selected = {valid=true, position={x=99,y=99}}
  update(player)
  assert(state.anchors["1:-0.5:3.5"], "Selection change must preserve references")
  toggle_hover(player, {x=-0.9,y=3.1})
  assert(not state.anchors["1:-0.5:3.5"] and state.anchors["1:7.5:9.5"], "Remove only the same tile")
  for _, object in pairs(first_objects) do assert(not object.valid, "Removing a pin must remove its marker") end
  assert(state.anchors["1:7.5:9.5"].tint.r == second_color.r, "Other references must keep their colors")
  toggle_hover(player, {x=7.9,y=9.1})
  assert(not next(state.anchors))
  for i=1,12 do toggle_hover(player,{x=i+20,y=10}) end
  local colors = {}
  for _, anchor in pairs(state.anchors) do
    local tint=anchor.tint
    local signature=tint.r .. ":" .. tint.g .. ":" .. tint.b
    assert(not colors[signature], "Colors must not repeat beyond the initial palette")
    colors[signature]=true
  end
  for i=1,12 do toggle_hover(player,{x=i+20,y=10}) end
  state.anchor = {position={x=1.5,y=2.5},cursor_key="1:empty"}
  state_for(player.index)
  assert(state.anchors["1:1.5:2.5"] and not state.anchor, "Upgrade must migrate the old fixed reference")
  toggle_hover(player,{x=1.1,y=2.1})
  assert(not next(state.anchors))
  player.selected = nil
  for _, name in ipairs({"transport-belt", "assembling-machine-1", "rail", "concrete", "blueprint", "blueprint-book", "copy-paste-tool", "cut-paste-tool", "deconstruction-planner", "upgrade-planner"}) do
    player.clear_cursor()
    assert(player.cursor_stack.set_stack{name = name, count = 1}, name)
    update(player)
    local state = state_for(player.index)
    assert(state.lines and #state.lines == 2, "Missing guides for " .. name)
    assert(state.lines[1].valid and state.lines[2].valid)
    if name == "transport-belt" or name == "assembling-machine-1" then
      assert(state.lines[1].from.type == "build-cursor")
      assert(state.lines[1].width == 32)
    else assert(state.lines[1].from.type == "cursor") end
    local id = state.lines[1].id
    update(player)
    assert(state.lines[1].id == id, "Unnecessary recreation")
    state.muted = true
    update(player)
    assert(not state.lines, "Muted guides remain")
    state.muted = false
    update(player)
    assert(state.lines and #state.lines == 2)
  end
  player.clear_cursor()
  player.cursor_stack.set_stack{name = "splitter", count = 1}
  update(player)
  local g = guide_for(player, state_for(player.index))
  assert(g.kind == "build-cursor" and g.x == 0.5 and g.y == 0, "Even-size tile offset")
  player.clear_cursor()
  player.cursor_ghost = {name = prototypes.item["transport-belt"]}
  update(player)
  assert(state_for(player.index).lines, "Ghost missing guides")
  assert(guide_for(player, state_for(player.index)).kind == "build-cursor", "Ghost must use snapped build target")
  toggle_hover(player, {x=-0.01,y=3.99})
  assert(state_for(player.index).anchors["1:-0.5:3.5"], "Prototype-valued ghost must support fixed references")
  update(player)
  toggle_hover(player, {x=-0.01,y=3.99})
  player.clear_cursor()
  player.cursor_stack.set_stack{name = "iron-plate", count = 1}
  update(player)
  assert(not state_for(player.index).lines, "Non-build item has guides")
  player.clear_cursor()
  player.cursor_stack.set_stack{name = "transport-belt", count = 1}
  update(player)
  local old = state_for(player.index).lines[1]
  old.destroy()
  update(player)
  assert(state_for(player.index).lines[1].valid, "Destroyed drawing not recovered")
  local second = game.create_surface("alignment-test-surface", {width = 32, height = 32})
  player.teleport({0, 0}, second)
  update(player)
  assert(state_for(player.index).surface == second.index, "Surface not updated")
  test_prefs["cursor-alignment-mode"].value = "manual"
  update(player)
  assert(not state_for(player.index).lines, "Manual mode must start hidden")
  state_for(player.index).manual_active = true
  update(player)
  assert(state_for(player.index).lines, "Manual activation")
  test_prefs["cursor-alignment-mode"].value = "always"
  player.clear_cursor()
  update(player)
  assert(state_for(player.index).lines, "Always mode with empty hand")
  test_prefs["cursor-alignment-grid-only"].value = true
  update(player)
  assert(not state_for(player.index).lines, "Grid-only must suppress unsnapped bands")
  test_prefs["cursor-alignment-grid-only"].value = false
  toggle_hover(player, {x=-0.01,y=2.99})
  local surface_index = player.surface.index
  local key = surface_index .. ":-0.5:2.5"
  test_prefs["cursor-alignment-grid-only"].value = true
  update(player)
  assert(state_for(player.index).anchors[key].lines, "Grid filter must allow pins")
  player.cursor_stack.set_stack{name="iron-plate",count=1}
  update(player)
  assert(state_for(player.index).anchors[key], "Changing tool must preserve references")
  player.teleport({0,0}, game.surfaces[1])
  update(player)
  assert(state_for(player.index).anchors[key] and not state_for(player.index).anchors[key].lines)
  toggle_hover(player, {x=-0.01,y=2.99})
  assert(state_for(player.index).anchors["1:-0.5:2.5"], "Same coordinates on different surfaces are independent")
  toggle_hover(player, {x=-0.01,y=2.99})
  player.teleport({0,0}, game.surfaces[surface_index])
  update(player)
  assert(state_for(player.index).anchors[key].lines, "Returning restores references")
  toggle_hover(player, {x=-0.01,y=2.99})
  test_prefs["cursor-alignment-grid-only"].value = false
  test_prefs["cursor-alignment-mix"].value = 100
  update(player, true)
  assert(state_for(player.index).lines[1].color.a == 0, "Additive mix must preserve background")
  -- GUI structure/actions use a test double; actual layout still needs a client.
  local function gui_node(spec, parent)
    local node = {valid = true, style = {}, children = {}, parent = parent}
    for k, v in pairs(spec or {}) do node[k] = v end
    node.tags = node.tags or {}
    node.add = function(child_spec)
      local child = gui_node(child_spec, node)
      node.children[#node.children + 1] = child
      if child.name then node[child.name] = child end
      return child
    end
    node.destroy = function()
      node.valid = false
      if parent and node.name then parent[node.name] = nil end
    end
    return node
  end
  player.gui = {top = gui_node(), screen = gui_node()}
  panel.ensure_button(player)
  panel.ensure_button(player)
  assert(#player.gui.top.children == 1, "Duplicate config button")
  panel.open(player)
  assert(player.opened == player.gui.screen["ca-panel"])
  local mode={valid=true,tags={ca=true,key="mode",mode="manual"},state=true}
  mode.parent={children={mode}}
  panel.change(player, {element=mode})
  assert(test_prefs["cursor-alignment-mode"].value == "manual")
  panel.change(player, {element = {valid=true, tags={ca=true,key="red"}, slider_value=128,
    parent={["ca-value"]={caption=""}}}})
  assert(math.abs(test_prefs["cursor-alignment-color"].value.r - 128/255) < 0.0001)
  panel.click(player, {element={valid=true,name="ca-reset"}})
  assert(test_prefs["cursor-alignment-mode"].value == "auto")
  assert(test_prefs["cursor-alignment-mix"].value == 0)
  panel.click(player, {element={valid=true,name="ca-close"}})
  assert(not player.gui.screen["ca-panel"])
  log("CURSOR ALIGNMENT TESTS PASSED")
end)
