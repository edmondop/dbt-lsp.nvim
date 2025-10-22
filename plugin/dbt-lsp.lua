if vim.g.loaded_dbt_lsp then
  return
end
vim.g.loaded_dbt_lsp = true

if vim.fn.has("nvim-0.11") == 0 then
  vim.notify("[dbt-lsp] Requires Neovim 0.11+", vim.log.levels.ERROR)
  return
end

local ok, dbt_lsp = pcall(require, "dbt-lsp")
if not ok then
  vim.notify("[dbt-lsp] Failed to load: " .. dbt_lsp, vim.log.levels.ERROR)
  return
end

local opts = vim.g.dbt_lsp_config or {}
dbt_lsp.setup(opts)
