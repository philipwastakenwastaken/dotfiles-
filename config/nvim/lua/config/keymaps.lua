vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set(
	"n",
	"gl",
	vim.diagnostic.open_float,
	{ noremap = true, silent = true, desc = "Show floating diagnostics window" }
)

vim.keymap.set("n", "<S-left>", "<cmd>bprev<CR>")
vim.keymap.set("n", "<S-right>", "<cmd>bnext<CR>")

vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({
		count = 1, -- move forward by one diagnostic
		wrap = true, -- wrap around if at the end of the file
		float = true, -- open a floating window after jumping
	})
end, { noremap = true, silent = true, desc = "Jump to next diagnostic" })

vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({
		count = -1, -- move forward by one diagnostic
		wrap = true, -- wrap around if at the end of the file
		float = true, -- open a floating window after jumping
	})
end, { noremap = true, silent = true, desc = "Jump to previous diagnostic" })
