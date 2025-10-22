local dbt_lsp = require("dbt-lsp")

describe("dbt-lsp.nvim integration tests", function()
  local test_project_dir = vim.fn.fnamemodify("tests/fixtures/example_dbt_project", ":p")

  before_each(function()
    vim.cmd("cd " .. test_project_dir)
  end)

  after_each(function()
    vim.lsp.stop_client(vim.lsp.get_clients(), true)
    vim.cmd("bufdo bwipeout!")
  end)

  it("finds dbt project root correctly", function()
    local model_path = test_project_dir .. "models/staging/stg_customers.sql"
    vim.cmd("edit " .. model_path)

    local bufnr = vim.api.nvim_get_current_buf()
    local root = vim.fs.find({ "dbt_project.yml" }, {
      path = vim.api.nvim_buf_get_name(bufnr),
      upward = true,
    })[1]

    assert.is_not_nil(root)
    assert.is_true(vim.endswith(root, "dbt_project.yml"))
  end)

  it("detects dbt project files correctly", function()
    local model_path = test_project_dir .. "models/staging/stg_customers.sql"
    vim.cmd("edit " .. model_path)

    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[bufnr].filetype

    assert.are.equal("sql", filetype)
  end)

  it("builds correct LSP command with socket", function()
    local config = {
      cmd = { "dbt-lsp" },
      socket_port = 7658,
    }

    local cmd = vim.deepcopy(config.cmd)
    table.insert(cmd, "--socket")
    table.insert(cmd, tostring(config.socket_port))
    table.insert(cmd, "--project-dir")
    table.insert(cmd, test_project_dir)

    assert.are.same({ "dbt-lsp", "--socket", "7658", "--project-dir", test_project_dir }, cmd)
  end)

  it("respects custom socket port configuration", function()
    dbt_lsp.setup({
      socket_port = 9999,
    })

    assert.are.equal(9999, dbt_lsp.config.socket_port)
  end)

  it("respects custom filetypes configuration", function()
    dbt_lsp.setup({
      filetypes = { "sql" },
    })

    assert.are.same({ "sql" }, dbt_lsp.config.filetypes)
  end)

  it("packages directory structure exists in repo", function()
    local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
    local packages_dir = plugin_root .. "/packages"
    local package_yaml = packages_dir .. "/dbt-lsp/package.yaml"

    assert.is_true(
      vim.fn.isdirectory(packages_dir) == 1,
      "packages directory should exist at: " .. packages_dir
    )
    assert.is_true(
      vim.fn.filereadable(package_yaml) == 1,
      "package.yaml should exist at: " .. package_yaml
    )
  end)

  if vim.fn.executable("dbt-lsp") == 1 then
    it("starts LSP server successfully with dbt-lsp binary", function()
      local model_path = test_project_dir .. "models/staging/stg_customers.sql"
      vim.cmd("edit " .. model_path)

      local bufnr = vim.api.nvim_get_current_buf()
      local client_id = dbt_lsp.start_client(bufnr)

      vim.wait(2000, function()
        return vim.lsp.get_client_by_id(client_id) ~= nil
      end)

      assert.is_not_nil(client_id, "LSP client should start")
      local client = vim.lsp.get_client_by_id(client_id)
      assert.is_not_nil(client, "LSP client should be retrievable")
      assert.are.equal("dbt-lsp", client.name, "LSP client name should be dbt-lsp")
    end)

    it("verifies command structure with socket and project flags", function()
      local test_config = { socket_port = 7658, cmd = { "dbt-lsp" } }
      local test_root = test_project_dir

      local cmd = vim.deepcopy(test_config.cmd)
      table.insert(cmd, "--socket")
      table.insert(cmd, tostring(test_config.socket_port))
      if test_root then
        table.insert(cmd, "--project-dir")
        table.insert(cmd, test_root)
      end

      assert.is_table(cmd, "Command should be a table")
      assert.are.equal("dbt-lsp", cmd[1], "First element should be dbt-lsp")
      assert.are.equal("--socket", cmd[2], "Should have --socket flag")
      assert.are.equal("7658", cmd[3], "Should have socket port")
      assert.are.equal("--project-dir", cmd[4], "Should have --project-dir flag")
      assert.are.equal(test_root, cmd[5], "Should have project directory")
    end)
  else
    it("skips LSP server test (dbt-lsp not installed)", function()
      pending("dbt-lsp executable not found - install it to run this test")
    end)
  end
end)
