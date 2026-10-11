-- ArchiveAccess implements rendering for web page archive links.bo
local p = {}

local NS_MAIN = 0
local NS_USER = 2
local NS_FILE = 6
local NS_TEMPLATE = 10
local NS_INDEX = 120
local NS_MODULE = 828
local title = mw.title.getCurrentTitle()

local UPDATED_YEARLY = {'news/happy-star-wars-day', 'news/star-wars-black-friday-and-cyber-week-deals', 'news/star-wars-day-deals', 'news/star-wars-day-merchandise', 'news/star-wars-day-video-game-deals', 'news/star-wars-fathers-day-gift-guide', 'news/star-wars-halloween-shopping-guide', 'news/star-wars-holiday-gift-guide', 'news/star-wars-mothers-day-gift-guide', 'news/star-wars-reads', 'news/star-wars-valentines-day-gift-guide', 'news/everything-star-wars-on-disney-plus', 'zones/starwars/editor.php'}
local DEFUNCT = {"SWArchive", "Hnn", "Blog", "WizardsCite", "Hyperspace", "CargoBay", "DHBoards", "Titan", "LegacyEdelweiss"}
local ARCHIVE_TODAY_DOMAINS = {'archive.is', 'archive.ph', 'archive.vn', 'archive.md', 'archive.fo', 'archive.li', 'archive.today'}
local SOCIAL = {"Instagram", "Bluesky", "Twitter", "ArtStation", "LinkedIn", "TikTok", "Facebook", "DeviantArt", "Tumblr"}
local TOYS = {"HasbroCite", "DisneyToyCite", "SideshowCite", "HotToysCite", "GentleGiantCite"}
local CARDS = {"Topps", "SWU", "Destiny"}

-- isCurrentPageMainSpaceOrFile determines whether the page being parsed is a mainspace or file page.
local function isCurrentPageMainSpaceOrFile()
	return title.namespace == NS_MAIN or title.namespace == NS_FILE or title.namespace == NS_MODULE or string.find(title.fullText, 'Wookieepedia:Sources') or string.find(title.fullText, 'Wookieepedia:Appearances')
end

function string.startswith(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.endswith(String, suffix)
    return string.sub(String, -#suffix) == suffix
end

function split(str, sep)
	local t = {}
	for str in string.gmatch(str, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end
	
function yes(s)
	return s ~= nil and s ~= '' and s ~= false
end

function category(c)
	return string.format('[[Category:%s|%s]]', c, title.text)
end

local function hasValue(tab, val)
	for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function isArchiveTodayLink(url)
	local domain = url:gsub('www%.', ''):match('^%w+://([^/]+)')
	return hasValue(ARCHIVE_TODAY_DOMAINS, domain)
end

local function detectDomain(url)
	if url:find('ghostarchive') then
		return ''
	end
	if isArchiveTodayLink(url) then
		return '/Today'
	end
	return ''
end

local function sharedTodayCategory(templateName, hasFile, fullUrl, noLive)
	local zx = ''
	if hasValue(DEFUNCT, templateName) then
		zx = '/Defunct'
	elseif templateName == "Blogspot" and yes(fullUrl) and fullUrl:find('dailysw') then
		zx = '/Defunct'
	elseif noLive then
		zx = '/nolive'
	elseif hasValue(SOCIAL, templateName) then
		zx = '/Social'
	elseif hasValue(CARDS, templateName) then
		zx = "/Cards"
	end
	if hasFile then
		return category('Archivetoday links with archival screenshots already provided')
	elseif title.namespace ~= NS_INDEX then
		return category('ArchiveAccess usages with archivetoday links'..zx..'|'..templateName)
	end
	return ''
end

-- getArchiveTrackingCategories returns tracking categories based on whether the explicit archive date used for this invocation
-- matches the implicit archive date sourced from the /Archive subpage of the template on behalf of which this module is invoked.
-- This is generally only useful if said /Archive subpage exists.
local function getArchiveTrackingCategories(explicitArchiveDate, knownArchiveDate, templateName, noLive, partialMatch, exempt, hasFile)
	if not isCurrentPageMainSpaceOrFile() then
		return ''
	end
	
	local cx = ''
	if explicitArchiveDate and string.startswith(explicitArchiveDate, '20') and string.endswith(explicitArchiveDate, 'com') then
		cx = category('Broken archivedate values') .. '\n'
	end
	if exempt then
		return cx
	end
	
	if knownArchiveDate ~= nil and explicitArchiveDate == nil and knownArchiveDate:find('archive') and isArchiveTodayLink(knownArchiveDate) then
		if hasFile then
			cx = cx .. category('Archivetoday links with archival screenshots already provided')
		else
			cx = cx .. category('ArchiveAccess usages with archivetoday links'..'|'..templateName)
		end
	end

	-- User-provided explicit archive date parameter matches the implicit archive date from template data.
	if knownArchiveDate ~= nil and explicitArchiveDate ~= nil and knownArchiveDate:gsub('https://', ''):gsub('http://', '') == explicitArchiveDate:gsub('https://', ''):gsub('http://', '') then
		return cx .. category(templateName .. ' usages with the same archivedate value')
	elseif partialMatch and explicitArchiveDate and knownArchiveDate and string.find(knownArchiveDate, explicitArchiveDate, 1, true) then
		return cx .. category(templateName .. ' usages with the same newurl value')
	end

	-- User-provided explicit archive date parameter does not match the implicit archive date from template data.
	if knownArchiveDate then
		if noLive and not hasValue(DEFUNCT, templateName) then
			return cx .. category('Internet citations with custom archivedate and nolive flag') .. ' §'
		else
			return cx .. category(templateName .. ' usages with custom archivedate') .. ' ‡'
		end
	else
		return cx .. category(templateName .. ' usages with archived URLs not in Archive')
	end
end

local function findMatch(target, templateData)
	local match = templateData.knownArchiveDates[string.lower(target)]
	if not match and string.lower(target) ~= target then
		match = templateData.knownArchiveDates[target]
	end
	if not match and string.startswith(target, '/') and #target > 1 then
		match = templateData.knownArchiveDates[string.lower(target:sub(2))]
		if not match and string.lower(target) ~= target then
			match = templateData.knownArchiveDates[target:sub(2)]
		end
	end
	return match
end

local function checkHttpOrHttps(target, templateData)
	local match = findMatch(target, templateData)
	if not match and string.startswith(target, 'http:') and string.endswith(target, '/') then
		match = findMatch(target:gsub("http:", "https:"):sub(0, -2), templateData)
	end
	if not match and string.startswith(target, 'http:') and not string.endswith(target, '/') then
		match = findMatch(target:gsub("http:", "https:") .. '/', templateData)
	end
	if not match and string.startswith(target, 'http:') then
		match = findMatch(target:gsub("http:", "https:"), templateData)
	end
	if not match and string.startswith(target, 'https:') then
		match = findMatch(target:gsub("https:", "http:"), templateData)
	end
	return match
end

local function determineArchiveValue(target, moduleName, simple)
	local templateData = require(moduleName)
	if simple then
		return templateData.knownArchiveDates[target]
	end
	if moduleName == "Module:ArchiveAccess/Rebelscum" then
		local _, i = target:find('rebelscum.com/')
		if i ~= nil then
			local tx = string.lower(target:sub(i + 1))
			if templateData.knownArchiveDates[tx] then
				return templateData.knownArchiveDates[tx]
			end
		end
	end
	
	local match = checkHttpOrHttps(target, templateData)
	if not match and not target:find('www.') then
		match = checkHttpOrHttps(target:gsub('://', '://www.'), templateData)
	end
	if not match and target:find('www.') then
		match = checkHttpOrHttps(target:gsub('www.', ''), templateData)
	end
	if not match and string.endswith(target, '//') then
		match = checkHttpOrHttps(target:sub(0, -3), templateData)
	end
	if not match and string.endswith(target, '/') then
		match = checkHttpOrHttps(target:sub(0, -2), templateData)
	end
	if not match and not string.endswith(target, '/') then
		match = checkHttpOrHttps(target .. '/', templateData)
	end
	return match
end

local function determineArchiveDate(target, templateName, simple)
	local valueString = determineArchiveValue(target, 'Module:ArchiveAccess/' .. templateName, simple)
	if yes(valueString) and type(valueString) ~= "string" then
		valueString = tostring(valueString)
	end
	local files = {}
	local value = ""
	if yes(valueString) and valueString:find('|') then
		local i = 0
		for x, val in ipairs(split(valueString, '|')) do
			if yes(val) and string.startswith(val, 'File:') then
				i = i + 1
				if i == 1 then
					files['archivefile'] = val:gsub(' ', '_')
				else
					files['archivefile'..i] = val:gsub(' ', '_')
				end
			elseif yes(val) then
				value = val
			end
		end
	elseif yes(valueString) and string.startswith(valueString, 'File:') then
		files['archivefile'] = valueString:gsub(' ', '_')
	else
		value = valueString
	end
	return value, files
end

local function determineArchiveNewUrl(target, templateName, simple)
	return determineArchiveValue(target, 'Module:NewUrlAccess/' .. templateName, false)
end

local function buildArchiveLink(archiveDate, fullUrl)
	if mw.ustring.find(archiveDate, 'http') then
		return archiveDate 
	end
	return 'https://web.archive.org/web/' .. archiveDate .. '/' .. fullUrl
end 

local function decideBoldOrItalics(known, explicit, old)
	if old then
		return ""
	elseif known == explicit then
		return "'''"
	elseif not known then
		return "''"
	else
		return ""
	end
end

local function buildDisclaimer(target, hasArchive, isProfile, templateForCategory)
	local linkTitle = hasArchive and 'Module:ArchiveAccess/' or 'Template:'
	local tx = hasArchive and ' ('..target..')' or ''
	if isProfile then
		return ' [['..linkTitle..templateForCategory..'|needs confirmation]]'..tx
	else
		return ' [['..linkTitle..templateForCategory..'|<span style="color: red">\'\'\'not verified!\'\'\'</span>]]'..tx
	end
end

local function decideTemplateCategory(sharedSiteTemplate, templateName, target)
	if not sharedSiteTemplate then
		return templateName
	elseif sharedSiteTemplate == "Rebelscum" and target:find('rebelscum') then
		return "Rebelscum"
	elseif sharedSiteTemplate == "SW" and target:find('starwars.com') then
		return "SW"
	elseif sharedSiteTemplate == "SWYouTube" then
		return "SWYouTube"
	end
	return templateName
end

-- Determine the Wayback URL to use based on the archive date and full_url params, if given.
local function decideKnownValuesAndTemplateCategory(target, templateName, sharedSiteTemplate, noArchive, useLuaSubpage, isVideo)
	local knownArchiveDate
	local knownArchiveFiles = {}
	local knownNewUrl
	local templateForCategory = decideTemplateCategory(sharedSiteTemplate, templateName, target)

	-- If the 'target' parameter was forwarded to this invocation, attempt fetch known archive dates from a Lua module subpage
	if target and not noArchive then
		if useLuaSubpage then
			knownArchiveDate, knownArchiveFiles = determineArchiveDate(target, templateName, isVideo)
		end
		
		if sharedSiteTemplate and not knownArchiveDate then
			knownArchiveDate, knownArchiveFiles = determineArchiveDate(target, sharedSiteTemplate, isVideo)
			if knownArchiveDate then
				templateForCategory = sharedSiteTemplate
			end
		end
	end
	
	if target and hasNewUrl then
		knownNewUrl = determineArchiveNewUrl(target, templateName, isVideo)
	end
	return knownArchiveDate, knownNewUrl, knownArchiveFiles, templateForCategory
end

-- Prepares tracking categories for archiveurl parameters
local function getArchiveUrlTrackingCategories(archiveUrl, fullUrl, target, noArchive, useLuaSubpage, notLive, isOldVersion, isVideo, templateName, suppress, exempt, archivefile)
	local domainFlag = detectDomain(archiveUrl)
	if domainFlag:find('Today') and (isOldVersion or templateName == 'Edelweiss') then
		domainFlag = domainFlag .. '/OldVersion'
	end
	if domainFlag == '/Today' then
		domainFlag = domainFlag..'|'..templateName
	end
	
	local nonWayback = category('Archiveurl usages with non-Wayback URLs'..domainFlag)
	if domainFlag:find('Today') and yes(archivefile) then
		nonWayback = category('Archivetoday links with archival screenshots already provided')
	end
	if not isCurrentPageMainSpaceOrFile() then
		nonWayback = ''
	end
	if archiveUrl:find('web%.archive%.org/web') and isCurrentPageMainSpaceOrFile() and templateName ~= "SWU" then
		nonWayback = ''
		if fullUrl then
			local st = string.lower(fullUrl:gsub('http://', ''):gsub('https://', ''):gsub('www%.', ''):gsub('%/$', ''))
			local tx = string.lower(archiveUrl:gsub('http://', ''):gsub('https://', ''):gsub('www%.', ''))
			if tx:find(st, 1, true) then
				nonWayback = category('Archiveurl usages instead of archivedate')
			end
		end
		if nonWayback == '' and not suppress then
			if templateName ~= "JCFCite" and templateName ~= "LCCN" and not archiveUrl:find('cdn') then
				nonWayback = category('Archiveurl usages with Wayback URLs')
			end
		end
	end
	
	local bold = ""
	local tracking = ''
	if target and not noArchive and useLuaSubpage then
		local knownArchiveValue, knownArchiveFiles = determineArchiveDate(target, templateName, isVideo)
		if isOldVersion and knownArchiveValue and knownArchiveValue:gsub('https://', ''):gsub('http://', '') == archiveUrl and not hasValue(UPDATED_YEARLY, target) then
			tracking = category('Usages of oldversion with common archivedate value')
		elseif not isOldVersion and knownArchiveValue and hasValue(UPDATED_YEARLY, target) then
			tracking = category('Yearly-updated webpages listed without oldversion') .. ' §'
		elseif not isOldVersion then
			bold = decideBoldOrItalics(knownArchiveValue, archiveUrl, isOldVersion)
			if bold then
				tracking = getArchiveTrackingCategories(archiveUrl, knownArchiveValue, templateName, notLive, true, exempt, yes(archivefile))
				if yes(archivefile) and knownArchiveFiles then
					tracking = tracking .. getArchiveTrackingCategories(archivefile:gsub(' ', '_'), knownArchiveFiles.archivefile, templateName, notLive, false, exempt, true)
				end
				if nonWayback:find('Today') and tracking:find('same ') then
					nonWayback = sharedTodayCategory(templateName, hasFile, fullUrl, notLive)
				end
			end
		end
	end
	return bold, tracking .. nonWayback
end

-- getMissingPermalinkTrackingCategory returns the tracking category to be used for the current owning template
-- if this invocation contained an archival link without a permalink timestamp.
-- It prefers to use a template-specific tracking category if one exists and a generic one otherwise.
local function getMissingPermalinkTrackingCategory(citationType, templateName, isProfile, noArchive)
	local icx = ''
	if title.namespace == NS_INDEX then
		icx = ''
	elseif not isCurrentPageMainSpaceOrFile() then
		return ''
	end
	
	if isProfile and (templateName == 'Instagram' or templateName == 'LinkedIn') then
		return '[[Category:Web citations with missing archival screenshots|'.. templateName..']]'
	elseif noArchive and templateName then
		return '[[Category:' .. citationType .. ' with missing permanent archival links'..icx..'|' .. templateName .. ']]'
	elseif templateName then
		return '[[Category:' .. citationType .. ' with missing shared permanent archival links'..icx..'|' .. templateName .. ']]'
	elseif noArchive then
		return category(citationType .. ' with missing permanent archival links'..icx)
	else
		return category(citationType .. ' with missing shared permanent archival links'..icx)
	end
end

local function addScreenshotToList(ft, file, i)
	if yes(file) then
		return ft..'; [[:'..file..'|screenshot '..i..']]', i + 1
	end
	return ft, i
end

function p.addScreenshotIfExists(archive, args)
	if yes(args.archivefile) and yes(args.nolive) and not yes(archive.disclaimer) then
		archive.disclaimer = 'content now obsolete'
	end

	if yes(args.archivefile) and yes(args.archivefile2) and yes (args.archivefile3) then
		archive.file = 'screenshots [[:'..args.archivefile..'|1]]'
		for i = 1, 10 do 
			if yes(args['archivefile'..i]) then
				archive.file = archive.file..', [[:'..args['archivefile'..i]..'|'..i..']]'
			end
		end
	elseif yes(args.archivefile) and yes(args.archivefile2) then
		archive.file = '[[:'..args.archivefile..'|screenshot 1]] & [[:'..args.archivefile2..'|screenshot 2]]'
	elseif yes(args.archivefile) then
		archive.file = '[[:'..args.archivefile..'|screenshot]]'
	end
	return archive
end

-- getBackupLink generates a Wayback machine archive URL based on invocation parameters
-- with appropriate tracking categories appended.
function p.getBackupLink(args)
	local results = p.buildBackupLinkPieces(args)
	if results.file ~= nil then
		return (results.disclaimer or '') .. results.file
	end
		
	local ret = {}
	ret[#ret + 1] = results.disclaimer
	if results.highlight ~= nil then
		ret[#ret + 1] = results.highlight
	end
	if results.link ~= nil and results.text ~= nil then
		ret[#ret + 1] = '['..results.link..' '..results.text..']'
	end
	if results.highlight ~= nil then
		ret[#ret + 1] = results.highlight
	end
	if results.extra ~= nil then
		ret[#ret + 1] = results.extra
	end
	if results.warning ~= nil then
		ret[#ret + 1] = results.warning
	end
	if results.categories ~= nil then
		ret[#ret + 1] = results.categories
	end
	return table.concat(ret)
end

function p.buildBackupLinkPieces(args)
	return p.addScreenshotIfExists(p._buildBackupLinkPieces(args), args)
end

function p._buildBackupLinkPieces(args)
	-- if no backup exists but we have a screenshot, then exclude the 'backup not available' text and bypass the rest of the logic
	if yes(args.nobackup) and yes(args.nolive) and yes(args.archivefile) then
		return {disclaimer = 'content now obsolete'}
	elseif yes(args.nobackup) and yes(args.archivefile) then
		return {}
	-- No backup link is available, so return a customizable disclaimer
	elseif yes(args.nobackup) and yes(args.nolive) then
		return {disclaimer = (args.nobackup_text or 'content obsolete and backup link not available')}
	elseif yes(args.nobackup) then
		return {disclaimer = (args.nobackup_text or 'backup link not available')}
	end

	-- If the original link is now inaccessible, render a customizable disclaimer
	local obsoleteDisclaimer = ''
	if yes(args.oldversion) then
		obsoleteDisclaimer = args.nolive_text or 'content only found on older version of webpage;&#32;'
	elseif yes(args.nolive) then
		obsoleteDisclaimer = args.nolive_text or 'content now obsolete;&#32;'
	end
	
	if title.fullText:sub(0, 9) == "User:Cade" then
		obsoleteDisclaimer = ''
	end

	local target = args.target or ''
	target = target:gsub('&ndash;', '–')
	local templateName = args.template_name or ''
	if templateName == "YouTube" and target:find('&') then
		target = target:sub(0, target:find('&') - 1)
	end
	local noArchive = args.no_archive or false
	local isVideo = args.is_video or false
	local archiveUrl = args.archiveurl or ''
	local fullUrl = args.full_url or ''
	local hasNewUrl = yes(args.has_new_url)
	local hasFile = yes(args.archivefile)
	local explicitArchiveDate = args.archivedate
	local explicitNewUrl = args.new_url
	local archiveLinkText = args.text or 'backup link'
	local useLuaSubpage = args.use_lua_subpage
	local sharedSiteTemplate = args.shared_site
	local isOldVersion = yes(args.oldversion)
	local notLive = yes(args.nolive) or isOldVersion
	local oldVersion = args.oldversion
	
	local tracking = ''
	local bold = ""
	local newHost = ''
	local exempt = target == '/' or target == ''
	local currentYear = false
	
	if yes(args.new_host) then
		newHost = ' on ' .. args.new_host
	end
	if args.simple then
		archiveLinkText = 'article'
		obsoleteDisclaimer = ''
	end
	
	-- flag legacy oldversion=1 values, otherwise use URL/date from oldversion
	if isOldVersion then
		if oldVersion == '1' and not yes(archiveUrl) then
			tracking = category('Legacy usages of oldversion parameter')
		elseif oldVersion:find('http') then
			if yes(archiveUrl) then
				tracking = category('Invalid usages of oldversion parameter')
			else
				archiveUrl = oldVersion
			end
		elseif #oldVersion > 4 and string.startswith(oldVersion, '2') then
			if yes(explicitArchiveDate) then
				tracking = category('Invalid usages of oldversion parameter')
			else
				explicitArchiveDate = oldVersion
				if hasValue(UPDATED_YEARLY, target) then
					if string.sub(oldVersion, 0, 4) == os.date("%Y") then
						obsoleteDisclaimer = ''
						currentYear = true
					end
				end
			end
		end
		if not yes(explicitNewUrl) and not yes(archiveUrl) and not yes(explicitArchiveDate) then
			tracking = tracking .. category('Usages of oldversion without explicit archivedate or archiveurl') .. ' §'
		end
	elseif hasValue(UPDATED_YEARLY, target) then
		tracking = tracking .. category('Yearly-updated webpages listed without oldversion') .. ' §'
	end
	
	if yes(explicitArchiveDate) and isCurrentPageMainSpaceOrFile() and (explicitArchiveDate:find('[a-z,-]') or string.len(explicitArchiveDate) ~= 14) then
		tracking = tracking .. category('Usages of archivedate with incorrect format') .. ' §'
	end

	-- Full Wayback URL given, so return it with appropriate tracking categories
	if yes(archiveUrl) then
		local urlBold, urlCategories = getArchiveUrlTrackingCategories(archiveUrl, fullUrl, target, noArchive, useLuaSubpage, notLive, isOldVersion, isVideo, templateName, args.suppress, exempt, args.archivefile)
		return {disclaimer = obsoleteDisclaimer, highlight = urlBold, link = archiveUrl, text = archiveLinkText, categories = tracking .. urlCategories}
	end
	
	-- No Lua Archive, so use the explicitly given values
	if noArchive and yes(explicitNewUrl) then
		return {disclaimer = obsoleteDisclaimer, link = explicitNewUrl, text = archiveLinkText, extra = newHost, categories = tracking, isCurrent = currentYear}
	elseif noArchive and yes(explicitArchiveDate) then
		return {disclaimer = obsoleteDisclaimer, link = buildArchiveLink(explicitArchiveDate, fullUrl), text = archiveLinkText, categories = tracking, isCurrent = currentYear}
	end
	
	local knownArchiveDate, knownNewUrl, knownArchiveFiles, templateForCategory = decideKnownValuesAndTemplateCategory(target, templateName, sharedSiteTemplate, noArchive, useLuaSubpage, isVideo)
	
	-- If an explicit backup host URL was given, use that.
	if yes(explicitNewUrl) then
		if isOldVersion and explicitNewUrl == knownNewUrl then
			tracking = tracking .. category('Usages of oldversion with common archivedate value')
		elseif not (noArchive or isOldVersion) then
			tracking = tracking .. getArchiveTrackingCategories(explicitNewUrl, knownNewUrl, templateForCategory, notLive, true, exempt, hasFile)
			bold = decideBoldOrItalics(knownNewUrl, explicitNewUrl, false)
		end
		return {disclaimer = obsoleteDisclaimer, highlight = bold, link = explicitNewUrl, text = archiveLinkText, extra = newHost, categories = tracking, isCurrent = currentYear}
	end

	-- If an explicit archive date was given, use it to point to the Wayback snapshot at that given time
	-- and append appropriate tracking categories.
	if yes(explicitArchiveDate) then
		if isOldVersion and explicitArchiveDate == knownArchiveDate and not hasValue(UPDATED_YEARLY, target) then
			tracking = tracking .. category('Usages of oldversion with common archivedate value')
		elseif not isOldVersion and knownArchiveDate and hasValue(UPDATED_YEARLY, target) then
			tracking = tracking .. category('Yearly-updated webpages listed without oldversion') .. ' §'
		elseif not (noArchive or isOldVersion) then
			tracking = tracking .. getArchiveTrackingCategories(explicitArchiveDate, knownArchiveDate, templateForCategory, notLive, false, exempt, hasFile)
			bold = decideBoldOrItalics(knownArchiveDate, explicitArchiveDate, false)
		end
		return {disclaimer = obsoleteDisclaimer, highlight = bold, link = buildArchiveLink(explicitArchiveDate, fullUrl), text = archiveLinkText, categories = tracking, isCurrent = currentYear}
	end
	
	-- No explicit backup host URL was given, so use the backup host URL from the archive subpage of the owning template if possible
	if knownNewUrl then
		return {disclaimer = obsoleteDisclaimer, link = knownNewUrl, text = archiveLinkText, extra = newHost, isCurrent = currentYear}
	end
	
	if knownArchiveDate ~= nil and knownArchiveDate:find('archive') and isArchiveTodayLink(knownArchiveDate) then
		tracking = tracking .. sharedTodayCategory(templateName, hasFile, fullUrl, notLive)
	end
	
	if yes(knownArchiveFiles) and yes(knownArchiveFiles.archivefile) then 
		if yes(args.archivefile) then
			tracking = tracking .. getArchiveTrackingCategories(args.archivefile:gsub(' ', '_'), knownArchiveFiles.archivefile, templateName, notLive, false, exempt, true)
		end
		for k, v in pairs(knownArchiveFiles) do
			if v ~= nil and v ~= undefined then
				args[k] = v
			end
		end
	elseif yes(args.archivefile) and not noArchive then
		tracking = tracking .. category(templateForCategory .. ' usages with archived URLs not in Archive') .. ' §'
	end

	-- No explicit archive date was given, so use the archive date from the archive subpage of the owning template if possible
	if not noArchive and yes(knownArchiveDate) then
		if knownArchiveDate ~= nil and string.match(knownArchiveDate, "^%d+$") and string.len(knownArchiveDate) ~= 14 then
			tracking = tracking .. category('Usages of archivedate with incorrect format') .. ' §'
		end
		return {disclaimer = obsoleteDisclaimer, link = buildArchiveLink(knownArchiveDate, fullUrl), text = archiveLinkText, categories = tracking, isCurrent = currentYear}
	end

	-- If optional param is given, then ignore tracking category
	if args.backup_optional then
		return {disclaimer = (args.nobackup_text or 'content obsolete and backup link not available') or obsoleteDisclaimer, categories = tracking, isCurrent = currentYear}
	elseif args.optional or yes(args.archivefile) then
		return {categories = tracking}
	else
		-- Neither an explicit nor implicit archive date is available, so point to the latest Wayback snapshot with a disclaimer
		local citationType = args.citation_type or 'Pages'
		local notVerifiedDisclaimer = buildDisclaimer(target, not noArchive, args.is_profile, templateForCategory)
		local missingCategory = getMissingPermalinkTrackingCategory(citationType, templateForCategory, args.is_profile, noArchive)
		return {disclaimer = obsoleteDisclaimer, link = 'https://web.archive.org/web/' .. fullUrl, text = archiveLinkText, warning = notVerifiedDisclaimer, categories = missingCategory .. tracking, isCurrent = currentYear}
	end
end

-- render outputs a full Wayback link wrapped in a container.
function p.render(args)
	local isSmallFont = args.normal_size == nil or args.normal_size == ""
	local wrapInParentheses = args.par
	local useSpaceSeparator = args.space
	
	if not args.nobackup and not args.archivefile and not args.archiveurl and not args.archivedate and args.optional then
		return ''
	else
		local link = p.getBackupLink(args)
		if link ~= nil and link ~= "" then
			return mw.ustring.format(
				'%s%s%s%s%s',
				isSmallFont and '<small>' or '',
				wrapInParentheses and '&#32;(' or (useSpaceSeparator and '&#32;' or ''),
				link,
				wrapInParentheses and ')' or '',
				isSmallFont and '</small>' or ''
			)
		else
			return ''
		end
	end
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p.render(args)
end

return p