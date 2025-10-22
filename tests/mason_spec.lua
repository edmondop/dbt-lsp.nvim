local dbt_lsp = require("dbt-lsp")

describe("dbt-lsp.nvim Mason integration", function()
  it("packages directory structure exists", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local packages_dir = plugin_root .. "/packages"
    assert.is_true(vim.fn.isdirectory(packages_dir) == 1, "packages directory should exist")
  end)

  it("dbt-lsp package definition exists", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local package_yaml = plugin_root .. "/packages/dbt-lsp/package.yaml"
    assert.is_true(vim.fn.filereadable(package_yaml) == 1, "package.yaml should exist")
  end)

  it("dbt-lsp package.yaml is valid YAML", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local package_yaml = plugin_root .. "/packages/dbt-lsp/package.yaml"
    local file = io.open(package_yaml, "r")
    assert.is_not_nil(file, "Should be able to open package.yaml")
    local content = file:read("*a")
    file:close()

    assert.is_true(content:match("name:%s*dbt%-lsp") ~= nil, "Should have name: dbt-lsp")
    assert.is_true(content:match("source:") ~= nil, "Should have source section")
    assert.is_true(content:match("bin:") ~= nil, "Should have bin section")
  end)

  it("get_mason_opts returns correct registry configuration", function()
    local opts = dbt_lsp.get_mason_opts()
    assert.is_table(opts)
    assert.is_table(opts.registries)
    assert.are.equal(2, #opts.registries)
    assert.are.equal("github:edmondop/dbt-lsp.nvim", opts.registries[1])
    assert.are.equal("github:mason-org/mason-registry", opts.registries[2])
  end)

  it("extend_mason_opts adds registry to existing config", function()
    local existing = { ui = { border = "rounded" } }
    local extended = dbt_lsp.extend_mason_opts(existing)

    assert.is_table(extended.registries)
    assert.are.equal(2, #extended.registries)
    assert.are.equal("github:edmondop/dbt-lsp.nvim", extended.registries[1])
    assert.are.equal("rounded", extended.ui.border)
  end)

  it("extend_mason_opts doesn't duplicate registry", function()
    local existing = {
      registries = {
        "github:edmondop/dbt-lsp.nvim",
        "github:mason-org/mason-registry",
      },
    }
    local extended = dbt_lsp.extend_mason_opts(existing)

    assert.are.equal(2, #extended.registries)
  end)

  it("Mason setup succeeds with get_mason_opts", function()
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed - skipping Mason integration test")
      return
    end

    local ok, err = pcall(function()
      mason.setup(dbt_lsp.get_mason_opts())
    end)

    assert.is_true(ok, "Mason setup should succeed with get_mason_opts(): " .. tostring(err))
  end)
end)
