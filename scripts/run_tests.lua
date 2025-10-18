-- scripts/run_tests.lua
local test_harness = require("plenary.test_harness")
test_harness.test_directory("tests", { minimal_init = "tests/minimal_init.lua" })
