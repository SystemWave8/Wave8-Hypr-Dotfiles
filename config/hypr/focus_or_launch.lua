-- FOCUS OR LAUNCH HELPER --

-- ~/.config/hypr/lua/focus_or_launch.lua

local function focus_or_launch(class, cmd)
  for _, w in pairs(hl.get_windows()) do
    if w.class == class then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
      return
    end
  end
  hl.dispatch(hl.dsp.exec_cmd(cmd))
end

return focus_or_launch