describe("dbt-lsp.nvim user configuration scenarios", function()
  it("works when Mason is not installed", function()
    local dbt_lsp = require("dbt-lsp")
    local ok, err = pcall(dbt_lsp.setup)
    assert.is_true(ok, "Plugin setup should work without Mason: " .. tostring(err))
  end)

  it("Mason setup does not error with get_mason_opts", function()
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    local dbt_lsp = require("dbt-lsp")
    local setup_ok, setup_err = pcall(function()
      mason.setup(dbt_lsp.get_mason_opts())
    end)

    assert.is_true(setup_ok, "Mason setup must not error: " .. tostring(setup_err))
  end)

  it("health check can run without errors", function()
    local health = require("dbt-lsp.health")
    local ok, err = pcall(health.check)
    assert.is_true(ok, "Health check must not error: " .. tostring(err))
  end)

  it("automatically registers with Mason when setup is called", function()
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    mason.setup()
    local dbt_lsp = require("dbt-lsp")
    dbt_lsp.setup()

    local mason_settings = require("mason.settings")
    local registries = mason_settings.current.registries

    local has_dbt_registry = false
    for _, reg in ipairs(registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt_registry = true
        break
      end
    end

    assert.is_true(has_dbt_registry, "dbt-lsp registry should be automatically added")
  end)

  it("simulates full user setup flow", function()
    local dbt_lsp_ok, dbt_lsp = pcall(require, "dbt-lsp")
    assert.is_true(dbt_lsp_ok, "Should be able to require dbt-lsp")

    local mason_ok, mason = pcall(require, "mason")
    if mason_ok then
      local setup_ok, setup_err = pcall(function()
        mason.setup()
      end)

      assert.is_true(setup_ok, "Mason setup should not error: " .. tostring(setup_err))
    end

    local plugin_ok, plugin_err = pcall(dbt_lsp.setup)
    assert.is_true(plugin_ok, "Plugin setup should not error: " .. tostring(plugin_err))

    local health_ok, health_err = pcall(require("dbt-lsp.health").check)
    assert.is_true(health_ok, "Health check should not error: " .. tostring(health_err))

    print("SUCCESS: Full user setup flow completed without errors")
  end)
end)
