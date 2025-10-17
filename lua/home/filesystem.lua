local l = require"home.list";
local stringp = require"home.string";

local Filesystem = {}

--- @param dir string
function Filesystem.create_dir_if_not_exists(dir)
  os.execute("mkdir \"" .. Filesystem.parse_separators(dir) .. "\"")
end

--- @param file_name string
--- @param content string
function Filesystem.write_file(file_name, content)
  local file = io.open(Filesystem.parse_separators(file_name), "w")
  if file ~= nil then
    file:write(content)
    file:close()
  end
end

--- @param file_name string
--- @param lines home.list.List<string>
function Filesystem.write_file_lines(file_name, lines)
  local to_write = ""
  for _, line in pairs(lines) do
    to_write = to_write .. line .. [[

]]
  end
  Filesystem.write_file(file_name, to_write)
end

--- @param file string
--- @return boolean
function Filesystem.file_exists(file)
  local stat = vim.uv.fs_stat(file)
  return (stat ~= nil) and stat.type == "file"
end

--- @param path string
--- @return boolean
function Filesystem.directory_exists(path)
  local stat = vim.uv.fs_stat(path)
  return (stat ~= nil) and stat.type == "directory"
end

function Filesystem.refresh_netrw()
  vim.cmd(":e")
end

--- @param file string
--- @return home.list.List<string>
function Filesystem.lines_from_file(file)
  local xfile = Filesystem.parse_separators(file)
  if not Filesystem.file_exists(xfile) then
    error("File \"" .. xfile .. "\" not found")
    return l.new({})
  end

  local lines = l.new({})
  for line in io.lines(xfile) do
    lines[#lines + 1] = line
  end
  return lines
end

--- @param path string
--- @return home.list.List<string>
function Filesystem.directory_entries(path)
  local xpath = Filesystem.parse_separators(path)
  if not Filesystem.directory_exists(xpath) then
    error("Directory \"" .. xpath .. "\" not found")
    return l.new({})
  end

  local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local entries = ""
  if at_windows then
    entries = vim.fn.system("dir " .. xpath .. " /b")
  else
    entries = vim.fn.system({ "ls", "-a", xpath })
  end
  local all_entries = stringp.split(entries, "\n")
  local list = l.filter(all_entries, function (x) return x ~= "." and x ~= ".." end)

  return list
end

--- @param path string
--- @return home.list.List<string>
function Filesystem.all_files_recursively(path)
  local xpath = Filesystem.parse_separators(path)

  local current_entries = Filesystem.directory_entries(xpath)
  local files = l.flat_map(current_entries, function(entry)
    local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
    local f = xpath .. "/" .. entry
    if at_windows then
      f = xpath .. "\\" .. entry
    end

    if Filesystem.directory_exists(f) then
      return Filesystem.all_files_recursively(f)
    else
      return l.new({ f })
    end
  end)

  return files
end

--- @param source string
--- @param target string
function Filesystem.copy_directory(source, target)
  local xsource = Filesystem.parse_separators(source)
  local xtarget = Filesystem.parse_separators(target)
  if not Filesystem.directory_exists(xsource) then
    error("Directory \"" .. xsource .. "\" not found")
    return
  end
  if not Filesystem.directory_exists(xtarget) then
    error("Directory \"" .. xtarget .. "\" not found")
    return
  end

  local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  if at_windows then
    if string.sub(xsource, #xsource, #xsource) ~= "\\" then
      xsource = xsource .. "\\"
    end
    if string.sub(xtarget, #xtarget, #xtarget) ~= "\\" then
      xtarget = xtarget .. "\\"
    end
    vim.fn.system("xcopy \"" .. xsource .. "\" \"" .. xtarget .. "\" /s /e /h")
  else
    os.execute("cp -rT \"" .. xsource .. "\" \"" .. xtarget .. "\"")
  end
end

--- @param path string
--- @return string
function Filesystem.parse_separators(path)
  local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  if not at_windows then
    return path
  else
    local y, _ = string.gsub(path, "/", "\\")
    return y
  end
end

return Filesystem
