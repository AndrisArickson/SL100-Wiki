local p = {}

local yesno = require('Module:Yesno')
local datatable = mw.loadData('Module:CardGameCite/data')
local currentTitle = mw.title.getCurrentTitle()

local function makeCategoryLink(cat)
    -- "Category" is split out here so that the module isn't put into the
    -- category "%s" when the page is saved.
    return string.format('[[%s:%s]]', 'Category', cat)
end

local function addBackup(template, link, urlPrefix, url, nobackup, args)
    if url == 'no-link' then
        return ''
    elseif url and url:find('<small') and url:find('%)</small>') then
    	return url
    elseif url then
        return string.format(' <small class="plainlinks">(%s)</small>', url)
    elseif nobackup then
        return ' <small class="plainlinks">(backup link not available)</small>'
    elseif currentTitle.fullText == "User:Hk 47/WiP3" then
    	return ''
    end
    local fullUrl = args.full_url
    if not full_url and link and urlPrefix then
		fullUrl = urlPrefix .. link
    elseif not full_url and link then
    	fullUrl = link
    end
    
	local buildArchive = require('Module:ArchiveAccess').render
	local archive = buildArchive({
		template_name = template, 
		full_url = fullUrl,
		target = link, 
		use_lua_subpage = args.use_lua_subpage,
		archiveurl = args.archiveurl,
		archivedate = args.archivedate,
		archivefile = args.archivefile,
		nobackup = args.nobackup,
		nolive = args.nolive, par = "1", normal_size = ""
	})
	if archive ~= nil and archive ~= "" then
		return ' ' .. archive
	elseif currentTitle.namespace == 0 or currentTitle.namespace == 6 then
        return makeCategoryLink('Pages with missing permanent archival links')
    end
	return ""
end

local function hideParanthetical(set)
	local stop = set:find('%s*%(')
    if stop then
        return set:sub(1, stop - 1)
    else
        return set
    end
    return set
end

local function compare(txt, full, t)
	if not txt or not full then
		return ''
	end
	
	local check, _ = txt:gsub("^''", ""):gsub("''$", "")
	if check == full then
		if t.namespace == 0 then
			return '[[Category:Unnecessary text parameters used in citation templates|' .. t.text .. ']]'
		elseif t.namespace == 6 or t.namespace == 120 then
			return '[[Category:Unnecessary text parameters used in citation templates|*' .. t.text .. ']]'
		end
	end
	return ''
end

local function hasValue(a, x)
	if a == nil then
		return false
	end
	for _, v in ipairs(a) do
		if v == x then
    		return true
		end
	end
	return false
end


local function makeWikitextError(template, msg)
    local ret = string.format(
        '<strong class="error">[[Template:%s]] error: %s.</strong>',
        template, msg
    )
    if currentTitle.namespace == 0 then
        ret = ret .. makeCategoryLink('Pages with template parameter errors')
    end
    return ret
end

local function buildSetText(setText, args, data, currentTitle, template)
	if args.promo ~= nil and args.promo ~= '' then
		return setText .. ' &mdash; ' .. args.set
	end
	
	local italics = "''"
	local set, text = args.set, args.text
    if (set == 'Core Set' or set == 'Base Set') and data.baseSet ~= nil then
		text = set
		set = data.baseSet
		italics = ''
		setText = setText .. ' '
	else
		if data.noItalics then
			italics = ''
		end
		if data.title then
        	setText = setText .. ' &mdash; '
        end
    end
    if data.suffix ~= nil and not set:find(data.suffix) then
		if hasValue(data.applyTo, set) then
			set = set .. ' (' .. data.suffix .. ')'
			if not text then
				text = hideParanthetical(set)
			end
		end
    end
	if args.hasText and args.text and set and template ~= "Topps" then
		setText = setText .. compare(args.text, hideParanthetical(set), currentTitle)
	end
    
    args.set, args.text = nil, nil
    if set == text or text == nil then
        setText = setText .. string.format("%s[[%s]]%s", italics, set, italics)
    else
        setText = setText .. string.format("%s[[%s|%s]]%s", italics, set, text, italics)
    end
    if args.subset ~= nil and args.subset ~= "" then
    	setText = setText .. ' – ' .. args.subset
    end
    return setText
end

function p._main(args, warnings, template)
    --[[
    Args:
    set: name of set article
    text: display text for set article link
    link: text to link card name to (possibly nil)
    customurl: Override parameter for archive URL, bypassing the default URL prefix
    cardname: name of card (possibly nil)
    nourl: boolean indicating external/internal link (true for internal)
    scenario (SWGTCG only): scenario name

    Warnings: table, possibly empty, of messages regarding deprecated
        parameters

    Template: name of the template, for looking up the data on it
    ]]
    local data = datatable[template]
    local setText = string.format('<span class="pnh"><span class="mhi">%s</span>&nbsp;', data.image)
    if currentTitle.fullText == "User:Hk 47/WiP3" then
    	setText = data.image .. ' '
	end
    -- Access to a local is faster than indexing a table each time
    local title, noSet = data.title, data.noSet
    if title then
        setText = setText .. title
    end
    if not noSet then
    	setText = buildSetText(setText, args, data, currentTitle, template)
    end
    local ret = {setText .. '</span>'}
    if currentTitle.fullText == "User:Hk 47/WiP3" and args.cardname then
    	ret = {''}
	end
    
    local link, cardname, customurl = args.link, args.cardname, args.customurl
    args.link, args.cardname, args.customurl = nil, nil, nil
    local backupLink = addBackup(template, link, data.urlprefix, args.manual_archiveurl, args.nobackup, args)
    args.manual_archiveurl, args.nobackup = nil, nil
    local scenarioFormat, scenarioName = data.scenario, args.scenario
    if scenarioFormat and scenarioName then
        args.scenario = nil
        ret[#ret + 1] = scenarioFormat:format(scenarioName)
    elseif (cardname == nil or cardname == "" or cardname == " ") then
        if (link or customurl) and not args.parent then
            return makeWikitextError(template, '"link" cannot be used without "cardname"')
        end
    else
        local ct = args.ctype and args.ctype or 'Card'
    	local cx = cardname
    	if args.ship then
    		cx = cx .. '&mdash;' .. args.ship
    	end
        local fmt = ' <small class="plainlinks cgct">%s: %s</small>%s'
        if currentTitle.fullText == "User:Hk 47/WiP3" then
        	fmt = ' <small>(%s: %s)</small>%s'
        end
        
        if customurl then
            ret[#ret + 1] = fmt:format(ct, string.format('[%s %s]', customurl, cx), backupLink)
        elseif not link then
            ret[#ret + 1] = fmt:format(ct, cx, backupLink)
        else
            local cardlink
            if args.nourl then
                if link == cardname then
                    cardlink = string.format('[[%s]]', cardname)
                else
                    cardlink = string.format('[[%s|%s]]', link, cardname)
                end
            else
                cardlink = string.format(
                    '[%s%s %s]', data.urlprefix, link, cx
                )
            end
            ret[#ret + 1] = fmt:format(ct, cardlink, backupLink)
        end
    end
    args.nourl = nil
    if not cardname and not args.parent and not scenarioName and not data.cardNotRequired and (currentTitle.namespace == 0 or currentTitle.namespace == 6) then
    	ret[#ret + 1] = '&nbsp;<small class="pnh mhi">(<span style="color: red"><b>no card name specified</b></span>)</small>[[Category:Citation template usages without cardname|'..(data.sortKey or template) .. currentTitle.text .. ']]'
    end

	args.full_url = nil
	args.parent = nil
	args.use_lua_subpage = nil
	args.archiveurl = nil
	args.archivedate = nil
	args.archivefile = nil
	args.nobackup = nil
	args.nolive = nil
	args.manual_archiveurl = nil
	args.hasText = nil
    -- At this point, the args table should be empty. Calling next() on it
    -- will return nil if it is indeed empty, or a string key if it is not.
    local key = next(args)
    if key and not (key == 1 or key == '1') then
        warnings[#warnings + 1] = makeCategoryLink(
            'Template usages with unrecognized parameters'
        )
        ret[#ret + 1] = string.format(
            ' <span style="color: red;">Warning: Call to Template:%s' ..
            ' contains unrecognized parameter "%s"</span>', template, key
        )
    end

    return table.concat(ret) .. table.concat(warnings)
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
	for k, v in pairs(frame.args) do
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

-- 
local function archiveWizards(args, warnings)
    if not args.nourl and args.link and args.link:match('wizards.com') then
        args.link = 'https://web.archive.org/web/' .. args.link
    end
end

-- Checks for the set parameter in the template parameters,
-- and also add warnings for the use of unnamed parameter 1
-- or the lack of a set parameter when it's required.
local function processSet(args, warnings)
    if not args.set then
        if args[1] then
            args.set = args[1]
            args[1] = nil
            if currentTitle.namespace == 0 or currentTitle.namespace == 6  then
	            warnings[#warnings + 1] = makeCategoryLink(
	                'Pages using deprecated unnamed parameter 1 for card game set'
	            )
            end
        else
            error('the "set" parameter is required', 0)
        end
    end
end

-- If the text parameter is not present, retrieves the text that will
-- be used for the set after some trimming.
local function generateTextFromSet(args, warnings)
	if args.text then
		args.hasText = true
    else
        args.text = hideParanthetical(args.set)
        args.hasText = false
    end
    if args.text:find('Core Set') then
        args.text = 'Core Set'
    end
end

-- Checks for the text parameter in the template parameters
-- and also add warnings for the use of unnamed parameter 2
-- or the lack of a text parameter when it's required.
local function processText(args, warnings)
	if args.text then
		args.hasText = true
    else
    	args.hasText = false
        if args[2] then
            args.text = args[2]
            args[2] = nil
            warnings[#warnings + 1] = makeCategoryLink(
                'Pages using deprecated unnamed parameter 2 for card game set'
            )
        else
            generateTextFromSet(args, warnings)
        end
    end
end

-- Checks for and stores the url parameter in the template parameters
-- and also add a warning for the use of the deprecated url parameter.
local function urlToLink(args, warnings)
    if not args.link then
        if args.url then
            args.link = args.url
            args.url = nil
            warnings[#warnings + 1] = makeCategoryLink(
                'Pages using deprecated url parameter to Template:SWGTCG'
            )
        end
    end
end

local function main(frame, template, ...)
    local success, args, warnings = pcall(processArgs, frame, ...)
    if not success then
        return makeWikitextError(template, args)
    end
    return p._main(args, warnings, template)
end

-- The following are specific function calls for each template that 
-- uses this Module framework for its template. To add a new template,
-- simply copy the last entry and change the template name. 
function p.TCG(frame)
    return main(frame, 'TCG', processSet, processText, archiveWizards)
end

function p.CCG(frame)
    return main(frame, 'CCG', processSet, generateTextFromSet)
end

function p.Destiny(frame)
    return main(frame, 'Destiny', processSet, processText)
end

function p.FFGTCG(frame)
    return main(frame, 'FFGTCG', processSet, processText)
end

function p.JKTCG(frame)
    return main(frame, 'JKTCG', processSet, processText)
end

function p.PocketModel(frame)
    return main(frame, 'PocketModel', processSet)
end

function p.SOTE(frame)
    return main(frame, 'SOTE')
end

function p.SOTEEMCC(frame)
    return main(frame, 'SOTEEMCC')
end

function p.SWGTCG(frame)
    return main(frame, 'SWGTCG', processSet, processText, urlToLink)
end

function p.Topps(frame)
    return main(frame, 'Topps', processSet, generateTextFromSet)
end

function p.YJCCG(frame)
    return main(frame, 'YJCCG', processSet, generateTextFromSet)
end

function p.SWIA(frame)
    return main(frame, 'SWIA', processSet, processText)
end

function p.SWU(frame)
    return main(frame, 'SWU', processSet, processText)
end

return p