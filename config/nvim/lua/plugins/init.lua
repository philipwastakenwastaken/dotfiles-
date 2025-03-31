return vim.tbl_deep_extend("force",
  require("plugins.lsp"),
  require("plugins.telescope")
)
