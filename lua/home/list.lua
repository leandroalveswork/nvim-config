local List = {}

--- @class home.list.List


--- Cria uma lista se utilizando de uma table ou outra lista
--- @param t table|home.list.List<a>
--- @return home.list.List<a>
function List.new(t)
  local y = { }
  for _, v in ipairs(t) do
    y[#y + 1] = v
  end

  return y
end

--- @param a home.list.List<a>
--- @param b home.list.List<b>
function List.push_list(a, b)
  for _, v in ipairs(b) do
    a[#a + 1] = v
  end
end

--- @param a home.list.List<a>
--- @param b home.list.List<b>
--- @return home.list.List<unknown>
function List.union(a, b)
  local y = List.new(a)
  for _, v in ipairs(b) do
    y[#y + 1] = v
  end

  return y
end
---
--- @param a home.list.List<a>
--- @param b home.list.List<b>
--- @return home.list.List<unknown>
function List.intersection(a, b)
  return List.new({ })
end

--- @param list home.list.List<a>|nil
--- @return a|nil
function List.first_or_nil(list)
  if list == nil or #list == 0 then
    return nil
  else
    return list[1]
  end
end

--- Projeta os elementos da lista em uma nova lista. Não fazer por conta própria, porque List contém pares relativos a implementação de List
--- @param list home.list.List<a>
--- @param fn function<a, b>
--- @return home.list.List<b>
function List.map(list, fn)
  local y = { }
  for _, v in ipairs(list) do
    y[#y + 1] = fn(v)
  end

  return y
end

--- Projeta os elementos da lista em uma nova lista, e depois mergeia os dois níveis de lista. Não fazer por conta própria, porque List contém pares relativos a implementação de List
--- @param list home.list.List<a>
--- @param fn function<a, home.list.List<a>>
--- @return home.list.List<a>
function List.flat_map(list, fn)
  local y = { }
  for _, v in ipairs(list) do
    List.push_list(y, fn(v))
  end

  return y
end

--- Devolve uma nova lista com os elementos que satisfaçam a fn. Não fazer por conta própria, porque List contém pares relativos a implementação de List
--- @param list home.list.List<a>
--- @param fn function<a, boolean>
--- @return home.list.List<a>
function List.filter(list, fn)
  local y = { }
  for _, v in ipairs(list) do
    if fn(v) then
      y[#y + 1] = v
    end
  end

  return y
end

return List
