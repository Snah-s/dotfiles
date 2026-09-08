vim.pack.add({
  "https://github.com/navarasu/onedark.nvim", -- Adding the repo
})

require('onedark').setup {
  style = 'warmer' -- Setting up the possible themes "Dark, Darker, Cool, Deep, Warm, Warmer"
}
require('onedark').load() -- Load the theme
