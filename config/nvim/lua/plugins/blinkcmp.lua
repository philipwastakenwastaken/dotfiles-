return {
  {
    'saghen/blink.cmp',
    -- Optional: provides snippets for the snippet source
    dependencies = { 'rafamadriz/friendly-snippets' },
    -- version = '1.*', -- use a release tag to download pre-built binaries
    -- Uncomment and adjust if you need to build from source:
    build = 'cargo build --release',
    opts = {
      -- Choose a preset for key mappings: 'default', 'super-tab', 'enter', or 'none'
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono', -- Adjust based on your preferred Nerd Font variant
      },
      completion = { documentation = { auto_show = true } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "rust" }
    },
    opts_extend = { "sources.default" }
  }
}
