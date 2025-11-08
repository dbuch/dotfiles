---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'j-hui/fidget.nvim',
    lazy = false,
    opts = {
      progress = {
        poll_rate = 5,
        ignore_done_already = true,
        ignore_empty_message = true,
        lsp = {
          progress_ringbuf_size = 2048,
        },
      },
      notification = {
        override_vim_notify = true,
        window = {
          normal_hl = 'Normal',
        },
      },
    },
  },
}
