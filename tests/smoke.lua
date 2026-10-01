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
  player.selected = {valid = true, position = {x = -2.2, y = 3.8}}
  update(player)
  assert(not state_for(player.index).lines, "Hover must not automatically show guides")
  toggle_hover(player)
  assert(state_for(player.index).lines, "Selected entity should show guides")
  assert(state_for(player.index).lines[1].width == 32)
  assert(guide_for(player, state_for(player.index)).position.x == -2.5)
  local color = state_for(player.index).lines[1].color
  assert(color.a < 0.2 and color.g <= color.a and color.b <= color.a, "Premultiplied translucent fill")
  toggle_hover(player)
  assert(not state_for(player.index).lines, "Hover shortcut should toggle off")
  toggle_hover(player)
  player.selected = nil
  update(player)
  assert(not state_for(player.index).lines, "Deselection should hide guides")
  player.selected = {valid = true, position = {x = -2.2, y = 3.8}}
  update(player)
  assert(not state_for(player.index).lines, "Returning to entity must require shortcut again")
  toggle_hover(player, {x = -0.01, y = 7.99})
  local exact = guide_for(player, state_for(player.index)).position
  assert(exact.x == -0.5 and exact.y == 7.5, "Hover input must floor the cursor tile, including negatives")
  toggle_hover(player)
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
  player.cursor_ghost = {name = "transport-belt"}
  update(player)
  assert(state_for(player.index).lines, "Ghost missing guides")
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
  player.cursor_stack.set_stack{name = "copy-paste-tool", count = 1}
  toggle_hover(player, {x = -0.01, y = 2.99})
  assert(guide_for(player, state_for(player.index)).position.x == -0.5, "Selection anchor must snap negative coordinates")
  test_prefs["cursor-alignment-grid-only"].value = true
  update(player)
  assert(state_for(player.index).lines, "Grid-only must allow fixed tile references")
  player.cursor_stack.set_stack{name = "iron-plate", count = 1}
  update(player)
  assert(not state_for(player.index).anchor, "Changing tool must clear the fixed reference")
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
  panel.change(player, {element = {valid=true, tags={ca=true,key="mode"}, selected_index=2}})
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
