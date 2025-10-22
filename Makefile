.PHONY: test test-unit test-integration lint fastlint format doc clean install-deps all

test:
	@echo "Running all tests..."
	@nvim --headless --clean \
		-u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

test-unit:
	@echo "Running unit tests..."
	@nvim --headless --clean \
		-u tests/minimal_init.lua \
		-c "PlenaryBustedFile tests/dbt-lsp_spec.lua"

test-integration:
	@echo "Running integration tests..."
	@nvim --headless --clean \
		-u tests/minimal_init.lua \
		-c "PlenaryBustedFile tests/integration_spec.lua"

lint: fastlint
	@stylua --check lua/ plugin/ tests/

fastlint:
	@luacheck lua/ plugin/

format:
	@stylua lua/ plugin/ tests/

doc:
	@nvim --headless --clean \
		-c "helptags doc" \
		-c "quit"

clean:
	@rm -rf doc/tags
	@rm -rf tests/fixtures/example_dbt_project/target
	@rm -rf tests/fixtures/example_dbt_project/dbt_packages
	@rm -rf tests/fixtures/example_dbt_project/logs

install-deps:
	@echo "Installing dependencies..."
	@luarocks install luacheck
	@luarocks install stylua

all: lint test
