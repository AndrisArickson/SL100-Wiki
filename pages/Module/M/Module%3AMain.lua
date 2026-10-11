-- This module implements [[Template:Main]].

local p = {}

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

function p._main(args)
	args[1] = args[1] or '{{{1}}}'
	local links = {}
	local isCategory = mw.title.getCurrentTitle().namespace == 14
	for i, v in ipairs(args) do
		local c = ''
		if isCategory and not v:find('/Legends') and exists(v .. '/Legends') then
			c = ' (and [[' .. v .. '/Legends|Legends]])'
		end
		links[i] = string.format(
			'[[%s|%s]]%s',
			v,
			args['l' .. i] or v:gsub("/Legends", ""),
			c
		)
	end
	local prefix
	if #links > 1 then
		prefix = 'Main articles'
	else
		prefix = 'Main article'
	end
	links = mw.text.listToText(links)
	return string.format(
		'<div class="noprint rellink" role="note">[[File:Blue_Glass_Arrow.svg|20px|alt=icon|class=notpageimage]] %s: %s</div>',
		prefix, links
	)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p