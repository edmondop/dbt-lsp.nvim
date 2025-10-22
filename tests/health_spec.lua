local health = require("dbt-lsp.health")

describe("dbt-lsp.nvim health check", function()
  it("can run health check without errors", function()
    local ok, err = pcall(health.check)
    assert.is_true(ok, "Health check should not error: " .. tostring(err))
  end)

  it("detects Neovim version correctly", function()
    local has_nvim_011 = vim.fn.has("nvim-0.11.0") == 1
    assert.is_true(has_nvim_011, "Tests should run on Neovim >= 0.11.0")
  end)

  it("checks for dbt-lsp executable", function()
    local has_dbt_lsp = vim.fn.executable("dbt-lsp") == 1
    if has_dbt_lsp then
      local handle = io.popen("dbt-lsp --version 2>&1")
      local output = handle:read("*a")
      handle:close()
      assert.is_not_nil(output)
      assert.is_true(#output > 0, "dbt-lsp --version should produce output")
    end
  end)
end)
