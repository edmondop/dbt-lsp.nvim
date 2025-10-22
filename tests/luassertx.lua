local assert = require("luassert")

local function wait(_, arguments)
  ---@type (fun()) Function to execute until it does not error.
  local assertions_fn = arguments[1]
  ---@type number Timeout in milliseconds. Defaults to 5000.
  local timeout = arguments[2] or 5000

  local err
  if
    not vim.wait(timeout, function()
      local ok, err_ = pcall(assertions_fn)
      err = err_
      return ok
    end, math.min(timeout, 100))
  then
    error(err)
  end

  return true
end

assert:register("assertion", "wait", wait)

return assert
