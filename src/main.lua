local utils = require("utils")
local dkjson = require("dkjson")
local http = require("socket.http")
local lfs = require("lfs")

local opts = ""
local action = ""
local args = {}

local repos = {
  TheKillerBunny = "https://codeberg.org/TheBunnyMan123/FigManagerRepo/raw/branch/main/repo";
  GNamimates = "https://raw.githubusercontent.com/lua-gods/GNs-Avatar-3/refs/heads/main/lib/figmanifest.json";
  Bitslayn = "https://raw.githubusercontent.com/Bitslayn/FOX-s-Figura-APIs/refs/heads/main/figman.json";
}
local reposdecoded = {}

local config = {
  libdir = "libs"
}

local homedir = os.getenv("HOME")
if not homedir or homedir == "" then
  homedir = os.getenv("HomeDrive") .. os.getenv("HomePath")
end
homedir = homedir:gsub("\\", "/"):gsub("/$", "")
local configdir = homedir .. "/.config/figmanager/"
local cachedir = homedir .. "/.cache/figmanager/"
local pkgfilepath = lfs.currentdir():gsub("\\", "/"):gsub("/$", "") .. "/.figman.json"
lfs.mkdir(cachedir:gsub("figmanager/$", ""))
lfs.mkdir(configdir:gsub("figmanager/$", ""))
lfs.mkdir(cachedir)
lfs.mkdir(configdir)

if not utils.exists(configdir .. "config.json") then
  local file = assert(io.open(configdir .. "config.json", "w+"))
  file:write(dkjson.encode(config))
  file:close()
end

config = dkjson.decode(utils.readfile(configdir .. "config.json"))
lfs.mkdir(lfs.currentdir():gsub("\\", "/"):gsub("/$", "") .. "/" .. config.libdir .. "/")

if not utils.exists(pkgfilepath) then
  local file = assert(io.open(pkgfilepath, "w+"))
  file:write("[]")
  file:close()
end

if not utils.exists(cachedir .. "repos.json") then
  local file = assert(io.open(cachedir .. "repos.json", "w+"))
  file:write(dkjson.encode(repos))
  file:close()
end

local iter = 1
for _, v in pairs(arg) do
  if v:match("^%-[^.]") then
    for _, w in ipairs(utils.split(v:gsub("^%-", ""), " ")) do
      opts = opts .. w
    end
  elseif iter == 1 then
    action = v
    iter = iter + 1
  else
    table.insert(args, v)
    iter = iter + 1
  end
end

if action ~= "update" and not (opts:match("u")) then
  repos = dkjson.decode(utils.readfile(cachedir .. "repos.json"))
end

local pkgfile = assert(io.open(pkgfilepath, "r"))
local pkgtbl = dkjson.decode(pkgfile:read("a"))
pkgfile:close()

local function updatecache()
  print("Updating cache...")

  local file = assert(io.open(cachedir .. "repos.json", "w+"))
  file:write(dkjson.encode(repos))
  file:close()

  for k, v in pairs(repos) do
    print("Getting repo " .. k .. " at url " .. v)
    local response = assert(http.request(v))
    local repofile = assert(io.open(cachedir .. k, "w+"))
    repofile:write(response)
    repofile:close()
    print("Done!")
  end
end

local function getcachedrepos()
  reposdecoded = {}
  for k in pairs(repos) do
    local file = assert(io.open(cachedir .. k, "r"))
    reposdecoded[k] = dkjson.decode(file:read("a"))
    file:close()
  end
end

---@param lib string
---@param ext string?
---@param nodeps boolean?
---@param type "PACKAGE"|"ASSET"|nil
local function get(lib, ext, nodeps, pkgtype)
  assert(lib, "The library to fetch is required")
  print("Getting " .. lib)
  pkgtype = pkgtype or "PACKAGE"

  for repo, v in pairs(reposdecoded) do
    local repodir = lfs.currentdir():gsub("\\", "/"):gsub("/$", "") .. "/" .. config.libdir .. "/" .. repo
    lfs.mkdir(repodir)

    for k, w in pairs(v) do
      if k == lib then
        if k:match("/") then
          local split = utils.split(k, "/")
          for i in pairs(split) do
            lfs.mkdir(repodir .. "/" .. (k:match((".-/"):rep(i)) or split[1]))
          end
        end
        if not utils.exists(repodir .. "/" .. k .. ".lua") then
          local file = assert(io.open(repodir .. "/" .. k .. (ext or ".lua"), "w"))
          file:write("")
          file:close()
        end
        if type(w) == "string" then
          local file = assert(io.open(repodir .. "/" .. k .. (ext or ".lua"), "w+"))
          local response = assert(http.request(w))
          file:write(response)
          file:close()
          pkgtbl[lib] = pkgtype
        elseif w.url then
          if not nodeps then
            print("Fetching dependencies")
            for _, x in pairs(w.dependencies or {}) do
              get(x)
            end
          end

          local file = assert(io.open(repodir .. "/" .. k .. (ext or ".lua"), "w+"))
          local response = assert(http.request(w.url))
          file:write(response)
          file:close()
          pkgtbl[lib] = pkgtype
        elseif w.bundle and not nodeps then
          print(k .. " is a bundle. Getting packages.")
          for _, pkg in pairs(w.assets) do
            get(pkg, "", false, "ASSET")
          end
          for _, pkg in pairs(w.bundle) do
            get(pkg)
          end
          pkgtbl[lib] = "BUNDLE"
        end
        return
      end
    end
  end

  print("Library " .. lib .. " not found. If you didn't ask for it to be installed, another library needs it and you should install it manually")
end

if opts:match("u") then
  updatecache()
end
if opts:match("h") then
  print("fetch: Fetches a library")
  print("  aliases: get")
  print("update: Updates the cache")
  print("upgrade: Upgrades libraries")
  print("list: Lists available libraries")
  print("")
  print("options:")
  print("  -u: Updates the cache before running the action")
  print("  -h: displays this message")
end

local function remove(lib, ext)
  for repo, v in pairs(reposdecoded) do
    for lib in pairs(v) do
      if lib == args[1] then
        if lib.bundle then
          for k in pairs(lib.assets or {}) do
            remove(k, "")
          end
          for k in pairs(lib.bundle) do
            remove(k)
          end
        else
          assert(os.remove(lfs.currentdir():gsub("\\", "/"):gsub("/$", "") .. "/" .. config.libdir .. "/" .. repo .. "/" .. lib .. (ext or ".lua")))
        end
        pkgtbl[lib] = nil
      end
    end
  end
end

if action == "update" then
  updatecache()
elseif action == "upgrade" then
  getcachedrepos()
  for k, v in pairs(pkgtbl) do
    if v == "ASSET" then
      get(k, "", true)
    else
      get(k, nil, true)
    end
  end
elseif action == "get" then
  getcachedrepos()
  get(args[1])
elseif action == "list" then
  getcachedrepos()
  
  for _, v in pairs(reposdecoded) do
    for lib in pairs(v) do
      print(lib)
    end
  end
elseif action == "remove" then
  getcachedrepos()
  remove(args[1])
end

local file = assert(io.open(pkgfilepath, "w+"))
file:write(dkjson.encode(pkgtbl))
file:close()

