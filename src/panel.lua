local M = {}
local modes = {"auto", "manual", "always"}
local function prefs(player) return settings.get_player_settings(player) end
local function get(player, key) return prefs(player)["cursor-alignment-" .. key].value end
local function set(player, key, value) prefs(player)["cursor-alignment-" .. key] = {value = value} end
local function label(key) return {"ca-ui." .. key} end

function M.remove_legacy_button(player)
  local button = player.gui.top["ca-open"]
  if button then button.destroy() end
end

local function close(player)
  local frame = player.gui.screen["ca-panel"]
  if frame then frame.destroy() end
end

local function slider(parent, key, value, maximum, tooltip)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.add{type = "label", caption = label(key), tooltip = tooltip and label(tooltip) or label(key)}.style.width = 205
  local input = row.add{type = "slider", name = "ca-" .. key, minimum_value = 0,
    maximum_value = maximum, value = value, value_step = 1,
    tags = {ca = true, key = key}}
  input.style.width = 190
  row.add{type = "label", name = "ca-value", caption = tostring(math.floor(value + 0.5))}.style.width = 45
end

local function section(parent, key)
  local group = parent.add{type="flow", direction="vertical"}
  group.style.top_margin = 8
  group.style.vertical_spacing = 4
  local heading = group.add{type="label",caption=label(key)}
  heading.style.font = "default-bold"
  group.add{type="line"}.style.horizontally_stretchable = true
  return group
end

local function shortcut(parent, action, binding, tooltip)
  local row = parent.add{type="flow", direction="horizontal"}
  row.add{type="label",caption=label(action),tooltip=tooltip and label(tooltip)}.style.width = 205
  row.add{type="label",caption=label(binding)}
end

function M.open(player)
  close(player)
  local f = player.gui.screen.add{type = "frame", name = "ca-panel", direction = "vertical", caption = label("title")}
  f.auto_center = true
  f.style.width = 520
  local body = f.add{type = "scroll-pane"}
  body.style.maximal_height = 580
  body.style.horizontally_stretchable = true
  local display = section(body, "section-display")
  display.add{type = "checkbox", caption = label("enabled"), state = get(player, "enabled"), tags = {ca = true, key = "enabled"}}
  local visibility = display.add{type="flow",direction="horizontal"}
  visibility.add{type="label",caption=label("visibility")}.style.width=205
  local index = 1
  for i, value in ipairs(modes) do if value == get(player, "mode") then index = i end end
  local choices=visibility.add{type="flow",direction="vertical",name="ca-modes"}
  for i, mode in ipairs(modes) do
    choices.add{type="radiobutton",name="ca-mode-" .. mode,caption=label(mode),
      state=i==index,tags={ca=true,key="mode",mode=mode}}
  end
  slider(display, "length", get(player, "length"), 2048)
  display.add{type="checkbox",caption=label("grid-only"),tooltip=label("grid-help"),state=get(player,"grid-only"),tags={ca=true,key="grid-only"}}
  local colors = section(body, "section-color")
  colors.tooltip = label("color-help")
  local c = get(player, "color")
  slider(colors, "red", c.r * 255, 255)
  slider(colors, "green", c.g * 255, 255)
  slider(colors, "blue", c.b * 255, 255)
  local transparency = section(body, "section-transparency")
  slider(transparency, "alpha", (c.a or 1) * 100, 100)
  slider(transparency, "fill", get(player, "fill"), 100)
  slider(transparency, "mix", get(player, "mix"), 100, "mix-help")
  local keys = section(body, "section-shortcuts")
  shortcut(keys,"action-toggle","shortcut-toggle")
  shortcut(keys,"action-reference","shortcut-reference","anchor-help")
  shortcut(keys,"action-panel","shortcut-panel")
  local hint=keys.add{type="label",caption=label("remove-hint"),tooltip=label("anchor-help")}
  hint.style.single_line=false; hint.style.maximal_width=475
  local footer = f.add{type = "flow", direction = "horizontal"}
  footer.add{type = "button", name = "ca-reset", caption = label("reset")}
  footer.add{type = "button", name = "ca-close", caption = label("close")}
  player.opened = f
end

function M.toggle(player)
  if player.gui.screen["ca-panel"] then close(player) else M.open(player) end
end

function M.click(player, event)
  local e = event.element
  if not e or not e.valid then return false end
  if e.name == "ca-close" then close(player)
  elseif e.name == "ca-reset" then
    for key, value in pairs({enabled = true, mode = "auto", always = false,
      color = {r = 0.1, g = 0.9, b = 1, a = 0.65}, fill = 25, mix = 0, length = 256, ["grid-only"] = false}) do set(player, key, value) end
    M.open(player)
    return "reset"
  end
  return false
end

function M.change(player, event)
  local e = event.element
  if not e or not e.valid or not e.tags.ca then return false end
  local key = e.tags.key
  if key == "enabled" or key == "grid-only" then set(player, key, e.state)
  elseif key == "mode" then
    if not e.state then e.state=true; return false end
    set(player, key, e.tags.mode); set(player, "always", false)
    for _, choice in pairs(e.parent.children) do choice.state=choice == e end
  else
    local value = math.floor(e.slider_value + 0.5)
    if key == "length" then value = math.max(8, value) end
    if key == "fill" then value = math.max(1, value) end
    e.slider_value = value
    e.parent["ca-value"].caption = tostring(value)
    local channel = ({red = "r", green = "g", blue = "b", alpha = "a"})[key]
    if channel then
      local c = get(player, "color")
      local color = {r = c.r, g = c.g, b = c.b, a = c.a or 1}
      color[channel] = value / (channel == "a" and 100 or 255)
      set(player, "color", color)
    else set(player, key, value) end
  end
  return true
end
return M
