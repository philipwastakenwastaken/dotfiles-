return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",  -- Runs TSUpdate after installation to update parsers.
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = { "c_sharp", "lua" }, -- You can change this to a list of languages if you prefer.
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      }
    end,
  },
}
