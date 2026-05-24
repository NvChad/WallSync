local M = {}

local uv = vim.uv or vim.loop

local defaults = {
  auto_start = true,
  auto_install_templates = true,
  notify = true,
  debounce_ms = 500,
  stability_timeout_ms = 2000,
  stability_interval_ms = 100,
  templates = {
    dark = "templates/dark.lua",
    light = "templates/light.lua",
  },
  wal_templates = {
    dark = vim.fn.expand "~/.config/wal/templates/base46-dark.lua",
    light = vim.fn.expand "~/.config/wal/templates/base46-light.lua",
  },
  cache = {
    dark = vim.fn.expand "~/.cache/wal/base46-dark.lua",
    light = vim.fn.expand "~/.cache/wal/base46-light.lua",
  },
  colors_file = vim.fn.expand "~/.cache/wal/colors",
  theme_output = vim.fn.stdpath "data" .. "/lazy/base46/lua/base46/themes/chadwal.lua",
  fallback_theme = vim.fn.stdpath "data" .. "/lazy/base46/lua/base46/themes/gruvchad.lua",
  reload = function()
    require("nvchad.utils").reload()
  end,
}

local state = {
  config = vim.deepcopy(defaults),
  processing = false,
  last_hash = nil,
  watchers = {},
  debounce_timer = nil,
}

local function path_join(...)
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":p:h:h:h")
end

local function notify(message, level)
  if state.config.notify then
    vim.notify(message, level or vim.log.levels.INFO, { title = "WallSync" })
  end
end

local function read_file(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end

  local content = file:read "*a"
  file:close()
  return content
end

local function write_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")

  local file = io.open(path, "wb")
  if not file then
    return false
  end

  file:write(content)
  file:close()
  return true
end

local function copy_file(source, destination, skip_if_exists)
  if skip_if_exists and vim.fn.filereadable(destination) == 1 then
    return true
  end

  local content = read_file(source)
  if not content then
    return false
  end

  return write_file(destination, content)
end

local function file_hash(path)
  local content = read_file(path)
  if not content then
    return nil
  end

  return vim.fn.sha256(content)
end

local function is_dark(hex_color)
  local color = hex_color:gsub("^#", "")
  if #color < 6 then
    return true
  end

  local red = tonumber(color:sub(1, 2), 16)
  local green = tonumber(color:sub(3, 4), 16)
  local blue = tonumber(color:sub(5, 6), 16)
  if not red or not green or not blue then
    return true
  end

  return ((red * 299 + green * 587 + blue * 114) / 1000) < 128
end

local function current_mode()
  local content = read_file(state.config.colors_file)
  local first_color = content and content:match "([^\r\n]+)"
  if not first_color then
    return "dark"
  end

  return is_dark(first_color) and "dark" or "light"
end

local function wait_for_stability(path, done)
  local timeout = state.config.stability_timeout_ms
  local interval = state.config.stability_interval_ms
  local elapsed = 0
  local previous_hash = file_hash(path)

  if not previous_hash then
    done(false)
    return
  end

  local function check()
    elapsed = elapsed + interval
    local current_hash = file_hash(path)
    if current_hash == previous_hash or elapsed >= timeout then
      done(true)
      return
    end

    previous_hash = current_hash
    vim.defer_fn(check, interval)
  end

  vim.defer_fn(check, interval)
end

function M.install_templates()
  local root = plugin_root()
  local installed = true

  for mode, relative_path in pairs(state.config.templates) do
    local source = path_join(root, relative_path)
    local destination = state.config.wal_templates[mode]
    installed = copy_file(source, destination, false) and installed
  end

  if installed then
    notify "Installed Pywal templates"
  else
    notify("Could not install every Pywal template", vim.log.levels.WARN)
  end

  return installed
end

function M.sync()
  if state.processing then
    return
  end

  state.processing = true

  if state.config.auto_install_templates then
    M.install_templates()
  end

  local mode = current_mode()
  local source = state.config.cache[mode]

  copy_file(state.config.fallback_theme, source, true)

  wait_for_stability(source, function(ok)
    if not ok then
      notify("Theme cache is not available: " .. source, vim.log.levels.WARN)
      state.processing = false
      return
    end

    local current_hash = file_hash(source)
    if current_hash and current_hash == state.last_hash then
      state.processing = false
      return
    end

    if copy_file(source, state.config.theme_output, false) then
      state.last_hash = file_hash(state.config.theme_output)
      pcall(state.config.reload)
      notify("Synced " .. mode .. " theme")
    else
      notify("Could not copy theme to " .. state.config.theme_output, vim.log.levels.WARN)
    end

    state.processing = false
  end)
end

local function schedule_sync()
  if state.debounce_timer then
    state.debounce_timer:stop()
  else
    state.debounce_timer = uv.new_timer()
  end

  state.debounce_timer:start(state.config.debounce_ms, 0, function()
    vim.schedule(M.sync)
  end)
end

function M.start()
  if #state.watchers > 0 then
    return
  end

  local watched_dirs = {}
  for _, path in pairs(state.config.cache) do
    watched_dirs[vim.fn.fnamemodify(path, ":h")] = true
  end

  for dir in pairs(watched_dirs) do
    vim.fn.mkdir(dir, "p")

    local watcher = uv.new_fs_event()
    if watcher then
      watcher:start(dir, {}, function(_, filename)
        if filename == nil or filename == "base46-dark.lua" or filename == "base46-light.lua" then
          schedule_sync()
        end
      end)
      table.insert(state.watchers, watcher)
    end
  end

  M.sync()
end

function M.stop()
  for _, watcher in ipairs(state.watchers) do
    watcher:stop()
    watcher:close()
  end

  state.watchers = {}

  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer:close()
    state.debounce_timer = nil
  end
end

function M.setup(options)
  state.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), options or {})

  vim.api.nvim_create_user_command("WallSyncInstallTemplates", M.install_templates, {
    desc = "Install WallSync Pywal templates",
    force = true,
  })
  vim.api.nvim_create_user_command("WallSyncStart", M.start, {
    desc = "Start WallSync file watchers",
    force = true,
  })
  vim.api.nvim_create_user_command("WallSyncSync", M.sync, {
    desc = "Sync the current WallSync theme",
    force = true,
  })
  vim.api.nvim_create_user_command("WallSyncStop", M.stop, {
    desc = "Stop WallSync file watchers",
    force = true,
  })

  if state.config.auto_start then
    M.start()
  elseif state.config.auto_install_templates then
    M.install_templates()
  end
end

return M
