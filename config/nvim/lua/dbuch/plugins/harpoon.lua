---@module 'lazy'
---@type LazyPluginSpec[]
return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    ---@module 'harpoon'
    ---@type HarpoonPartialSettings
    opts = {
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local harpoon = require('harpoon')
      local keys = {
        {
          '<leader>h',
          function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = 'Harpoon Quick Menu',
        },
      }

      for i = 0, 9 do
        table.insert(keys, {
          '<leader>' .. i,
          function()
            local list = harpoon:list()
            ---@type HarpoonItem?
            local slot = list:get(i)

            if slot and not slot.value:is_empty() then
              return list:select(i)
            end

            if i >= list:length() then
              ---@type HarpoonItem
              local item = list.config.create_list_item(list.config)
              local val = item and item.value

              if not string.is_empty(val) and not list:get_by_value(val) then
                list:add(item)
                vim.notify("Harpoon'ed: " .. item.value)
              end
            end
          end,
          desc = 'Harpoon to File ' .. i,
        })
      end
      return keys
    end,
  },
}
