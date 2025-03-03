-- INFO: must be named lua_LS

---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
    'selene.yml',
  },
  -- Note this is ignored if the project has a .luarc.json
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        pathStrict = true,
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          '${3rd}/busted/library',
          '${3rd}/luv/library',
        },
      },
      diagnostics = {
        unusedLocalExclude = { '_*' },
        globals = {
          'it',
          'describe',
          'before_each',
          'after_each',
          'pending',
        },
      },
      doc = {
        packageName = { '_*' },
        privateName = { '_*' },
      },
    },
  },
}
