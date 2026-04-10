require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- tmux + nvim navigation
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>",  { desc = "window left" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>",  { desc = "window down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>",    { desc = "window up" })

-- unbind NvChad's <leader>h (horizontal terminal) — conflicts with gitsigns <leader>h* mappings
vim.keymap.del("n", "<leader>h")

-- Telescope live grep, pre-filled with word under cursor (editable)
map("n", "<leader>fw", function()
  require("telescope.builtin").live_grep({ default_text = vim.fn.expand("<cword>") })
end, { desc = "grep word under cursor" })
