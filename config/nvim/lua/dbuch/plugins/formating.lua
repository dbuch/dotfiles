---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'stevearc/conform.nvim',
    event = { 'VeryLazy' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>=',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = '',
        desc = 'Format Buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_format' },
        toml = { 'taplo' },
        c = { 'uncrustify' },
        just = { 'just' },
      },
      ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
      formatters = {
        injected = {
          options = { ignore_errors = true },
        },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
