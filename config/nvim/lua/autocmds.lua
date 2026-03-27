require "nvchad.autocmds"

-- Auto-start vim-obsession session tracking for tmux-resurrect
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Skip if session was loaded via -S (obsession picks it up automatically)
    if vim.v.this_session ~= "" then
      return
    end
    vim.schedule(function()
      pcall(vim.cmd, "Obsess")
    end)
  end,
})

-- When restoring a session (nvim -S), clean up broken nvim-tree buffer and reopen properly
vim.api.nvim_create_autocmd("SessionLoadPost", {
  callback = function()
    vim.schedule(function()
      -- Delete any NvimTree buffers that got restored as regular buffers
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(b)
        if name:match("NvimTree_") then
          pcall(vim.api.nvim_buf_delete, b, { force = true })
        end
      end

      local ok, api = pcall(require, "nvim-tree.api")
      if ok then
        api.tree.open()
        vim.cmd "wincmd p"
      end
    end)
  end,
})
