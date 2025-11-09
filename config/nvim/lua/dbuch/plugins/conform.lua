---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
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
      notify_on_error = false,
      formatters_by_ft = {
        -- c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
        -- javascript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
        -- javascriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
        -- json = { 'prettier', stop_on_first = true, name = 'dprint', timeout_ms = 500 },
        -- jsonc = { 'prettier', stop_on_first = true, name = 'dprint', timeout_ms = 500 },
        -- less = { 'prettier' },
        -- markdown = { 'prettier' },
        -- scss = { 'prettier' },
        -- sh = { 'shfmt' },
        -- typescript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
        -- typescriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
        lua = { 'stylua' },
        python = { 'ruff_format' },
        tombi = { name = 'tombi', timeout_ms = 500, lsp_format = 'prefer' },
        c = { 'uncrustify' },
        just = { 'just' },
        rust = { name = 'rust_analyzer', timeout_ms = 500, lsp_format = 'prefer' },
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
      ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
      formatters = {
        injected = {
          options = { ignore_errors = true },
        },
      },
      format_on_save = function()
        if vim.g.minifiles_active then
          return nil
        end

        if not vim.g.autoformat then
          return nil
        end

        return {}
      end,
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
