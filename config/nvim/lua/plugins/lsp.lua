return {
  -- nvim-lspconfig with Mason dependencies
{
  "neovim/nvim-lspconfig",
  dependencies = {
    "saghen/blink.cmp", -- Replace nvim-cmp dependency with blink.cmp
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup()
      end,
    },
    {
      "williamboman/mason-lspconfig.nvim",
      config = function()
        require("mason-lspconfig").setup({
          ensure_installed = { "lua_ls" },
          automatic_installation = true,
        })
      end,
    },
  },
  config = function()
    local lspconfig = require("lspconfig")
    -- Use blink.cmp to get the enhanced LSP capabilities
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })
  end,
},
}
