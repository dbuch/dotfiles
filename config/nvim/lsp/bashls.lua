---@type vim.lsp.Config
return {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { 'zsh', 'bash', 'sh' },
  settings = {
    bashIde = {
      globPattern = vim.env.GLOB_PATTERN or '@(.sh|.inc|.bash|.command)',
      shellcheckArguments = {
        '-e',
        'SC2086', -- Double quote to prevent globbing and word splitting
        '-e',
        'SC2155', -- Declare and assign separately to avoid masking return values
      },
    },
  },
}
