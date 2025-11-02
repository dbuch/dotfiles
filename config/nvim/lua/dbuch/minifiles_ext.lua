---@class FsEntry
---@field fs_type string one of "file" or "directory"
---@field name string basename of an entry (including extension)
---@field path string full path of an entry

---@class MiniFilesExt
---@field anchor_path string|nil
---@field show_dotfiles boolean
---@field show_gitignored boolean
---@field gitignored_cache table<string, boolean>

local M = {}
M.__index = M

-- Constructor
---@return MiniFilesExt
function M.new()
  local self = setmetatable({}, M)

  -- State
  self.anchor_path = nil
  self.show_dotfiles = false
  self.show_gitignored = false
  self.gitignored_cache = {}
  self.current_git_root = nil

  return self
end

function M:toggle_dotfiles()
  self.show_dotfiles = not self.show_dotfiles
  ---@module "mini.files"
  MiniFiles.refresh({
    content = {
      filter = function(entry)
        return self:combined_filter(entry)
      end,
    },
  })
end

---@param fs_entry FsEntry
---@return boolean
function M:combined_filter(fs_entry)
  -- Hide dotfiles unless explicitly showing
  if not self.show_dotfiles and vim.startswith(fs_entry.name, '.') then
    return false
  end

  -- Hide gitignored files unless explicitly showing
  if not self.show_gitignored and self:is_gitignored(fs_entry.name) then
    return false
  end

  return true
end

function M:is_gitignored(path)
  local res = vim.tbl_contains(self.gitignored_cache, path)
  return res
end

function M:detect_git_root(dir)
  local result = vim
    .system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = dir, text = true })
    :wait()

  if result.code == 0 and result.stdout then
    local root = vim.trim(result.stdout)
    if root ~= '' then
      return root
    end
  end
  return nil
end

function M:cache_is_populated()
  return self:cache_size() > 0
end

function M:cache_size()
  return vim.tbl_count(self.gitignored_cache)
end

function M:update_gitignored_cache(root)
  local path = string.gsub(root, '^minifiles://%w+/', '')
  if vim.fn.isdirectory(path) == 0 then
    return
  end

  if self.current_git_root == nil then
    self.current_git_root = self:detect_git_root(path)
  end

  if self.current_git_root == nil then
    return
  end

  local git_path = vim.fs.relpath(self.current_git_root, path)
  if git_path == nil then
    return
  end

  -- Run asynchronously using `git ls-files`
  vim.system(
    { 'git', 'ls-files', '-i', '-o', '--exclude-standard' },
    { cwd = self.current_git_root, text = true },
    function(obj)
      -- If command fails or no output, just return
      if obj.code ~= 0 or not obj.stdout then
        return
      end

      -- Process output line-by-line
      for line in obj.stdout:gmatch('[^\r\n]+') do
        if line ~= '' then
          local abs_path = vim.fn.fnamemodify(path .. '/' .. line, ':p')
          self.gitignored_cache[abs_path] = true
        end
      end
    end
  )
end

function M:subscribe_events()
  local explorer_group = vim.api.nvim_create_augroup('dbuch/minifiles_explorer', { clear = true })
  -- Handle buffer creation: bind keys and initialize gitignore cache
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local buf_id = args.data.buf_id
      local root = vim.fn.expand('%:p:h')
      -- Setup keymaps
      vim.keymap.set('n', '<C-h>', function()
        self:toggle_dotfiles()
      end, { buffer = buf_id })

      self:update_gitignored_cache(root)
    end,
  })

  -- Track open/close state
  vim.api.nvim_create_autocmd('User', {
    group = explorer_group,
    pattern = 'MiniFilesExplorerOpen',
    callback = function(args)
      ---@type FsEntry|nil
      local fs_entry = MiniFiles.get_fs_entry(args.buf)
      if fs_entry ~= nil then
        self.anchor_path = fs_entry.path
      end

      vim.g.minifiles_active = true
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = explorer_group,
    pattern = 'MiniFilesExplorerClose',
    callback = function()
      vim.g.minifiles_active = false
    end,
  })

  -- Hook into rename action
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesActionRename',
    callback = function(event)
      ---@module 'snacks'
      if Snacks and Snacks.rename then
        Snacks.rename.on_rename_file(event.data.from, event.data.to)
      end
    end,
  })
end

return M
