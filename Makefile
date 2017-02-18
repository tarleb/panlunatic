PANDOC_VERSION=$(shell pandoc --version | sed -ne 's/^pandoc \([0-9.]*\)/\1/p')

LUA_PATH := src/?.lua;$(LUA_PATH)
export LUA_PATH

test: dist/test
	@echo "Using Pandoc" $(PANDOC_VERSION)
	@echo "Testing plain JSON conversion..."
	@PANDOC_VERSION=$(PANDOC_VERSION) \
	  pandoc --from=native --to=tests/identity.lua tests/testsuite.native |\
		pandoc --from=json --to=native --standalone -o dist/identity.native
	@test -z "$(diff tests/testsuite.native dist/identity.native)"
	@echo "Success"
	@echo "Testing table JSON conversion..."
	@PANDOC_VERSION=$(PANDOC_VERSION) \
	  pandoc --from=native --to=tests/identity.lua tests/tables.native |\
		pandoc --from=json --to=native --standalone -o dist/tables.native
	@test -z "$(diff tests/tables.native dist/tables.native)"
	@echo "Success"

dist/test:
	mkdir -p dist/test

release:
	mkdir -p dist/panlunatic
	mkdir -p dist/luarocks
	luarocks make --tree=dist/luarocks rockspecs/panlunatic-scm-0.rockspec
	luarocks install --tree=dist/luarocks rockspecs/panlunatic-scm-0.rockspec
	cp -av dist/luarocks/share/lua/5.1/* dist/panlunatic
	tar zvcf dist/panlunatic.tgz -C dist panlunatic

clean:
	rm -r dist

.PHONY: test clean release
