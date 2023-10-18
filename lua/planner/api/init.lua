local M = {}
local curl = require("custom_curl")
local floating = require("planner.buf.floating")

M.get = function(url_info, auth, callback)

	return curl.get(url_info, {
		headers = {
			Authorization = auth,
		},
		callback = vim.schedule_wrap(function(out)
			local parsed = callback(out)
      floating.task(parsed.title, parsed.description, "subtasks")

		end),
	})
end

return M
