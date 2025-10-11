local l = require"home.list";

local String = {};

--- @param x string
--- @return string
function String.to_lower_camel_case(x)
  local y = ""
  for i = 1, #x do
    local c = x:sub(i, i)
    if i == 1 then
      y = y .. string.lower(c)
    else
      local previous = x:sub(i - 1, i - 1)
      if previous == "-" then
        y = y .. string.upper(c)
      else
        if c ~= "-" then
          y = y .. c
        end
      end
    end
  end

  return y
end

--- @param x string
--- @return string
function String.to_upper_camel_case(x)

  local y = ""
  for i = 1, #x do
    local c = x:sub(i, i)
    if i == 1 then
      y = y .. string.upper(c)
    else
      local previous = x:sub(i - 1, i - 1)
      if previous == "-" then
        y = y .. string.upper(c)
      else
        if c ~= "-" then
          y = y .. c
        end
      end
    end
  end

  return y
end

--- @param text string
--- @param separator string
--- @return home.list.List<string>
function String.split(text, separator)
  local list = l.new({})
  local remain = text
  while remain ~= "" do

    local divider_at = string.find(remain, separator)
    if divider_at == nil then
      list[#list + 1] = remain
      remain = ""
    else
      local entry = remain:sub(1, divider_at - 1)
      list[#list + 1] = entry
      remain = remain:sub(divider_at + 1, string.len(remain))
    end
  end
  return list
end

--- @param text string
--- @param separator string
--- @param condition function<string, boolean>
--- @return number?
function String.find_index_of_split_reversed(text, separator, condition)
  local trial = text
  while trial ~= "" do
    if condition(trial) then
      return string.len(trial) + 1
    end

    local reverse_divider_at = string.find(trial:reverse(), separator)
    if reverse_divider_at == nil then
      trial = ""
    else
      local last_divider_at = string.len(trial) - reverse_divider_at + 1
      trial = trial:sub(1, last_divider_at - 1)
    end
  end
  if condition(trial) then
    return 1
  end

  return nil
end

return String;
