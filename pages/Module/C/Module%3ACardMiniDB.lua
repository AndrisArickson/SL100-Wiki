local p = {}

local yesno = require('Module:Yesno')
local pagetitle = mw.title.getCurrentTitle()

local tooBig = {"Anakin Skywalker", "Galactic Empire/Legends/Sources"}

local function makeCategoryLink(cat)
    -- "Category" is split out here so that the module isn't put into the
    -- category "%s" when the page is saved.
    if pagetitle.namespace == 10 or pagetitle.namespace == 2 or pagetitle.namespace % 2 == 1 then
    	return ''
    end
    return string.format('[[%s:%s|%s]]', 'Category', cat, pagetitle.text)
end

local function makeWikitextError(template, msg)
    local ret = string.format(
        '<strong class="error">[[Template:%s]] error: %s.</strong>',
        template, msg
    )
    if pagetitle.namespace ~= 10 and pagetitle.namespace ~= 2 then
        ret = ret .. makeCategoryLink('Pages with template parameter errors')
    end
    return ret
end

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function startsWith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function pipelink(s, t)
	if t then
		return string.format('[[%s|%s]]', s, t)
	else
		return string.format('[[%s]]', s)
	end
end

function prepareSetLink(name, text)
	return text ~= nil and text or ("[["..name.."]]")
end

local function checkCard(cards, x, c, s, t)
	if s ~= nil and cards[c .. ':' .. s] then
		return x, cards[c .. ':' .. s], t
	elseif cards[c] then
		return x, cards[c], t
	end
	return nil, nil, false
end

local function retrieveCardData(data, set, cardname, ship, legends, split)
	local is_legends = has_value(legends, set)
	local is_split = has_value(split, set)
	local c = (cardname or ''):gsub('"', ''):gsub("''", "")
	local s = (ship or ''):gsub("'", "")
	if data[set] ~= nil then
		local a, b, t = checkCard(data[set], set, c, s, false)
		if a ~= nil then
			return a, b, false
		end
		for k, v in pairs(data[set]) do
			if s ~= nil and string.lower(k) == string.lower(c .. ':' .. s) then
				return set, v, false
			elseif string.lower(k) == string.lower(c) then
				return set, v, false
			end
		end
	end
	for x, cards in pairs(data) do
		local valid = false
		if is_split or (is_legends and has_value(legends, x)) or (not is_legends and not has_value(legends, x)) then
			local a, b, t = checkCard(cards, x, c, s)
			if a ~= nil then
				return a, b, true
			end
		end
	end
	return nil, nil, false
end


local function addHideSpan(s)
	if pagetitle.namespace == 4 then
		return s
	end
	return '<span class="pnh">' .. s .. '</span>'
end


local function buildText(ct, known, imageClass, image, title, sep, set, stext, link, otherLinks, cx)
	local setText = string.format('<span class="%s">%s</span> %s %s', imageClass, image, title, sep)..prepareSetLink(set, stext)
	
	local b = "'''"
	if known then
		b = ""
	end
	
	if link ~= nil and link ~= '' then
		cx = string.format('[%s %s]', link, cx)
	end
	local cardText = string.format(' <small class="cgct plainlinks">%s%s: %s%s</small>', b, ct, cx, b)
	if #otherLinks > 0 then
		cardText = cardText..'  <small class="cgct plainlinks">' .. otherLinks[1] .. ' other model]</small>'
	end
	return addHideSpan(setText) .. cardText
end

local function concatenate(items)
	local s = ''
	for i, v in ipairs(items) do
		if i == 1 then
			s = v
		elseif i == #items and #items == 2 then
			s = s .. ' and ' .. v
		elseif i == #items then
			s = s .. ', and ' .. v
		else
			s = s .. ', ' .. v
		end
	end
	return s
end

function concatAndShorten(list, set_text, suffix)
	local items = {}
	if #list == 1 and set_text[list[1]] then
		items[1] = set_text[list[1]]
	elseif #list == 1 then
		items[1] = string.format('[[%s]]', list[1])
	elseif #list > 1 then
		for i, v in pairs(list) do
			if i == #list and set_text[v] and set_text[v]:find('|') then
				items[i] = set_text[v]:gsub(']]', 's]]')
			elseif i == #list then
				items[i] = string.format('[[%s]]s', v)
			elseif set_text[v] then
				items[i] = set_text[v]:gsub(' ' .. suffix .. ']]', ']]')
			else
				items[i] = pipelink(v, v:gsub(' ' .. suffix, ''))
			end
		end
	end
	return concatenate(items)
end

function isSharedName(data, cardname, ship, set, checkOthers)
	local cx = cardname:gsub('"', ''):gsub("''", '')
	for x, cards in pairs(data) do
		if x == set then
			local i = 0
			for k, v in pairs(cards) do
				if k == cx or startsWith(cx, k .. ' (') or startsWith(cx, k .. ':') then
					i = i + 1
				end
			end
			if i > 1 then
				return true
			end
		elseif checkOthers then
			for k, v in pairs(cards) do
				if k == cx or startsWith(cx, k .. ' (') or startsWith(cx, k .. ':') then
					if v.ship == nil or ship == nil or v.ship ~= ship then
						return true
					end
				end
			end
		end
	end
	return false
end

local function addBackup(set_data, template, args, link)
	if set_data.hasArchive == nil or set_data.hasArchive == "" then
		return ""
	elseif link == nil or link == "" then
		return ""
	elseif set_data.url ~= nil and set_data.url ~= "" and startsWith(link, set_data.url) then
		return ""
	end
	local buildArchive = require('Module:ArchiveAccess').render
	local archive = buildArchive({
		template_name = template, target = link, full_url = link,
		use_lua_subpage = "1", shared_site = args.sharedSite,
		archiveurl = args.archiveurl, archivedate = args.archivedate,
		archivefile = args.archivefile, nobackup = args.nobackup,
		nolive = args.nolive, par = "1", normal_size = ""
	})
	if archive ~= nil and archive ~= "" then
		return ' ' .. archive
	end
	return ""
end

function addSubtitleOrShip(cx, cardname, card_data) 
	if card_data.subtitle and card_data.ship then
    	return string.format('%s &mdash; %s &mdash; %s', cardname, card_data.subtitle, card_data.ship)
    elseif card_data.subtitle then
    	return string.format('%s &mdash; %s', cardname, card_data.subtitle)
    elseif card_data.ship then
    	return string.format('%s &mdash; %s', cardname, card_data.ship)
    end
	return cx
end

function prepareReprints(ret, args, card_data, set_list, set_text, set_data)
	local collapseNames = set_data.collapse or {}
    local wk, toCollapse, other = {}, {}, {}
    local rx = 0
	if card_data.reprints then
		for i, v in pairs(set_list) do
			if has_value(card_data.reprints, v) then
				rx = rx + 1
				local found = false
				if v:find('Wookiee Warrior') then
					wk[#wk + 1] = v
				end
				for a, b in pairs(collapseNames) do
					if v:find(b) and not found then
						if toCollapse[b] == nil then
							toCollapse[b] = {}
						end
						toCollapse[b][#toCollapse[b] + 1] = v
						found = true
					end
				end
				if not found then
					other[#other + 1] = v
				end
			end
		end
	end
	
    if rx > 0 and has_value(tooBig, pagetitle.fullText) then
    	-- do nothing
    elseif rx > 0 then
    	local repr = {}
    	local done = 0
    	if #wk == 2 then
    		repr[#repr + 1] = '[[Wookiee Warriors Unit Expansion (2018)|Wookiee Warriors Unit Expansions (2018)]] and [[Wookiee Warriors Unit Expansion (2021)|(2021)]]'
    		local nx = {}
    		for i, v in pairs(toCollapse['Unit Expansion']) do
    			if not v:find('Wookiee Warriors') then
    				nx[#nx + 1] = v
    			end
    		end
    		toCollapse['Unit Expansion'] = nx
    	end
    	for cn, cs in pairs(toCollapse) do
    		if #cs > 0 then
    			done = done + #cs
    			repr[#repr + 1] = concatAndShorten(cs, set_text, cn)
    			if #cs > 1 and rx > done then
    				repr[#repr] = repr[#repr] .. ','
    			end
			end
    	end
	    for i, v in pairs(other) do
	    	local vt = set_text[v] or v
			if set_text[v] ~= nil then
				repr[#repr + 1] = set_text[v]
			else
				repr[#repr + 1] = string.format("[[%s]]", v)
			end
	    end
    	ret[#ret + 1] = ' <small class="rht">Reissued in ' .. concatenate(repr):gsub(',,', ',') .. '</small>'
    elseif args.reprint then
    	ret[#ret + 1] = makeCategoryLink('Invalid reprint parameters in game citation templates') .. ' ¿'
    end
end

function p._main(template, originalSet, args)
	local shared = mw.loadData('Module:CardMiniDB/shared')
	local set_data = shared[template]
	local image, title, url = set_data.image, set_data.title, set_data.url
	if pagetitle.text:find("WPWeb:Template icons standardization") then
		return string.format("%s&#32;%s &mdash; %s", image, title, set and set or '')
	end
	
	local card_list = mw.loadData('Module:CardMiniDB/' .. template)
	local set_list = set_data.sets
    local set_text = set_data.stext
	local legends, split = {}, {}
	if set_data.legends ~= nil then
		legends = set_data.legends
	end
	if set_data.split ~= nil then
		split = set_data.split
	end

	local imageClass = set_data.invert and "mhi invert-images" or "mhi"
	local set = originalSet:gsub(' %(.*%)$', '')
	if originalSet:find("%(20") then
		set = originalSet
	end
	local legacySetName = set ~= originalSet
    local cardname = args.cardname or ''
    local ct = 'Card'
    if args.pack ~= nil and args.pack ~= "" then
    	cardname = args.pack
    	ct = 'Pack'
    elseif args.mission ~= nil and args.mission ~= "" then
    	cardname = args.mission
    	ct = "Mission"
    end
    local ship = args.ship
    local link = args.link or ''
    local bypass = args.bypass
    if link ~= nil and link ~= "" and not link:find('http') then
    	link = url .. link
    end
    
	local cx = cardname:gsub(' %(.*?%)', '')
	if ship then
		cx = cx .. ' &mdash; ' .. ship
	end
    
    local err = ""
	local sep = '&mdash; '
    if set_data.baseSet ~= nil and set == set_data.baseSet then
		sep = ''
    	if not err then
    		err = "Legacy set parameter values for Template:" .. template
    	end
    	set = "Core Set"
    elseif set == 'Core Set' then
    	sep = ''
    end
    
    if set == nil then
    	if pagetitle.namespace == 10 then
            return ''
    	end
    	set = '<span style="color: red"><b>No set defined!</b></span>'
    	err = makeCategoryLink("Invalid set parameter values in game citation templates")
    elseif not has_value(set_list, set) then
    	if pagetitle.namespace == 10 then
            return ''
    	elseif not pagetitle.text:find("CardSets") and pagetitle.text ~= "List of future products" then
	    	set = string.format('<span style="color: red"><b>Unknown set: %s</b></span>', set)
	    	err = makeCategoryLink("Invalid set parameter values in game citation templates")
    	end
    end

    if not args.cardname and not args.pack and not args.mission then
    	local nct = ""
    	if set_data.requireCard and not args.parent and not set:find('Map Pack') and not set:find('Scenario Pack') and not set:find('Colossal Pack') and not (template == "SWMiniCite" and pagetitle.namespace == 6) then
    		nct = ' &mdash; <small class="mhi"><span style="color: red"><b>No card/pack provided!</b></span></small>' .. makeCategoryLink("Citation template usages without cardname|"..set)
    	end
		return string.format('<span class="%s">%s</span> %s %s%s%s', imageClass, image, title, sep, prepareSetLink(set, set_text[set]), nct)..err
    end
    
    local s, card_data, wrong = retrieveCardData(card_list, set, cardname, ship, legends, split)
    if s == nil or template == "NewLegion" then
    	local skip = bypass or (template == "SWIA" and args.cardname ~= nil and args.cardname ~= "") or template == "NewLegion"
    	local t = buildText(ct, skip, imageClass, image, title, sep, set, set_text[set], link, {}, cx)
		if skip then
    		t = t .. ' ' .. addBackup(set_data, template, args, link) .. err
    	elseif not bypass then
    		t = t .. makeCategoryLink("Unknown cardname values") .. err .. ' ♦'
    	end
    	return t
    end
    
    cx = addSubtitleOrShip(cx, cardname, card_data)
    
    link = card_data.link or ''
    if link ~= nil and link ~= '' and not link:find('http') then
    	link = url .. link
    end
    local links = {}
    if card_data.links then
    	for i, v in pairs(card_data.links) do
    		if v:find('http') then
	    		links[#links + 1] = v
    		else
    			links[#links + 1] = url .. v
    		end
    	end
    end
	
    local cardText = buildText(ct, bypass or not wrong, imageClass, image, title, sep, set, card_data.stext or set_text[set], link, links, cx)
    local ret = {cardText .. ' ' .. addBackup(set_data, template, args, link)}
    if err and not bypass then
    	ret[#ret + 1] = err
    end
    
    if args.reprint then
		prepareReprints(ret, args, card_data, set_list, set_text, set_data)
	end
	
    if card_data.link and args.link then
    	ret[#ret + 1] = makeCategoryLink('Unnecessary link parameter in game citation templates')  .. ' ‡'
    end
	
    if not bypass then
	    if wrong then
	    	ret[#ret + 1] = makeCategoryLink('Incorrect cardname-set pairings in game citation templates')  .. ' ‡'
	    end
	    if card_data.ship ~= nil and (ship == nil or ship == '') then
	    	if isSharedName(card_list, cardname, card_data.ship, set, false) then
	    		ret[#ret + 1] = makeCategoryLink("Miniature game citation template usages without ship parameter") .. ' •'
	    	end
	    end
	    if card_data.fmt ~= nil and card_data.fmt ~= cardname then
	    	ret[#ret + 1] = makeCategoryLink('Incorrect cardnames in game citation templates') .. ' •'
	    end
	    if legacySetName then
	    	ret[#ret + 1] = makeCategoryLink('Legacy set values in game citation templates') .. ' •'
	    end
	end
    return table.concat(ret)
end

-- Trim whitespace from template arguments and store them
local function processArgs(frame, ...)
    local args, warnings = {}, {}
    local funcs = {...}
    for k, v in pairs(frame:getParent().args) do
        v = v:match('^%s*(.-)%s*$') -- trim whitespace
        if v ~= '' then
            args[k] = v
        end
    end
    args.nourl = yesno(args.nourl)
    for _, func in ipairs(funcs) do
        func(args, warnings)
    end
    return args, warnings
end

function p.main(frame, ...)
    local success, args, warnings = pcall(processArgs, frame, ...)
    if not success then
        return makeWikitextError("XW2", args)
    end
    return p._main(frame.args.template, frame.args.set or '', args)
end

return p