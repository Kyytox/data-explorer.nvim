local utils = require("data-explorer.core.utils")

describe("Tests Utils module", function()
	-- Test for is_accepted_file_type
	it("is_accepted_file_type", function()
		local accepted_types = { "csv", "parquet", "tsv" }

		assert.is_true(utils.is_accepted_file_type("data.csv", accepted_types))
		assert.is_true(utils.is_accepted_file_type("data.parquet", accepted_types))
		assert.is_false(utils.is_accepted_file_type("data.txt", accepted_types))
		assert.is_true(utils.is_accepted_file_type("report.tsv", accepted_types))
		assert.is_false(utils.is_accepted_file_type("image.png", accepted_types))
	end)

	-- Test for get_files_in_working_directory
	it("get_files_in_working_directory", function()
		local accepted_types = { "csv", "parquet" }
		local files = (utils.get_files_in_working_directory(accepted_types))

		-- Assuming there are some .lua and .md files in the working directory for this test
		assert.is_true(#files > 0)

		for _, file in ipairs(files) do
			assert.is_true(utils.is_accepted_file_type(file, accepted_types))
		end
	end)
end)
