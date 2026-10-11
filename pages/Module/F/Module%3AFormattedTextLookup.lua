local p = {}

local title = mw.title.getCurrentTitle()

local ignore = {"Build R2-D2", "Build the X-Wing", "Build the Falcon", "Step By Step"}

function startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

local function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function hideParanthetical(s)
	local stop = s:find('%s*%(')
    if stop then
        return s:sub(1, stop - 1)
    else
        return s
    end
    return s
end

local function strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function flatten(s)
	return strip(string.lower(s:gsub("'s ", " "):gsub('%!', ''):gsub('%?', ''):gsub('&#39;', "'"):gsub("'", ""):gsub('—', '-'):gsub('–', '-'):gsub('&mdash;', '-'):gsub('&ndash;', '-'):gsub(' %-', '-'):gsub('%- ', '-'):gsub('s$', '')):gsub('the ', ''):gsub('droid, part', 'droids, part'))
end

function skipCategory()
	if title.namespace == 4 and (title.fullText:find('nominations') or title.fullText:find('reviews')) then
		return true
	elseif title.namespace % 2 == 1 or title.namespace == 2 or title.namespace == 10 or title.namespace == 100 then
		return true
	end
	return false
end

function addCatIfNecessary(text, t, link, args)
	if skipCategory() then
		return ''
	elseif text ~= nil and text ~= "" and not string.find(title.text, 'Bot requests') then
		local tx = string.lower(args.target .. ': ')
		local tf = flatten(t):gsub(tx, ''):gsub(': ', '-')
		local xf = flatten(text):gsub(tx, ''):gsub(': ', '-')
		if tf == xf then
			if string.find(title.fullText, 'Wookieepedia:Sources') or string.find(title.fullText, 'Wookieepedia:Appearances') or title.text == link or startsWith(title.text, link .. ' ') then
				return ''
			end
			return '[[Category:Unnecessary text parameters used in citation templates|' .. title.text .. ']] ‡'
		elseif link ~= "Build R2-D2" and link ~= "Build the X-Wing" and link ~= "Build the Falcon" and link ~= "Step By Step" and title.text ~= link then
			local st = ''
			if args.show then
				st = ' <' .. tf .. '><' .. xf .. '>'
			end
			return '[[Category:Incorrect text parameters in citation templates|' .. title.text .. ']] ‡' .. st
		end
	end
	return ''
end

function p.render(args)
	if args.exception and args.target and args.exception == args.target then
		return ''
	end
	local dataStoreName = args.type and args.type or 'data'
	local data = mw.loadData('Module:FormattedTextLookup/' .. dataStoreName)
	local template = args.template
	local target = args.target
	local targetLink = target
	if args.prefix ~= nil and args.prefix ~= "" then
		targetLink = args.prefix .. target
	end
	local targetKey = args.target
	if args.issue then
		targetKey = args.issue .. '-' .. args.target
	end
	if targetKey then
		targetKey = targetKey:gsub('—', '-'):gsub('–', '-'):gsub('&mdash;', '-'):gsub('&ndash;', '-')
	end
	
	local text = args.text or ''
	if args.combine and text ~= nil and text ~= "" then
		text = args.target .. ': ' .. text
	end
	local i = ""
	if args.italics then
		i = "''"
	end
	if target == nil or target == "" then
		local x  ='<span style="color: red"><b>No target defined!</b></span>'
		if title.namespace ~= 10 then
			x = x .. '[[Category:Invalid set parameter values in game citation templates|' .. title.text .. ']]'
		end
		return x
	end
	
	local data = data[template]
	if data ~= nil and data["exceptions"] and hasValue(data["exceptions"], target) and text ~= "" then
		return string.format("[[%s|%s]]", target, text)
	elseif data ~= nil and data[targetKey] ~= nil and data[targetKey] == "<TBD>" then
		if target:find('%s*%(') then
			target = hideParanthetical(target)
		end
		if args.textOnly then
			return ''
		end
		return string.format("%s[[%s|%s]]%s%s", i, targetLink, target, i, c)
	elseif data ~= nil and data[targetKey] ~= nil then
		if args.textOnly or data[targetKey]:sub(0, 2) == '[[' then
			return data[targetKey] .. addCatIfNecessary(text, data[targetKey], targetLink, args)
		end
		return string.format("[[%s|%s]]%s", targetLink, data[targetKey], addCatIfNecessary(text, data[targetKey], targetLink, args))
	else
		if target:find('%s*%(') then
			target = hideParanthetical(target)
		end
		if args.textOnly and hasValue(ignore, title.text) then
			return ''
		elseif args.textOnly then
			return target .. addCatIfNecessary(text, target, targetLink, args)
		end
		local x = string.format("%s[[%s|%s]]%s%s", i, targetLink, target, i, addCatIfNecessary(text, target, targetLink, args))
		if args.type == "Cards" and args.template == "Topps" and not skipCategory() then
			x = x .. '[[Category:Set values with undefined formatting text in lookup data|' .. title.text .. ']] ‡'
		end
		return x
	end
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	if frame:getParent().args and frame:getParent().args.show then
		args.show = true
	end
	return p.render(args)
end

return p