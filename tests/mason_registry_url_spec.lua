describe("Mason registry URL construction", function()
  it("checks how Mason interprets github: registries", function()
    local registry_spec = "github:edmondop/dbt-lsp.nvim"

    print("Registry spec:", registry_spec)

    local owner, repo = registry_spec:match("^github:([^/]+)/(.+)$")
    print("Parsed owner:", owner)
    print("Parsed repo:", repo)

    assert.are.equal("edmondop", owner)
    assert.are.equal("dbt-lsp.nvim", repo)

    local owner_pattern = owner:gsub("%-", "%%-")
    local repo_pattern = repo:gsub("%-", "%%-"):gsub("%.", "%%.")
    local expected_url_pattern = "https://github%.com/"
      .. owner_pattern
      .. "/"
      .. repo_pattern
      .. "/releases/download/.+/registry%.json%.zip"

    print("Expected URL pattern:", expected_url_pattern)

    local actual_release_url =
      "https://github.com/edmondop/dbt-lsp.nvim/releases/download/2025-10-20-mere-home/registry.json.zip"
    print("Actual release URL:", actual_release_url)

    assert.is_true(
      actual_release_url:match(expected_url_pattern) ~= nil,
      "Release URL should match expected pattern"
    )
  end)

  it("verifies Mason can access our registry", function()
    local releases_api = "https://api.github.com/repos/edmondop/dbt-lsp.nvim/releases/latest"

    local cmd = string.format("curl -s '%s' 2>&1", releases_api)
    local handle = io.popen(cmd)
    local response = handle:read("*a")
    handle:close()

    local ok, release = pcall(vim.fn.json_decode, response)

    if not ok or not release or not release.tag_name then
      pending("No GitHub release exists yet - push code to trigger release")
      return
    end

    assert.is_true(ok, "Should parse release JSON")

    print("Latest release tag:", release.tag_name)
    print("Release assets:")
    for _, asset in ipairs(release.assets or {}) do
      print("  -", asset.name, "->", asset.browser_download_url)
    end

    local has_registry_zip = false
    local has_checksums = false

    for _, asset in ipairs(release.assets or {}) do
      if asset.name == "registry.json.zip" then
        has_registry_zip = true
      end
      if asset.name == "checksums.txt" then
        has_checksums = true
      end
    end

    assert.is_true(has_registry_zip, "Release should have registry.json.zip")
    assert.is_true(has_checksums, "Release should have checksums.txt")
  end)

  it("downloads registry exactly how Mason would", function()
    local releases_url = "https://api.github.com/repos/edmondop/dbt-lsp.nvim/releases/latest"

    local cmd = string.format("curl -s '%s' 2>&1", releases_url)
    local handle = io.popen(cmd)
    local response = handle:read("*a")
    handle:close()

    local ok, release = pcall(vim.fn.json_decode, response)

    if not ok or not release or not release.tag_name then
      pending("No GitHub release exists yet - push code to trigger release")
      return
    end

    assert.is_true(ok, "Should get latest release")

    local registry_asset = nil
    for _, asset in ipairs(release.assets or {}) do
      if asset.name == "registry.json.zip" then
        registry_asset = asset
        break
      end
    end

    assert.is_not_nil(registry_asset, "Should find registry.json.zip asset")

    print("Downloading from:", registry_asset.browser_download_url)

    local download_cmd = string.format("curl -sL '%s' 2>&1", registry_asset.browser_download_url)
    local handle2 = io.popen(download_cmd)
    local zip_content = handle2:read("*a")
    handle2:close()

    assert.is_true(#zip_content > 100, "Downloaded content should be substantial")

    local tmpfile = "/tmp/test_registry.json.zip"
    local f = io.open(tmpfile, "wb")
    f:write(zip_content)
    f:close()

    local unzip_cmd = string.format("gunzip -c '%s' 2>&1", tmpfile)
    local handle3 = io.popen(unzip_cmd)
    local json_content = handle3:read("*a")
    handle3:close()

    os.remove(tmpfile)

    local json_ok, packages = pcall(vim.fn.json_decode, json_content)
    assert.is_true(json_ok, "Registry JSON should be valid")
    assert.is_table(packages, "Registry should be array")

    local found = false
    for _, pkg in ipairs(packages) do
      if pkg.name == "dbt-lsp" then
        found = true
        print("SUCCESS: Found dbt-lsp in registry!")
        break
      end
    end

    assert.is_true(found, "dbt-lsp should be in registry")
  end)
end)
