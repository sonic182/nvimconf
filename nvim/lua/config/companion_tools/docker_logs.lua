---@class CodeCompanion.Tools.Tool
local M = {
  name = "docker_logs",
  schema = {
    type = "function",
    ["function"] = {
      name = "docker_logs",
      description = "Tail recent Docker logs from a container",
      parameters = {
        type = "object",
        properties = {
          container = {
            type = "string",
            description = "Docker container name or ID"
          },
          minutes = {
            type = "integer",
            description = "How many minutes back to read (default 5)",
            minimum = 1
          },
          lines = {
            type = "integer",
            description = "Max number of lines to return (default 100)",
            minimum = 1
          },
          timestamps = {
            type = "boolean",
            description = "Include timestamps with logs (default false)"
          },
        },
        -- all fields as required, for openai compatibility mostly
        required = { "container", "minutes", "lines", "timestamps" },
        additionalProperties = false,
      },
      strict = true,
    },
  },
  opts = { requires_approval = true },

  handlers = {
    setup = function(self, tools)
      local minutes   = tonumber(self.args.minutes) or 5
      local lines     = tonumber(self.args.lines) or 100
      local container = assert(self.args.container, "container is required")

      local cmd       = {
        "docker", "logs",
        "--since", string.format("%dm", minutes),
        "--tail", tostring(lines)
      }
      if self.args.timestamps then
        table.insert(cmd, "--timestamps")
      end
      table.insert(cmd, container)
      self.cmds = { cmd }
    end,
  },

  output = {
    prompt = function(self, tools)
      local minutes = tonumber(self.args.minutes) or 5
      local lines   = tonumber(self.args.lines) or 100
      return string.format(
        "Run: docker logs --since %dm --tail %d%s %s ?",
        minutes,
        lines,
        (self.args.timestamps and " --timestamps" or ""),
        self.args.container
      )
    end,

    success = function(self, tools, cmd, stdout)
      local output = self:extract_output(stdout)
      return tools.chat:add_tool_output(self, output)
    end,

    error = function(self, tools, cmd, stderr)
      local output = self:extract_output(stderr)
      return tools.chat:add_tool_output(self, "Error: " .. output)
    end,
  },

  extract_output = function(self, data)
    if type(data) == "string" then
      return data
    elseif type(data) == "table" then
      if data.data then
        return tostring(data.data)
      end

      local lines = {}
      for _, line in ipairs(data) do
        if type(line) == "string" then
          table.insert(lines, line)
        elseif type(line) == "table" and line.data then
          table.insert(lines, tostring(line.data))
        end
      end

      return #lines > 0 and table.concat(lines, "\n") or vim.inspect(data)
    end
    return vim.inspect(data)
  end,
}

return M
