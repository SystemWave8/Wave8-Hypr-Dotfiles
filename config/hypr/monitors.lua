------------------
---- MONITORS ----
------------------
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local function get_hostname()
    local handle = io.popen("hostname")
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+$", "") -- trim trailing newline
end

local hostname = get_hostname()
local scale = (hostname == "surfland") and "1.5" or "1"

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = scale,
})