-- Providers
vim.g.loaded_perl_provider = 0 -- Disable the Perl provider
vim.g.loaded_ruby_provider = 0 -- Disable the Ruby provider

-- Clipboard
vim.opt.clipboard = "unnamedplus" -- Sync nvim clipboard with system clipboard

-- Numbers
vim.opt.number = true -- Enable line number on the left side
vim.opt.relativenumber = true -- Enable relative line numbers (distance from current position)

-- Lines Behaviour
vim.opt.cursorline = true -- Enable highlighting the current line
vim.opt.signcolumn = "yes" -- Always show the sign column to prevent UI jitter when LSP diagnostics, Git signs, or debug breakpoints appear
vim.opt.scrolloff = 4 -- Keeps at least 4 lines of context above and below the cursor when scrolling

-- Wrapping
vim.opt.wrap = true -- Enable line wrapping so they don't extend out off-screen
vim.opt.linebreak = true -- When a word is near the edge, it won't break to preserve the word

-- Tab Indention
vim.opt.expandtab = true -- When true, pressing Tab inserts spaces instead of a Tab character
vim.opt.tabstop = 2 -- Sets the number of spaces that a tab character represents on screen
vim.opt.shiftwidth = 2 -- Sets the number of spaces used for each indent step
vim.opt.softtabstop = 2 -- Sets the number of spaces that a Tab keypress inserts or deletes when editing
vim.opt.autoindent = true -- Copy indentation from the previous line when starting a new line
vim.opt.breakindent = true -- Makes wrapped continuation lines visually indented to match the beginning of the original line
vim.opt.breakindentopt = "shift:2,sbr" -- Extra 2-char indent + showbreak before indent
vim.opt.showbreak = "↳ " -- Glyph shown at start of wrapped lines

-- Colours
vim.opt.termguicolors = true -- Enables 24-bit RGB (true colours) in the terminal

-- Undo
vim.opt.undofile = true -- Enable undo across sessions
vim.opt.swapfile = false -- Disable the safeguard against losing unsaved files 

-- Search
vim.opt.ignorecase = true -- Makes search patterns case-insensitive.
vim.opt.smartcase = true -- Makes search behaviour to be case-sensitive only when the search pattern contains uppercase letters.
vim.opt.hlsearch = true -- All matches during search will be highlighted in the buffer

-- Fold
vim.opt.foldlevel = 99 -- Set fold level to 99
vim.opt.foldmethod = "indent" -- Set fold method to indent
vim.opt.foldtext = "" -- Set fold text so it doesn't appear
vim.opt.fillchars = { -- Set all fill chars to fold
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- List
vim.opt.list = true -- Enables list mode
vim.opt.listchars = {  -- Set the chars used by list mode
  tab = '▸ ',
  trail = '·',
  nbsp = '␣',
}

-- Reload
vim.opt.autoread = true -- Reloads buffer when the file is changed outside of the editor
vim.opt.updatetime = 200 -- Sets the idle timeout to 200 ms

-- Buffer Behaviour
vim.opt.splitbelow = true -- Makes horizontal splits spawn below
vim.opt.splitright = true -- Makes vertical splits spawn at the right side
vim.opt.virtualedit = "block" -- Allows the cursor to be positioned where actual characters don't exist, in block mode

-- Statusline
vim.opt.laststatus = 3 -- Set laststatus to 3 to enable the global statusline

-- Spelling
vim.opt.spell = true -- Enable spellchecker
vim.opt.spelllang = {"en_gb", "es"} -- Sets the checking languages


vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
  },
  underline = true,
  severity_sort = true,
})

vim.diagnostic.config({
  virtual_text = { current_line = false },
  virtual_lines = { current_line = true },  -- detalle completo solo donde estás
})
