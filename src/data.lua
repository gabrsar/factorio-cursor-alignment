local selection = {border_color={r=0.1,g=0.9,b=1}, cursor_box_type="copy", mode={"any-tile"}}
data:extend({
  {
    type="selection-tool", name="cursor-alignment-tool",
    icon="__cursor-alignment__/thumbnail.png", icon_size=144,
    flags={"only-in-cursor", "spawnable", "not-stackable"}, stack_size=1,
    select=selection, alt_select=selection,
    localised_name={"controls.cursor-alignment-hover"}
  },
  {
    type="shortcut", name="cursor-alignment-tool", action="lua",
    icon="__cursor-alignment__/thumbnail.png", icon_size=144,
    small_icon="__cursor-alignment__/thumbnail.png", small_icon_size=144,
    associated_control_input="cursor-alignment-hover",
    localised_name={"controls.cursor-alignment-hover"}, order="z[cursor-alignment]"
  },
  {type="custom-input", name="cursor-alignment-cancel", key_sequence="mouse-button-2", consuming="none"},
  {type="custom-input", name="cursor-alignment-escape", key_sequence="ESCAPE", consuming="none"},
  {
    type = "custom-input",
    name = "cursor-alignment-toggle",
    key_sequence = "COMMAND + SHIFT + H",
    consuming = "none"
  },
  {
    type = "custom-input",
    name = "cursor-alignment-hover",
    key_sequence = "COMMAND + SHIFT + S",
    consuming = "none"
  },
  {
    type = "custom-input", name = "cursor-alignment-config",
    key_sequence = "COMMAND + SHIFT + O", consuming = "none"
  }
})
