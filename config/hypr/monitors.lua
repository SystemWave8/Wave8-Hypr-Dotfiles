------------------
---- MONITORS ----
------------------
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local function get_hostname()
    local f = io.open("/etc/hostname", "r")
    if not f then return "" end
    local hostname = f:read("*l") -- read first line
    f:close()
    return hostname or ""
end

local hostname = get_hostname()
local scale = (hostname == "surfland") and "1.5" or "1"
local mode = (hostname == "topland") and "1920x1080@60" or "preferred"

hl.monitor({
    output   = "",
    mode     = mode,
    position = "auto",
    scale    = scale,
})