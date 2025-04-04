local system = require('coop.vim').system
local coop = require('coop')
local uv = require('coop.uv')

local iswin = vim.loop.os_uname().version:match('Windows')
local function is_fs_root(path)
  if iswin then
    return path:match('^%a:$')
  else
    return path == '/'
  end
end

local function traverse_parents(path, cb)
  path = vim.loop.fs_realpath(path)
  local dir = path
  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    dir = vim.fs.dirname(dir)
    if not dir then
      return
    end
    -- If we can't ascend further, then stop looking.
    if cb(dir, path) then
      return dir, path
    end
    if is_fs_root(dir) then
      break
    end
  end
end

--- This can be replaced with `vim.fs.relpath` once minimum neovim version is at least 0.11.
local function is_descendant(root, path)
  if not path then
    return false
  end

  local function cb(dir, _)
    return dir == root
  end

  local dir, _ = traverse_parents(path, cb)

  return dir == root
end

local function is_library(fname)
  local user_home = vim.fs.normalize(vim.env.HOME)
  local cargo_home = os.getenv('CARGO_HOME') or user_home .. '/.cargo'
  local registry = cargo_home .. '/registry/src'
  local git_registry = cargo_home .. '/git/checkouts'

  local rustup_home = os.getenv('RUSTUP_HOME') or user_home .. '/.rustup'
  local toolchains = rustup_home .. '/toolchains'

  for _, item in ipairs({ toolchains, registry, git_registry }) do
    if is_descendant(item, fname) then
      local clients = vim.lsp.get_lsp_clients({ name = 'rust_analyzer' })
      return #clients > 0 and clients[#clients].config.root_dir or nil
    end
  end
end

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_dir = function(bufnr, done_callback)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local reuse_active = is_library(fname)
    if reuse_active then
      return reuse_active
    end

    local cargo_crate_dir = vim.fs.root(0, 'Cargo.toml')

    local cmd = {
      'cargo',
      'metadata',
      '--no-deps',
      '--format-version',
      '1',
      '--manifest-path',
      cargo_crate_dir .. '/Cargo.toml',
    }

    local result = coop
      .spawn(function()
        return system(cmd)
      end)
      :await(5000, 20)

    local cargo_workspace_root
    if result and result.stdout then
      result = vim.json.decode(result.stdout)
      if result then
        cargo_workspace_root = vim.fs.normalize(result['workspace_root'])
      end
    end

    done_callback(cargo_workspace_root or cargo_crate_dir)
  end,
  capabilities = {
    experimental = {
      serverStatusNotification = true,
    },
  },
  before_init = function(init_params, config)
    -- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
    if config.settings and config.settings['rust-analyzer'] then
      init_params.initializationOptions = config.settings['rust-analyzer']
    end
  end,
}
