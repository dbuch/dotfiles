---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'luukvbaal/statuscol.nvim',
    enabled = true,
    event = 'VeryLazy',
    dependencies = {
      'lewis6991/gitsigns.nvim',
    },
    config = function(_, _)
      local builtin = require('statuscol.builtin')
      local lnum_func = function(args)
        if args.rnu ~= 0 and not args.nu then
          return ''
        end

        if args.virtnum ~= 0 then
          return '%='
        end

        local highlight = ((args.relnum % 10 > 0) and '%#CurrentLineNr#' or '%#Normal#')
        return highlight .. ((args.relnum == 0) and '%l%=' or '%=%l')
      end

      require('statuscol').setup({
        setopt = true,
        segments = {
          { text = { '%C' }, click = 'v:lua.ScFa' },
          { text = { '%s' }, click = 'v:lua.ScSa' },
          {
            text = { lnum_func, ' ' },
            condition = { true, builtin.not_empty },
            click = 'v:lua.ScLa',
          },
        },
      })
    end,
  },
}
