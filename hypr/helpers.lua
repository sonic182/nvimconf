-- Shared helper functions for hyprland.lua.

local M = {}

-- os.execute's exit status is unreliable inside Hyprland's embedded Lua
-- (its SIGCHLD reaping races with Lua's waitpid, so os.execute always
-- returns nil/"No child processes"). Use io.popen and check for output
-- instead, since that only reads the pipe and doesn't depend on the
-- collected exit status.
function M.bin_exists(bin)
    local handle = io.popen("command -v " .. bin .. " 2>/dev/null")
    if not handle then
        return false
    end
    local result = handle:read("l")
    handle:close()
    return result ~= nil and result ~= ""
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

-- Personal laptop is identified by hostname; adjust if it ever changes.
function M.is_personal_pc()
    return io.popen("hostname"):read("l") == "sonic182-nh5070ra"
end

return M
