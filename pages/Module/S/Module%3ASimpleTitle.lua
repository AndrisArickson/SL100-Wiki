
local p = {}

function p._main(args)
	local title = args.title or mw.title.getCurrentTitle().text
	local trimmed = title:gsub('/Canon$', ''):gsub('/Legends$', '')
	if trimmed:find('%(') then
		local simple, paren = trimmed:match('^(.*)%s*%((.-)%)$')
		return simple
	else
		return trimmed
	end
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

return p