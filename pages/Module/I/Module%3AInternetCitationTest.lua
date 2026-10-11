local p = {}

local currentTitle = mw.title.getCurrentTitle()

local LANGUAGES = {
	["ar"] = "Argentinian",
	["au"] = "Australia",
	["be"] = "Belgian",
	["bg"] = "Bulgarian",
	["br"] = "Brazil",
	["cz"] = "Czech",
	["de"] = "German",
	["es"] = "Spain",
	["fr"] = "French",
	["gr"] = "Greek",
	["it"] = "Italian",
	["jp"] = "Japanese",
	["mx"] = "Mexico",
	["pl"] = "Polish",
	["pt"] = "Portugal",
	["sk"] = "Slovakian",
	["uk"] = "United Kingdom",
	["us"] = "United States",
}

function findLanguage(value)
	local key = value:gsub("com?[%.%/]", "")
	if LANGUAGES[key] ~= nil then
		return LANGUAGES[key]
	elseif LANGUAGES[key:gsub("/.+$", "")] then
		return LANGUAGES[key:gsub("/.+$", "")]
	end
	return nil
end

function yes(s)
	return s ~= nil and s ~= '' and s ~= false
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

local function addHideSpan(s)
	return '<span class="pnh">' .. s .. '</span>'
end

local function makeDateLink(date)
	if not yes(date) then
		return ''
	end
	
	lang = lang or mw.language.getContentLanguage()
	local success, dateLink
	if date and #date == 7 then 
		-- YYYY-MM
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[F]], [[Y]]',
			date .. '-01'
		)
	elseif date and #date == 4 then
		-- YYYY
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[Y]]',
			date .. '-01-01'
		)
	else
		-- YYYY-MM-DD
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[F j]], [[Y]]',
			date
		)
	end
	return dateLink
end

local function makeCategoryLink(cat)
	if currentTitle.fullText == "Wookieepedia:Templates/Sources" then
		return ''
	end
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s|%s]]', 'Category', cat, currentTitle.text)
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

local function substitute(text, name, value, addSpace)
	if yes(value) and value:find('%%') then
		local a, b = text:find(name)
		if a ~= nil then
			text = text:sub(0, a - 1)..value..text:sub(b + 1)
		end
	elseif yes(value) and addSpace then
		return text:gsub(name, ' '..value)
	end
	return text:gsub(name, value or '')
end

local function cleanUrl(u)
	return (u or ''):gsub('//', '/'):gsub('(https?:)//?', '%1//'):gsub('/$', '')
end

local function combineUrls(baseUrl, path)
	if not yes(baseUrl) then
		return path
	elseif not yes(path) then
		return baseUrl
	elseif baseUrl:sub(-1) == "/" or baseUrl:sub(-1) == "=" or baseUrl:sub(-1) == "@" or baseUrl:sub(-1) == "?" then
		return cleanUrl(baseUrl..path)
	else
		return cleanUrl(baseUrl..'/'..path)
	end
end

local function buildUrls(args)
	local targetUrl = cleanUrl(args.target_url)
	if yes(args.full_url) then
		local full = cleanUrl(args.full_url)
		return full, nil, targetUrl or full
	else
		local baseUrl = cleanUrl(args.base_url)
		if yes(baseUrl) then
			if yes(targetUrl) then
				return combineUrls(baseUrl, targetUrl), baseUrl, targetUrl
			elseif yes(args.blog) and yes(args.username) then
				return baseUrl, baseUrl, args.username	-- edge case for ArtStation/Blogspot/Tumblr homepages
			elseif yes(args.no_archive) and yes(args.no_profile) then
				return baseUrl, baseUrl, args.subdomain or baseUrl
			end
		end
		return '<strong class="error">error: no full-URL provided.</strong>', nil, targetUrl
	end
end

local function addBackup(template, fullUrl, lookupKey, noLive, args)
    if link == 'no-link' then
        return {}
    elseif yes(args.nobackup) and not yes(args.archivefile) and noLive then
        return {disclaimer = 'content obsolete and backup link not available'}
    elseif yes(args.nobackup) and not yes(args.archivefile) then
        return {disclaimer = 'backup link not available'}
    elseif currentTitle.fullText == "User:Hk 47/WiP3" then
    	return {}
    end
    
    local pt = args.social_media and "Social media citations" or 'Pages'
    local isProfile = yes(args.is_profile)
    if (args.social_media or args.blog) and not yes(args.is_post) then
		isProfile = true
	end
    
	local buildArchivePieces = require('Module:ArchiveAccess').buildBackupLinkPieces
	local archive = buildArchivePieces({
		template_name = template, 
		full_url = fullUrl,
		target = lookupKey, 
		simple = yes(args.int) and noLive,
		archiveurl = args.archiveurl or '',
		archivedate = args.archivedate or '',
		archivefile = args.archivefile or '',
		archivefile2 = args.archivefile2 or '',
		archivefile3 = args.archivefile3 or '',
		archivefile4 = args.archivefile4 or '',
		archivefile5 = args.archivefile5 or '',
		oldversion = args.oldversion or '',
		citation_type = pt,
		use_lua_subpage = args.use_lua_subpage,
		backup_optional = args.backup_optional,
		is_profile = isProfile,
		optional = args.optional,
		no_archive = args.no_archive,
		nobackup = args.nobackup or '',
		nolive = noLive,
	})
	if archive ~= nil then
		return archive
	elseif args.optional then
		return {}
	elseif currentTitle.namespace == 0 or currentTitle.namespace == 6 then
        return {disclaimer = makeCategoryLink(pt..'with missing permanent archival links')}
    end
	return {}
end

local function addSiteBackup(template, baseUrl, targetUrl) 
	local buildArchive = require('Module:ArchiveAccess').buildBackupLinkPieces
	local archive = buildArchive({
		template_name = template, 
		full_url = baseUrl..'/'..targetUrl,
		target = targetUrl, 
		use_lua_subpage = 1
	})
	if archive ~= nil then
		return archive
	elseif currentTitle.namespace == 0 or currentTitle.namespace == 6 then
        return {disclaimer = makeCategoryLink('Pages with missing permanent archival links/'..template)}
    end
	return {}
end

local function addSwBackup(template, url)
	return addSiteBackup("SW", "https://www.starwars.com", url)
end

function buildLinkAndBackupTextFormat(backup, int, oldVersion, noLive)
	if yes(backup.file) and not yes(backup.link) then -- backup files don't display backup links
		if yes(int) and oldVersion then
			return "[[<INT>|<TEXT>]]", "<small>(<FILE>; content not present on [<FULL_URL> current version])</small>"
		elseif yes(int) then
			return "[[<INT>|<TEXT>]]", "<small>([<FULL_URL> article]) (<DISCLAIMER>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", "<small>(<FILE>) (<DISCLAIMER>)</small>"
		end

	elseif oldVersion then	-- if old version, prioritize displaying the backup link (if exists)
		if yes(int) and yes(backup.link) then
			return "[[<INT>|<TEXT>]]", "<small>([<BACKUP_LINK> backup link]<WARNING>; content not present on [<FULL_URL> current version]) (<FILE>)</small>"
		elseif yes(backup.link) then
			return "[<BACKUP_LINK> <TEXT>]<WARNING>", "<small>(content not present on [<FULL_URL> current version]) (<FILE>)</small>"
		elseif yes(int) then
			return "[[<INT>|<TEXT>]]", "<small>(content not present on [<FULL_URL> current version]<WARNING>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", "<small>(<DISCLAIMER><WARNING>) (<FILE>)</small>"
		end
		
	elseif noLive and yes(backup.link) then -- if no longer live, prioritize displaying the backup link
		if yes(int) then
			return "[[<INT>|<TEXT>]]", "<small>(<HIGHLIGHT>[<BACKUP_LINK> backup link]<HIGHLIGHT><WARNING>) ([<FULL_URL> original <SITE_OR_LINK>] is <OBSOLETE>) (<FILE>)</small>"
		else
			return "[<BACKUP_LINK> <TEXT>]<WARNING>", "<small>(<HIGHLIGHT>[<FULL_URL> original <SITE_OR_LINK>]<HIGHLIGHT> is <OBSOLETE>) (<FILE>)</small>"
		end
	
	elseif yes(int) then -- all other int= cases
		if yes(backup.link) then
			return "[[<INT>|<TEXT>]]", "<small>([<FULL_URL> article]) (<HIGHLIGHT>[<BACKUP_LINK> backup link]<HIGHLIGHT><WARNING>) (<FILE>)</small>"
		elseif yes(backup.disclaimer) then
			return "[[<INT>|<TEXT>]]", "<small>([<FULL_URL> article]) (<DISCLAIMER>) (<FILE>)</small>"
		else
			return "[[<INT>|<TEXT>]]", "<small>([<FULL_URL> article]) (<FILE>)</small>"
		end
		
	else -- all other cases
		if yes(backup.link) then
			return "[<FULL_URL> <TEXT>]", "<small>(<HIGHLIGHT>[<BACKUP_LINK> backup link]<HIGHLIGHT><WARNING>) (<FILE>)</small>"
		elseif yes(backup.disclaimer) then
			return "[<FULL_URL> <TEXT>]", "<small>(<DISCLAIMER>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", ""
		end
	end
end

function buildMainText(linkText, backupText, parentLink, siteText, authorText, separator, args)
	local baseText
	if args.social_media and yes(args.is_post) and yes(args.text) then	-- posts w/ title get different format
		baseText = string.format("%s (%s) on %s: %s (<DATE>)", authorText, parentLink, siteText, linkText)
	elseif args.social_media and yes(args.is_post) then
		baseText = string.format("%s (%s) on %s (%s on <DATE>)", authorText, parentLink, siteText, linkText)
	elseif args.social_media then	-- no post URL = link/backup points to profile
		baseText = string.format("%s (%s) on %s (<DATE>)", authorText, linkText, siteText)
	elseif args.blog and yes(args.is_post) and yes(args.text) then
		baseText = string.format("%s &mdash; %s on %s (<DATE>)", parentLink, linkText, siteText)
	elseif args.blog then	-- no post URL = link/backup points to profile
		baseText = string.format("%s on %s (<DATE>)", linkText, siteText)
	elseif args.site_first then
		baseText = string.format("%s %s%s (<DATE>)", siteText, linkText, authorText)
	else
		baseText = string.format("%s%s %s %s (<DATE>)", linkText, authorText, separator, siteText)
	end
	if args.template == "Twitch" then
		baseText = baseText:gsub(" ?%((.*)%) on ", "%1's channel on ")
	end
	if yes(args.quote) then
		baseText = baseText..': <small>"'..args.quote..'"</small>'
	end
	if yes(backupText) then
		return baseText..' '..backupText
	end
	return baseText
end

function buildSite(args)
	if yes(args.company) and yes(args.site_url) and yes(args.site_description) then
		return string.format("%s{{'s}} [%s %s]", args.company, args.site_url, args.site_description)
	elseif yes(args.company) and yes(args.site_url) then
		-- TODO: language
		return string.format("%s{{'s}} [%s official website]", args.company, args.site_url, args.site_description)
	elseif yes(args.site_text) then
		return args.site_text
	else
		return makeWikitextError(args.template, 'No site text defined for this template')
	end
end

function addLanguage(siteText, args)
	local language = ''
	if args.lang then
		language = findLanguage(args.lang)
	elseif args.domain then
		language = findLanguage(args.domain)
	end
	if yes(language) then
		return siteText:gsub('official website', 'official '..language..' website')
	end
	return siteText
end

local function decideParentName(args, template, parentName)
	if yes(parentName) and template == "Facebook" and parentName:find('-[0-9][0-9][0-9][0-9][0-9][0-9]') then 
		return 'profile'	-- hiding non-dedicated FB links
	elseif yes(parentName) and (args.exclude_at_symbol or args.blog or parentName:sub(0, 1) == '@') then
		return parentName
	elseif yes(parentName) then
		return '@'..parentName
	elseif yes(args.username) and (args.exclude_at_symbol or args.blog or args.username:sub(0, 1) == '@') then
		return args.username
	elseif yes(args.username) then
		return '@'..args.username
	else
		return 'profile'
	end
end

local function buildParentLinkAndText(args, template, baseUrl)
	local parentUrl, parentName = '', ''
	if yes(args.social_media) and not yes(args.no_profile) then
		parentName = args.usertext or (args.username or '')
		parentUrl = yes(args.username) and combineUrls(args.base_url, args.username) or ''
	elseif yes(args.blog) and not yes(args.no_profile) then
		parentName = args.usertext or '{{{usertext}}}'
		parentUrl = baseUrl
	else
		return '', args.text or '<strong class="error">error: no text provided.</strong>'
	end
		
	parentName = decideParentName(args, template, parentName)
	local parentLink = yes(parentUrl) and '['..parentUrl..' '..parentName..']' or ''
	-- use post title if given, otherwise display 'post', 'profile' or the profile/user name
	if yes(args.text) then
		return parentLink, args.text
	elseif yes(args.is_post) then
		return parentLink, args.post_type or 'post'
	else
		return parentLink, parentName or '<strong class="error">error: no text provided.</strong>'
	end
end

function p.citation(args)
	local template = args.template
	local fullUrl, baseUrl, urlParamOrLookupKey = buildUrls(args)
	local parentLink, text = buildParentLinkAndText(args, template, baseUrl)
	local int = args.int or ''
	local separator = args.separator ~= nil and args.separator or 'on'
	local noBackup = yes(args.nobackup)
	local oldVersion = yes(args.oldversion)
	local noLive = yes(args.defunct_site) or yes(args.nolive)
	
	-- adjust parameters as necessary
	if fullUrl:find('youtube.com/playlist=') then
		separator = 'playlist on'
	end
	local dateText = makeDateLink(args.date)
	if yes(dateText) and yes(args.time) then
		dateText = dateText:gsub('%)', ' at '..args.time..')')
	end
	local authorText = ''
	if yes(args.author) and yes(args.social_media) then
		authorText = args.author
	elseif yes(args.author_text) then
		authorText = ' '..args.author_text
	elseif yes(args.author) then
		authorText = ' by '..args.author
	end
	
	local siteText = addLanguage(buildSite(args), args)
	local backupData = addBackup(template, fullUrl, urlParamOrLookupKey, noLive, args)
	local linkText, backupText = buildLinkAndBackupTextFormat(backupData, int, oldVersion, noLive)
	local mainText = buildMainText(linkText, backupText, parentLink, siteText, authorText, separator, args)
	
	-- replace <variables> in the link & backup with appropriate values
	mainText = substitute(mainText, '<INT>', int, false)
	mainText = substitute(mainText, '<TEXT>', text, false)
	mainText = substitute(mainText, '<DATE>', dateText, false)
	mainText = substitute(mainText, ' ?<FULL_URL>', fullUrl, false)
	mainText = substitute(mainText, ' ?<BACKUP_LINK>', backupData.link, false)
	mainText = substitute(mainText, '<FILE>', backupData.file, false)
	mainText = substitute(mainText, '<DISCLAIMER>', backupData.disclaimer, false)
	mainText = substitute(mainText, '<WARNING>', backupData.warning, true)
	mainText = mainText:gsub('<HIGHLIGHT>', backupData.highlight or '')
	mainText = mainText:gsub('<OBSOLETE>', args.defunct_site and 'defunct' or 'obsolete')
	mainText = mainText:gsub('<SITE_OR_LINK>', args.defunct_site and 'site' or 'link')
	if yes(backupData.categories) then
		mainText = mainText..backupData.categories
	end
	
	-- cleanup
	mainText = mainText:gsub(" ?%(%)", ""):gsub('@profile', 'profile'):gsub(" on %)", ")")
	
	if yes(args.series) then
		mainText = args.series..' '..mainText
	end
	
	local otherBackup = {}
	local siteName = args.site_name or '{{{site_name}}}'
	if yes(args.sw_url) then
		siteName = 'StarWars.com'
		otherBackup = addSwBackup("SW", args.sw_url)
		if yes(otherBackup.warning) then
			local otherBackup2 = addSwBackup("SWArchive", args.sw_url)
			if yes(otherBackup2.link) and not yes(otherBackup2.warning) then
				otherBackup = otherBackup2
			end
		end
	elseif yes(args.site_url) then
		otherBackup = addSiteBackup(args.site_template, args.site_base_url, args.site_url)
	end
	if yes(otherBackup.link) then
		mainText = mainText..' <small>(['..otherBackup.link..' Posted on '..siteName..']'..(otherBackup.warning or '')..')</small>'..(otherBackup.disclaimer or '')
	end
	if yes(args.image) then
		mainText = args.image..'&#32;'..mainText
	end

	return buildAndValidate(mainText, args, urlParamOrLookupKey, fullUrl)
end

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local function includesBaseUrl(url, base)
	return yes(base) and url:find(base:gsub('^.*//w*\.?', ''))
end

function buildAndValidate(mainText, args, urlParamOrLookupKey, baseUrl, fullUrl)
	local ret = {}
	ret[#ret + 1] = string.format('<span class="plainlinks mobile-template-image">%s</span>', mainText)
	if args.unnamed and not args.allow_unnamed then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with positional parameters")..'§'
	elseif args.unnamed and args.allow_unnamed == '2' then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with legacy positional parameters")..'·'
	elseif urlParamOrLookupKey ~= nil then
		if urlParamOrLookupKey:find('=http') then
			-- do nothing
		elseif yes(args.full_url) and urlParamOrLookupKey == args.full_url then
			-- do nothing
		elseif yes(args.subdomain) and urlParamOrLookupKey == args.subdomain then
			-- do nothing
		elseif urlParamOrLookupKey:find('http:') or urlParamOrLookupKey:find('https:') then
			ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL parameters")..'§'
		elseif includesBaseUrl(urlParamOrLookupKey, baseUrl) then
			ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL parameters")..'§'
		end
	else
		ret[#ret + 1] = makeCategoryLink("Web citation template usages without URL parameter")
	end
	
	if args.social_media and not yes(args.username) and not yes(args.no_profile) then
		if currentTitle.namespace == 0 or currentTitle.namespace == 6 then
			ret[#ret + 1] = makeCategoryLink("Citation template usages without profile/"..args.template)
		end
	end
	if yes(args.text) or yes(args.social_media) or yes(args.is_profile) or (yes(args.blog) and not yes(args.is_post)) then
		-- do nothing
	else
		ret[#ret + 1] = makeCategoryLink("Web citation template usages without text parameter")
	end
	if args.domain_not_allowed and yes(args.domain) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL domain parameter")..'§'
	end
	
	if yes(args.archivefile) and not exists(args.archivefile) then
		ret[#ret + 1] = makeCategoryLink("Citation template usages with broken file links|"..args.template)..'§'
	end
	
	if currentTitle.namespace == 10 and not currentTitle.fullText:find('/doc') and currentTitle.fullText:find(args.template) then
		if args.full_url ~= nil then
			ret[#ret + 1] = makeCategoryLink('Citation templates using full URL parameter')
		end
		if args.use_lua_subpage then
			-- do nothing
		elseif args.no_archive then
			ret[#ret + 1] = makeCategoryLink("Citation templates without archive subpages")
		else
			ret[#ret + 1] = makeCategoryLink("Citation templates that do not use their Lua subpage")
		end
	end
	return table.concat(ret)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' and k ~= "int" then
			args[k] = v
		end
		if type(k) == "number" then
			args.unnamed = true
		end
	end

	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.citation(args)
end

return p