local M = {}

function M.check()
  vim.health.start("dbt-lsp.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.11.0") == 1 then
    vim.health.ok("Neovim >= 0.11.0")
  else
    vim.health.error("Neovim >= 0.11.0 required")
  end

  -- Check Mason registry integration
  local mason_ok, mason_settings = pcall(require, "mason.settings")
  if mason_ok then
    local registries = mason_settings.current.registries or {}
    local has_dbt_registry = false

    for _, reg in ipairs(registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt_registry = true
        break
      end
    end

    if has_dbt_registry then
      vim.health.ok("dbt-lsp registry is registered with Mason")
    else
      vim.health.warn("dbt-lsp registry not yet injected into Mason", {
        "The registry will be automatically injected when:",
        "  - Mason finishes loading (if lazy-loaded with cmd = 'Mason')",
        "  - You open a dbt file (SQL/YAML in a dbt project)",
        "  - After a brief delay (100-1000ms)",
        "If this persists after using :Mason, there may be a configuration issue.",
      })
    end
  else
    vim.health.warn("Mason not loaded yet", {
      "Mason will be loaded when you run :Mason or when it's configured to load",
      "The dbt-lsp registry will be automatically injected once Mason loads",
      ":MasonInstall dbt-lsp will work after Mason is loaded",
    })
  end

  -- Check dbt-lsp binary
  if vim.fn.executable("dbt-lsp") == 1 then
    local handle = io.popen("dbt-lsp --version 2>&1")
    local version = handle:read("*a")
    handle:close()
    vim.health.ok("dbt-lsp is installed: " .. vim.trim(version))
  else
    vim.health.warn("dbt-lsp binary not found in PATH", {
      "Install via Mason: :MasonInstall dbt-lsp",
      "Or install manually: curl -fsSL https://raw.githubusercontent.com/dbt-labs/dbt-fusion/main/crates/dbt-common/assets/install.sh | sh -s -- --package dbt-lsp",
    })
  end

  -- Check if in a dbt project
  local has_project = vim.fn.filereadable("dbt_project.yml") == 1
  if has_project then
    vim.health.ok("dbt_project.yml found in current directory")
  else
    local found = vim.fs.find("dbt_project.yml", {
      upward = true,
      path = vim.fn.getcwd(),
    })[1]
    if found then
      vim.health.ok("dbt_project.yml found at: " .. vim.fn.fnamemodify(found, ":h"))
    else
      vim.health.info(
        "No dbt_project.yml found (LSP will activate when you open files in a dbt project)"
      )
    end
  end
end

return M
