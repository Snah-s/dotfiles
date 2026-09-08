vim.pack.add({
  "https://github.com/olimorris/onedarkpro.nvim"
})

require("onedarkpro").setup({
  options = {
    cursorline = true,
    transparency = false, },
})

vim.cmd.colorscheme("onedark")
