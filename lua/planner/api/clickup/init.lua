local M = {}
local utils = require("planner.utils")
local rest = require("planner.api")

M.status_to_icon = function(status)
	local name_by_icon = {
		["-"] = { "upcoming" },
		["!"] = { "in progress" },
		["="] = { "planned" },
		["x"] = { "Closed" },
		["_"] = { "abandoned" },
		[" "] = { "Open" },
		-- "abandoned", "Open", "planned", "checklist", "in progress",  "upcoming",  "Closed"
		-- - ( ) Undone -> not done yet
		-- - (x) Done -> done with that
		-- - (?) Needs further input
		-- - (!) Urgent -> high priority task
		-- - (+) Recurring task with children
		-- - (-) Pending -> currently in progress
		-- - (=) Task put on hold
		-- - (_) Task cancelled (put down)
	}

	for icon, status_name in pairs(name_by_icon) do
		if vim.tbl_contains(status_name, status) then
			return icon
		end
	end
	return "?"
end

M.get_task = function(task_id, api_key)
	local url_info =
		utils.interpolate("https://api.clickup.com/api/v2/task/{task_id}?include_subtasks=true", { task_id = task_id })

	rest.get(url_info, api_key, function(out)
		local output_task = vim.json.decode(out.body) or {}

		local title = output_task["name"] or ""
		local description = output_task["text_content"] or ""
		local subtasks = output_task["subtasks"] or {}
		vim.print(subtasks)

		local subtasks_texts = vim.tbl_map(function(subtask)
			local status = M.status_to_icon(subtask["status"]["status"])
			local subtask_line_template = [[- ({status}) {subtask_title}]]
			local subtask_line =
				utils.interpolate(subtask_line_template, { status = status, subtask_title = subtask["name"] })
			return subtask_line
		end, subtasks)

		return { title = title, description = description, subtasks = table.concat(subtasks_texts, "\n") }
	end):start()
end

return M
