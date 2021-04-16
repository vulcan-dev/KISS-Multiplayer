local M = {}
local imgui = ui_imgui

local function generate_base_secret()
  local result = ""
  for i=0,64 do
    local char = string.char(32 + math.random() * 96)
    result = result..char
  end
  return result
end

local function save_config()
  local secret = network.base_secret
  if secret == "None" then
    secret = generate_base_secret()
  end
  local result = {
    name = ffi.string(kissui.player_name),
    addr = ffi.string(kissui.addr),
    show_nametags = kissui.show_nametags[0],
    show_drivers = kissui.show_drivers[0],
    window_opacity = kissui.window_opacity[0],
    enable_view_distance = kissui.enable_view_distance[0],
    view_distance = kissui.view_distance[0],
    base_secret = secret
  }
  local file = io.open("./settings/kissmp_config.json", "w")
  file:write(jsonEncode(result))
  io.close(file)
end

local function load_config()
  local file = io.open("./settings/kissmp_config.json", "r")
  if not file then
    if Steam and Steam.isWorking and Steam.accountLoggedIn then
      kissui.player_name = imgui.ArrayChar(32, Steam.playerName)
    end
    return
  end
  local content = file:read("*a")
  local config = jsonDecode(content or "")
  if not config then return end

  if config.name ~= nil then
    kissui.player_name = imgui.ArrayChar(32, config.name)
  end
  if config.addr ~= nil then
    kissui.addr = imgui.ArrayChar(128, config.addr)
  end
  if config.show_nametags ~= nil then
    kissui.show_nametags[0] = config.show_nametags
  end
  if config.show_drivers ~= nil then
    kissui.show_drivers[0] = config.show_drivers
  end
  if config.window_opacity ~= nil then
    kissui.window_opacity[0] = config.window_opacity
  end
  if config.view_distance ~= nil then
    kissui.view_distance[0] = config.view_distance
  end
  if config.enable_view_distance ~= nil then
    kissui.enable_view_distance[0] = config.enable_view_distance
  end
  if config.base_secret ~= nil then
    network.base_secret = config.base_secret
  end
  io.close(file)
end

local function init()
  load_config()
  if #FS:findFiles("/mods/", "KISSMultiplayer.zip", 1000) == 0 then
    kissui.incorrect_install = true
  end
    -- Hack to reload input actions
  local actions = require("lua/ge/extensions/core/input/actions")
  extensions.core_input_actions = actions
  core_input_bindings.onFirstUpdate()
end

M.save_config = save_config
M.load_config = load_config
M.onExtensionLoaded = init

return M
