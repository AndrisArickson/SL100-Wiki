-- This module implements [[Template:HBCite]].

local p = {}
local NS_MODULE = 828
local title = mw.title.getCurrentTitle()

function yes(s)
	return s ~= nil and s ~= ''
end

function isMissing(s)
	return s == nil or s == ''
end

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s|%s]]', 'Category', cat, title.text)
end

-- isCurrentPageMainSpaceOrFile determines whether the page being parsed is a mainspace or file page.
local function isCurrentPageMainSpaceOrFile()
	return title.namespace == NS_MAIN or title.namespace == NS_FILE or title.namespace == NS_MODULE or string.find(title.fullText, 'Wookieepedia:Sources') or string.find(title.fullText, 'Wookieepedia:Appearances')
end

local function hideParenthetical(set)
	local stop = set:find('%s*%(')
    return stop and set:sub(1, stop - 1) or set
end

function buildIssue(s, f, i, x, y, italics)
	if isMissing(s) or isMissing(i) then
		return '<strong class="error">Missing series/issue parameters, cannot construct parent</strong>' .. makeCategoryLink("BaseCitation usage issues")
	elseif yes(f) then
		return string.format("[[%s %s%s|%s %s%s]]", s, i, x, f, i, y)
	else
		return string.format("[[%s %s%s|%s%s%s %s%s]]", s, i, x, italics, hideParenthetical(s), italics, i, y)
	end
end

function buildName(s, i)
	return string.format('%s %s', s, i)
end

REMAP = {
	["Star Wars: Legacy Collection"] = "[[Star Wars: The Legacy Collection|''Star Wars: Legacy Collection'']]",
	["Star Wars: The Power of the Force (1985 toy line)"] = "[[Star Wars: The Power of the Force (1985 toy line)|''Star Wars: The Power of the Force'' (1985)]]",
	["Star Wars: The Power of the Force (1995 toy line)"] = "[[Star Wars: The Power of the Force (1995 toy line)|''Star Wars: The Power of the Force'' (1995)]]",
	["Star Wars (Hasbro toy line)"] = "[[Star Wars (Hasbro toy line)|Hasbro's ''Star Wars'' toy line]]",
	["Star Wars (Kenner toy line)"] = "[[Star Wars (Kenner toy line)|Kenner's ''Star Wars'' toy line]]",
}

function buildParent(args)
	local set = args.set
	if isMissing(set) and isCurrentPageMainSpaceOrFile() then
		return '<strong class="error">Missing set parameters, cannot construct parent</strong>' .. makeCategoryLink("ToyCitation usage issues")
	elseif isMissing(set) then
		return '[[{{{set}}}]]'
	end
	
	local italics = "''"
	if yes(args.noitalics) then
		italics = ''
	end
	if yes(args.stext) then
		return string.format("[[%s|%s]]", set:gsub('Star Wars: Legacy Collection', 'Star Wars: The Legacy Collection'), args.stext)
	elseif set:find('%(toy line%)') and italics ~= "" then
		return string.format("[[%s|''%s'' toy line]]", set, hideParenthetical(set))
	elseif REMAP[set] ~= nil then
		return REMAP[set]
	else
		return string.format('%s[[%s|%s]]%s', italics, set, hideParenthetical(set), italics)
	end
end

function buildChild(args, url)
	if yes(args.parent) then
		return ""
	elseif yes(args.itemlink) and yes(args.itext) then
		return string.format('[[%s|%s]]', args.itemlink, args.itext)
	elseif yes(args.itemlink) then
		return string.format('[[%s|%s]]', args.itemlink, hideParenthetical(args.itemlink))
	elseif isMissing(args.pack) and isCurrentPageMainSpaceOrFile() then
		return '<strong class="error">Missing child parameters, cannot construct child link</strong>' .. makeCategoryLink("ToyCitation usage issues")
	elseif isMissing(args.pack) then
		return '{{{pack|}}}'
	end
	
	local pack = args.pack
	if yes(url) and isMissing(args.nobackup) then
		pack = string.format('[%s %s]', url, pack)
	end
	
	if yes(args.nopacktype) then
		return pack
	elseif yes(args.packtype) then
		return string.format("%s: %s", args.packtype, pack)
	else
		return 'Pack: ' .. pack
	end
end

local buildArchive = require('Module:ArchiveAccess').render

local function determineUrl(args)
	if yes(args.url) then
		return args.url, args.url
	elseif yes(args.link) and args.link:sub(0, 1) ~= '/' then
		return args.link, args.baseUrl .. '/' .. args.link
	elseif yes(args.link) then
		return args.link, args.baseUrl .. args.link
	end
	return '', ''
end

local function buildBackup(target, fullUrl, args)
	return buildArchive({
		template_name = args.template, target = target, full_url = fullUrl,
		par = "1", use_lua_subpage = "1", shared_site = args.sharedSite,
		archiveurl = args.archiveurl, archivedate = args.archivedate,
		archivefile = args.archivefile, nobackup = args.nobackup,
		nolive = args.nolive
	})
end

function p.citation(args)
	local image = args.image
	local target, fullUrl = determineUrl(args)
	
	local parentText = buildParent(args)
	local childText = buildChild(args, fullUrl)
	
	local backup = ''
	if yes(fullUrl) and isMissing(args.skipArchive) then
		local arc = buildBackup(target, fullUrl, args)
		if yes(arc) then
			backup = ' ' .. arc:gsub('/web//', '/web/')
		end
	end
	local text = ""
	if yes(args.parent) then
		text = string.format('<span class="plainlinks">%s</span>', parentText)	
	else
		text = string.format('<span class="plainlinks">%s <small>(%s)%s</small></span>', parentText, childText, backup)
	end
	if yes(args.link) and args.link:find('http') then
		text = text .. makeCategoryLink('Web citation template usages with invalid URL parameters') .. ' §'
	end
	
	if yes(image) and yes(args.invert) then
		text = string.format('<span class="invert-images">%s</span> %s', image, text)
	elseif yes(image) then
		text = string.format("%s %s", image, text)
	end
	return text
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	for k, v in pairs(frame.args) do
		args[k] = v
	end
	return p.citation(args)
end

return p