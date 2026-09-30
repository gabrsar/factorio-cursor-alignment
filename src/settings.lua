data:extend({
  {
    type = "bool-setting", name = "cursor-alignment-enabled",
    setting_type = "runtime-per-user", default_value = true, order = "a"
  },
  {
    type = "bool-setting", name = "cursor-alignment-always",
    setting_type = "runtime-per-user", default_value = false, order = "b"
  },
  {
    type = "color-setting", name = "cursor-alignment-color",
    setting_type = "runtime-per-user",
    default_value = {r = 0.1, g = 0.9, b = 1, a = 0.65}, order = "c"
  },
  {
    type = "int-setting", name = "cursor-alignment-length",
    setting_type = "runtime-per-user", default_value = 256,
    minimum_value = 8, maximum_value = 2048, order = "d"
  },
  {
    type = "int-setting", name = "cursor-alignment-fill",
    setting_type = "runtime-per-user", default_value = 25,
    minimum_value = 1, maximum_value = 100, order = "e"
  },
  {
    type = "string-setting", name = "cursor-alignment-mode",
    setting_type = "runtime-per-user", default_value = "auto",
    allowed_values = {"auto", "manual", "always"}, order = "b-a"
  },
  {
    type = "int-setting", name = "cursor-alignment-mix",
    setting_type = "runtime-per-user", default_value = 0,
    minimum_value = 0, maximum_value = 100, order = "f"
  },
  {
    type = "bool-setting", name = "cursor-alignment-grid-only",
    setting_type = "runtime-per-user", default_value = false, order = "g"
  }
})
