local p = {}

function p.main(frame)
    local ret = {'ARGUMENTS: {'}
	for k, v in pairs(frame:getParent().args) do
		if string.len(v) > 0 and string.find(v, 'ref') then
			ret[#ret + 1] = '\n"' .. k:gsub(' ', '_') .. '":<nowiki>"YES: ' .. v ..'"</nowiki>,'
		else
			ret[#ret + 1] = '\n"' .. k:gsub(' ', '_') .. '":<nowiki>"' .. v ..'"</nowiki>,'
		end
	end

	ret[#ret + 1] = '}</nowiki>'
	return table.concat(ret)
end

return p