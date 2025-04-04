local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cs",
  callback = function(args)
    local root_candidates = vim.fs.find({ ".sln", ".csproj", ".git" }, { upward = true })
    local root_dir = root_candidates[1] and vim.fs.dirname(root_candidates[1]) or vim.loop.cwd()

    vim.lsp.start({
      name = "csharp-language-server",
      cmd = { "csharp-language-server" },
      root_dir = root_dir,
      capabilities = capabilities,  -- Passing capabilities for enhanced completion
      -- on_attach = function(client, bufnr)
      --   -- Optional: Additional per-server setup can go here
      -- end,
    })
  end,
})
