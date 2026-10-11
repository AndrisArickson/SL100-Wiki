local p = {}
local NS_MODULE = 828

local currentTitle = mw.title.getCurrentTitle()
	
function yes(s)
	return s ~= nil and s ~= ''
end

function isMissing(s)
	return s == nil or s == '' or (s:sub(0, 3) == "{{{" and s:sub(-3) == "}}}")
end

function ternary(cond, t, f)
	if cond then return t else return f end
end

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local CUSTOM_AUDIOBOOKS = {
	["5-Minute Star Wars Stories"] = "5-Minute Star Wars Stories (German audiobook)",
	["5-Minute Star Wars Stories (2015)"] = "5-Minute Star Wars Stories (German audiobook)",
	["5-Minute Star Wars Stories (second edition)"] = "Star Wars 5-Minute Stories Audio Collection: Volume 1",
	["5-Minute Star Wars Villain Stories"] = "5-Minute Star Wars Stories 2",
	["5-Minute Star Wars Stories Strike Back"] = "5-Minute Star Wars Stories 2",
	["The Prequel Trilogy Stories"] = "Star Wars Storybook Collection",
	["The Original Trilogy Stories"] = "Star Wars Storybook Collection",
	["Canto Bight (novella collection)"] = "Canto Bight (audiobook)",
}

local IGNORE = {
	"An Unlikely Ally", "X-Wing Attack",  "The Heart of a Jedi", "A Spark of Hope", "Danger in the Desert", "The Final Battle"
}

local ENCYCLOPEDIA = {"Ace Squadron", "Anakin Skywalker", "C-3PO", "Coruscant", "Darth Vader", "Emperor Palpatine", "Han Solo", "Luke Skywalker", "Millennium Falcon", "Naboo", "Obi-Wan Kenobi", "Padmé Amidala", "Princess Leia Organa", "R2-D2", "TIE Fighters", "Tatooine", "The Clone Wars", "The First Order", "The Grand Army of the Republic", "The Rebel Alliance", "The Resistance", "The Separatists"}

local DEPARTMENTS = {"A Certain Point of View", "Bantha Tracks", "Blaster", "Books", "Bounty Hunters", "Comics", "Comlink", "Crossword", "Games", "Jedi Archive", "Jedi Library", "Red Five", "Rogues Gallery", "Toys", "Versus"}

function buildAbText(story) 
	return string.format('<small>(and [[%s|audiobook]])</small>', story)
end

function buildAudiobook(param, story)
	if story == "5-Minute Star Wars Stories (second edition)" or story == "Star Wars 5-Minute Stories" then
		local x = ""
		-- if not hasValue(IGNORED, story) then
		-- 	x = "and [[Star Wars 5-Minute Stories (audioobok)|audiobook]] "
		-- end
		if param == "2" then
			x = x .. "and [[Star Wars 5-Minute Stories Audio Collection: Volume 2|audio collection]]"
		else
			x = x .. "and [[Star Wars 5-Minute Stories Audio Collection: Volume 1|audio collection]]"
		end
		return '<small>('..x..')</small>'
	elseif CUSTOM_AUDIOBOOKS[story] ~= nil then
		return buildAbText(CUSTOM_AUDIOBOOKS[story])
	end
	return buildAbText(story .. " (audiobook)")
end

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s|%s]]', 'Category', cat, currentTitle.text)
end

-- isCurrentPageMainSpaceOrFile determines whether the page being parsed is a mainspace or file page.
local function isCurrentPageMainSpaceOrFile()
	return currentTitle.namespace == 0 or currentTitle.namespace == 6 or currentTitle.namespace == 828 or string.find(currentTitle.fullText, 'Wookieepedia:Sources') or string.find(currentTitle.fullText, 'Wookieepedia:Appearances')
end

local function hideParenthetical(set)
	local stop = set:find('%s*%(')
    return stop and set:sub(1, stop - 1) or set
end

local function compare(txt, full, italics)
	if not txt or not full then
		return ''
	end
	
	local match = full == txt
	if italics then
		match = full == txt:gsub("^''", ""):gsub("''$", "")
	end
	
	if match then
		if currentTitle.namespace == 0 then
			return '[[Category:Unnecessary text parameters used in citation templates|' .. currentTitle.text .. ']] ·'
		elseif currentTitle.namespace == 6 or currentTitle.namespace == 120 then
			return '[[Category:Unnecessary text parameters used in citation templates|*' .. currentTitle.text .. ']] ·'
		end
	end
	return ''
end

function buildIssue(s, f, i, x, y, italics, noIssue)
	if isMissing(s) or (isMissing(i) and currentTitle.namespace ~= 10) then
		return '<strong class="error">Missing series/issue parameters, cannot construct parent</strong>' .. makeCategoryLink("BaseCitation usages with invalid issue parameters")
	elseif noIssue and yes(f) then
		return string.format("[[%s|%s %s%s]]", s, f, i or '{{{issue}}}', y)
	elseif noIssue then
		return string.format("[[%s|%s%s%s %s%s]]", s, italics, hideParenthetical(s), italics, i or '{{{issue}}}', y)
	elseif yes(f) then
		return string.format("[[%s %s%s|%s %s%s]]", s, i, x, f, i or '{{{issue}}}', y)
	else
		return string.format("[[%s %s%s|%s%s%s %s%s]]", s, i or '{{{issue}}}', x, italics, hideParenthetical(s), italics, i or '{{{issue}}}', y)
	end
end

function buildName(s, i)
	return string.format('%s %s', s, i)
end

local matches = {"audiobook", "second edition", "Second Edition"}

local function autoItalicizeParent(parent)
	if parent:match(" Level 1$") ~= nil then
		return nil
	end
	local m = parent:match("( %(%d+%) %d%d?%d?)$")
	local n = parent:match("( %d%d?%d?)$")
	if m ~= nil then
        return "''"..parent:sub(0, #parent - #m).."''"..m
	elseif n ~= nil then
        return "''"..parent:sub(0, #parent - #n).."''"..n
    end
	
	for _, suffix in ipairs(matches) do
		local q = parent:match("( %("..suffix.."%))$")
        if q ~= nil then
            return "''"..parent:sub(0, #parent - #q).."'', "..suffix
        end
    end
    return nil
end

local function isOtherSeries(args, issue)
	local swap = false
	if yes(args.checkseries) and yes(args.threshold) and (yes(args.series2) or yes(args.suffix2)) then
		local threshold = tonumber(args.threshold)
		if yes(args.issue) and tonumber(args.issue) ~= nil and tonumber(args.issue) <= threshold then
			swap = true
		elseif yes(args.issue1) and tonumber(args.issue1) ~= nil and tonumber(args.issue1) <= threshold then
			swap = true
		end
	end
	return swap and makeCategoryLink("Legacy magazine series citations") or ''
end

function buildParent(args)
	local image = args.image
	local cat = ''
	local italics = "''"
	if yes(args.noitalics) or (args.parent or ''):find('Free Comic Book Day') then
		italics = ''
	end
	local ptext = args.ptext
	if yes(args.parent) and not yes(args.ptext) and args.italicize then
	    ptext = autoItalicizeParent(args.parent)
	end
	
	if yes(args.parent) and yes(ptext) then
		return image, args.parent, string.format("[[%s|%s]]", args.parent, ptext) .. compare(args.ptext, hideParenthetical(args.parent), italics)
	elseif yes(args.parent) then
		return image, args.parent, string.format('%s[[%s|%s]]%s', italics, args.parent, hideParenthetical(args.parent), italics)
	end
	
	local series = args.series
	if isMissing(series) and isCurrentPageMainSpaceOrFile() then
		return image, '', '<strong class="error">Missing series parameters, cannot construct parent</strong>' .. makeCategoryLink("BaseCitation usages with invalid parent parameters")
	elseif isMissing(series) then
		return image, '', string.format('%s[[{{{parent}}}]]%s', italics, italics)
	end
	
	local noIssueLink = args.noissue
	local stext = args.stext
	local issue = args.issue
	local issue1 = args.issue1
	local issue2 = args.issue2
	local suffix = ''
	local ss = ''
	if yes(args.suffix) then
		suffix = ' ' .. args.suffix
		if yes(args.showsuffix) then
			ss = ' ' .. suffix
		end
	end
	
	if yes(args.threshold) and (yes(args.series2) or yes(args.suffix2)) then
		local threshold = tonumber(args.threshold)
		local swap = false
		if yes(issue) and tonumber(issue) ~= nil and tonumber(issue) <= threshold then
			swap = true
		elseif yes(issue1) and tonumber(issue1) ~= nil and tonumber(issue1) <= threshold then
			swap = true
		end
		if swap then
			if yes(args.series2) then
				series = args.series2
			end
			if yes(args.suffix2) then
				suffix = ' ' .. args.suffix2
				if yes(args.showsuffix) then
					ss = ' ' .. args.suffix2
				end
			end
			if yes(args.image2) then
				image = args.image2
			end
		end
	end
	
	if args.mode == "ref" and yes(issue) and yes(args.lookupIssue) then
		local target = buildName(series, issue .. suffix)
		if series == "Star Wars Starships & Vehicles" and issue == "S1" then
			target = "Star Wars Starships & Vehicles: Death Star II"
		elseif series == "Star Wars Starships & Vehicles" and issue == "S2" then
			target = "Star Wars Starships & Vehicles: Starkiller Base"
		end
		local issueText = lookUpFormattedText("Issue", args, args.lookupIssueType, '', false)
		if yes(issueText) then
			return image, target, string.format("[[%s|%s]]", target, issueText)
		end
	end
	
	if noIssueLink and yes(issue1) and yes(issue2) then
		return image, series, buildIssue(series, stext, issue1 .. '–' .. issue2, suffix, ss, italics, noIssueLink)
	elseif yes(issue1) and yes(issue2) then 
		local i1 = buildIssue(series, stext, issue1, suffix, ss, italics, noIssueLink)
		local i2 = string.format("[[%s %s%s|%s]]", series, issue2, suffix, issue2)
		return image, buildName(series, issue1 .. suffix), string.format("%s–%s", i1, i2)
	elseif yes(issue1) then
		return image, buildName(series, issue1 .. suffix), buildIssue(series, stext, issue1, suffix, ss, italics, noIssueLink) .. makeCategoryLink('BaseCitation usages with invalid issue parameters')
	elseif yes(issue) then
		return image, buildName(series, issue .. suffix), buildIssue(series, stext, issue, suffix, ss, italics, noIssueLink)
	elseif yes(stext) and stext:find("''") then
		return image, series, string.format("[[%s|%s]]", series, stext)
	elseif yes(stext) then
		return image, series, string.format("%s[[%s|%s]]%s", italics, series, stext, italics)
	else
		return image, series, string.format("%s[[%s|%s]]%s", italics, series, hideParenthetical(series), italics)
	end
end

function prepareChild(args) 
	local child = args.child
	if child ~= nil and child ~= "" and args.parentheses then
        for k in args.parentheses:gmatch('[^%,]+') do
            if k:find(' %(') and string.lower(child) == string.lower(k:sub(0, k:find(' %(') - 1)) then
            	return k
            end
	    end
	end
	return child
end

function lookUpFormattedText(target, args, lookupType, textValue, combine, combine)
	if lookupType ~= nil and lookupType ~= "" then
		local render = require('Module:FormattedTextLookup').render
		return render({type = lookupType or '', template = args.template,
			issue = args.issue, target = target, text = textValue,
			combine = args.lookupCombine, textOnly = 'yes'})
	end
	return ""
end


function buildChild(args, small)
	if isMissing(args.child) and args.mode == "ref" and yes(args.parentMode) then
		return "", ""
	elseif isMissing(args.child) and isCurrentPageMainSpaceOrFile() then
		return "", '<strong class="error">Missing child parameters, cannot construct child link</strong>' .. makeCategoryLink("BaseCitation usages with invalid child parameters")
	elseif isMissing(args.child) then
		return "", '"[[{{{child|}}}]]"'
	end
	
	if args.template == "EncyclopediaCite" then
		local book = args.child:gsub(" %(..+%)$", "")
		if book == "Millennium Falcon" then
			return book .. ' (reference book)', string.format('"[[Millennium Falcon (reference book)|%s]]"', "''Millennium Falcon''")
		elseif hasValue(ENCYCLOPEDIA, book) then
			return book .. ' (reference book)', string.format('"[[%s (reference book)|%s]]"', book, book)
		else
			return book, string.format('"[[%s]]"', book, book)
		end
	end
	
	local child = prepareChild(args)
	if child == "Bantha Tracks (newsletter)" or child == "Bantha Tracks (department)" or child == "Bantha Tracks" then
		return child, "[[Bantha Tracks (department)|''Bantha Tracks'']]"
	elseif args.template == "InsiderCite" and hasValue(DEPARTMENTS, child) then
		child = child .. ' (department)'
	end
	
	local ctext = args.ctext
	if args.lookupText then
		ctext = lookUpFormattedText(args.child, args, args.lookupType, args.lookupTextValue, args.lookupCombine)
		if not ctext and args.child ~= child then
			ctext = lookUpFormattedText(child, args, args.lookupType, args.lookupTextValue, args.lookupCombine)
		end
		if not ctext then
			ctext = args.ctext
		end
	end
	local textCat = ''
	if ctext and ctext:find("%[%[Category:") then
		local z = ctext:find("%[%[Category:")
		textCat = ctext:sub(z)
		ctext = ctext:sub(0, z - 1)
	end
	local quote = '"'
	if yes(args.noquotes) or small then
		quote = ''
	elseif string.lower(child:sub(0, 8)) == "untitled" then
		quote = ''
	end
	
	if yes(args.nolink) then
		return child, string.format("%s%s%s", quote, hideParenthetical(yes(ctext) and ctext or child), quote) .. compare(ctext, hideParenthetical(child), false) .. textCat
	elseif yes(ctext) then
		return child, string.format("%s[[%s|%s]]%s", quote, child, ctext, quote) .. compare(ctext, hideParenthetical(child), false) .. textCat
	elseif child:find('%(1%)') or child:find('%(2%)') then
		return child, string.format("%s[[%s|%s]]%s", quote, child, child, quote) .. textCat
	else
		return child, string.format("%s[[%s|%s]]%s", quote, child, hideParenthetical(child), quote) .. textCat
	end
end

local function addHideSpan(s)
	return '<span class="pnh">' .. s .. '</span>'
end

function p.citation(args)
	local spacing, dash, parentFirst = ' ', '&mdash;', false
	local small = false
	local mode = string.lower(args.mode or '')
	if mode == "tv" then
		parentFirst = true
	elseif mode == "magazine" then
		parentFirst = false
	elseif mode == "ref" then
		parentFirst = true
		small = true
	else
		if yes(args.nospaces) then
			spacing = ''
		end
		dash = yes(args.ndash) and '&ndash;' or '&mdash;'
		parentFirst = yes(args.parentfirst)
	end
	small = small or yes(args.small)
	
	local image, parent, parentText = buildParent(args)
	local child, childText = buildChild(args, small)
	
	local imageText= ''
	if yes(image) and small and yes(args.child) then
		imageText = image..' '
	elseif yes(image) then
		imageText = string.format('<span class="mhi %s">%s</span> ', yes(args.invert) and "invert-images" or '', image)
	end
	
	local text = ''
	if yes(args.parentMode) then
		text = imageText .. parentText
	elseif small and yes(args.child) then
		--text = string.format('%s <small class="cgct">%s%s%s</small>', addHideSpan(image..' '..parentText), addHideSpan('('), childText, addHideSpan(')'))
		text = string.format('%s <small class="cgct">%s</small>', addHideSpan(imageText..parentText), childText)
	elseif parentFirst then
		text = string.format("%s%s%s%s%s%s", imageText, parentText, spacing, dash, spacing, childText)
	else
		text = string.format("%s%s%s%s%s%s", imageText, childText, spacing, dash, spacing, parentText)
	end
	if mode == 'magazine' and yes(parent) and yes(child) and parent == child then
		text = text .. makeCategoryLink("Magazine citations using issue as article parameter")
	end
	
	text = text .. isOtherSeries(args)
	
	if yes(args.audiobook) and yes(parent) then
		text = text .. ' ' .. buildAudiobook(args.audiobook, parent)
	end
	if yes(args.reprint) then
		local buildReprint = require('Module:Reprint').buildReprint
		local rt = buildReprint(yes(args.reprintParent) and parent or child, args.issue, false, args.abbr)
		if yes(rt) then
			text = text .. ' ' .. rt
		end
	end
	return text
end

function p.main(frame)
	return p.citation(frame.args)
end

return p