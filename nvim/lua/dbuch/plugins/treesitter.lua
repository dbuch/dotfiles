---@return string[]
local function ensure_installed()
  local base = {
    'c',
    'css',
    'c_sharp',
    'cpp',
    'lua',
    'rust',
    'html',
    'javascript',
    'typescript',
    'wgsl',
    'zig',
    'sql',
    'markdown',
    'markdown_inline',
    'python',
    'regex',
    'query',
    'toml',
    'yaml',
    'json',
    'xml',
    'vim',
    'vimdoc',
    'gitcommit',
    'gitignore',
    'gitattributes',
    'git_config',
    'git_rebase',
  }
  if not vim.uv.os_uname().sysname:match 'Windows' then
    table.insert(base, 'bash')
  end
  return base
end

---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    --lazy = false,
    opts = {
      enable = true,
      max_lines = 3,
      trim_scope = 'outer',
    },
    config = true,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    version = false,
    build = ':TSUpdate',
    event = { 'VeryLazy' },
    init = function(plugin)
      require('lazy.core.loader').add_to_rtp(plugin)
      require 'nvim-treesitter.query_predicates'
    end,
    dependencies = {
      -- 'nvim-treesitter/nvim-treesitter-textobjects',
      { 'nushell/tree-sitter-nu' },
    },
    opts = {
      ensure_installed = ensure_installed(),
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      -- textobjects = {
      --   enable = true,
      --   lookahead = true,
      --   lsp_interop = {
      --     enable = true,
      --   },
      -- },
      indent = {
        'enabled',
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
      matchup = {
        enable = true,
      },
      fold = {
        enable = true,
        disable = { 'rst', 'make' },
      },
      context_commentstring = { enable = true, enable_autocmd = false },
      injections = {
        enable = true,
      },
      disable = function(_lang, buf)
        local max_filesize = 1024 * 1024 -- MiB
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          vim.notify('Treesitter is disabled due to huge filesize (1MiB)', vim.log.levels.WARN)
          return true
        end
      end,
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
  },
}
