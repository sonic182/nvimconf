local function read_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    error("Could not open file: " .. file_path)
  end
  local line = file:read("*l")
  file:close()
  return line
end

return {
  read_file = read_file
}