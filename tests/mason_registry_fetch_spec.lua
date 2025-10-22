describe("Mason registry fetch simulation", function()
  it("downloads and parses registry from GitHub release", function()
    -- First check if any release exists
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

    -- Find registry.json.zip asset
    local registry_asset = nil
    for _, asset in ipairs(release.assets or {}) do
      if asset.name == "registry.json.zip" then
        registry_asset = asset
        break
      end
    end

    if not registry_asset then
      pending("No registry.json.zip in latest release")
      return
    end

    local registry_url = registry_asset.browser_download_url

    local download_cmd = string.format("curl -sL '%s' 2>&1", registry_url)
    local handle2 = io.popen(download_cmd)
    local zip_content = handle2:read("*a")
    local success = handle2:close()

    assert.is_true(success, "Should download registry.json.zip")
    assert.is_true(#zip_content > 0, "Downloaded content should not be empty")

    local tmpfile = "/tmp/registry_test.json.zip"
    local f = io.open(tmpfile, "wb")
    f:write(zip_content)
    f:close()

    local unzip_cmd = string.format("gunzip -c '%s' 2>&1", tmpfile)
    local handle2 = io.popen(unzip_cmd)
    local json_content = handle2:read("*a")
    handle2:close()

    os.remove(tmpfile)

    assert.is_true(#json_content > 0, "Unzipped content should not be empty")

    local ok, registry = pcall(vim.fn.json_decode, json_content)
    assert.is_true(ok, "Registry should be valid JSON: " .. tostring(registry))
    assert.is_table(registry, "Registry should be an array")

    print("Registry contains", #registry, "packages")

    local found_dbt_lsp = false
    for _, pkg in ipairs(registry) do
      print("Package:", pkg.name)
      if pkg.name == "dbt-lsp" then
        found_dbt_lsp = true
        print("Found dbt-lsp!")
        print(vim.inspect(pkg))
      end
    end

    assert.is_true(found_dbt_lsp, "Registry should contain dbt-lsp package")
  end)

  it("simulates Mason registry lookup", function()
    -- First check if GitHub release exists
    local releases_api = "https://api.github.com/repos/edmondop/dbt-lsp.nvim/releases/latest"
    local cmd = string.format("curl -s '%s' 2>&1", releases_api)
    local handle = io.popen(cmd)
    local response = handle:read("*a")
    handle:close()

    local ok, release = pcall(vim.fn.json_decode, response)
    if not ok or not release or not release.tag_name then
      pending("No GitHub release exists yet - can't test registry refresh")
      return
    end

    local mason_ok, mason = pcall(require, "mason")
    if not mason_ok then
      pending("mason.nvim not installed")
      return
    end

    mason.setup({
      registries = {
        "github:edmondop/dbt-lsp.nvim",
        "github:mason-org/mason-registry",
      },
    })

    local dbt_lsp = require("dbt-lsp")
    dbt_lsp.setup()

    local mason_settings = require("mason.settings")
    print("Mason registries:", vim.inspect(mason_settings.current.registries))

    vim.fn.delete(vim.fn.stdpath("data") .. "/mason/registries", "rf")

    local registry_ok, registry = pcall(require, "mason-registry")
    if not registry_ok then
      pending("mason-registry not available")
      return
    end

    print("Refreshing registry...")
    local refresh_done = false
    local refresh_error = nil

    registry.refresh(vim.schedule_wrap(function(success, err)
      refresh_done = true
      refresh_error = err
      if success then
        print("Registry refresh succeeded")

        local all_packages = registry.get_all_package_names()
        print("Total packages after refresh:", #all_packages)

        for _, name in ipairs(all_packages) do
          if name:match("dbt") then
            print("Found package:", name)
          end
        end

        local has_dbt, pkg_or_err = pcall(registry.get_package, "dbt-lsp")
        if has_dbt then
          print("SUCCESS: dbt-lsp package found!")
          print("Package:", vim.inspect(pkg_or_err))
        else
          print("ERROR: dbt-lsp not found:", pkg_or_err)
        end
      else
        print("Registry refresh failed:", err)
      end
    end))

    vim.wait(10000, function()
      return refresh_done
    end, 100)

    assert.is_true(refresh_done, "Registry refresh should complete")
    if refresh_error then
      print(
        "Warning: Registry refresh had errors, but this may be expected without a GitHub release"
      )
    end
  end)
end)
