-- Cursor targets are resolved locally by the engine (Factorio 2.1+).
-- No mouse-coordinate polling, entities, or world changes are needed.
local panel = require("panel")
local function state_for(index)
  storage.players = storage.players or {}
  storage.players[index] = storage.players[index] or {muted = false}
  return storage.players[index]
end

local function clear(state)
  for _, object in pairs(state.lines or {}) do
    if object.valid then object.destroy() end
  end
  state.lines = nil
  state.surface = nil
  state.guide_key = nil
end

local function has_build_cursor(player)
  -- Includes blueprints from books and the blueprint library.
  if player.is_cursor_blueprint() then return true end
  local stack = player.cursor_stack
  if stack and stack.valid_for_read then
    if stack.is_blueprint or stack.is_blueprint_book
      or stack.is_selection_tool or stack.is_deconstruction_item
      or stack.is_upgrade_item then return true end
    local prototype = stack.prototype
    if prototype.place_result or prototype.place_as_tile_result or prototype.type == "rail-planner" then return true end
  end
  local ghost = player.cursor_ghost
  if ghost then
    local prototype = prototypes.item[ghost.name]
    return prototype ~= nil and
      (prototype.place_result ~= nil or prototype.place_as_tile_result ~= nil or prototype.type == "rail-planner")
  end
  return false
end

local function grid_center(position)
  return {x = math.floor(position.x) + 0.5, y = math.floor(position.y) + 0.5}
end

local function cursor_key(player)
  local stack = player.cursor_stack
  return tostring(player.surface.index) .. ":" ..
    (stack and stack.valid_for_read and stack.name or
      player.cursor_ghost and player.cursor_ghost.name or "empty")
end

local function guide_for(player, state)
  if state.anchor then
    local p = state.anchor.position
    return {kind = "position", position = p, key = "anchor:" .. p.x .. ":" .. p.y}
  end
  local stack = player.cursor_stack
  local item = stack and stack.valid_for_read and stack.prototype
  if not item and player.cursor_ghost then item = prototypes.item[player.cursor_ghost.name] end
  local entity = item and item.place_result
  if entity and not entity.has_flag("placeable-off-grid")
    and not entity.has_flag("building-direction-8-way")
    and not entity.has_flag("building-direction-16-way") then
    -- Even-sized entities have their origin on a tile boundary. Shift half a
    -- tile so the band covers ONE whole tile. The engine rotates/mirrors offsets.
    return {kind = "build-cursor", x = entity.tile_width % 2 == 0 and 0.5 or 0,
      y = entity.tile_height % 2 == 0 and 0.5 or 0, key = "build:" .. entity.name}
  end
  if not has_build_cursor(player) and state.hover_entity
    and state.hover_entity == player.selected and player.selected.valid then
    local p = state.hover_position or grid_center(player.selected.position)
    return {kind = "position", position = p, key = "selected:" .. p.x .. ":" .. p.y}
  end
  -- No continuous mouse-coordinate API exists for selection tools/blueprints.
  -- These bands still follow the free cursor; they are not tile-snapped.
  return {kind = "cursor", key = "free"}
end

local function update(player, rebuild)
  local state = state_for(player.index)
  if state.anchor and state.anchor.cursor_key ~= cursor_key(player) then state.anchor = nil end
  if state.hover_entity and (not state.hover_entity.valid or state.hover_entity ~= player.selected) then
    state.hover_entity = nil
    state.hover_position = nil
  end
  local prefs = settings.get_player_settings(player)
  local mode = prefs["cursor-alignment-mode"].value
  local contextual = state.anchor ~= nil or state.hover_entity ~= nil or has_build_cursor(player)
  local visible = prefs["cursor-alignment-enabled"].value and not state.muted
    and (mode == "always" or prefs["cursor-alignment-always"].value
      or (mode == "manual" and state.manual_active)
      or (mode == "auto" and contextual))
  if not visible then clear(state); return end

  local guide = guide_for(player, state)
  if guide.kind == "cursor" and prefs["cursor-alignment-grid-only"].value then clear(state); return end
  if rebuild or state.surface ~= player.surface.index or state.guide_key ~= guide.key then clear(state) end
  if state.lines then
    local valid = true
    for _, object in pairs(state.lines) do
      if not object.valid then valid = false; break end
    end
    if valid then return end
    clear(state)
  end

  local length = prefs["cursor-alignment-length"].value
  local tint = prefs["cursor-alignment-color"].value
  local alpha = (tint.a or 1) * prefs["cursor-alignment-fill"].value / 100
  -- Rendering colors are premultiplied: lowering alpha alone makes an
  -- additive-looking bright overlay instead of a subtle transparent fill.
  local mix = prefs["cursor-alignment-mix"].value / 100
  local color = {r = tint.r * alpha, g = tint.g * alpha, b = tint.b * alpha, a = alpha * (1 - mix)}
  local width = 32 -- 32 pixels = exactly one world tile.
  local function target(x, y)
    if guide.position then
      return {type = "position", position = {guide.position.x + x, guide.position.y + y}}
    end
    return {type = guide.kind, offset = {x + (guide.x or 0), y + (guide.y or 0)}}
  end
  state.lines = {}
  for _, axis in ipairs({{length, 0}, {0, length}}) do
    state.lines[#state.lines + 1] = rendering.draw_line{
      color = color, width = width,
      from = target(-axis[1], -axis[2]),
      to = target(axis[1], axis[2]),
      surface = player.surface,
      players = {player.index},
      draw_on_ground = false,
      render_mode = guide.kind == "build-cursor" and "build-cursor" or "game"
    }
  end
  state.surface = player.surface.index
  state.guide_key = guide.key
end

local function initialize()
  storage.players = storage.players or {}
  for _, state in pairs(storage.players) do clear(state) end
  for _, player in pairs(game.connected_players) do panel.ensure_button(player); update(player) end
end

script.on_init(initialize)
script.on_configuration_changed(initialize)

script.on_event({
  defines.events.on_player_created,
  defines.events.on_player_joined_game,
  defines.events.on_player_cursor_stack_changed,
  defines.events.on_selected_entity_changed,
  defines.events.on_player_changed_surface,
  defines.events.on_player_controller_changed
}, function(event)
  local player = game.get_player(event.player_index)
  if player then
    if event.name == defines.events.on_player_changed_surface then
      state_for(player.index).anchor = nil
    end
    panel.ensure_button(player); update(player)
  end
end)

-- Covers book/library changes and surface transitions without rebuilding
-- the drawings every tick. The engine moves the lines every rendered frame.
script.on_nth_tick(6, function()
  for _, player in pairs(game.connected_players) do update(player) end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if not event.player_index or not event.setting:find("cursor-alignment-", 1, true) then return end
  local player = game.get_player(event.player_index)
  if player then
    if event.setting == "cursor-alignment-enabled" then
      state_for(player.index).muted = false
    end
    update(player, true)
  end
end)

script.on_event("cursor-alignment-toggle", function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not settings.get_player_settings(player)["cursor-alignment-enabled"].value then
    player.print({"cursor-alignment.enable-in-settings"})
    return
  end
  local state = state_for(player.index)
  if settings.get_player_settings(player)["cursor-alignment-mode"].value == "manual" then
    state.manual_active = not state.manual_active
    state.muted = false
    update(player)
    return
  end
  state.muted = not state.muted
  update(player)
  player.print({state.muted and "cursor-alignment.off" or "cursor-alignment.on"})
end)

local function toggle_hover(player, cursor_position)
  local state = state_for(player.index)
  if has_build_cursor(player) or not player.selected then
    if state.anchor then state.anchor = nil
    elseif cursor_position then
      state.anchor = {position = grid_center(cursor_position), cursor_key = cursor_key(player)}
    end
    state.hover_entity = nil; state.hover_position = nil
  elseif state.hover_entity == player.selected then
    state.hover_entity = nil; state.hover_position = nil
  else
    state.hover_entity = player.selected
    state.hover_position = cursor_position and grid_center(cursor_position) or nil
  end
  state.muted = false
  if settings.get_player_settings(player)["cursor-alignment-mode"].value == "manual" then
    state.manual_active = state.anchor ~= nil or state.hover_entity ~= nil
  end
  update(player)
end

script.on_event("cursor-alignment-hover", function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not settings.get_player_settings(player)["cursor-alignment-enabled"].value then
    player.print({"cursor-alignment.enable-in-settings"})
    return
  end
  toggle_hover(player, event.cursor_position)
end)

script.on_event("cursor-alignment-config", function(event)
  local player = game.get_player(event.player_index)
  if player then panel.toggle(player) end
end)
script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local result = panel.click(player, event)
  if result == "reset" then
    local state = state_for(player.index)
    state.muted = false; state.manual_active = false
    state.anchor = nil; state.hover_entity = nil; state.hover_position = nil
  end
  if result then update(player, true) end
end)
script.on_event({defines.events.on_gui_checked_state_changed,
  defines.events.on_gui_value_changed, defines.events.on_gui_selection_state_changed}, function(event)
  local player = game.get_player(event.player_index)
  if player and panel.change(player, event) then update(player, true) end
end)
script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "ca-panel" then event.element.destroy() end
end)

script.on_event({defines.events.on_player_left_game, defines.events.on_player_removed}, function(event)
  local state = storage.players and storage.players[event.player_index]
  if state then clear(state) end
  if event.name == defines.events.on_player_removed and storage.players then
    storage.players[event.player_index] = nil
  end
end)
