local function herb_language_server_cmd()
  local executable = vim.fn.exepath("herb-language-server")

  if executable == "" then
    executable = vim.fn.expand("~/.cache/.bun/bin/herb-language-server")
  end

  return { executable, "--stdio" }
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        herb_ls = {
          cmd = herb_language_server_cmd(),
          mason = false,
        },
      },
    },
  },
}
