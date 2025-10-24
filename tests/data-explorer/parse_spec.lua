local plugin = require("data-explorer.core.parser")

describe("Data Explorer Parser", function()
	-- Test for parse_csv
	it("parse_csv with delimiter ,", function()
		local csv_text = [[
      Header1,Header2
      Value1,Value2
      Value3,Value4
    ]]

		local result, err = plugin.parse_csv(csv_text, ",")
		assert.is_nil(err)
		assert.are.same({ "Header1", "Header2" }, result.headers)
		assert.are.same({
			{
				Header1 = "      Value1",
				Header2 = "Value2",
			},
			{
				Header1 = "      Value3",
				Header2 = "Value4",
			},
		}, result.data)
	end)

	-- Test for parse_csv with delimiter |
	it("parse_csv with delimiter |", function()
		local csv_text = [[
      Header1|Header2
      Value1|Value2
      Value3|Value4
    ]]

		local result, err = plugin.parse_csv(csv_text, "|")
		assert.is_nil(err)
		assert.are.same({ "Header1", "Header2" }, result.headers)
		assert.are.same({
			{
				Header1 = "      Value1",
				Header2 = "Value2",
			},
			{
				Header1 = "      Value3",
				Header2 = "Value4",
			},
		}, result.data)
	end)

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
