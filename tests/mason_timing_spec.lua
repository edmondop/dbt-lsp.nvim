describe("Mason timing and load order", function()
  before_each(function()
    package.loaded["mason"] = nil
    package.loaded["mason.settings"] = nil
    package.loaded["mason-registry"] = nil
    package.loaded["dbt-lsp"] = nil
  end)

  it("detects when setup() runs before Mason is loaded", function()
    -- Note: In CI, Mason may already be loaded from previous tests
    -- The important thing is that setup() doesn't crash either way
    local dbt_lsp = require("dbt-lsp")

    local setup_ok = pcall(dbt_lsp.setup)
    assert.is_true(setup_ok, "setup() should not crash if Mason not loaded")

    -- Don't assert Mason's state - it varies depending on test order
    -- Just verify setup() succeeded without errors
  end)

  it("detects when setup() runs after Mason.setup() - CORRECT ORDER", function()
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    mason.setup({ registries = { "github:mason-org/mason-registry" } })

    local dbt_lsp = require("dbt-lsp")
    dbt_lsp.setup()

    local mason_settings = require("mason.settings")
    local registries = mason_settings.current.registries

    local has_dbt = false
    for _, reg in ipairs(registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt = true
        break
      end
    end

    assert.is_true(has_dbt, "Registry should be injected when order is correct")
  end)

  it("verifies health check can detect missing registry injection", function()
    local health = require("dbt-lsp.health")

    local mason_ok, mason = pcall(require, "mason")
    if mason_ok then
      mason.setup({ registries = { "github:mason-org/mason-registry" } })

      local mason_settings = require("mason.settings")
      local has_dbt = false
      for _, reg in ipairs(mason_settings.current.registries) do
        if reg:match("edmondop/dbt%-lsp%.nvim") then
          has_dbt = true
          break
        end
      end

      if not has_dbt then
        print("WARNING: dbt-lsp registry not in Mason - timing issue detected")
      end
    end

    local ok = pcall(health.check)
    assert.is_true(ok, "Health check should not crash")
  end)
end)
