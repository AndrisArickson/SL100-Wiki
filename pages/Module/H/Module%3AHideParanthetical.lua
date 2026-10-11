local p = {}

local title = mw.title.getCurrentTitle()

local function hideParanthetical(set)
	local stop = set:find('%s*%(')
    if stop then
        return set:sub(1, stop - 1)
    else
        return set
    end
    return set
end

local function compare(txt, full, italics, t)
	if not txt or not full then
		return ''
	end
	
	local match = full == txt
	if italics then
		match = full == txt:gsub("^''", ""):gsub("''$", "")
	end
	
	if match then
		if t.namespace == 0 then
			return '[[Category:Unnecessary text parameters used in citation templates|' .. t.text .. ']]·'
		elseif t.namespace == 6 or t.namespace == 120 then
			return '[[Category:Unnecessary text parameters used in citation templates|*' .. t.text .. ']]·'
		end
	end
	return ''
end

function p.render(args)
	local link = args.link or ''
	local i = ""
	local iCheck = args.icheck or ''
	if args.italics then
		i = "''"
		iCheck = 'true'
	end 
	
	if not link:find('%s*%(') and not args.text then
		return string.format("%s[[%s|%s]]%s", i, link, link:gsub('Wikipedia:', ''), i)
	end
	
	local prep = hideParanthetical(link):gsub('Wikipedia:', '')
	if link == "Star Wars: The Power of the Force (1985 toy line)" then
		prep = "''Star Wars: The Power of the Force'' (1985)"
		i = ''
	elseif link == "Star Wars: The Power of the Force (1995 toy line)" then
		prep = "''Star Wars: The Power of the Force'' (1995)"
		i = ''
	end
	
	if args.text and string.len(args.text) > 0 then
		local cat = compare(args.text, prep, string.len(iCheck) > 0, title)
		return string.format("[[%s|%s]]", link, args.text) .. cat
	else
		return string.format("%s[[%s|%s]]%s", i, link, prep, i)
	end
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p