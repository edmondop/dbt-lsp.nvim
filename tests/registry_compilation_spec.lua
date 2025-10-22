describe("Mason registry compilation", function()
  it("package.yaml can be compiled to JSON with yq", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local package_yaml = plugin_root .. "/packages/dbt-lsp/package.yaml"

    local handle = io.popen(string.format("yq eval '.' -o json %s 2>&1", package_yaml))
    local json_output = handle:read("*a")
    local exit_code = handle:close()

    if not exit_code then
      print("ERROR: yq failed to parse package.yaml")
      print("Output:", json_output)
    end

    assert.is_true(exit_code ~= nil and exit_code, "yq should successfully parse package.yaml")
    assert.is_true(#json_output > 0, "yq should produce JSON output")

    local json_ok, parsed = pcall(vim.fn.json_decode, json_output)
    assert.is_true(json_ok, "JSON output should be valid: " .. tostring(parsed))
    assert.are.equal("dbt-lsp", parsed.name)
    assert.is_table(parsed.source)
    assert.is_table(parsed.bin)
  end)

  it("simulates mason-org/actions registry-release compilation", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local packages_dir = plugin_root .. "/packages"

    local compile_cmd =
      string.format("cd %s && yq ea '[.]' -o json */package.yaml 2>&1", packages_dir)

    local handle = io.popen(compile_cmd)
    local registry_json = handle:read("*a")
    local exit_code = handle:close()

    if not exit_code then
      print("ERROR: registry compilation failed")
      print("Output:", registry_json)
    end

    assert.is_true(exit_code ~= nil and exit_code, "Registry compilation should succeed")
    assert.is_true(#registry_json > 0, "Registry JSON should not be empty")

    local json_ok, packages = pcall(vim.fn.json_decode, registry_json)
    assert.is_true(json_ok, "Registry JSON should be valid: " .. tostring(packages))
    assert.is_table(packages, "Registry should be an array")
    assert.is_true(#packages > 0, "Registry should contain at least one package")

    local has_dbt_lsp = false
    for _, pkg in ipairs(packages) do
      if pkg.name == "dbt-lsp" then
        has_dbt_lsp = true
        assert.is_table(pkg.source, "dbt-lsp should have source")
        assert.is_table(pkg.bin, "dbt-lsp should have bin")
        assert.are.equal("custom", pkg.source.id)
        break
      end
    end

    assert.is_true(has_dbt_lsp, "Registry should contain dbt-lsp package")
  end)
end)
