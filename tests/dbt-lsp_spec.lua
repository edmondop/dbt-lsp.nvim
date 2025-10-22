local dbt_lsp = require("dbt-lsp")

describe("dbt-lsp.nvim", function()
  it("can be required without errors", function()
    assert.is_not_nil(dbt_lsp)
    assert.is_function(dbt_lsp.setup)
    assert.is_function(dbt_lsp.start_client)
  end)

  it("has default configuration", function()
    assert.is_table(dbt_lsp.config)
    assert.is_table(dbt_lsp.config.cmd)
    assert.are.equal("dbt-lsp", dbt_lsp.config.cmd[1])
    assert.is_table(dbt_lsp.config.filetypes)
    assert.is_number(dbt_lsp.config.socket_port)
    assert.are.equal(7658, dbt_lsp.config.socket_port)
  end)

  it("allows custom configuration", function()
    local custom_config = {
      socket_port = 9999,
      filetypes = { "sql" },
    }

    dbt_lsp.setup(custom_config)

    assert.are.equal(9999, dbt_lsp.config.socket_port)
    assert.are.same({ "sql" }, dbt_lsp.config.filetypes)
  end)

  it("merges configurations deeply", function()
    local initial_config = vim.deepcopy(dbt_lsp.config)
    local custom_config = {
      socket_port = 8000,
    }

    dbt_lsp.setup(custom_config)

    assert.are.equal(8000, dbt_lsp.config.socket_port)
    assert.are.same(initial_config.filetypes, dbt_lsp.config.filetypes)
  end)
end)
