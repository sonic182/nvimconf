local function compat_tbl_flatten(items)
  local flat = {}

  local function flatten(value)
    if type(value) ~= "table" then
      flat[#flat + 1] = value
      return
    end

    for _, nested in ipairs(value) do
      flatten(nested)
    end
  end

  flatten(items)

  return flat
end

local version = vim.version()
if version.major == 0 and version.minor >= 13 then
  vim.tbl_flatten = compat_tbl_flatten
end

require("config.lazy")
