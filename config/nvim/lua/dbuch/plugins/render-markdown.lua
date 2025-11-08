---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      file_types = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki' },
      heading = {
        sign = true,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      },
      checkbox = { enabled = true },
      completions = {
        coq = {
          enabled = false,
        },
        lsp = {
          enabled = true,
        },
      },
      latex = {
        enabled = false,
      },
      indent = {
        enabled = false,
      },
    },
  },
}
