-- some array helpers
local M = {}

--- Array a -> Array a
--- Returns an empty Array if called on an empty Array
---@param array table
M.tail = function(array)
  if next(array) == nil then
    return {}
  else
    local tail = {}

    for i = 2, #array do
      table.insert(tail, array[i])
    end

    return tail
  end
end

--- Array a -> a
--- Returns a  nil  if called on empty Array
---@param array table
M.head = function(array)
  if next(array) == nil then
    return nil
  else
    local _, a = next(array)
    return a
  end
end

--- Array a -> Tuple a as
--- Returns a Tuple of nil and an empty Array if called on empty Array
---@param array table
M.uncons = function(array)
  return M.head(array), M.tail(array)
end

--- ( a -> b -> b) -> b -> Array a -> b
---@param func function takes 2 args, current value and accumulator (you should return a copy of the accumulator or it will get mutated)
---@param accumulator any
---@param array table an array of type a
M.reduce = function(func, accumulator, array)
  local x, xs = M.uncons(array)
  if x == nil then
    return accumulator
  else
    local acc = func(x, accumulator)
    return M.reduce(func, acc, xs)
  end
end

--- ( a -> b) -> Array a -> Array b
--- returns a new Array of modified values
---@param f function recieves an element from the array as an arugment and returns a modifed version
---@param array any
M.map = function(f, array)
  local a2b = function(currentVal, acc)
    local accumulator = vim.deepcopy(acc)
    table.insert(accumulator, f(currentVal))
    return accumulator
  end
  return M.reduce(a2b, {}, array)
end

--- ( a -> Bool) -> Array a -> Array a
--- returns a new array containing only elements that pass the predicate test
---@param func function that modifies
---@param array any
M.filter = function(predicate, array)
  local maybeInsert = function(currentVal, acc)
    if predicate(currentVal) then
      local accumulator = vim.deepcopy(acc)
      table.insert(accumulator, currentVal)
      return accumulator
    else
      return acc
    end
  end
  return M.reduce(maybeInsert, {}, array)
end

--- List a -> (a -> a -> Bool) -> List a
--- a wrapper for table.sort that doesn not mutate the origional see:
--- https://www.lua.org/manual/5.1/manual.html#pdf-table.sort
---@param array any must be comparable in some way
---@param func any  takes two elements compares them, deafaults to (\a b -> a < b)
---@return [any] a new Array that is sorted
M.sort = function(array, func)
  local sorted = vim.deepcopy(array)
  if func == nil then
    table.sort(sorted)
    return sorted
  else
    table.sort(sorted, func)
    return sorted
  end
end

return M
