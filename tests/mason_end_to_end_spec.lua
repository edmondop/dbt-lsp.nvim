describe("Mason end-to-end integration", function()
  local mock_registry_json

  before_each(function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local packages_dir = plugin_root .. "/packages"

    local compile_cmd =
      string.format("cd %s && yq ea '[.]' -o json */package.yaml 2>&1", packages_dir)

    local handle = io.popen(compile_cmd)
    mock_registry_json = handle:read("*a")
    handle:close()
  end)

  it("setup() injects registry into Mason settings", function()
    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    mason.setup({ registries = { "github:mason-org/mason-registry" } })

    local mason_settings = require("mason.settings")
    local before_registries = vim.deepcopy(mason_settings.current.registries)

    local dbt_lsp = require("dbt-lsp")
    dbt_lsp.setup()

    local after_registries = mason_settings.current.registries

    local has_dbt_registry = false
    for _, reg in ipairs(after_registries) do
      if reg:match("edmondop/dbt%-lsp%.nvim") then
        has_dbt_registry = true
        break
      end
    end

    assert.is_true(has_dbt_registry, "setup() should inject dbt-lsp registry")
    assert.are.equal(#before_registries + 1, #after_registries, "Should add one registry")

    print("Before registries:", vim.inspect(before_registries))
    print("After registries:", vim.inspect(after_registries))
  end)

  it("verifies compiled registry has correct structure for Mason", function()
    local packages = vim.fn.json_decode(mock_registry_json)

    for _, pkg in ipairs(packages) do
      if pkg.name == "dbt-lsp" then
        assert.is_string(pkg.name)
        assert.is_string(pkg.description)
        assert.is_string(pkg.homepage)
        assert.is_table(pkg.licenses)
        assert.is_table(pkg.languages)
        assert.is_table(pkg.categories)
        assert.is_table(pkg.source)
        assert.is_string(pkg.source.id)
        assert.is_table(pkg.bin)

        print("Package structure validated:")
        print(vim.inspect(pkg))
        return
      end
    end

    error("dbt-lsp package not found in compiled registry")
  end)
end)
