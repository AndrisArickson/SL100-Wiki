local p = {}

local datatable = mw.loadData("Module:Reprint/data")
local currentTitle = mw.title.getCurrentTitle()

local function abbreviate(s, a)
	if a then
		s = s:gsub(a, ""):gsub("%|: ", "|")
	end
	return s
end

local function prepareParents(title, data, formatting)
	local ret = {}
	if title:sub(0, 16) == "Star Wars (1977)" then
		local num = tonumber(title:sub(17))
		if num > 95 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 7: Far, Far Away]]''"
		elseif num > 81 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 6: Wookiee World]]''"
		elseif num > 67 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 5: Fool's Bounty]]''"
		elseif num > 53 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 4: Screams in the Void]]''"
		elseif num > 38 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 3: Resurrection of Evil]]''"
		elseif num > 20 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 2: Dark Encounters]]''"
		elseif num > 0 then
			ret[#ret + 1] = "''[[Star Wars: A Long Time Ago... Volume 1: Doomworld]]''"
		end
	end
	if data.format ~= nil then
		for _, t in ipairs(data.format) do
			ret[#ret + 1] = t
		end
	elseif data.issues ~= nil then
		for _, t in ipairs(data.issues) do
			if formatting[t] ~= nil then
				ret[#ret + 1] = "[[" .. t .. "|" .. formatting[t] .. "]]"
			elseif t:find("offizielle") then
				ret[#ret + 1] = "[[" .. t .. "|" .. t:gsub("Star Wars", "''Star Wars"):gsub("Magazin ", "Magazin'' ") .. "]]"
			else
				ret[#ret + 1] = "''[[" .. t .. "]]''"
			end
		end
	end
	return ret
end

function p.render(args)
	return p.buildReprint(args.title, args.issue, args.full, args.abbr)
end

function p.buildReprint(originalTitle, issue, full, abbr)
	if not originalTitle then
		return '<strong class="error">[[Template:Reprint]] error: no title provided.</strong>'
	end
	local title = originalTitle:gsub('&ndash;', '–'):gsub('&mdash;', '—')
	
	local data = datatable[title:gsub('"', "")]
	if not data and issue then
		data = datatable[title:gsub('"', "") .. '-' .. issue]
	end
	
	if not data and title:sub(0, 16) == "Star Wars (1977)" then
		data = {issues = {}, color = true}
	end
	
	if not data then
		return '<strong class="error">[[Template:Reprint]] error: no reprints found for title: ' .. title .. '.</strong>[[Category:Bad parameters in Template:Reprint|' .. currentTitle.text .. ']]'
	end
	
	local parents = prepareParents(title, data, datatable.formatting)
	if #parents == 0 then
		return ''
	elseif full then
		local ret = {}
		for _, t in ipairs(parents) do
			local s = '"[[' .. originalTitle
			if data.image then
				s = data.image .. ' ' .. s
			end
			if data.text then
				s = s .. "|" .. data.text
			end
			s = s .. ']]" — ' .. abbreviate(t, abbr)
			if data.color then
				s = s .. ' <small>(colorized reprint)</small>'
			end
			ret[#ret + 1] = "\n*" .. s
		end
		return table.concat(ret)
	else
		local s = ''
		for i, v in ipairs(parents) do
			v = abbreviate(v, abbr)
			if i == 1 then
				s = v
			elseif i == #parents and #parents == 2 then
				s = s .. ' and ' .. v
			elseif i == #parents then
				s = s .. '; and ' .. v
			else
				s = s .. '; ' .. v
			end
		end
		if data.color and title:sub(0, 16) == "Star Wars (1977)" then
			return '<small class="mobile-hide">(recolorized in ' .. s .. ')</small>'
		elseif data.color then
			return '<small class="mobile-hide">(colorized in ' .. s .. ')</small>'
		else
			return '<small class="mobile-hide">(reprinted in ' .. s .. ')</small>'
		end
	end
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p