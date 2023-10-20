local M = {}
local key = require("planner.api.key")
local clickup = require("planner.api.clickup")
local autocmd = require("planner.buf.autocmd")
-- autocmd.create_text_changed(app, bufnr)

M.update_task = function(app, task_id, fields)
  if app == "clickup" then
    clickup.update_task(task_id, key.key_by_app["clickup"], fields)
  end
end

M.get_task = function(app, task_id)
  if app == "clickup" then
    clickup.get_task(task_id, key.key_by_app["clickup"])
  end
end


return M
