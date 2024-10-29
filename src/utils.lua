local _M = {}
local http = require("socket.http")

---Makes an http request and returns the response
---@param url string
---@return string|false, string?
function _M.httpget(url)
  print(assert(http.request {
    url = url,
    headers = {
      USERAGENT = "figmanager"
    }
  }))

  if status ~= 200 then
    return false, "Got status code " .. status .. " on HTTP request to " .. url
  end

  for k, v in pairs(headers) do
    print(k, v)
  end
  
  return response
end

function _M.exists(path)
   local f=io.open(path, "r")
   if f~=nil then
     io.close(f)
     return true
   else
     return false
   end
end

---Reads a file as cachedir a string
---@param path string
---@return string
function _M.readfile(path)
  local file = assert(io.open(path, "r"))
  local str = file:read("a")
  file:close()

  return str
end

---Splits a string
---@param instr string
---@return string[]
function _M.split(instr, sep)
  if sep == nil then
    sep = " "
  end

  local split = {}

  for str in string.gmatch(instr, "([^" .. sep .. "]+)") do
    table.insert(split, str)
  end

  return split
end

return _M

