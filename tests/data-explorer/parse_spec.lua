local plugin = require("data-explorer.parser")

describe("Tests Parser module", function()
	-- Test for parse_csv
	it("parse_csv", function()
		local csv_text = [[
      Header1,Header2,Count
      Value1,Value2,20
      Value3,Value4,20
    ]]

		local result, err = plugin.parse_csv(csv_text)
		assert.is_nil(err)
		assert.are.same({ "Header1", "Header2" }, result.headers)
		assert.are.same(
			{ { Header1 = "Value1", Header2 = "Value2" }, { Header1 = "Value3", Header2 = "Value4" } },
			result.data
		)
		assert.are.equal("20", result.count_lines)
	end)

	-- Test for parse_columns_string
	it("parse_columns_string", function()
		local input = [[
      Columns,nombre_lignes: "[{'name': 'Header1', 'type': 'STRING'}, {'name': 'Header2', 'type': 'STRING'}]",30]]

		local result, err = plugin.parse_columns_string(input)
		assert.is_nil(err)
		assert.are.same({ "column", "type" }, result.headers)
		assert.are.same({
			{ column = "Header1", type = "STRING" },
			{ column = "Header2", type = "STRING" },
		}, result.data)
		assert.are.equal("30", result.count_lines)
	end)
end)
