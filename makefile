TESTS_INIT=tests/minimal_init.lua
# TESTS_DIR=tests/other_tests/
TESTS_DIR=tests/data-explorer/

.PHONY: test

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
