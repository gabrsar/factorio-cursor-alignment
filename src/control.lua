-- Cursor targets are resolved locally by the engine (Factorio 2.1+).
-- No mouse-coordinate polling, entities, or world changes are needed.
local panel = require("panel")
local palette = {
  {r=0.1,g=0.9,b=1}, {r=1,g=0.55,b=0.1}, {r=0.7,g=0.4,b=1},
  {r=0.3,g=1,b=0.35}, {r=1,g=0.35,b=0.65}, {r=0.25,g=0.55,b=1},
  {r=1,g=0.9,b=0.2}, {r=1,g=0.3,b=0.2}
}
local function assign_color(state, anchor)
  if anchor.color_index and anchor.tint then return end
  local used = {}
  for _, existing in pairs(state.anchors) do
    if existing.color_index then used[existing.color_index] = true end
  end
  local index = 1
  while used[index] do index = index + 1 end
  anchor.color_index = index
  local tint = palette[index]
  if not tint then
    -- Golden-angle hues keep additional references from repeating the palette.
    local hue = ((index - #palette) * 0.61803398875) % 1 * 6
    local sector = math.floor(hue)
    local f = hue - sector
    local p, q, t = 0.25, 1 - 0.75 * f, 0.25 + 0.75 * f
    local rgb = ({ {1,t,p}, {q,1,p}, {p,1,t}, {p,q,1}, {t,p,1}, {1,p,q} })[sector+1]
    tint = {r=rgb[1],g=rgb[2],b=rgb[3]}
  end
  anchor.tint = {r=tint.r,g=tint.g,b=tint.b}
end
local function state_for(index)
  storage.players = storage.players or {}
  storage.players[index] = storage.players[index] or {muted = false}
  local state = storage.players[index]
  state.anchors = state.anchors or {}
  if state.anchor then
    local surface = state.surface or tonumber((state.anchor.cursor_key or ""):match("^(%d+):"))
    if surface then
      local p = state.anchor.position
      state.anchors[surface .. ":" .. p.x .. ":" .. p.y] = {position=p, surface_index=surface}
    end
    state.anchor = nil
  end
  if state.hover_position and state.hover_entity and state.hover_entity.valid then
    local p = state.hover_position
    local surface = state.hover_entity.surface.index
    state.anchors[surface .. ":" .. p.x .. ":" .. p.y] = {position=p, surface_index=surface}
  end
  state.hover_entity = nil; state.hover_position = nil
  local keys = {}
  for key, anchor in pairs(state.anchors) do
    if not anchor.tint then keys[#keys+1] = key end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do assign_color(state, state.anchors[key]) end
  return state
end

local function clear(state)
  for _, object in pairs(state.lines or {}) do
    if object.valid then object.destroy() end
  end
  state.lines = nil
  state.surface = nil
  state.guide_key = nil
end

local function ghost_prototype(player)
  local ghost = player.cursor_ghost
  if not ghost then return nil end
  -- Reading cursor_ghost returns a prototype/quality pair, not an ItemStack.
  -- Its name can be a LuaItemPrototype; normalize before indexing or joining.
  return type(ghost.name) == "string" and prototypes.item[ghost.name] or ghost.name
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
    return prototype.place_result ~= nil or prototype.place_as_tile_result ~= nil or prototype.type == "rail-planner"
  end
  local prototype = ghost_prototype(player)
  if prototype then
    return prototype ~= nil and
      (prototype.place_result ~= nil or prototype.place_as_tile_result ~= nil or prototype.type == "rail-planner")
  end
  return false
end

local function grid_center(position)
  return {x = math.floor(position.x) + 0.5, y = math.floor(position.y) + 0.5}
end

local function guide_for(player, state)
  local stack = player.cursor_stack
  local item = stack and stack.valid_for_read and stack.prototype
  if not item then item = ghost_prototype(player) end
  local entity = item and item.place_result
  if entity and not entity.has_flag("placeable-off-grid")
    and not entity.has_flag("building-direction-8-way")
    and not entity.has_flag("building-direction-16-way") then
    -- Even-sized entities have their origin on a tile boundary. Shift half a
    -- tile so the band covers ONE whole tile. The engine rotates/mirrors offsets.
    return {kind = "build-cursor", x = entity.tile_width % 2 == 0 and 0.5 or 0,
      y = entity.tile_height % 2 == 0 and 0.5 or 0, key = "build:" .. entity.name}
  end
  -- No continuous mouse-coordinate API exists for selection tools/blueprints.
  -- These bands still follow the free cursor; they are not tile-snapped.
  return {kind = "cursor", key = "free"}
end

local function draw_guide(player, state, guide, rebuild, surface)
  local prefs = settings.get_player_settings(player)
  if rebuild or state.surface ~= surface.index or state.guide_key ~= guide.key then clear(state) end
  if state.lines then
    local valid = true
    for _, object in pairs(state.lines) do if not object.valid then valid = false; break end end
    if valid then return end
    clear(state)
  end
  local length = prefs["cursor-alignment-length"].value
  local tint = prefs["cursor-alignment-color"].value
  local rgb = guide.tint or tint
  local alpha = (tint.a or 1) * prefs["cursor-alignment-fill"].value / 100
  -- Rendering colors are premultiplied: lowering alpha alone makes an
  -- additive-looking bright overlay instead of a subtle transparent fill.
  local mix = prefs["cursor-alignment-mix"].value / 100
  local color = {r = rgb.r * alpha, g = rgb.g * alpha, b = rgb.b * alpha, a = alpha * (1 - mix)}
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
      surface = surface,
      players = {player.index},
      draw_on_ground = false,
      render_mode = guide.kind == "build-cursor" and "build-cursor" or "game"
    }
  end
  if guide.tint then
    -- Strong root marker with a dark halo; bands retain the configured opacity.
    for _, outline in ipairs({{width=6,color={r=0,g=0,b=0,a=0.85}},
      {width=3,color={r=rgb.r*0.9,g=rgb.g*0.9,b=rgb.b*0.9,a=0.9}}}) do
      state.lines[#state.lines+1] = rendering.draw_rectangle{
        color=outline.color, width=outline.width, filled=false,
        left_top=target(-0.46,-0.46), right_bottom=target(0.46,0.46),
        surface=surface, players={player.index}, draw_on_ground=false
      }
    end
    for _, dot in ipairs({{radius=0.18,color={r=0,g=0,b=0,a=0.9}},
      {radius=0.12,color={r=rgb.r,g=rgb.g,b=rgb.b,a=1}}}) do
      state.lines[#state.lines+1] = rendering.draw_circle{
        color=dot.color, radius=dot.radius, filled=true, target=target(0,0),
        surface=surface, players={player.index}, draw_on_ground=false
      }
    end
  end
  state.surface = surface.index
  state.guide_key = guide.key
end

local function update(player, rebuild)
  local state = state_for(player.index)
  local prefs = settings.get_player_settings(player)
  local mode = prefs["cursor-alignment-mode"].value
  local pins_visible = prefs["cursor-alignment-enabled"].value and not state.muted
    and (mode ~= "manual" or state.manual_active or prefs["cursor-alignment-always"].value)
  for key, anchor in pairs(state.anchors) do
    local surface = game.surfaces[anchor.surface_index]
    if not surface then clear(anchor); state.anchors[key] = nil
    elseif pins_visible and surface.index == player.surface.index then
      draw_guide(player, anchor, {kind="position", position=anchor.position, key=key, tint=anchor.tint}, rebuild, surface)
    else clear(anchor) end
  end
  local contextual = has_build_cursor(player)
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

  draw_guide(player, state, guide, rebuild, player.surface)
end

local function initialize()
  storage.players = storage.players or {}
  for index in pairs(storage.players) do
    local state = state_for(index)
    clear(state)
    for _, anchor in pairs(state.anchors) do clear(anchor) end
  end
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
  local position = cursor_position or (player.selected and player.selected.valid and player.selected.position)
  if not position then return end
  local p = grid_center(position)
  local surface = player.surface.index
  local key = surface .. ":" .. p.x .. ":" .. p.y
  if state.anchors[key] then clear(state.anchors[key]); state.anchors[key] = nil
  else
    local anchor = {position=p, surface_index=surface}
    assign_color(state, anchor)
    state.anchors[key] = anchor
  end
  state.muted = false
  if settings.get_player_settings(player)["cursor-alignment-mode"].value == "manual" then
    state.manual_active = true
  end
  update(player)
end

local function equip_alignment_tool(player)
  if not settings.get_player_settings(player)["cursor-alignment-enabled"].value then
    player.print({"cursor-alignment.enable-in-settings"})
    return
  end
  if player.clear_cursor() then
    player.cursor_stack.set_stack{name="cursor-alignment-tool", count=1}
  end
end

script.on_event("cursor-alignment-hover", function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if not settings.get_player_settings(player)["cursor-alignment-enabled"].value then
    player.print({"cursor-alignment.enable-in-settings"})
    return
  end
  equip_alignment_tool(player)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= "cursor-alignment-tool" then return end
  local player = game.get_player(event.player_index)
  if player then equip_alignment_tool(player) end
end)

script.on_event({defines.events.on_player_selected_area, defines.events.on_player_alt_selected_area}, function(event)
  if event.item ~= "cursor-alignment-tool" then return end
  local player = game.get_player(event.player_index)
  if not player or not settings.get_player_settings(player)["cursor-alignment-enabled"].value then return end
  -- One reference per gesture, even when the player drags a selection rectangle.
  local a, b = event.area.left_top, event.area.right_bottom
  toggle_hover(player, {x=(a.x+b.x)/2, y=(a.y+b.y)/2})
end)

script.on_event({"cursor-alignment-cancel", "cursor-alignment-escape"}, function(event)
  local player = game.get_player(event.player_index)
  if player and player.cursor_stack and player.cursor_stack.valid_for_read
      and player.cursor_stack.name == "cursor-alignment-tool" then player.clear_cursor() end
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
  if state then
    clear(state)
    for _, anchor in pairs(state.anchors or {}) do clear(anchor) end
  end
  if event.name == defines.events.on_player_removed and storage.players then
    storage.players[event.player_index] = nil
  end
end)
