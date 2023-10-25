local M = {}
local ts = require("planner.ts")
local tl = require("planner.tl")
local floating = require("planner.buf.floating")
local utils = require("planner.utils")
local status = require("planner.api.status")
local curl = require("custom_curl")

local default_url = "https://api.clickup.com/api/v2"

--- Update task
---@param task_id string
---@param api_key string
---@param fields table
---@return any
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

--- Parse get task response from ClickUp API
---@param out table
---@return table
local task_parser = function(out)
	local output_task = vim.json.decode(out.body) or {}

	local title = output_task["name"] or ""
	local description = output_task["text_content"] or ""
	local subtasks = output_task["subtasks"] or {}
	-- local author = output_task["creator"]["username"] or ""
	local author = "Me"
	local categories = ""
	local created = os.date("%Y-%m-%d %H:%M:%S", tonumber(output_task["date_created"]) / 1000) or ""
	local date_updated = os.date("%Y-%m-%d %H:%M:%S", tonumber(output_task["date_updated"]) / 1000) or ""
	local task_status = output_task["status"]["status"] or "Open"
	local task_status_icon = status.icon_by_name["clickup"][task_status] or " "
  local due_date = "2023-01-01 00:00:00"
  local start_date = "2023-01-01 00:00:00"
	-- local due_date = os.date("%Y-%m-%d %H:%M:%S", tonumber(output_task["due_date"]) / 1000) or ""
	-- local start_date = os.date("%Y-%m-%d %H:%M:%S", tonumber(output_task["start_date"]) / 1000) or ""
	local fields = utils.interpolate(
		[[
due_date: {due_date}
start_date: {start_date}]],
		{ due_date = due_date, start_date = start_date }
	)

	local subtask_line_template = [[~ ({status}) {subtask_title}]]
	local subtask_fields_template = [[~~ {task_id}, {priority}]]
	local subtasks_texts = vim.tbl_map(function(subtask)
		local subtask_status_icon = status.icon_by_name["clickup"][subtask["status"]["status"]] or " "
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
		fields = fields,
		categories = categories,
		task_status_icon = task_status_icon,
		list_id = output_task["list"]["id"],
	}
end

--- Get task and open it in buffer
---@param task_id string
---@param api_key string
---@return any
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
				parsed.fields,
				parsed.task_status_icon,
				task_id
			)
			vim.b[bufnr].task_id = task_id
			vim.b[bufnr].list_id = parsed.list_id

			vim.api.nvim_create_autocmd("TextChanged", {
				buffer = bufnr,
				callback = function(_)
					local current_cursor_node = ts.get_node_at_cursor()
					if not ts.is_task_status_node(current_cursor_node) then
						return
					end
					local line_section = ts.get_line_section(current_cursor_node)
					local section = line_section["title"]
					local cursor_pos = vim.fn.getpos(".")
					local curchar = vim.api.nvim_buf_get_text(
						bufnr,
						cursor_pos[2] - 1,
						cursor_pos[3] - 1,
						cursor_pos[2] - 1,
						cursor_pos[3],
						{}
					)[1]

					if section == "STATUS" then
						M.update_task(
							vim.b.task_id,
							api_key,
							{ status = status.name_by_icon["clickup"][curchar] },
							function(output_task)
								local new_status = output_task["status"]["status"]
								vim.print("Transition done - New status: " .. new_status)
							end
						)
						return
					end

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
					local line_section = ts.get_line_section(current_cursor_node)
					local section = line_section["title"]

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
					elseif section == "document.meta" then
						local updated_task_id = vim.b.task_id
						local task_tag_text = ts.get_task_description(current_cursor_node)
						local task_tags = vim.fn.split(task_tag_text, "\n")
						local task_title = vim.split(task_tags[1], "title: ")[2]
						M.update_task(updated_task_id, api_key, { name = task_title }, function(_)
							vim.print("Task title updated: " .. task_title)
						end)
					end
				end,
			})
		end),
	}):start()
end

--- Create sub-task while in the SUBTASKS section
---@param title string 
---@param api_key string
---@param callback function
---@return any
M.create_subtask = function(title, api_key, callback)
	local current_cursor_node = ts.get_node_at_cursor()
	local line_section = ts.get_line_section(current_cursor_node)
	if line_section["title"] ~= "SUBTASKS" then
		vim.print("Create subtask yet only works in the SUBTASKS section")
		return {}
	end

	local url_info = utils.interpolate(
		"{default_url}/list/{list_id}/task?custom_task_ids=false",
		{ list_id = vim.b.list_id, default_url = default_url }
	)
	return curl.post(url_info, {
		headers = {
			Authorization = api_key,
		},
		body = { name = title, parent = vim.b.task_id },
		callback = vim.schedule_wrap(function(out)
			local output_task = vim.json.decode(out.body) or {}
			local new_subtask_text = utils.interpolate(
				[[~ ({status_icon}) {title} 
~~ {task_id}, {priority}]],
				{
					title = output_task["name"],
					task_id = output_task["id"],
					priority = "1",
					status_icon = status.icon_by_name["clickup"][output_task["status"]["status"]],
				}
			)
			local section_end_row = line_section["node"]:end_()
			vim.api.nvim_buf_set_lines(
				0,
				section_end_row,
				section_end_row + 1,
				false,
				vim.split(new_subtask_text, "\n")
			)
			vim.print("Subtask created: " .. output_task["name"])
			callback(output_task)
		end),
	}):start()
end

--- Get list of tasks and open telescope picker
---@param list_id string
---@param api_key string
---@return any
M.list_tasks = function(list_id, api_key)
	local url_info = utils.interpolate(
		"{default_url}/list/{list_id}/task?archived=false&include_closed=false",
		{ list_id = list_id, default_url = default_url }
	)
	return curl.get(url_info, {
		headers = {
			Authorization = api_key,
		},
		callback = vim.schedule_wrap(function(out)
			local output_tasks = vim.json.decode(out.body) or {}
      tl.picker_tasks(output_tasks["tasks"], function(selected)
        M.get_task(selected, api_key)
      end)
    end),
	}):start()
end


--- Create task and open
---@param title string 
---@param api_key string
---@param callback function
---@return any
M.create_task = function(list_id, title, api_key, callback)
  -- TODO: merge with create_subtask
	local url_info = utils.interpolate(
		"{default_url}/list/{list_id}/task?custom_task_ids=false",
		{ list_id = list_id, default_url = default_url }
	)
	return curl.post(url_info, {
		headers = {
			Authorization = api_key,
		},
		body = { name = title },
		callback = vim.schedule_wrap(function(out)
			local output_task = vim.json.decode(out.body) or {}
      M.get_task(output_task["id"], api_key)
			vim.print("Task created: " .. output_task["name"])
			callback(output_task)
		end),
	}):start()
end

return M
