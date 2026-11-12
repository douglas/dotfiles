-- The current Omarchy theme, as on Linux: omarchy-theme-pull copies Omarchy's
-- rendered neovim.lua here. Catppuccin Mocha (Omarchy's Catppuccin) until then.
local omarchy = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.uv.fs_stat(omarchy) then
  return dofile(omarchy)
end

return {
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
