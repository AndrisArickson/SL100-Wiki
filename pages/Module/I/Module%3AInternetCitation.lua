local p = {}

local currentTitle = mw.title.getCurrentTitle()

local defunctUsernames = {
	["Twitter"] = {"pabl0hidalgo", "ZyngaStarWars"}
}
local tooBig = {"Anakin Skywalker", "Editoronthewiki/Workbench"}
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

local CHANNELS = {
	"fornite", "epicfortnite", "fantasyflightgames1", "fantasyflightgames", "eastarwars", "ubisoft", "disney", "disneyplus", "disneyxd", "starwarsgalacticracer"
}
local BOARDS = {"SWBoards", "DHBoards", "JCFCite", "Substack", "Getty", "GameSpot", "YouTube", "Reddit"}
local OFFICIAL = {
	"angrybirds", "aspyrmedia", "atomicmassgames", "bbc", "blurstudioinc", "collectsideshow", "comicbook", "comiccon", "darkhorsecomics", "disneychannel", "disneygames", "disneyjunior", "disneymusic", "disneymusicvevo", "disneyparks", "disneyxduk", "entertainmenttonight", "gameloft", "entertainmentweekly", "fallontonight", "hasbropulse", "ign", "jimmykimmellive", "kabamrpg", "legostarwarsgame", "lucasfilm", "modelspaceusa", "nintendoamerica", "oyme92ftfe1ycjped1w", "penguinrandomhouse", "playstation", "rachaelrayshow", "rebelforceradio", "rebellegionofficial", "rovioentertainment", "toysrusuk", "uca4lpqzo0fjn0--iezve1uw", "ucbrf5hshlcjnfan17ihiciq", "ucbtechmwyv8ro1ekhbaxewg", "uccgpau7kcgadweckv_ofcyw", "ucdf1rhyrh8lcxbhx5_mrz0w", "ucgrqhk8ttr1j9xcepcalgbq", "uch1ory1dinbmvp3ufwrkp0w", "uchkbmo2s_nounshfrtf5udq", "uchqaojd1bj-pvtpck8qdfmq", "ucirslk1qpjmw5vfcq9-mw4w", "ucj0uqci0vqr2rrt1hsegirg", "uclnruybpqp5n48ek-f45btq", "uclsfjmfdck0wav_0arr--0q", "uclwcqnaggkmw7sdts3bkebg", "ucqfzwxsci39lnw1jkfr3efg", "ucr79jjpuptzfwr7477t0mog", "uctagbu2l6_rbkdbtveodedw", "ucttkrdbu5zbaqaj1tiozizq", "ucvneq_xhmbjalh0ql4zpqca", "ucvs9ta3pi8gard_lrtx0ysq", "ucwkubn7fowu9gcy5cfmso-q", "uc_baxrhnrei_v0dvxjxdala", "vanityfair", "variety", "volkswagen", "vw", "wired", "yahooentertainment", "zenstudios", 
}

local CUSTOM = {
	["Characters of Star Wars: The High Republic"] = "[[Characters of Star Wars: The High Republic|Characters of ''Star Wars: The High Republic'']]:",
	["Let's Draw Star Wars"] = "Let's Draw ''Star Wars'':",
	["On Location"] = "[[on location]]",
	["Dispatches from the Halcyon"] = "[[Dispatches from the Halcyon|Dispatches from the ''Halcyon'']]:",
	["The New Yoda Chronicles"] = "[[LEGO Star Wars: The Yoda Chronicles|''The New Yoda Chronicles'']]: ",
	["Star Wars: Visions Filmmaker Focus"] = "[[Star Wars: Visions Filmmaker Focus|''Star Wars: Visions'' Filmmaker Focus]]",
	["So Uncivilized: Great Gunslingers in Star Wars"] = "[[So Uncivilized: Great Gunslingers in Star Wars|So Uncivilized: Great Gunslingers in ''Star Wars'']]",
	["Star Wars: The Essential Guide to Warfare Author's Cut"] = "[[Star Wars: The Essential Guide to Warfare Author's Cut|''Star Wars: The Essential Guide to Warfare'' Author's Cut]],",
	["Sports in the Star Wars Galaxy"] = "[[Sports in the Star Wars Galaxy|Sports in the ''Star Wars'' Galaxy]]",
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
	return s ~= nil and s ~= '' and s ~= ' ' and s ~= false
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

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local function includesBaseUrl(url, base)
	return yes(base) and url:find(base:gsub('^.*//w*%.?', ''))
end

local function makeDateLink(date)
	if not yes(date) then
		return '', false
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
	return dateLink, not success
end

local function makeDateText(date)
	if not yes(date) then
		return ''
	end
	
	lang = lang or mw.language.getContentLanguage()
	local success, dateLink
	if date and #date == 7 then 
		success, dateLink = pcall(lang.formatDate, lang, 'F, Y', date .. '-01')
	elseif date and #date == 4 then
		success, dateLink = pcall(lang.formatDate, lang, 'Y', date .. '-01-01')
	else
		success, dateLink = pcall(lang.formatDate, lang, 'F j, Y', date)
	end
	return success and dateLink or ""
end

-- "Category" is split out here so that the module isn't put into the
-- category "%s" when the page is saved.
local function makeCategoryLink(cat)
	if currentTitle.fullText == "Wookieepedia:Templates/Sources" then
		return ''
	elseif currentTitle.namespace == 2 then
		return string.format('[[%s:%s|%s]]', 'Category', cat, '*'..currentTitle.text)
	else
		return string.format('[[%s:%s|%s]]', 'Category', cat, currentTitle.text)
	end
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

local function buildUrls(target_url, base_url, full_url, subdomain, no_archive, no_profile)
	local targetUrl = cleanUrl(target_url)
	if yes(full_url) and yes(base_url) then
		local full = cleanUrl(full_url)
		return full, cleanUrl(base_url), targetUrl or full
	elseif yes(full_url) then
		local full = cleanUrl(full_url)
		return full, nil, targetUrl or full
	else
		local baseUrl = cleanUrl(base_url)
		if yes(baseUrl) then
			if yes(targetUrl) and yes(subdomain) and subdomain == targetUrl then
				return baseUrl, baseUrl, targetUrl
			elseif yes(targetUrl) then
				return combineUrls(baseUrl, targetUrl), baseUrl, targetUrl
			elseif yes(target_url) and target_url == '/' then
				return baseUrl, baseUrl, '/'
			elseif yes(no_archive) and yes(no_profile) then
				return baseUrl, baseUrl, subdomain or baseUrl
			end
		end
		return '<strong class="error">error: no full-URL provided.</strong>', nil, targetUrl
	end
end

local function buildUrlsFromArgs(args)
	return buildUrls(args.target_url, args.base_url, args.full_url, args.subdomain, args.no_archive, args.no_profile)
end

local function addBackup(template, fullUrl, lookupKey, noLive, args)
    if link == 'no-link' then
        return {}
    elseif yes(args.nobackup) and not yes(args.archivefile) and noLive then
        return {disclaimer = yes(args.sw_url) and 'content obsolete' or 'content obsolete and backup link not available'}
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
	if yes(args.use_new) then
		buildArchivePieces = require('Module:ArchiveAccess2').buildBackupLinkPieces
	end
	local archive = buildArchivePieces({
		template_name = args.archive or template, 
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
		archivefile6 = args.archivefile6 or '',
		archivefile7 = args.archivefile7 or '',
		archivefile8 = args.archivefile8 or '',
		archivefile9 = args.archivefile9 or '',
		archivefile10 = args.archivefile10 or '',
		oldversion = args.oldversion or '',
		citation_type = pt,
		use_lua_subpage = args.use_lua_subpage,
		backup_optional = args.backup_optional,
		is_profile = isProfile,
		has_new_url = args.has_new_url,
		optional = args.optional,
		no_archive = args.no_archive,
		nobackup = args.nobackup or '',
		nolive = autoNoLive or noLive,
		suppress = args.suppress or ''
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

-- Builds a secondary backup link for alternate-host versions of the webpage
local function addSiteBackup(template, fullUrl, targetUrl) 
	local buildArchive = require('Module:ArchiveAccess').buildBackupLinkPieces
	local archive = buildArchive({
		template_name = template, 
		full_url = fullUrl,
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
	return addSiteBackup(template, "https://www.starwars.com/"..url, url)
end

-- Builds the link and backup link for the citation, using building blocks for replacements and ordering them depending on the scenario
function buildLinkAndBackupTextFormat(backup, int, oldVersion, noLive, defunctSite, deadSite, isInternetArchive)
	if yes(backup.file) and not yes(backup.link) then -- backup files don't display backup links
		if yes(int) and oldVersion and not defunctSite then
			return "[[<INT>|<TEXT>]]", "<small>(<FILE>; content not present on [<FULL_URL> current version])</small>"
		elseif yes(int) then
			return "[[<INT>|<TEXT>]]", "<small>([<FULL_URL> article]) (<DISCLAIMER>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", "<small>(<FILE>) (<DISCLAIMER>)</small>"
		end
		
	elseif isInternetArchive then -- no backup for IA links
		return "[<FULL_URL> <TEXT>]", ""

	elseif oldVersion and not defunctSite then	-- if old version, prioritize displaying the backup link (if exists)
		local x = "content not present on [<FULL_URL> current version]"
		if yes(backup.isCurrent) then
			x = "[<FULL_URL> current version]"
		elseif deadSite then
			x = ""
		end
		
		if yes(int) and yes(backup.link) then
			return "[[<INT>|<TEXT>]]", "<small>([<BACKUP_LINK> backup link]<OV_DATE><WARNING>; "..x..") (<FILE>)</small>"
		elseif yes(backup.link) then
			return "[<BACKUP_LINK> <TEXT>]<WARNING>", "<small>(<OV_DATE>"..x..") (<FILE>)</small>"
		elseif yes(int) then
			return "[[<INT>|<TEXT>]]", "<small>(<OV_DATE>"..x.."<WARNING>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", "<small>(<DISCLAIMER><WARNING>) (<FILE>)</small>"
		end
		
	elseif noLive and yes(backup.link) then -- if no longer live, prioritize displaying the backup link
		local x = " (<HIGHLIGHT>[<FULL_URL> original <SITE_OR_LINK>]<HIGHLIGHT> is <OBSOLETE>)"
		if deadSite then
			x = ""
		end
		
		if yes(int) then
			x = x:gsub('<HIGHLIGHT>', '')
			return "[[<INT>|<TEXT>]]", "<small>(<HIGHLIGHT>[<BACKUP_LINK> backup link]<HIGHLIGHT><WARNING>)"..x.." (<FILE>)</small>"
		elseif hasValue(tooBig, currentTitle.text) then
			return "[<BACKUP_LINK> <TEXT>]<WARNING>", ""
		else
			return "[<BACKUP_LINK> <TEXT>]<WARNING>", "<small>"..x.." (<FILE>)</small>"
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
		if hasValue(tooBig, currentTitle.text) then
			return "[<FULL_URL> <TEXT>]", ""
		elseif yes(backup.link) then
			return "[<FULL_URL> <TEXT>]", "<small>(<HIGHLIGHT>[<BACKUP_LINK> backup link]<HIGHLIGHT><WARNING>) (<FILE>)</small>"
		elseif yes(backup.disclaimer) then
			return "[<FULL_URL> <TEXT>]", "<small>(<DISCLAIMER>) (<FILE>)</small>"
		else
			return "[<FULL_URL> <TEXT>]", ""
		end
	end
end

-- Builds the overall text for the citation, depending on the type of site
function buildMainText(linkText, backupText, parentLink, siteText, authorText, separator, prefix, args)
	local baseText
	if args.social_media and yes(args.is_post) and yes(args.text) then	-- posts w/ title get different format
		baseText = "<AUTHOR> (<PARENT>) on <SITE>: <LINK> (<DATE>)"
	elseif args.social_media and yes(args.is_post) then
		baseText = "<AUTHOR> (<PARENT>) on <SITE> (<LINK> on <DATE>)"
	elseif args.social_media then	-- no post URL = link/backup points to profile
		baseText = "<AUTHOR> (<LINK>) on <SITE> (<DATE>)"
	elseif args.blog and yes(args.is_post) and yes(args.text) then
		baseText = "<LINK> &mdash; <PARENT> on <SITE> (<DATE>)"
	elseif args.blog then	-- no post URL = link/backup points to profile
		baseText = "<LINK> on <SITE> (<DATE>)"
	elseif args.site_first then
		baseText = "<SITE> <LINK><AUTHOR> (<DATE>)"
	else
		baseText = "<PREFIX><LINK><AUTHOR> <SEPARATOR> <SITE> (<DATE>)"
	end
	
	baseText = substitute(baseText, '<LINK>', linkText, false)
	baseText = substitute(baseText, '<PARENT>', parentLink, false)
	baseText = substitute(baseText, '<SITE>', siteText, false)
	baseText = substitute(baseText, '<AUTHOR>', authorText, false)
	baseText = substitute(baseText, '<PREFIX>', prefix, false)
	baseText = substitute(baseText, '<SEPARATOR>', separator, false)
	
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
	local parentUrl, parentName, cat = '', '', ''
	local text = (args.text or ''):gsub('%[', '&#91;'):gsub('%]', '&#93;')
	if yes(args.no_profile) then
		-- do nothing
	elseif yes(args.social_media) then
		parentName = args.usertext or (args.username or '')
		parentUrl = yes(args.username) and combineUrls(args.base_url, args.username) or ''
		if template == "ArtStation" and yes(args.subdomain) and yes(args.username) then
			parentUrl = parentUrl:gsub(args.subdomain..'%.', 'www.')
		end
	elseif yes(args.blog) then
		parentName = yes(args.usertext) and args.usertext or 'NO NAME'
		if parentName == 'NO NAME' then
			cat = '[[Category:Blog citations missing site name|'..(args.subdomain or (args.username or template))..']]'
		end
		if yes(args.nonsubdomain) and yes(args.username) then
			parentUrl = combineUrls(args.base_url, args.username)
		else
			parentUrl = baseUrl
		end
	else
		return '', text or '<strong class="error">error: no text provided.</strong>'
	end
		
	parentName = decideParentName(args, template, parentName)
	local parentLink = yes(parentUrl) and '['..parentUrl..' '..parentName..']'..cat or ''
	-- use post title if given, otherwise display 'post', 'profile' or the profile/user name
	if yes(text) then
		return parentLink, text
	elseif yes(args.is_post) then
		return parentLink, args.post_type or 'post'
	else
		return parentLink, parentName or '<strong class="error">error: no text provided.</strong>'
	end
end

function addSeriesIfNeeded(text, args)
	if yes(args.series_text) or (yes(args.series) and args.series:find('%[')) then
		return args.series..' '..text
	elseif CUSTOM[args.series] ~= nil then
		return CUSTOM[args.series].." "..text
	elseif yes(args.series) and yes(args.template) and args.template:find('YouTube') then
		return "''[["..args.series.."]]'': "..text
	elseif yes(args.serieslink) or yes(args.series) then
		local sx = yes(args.serieslink) and args.serieslink or args.series
		if sx:sub(0, 5) == "Part " then
			return "[["..sx.."]] "..text
		end
		return "[["..sx.."]]: "..text
	end
	return text
end

function p.citation(args)
	local template = args.template
	local fullUrl, baseUrl, urlParamOrLookupKey = buildUrlsFromArgs(args)
	local parentLink, text = buildParentLinkAndText(args, template, baseUrl)
	local int = args.int or ''
	local separator = args.separator ~= nil and args.separator or 'on'
	local noBackup = yes(args.nobackup)
	local oldVersion = yes(args.oldversion)
	local legacy = yes(args.legacy) or yes(args.oldversion)
	local defunctSite = yes(args.defunct_site)
	local deadSite = yes(args.dead_site)
	local noLive = defunctSite or yes(args.nolive)
	local prefix = yes(args.prefix) and (args.prefix..' ') or ''
	local isInternetArchive = (args.base_url or (args.full_url or '')):find("archive%.org")

	if not noLive and yes(args.username) and defunctUsernames[template] ~= nil and hasValue(defunctUsernames[template], args.username) then
		noLive = true
	end
	
	-- adjust parameters as necessary
	if fullUrl:find('youtube.com/playlist=') then
		separator = 'playlist on'
	end
	local dateText, dateError = makeDateLink(args.date)
	if yes(dateText) and yes(args.time) then
		dateText = dateText:gsub('%)', ' at '..args.time..')')
	end
	local ovDateText = ''
	if oldVersion then
		ovDateText = makeDateText(args.oldversion)
		if yes(ovDateText) then
			ovDateText = 'recorded on '..ovDateText..';&nbsp;'
		end
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
	local linkText, backupText = buildLinkAndBackupTextFormat(backupData, int, legacy, noLive, defunctSite, deadSite, isInternetArchive)
	local mainText = buildMainText(linkText, backupText, parentLink, siteText, authorText, separator, prefix, args)
	if yes(backupData.isCurrent) then
		ovDateText = ''
	end
	
	-- replace <variables> in the link & backup with appropriate values
	mainText = substitute(mainText, '<INT>', int, false)
	mainText = substitute(mainText, '<TEXT>', text, false)
	mainText = substitute(mainText, '<DATE>', dateText, false)
	mainText = substitute(mainText, '<OV_DATE>', ovDateText, false)
	mainText = substitute(mainText, ' ?<FULL_URL>', fullUrl, false)
	mainText = substitute(mainText, ' ?<BACKUP_LINK>', backupData.link, false)
	mainText = substitute(mainText, '<FILE>', backupData.file, false)
	mainText = substitute(mainText, '<DISCLAIMER>', backupData.disclaimer, false)
	mainText = substitute(mainText, '<WARNING>', (backupData.warning and backupData.warning ~= "") and addHideSpan(backupData.warning) or '', true)
	mainText = mainText:gsub('<HIGHLIGHT>', backupData.highlight or '')
	mainText = mainText:gsub('<OBSOLETE>', args.defunct_site and 'defunct' or 'obsolete')
	mainText = mainText:gsub('<SITE_OR_LINK>', args.defunct_site and 'site' or 'link')
	if yes(backupData.categories) then
		mainText = mainText..backupData.categories
	end
	
	-- cleanup
	mainText = mainText:gsub(" ?%(%)", ""):gsub('@profile', 'profile'):gsub(" on %)", ")")
	
	mainText = addSeriesIfNeeded(mainText, args)
	
	if yes(args.livestream) or yes(args.original) then
		local otherUrl, _, otherKey = buildUrls(args.livestream or args.original, args.base_url, nil, nil, false, false)
		local otherBackup = addBackup(args.archive or template, otherUrl, otherKey, noLive, args)
		if yes(otherBackup.link) then
			local lx = yes(args.livestream) and 'livestream' or 'original version'
			local dx = (yes(otherBackup.disclaimer) and not yes(backupData.disclaimer)) and ' '..otherBackup.disclaimer or ''
			mainText = mainText..' <small>(['..otherBackup.link..' '..lx..'] no longer available'..(otherBackup.warning or '')..dx..')</small>'
		end
	else
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
			otherBackup = addSiteBackup(args.site_template, args.site_base_url..'/'..args.site_url, args.site_url)
		elseif yes(args.dub_url) then
			local otherUrl, _, otherKey = buildUrls(args.dub_url, args.base_url, nil, nil, false, false)
			otherBackup = addSiteBackup(args.archive or template, otherUrl, args.dub_url)
		elseif yes(args.yt_video) then
			local otherUrl, _, otherKey = buildUrls(args.yt_video, 'https://www.youtube.com/watch?v=', nil, nil, false, false)
			otherBackup = addSiteBackup('YouTube', otherUrl, args.yt_video)
		end
		if yes(otherBackup.link) then
			local dx = (yes(otherBackup.disclaimer) and not yes(backupData.disclaimer)) and ' '..otherBackup.disclaimer or ''
			if yes(args.dub_url) then
				mainText = mainText..' <small>(['..otherBackup.link..' English Dub]'..(otherBackup.warning or '')..dx..')</small>'
			elseif yes(args.yt_video) then
				mainText = mainText..' <small>(['..otherBackup.link..' YouTube video]'..(otherBackup.warning or '')..dx..')</small>'
			else
				mainText = mainText..' <small>(['..otherBackup.link..' Posted on '..siteName..']'..(otherBackup.warning or '')..dx..')</small>'
			end
		end
	end
	if yes(args.image) then
		mainText = args.image..'&#160;'..mainText
	end
	if dateError and currentTitle.namespace ~= 2 then
		mainText = mainText .. makeCategoryLink("WebCite date argument usages with incorrect date formats")
	end
	
	return buildAndValidate(mainText, args, urlParamOrLookupKey, fullUrl)
end

-- Primary validation function, checks a variety of different scenarios and adds relevant maintenance categories
function buildAndValidate(mainText, args, urlParamOrLookupKey, baseUrl, fullUrl)
	local ret = {}
	ret[#ret + 1] = string.format('<span class="mti">%s</span>', mainText)
	if currentTitle.namespace == 2 then
		return table.concat(ret)
	elseif args.unnamed and not yes(args.is_post) and (yes(args.social_media) or yes(args.blog)) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with positional parameters")..'·'
	elseif args.unnamed and not args.allow_unnamed then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with positional parameters")..'§'
	elseif args.unnamed and args.allow_unnamed and args.archive == "YouTube" and yes(args['unnamed-3']) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with positional parameters")..'§'
	elseif urlParamOrLookupKey ~= nil then
		if urlParamOrLookupKey:find('=http') then
			-- do nothing
		elseif yes(args.full_url) and cleanUrl(urlParamOrLookupKey:gsub('https?://', '')) == cleanUrl(args.full_url:gsub('https?://', '')) then
			-- do nothing
		elseif yes(args.subdomain) and urlParamOrLookupKey == args.subdomain then
			-- do nothing
		elseif urlParamOrLookupKey:find('http:') or urlParamOrLookupKey:find('https:') then
			if urlParamOrLookupKey:sub(0, 4) ~= 'web/' then
				ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL parameters")..'§'
			end
		elseif includesBaseUrl(urlParamOrLookupKey, baseUrl) then
			ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL parameters")..'§'
		end
	else
		ret[#ret + 1] = makeCategoryLink("Web citation template usages without URL parameter")
	end
	
	if yes(args.text) and args.text:find('%[%[') then
		ret[#ret + 1] = makeCategoryLink("Web citation templates using brackets in text parameter")
	end
	if yes(args.text) and args.text:find('<small>%(') then
		ret[#ret + 1] = makeCategoryLink("Web citation templates using small text in text parameter")
	end
	if yes(args.quote) and args.quote:find('<small>%(') then
		ret[#ret + 1] = makeCategoryLink("Web citation templates using small text in quote parameter")
	end
	if yes(args.work) then
		ret[#ret + 1] = makeCategoryLink("Dedicated internet citation templates using work parameter")
	end
	
	if args.social_media and not yes(args.username) and not yes(args.no_profile) then
		if currentTitle.namespace == 0 or currentTitle.namespace == 6 then
			ret[#ret + 1] = makeCategoryLink("Citation template usages without profile")
		end
	end
	if mainText:find('no text provided') then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages without text parameter")
	elseif yes(args.text) or yes(args.social_media) or yes(args.is_profile) or (yes(args.blog) and not yes(args.is_post)) then
		-- do nothing
	else
		ret[#ret + 1] = makeCategoryLink("Web citation template usages without text parameter")..'‡'
	end
	if args.empty and not (args.template == "HoloNetNewsWeb" or args.template == "Holonet" or args.template == "HolonetOld") then
		if currentTitle.namespace == 0 or currentTitle.namespace == 6 then
    		ret[#ret + 1] = makeCategoryLink('Web citation template usages with empty parameters')..'§'
    	end
    end
	if args.domain_not_allowed and yes(args.domain) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with invalid URL domain parameter")..'§'
	end
	
	if yes(args.channel) then
		if args.channel ~= urlParamOrLookupKey and hasValue(CHANNELS, string.lower(args.channel):gsub('@', ''):gsub('c/', ''):gsub('user/', '')) then
			ret[#ret + 1] = makeCategoryLink("YouTube usages instead of proper citation templates")..'§'
		elseif args.template == "YouTube" and hasValue(OFFICIAL, string.lower(args.channel):gsub('@', ''):gsub('c/', ''):gsub('user/', ''):gsub('channel/', '')) then
			ret[#ret + 1] = makeCategoryLink("YouTube usages to be converted to OfficialYouTube")..'§'
		end
	end
	
	if yes(args.archivefile) and not exists(args.archivefile) and currentTitle.namespace ~= 6 then
		ret[#ret + 1] = makeCategoryLink("Citation template usages with broken file links|"..args.template)..'§'
	end
	
	if yes(args.blogspotname) or yes(args.blogspoturl) or yes(args.tumblrurl) or yes(args.tumblrname) or yes(args.profilename) or yes(args.profilelink) or yes(args.profile) or yes(args.channelname) or yes(args.postname) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with legacy parameters")
	end
	
	if not (yes(args.social_media) or yes(args.blog) or hasValue(BOARDS, args.template) or (yes(args.subdomain) and args.subdomain == "community" and args.template == "Kabam")) and (yes(args.author) or yes(args.date)) then
		ret[#ret + 1] = makeCategoryLink("Web citation template usages with author or date parameters")
	end
	
	if currentTitle.namespace == 10 and not currentTitle.fullText:find('/doc') and currentTitle.fullText:find(args.template) then
		if args.use_lua_subpage then
			ret[#ret + 1] = makeCategoryLink("Citation templates with archive subpages")
		elseif args.no_archive then
			ret[#ret + 1] = makeCategoryLink("Citation templates without archive subpages")
		else
			ret[#ret + 1] = makeCategoryLink("Citation templates that do not use their Lua subpage")
		end
		if args.defunct_site then
			ret[#ret + 1] = makeCategoryLink("Citation templates for defunct websites")
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
		elseif v == '' and k ~= "int" then
			args['empty'] = true
		end
		if type(k) == "number" then
			args.unnamed = true
			args['unnamed-'..k] = v
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