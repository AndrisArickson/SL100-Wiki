-- This module implements [[Template:HBCite]].

local p = {}
local NS_MODULE = 828

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

-- isCurrentPageMainSpaceOrFile determines whether the page being parsed is a mainspace or file page.
local function isCurrentPageMainSpaceOrFile()
	local title = mw.title.getCurrentTitle()

	return title.namespace == NS_MAIN or title.namespace == NS_FILE or title.namespace == NS_MODULE or string.find(title.fullText, 'Wookieepedia:Sources') or string.find(title.fullText, 'Wookieepedia:Appearances')
end

-- getArchiveTrackingCategories returns tracking categories based on whether the explicit archive date used for this invocation
-- matches the implicit archive date sourced from the /Archive subpage of the template on behalf of which this module is invoked.
-- This is generally only useful if said /Archive subpage exists.
local function getArchiveTrackingCategories(explicitArchiveDate, knownArchiveDate, templateName, noLive)
	if not isCurrentPageMainSpaceOrFile() then
		return ''
	end

	-- User-provided explicit archive date parameter matches the implicit archive date from template data.
	if knownArchiveDate == explicitArchiveDate then
		return '[[Category:' .. templateName .. ' usages with the same archivedate value]]'
	end

	-- User-provided explicit archive date parameter does not match the implicit archive date from template data.
	if knownArchiveDate then
		if noLive then
			return '\n[[Category:' .. templateName .. ' usages with custom archivedate and nolive flag]]'
		else
			return '\n[[Category:' .. templateName .. ' usages with custom archivedate]]'
		end
	end
	
	return '[[Category:' .. templateName .. ' usages with archived URLs not in Archive]]'
end

local function check(str)
	if str == nil then
		str = ""
	end
	return str
end

local function getBackupLink(args, fullUrl, knownArchiveDate)
	-- No backup link is available, so return a customizable disclaimer
	if args.nobackup then
		return (args.nobackup_text or 'content obsolete and backup link not available')
	end

	-- If the original link is now inaccessible, render a customizable disclaimer
	local obsoleteDisclaimer = 'content now obsolete;&#32;'

	local archiveFile = args.archivefile
	if archiveFile then
		return obsoleteDisclaimer .. '[[:' .. archiveFile .. '|screenshot]]'
	end

	local archiveUrl = args.archiveurl
	local archiveLinkText = args.text or 'backup link'

	-- Full Wayback URL given, so return it with appropriate tracking categories
	if archiveUrl then
		local trackingCategories = '[[Category:Archiveurl usages with non-Wayback URLs]]'
		if mw.ustring.find(archiveUrl, 'web.archive.org/web') and isCurrentPageMainSpaceOrFile() then
			trackingCategories = '[[Category:Archiveurl usages with Wayback URLs]]'
		end
		return obsoleteDisclaimer .. '[' .. archiveUrl .. ' ' .. archiveLinkText .. ']' .. trackingCategories
	end

	-- Determine the Wayback URL to use based on the archive date and full_url params, if given.
	local templateName = args.template_name or ''
	local explicitArchiveDate = args.archivedate
	local target = args.target

	-- If an explicit archive date was given, use it to point to the Wayback snapshot at that given time
	-- and append appropriate tracking categories.
	if explicitArchiveDate then
		local trackingCategories = not noArchive and getArchiveTrackingCategories(explicitArchiveDate, knownArchiveDate, 'HBCite', args.nolive) or ''
		return obsoleteDisclaimer .. '[https://web.archive.org/web/' .. explicitArchiveDate .. '/' .. fullUrl .. ' ' .. archiveLinkText .. ']' .. trackingCategories
	end

	-- No explicit archive date was given, so use the archive date from the archive subpage of the owning template if possible
	if knownArchiveDate ~= nil and knownArchiveDate ~= '' then
		return obsoleteDisclaimer .. '[https://web.archive.org/web/' .. knownArchiveDate .. '/' .. fullUrl .. ' ' .. archiveLinkText .. ']'
	elseif args.optional then
		return ''
	else
		return (args.nobackup_text or 'content obsolete and backup link not available')
	end
end
		
function p.citation(args, data)
	local issue = args.issue or args[1]
	local text = issue
	local url = args.url or ''
	
	local info = data.issues[issue]
	local archivedate = nil
	if info then
		url = info.url
		if info.txt ~= nil and info.txt ~= "" then
			text = issue .. " - " .. info.txt
		end
		archivedate = info.archive
	end
	
	if url == nil or url == '' then
		url = 'http://www.starwars.com/media/newsletter/beacon/beacon_' .. issue .. '.html'
	end
	
	if url ~= nil and url ~= '' and url:find('http', 1, true) ~= 1 then
		url = 'http://www.starwars.com/' .. url
	end
	
	local archivetext = '<small>(' .. getBackupLink(args, url or '', archivedate) .. ')</small>'
	
	local image = "[[File:HomingBeaconTitleSmall.png|baseline|x12px|link=Homing Beacon (newsletter)]]"
	local result = image .. " [[Homing Beacon (newsletter)|Homing Beacon]] [" .. url .. " #" .. text .. "] on [[StarWars.com]] " .. archivetext
	return "<span class=\"plainlinks\">" .. result .. "</span>"
end

function p.main(frame)
	local data = mw.loadData('Module:HBCite/data')
	local args = {}
	for k, v in pairs(frame:getParent().args) do 
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.citation(args, data) or '{{{1}}}'
end

return p