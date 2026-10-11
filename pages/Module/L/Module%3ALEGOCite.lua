local p = {}

local data = {
	headz = "[[The LEGO Group|LEGO]] [[w:c:lego:BrickHeadz|BrickHeadz]] <small>(Set:",
	micro = "[[The LEGO Group|LEGO]] [[w:c:lego:Microfighters|Microfighters]] <small>(Set:",
	ucs = "[[LEGO Ultimate Collector's Series]] <small>(Set: ",
	smart = "[[LEGO Star Wars|LEGO ''Star Wars'']] <small>(Smart Play Set:",
	gift = "[[LEGO Star Wars|LEGO ''Star Wars'']] <small>(Promotional/Gift Set:"
}

function p.render(args)
	local theme = args.theme or ''
	local text = data[string.lower(theme)]
	if text then
		return text
	end
	return "[[LEGO Star Wars|LEGO ''Star Wars'']] <small>(Set: "
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p