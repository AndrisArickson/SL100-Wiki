local p = {}

local yesno = require('Module:Yesno')
local datatable = mw.loadData('Module:CCG/data')

local function makeCategoryLink(cat)
    -- "Category" is split out here so that the module isn't put into the
    -- category "%s" when the page is saved.
    if mw.title.getCurrentTitle().namespace == 10 then
    	return ''
    end
    return string.format('[[%s:%s]]', 'Category', cat)
end

local function makeWikitextError(template, msg)
    local ret = string.format(
        '<strong class="error">[[Template:%s]] error: %s.</strong>',
        template, msg
    )
    if mw.title.getCurrentTitle().namespace ~= 10 then
        ret = ret .. makeCategoryLink('Pages with template parameter errors')
    end
    return ret
end

local function buildCategory()
    if mw.title.getCurrentTitle().namespace == 10 then
        return ''
    end
    return makeCategoryLink('Pages with missing permanent archival links')
end

function p._main(args)
    local image = "[[File:Swccglogolg.png|text-top|x16px|link=Star Wars Customizable Card Game]]"
    local title = "[[Star Wars Customizable Card Game|''Star Wars'' Customizable Card Game]]"

    local set = args.set
    local error = false
    if set == nil then
    	if mw.title.getCurrentTitle().namespace == 10 then
            return ''
    	end
    	set = '<span style="color: red"><b>No set defined!</b></span>'
    	error = true
    end
    local set_data = datatable[set]
    if set_data == nil then
    	if mw.title.getCurrentTitle().namespace == 10 then
            return ''
    	end
    	set = string.format('<span style="color: red"><b>Unknown set: %s</b></span>', set)
    	error = true
    end

    local ret = {string.format("<span class=\"pnh\">%s&nbsp;%s &mdash; ''[[%s]]''</span>", image, title, set)}
    if error then
    	return table.concat(ret)
	end

    local cardname = args.cardname
    local cardtext = args.cardtext
    if cardname == nil then
    	if not args.parent then
    		ret[#ret + 1] = makeCategoryLink("Citation template usages without cardname|CCG")
    		ret[#ret + 1] = '&nbsp;<small class="cgct"><span style="color: red">\'\'\'no cardname specified!\'\'\'</span></small>'
    	end
    	return table.concat(ret)
    end
    cardname = cardname:gsub("_", " "):gsub("(Dark Side)", "(Dark)"):gsub("(Light Side)", "(Light)")
	if cardtext == nil and string.find(cardname, "''") then
		cardtext = cardname
		cardname = cardname:gsub("''", "")
	end
    	
    local card_data = set_data[string.upper(cardname:gsub('é', 'e'):gsub("á", "a"))]
    if card_data == nil then
		ret[#ret + 1] = string.format(" <small class=\"cgct plainlinks\">'''Card: %s'''</small>", cardname)
		if mw.title.getCurrentTitle().namespace ~= 100 and not string.find(mw.title.getCurrentTitle().text, "Cavalier One") then
			ret[#ret + 1] = makeCategoryLink("Unknown cardname values") .. ' ♦'
		end
		return table.concat(ret)
    end
    
    local link
    local linkIsSame = false
    if args.link then
    	link = args.nourl ~= nil and args.link or "https://res.starwarsccg.org/cardlists/images/starwars/" .. args.link
    	if card_data.link ~= nil and card_data.link ~= "" and link ~= nil and link ~= "" then
    		linkIsSame = string.lower(link) == string.lower(card_data.link)
    	end
    else
    	link = card_data.link
    end
    local archivedate = card_data.archivedate
    local archiveurl = card_data.archiveurl

    local fmt
    if args.nourl then
    	fmt = ' <small class="plainlinks cgct">Card: [[%s|%s]]</small>%s'
    else 
    	fmt = ' <small class="plainlinks cgct">Card: [%s %s]</small>%s'
    end
    local archive_link = ''
    if archiveurl then
        archive_link = string.format(' <small>([%s backup link])</small>', archiveurl, link)
    elseif archivedate then
        archive_link = string.format(' <small>([https://web.archive.org/web/%s/%s backup link])</small>', archivedate, link)
    elseif args.nobackup or card_data.nobackup then
    	archive_link = ' <small>(no backup available)</small>'
    else
        archive_link = string.format(' <small>([https://web.archive.org/web/%s backup link] <span style="color: red"><b>not verified!</b></span>%s)</small>', link, buildCategory())
    end
    if cardtext then
		ret[#ret + 1] = fmt:format(link, cardtext, archive_link)
	else
		ret[#ret + 1] = fmt:format(link, cardname, archive_link)
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
        return makeWikitextError("CCG", args)
    end
    return p._main(args)
end

return p