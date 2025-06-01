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
    'typst',
  }
  if not vim.uv.os_uname().sysname:match('Windows') then
    table.insert(base, 'bash')
  end
  return base
end

---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'User TSAttached' },
    opts = {
      enable = true,
      max_lines = 3,
      trim_scope = 'outer',
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false,
    build = ':TSUpdate',
    lazy = false,
    -- event = { 'VeryLazy' },
    init = function(plugin)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end

          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          local ft = vim.bo.filetype
          local lang = vim.treesitter.language.get_lang(ft)
          vim.api.nvim_exec_autocmds(
            'User',
            { pattern = 'TSAttached', data = { buf = args.buf, lang = lang } }
          )
        end,
      })

      -- require('lazy.core.loader').add_to_rtp(plugin)
      -- require('nvim-treesitter.query_predicates')
    end,
    dependencies = {
      { 'nushell/tree-sitter-nu' },
    },
    opts_extend = { 'ensure_installed' },
    opts = {
      ensure_installed = ensure_installed(),
      auto_install = true,
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
      require('nvim-treesitter').install(opts.ensure_installed)
    end,
  },
}
