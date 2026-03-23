return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local map = function(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Hunk navigation (Danish keyboard friendly)
      map('n', 'æ', gs.next_hunk, 'Next hunk')
      map('n', 'ø', gs.prev_hunk, 'Previous hunk')

      -- Stage & reset
      map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
      map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
      map('v', '<leader>hs', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage selection')
      map('v', '<leader>hr', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Reset selection')
      map('n', '<leader>hS', gs.stage_buffer, 'Stage entire buffer')
      map('n', '<leader>hR', gs.reset_buffer, 'Reset entire buffer')
      map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo last stage')

      -- Info
      map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk diff')
      map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
      map('n', '<leader>tb', gs.toggle_current_line_blame, 'Toggle inline blame')
      map('n', '<leader>hd', gs.diffthis, 'Diff against index')

      -- Hunk text object
      map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'Select hunk')
    end
  },
}

