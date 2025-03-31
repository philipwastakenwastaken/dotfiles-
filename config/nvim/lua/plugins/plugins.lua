return {
    {
      "ibhagwan/fzf-lua",
      dependencies = { "echasnovski/mini.icons" },
      opts = {}
    },
    {
     "folke/which-key.nvim",
     event = "VeryLazy",
     opts = {
       -- your configuration comes here
       -- or leave it empty to use the default settings
       -- refer to the configuration section below
     },
     keys = {
       {
         "<leader>?",
         function()
           require("which-key").show({ global = false })
         end,
         desc = "Buffer Local Keymaps (which-key)",
       },
     },
    },
     -- Telescope core
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = vim.fn.executable("make") == 1, -- only load if `make` is available
      },
    }
  }, 
 }
