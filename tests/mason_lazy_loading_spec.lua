describe("Mason lazy-loading scenario", function()
  it("simulates Mason NOT being setup when dbt-lsp.setup() runs", function()
    package.loaded["mason"] = nil
    package.loaded["mason.settings"] = nil
    package.loaded["dbt-lsp"] = nil

    local dbt_lsp = require("dbt-lsp")

    print("Scenario: dbt-lsp loads but Mason hasn't been setup yet")
    print("This is what happens with cmd = 'Mason' + lazy = false")

    local setup_ok, setup_err = pcall(function()
      dbt_lsp.setup()
    end)

    print("dbt-lsp.setup() result:", setup_ok, setup_err)
    assert.is_true(setup_ok, "setup() should not crash even if Mason not loaded")

    print("\nNow user runs :Mason and Mason gets setup...")

    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    mason.setup({ registries = { "github:mason-org/mason-registry" } })

    local mason_settings = require("mason.settings")
    print("Mason registries after Mason setup:", vim.inspect(mason_settings.current.registries))

    local has_dbt_registry = false
    for _, reg in ipairs(mason_settings.current.registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt_registry = true
        break
      end
    end

    print("Does Mason have dbt-lsp registry?", has_dbt_registry)

    if not has_dbt_registry then
      print("\nPROBLEM: dbt-lsp.setup() ran BEFORE Mason.setup(), so registry wasn't injected!")
      print("This is the bug!")
    end

    assert.is_false(has_dbt_registry, "This test should FAIL - proving the timing bug exists")
  end)

  it("tests the CORRECT approach - dbt-lsp.setup() runs AFTER Mason.setup()", function()
    package.loaded["mason"] = nil
    package.loaded["mason.settings"] = nil
    package.loaded["dbt-lsp"] = nil

    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    print("Correct order: Mason.setup() FIRST")
    mason.setup({ registries = { "github:mason-org/mason-registry" } })

    print("Then dbt-lsp.setup() SECOND")
    local dbt_lsp = require("dbt-lsp")
    dbt_lsp.setup()

    local mason_settings = require("mason.settings")
    print("Mason registries after CORRECT order:", vim.inspect(mason_settings.current.registries))

    local has_dbt_registry = false
    for _, reg in ipairs(mason_settings.current.registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt_registry = true
        break
      end
    end

    assert.is_true(has_dbt_registry, "Registry should be injected when order is correct")
  end)
end)
