---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'saecki/crates.nvim',
    tag = 'stable',
    event = 'BufRead Cargo.toml',
    ---@module "crates.config"
    ---@type crates.UserConfig
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
      completion = {
        coq = {
          enabled = false,
        },
        cmp = {
          enabled = false,
        },
      },
    },
  },
}
