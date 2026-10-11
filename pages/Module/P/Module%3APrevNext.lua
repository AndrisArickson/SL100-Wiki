local p = {}

function isRedundant(v, stx)
	stx = stx:gsub('&mdash;', '-'):gsub('&ndash;', '-'):gsub('—', '-'):gsub('–', '-')
	local vt = v:gsub('%(', ''):gsub('%)', ''):gsub('&mdash;', '-'):gsub('&ndash;', '-'):gsub('—', '-'):gsub('–', '-')
	if vt:find("<ref") ~= nil then
		vt = vt:sub(0, vt:find("<ref") - 1)
	end
	if v:find(stx..' %(') then
		return false
	elseif vt:find(stx..'|') or vt:find(stx..' ') or vt:find(stx..']]') then
		_, c = vt:gsub('%[%[', '')
		if c > 1 then
			return false
		elseif vt:find('crossover') or vt:find('Crossover') then
			return false
		end
		return true
	end
	return false
end

function p.decide(args)
	local title = mw.title.getCurrentTitle().text
	local hasParenthetical = title:find(" %(.*%)$")
	local parenthetical = ""
	if hasParenthetical then
		parenthetical = title:sub(hasParenthetical)
		title = title:sub(0, hasParenthetical - 1)
	end
	
	local issueIndex = title:find(" [0-9%.]+$")
	if not issueIndex then
		return args.value or ''
	end
	
	local ix = title:sub(issueIndex +1)
	local px = ''
	local zx = ix:find('%.')
	if zx then
		px = ix:sub(0, zx)
		ix = ix:sub(zx + 1)
	end
	local currentIssue = tonumber(ix)
	local targetIssue = nil
	if args.mode == "next" then
		targetIssue = currentIssue + 1
	elseif currentIssue <= 1 then
		return args.value or ''
	else
		targetIssue = currentIssue - 1
	end
	targetIssue = string.format('%s%s', px, targetIssue)
	
	local series = title:sub(0, issueIndex - 1)
	if args.value ~= nil and args.value ~= "" then
		local stx = (series..' '..targetIssue..(parenthetical ~= "" and ' '..parenthetical or '')):gsub('%(', ''):gsub('%)', ''):gsub('  ', '')
		if isRedundant(args.value, stx) then
			return args.value..'[[Category:Redundant prev & next fields in infobox]]'
		end
		return args.value
	end
	
	if args.label ~= nil and args.label ~= "" then
		return string.format("[[%s %s%s|%s %s]]", series, targetIssue, parenthetical, args.label, targetIssue)
	elseif series:find(" Part$") then
		return string.format("[[%s %s%s|Part %s]]", series, targetIssue, parenthetical, targetIssue)
	elseif series:find(" Volume$") then
		return string.format("[[%s %s%s|Volume %s]]", series, targetIssue, parenthetical, targetIssue)
	elseif series:find(" Special Edition$") then
		return string.format("[[%s %s%s|Special Edition %s]]", series, targetIssue, parenthetical, targetIssue)
	end
	
	local stext = series
	if series:sub(0, 11) == "Star Wars: " and #series > 15 then
		stext = series:sub(12)
	elseif series:sub(0, 12) == "Star Wars - "and #series > 15 then
		stext = series:sub(13)
	elseif series:sub(0, 10) == "Star Wars " and series:sub(0, 11) ~= "Star Wars (" then
		stext = series:sub(11)
	end
	
	local yearIndex = stext:find(" %(.*%)$")
	local link = ''
	local linkText = ''
	if yearIndex then
		local seriesName = stext:sub(0, yearIndex - 1)
		local year = stext:sub(yearIndex)
		link = string.format("%s %s", series, targetIssue)
		linkText = string.format("''%s''%s %s", seriesName, year, targetIssue)
	else
		link = string.format("%s %s%s", series, targetIssue, parenthetical)
		linkText = string.format("''%s'' %s", stext, targetIssue)
	end
	return "[[" .. link .. '|' .. linkText:gsub(" Comic'' ", "'' Comic ") .. "]]"
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame.args) do 
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	if args.value == "last" then
		return ''
	end
	return p.decide(args)
end

return p