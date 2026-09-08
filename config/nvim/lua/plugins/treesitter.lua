vim.pack.add(
  {"https://github.com/nvim-treesitter/nvim-treesitter"}
) -- import the package

local langs = {
  "bash",
  "c", "cpp", "comment", "css",
  "diff", "dockerfile", "doxygen", "go", 
  "html", 
  "java", "javascript","json", "jsdoc",
  "latex", "lua", "luadoc",
  "markdown", "markdown_inline",
--  "python",
  "query",
  "rust",
  "sql",
  "typescript",
  "vim", "vimdoc",
  "yaml",
}

require("nvim-treesitter").install(langs)
