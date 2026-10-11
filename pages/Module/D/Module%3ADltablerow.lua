local p = {}

local COLOR = {
	A="F8312F",
	SWN="7D4533",
	MF="3F5FFF",
	CP="FF822D",
	PF="B4ACBC",
	F="D67D00",
	FC="8D65C5",
	TA="CDC4D6",
	HOF="F9C23C"
}

local TYPES = {
	MF = "M/F",
	PF = "P/F",
	TA = "T/A"
}

function p.render(args)
	local cx = COLOR[args[1]] or "9B9B9B"
	local ct = TYPES[args[1]] or args[1]
	local link = string.format("[https://starwars.fandom.com/f/p/%s %s]", args[4], args[5]:gsub('%[', '&#91;'):gsub('%]', '&#93;'))
	local extra = ""
	if args[7] then
		extra = string.format("||[[User:%s|%s]] ([https://starwars.fandom.com/f/u/%s posts])", args[7], args[7], args[6])
	end
	local text = string.format([[|- class="%s"
|data-sort-value=%s|%s||style="background-color:#%s; text-align:center"|%s||style="padding:0 5px"|%s%s]], args[1], args[2], args[3], cx, ct, link, extra)
	return text
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p