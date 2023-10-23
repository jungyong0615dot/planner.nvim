local M = {}
local ts = require("planner.ts")
local floating = require("planner.buf.floating")
local utils = require("planner.utils")
local status = require("planner.api.status")
local curl = require("custom_curl")

local default_url = "https://api.clickup.com/api/v2"

--- Update task in ClickUp API
---@param task_id string
---@param api_key string
---@param fields table
---@return job
M.update_task = function(task_id, api_key, fields, callback)
	local url_info = utils.interpolate("{default_url}/task/{task_id}", { task_id = task_id, default_url = default_url })
	return curl.put(url_info, {
		headers = {
			Authorization = api_key,
		},
		body = fields,
		callback = vim.schedule_wrap(function(out)
			local output_task = vim.json.decode(out.body) or {}
			callback(output_task)
		end),
	}):start()
end

local task_parser = function(out)
	local output_task = vim.json.decode(out.body) or {}

	local title = output_task["name"] or ""
	local description = output_task["text_content"] or ""
	local subtasks = output_task["subtasks"] or {}
	local author = output_task["creator"]["username"] or ""
	local categories = ""
	local created = output_task["date_created"] or ""
	local date_updated = output_task["date_updated"] or ""

	local subtask_line_template = [[~ ({status}) {subtask_title}]]
	local subtask_fields_template = [[~~ {task_id}, {priority}]]
	local subtasks_texts = vim.tbl_map(function(subtask)
		local subtask_status_icon = status.icon_by_name["clickup"][subtask["status"]["status"]] or "Open"
		local subtask_line =
			utils.interpolate(subtask_line_template, { status = subtask_status_icon, subtask_title = subtask["name"] })
		local subtask_fields = utils.interpolate(subtask_fields_template, { task_id = subtask["id"], priority = "1" })
		return subtask_line .. "\n" .. subtask_fields
	end, subtasks)

	return {
		app = "clickup",
		title = title,
		description = description,
		subtasks = table.concat(subtasks_texts, "\n"),
		author = author,
		created = created,
		updated = date_updated,
		version = "",
		fields = "",
		categories = categories,
	}
end

--- Get task from ClickUp API
---@param task_id string
---@param api_key string
---@return job
M.get_task = function(task_id, api_key)
	local url_info = utils.interpolate(
		"{default_url}/task/{task_id}?include_subtasks=true",
		{ task_id = task_id, default_url = default_url }
	)
	return curl.get(url_info, {
		headers = {
			Authorization = api_key,
		},
		callback = vim.schedule_wrap(function(out)
			local parsed = task_parser(out)
			local bufnr = floating.task(
				parsed.app,
				parsed.title,
				parsed.description,
				parsed.subtasks,
				parsed.author,
				parsed.categories,
				parsed.created,
				parsed.updated,
				parsed.version,
				parsed.fields
			)
      vim.b[bufnr].task_id = task_id

			vim.api.nvim_create_autocmd("TextChanged", {
				buffer = bufnr,
				callback = function(_)
					local current_cursor_node = ts.get_node_at_cursor()
					if not ts.is_task_status_node(current_cursor_node) then
						return
					end
					local cursor_pos = vim.fn.getpos(".")
					local curchar = vim.api.nvim_buf_get_text(
						bufnr,
						cursor_pos[2] - 1,
						cursor_pos[3] - 1,
						cursor_pos[2] - 1,
						cursor_pos[3],
						{}
					)[1]
					local fields = ts.get_fields_of_subtask(current_cursor_node)

					M.update_task(
						fields.task_id,
						api_key,
						{ status = status.name_by_icon["clickup"][curchar] },
						function(output_task)
							local new_status = output_task["status"]["status"]
							vim.print("Transition done - New status: " .. new_status)
						end
					)
				end,
			})

			vim.api.nvim_create_autocmd("InsertLeave", {
				buffer = bufnr,
				callback = function(_)
					local current_cursor_node = ts.get_node_at_cursor()
					local section = ts.get_line_section(current_cursor_node)
					if section == "SUBTASKS" then
						local fields = ts.get_fields_of_subtask(current_cursor_node)
						local subtask_title = ts.get_title_of_subtask(current_cursor_node)
						M.update_task(fields["task_id"], api_key, { name = subtask_title }, function(_)
							vim.print("SubTask title updated: " .. subtask_title)
						end)
					elseif section == "DESCRIPTION" then
            local task_description = ts.get_task_description(current_cursor_node)
						local updated_task_id = vim.b.task_id
						M.update_task(updated_task_id, api_key, { description = task_description }, function(_)
							vim.print("Task description updated")
						end)
						-- updated[updated_task_id] = {description= ""}
					end
				end,
			})

		end),
	}):start()
end

return M
