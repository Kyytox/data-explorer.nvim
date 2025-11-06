local plugin = require("data-explorer.core.parser")

describe("Data Explorer Parser", function()
	-- Test for parse_raw_text
	it("parse_raw_text", function()
		local raw_text = [[
┌────────────────┬─────────┬─────────┬
│     Column     │  Type   │  Count  │
│    varchar     │ varchar │  int64  │
├────────────────┼─────────┼─────────┼
│ nom            │ VARCHAR │     100 │
│ prenom         │ VARCHAR │     100 │
└────────────────┴─────────┴─────────┴]]

		local result, err = plugin.parse_raw_text(raw_text)
		assert.is_nil(err)
		assert.are.same({
			"┌────────────────┬─────────┬─────────┬",
			"│     Column     │  Type   │  Count  │",
			"│    varchar     │ varchar │  int64  │",
			"├────────────────┼─────────┼─────────┼",
			"│ nom            │ VARCHAR │     100 │",
			"│ prenom         │ VARCHAR │     100 │",
			"└────────────────┴─────────┴─────────┴",
		}, result.data)
		assert.are.equal(100, result.count_lines)
	end)
end)
