-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Ejecutar después de cargar el colorscheme
vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#E06C75" })
vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#E5C07B" })
vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#61AFEF" })
vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#D19A66" })
vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#98C379" })
vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#da70d6" })
vim.api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#56B6C2" })
