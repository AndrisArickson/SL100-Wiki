local p = {}
	
function yes(s)
	return s ~= nil and s ~= '' and s ~= false
end

function p.render(args)
	local ret = {}
	local rowClass = args.class or ''
	local code = args.code or ''
	local work = args.work or ''
	local timeline = args.date or ''
	local publishedDate = args.published or ''
	if yes(args.unpublished) then
		rowClass = rowClass .. ' unpublished'
	end
	
	if yes(args.adaptation) then
		ret[#ret + 1] = '<tr class="' .. rowClass .. ' adaptation">'
	else
		ret[#ret + 1] = '<tr class="' .. rowClass .. '">'
	end
	
	ret[#ret + 1] = '<td>' .. timeline .. '</td>'
	
	if yes(args.unpublished) then
		ret[#ret + 1] = '<td class="' .. rowClass .. ' unpublished">' .. code .. '</td>'
	else
		ret[#ret + 1] = '<td class="' .. rowClass ..'">' .. code .. '</td>'
	end
	
	ret[#ret + 1] = '<td>'
	ret[#ret + 1] = work
	if yes(args.note) then
		ret[#ret + 1] = '<br><li><small>' .. args.note .. '</small></li>'
	end
	ret[#ret + 1] = '</td>'
	
	if yes(args.published) and args.published:find('-XX') then
		ret[#ret + 1] = '<td data-sort-value="' .. args.published:gsub('-XX', '-31') .. '">' .. args.published .. '</td>'
	elseif yes(args.published) then
		ret[#ret + 1] = '<td>' .. args.published .. '</td>'
	else
		ret[#ret + 1] = '<td data-sort-value="9999"></td>'
	end
	ret[#ret + 1] = '</tr>'
	return table.concat(ret)
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p