local M = {}

M.name_by_icon = {
	clickup = {
		["-"] = "upcoming",
		["!"] = "in progress",
		["="] = "planned",
		["x"] = "Closed",
		["_"] = "abandoned",
		[" "] = "Open",
	},
}


local reverse = function(tb)
  local reversed = {}
  for k, v in pairs(tb) do
    reversed[v] = k
  end
  return reversed
end

M.icon_by_name = {}
for app, name_by_icon in pairs(M.name_by_icon) do
  M.icon_by_name[app] = reverse(name_by_icon)
end

return M
