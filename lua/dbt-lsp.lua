local M = {}

M.config = {
  cmd = { "dbt-lsp-proxy" },
  filetypes = { "sql", "yaml" },
  root_dir = nil,
  settings = {},
  socket_port = 7658,
}

function M.get_mason_opts()
  return {
    registries = {
      "github:edmondop/dbt-lsp.nvim",
      "github:mason-org/mason-registry",
    },
  }
end

function M.extend_mason_opts(existing_opts)
  existing_opts = existing_opts or {}
  local registries = existing_opts.registries or { "github:mason-org/mason-registry" }

  local has_dbt_registry = false
  for _, reg in ipairs(registries) do
    if reg:match("edmondop/dbt%-lsp%.nvim") then
      has_dbt_registry = true
      break
    end
  end

  if not has_dbt_registry then
    table.insert(registries, 1, "github:edmondop/dbt-lsp.nvim")
  end

  existing_opts.registries = registries
  return existing_opts
end

local function find_dbt_project_root(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.find({ "dbt_project.yml" }, {
    path = path,
    upward = true,
  })[1]

  if root then
    return vim.fn.fnamemodify(root, ":h")
  end

  return nil
end

local function build_cmd(config, root_dir)
  local cmd = vim.deepcopy(config.cmd)
  table.insert(cmd, "--socket")
  table.insert(cmd, tostring(config.socket_port))

  if root_dir then
    table.insert(cmd, "--project-dir")
    table.insert(cmd, root_dir)
  end

  return cmd
end

function M.start_client(bufnr, config)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  config = vim.tbl_deep_extend("force", M.config, config or {})

  local root_dir = config.root_dir
  if not root_dir then
    root_dir = find_dbt_project_root(bufnr)
  end

  if not root_dir then
    return
  end

  local cmd = build_cmd(config, root_dir)

  local client_id = vim.lsp.start({
    name = "dbt-lsp",
    cmd = cmd,
    root_dir = root_dir,
    settings = config.settings,
  }, {
    bufnr = bufnr,
  })

  if client_id then
    vim.notify(
      string.format("[dbt-lsp] Started on port %d", config.socket_port),
      vim.log.levels.INFO
    )
  end

  return client_id
end

local registry_injected = false

local function inject_mason_registry()
  if registry_injected then
    return true
  end

  local mason_ok, mason_settings = pcall(require, "mason.settings")
  if not mason_ok then
    return false
  end

  local current_registries = mason_settings.current.registries
    or { "github:mason-org/mason-registry" }

  local has_dbt_registry = false
  for _, reg in ipairs(current_registries) do
    if reg:match("edmondop/dbt%-lsp%.nvim") then
      has_dbt_registry = true
      break
    end
  end

  if not has_dbt_registry then
    table.insert(current_registries, 1, "github:edmondop/dbt-lsp.nvim")
    mason_settings.set({ registries = current_registries })
  end

  registry_injected = true
  return true
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Try immediate injection (works if Mason already loaded)
  local injected = inject_mason_registry()

  -- If Mason not loaded yet, set up deferred injection attempts
  if not injected then
    -- Attempt 1: Retry after a short delay (handles Mason loading shortly after)
    vim.defer_fn(function()
      if not registry_injected then
        inject_mason_registry()
      end
    end, 100)

    -- Attempt 2: Retry after a longer delay (handles slower lazy-loading)
    vim.defer_fn(function()
      if not registry_injected then
        inject_mason_registry()
      end
    end, 1000)

    -- Attempt 3: Set up UIEnter autocmd (handles very late Mason loading)
    vim.api.nvim_create_autocmd("UIEnter", {
      once = true,
      callback = function()
        vim.defer_fn(function()
          if not registry_injected then
            inject_mason_registry()
          end
        end, 500)
      end,
    })
  end

  local group = vim.api.nvim_create_augroup("DbtLsp", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = M.config.filetypes,
    callback = function(args)
      -- Retry injection on first dbt file open (handles cmd-based Mason loading)
      if not registry_injected then
        inject_mason_registry()
      end

      local root_dir = find_dbt_project_root(args.buf)
      if root_dir then
        M.start_client(args.buf, M.config)
      end
    end,
  })
end

return M
