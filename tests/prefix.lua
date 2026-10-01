-- Test-only adapters: real inventory/prototypes/rendering, synthetic player.
local real_rendering = rendering
local function adapt(method, args)
  assert(#args.players == 1 and args.players[1] == 1)
  args.players = nil -- Headless new maps have no real players.
  return real_rendering[method](args)
end
local rendering = {
  draw_line=function(args) return adapt("draw_line",args) end,
  draw_rectangle=function(args) return adapt("draw_rectangle",args) end,
  draw_circle=function(args) return adapt("draw_circle",args) end
}
local test_prefs = {
    ["cursor-alignment-enabled"] = {value = true},
    ["cursor-alignment-always"] = {value = false},
    ["cursor-alignment-color"] = {value = {r=0.1,g=0.9,b=1,a=0.65}},
    ["cursor-alignment-fill"] = {value = 25},
    ["cursor-alignment-mix"] = {value = 0},
    ["cursor-alignment-mode"] = {value = "auto"},
    ["cursor-alignment-grid-only"] = {value = false},
    ["cursor-alignment-length"] = {value = 256}
}
settings = {get_player_settings = function(player) return test_prefs end}
