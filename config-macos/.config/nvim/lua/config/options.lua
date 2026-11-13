-- Options are automatically loaded before lazy.nvim startup.
-- remote_clipboard knows Wayland and tmux, not the macOS clipboard, so on a Mac
-- it only takes over in SSH sessions.
if vim.fn.has("mac") == 0 or vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  require("config.remote_clipboard").setup()
end

vim.opt.relativenumber = false
vim.g.autoformat = false
