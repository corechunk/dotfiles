-- Bootstrap packer.nvim
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Initialize packer with plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'          -- Package manager
  use 'nvim-tree/nvim-tree.lua'         -- File tree
  use 'nvim-lua/plenary.nvim'           -- Dependency for Telescope
  use 'nvim-telescope/telescope.nvim'   -- Command palette
  use 'akinsho/toggleterm.nvim'         -- Integrated terminal

  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- Basic settings
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.showmode = false  -- Hide mode indicator (e.g., -- INSERT --) for a cleaner terminal experience

-- Keybindings
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Toggle file tree (Ctrl+T)
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-t>', function()
  require('nvim-tree.api').tree.toggle()
end, opts)

-- Ctrl+Shift+T: Focus tree (open if closed, focus if open, keep focus if already focused)
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-S-t>', function()
  local api = require('nvim-tree.api')
  if not api.tree.is_visible() then
    api.tree.open()
  end
  api.tree.focus()
end, opts)

-- Global terminal instance
_G.my_terminal = nil

-- Terminal keybindings
-- Ctrl+Alt+C: Open terminal in current directory (only if no terminal exists) and focus it
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-M-c>', function()
  -- Check if the terminal instance exists and is valid
  if _G.my_terminal then
    -- If the buffer is invalid (e.g., terminal was closed with exit), reset the instance
    if not vim.api.nvim_buf_is_valid(_G.my_terminal.bufnr) then
      _G.my_terminal = nil
    else
      -- If the terminal is hidden but still exists, don't create a new one
      print("Terminal already exists. Use Ctrl+Shift+F to toggle.")
      return
    end
  end

  -- Create a new terminal if none exists
  if not _G.my_terminal then
    local Terminal = require('toggleterm.terminal').Terminal
    _G.my_terminal = Terminal:new({
      id = 1,
      direction = 'horizontal',  -- Ensure horizontal split
      dir = vim.fn.getcwd(),
      size = 15,
      on_exit = function()
        -- Reset the global instance when the terminal process exits (e.g., with exit)
        _G.my_terminal = nil
      end
    })
    _G.my_terminal:open()
    vim.api.nvim_set_current_win(_G.my_terminal.window)
    vim.cmd('startinsert')
    _G.terminal_size_state = 'small'
  end
end, opts)

-- Ctrl+Shift+C: Toggle terminal visibility
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-S-c>', function()
  if _G.my_terminal then
    if not vim.api.nvim_buf_is_valid(_G.my_terminal.bufnr) then
      _G.my_terminal = nil
      print("Terminal was closed. Use Ctrl+Alt+C to create a new one.")
      return
    end
    _G.my_terminal:toggle()
    if _G.my_terminal:is_open() then
      vim.api.nvim_set_current_win(_G.my_terminal.window)
      vim.cmd('startinsert')
    end
  else
    print("No terminal exists. Use Ctrl+Alt+C to create one.")
  end
end, opts)

-- Ctrl+Shift+R: Toggle terminal size between small and full (only if terminal exists and is open)
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-S-r>', function()
  if _G.my_terminal then
    if not vim.api.nvim_buf_is_valid(_G.my_terminal.bufnr) then
      _G.my_terminal = nil
      print("Terminal was closed. Use Ctrl+Alt+C to create a new one.")
      return
    end
    if _G.my_terminal:is_open() then
      -- Ensure the terminal is in a horizontal split
      if _G.my_terminal.direction ~= 'horizontal' then
        _G.my_terminal:close()
        _G.my_terminal.direction = 'horizontal'
      end
      -- Toggle the size
      local new_size
      if _G.terminal_size_state == 'small' then
        new_size = vim.o.lines - 10
        _G.terminal_size_state = 'full'
      else
        new_size = 15
        _G.terminal_size_state = 'small'
      end
      -- Update the terminal instance's size
      _G.my_terminal.size = new_size
      -- Close and reopen to apply the new size
      _G.my_terminal:close()
      -- Force a full redraw of the UI
      vim.cmd('redraw!')
      -- Reopen with the new size
      _G.my_terminal:open()
      -- Force the window to resize to the new size
      vim.api.nvim_win_set_height(_G.my_terminal.window, new_size)
      vim.api.nvim_set_current_win(_G.my_terminal.window)
      vim.cmd('startinsert')
    else
      print("Terminal is not open. Use Ctrl+Shift+F to open it.")
    end
  else
    print("No terminal exists. Use Ctrl+Alt+C to create one.")
  end
end, opts)

-- Ctrl+Shift+F: Toggle terminal visibility
-- Map in both normal and terminal modes
map({'n', 't'}, '<C-S-f>', function()
  if _G.my_terminal then
    if not vim.api.nvim_buf_is_valid(_G.my_terminal.bufnr) then
      _G.my_terminal = nil
      print("Terminal was closed. Use Ctrl+Alt+C to create a new one.")
      return
    end
    if _G.my_terminal:is_open() then
      _G.my_terminal:close()
    else
      _G.my_terminal:open()
      vim.api.nvim_set_current_win(_G.my_terminal.window)
      vim.cmd('startinsert')
    end
  else
    print("No terminal exists. Use Ctrl+Alt+C to create one.")
  end
end, opts)

-- Buffer switching (Ctrl+1 to Ctrl+9)
for i = 1, 9 do
  map('n', '<C-' .. i .. '>', ':' .. i .. 'b<CR>', opts)
end

-- Last buffer (Ctrl+L)
map('n', '<C-l>', ':b#<CR>', opts)

-- Close buffer (Ctrl+W)
map('n', '<C-w>', ':bd<CR>', opts)

-- Command palette (Ctrl+Space)
map('n', '<C-Space>', ':Telescope commands<CR>', opts)

-- Previous/Next buffer (Ctrl+[, Ctrl+])
map('n', '<C-[>', ':bprevious<CR>', opts)
map('n', '<C-]>', ':bnext<CR>', opts)

-- Move cursor 5 lines (Ctrl+, and Ctrl+.)
map('n', '<C-,>', '5k', opts)
map('n', '<C-.>', '5j', opts)

-- Plugin configs
require('nvim-tree').setup({
  view = {
    side = 'left',
    width = 30
  },
  actions = {
    open_file = {
      quit_on_open = true
    }
  },
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')
    api.config.mappings.default_on_attach(bufnr)
    -- Unmap any potential conflicts with Ctrl+Alt+C (safely)
    vim.keymap.del('n', '<C-t>', { buffer = bufnr })
    pcall(vim.keymap.del, 'n', '<C-M-c>', { buffer = bufnr })
    vim.keymap.set('n', '<C-t>', ':NvimTreeToggle<CR>', { buffer = bufnr, noremap = true, silent = true })
  end
})

require('toggleterm').setup({
  open_mapping = nil,
  direction = 'horizontal',
  size = 15,
  start_in_insert = true,
  on_open = function(term)
    -- Unmap <Esc> to prevent closing the terminal and keep it in insert mode
    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
    -- Automatically re-enter insert mode when entering the terminal buffer
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = term.bufnr,
      callback = function()
        vim.cmd('startinsert')
      end
    })
  end
})

require('telescope').setup()

-- Initialize terminal size state
_G.terminal_size_state = 'small'
