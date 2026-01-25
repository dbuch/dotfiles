local attach_augroup = vim.api.nvim_create_augroup('dbuch.lsp', {})

---@param cb fun(client?:vim.lsp.Client, bufnr?:integer): boolean?
---@param augroup? number|nil
local function on_attach(cb, augroup)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = augroup,
    callback = function(args)
      ---@type integer
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client ~= nil then
        return cb(client, bufnr)
      end
    end,
  })
end

on_attach(function(_client, _bufnr)
  if safe_require('lsp_utils') then
    -- Detach on first succes require
    return true
  end
end, attach_augroup)

on_attach(function(_client, bufnr)
  local map = vim.keymap.set
  map('n', 'ca', require('tiny-code-action').code_action, { silent = true, buffer = bufnr })
  map('n', 'cd', ':Trouble lsp_definitions<CR>', { silent = true, buffer = bufnr })
  map('n', 'cn', vim.lsp.buf.rename, { silent = true, buffer = bufnr })
  map('n', 't', ':Trouble diagnostics toggle<CR>', { silent = true, buffer = bufnr })
  map('n', 'cr', ':Trouble lsp toggle<CR>', { silent = true, buffer = bufnr })
end, attach_augroup)

require('dbuch.diagnostic').config()

local enabled_lsps = {
  -- Shell
  'nushell',
  'bashls',

  -- Data/Exchangeable formats ls
  'html', -- Html
  'jsonls', -- Json
  'cssls', -- Css
  -- 'taplo', -- Toml
  'tombi', -- Toml
  'lemminx', -- XML
  'yamlls', -- Yaml

  -- Programming
  -- 'rust_analyzer',
  'lua_ls',
  'clangd',

  'pyright',
  'ruff',
  'zls',

  'roslyn',
  'wgsl',

  -- Web Programming
  'ts_ls',
  'denols',

  -- Writing
  'tinymist',
  'typos_lsp',
}

vim.lsp.config('*', {
  root_markers = { '.git' },
})

vim.lsp.enable(enabled_lsps)
