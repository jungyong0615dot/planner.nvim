local M = {}

--- string interpolation
---@param str 
---@param vars 
---@param whole 
---@param i 
---@return 
---@return 
M.interpolate = function(str, vars)
	-- Example:
	-- output = M.interpolate{
	-- 	[[Hello {name}, welcome to {company}. ]],
	-- 	name = name,
	-- 	company = get_company_name()
	-- }
	if not vars then
		vars = str
		str = vars[1]
	end
	return (string.gsub(str, "({([^}]+)})", function(whole, i)
		return vars[i] or whole
	end))
end

return M
