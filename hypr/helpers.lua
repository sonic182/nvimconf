-- Shared helper functions for hyprland.lua.

local M = {}

function M.bin_exists(bin)
    local ok = os.execute("command -v " .. bin .. " >/dev/null 2>&1")
    return ok == true or ok == 0
end

-- Auto-detect an app launcher: first binary found wins, in priority order.
function M.detect_menu(candidates)
    for _, candidate in ipairs(candidates) do
        if M.bin_exists(candidate.bin) then
            return candidate.cmd
        end
    end
    return candidates[1].cmd
end

-- Work PC is identified by hostname; adjust if it ever changes.
function M.is_work_pc()
    return io.popen("hostname"):read("l") == "eliminapro"
end

return M
