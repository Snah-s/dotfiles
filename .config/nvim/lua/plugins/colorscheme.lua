return {
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      require("vscode").setup({
        transparent = false,
        italic_comments = true,
      })
      vim.cmd.colorscheme("vscode")
    end,
  },
}
