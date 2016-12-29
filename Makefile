test: dist
	@echo "Testing plain JSON conversion..."
	@pandoc --from=native --to=tests/identity.lua tests/testsuite.native |\
		pandoc --from=json --to=native --standalone -o dist/identity.native
	@test -z "$(diff tests/testsuite.native dist/identity.native)"
	@echo "Success"
	@echo "Testing table JSON conversion..."
	@pandoc --from=native --to=tests/identity.lua tests/tables.native |\
		pandoc --from=json --to=native --standalone -o dist/tables.native
	@test -z "$(diff tests/tables.native dist/tables.native)"
	@echo "Success"

dist:
	mkdir dist

clean:
	rm -r dist

.PHONY: test clean
