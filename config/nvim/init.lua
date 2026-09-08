-- ==================== Options ====================
require("core.options") -- import options module
require("core.autocmds") -- import autocmd module
require("core.keymaps") -- import keymaps module
-- ================== Colorscheme ==================
require("colorscheme.one-dark")
-- require("colorscheme.one-dark-pro")

-- ==================== Plugins ====================
require("plugins.treesitter")
require("plugins.lspconfig")
require("plugins.autopairs")
require("plugins.blink")
