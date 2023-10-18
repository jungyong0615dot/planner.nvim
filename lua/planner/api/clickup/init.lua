local M = {}
local utils = require("planner.utils")
local rest = require("planner.api")

M.get_task = function(task_id, api_key)
	local url_info = utils.interpolate("https://api.clickup.com/api/v2/task/{task_id}", { task_id = task_id })

	rest.get(url_info, api_key, function(out)
		local output_task = vim.json.decode(out.body) or {}
		local title = output_task["name"] or ""
		local description = output_task["text_content"] or ""
		return { title = title, description = description }
	end):start()
end

return M
