local M = {}
local modes = {"auto", "manual", "always"}
local function prefs(player) return settings.get_player_settings(player) end
local function get(player, key) return prefs(player)["cursor-alignment-" .. key].value end
local function set(player, key, value) prefs(player)["cursor-alignment-" .. key] = {value = value} end
local function label(key) return {"ca-ui." .. key} end

function M.ensure_button(player)
  if not player.gui.top["ca-open"] then
    player.gui.top.add{type = "button", name = "ca-open", caption = {"mod-name.cursor-alignment"}, tooltip = label("open")}
  end
end

local function close(player)
  local frame = player.gui.screen["ca-panel"]
  if frame then frame.destroy() end
end

local function slider(parent, key, value, maximum)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.add{type = "label", caption = label(key)}.style.width = 145
  local input = row.add{type = "slider", name = "ca-" .. key, minimum_value = 0,
    maximum_value = maximum, value = value, value_step = 1,
    tags = {ca = true, key = key}}
  input.style.width = 190
  row.add{type = "label", name = "value", caption = tostring(math.floor(value + 0.5))}.style.width = 45
end

function M.open(player)
  close(player)
  local f = player.gui.screen.add{type = "frame", name = "ca-panel", direction = "vertical", caption = label("title")}
  f.auto_center = true
  f.style.width = 460
  local body = f.add{type = "scroll-pane"}
  body.style.maximal_height = 580
  body.style.horizontally_stretchable = true
  body.add{type = "checkbox", caption = label("enabled"), state = get(player, "enabled"), tags = {ca = true, key = "enabled"}}
  body.add{type = "label", caption = label("visibility")}
  local index = 1
  for i, value in ipairs(modes) do if value == get(player, "mode") then index = i end end
  body.add{type = "drop-down", items = {label("auto"), label("manual"), label("always")}, selected_index = index, tags = {ca = true, key = "mode"}}
  local help = body.add{type = "label", caption = label("keys")}
  help.style.single_line = false; help.style.maximal_width = 415
  body.add{type = "line"}
  local c = get(player, "color")
  slider(body, "red", c.r * 255, 255)
  slider(body, "green", c.g * 255, 255)
  slider(body, "blue", c.b * 255, 255)
  slider(body, "alpha", (c.a or 1) * 100, 100)
  slider(body, "fill", get(player, "fill"), 100)
  slider(body, "mix", get(player, "mix"), 100)
  local mix = body.add{type = "label", caption = label("mix-help")}
  mix.style.single_line = false; mix.style.maximal_width = 415
  slider(body, "length", get(player, "length"), 2048)
  body.add{type = "checkbox", caption = label("grid-only"), state = get(player, "grid-only"), tags = {ca = true, key = "grid-only"}}
  local note = body.add{type = "label", caption = label("api-note")}
  note.style.single_line = false; note.style.maximal_width = 415
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
  if e.name == "ca-open" then M.toggle(player)
  elseif e.name == "ca-close" then close(player)
  elseif e.name == "ca-reset" then
    for key, value in pairs({enabled = true, mode = "auto", always = false,
      color = {r = 0.1, g = 0.9, b = 1, a = 0.65}, fill = 25, mix = 0, length = 256, ["grid-only"] = false}) do set(player, key, value) end
    M.open(player)
    return true
  end
  return false
end

function M.change(player, event)
  local e = event.element
  if not e or not e.valid or not e.tags.ca then return false end
  local key = e.tags.key
  if key == "enabled" or key == "grid-only" then set(player, key, e.state)
  elseif key == "mode" then set(player, key, modes[e.selected_index]); set(player, "always", false)
  else
    local value = math.floor(e.slider_value + 0.5)
    if key == "length" then value = math.max(8, value) end
    if key == "fill" then value = math.max(1, value) end
    e.slider_value = value
    e.parent["value"].caption = tostring(value)
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
