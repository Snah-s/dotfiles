vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
        diagnosticMode = "openFilesOnly",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        inlayHints = {callArgumentsNames = true}
      },
    },
  },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      hint = {
        enable = true,
        paramName = "All",
        paramType = true,
        setType = true,
      },
    },
  },
})

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--inlay-hints=true",
  },
})

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.config("ts_ls", {
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
})

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      inlayHints = {
        parameterHints = {
          enable = true,
        },
        typeHints = {
          enable = true,
        },
        chainingHints = {
          enable = true,
        },
      },
    },
  },
})

vim.lsp.inlay_hint.enable(true)

vim.lsp.enable("clangd")
vim.lsp.enable("basedpyright")
vim.lsp.enable("lua_ls")
vim.lsp.enable("ts_ls")
vim.lsp.enable("gopls")
vim.lsp.enable("rust_analyzer")
