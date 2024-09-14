-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.scrollback_lines = 100000

-- For example, changing the color scheme:
config.color_scheme = 'Ayu Mirage'

config.font = wezterm.font 'Fira Code Retina'
config.font_size = 13
-- You can specify some parameters to influence the font selection;
-- for example, this selects a Bold, Italic font variant.
-- config.font =
--   wezterm.font('JetBrains Mono', { weight = 'Bold', italic = true })
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

local act = wezterm.action
config.keys = {
  {
    key = "d",
    mods = "SHIFT|CMD",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "d",
    mods = "CMD",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = '`',
    mods = 'OPT',
    action = act.ActivatePaneDirection 'Next',
  },
}

-- and finally, return the configuration to wezterm
return config

