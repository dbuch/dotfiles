local M = {}

function M.get_root_for_position(line, col, root_lang_tree)
  if not root_lang_tree then
    root_lang_tree = vim.treesitter.get_parser()
  end

  local lang_tree = root_lang_tree:language_for_range({ line, col, line, col })

  while true do
    for _, tree in pairs(lang_tree:trees()) do
      local root = tree:root()

      if root and vim.treesitter.is_in_node_range(root, line, col) then
        return root, tree, lang_tree
      end
    end

    if lang_tree == root_lang_tree then
      break
    end

    -- This case can happen when the cursor is at the start of a line that ends a injected region,
    -- e.g., the first `]` in the following lua code:
    -- ```
    -- vim.cmd[[
    -- ]]
    -- ```
    lang_tree = lang_tree:parent()
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end

function M.get_node_at_cursor(winnr, ignore_injected_langs)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)
  local root_lang_tree = vim.treesitter.get_parser(buf)
  if not root_lang_tree then
    return
  end

  local root ---@type TSNode|nil
  if ignore_injected_langs then
    for _, tree in pairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if
        tree_root and vim.treesitter.is_in_node_range(tree_root, cursor_range[1], cursor_range[2])
      then
        root = tree_root
        break
      end
    end
  else
    root = M.get_root_for_position(cursor_range[1], cursor_range[2], root_lang_tree)
  end

  if not root then
    return
  end

  return root:named_descendant_for_range(
    cursor_range[1],
    cursor_range[2],
    cursor_range[1],
    cursor_range[2]
  )
end

---@type table<integer, table<TSNode|nil>>
local selections = {}

function M.init_selection()
  local buf = vim.api.nvim_get_current_buf()
  vim.treesitter.get_parser():parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
  local node = M.get_node_at_cursor()
  selections[buf] = { [1] = node }
  M.update_selection(buf, node)
end

-- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
---comment
---@param range integer[]
---@param buf integer|nil
---@return integer, integer, integer, integer
local function get_vim_range(range, buf)
  ---@type integer, integer, integer, integer
  local srow, scol, erow, ecol = unpack(range)
  srow = srow + 1
  scol = scol + 1
  erow = erow + 1

  if ecol == 0 then
    -- Use the value of the last col of the previous row instead.
    erow = erow - 1
    if not buf or buf == 0 then
      ecol = vim.fn.col({ erow, '$' }) - 1
    else
      ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
    end
    ecol = math.max(ecol, 1)
  end
  return srow, scol, erow, ecol
end

-- Set visual selection to node
-- @param selection_mode One of "charwise" (default) or "v", "linewise" or "V",
--   "blockwise" or "<C-v>" (as a string with 5 characters or a single character)
function M.update_selection(buf, node, selection_mode)
  local start_row, start_col, end_row, end_col =
    get_vim_range({ vim.treesitter.get_node_range(node) }, buf)

  local v_table = { charwise = 'v', linewise = 'V', blockwise = '<C-v>' }
  selection_mode = selection_mode or 'charwise'

  -- Normalise selection_mode
  if vim.tbl_contains(vim.tbl_keys(v_table), selection_mode) then
    selection_mode = v_table[selection_mode]
  end

  -- enter visual mode if normal or operator-pending (no) mode
  -- Why? According to https://learnvimscriptthehardway.stevelosh.com/chapters/15.html
  --   If your operator-pending mapping ends with some text visually selected, Vim will operate on that text.
  --   Otherwise, Vim will operate on the text between the original cursor position and the new position.
  local mode = vim.api.nvim_get_mode()
  if mode.mode ~= selection_mode then
    -- Call to `nvim_replace_termcodes()` is needed for sending appropriate command to enter blockwise mode
    selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
    vim.api.nvim_cmd({ cmd = 'normal', bang = true, args = { selection_mode } }, {})
  end

  vim.api.nvim_win_set_cursor(0, { start_row, start_col - 1 })
  vim.cmd('normal! o')
  vim.api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
end

-- Get the range of the current visual selection.
--
-- The range starts with 1 and the ending is inclusive.
---@return integer, integer, integer, integer
local function visual_selection_range()
  local _, csrow, cscol, _ = unpack(vim.fn.getpos('v')) ---@type integer, integer, integer, integer
  local _, cerow, cecol, _ = unpack(vim.fn.getpos('.')) ---@type integer, integer, integer, integer

  local start_row, start_col, end_row, end_col ---@type integer, integer, integer, integer

  if csrow < cerow or (csrow == cerow and cscol <= cecol) then
    start_row = csrow
    start_col = cscol
    end_row = cerow
    end_col = cecol
  else
    start_row = cerow
    start_col = cecol
    end_row = csrow
    end_col = cscol
  end

  return start_row, start_col, end_row, end_col
end

---@param node TSNode
---@return boolean
local function range_matches(node)
  local csrow, cscol, cerow, cecol = visual_selection_range()
  local srow, scol, erow, ecol = get_vim_range({ node:range() })
  return srow == csrow and scol == cscol and erow == cerow and ecol == cecol
end

---@param get_parent fun(node: TSNode): TSNode|nil
---@return fun():nil
local function select_incremental(get_parent)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    local nodes = selections[buf]

    local csrow, cscol, cerow, cecol = visual_selection_range()
    -- Initialize incremental selection with current selection
    if not nodes or #nodes == 0 or not range_matches(nodes[#nodes]) then
      local parser = vim.treesitter.get_parser()
      if parser == nil then
        return
      end
      parser:parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
      local node = parser:named_node_for_range(
        { csrow - 1, cscol - 1, cerow - 1, cecol },
        { ignore_injections = false }
      )
      M.update_selection(buf, node)
      if nodes and #nodes > 0 then
        table.insert(selections[buf], node)
      else
        selections[buf] = { [1] = node }
      end
      return
    end

    -- Find a node that changes the current selection.
    local node = nodes[#nodes] ---@type TSNode
    while true do
      local parent = get_parent(node)
      if not parent or parent == node then
        -- Keep searching in the parent tree
        local root_parser = vim.treesitter.get_parser()
        if root_parser == nil then
          return
        end
        root_parser:parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
        local current_parser =
          root_parser:language_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
        if root_parser == current_parser then
          node = root_parser:named_node_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
          M.update_selection(buf, node)
          return
        end
        -- NOTE: parent() method is private
        local parent_parser = current_parser:parent()
        if parent_parser ~= nil then
          parent = parent_parser:named_node_for_range({ csrow - 1, cscol - 1, cerow - 1, cecol })
        end
      end
      node = parent
      local srow, scol, erow, ecol = get_vim_range({ node:range() })
      local same_range = (srow == csrow and scol == cscol and erow == cerow and ecol == cecol)
      if not same_range then
        table.insert(selections[buf], node)
        if node ~= nodes[#nodes] then
          table.insert(nodes, node)
        end
        M.update_selection(buf, node)
        return
      end
    end
  end
end

M.node_incremental = select_incremental(function(node)
  return node:parent() or node
end)

---@param bufnr? integer
---@return string|nil
local function get_buf_lang(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return vim.treesitter.language.get_lang(ft)
end

M.scope_incremental = select_incremental(function(node)
  local lang = get_buf_lang()
  if not lang then
    return node:parent()
  end

  local query = vim.treesitter.query.get(lang, 'locals')
  if not query then
    return node:parent()
  end

  local parent = node
  while parent do
    for id, n in query:iter_captures(parent, 0, parent:start(), parent:end_()) do
      local name = query.captures[id]
      if name == 'scope' and parent ~= node then
        return parent
      end
    end
    parent = parent:parent()
  end

  return node:parent()
end)

function M.node_decremental()
  local buf = vim.api.nvim_get_current_buf()
  local nodes = selections[buf]
  if not nodes or #nodes < 2 then
    return
  end

  table.remove(selections[buf])
  local node = nodes[#nodes] ---@type TSNode
  M.update_selection(buf, node)
end

local FUNCTION_DESCRIPTIONS = {
  init_selection = 'Start selecting nodes with nvim-treesitter',
  node_incremental = 'Increment selection to named node',
  scope_incremental = 'Increment selection to surrounding scope',
  node_decremental = 'Shrink selection to previous named node',
}

M.keymaps = {
  init_selection = '<C-space>',
  node_incremental = '<C-space>',
  scope_incremental = false,
  node_decremental = '<bs>',
}

---@param bufnr integer
function M.attach(bufnr)
  for funcname, mapping in pairs(M.keymaps) do
    if mapping then
      local mode = funcname == 'init_selection' and 'n' or 'x'
      local rhs = M[funcname] ---@type function

      if not rhs then
        vim.notify('Unknown keybinding: ' .. funcname .. debug.traceback(), vim.log.levels.ERROR)
      else
        vim.keymap.set(
          mode,
          mapping,
          rhs,
          { buffer = bufnr, silent = true, desc = FUNCTION_DESCRIPTIONS[funcname] }
        )
      end
    end
  end
end

function M.detach(bufnr)
  for f, mapping in pairs(M.keymaps) do
    if mapping then
      local mode = f == 'init_selection' and 'n' or 'x'
      local ok, err = pcall(vim.keymap.del, mode, mapping, { buffer = bufnr })
      if not ok then
        vim.notify(string.format('%s "%s" for mode %s', err, mapping, mode), vim.log.levels.ERROR)
      end
    end
  end
end

return M
