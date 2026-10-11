-- This module implements [[Template:SpecialCategorizer]].

local blacklist = mw.loadData('Module:SpecialCategorizer/blacklist')
local p = {}

function p._main(val)
	if blacklist.isFullyBlacklisted or blacklist.isBlacklisted then
		return nil
	elseif type(val) == 'function' then
		-- val is a callback function, so call it
		return val()
	else
		return val
	end
end

function p.main(frame)
	-- Send the value through to p._main as a callback function, so that the
	-- argument is only expanded if necessary. (Expanding arguments is
	-- expensive.)
	return p._main(function ()
		return frame:getParent().args[1] or '{{{1}}}'
	end)
end

return p