  -- Helpers --
--	   --


local focus_or_launch = require("focus_or_launch")

---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "wofi"


---------------------
---- KEYBINDINGS ----
---------------------

-- Main Mod Set

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- 			--


-- hypr-conf-menu
hl.bind(mainMod .. " + ALT + Space", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-conf-menu.sh"))   -- Quick Access to Open Hyprland Configs (both lua and conf)
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/bin-script-menu.sh"))  -- Quick Access to edit bash scripts - > .sh files

-- Day to Day Use Case

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close()) -- close current window

-- closeWindowBind:set_enabled(false)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

--Shutdown // Reboot // Classic hyprctl dispatch exit
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("shutdown now"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("reboot"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exit())

-- Kill all windows --

hl.bind(mainMod .. " + K", function()
    local ws = hl.get_active_workspace()
    local windows = hl.get_workspace_windows(ws.id)
    for _, w in pairs(windows) do
        hl.dispatch(hl.dsp.window.close({ window = "address:" .. w.address }))
    end
end)


-- Launch/focus Web Apps
hl.bind(mainMod .. " + Y", function()
  focus_or_launch("brave-www.youtube.com__-Default", "brave --app=https://www.youtube.com/")
end)

hl.bind(mainMod .. " + ALT + C", function()
  focus_or_launch("chrome-chat.openai.com__-Default", "chromium --class=chrome-chat.openai.com__-Default --app=https://chat.openai.com/")
end)

hl.bind(mainMod .. " + C", function()
  focus_or_launch("chrome-claude.ai__new-Default", "helium-browser --app=https://claude.ai/new")
end)

hl.bind(mainMod .. " + H", function()
  focus_or_launch("chrome-wiki.hyprland.org__-Default", "chromium --class=chrome-wiki.hyprland.org__-Default --app=https://wiki.hyprland.org/")
end)

hl.bind(mainMod .. " + N", function()
  focus_or_launch("chrome-notebooklm.google.com__-Default", "chromium --app=https://notebooklm.google.com/")
end)

hl.bind(mainMod .. " + G", function()
  focus_or_launch("chrome-grok.com__-Default", "chromium --app=https://grok.com/")
end)

hl.bind(mainMod .. " + period", function()
  focus_or_launch("chrome-github.com__SystemWave8_Wave8-Hypr-Dotfiles-Default", "chromium --app=https://github.com/SystemWave8/Wave8-Hypr-Dotfiles")
end)

hl.bind(mainMod .. " + O", function()
  focus_or_launch("chrome-outlook.live.com__mail_0_-Default", "helium-browser --app=https://outlook.live.com/mail/0/?login_hint=systemwave%40outlook.com")
end)

hl.bind(mainMod .. " + M", function()
  focus_or_launch("chrome-music.youtube.com__-Default", "helium-browser --app=https://music.youtube.com/")
end)


-- Window Capture Tool-- hypr-windowrule-snapshot --

hl.bind(mainMod .. " + ALT + comma", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-windowrule-snapshot.sh"))


-- Wallpaper Picker --

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/wallpicker.sh"))

-- Steam OS Launcher

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("/usr/bin/steamos-session-select"))


-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- switchwindow with mainMod SHIFT + arrow keys

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))


-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && $HOME/.local/bin/vol-notify.sh"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && $HOME/.local/bin/vol-notify.sh"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && $HOME/.local/bin/vol-notify.sh"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),                                     { locked = true, repeating = true })

hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Toggle Scrolling and Dwindle

hl.bind(mainMod .. " + ALT + L", function()
    local layout = hl.get_config("general.layout")
    if layout == "dwindle" then
        hl.config({ general = { layout = "scrolling" } })
    else
        hl.config({ general = { layout = "dwindle" } })
    end
end)



-- Example special workspace (scratchpad)
--hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
--hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))