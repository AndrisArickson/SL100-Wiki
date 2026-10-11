-- <nowiki>

-------------------------------------------------------------------------------
--                              Module:Top
--
-- This module renders the icons in the top-right corner of articles, as well
-- as the Canon and Legends tabs for pages with a Canon/Legends counterpart.
-- It also formats the page title with {{DISPLAYTITLE}}. It is a rewrite of
-- [[Template:Top]].
-------------------------------------------------------------------------------

local DEBUG_MODE = false -- if true, errors are not caught
local whitelist = require('Module:Top/whitelist')

-------------------------------------------------------------------------------
-- Icon data
-------------------------------------------------------------------------------

--[[
-- This table stores data for all the icons displayed in the top-right. It can
-- have the following fields:
-- * image - the icon image name, minus any "File:" prefix (required).
-- * tooltip - the icon tooltip (optional).
-- * link - the page to link from the icon (optional).
-- * category - a category to go with the icon, minus any "Category:" prefix
--     (optional).
-- * protectionAction - for protection icons, an action such as "edit" or "move"
--     to check (optional).
-- * protectionLevel - for protection icons, the protection level to check,
--     such as "sysop". If the page doesn't have the right protection level
--     it is put in a tracking category and the icon is not displayed
--     (optional).
-- Note: this is just a convenient place to store the data. The subtables are
-- accessed from the code manually, so adding new subtables won't automatically
-- add new icons, and removing subtables may break things.
--]]

local iconData = {
	can = {
		image = 'Premium-Eras-canon.png',
		tooltip = 'This article details a subject that is considered canon.',
		canon = true,
		link = 'Canon'
	},
	leg = {
		image = 'Premium-Eras-legends.png',
		tooltip = 'This article details a subject that falls under the Legends continuity.',
		canon = false,
		link = 'Star Wars Legends'
	},
	ncc = {
		image = 'Premium-Eras-NCC.png',
		tooltip = 'This article details a subject that is considered non-canon.',
		canon = true,
		link = 'Canon'
	},
	ncl = {
		image = 'Premium-Eras-NCL.png',
		tooltip = 'This article details a subject that is considered non-canon within the Legends continuity.',
		canon = false,
		link = 'Star Wars Legends'
	},
	dotj = {
		image = 'DawnofJediWhite.png|20px',
		tooltip = 'The subject of this article takes place in the Dawn of the Jedi era.',
		canon = true,
		link = 'Dawn of the Jedi era'
	},
	tor = {
		image = 'TORWhite.png|20px',
		tooltip = 'The subject of this article takes place in the Old Republic era.',
		canon = true,
		link = 'Old Republic-era'
	},
	thr = {
		image = 'HighRepublicBlack.png|20px',
		tooltip = 'The subject of this article takes place in the High Republic era.',
		canon = true,
		link = 'High Republic Era'
	},
	fotj = {
		image = 'RepublicWhite.png|20px',
		tooltip = 'The subject of this article takes place in the Fall of the Jedi era.',
		canon = true,
		link = 'Republic Era'
	},
	rote = {
		image = 'BlackEmpire.png|20px',
		tooltip = 'The subject of this article takes place in the Reign of the Empire era.',
		canon = true,
		link = 'Imperial Era'
	},
	aor = {
		image = 'BlackRebelStarbird.png|20px',
		tooltip = 'The subject of this article takes place in the Age of Rebellion era.',
		canon = true,
		link = 'Galactic Civil War'
	},
	tnr = {
		image = 'NewRepubWhite.png|20px',
		tooltip = 'The subject of this article takes place in the New Republic era.',
		canon = true,
		link = 'New Republic Era'
	},
	rofo = {
		image = 'FirstOrderWhite.png|20px',
		tooltip = 'The subject of this article takes place in the Rise of the First Order era.',
		canon = true,
		link = 'First Order-Resistance War'
	},
	cnjo = {
		image = 'NJOWhite.png|20px',
		tooltip = 'The subject of this article takes place in the New Jedi Order era.',
		canon = true,
		link = 'New Jedi Order Era'
	},
	pre = {
		image = "Premium-Era-pre.png",
		tooltip = "The subject of this article takes place before the Before the Republic era.",
		canon = false,
		link = "Pre-Republic era"
	},
	btr = {
		image = "Premium-Era-pre.png",
		tooltip = "The subject of this article takes place in the Before the Republic era.",
		canon = false,
		link = "Before the Republic"
	},
	old = {
		image = "Premium-Era-old.png",
		tooltip = "The subject of this article takes place in the Old Republic era.",
		canon = false,
		link = "Old Republic era"
	},
	imp = {
		image = "Premium-Era-imp.png",
		tooltip = "The subject of this article takes place in the Rise of the Empire era.",
		canon = false,
		link = "Rise of the Empire era"
	},
	reb = {
		image = "Premium-Era-reb.png",
		tooltip = "The subject of this article takes place in the Rebellion era.",
		canon = false,
		link = "Rebellion era"
	},
	new = {
		image = "Premium-Era-new.png",
		tooltip = "The subject of this article takes place in the New Republic era.",
		canon = false,
		link = "New Republic era"
	},
	njo = {
		image = "Premium-Era-njo.png",
		tooltip = "The subject of this article takes place in the New Jedi Order era.",
		canon = false,
		link = "New Jedi Order era"
	},
	lgc = {
		image = "Premium-Era-leg.png",
		tooltip = "The subject of this article takes place in the Legacy era.",
		canon = false,
		link = "Legacy era"
	},
	inf = {
		image = "Premium-Era-inf.png",
		tooltip = "The subject of this article is considered part of Star Wars Infinities.",
		canon = false,
		link = "Infinities"
	},
	music = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		canon = false,
		doSort = false,
		link = "Category:Real-world music",
		category = "Real-world music"
	},
	real = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		canon = false,
		doSort = false,
		link = "Category:Real-world articles",
		category = "Real-world articles"
	},
	rwc = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		canon = false,
		doSort = true,
		link = "Category:Real-world companies",
		category = "Real-world companies"
	},
	rwp = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		canon = false,
		doSort = true,
		link = "Category:Real-world people",
		category = "Real-world people"
	},
	rwm = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		canon = false,
		doSort = true,
		link = "Category:Real-world media",
		category = "Real-world media"
	},
	audio = {
		image = "YouTube.svg|20px",
		tooltip = "Listen to an audio version of this article on Wookieepedia's official YouTube channel.",
		other = true,
		category = "Articles with audio counterparts"
	},
	fa = {
		image = "FA-Icon.svg",
		tooltip = "This is a Wookieepedia Featured Article.",
		other = true,
		link = "Wookieepedia:Featured articles",
		category = "Wookieepedia Featured articles"
	},
	ffa = {
		image = "FA-Former.svg",
		tooltip = "This is a former Wookieepedia Featured Article.",
		other = true,
		link = "Wookieepedia:Featured articles",
		category = "Wookieepedia former Featured articles"
	},
	pfa = {
		image = "FA-Review.svg",
		tooltip = "This is a Wookieepedia Featured Article on probation.",
		other = true,
		link = "Wookieepedia:Featured article reviews",
		category = "Wookieepedia Featured articles on probation"
	},
	ga = {
		image = "GA-Icon.svg",
		tooltip = "This is a Wookieepedia Good Article.",
		other = true,
		link = "Wookieepedia:Good articles",
		category = "Wookieepedia Good articles"
	},
	fga = {
		image = "GA-Former.svg",
		tooltip = "This is a former Wookieepedia Good Article.",
		other = true,
		link = "Wookieepedia:Good articles",
		category = "Wookieepedia former Good articles"
	},
	pga = {
		image = "GA-Review.svg",
		tooltip = "This is a Wookieepedia Good Article on probation.",
		other = true,
		link = "Wookieepedia:Good article reviews",
		category = "Wookieepedia Good articles on probation"
	},
	ca = {
		image = "CA-Icon.svg",
		tooltip = "This is a Wookieepedia Comprehensive Article.",
		other = true,
		link = "Wookieepedia:Comprehensive articles",
		category = "Wookieepedia Comprehensive articles"
	},
	fca = {
		image = "CA-Former.svg",
		tooltip = "This is a former Wookieepedia Comprehensive Article.",
		other = true,
		link = "Wookieepedia:Comprehensive articles",
		category = "Wookieepedia former Comprehensive articles"
	},
	pca = {
		image = "CA-Review.svg",
		tooltip = "This is a Wookieepedia Comprehensive Article on probation.",
		other = true,
		link = "Wookieepedia:Comprehensive article reviews",
		category = "Wookieepedia Comprehensive articles on probation"
	},
	fprot = {
		protectionAction = "edit",
		protectionLevel = "sysop",
		image = "Protect-F.svg",
		tooltip = "This page is protected from editing.",
		other = true,
		link = "Wookieepedia:Protection_policy#Full_protection",
		category = "Fully protected pages"
	},
	sprot = {
		protectionAction = "edit",
		protectionLevel = "autoconfirmed",
		image = "Protect-S.svg",
		tooltip = "This page is semi-protected.",
		other = true,
		link = "Wookieepedia:Protection_policy#Semi-protection",
		category = "Semi-protected pages"
	},
	ssprot = {
		image = "Protect-SS.svg",
		tooltip = "This page is super-semi-protected.",
		other = true,
		link = "Wookieepedia:Protection_policy#Super-semi-protection",
		category = "Super-semi-protected pages"
	},
	mprot = {
		protectionAction = "move",
		protectionLevel = "sysop",
		image = "Protect-M.svg",
		tooltip = "This page is move protected.",
		other = true,
		link = "Wookieepedia:Protection_policy#Move protection",
		category = "Move protected pages"
	},
	uprot = {
		protectionAction = "upload",
		protectionLevel = "sysop",
		image = "Protect-U.svg",
		tooltip = "This file is upload protected.",
		other = true,
		link = "Wookieepedia:Protection_policy#Upload protection",
		category = "Upload protected files"
	},
	noncanon = {
		image = "Premium-Era-inf.png",
		other = true,
		tooltip = "The subject of this article is considered non-canon."
	}
}

local SUFFIXES = {'Jr.', 'Jr', 'Jnr', 'Sr.', 'Sr', 'I', 'II', 'III', 'IV', 'V'}
local EXTRA = {'Al', "d'", 'Da', 'Dae', 'Dal', 'De', 'Del', 'Der', 'Di', 'Du', 'El', 'La', 'Le', 'St.', 'Van', 'Von'}

local function strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1"):gsub("[\n\r]", " ")
end

local function isItalicized(s, p, i)
	return s == "''{{PAGENAME}}''" or s == "''{{PAGENAME}}" or s == "''" .. p .. "''" or (i and s == p)
end

local function cleanCharacters(x) 
	return x:gsub('&#33;', "!"):gsub('&#34;', '"'):gsub('&#38;', "&"):gsub('&#39;', "'"):gsub('&#63;', "?"):gsub("&mdash;", "—"):gsub("&ndash;", "–"):gsub("{{'s}}", "'s")
end

local function compareTitles(d, b)
	local x = cleanCharacters(d):gsub("''", ""):gsub("{{'}}", "'"):gsub('<nowiki></nowiki>', ''):gsub('<span.*\">', ''):gsub('</span>', '')
	local y = b:gsub("''", "")
	return x ~= y and x ~= y:sub(0, 1):lower() .. y:sub(2)
end
	
local function splitAtLastString(s)
	local z = s:find(' [^ ]*$')
	if z then
		return strip(s:sub(0, z)), strip(s:sub(z))
	else
		return s, ''
	end
end

local function checkForExtra(f1, f2, ln)
	local fn = ''
	for _, y in ipairs(EXTRA) do
		if string.lower(f2) == string.lower(y) then
			fn = f1
			ln = f2 .. ' ' .. ln
		end
	end
	return fn, ln
end
	
local function determineNameSort(pagename, person)
	local base, paren = pagename:match('^(.*)%s*%((.-)%)$')
	if not base then
		base = pagename
	end
	
	base = strip(base)
	if person and not base:find(' ') then
		return pagename:gsub(',', ''):gsub('á', 'a'):gsub('é', 'e'):gsub('ë', 'e'):gsub('í', 'i'):gsub('ó', 'o'):gsub('ō', 'o'):gsub('ö', 'o'):gsub('ô', 'o'):gsub('ü', 'u'):gsub('ù', 'u'):gsub('ü', 'u'):gsub('ń', 'n'):gsub('š', 's'):gsub('Š', 'S'):gsub('Á', 'A'):gsub('É', 'E'):gsub('Ō', 'O')
	elseif person then
		base = base:gsub(',', ''):gsub('á', 'a'):gsub('é', 'e'):gsub('ë', 'e'):gsub('í', 'i'):gsub('ó', 'o'):gsub('ō', 'o'):gsub('ö', 'o'):gsub('ô', 'o'):gsub('ü', 'u'):gsub('ù', 'u'):gsub('ü', 'u'):gsub('ń', 'n'):gsub('š', 's'):gsub('Š', 'S'):gsub('Á', 'A'):gsub('É', 'E'):gsub('Ō', 'O')
		if base:find('"') then
			local _, c = string.gsub(base, ' ', '')
			if c > 1 then
				base = base:gsub('".*"', ''):gsub("  ", " ")
			end
		end
		local fn, ln = splitAtLastString(base)
		if ln then
			local f1, f2 = splitAtLastString(fn)
			local f3 = ''
			if f2 then
				for _, y in ipairs(SUFFIXES) do
					if ln == y then
						ln = f2
						f2 = ''
						f3 = y
					end
				end
			end
			fn = strip(f1 .. ' ' .. f2)
			
			local f4 = ''
			if fn:find(' ') then 
				local f1, f2 = splitAtLastString(fn)
				if f1 ~= nil and f2 ~= nil then
					f4, ln = checkForExtra(f1, f2, ln)
					if f4 ~= nil and f4 ~= '' then
						fn = f4
						if f4 ~= nil and f4:find(' ') then
							f1, f2 = splitAtLastString(fn)
							if f1 ~= nil and f2 ~= nil then
								f4, ln = checkForExtra(f1, f2, ln)
								if f4 ~= nil and f4 ~= '' then
									fn = f4
								end
							end
						end
					end
				end
			end
			local sortKey = strip(ln .. ', ' .. fn .. ' ' .. f3)
			if paren then
				sortKey = sortKey .. ' (' .. paren .. ')'
			end
			return strip(sortKey)
		end
	else
		local x = base:gsub(' ([0-9])$', " 0%1"):gsub(' ([0-9][0-9])$', " 0%1"):gsub(' ([0-9]):', " 0%1:")
		if x ~= base then
			return x
		end
	end
	return nil
end

-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

-- Find whether the specified page exists. We use pcall to catch errors if we
-- are over the expensive parser function count limit, or a number of other
-- juicy errors. This function increases the expensive parser function count
-- for every new page called.
local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local function clean(t)
	return t:gsub('/Legends', ''):gsub('/Canon', ''):gsub('"', ''):gsub(',', ''):gsub('-', ' '):gsub("'", ''):lower()
end

local function simpleClean(t)
	return t:gsub('/Legends', ''):gsub('/Canon', ''):lower()
end

local function hasValue(values, x)
	if values ~= nil and #values > 0 then
		for index, value in ipairs(values) do
	        if value == x then
	            return true
	        end
		end
	end
    return false
end

-------------------------------------------------------------------------------
-- Eras class
-------------------------------------------------------------------------------

-- The eras class does all of the heavy lifting in the module. We use a class
-- rather than normal functions so that we can avoid passing lots of different
-- values around for each different function.

local Eras = {}
Eras.__index = Eras -- Set up inheritance for tables that use Eras as a metatable.

-- This function makes a new eras object. Here we set all the values from the
-- arguments and do any preprocessing that we need.
function Eras.new(args, title)
	local obj = setmetatable({}, Eras) -- Make our object inherit from Eras.
	obj.title = title or mw.title.getCurrentTitle()

	-- Set object structure
	obj.categories = {}

	-- Set display title parameters
	obj.noDisplayTitle = args.notitle
	obj.displayTitleBase = args.title
	obj.displayTitleParen = args.title2
	obj.italics = args.italics
	obj.italics2 = args.italics2
	obj.nocat = args.nocat
	if args.sort then
		obj.sortKey = args.sort
	elseif args.sortKey then
		obj.sortKey = args.sortKey
	elseif args.sortkey then
		obj.sortKey = args.sortkey
	else 
		obj.sortKey = ''
	end
	obj.noSort = args.nosort
	obj.showSort = args.showSort or args.showsort
	obj.mobileImages = ''

	-- Set audio version link if present
	obj.audio = args.audio

	-- Set hidden status
	obj.isHidden = args.hide
	
	-- Set notoc value
	obj.hideToc = args.notoc

	-- Set canon and legends article names for the subject
	obj.legendsArticle = args.legends
	obj.canonArticle = args.canon
	obj.unmatched = args.unmatched
	obj.closeMatch = false
	obj.exactMatch = false
	obj.perfectMatch = false
	obj.special = false
	
	local pageTitle = mw.title.getCurrentTitle().text
	if args.canon then
		obj.sortKeyForCheck = args.canon .. '/Legends'
		obj.special = pageTitle:find('/Legends')
		obj.perfectMatch = simpleClean(pageTitle) == simpleClean(args.canon)
		obj.exactMatch = clean(pageTitle) == clean(args.canon)
		obj.closeMatch = clean(pageTitle):sub(0, 3) == clean(args.canon):sub(0, 3)
		if args.canon == pageTitle:gsub('/Legends', '') then
			table.insert(obj.categories, {category = 'Unnecessary canon/legends parameters in Template:Top', sortKey = pageTitle})
		end
	elseif args.legends then
		obj.sortKeyForCheck = pageTitle .. '/'
		obj.special = args.legends:find('/Legends')
		obj.perfectMatch = simpleClean(pageTitle) == simpleClean(args.legends)
		obj.exactMatch = clean(pageTitle) == clean(args.legends)
		obj.closeMatch = clean(pageTitle):sub(0, 3) == clean(args.legends):sub(0, 3)
		if args.legends == pageTitle .. '/Legends' then
			table.insert(obj.categories, {category = 'Unnecessary canon/legends parameters in Template:Top', sortKey = pageTitle})
		end
	end

	-- Get the icon data.
	do
		local icons = {}
		local counts = {}
		for _, v in ipairs(args) do
			local t = iconData[string.lower(v)]
			if t then
				icons[string.lower(v)] = t
				if counts[string.lower(v)] ~= nil then
					counts[string.lower(v)] = counts[string.lower(v)] + 1
				else
					counts[string.lower(v)] = 1
				end
			elseif string.lower(v) == 'ref' then
				icons['ref'] = {}
			else
				-- The specified icon wasn't found in the icon data, so set a
				-- tracking category flag.
				obj.hasBadParameter = true
			end
		end
		if obj.audio then
			local t = iconData["audio"]
			t.link = obj.audio
			icons["audio"] = t
		end
		obj.hasDuplicates = false
		for k, v in pairs(counts) do
			if v > 1 then
				obj.hasDuplicates = true
			end
		end
		
		obj.icons = icons
	end

	return obj
end

-- Raise an error. If DEBUG_MODE is set to false, then errors raised here
-- are caught by the export function p._main.
function Eras:raiseError(msg)
	local level
	if DEBUG_MODE then
		level = nil
	else
		level = 0 -- Suppress module name and line number in the error message.
	end
	error(msg, level)
end

-- Add a category, to be rendered at the very end of the template output.
function Eras:addCategory(cat, s)
	table.insert(self.categories, {category = cat, sortKey = s})
end

-- Shortcut method for getting an icon data subtable.
function Eras:getIconData(code)
	return self.icons[code]
end

-- Whether the current title ends with /Canon.
function Eras:hasCanonTitle()
	return self.title.text:find('/Canon$')
end

-- Whether the current title ends with /Legends.
function Eras:hasLegendsTitle()
	return self.title.text:find('/Legends$')
end
function Eras:hasLEGOTitle()
	return self.title.text:find('/LEGO$')
end

-- Returns a boolean showing whether any of the icons were specified by the
-- user.
function Eras:hasAnyOfIcons(...)
	for i = 1, select('#', ...) do
		if self:getIconData(select(i, ...)) then
			return true
		end
	end
	return false
end

function compareItalics(manual, actual, italics)
	local x = cleanCharacters(manual):gsub("—", "-"):gsub("–", "-"):gsub("'s ", "s ")
	local y = actual:gsub("—", "-"):gsub("–", "-"):gsub("'s ", "s ")
	return x == "''"..y or x == "''"..y.."''" or (italics and x == y)
end

function isManuallyItalicized(dBase, base, pagename, italics)
	if dBase == "''{{PAGENAME}}''" or dBase == "''{{PAGENAME}}" then
		return true
	elseif compareItalics(dBase, base, italics) then
		return true
	elseif pagename ~= base then
		return compareItalics(dBase, pagename, italics)
	end
	return false
end

-- Analyses the page name and sets {{DISPLAYTITLE}}.
function Eras:renderDisplayTitle()
	local pagename = self.title.text

	-- Exit if we have been told not to set a title or if the title begins with
	-- an opening parenthesis.
	if self.noDisplayTitle or pagename:find('^%(') then
		return nil
	end

	-- Find the display base and the display parentheses.
	local dBase = self.displayTitleBase
	local dParen = self.displayTitleParen
	local cat1, cat2 = '', ''
	if dBase and pagename:find('%(') then
		if isItalicized(dBase, pagename, true) then
			cat1 = '[[Category:Incorrect usage of title parameter in Template:Top]]'
		end
	end
	
	-- Analyse the pagename to find base part and any ending parentheses.
	-- /Canon is removed, and parentheses are only recognised if they are
	-- at the end of the pagename.
	local trimmedPagename = pagename:gsub('/Canon$', '')
	trimmedPagename = trimmedPagename:gsub('/Legends$', '')
	local original, paren = trimmedPagename:match('^(.*)%s*%((.-)%)$')
	if not original then
		original = trimmedPagename
	end
	local base = strip(original)
	if paren then
		paren = strip(paren)
	end
		
	if dBase and base and dBase == base then
		cat1 = cat1 .. '[[Category:Unnecessary title parameters in Template:Top]]'
	end
	if dParen and paren and dParen == paren then
		cat1 = cat1 .. '[[Category:Unnecessary title2 parameters in Template:Top]]'
	end
	
	if self.italics then
		base = "''" .. base .. "''"
	end
	if self.italics2 and paren then
		paren = "''" .. paren .. "''"
	end
	
	if dBase and isManuallyItalicized(dBase, base, pagename, self.italics) then
		cat2 = '[[Category:Manual italicization of title in Template:Top|' .. self.title.text .. ']]'
	elseif dBase and self.title.namespace == 0 and compareTitles(dBase, base) then
		local x = cleanCharacters(dBase):gsub("''", "")
		local y = base:gsub("''", "")
		cat2 = '[[Category:Incorrect title value in Template:Top|' .. self.title.text .. ']]' .. '<' .. x .. '>-<' .. y .. '>'
	end
		
	if dParen and paren and isItalicized(dParen, paren, self.italics2) then
		cat2 = '[[Category:Manual italicization of title2 in Template:Top|' .. self.title.text .. ']]'
	elseif dParen and paren and self.title.namespace == 0 and compareTitles(dParen, paren) then
		cat2 = '[[Category:Incorrect title value in Template:Top|' .. self.title.text .. ']]' .. '<' .. dParen:gsub("''", ""):gsub("PAGENAME", "PAGE NAME"):gsub("&", "") .. '>-<' .. paren:gsub("''", ""):gsub("&", "") .. '>'
	end
	
	-- Use the values we found, but only if a value has not already been
	-- specified.
	dBase = dBase or base
	dParen = dParen or paren
	
	local personSort = ''
	if self.sortKey ~= nil and self.sortKey ~= '' then
		cat2 = cat2 .. '\n[[Category:Manual sortkey parameter in Template:Top]]'
	end	
	if self:hasAnyOfIcons('rwp') then
		personSort = determineNameSort(pagename, true)
		if self.sortKey and self.sortKey == personSort then
			cat2 = cat2 .. '\n[[Category:Unnecessary manual sortkey parameter]]' 
		elseif self.sortKey ~= nil and self.sortKey ~= '' then
			cat2 = cat2 .. '\n[[Category:Differing sortkey values in Template:Top]]'
		else
			self.sortKey = personSort
		end
	end
	
	local sortText = ''
	local extra = ''
	if self.noSort then
		sortText = ''
	elseif self.sortKey ~= nil and self.sortKey ~= '' then
		sortText = '\n{{DEFAULTSORT:' .. self.sortKey .. '}}'
		if self.showSort then
			extra = extra .. '\n[' .. personSort .. ']=[' .. self.sortKey .. '] --> ' 
			if personSort == self.sortKey then
				extra = extra .. 'match'
			else
				extra = extra .. 'diff'
			end
		end
	elseif self:hasAnyOfIcons('rwm') then
		self.sortKey = determineNameSort(pagename, false)
		if original:match(" %d+$") and not hasValue(whitelist, pagename) then
			if self.italics then
				cat2 = cat2 .. '[[Category:Potential comic book italicization issues]]'
			elseif dBase and (isItalicized(dBase, base, self.italics) or dBase == dBase:gsub("''", "")) then
				cat2 = cat2 .. '[[Category:Potential comic book italicization issues]]'
			end
		end
	end

	-- Build the display string
	local display
	if dParen then
		display = string.format('%s <small>(%s)</small>', dBase, dParen)
	else
		display = dBase
	end
	if self.title.namespace ~= 0 then
		display = mw.site.namespaces[self.title.namespace].name .. ':' .. display
	end

	-- Return the expanded DISPLAYTITLE parser function.
	return mw.getCurrentFrame():preprocess(string.format(
		'{{DISPLAYTITLE:%s}}%s%s%s%s',
		display, sortText, cat1, cat2, extra
	))
end

-- Renders an eras icon from the given icon data. It deals with the image,
-- tooltip, link, and the category, but not the protection fields.
function Eras:renderIcon(data)
	-- Render the category at the end if it exists.
	if data.category and not mw.title.getCurrentTitle().text:find('/preload') then
		if data.doSort and self.sortKey and not self.noSort then
			self:addCategory(data.category, self.sortKey)
		elseif not self.nocat then
			self:addCategory(data.category, self.title.text)
		end
	end
	-- Render the icon and return it.
	local ret = {}
	ret[#ret + 1] = '[[File:'
	ret[#ret + 1] = data.image
	if data.tooltip then
		ret[#ret + 1] = '|'
		ret[#ret + 1] = data.tooltip
	end
	if data.link then
		ret[#ret + 1] = '|link='
		ret[#ret + 1] = data.link
	end
	ret[#ret + 1] = ']]'
	return table.concat(ret)
end

-- Renders a protection eras icon from the given data. If the page doesn't have
-- the specified protection level, returns nil and adds a flag to add a
-- tracking category later on in processing.
function Eras:renderProtectionIcon(data)
	if not data.protectionAction then
		return self:renderIcon(data)
	end
	local protectionLevel = self.title.protectionLevels[data.protectionAction]
	protectionLevel = protectionLevel and protectionLevel[1]
	if protectionLevel and protectionLevel == data.protectionLevel then
		return self:renderIcon(data)
	else
		self.hasIncorrectProtectionIcon = true
	end
end

-- Renders the first icon, either Canon or Legends, or nil if the continuity
-- couldn't be determined. This is equivalent to the previous {{Eraicon/canon}}
-- template.
function Eras:renderContinuityIcon()
	if self.sortKeyForCheck and math.fmod(self.title.namespace, 2) == 0 then
		if self.unmatched then
			self:addCategory('Differing article titles/Unmatched', self.title.text)
		elseif self.special then
			self:addCategory('Differing article titles/Special', self.sortKeyForCheck)
		elseif self.perfectMatch then
			self:addCategory('Differing article titles/Perfect', self.sortKeyForCheck)
		elseif self.exactMatch then
			self:addCategory('Differing article titles/Exact', self.sortKeyForCheck)
		elseif self.closeMatch then
			self:addCategory('Differing article titles/Similar', self.sortKeyForCheck)
		else
			self:addCategory('Differing article titles', self.sortKeyForCheck)
		end
	end

	-- First, find what continuity to use, if any.
	local continuity, isUsingCategory, nonCanon
	if self:hasAnyOfIcons('ncc', 'ncl') then
		nonCanon = true
	else
		nonCanon = false
	end
	if self:hasAnyOfIcons('leg', 'ncl') then
		continuity = 'legends'
		if self:hasAnyOfIcons('real', 'rwp', 'rwm', 'rwc', 'music') then
			isUsingCategory = false
		else
			isUsingCategory = true
		end
	elseif self.title.namespace == 0 then
		if self:hasLegendsTitle() then
			continuity = 'legends'
			isUsingCategory = true
		elseif self:hasCanonTitle() then
			continuity = 'canon'
			isUsingCategory = true
		elseif self.legendsArticle then
			continuity = 'canon'
			isUsingCategory = true
		elseif self.canonArticle then
			continuity = 'legends'
			isUsingCategory = true
		elseif self:hasAnyOfIcons('real', 'rwp', 'rwm', 'rwc', 'music') then
			if self:hasAnyOfIcons('can', 'ncc') or self:hasCanonEra() then
				continuity = 'canon'
			elseif self:hasAnyOfIcons('leg', 'ncl') or self:hasLegendsEra() then
				continuity = 'legends'
			end
			isUsingCategory = false
		elseif exists(self.title.text .. '/Legends') then
			continuity = 'canon'
			isUsingCategory = true
		elseif exists(self.title.text .. '/Canon') then
			continuity = 'legends'
			isUsingCategory = true
		elseif self:hasAnyOfIcons('can', 'ncc') or self:hasCanonEra() then
			continuity = 'canon'
			isUsingCategory = true
		elseif self:hasAnyOfIcons('leg', 'ncl') or self:hasLegendsEra() then
			continuity = 'legends'
			isUsingCategory = true
		elseif self:hasAnyOfIcons('inf', 'noncanon') then
			continuity = 'legends'
			isUsingCategory = false
		else
			continuity = 'canon'
			isUsingCategory = true
		end
	end

	-- Generate the icon data and make the icon.
	local data
	if continuity == 'canon' then
		if nonCanon then
			data = iconData['ncc']
			if isUsingCategory then
				data.category = 'Non-canon articles'
			elseif self:hasAnyOfIcons('rwm') then
				data.category = 'Non-canon media'
			end
		else
			data = iconData['can']
			if isUsingCategory then
				data.category = 'Canon articles'
			elseif self:hasAnyOfIcons('rwm') then
				data.category = 'Canon media'
			end
		end
		return self:renderIcon(data)
	elseif continuity == 'legends' then
		if nonCanon then
			data = iconData['ncl']
			if isUsingCategory then
				data.category = 'Non-canon Legends articles'
			elseif self:hasAnyOfIcons('rwm') then
				data.category = 'Non-canon Legends media'
			end
		else
			data = iconData['leg']
			if isUsingCategory then
				data.category = 'Legends articles'
			elseif self:hasAnyOfIcons('rwm') then
				data.category = 'Legends media'
			end
		end
		return self:renderIcon(data)
	end
end

function Eras:hasCanonEra(skip)
	return self:hasAnyOfIcons('dotj', 'tor', 'thr', 'fotj', 'rote', 'aor', 'tnr', 'rofo', 'cnjo')
end

function Eras:hasLegendsEra()
	return self:hasAnyOfIcons('pre', 'btr', 'old', 'imp', 'reb', 'new', 'njo', 'lgc')
end


function Eras:compileCanonPublishingIcons()
	return self:compilePublishingIcons({'dotj', 'tor', 'thr', 'fotj', 'rote', 'aor', 'tnr', 'rofo', 'cnjo'})
end

function Eras:compileLegendsPublishingIcons()
	return self:compilePublishingIcons({'pre', 'btr', 'old', 'imp', 'reb', 'new', 'njo', 'lgc', 'inf'})
end

function Eras:compilePublishingIcons(codes) 
	local ret = {}
	for _, code in ipairs(codes) do
		local data = self:getIconData(code)
		if data then
			ret[#ret + 1] = self:renderIcon(data)
		end
	end
	return table.concat(ret)
end

-- Renders the icons that respond to a publishing era.
function Eras:renderPublishingIcons()
	if self:hasAnyOfIcons('can', 'ncc') or self.legendsArticle or self:hasCanonTitle() or self:hasCanonEra() then
		return self:compileCanonPublishingIcons()
	elseif self:hasAnyOfIcons('leg', 'ncl') or self.canonArticle or self:hasLegendsTitle() or self:hasLegendsEra() then
		return self:compileLegendsPublishingIcons()
	end
end

-- Renders other icons, e.g. featured article status and protection status.
function Eras:renderNonPublishingIcons()
	local ret = {}
	local codes = {'real', 'rwp', 'rwm', 'rwc', 'music', 'audio', 'fa', 'ffa', 'ga', 'fga', 'ca', 'fca', 'pfa', 'pga', 'pca'}
	for _, code in ipairs(codes) do
		local data = self:getIconData(code)
		if data then
			ret[#ret + 1] = self:renderIcon(data)
		end
	end
	local protectionCodes = {'fprot', 'sprot', 'ssprot', 'mprot', 'uprot'}
	for _, code in ipairs(protectionCodes) do
		local data = self:getIconData(code)
		if data then
			ret[#ret + 1] = self:renderProtectionIcon(data)
		end
	end
	return table.concat(ret)
end

-- Render all the icons and eclose them in a surrounding div tag.
function Eras:renderIcons()
	local icons = {}
	icons[#icons + 1] = self:renderContinuityIcon()
	icons[#icons + 1] = self:renderPublishingIcons()
	icons[#icons + 1] = self:renderNonPublishingIcons()
	icons = table.concat(icons)
	self:addMaintenanceCategories()

	local root = mw.html.create('div')
	root
		:attr('id', 'title-eraicons')
		:css('float', 'right')
		:css('position', 'static')
		:css('display', 'none')
		:wikitext(icons)

	return tostring(root)
end


function Eras:addMaintenanceCategories()
	if self:hasAnyOfIcons('rwm') and not self:hasAnyOfIcons('ref') then
		if self:hasAnyOfIcons('can') and not self:hasCanonEra() then
			self:addCategory('Real-world canon articles missing eras parameters')
		end
		if self:hasAnyOfIcons('leg') and not self:hasLegendsEra() then
			self:addCategory('Real-world Legends articles missing eras parameters')
		end
	end
	if self.hasDuplicates then
		self:addCategory('Articles with duplicate parameters in Template:Top')
	end
end

-- Renders the Canon and Legends tabs for articles that are in both
-- continuities.
function Eras:renderCanonTab()
	if self.isHidden and self:hasLegendsTitle() then
		self:addCategory('Articles with hide parameter and /Legends or /Canon')
	elseif self.isHidden and self:hasCanonTitle() then
		self:addCategory('Articles with hide parameter and /Legends or /Canon')
	end
	
	if self:hasLEGOTitle() then
		self:addCategory('Articles with /LEGO')
	end
	
	if self.isHidden or self.title.namespace ~= 0 then
		-- Exit if we have been explicitly hidden or if we are not in the main
		-- namespace.
		return nil
	elseif self:hasAnyOfIcons('real', 'rwp', 'rwm', 'rwc', 'music') and not self.title.text:find('Timeline of ') then
		return nil
	end

	-- Find the page type, canon title, and legends title.
	local pageType, canonTitle, legendsTitle
	if self.legendsArticle then
		pageType = 'canon'
		canonTitle = self.title.text
		legendsTitle = self.legendsArticle
	elseif self.canonArticle then
		pageType = 'legends'
		canonTitle = self.canonArticle
		legendsTitle = self.title.text
	elseif self:hasCanonTitle() then
		pageType = 'canon'
		canonTitle = self.title.text
		legendsTitle = canonTitle:match('^(.*)/Canon$') or canonTitle
	elseif self:hasLegendsTitle() then
		pageType = 'legends'
		legendsTitle = self.title.text
		canonTitle = legendsTitle:match('^(.*)/Legends$') or legendsTitle
	elseif self:hasAnyOfIcons('real', 'rwp', 'rwm', 'rwc', 'music') then
		return nil
	elseif exists(self.title.text .. '/Legends') then
		pageType = 'canon'
		legendsTitle = self.title.text .. '/Legends'
		canonTitle = self.title.text
		if self:hasAnyOfIcons('leg') then
			self:addCategory('Legends subpages for Legends articles')
			return nil
		end
		
	elseif exists(self.title.text .. '/Canon') then
		pageType = 'legends'
		canonTitle = self.title.text .. '/Canon'
		legendsTitle = self.title.text
	else
		if self:hasAnyOfIcons('ncl') then
			self.mobileImages = '[[File:OnANONCANONArticle.png|150px|link=Star Wars Legends]]'
		elseif self:hasAnyOfIcons('ncc') then
			self.mobileImages = '[[File:OnANONCANONArticle.png|150px|link=Canon]]'
		elseif self:hasAnyOfIcons('leg') then
			self.mobileImages = "[[File:OnALegendsArticle.png|150px|link=Star Wars Legends]]"
		else
			self.mobileImages = "[[File:OnACanonArticle.png|150px|link=Canon]]"
		end
		-- Could not determine that the article has both a Canon and a Legends
		-- version, so exit.
		return nil
	end
	
	if self:hasCanonTitle() then
		self:addCategory('Articles with /Canon')
		if exists(self.title.text:gsub('/Canon', '/Legends')) and exists(self.title.text:gsub('/Canon', '')) then
			self:addCategory('Canon subpages with existing Legends subpages')
		end
	end

	-- Add categories.
	if pageType == 'canon' then
		self.mobileImages ="[[File:OnACanonArticle.png|150px|link=Canon]][[File:GoToLegends.png|150px|link=" .. legendsTitle .. "]]"
		self:addCategory('Canon articles with Legends counterparts')
	elseif pageType == 'legends' then
		self.mobileImages ="[[File:OnALegendsArticle.png|150px|link=Star Wars Legends|]][[File:GoToCanon.png|150px|link=" .. canonTitle .. "]]"
		self:addCategory('Legends articles with canon counterparts')
	else
		self:addCategory('Outliers')
	end
	

	-- Make the table root.
	local root = mw.html.create('table')
	root
		:attr('id', 'canontab')
		:css('text-align', 'center')
		:css('padding', '0')
		:css('margin', '0 0 5px 0')
		:css('border-left', '0')
		:css('border-right', '0')
		:css('border-top', '0')
		:css('border-bottom', '0')
		:css('border-spacing', '0')
		:css('border-collapse', 'collapse')
		:css('width', '100%')
		:css('vertical-align', 'top')

	local row = root:tag('tr')

	-- This makes one Canon/Legends cell. Having this as a function rather than
	-- doing it with chaining allows us to avoid putting the same code in twice.
	local function makeCell(id, color, image, link, tooltip)
		local cell = mw.html.create('td')
		cell
			:attr('id', id)
			:css('padding', '5px 0 5px 0')
			:css('background-color', color)
			:css('line-height', '0.95em')
			:css('font-size', '150%')
			:css('font-weight', 'bold')
			:css('border-bottom', '3px solid #002e54')
			:css('min-width', '170px')
			:css('vertical-align', 'top')
			:css('border-radius', '5px 5px 0 0')
			:wikitext(string.format(
				' [[File:%s|link=%s|%s]]',
				image, link, tooltip
			))
		return cell
	end

	local foregroundColor = '#002e54'
	local backgroundColor = '#d8e9fc'

	-- Make the canon cell.
	do
		local link = canonTitle
		local color, image, tooltip
		if pageType == 'canon' then
			id = 'canontab-canon_ctcw'
			color = foregroundColor
			image = 'Tab-canon-white.png'
			tooltip = 'This article covers the Canon version of this subject.'
		else
			id = 'canontab-canon_ctcb'
			color = backgroundColor
			image = 'Tab-canon-black.png'
			tooltip = "Click here for Wookieepedia's article on the Canon " ..
				"version of this subject."
		end
		row:node(makeCell(id, color, image, link, tooltip))
	end

	-- First separator cell
	row:tag('td')
		:attr('id', 'canontab-separator1')
		:css('width', '3px')
		:css('border-bottom', '3px solid #002e54')
		:wikitext('&nbsp;')
	
	-- Make the legends cell
	do
		local link = legendsTitle
		local color, image, tooltip
		if pageType ~= 'canon' then -- is a Legends page
			id = 'canontab-legends_ctlw'
			color = foregroundColor
			image = 'Tab-legends-white.png'
			tooltip = 'This article covers the Legends version of this subject.'
		else -- is a Canon page
			id = 'canontab-legends_ctlb'
			color = backgroundColor
			image = 'Tab-legends-black.png'
			tooltip = "Click here for Wookieepedia's article on the Legends " ..
				"version of this subject."
		end
		row:node(makeCell(id, color, image, link, tooltip))
	end
	
	-- Second separator cell
	row:tag('td')
		:attr('id', 'canontab-separator2')
		:css('width', '3000px')
		:wikitext('&nbsp;')
	
	return tostring(root)
end

-- Render all the categories that were specified using Eras:addCategory or with
-- category flags.
function Eras:renderCategories()
	local fullPagename = self.title.prefixedText
	if fullPagename == 'Template:Eras' then
		-- Exit if we are on a blacklisted page.
		return nil
	end

	local pagename = self.title.text

	-- Renders one category.
	local function renderCategory(cat, s)
		if s ~= nil and s ~= '' then
			return string.format(
				'[[%s:%s|%s]]', 'Category', cat, s or pagename
			)
		else
			return '[[Category:' .. cat .. ']]'
		end
	end

	local ret = {}

	if self.title.namespace ~= 2 then
	-- Render categories from Eras:addCategory
		for i, t in ipairs(self.categories) do
			ret[i] = renderCategory(t.category, t.sortKey)
		end
	end

	-- Render categories from category flags.
	if self.hasBadParameter then
		ret[#ret + 1] = renderCategory(
			'Pages with bad parameters in Template:Top'
		)
	end
	if self.hasIncorrectProtectionIcon then
		ret[#ret + 1] = renderCategory(
			'Pages with incorrect protection icons'
		)
	end

	return table.concat(ret)
end

-- Add __NOTOC__ if needed
function Eras:renderNotoc()
	if self.hideToc then
		return '__NOTOC__'
	end
	return nil
end

-- This method is called when the tostring function is used on the Eras object.
-- (This works in a similar fashion to Eras.__index above.) It calls all the
-- top-level render methods and returns the final output.
function Eras:__tostring()
	local ret = {}
	ret[#ret + 1] = self:renderDisplayTitle()
	ret[#ret + 1] = self:renderIcons()
	ret[#ret + 1] = self:renderCanonTab()
	ret[#ret + 1] = self:renderCategories()
	ret[#ret + 1] = self:renderNotoc()
	if self.mobileImages ~= nil and self.mobileImages ~= "" then
		ret[#ret + 1] = '<span class="mobileTopIcons">' .. self.mobileImages .. '</span>'
	end
	return table.concat(ret)
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

local p = {}

-- This function is the entry point from other Lua modules.
function p._main(args)
	-- Define a function to call from pcall so that we can catch any errors
	-- and display them to the user rather than the cryptic "Script error".
	-- (It's not so cryptic if you click on it to see the error message, but
	-- not so many users know to do that.)
	local function getErasResult ()
		local erasObj = Eras.new(args)
		-- Temporary hack to hide ugly error message on LEGO articles
		if erasObj == false then
			return '[[' .. 'Category:Pages with bad parameters in Template:Top]]'
		end
		return tostring(erasObj)
	end
	
	if mw.title.getCurrentTitle().text == "UnusedPages" or mw.title.getCurrentTitle().text == "UnusedPreloads" then
		return ''
	end

	-- Get the result. We only catch errors if debug mode is set to false.
	local success, result
	if DEBUG_MODE then
		success = true
		result = getErasResult()
	else
		success, result = pcall(getErasResult)
	end

	-- Return the result if there were no errors, and a formatted error message 
	-- if there were.
	if success then
		return result
	else
		return string.format(
			'<strong class="error">[[Template:Eras]] error: %s.</strong>' ..
			'[[' .. 'Category:Pages with bad parameters in Template:Top]]',
			result -- this is the error message
		)
	end
end

-- This is the function accessed from wikitext. It must be accessed through
-- a template. The template should transclude only the text
-- "{{#invoke:Eras|main}}", and then when that template is used, any arguments
-- passed to it are magically sent through to the module.
function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p

-- </nowiki>
-- [[Category:Eras utility templates|{{PAGENAME}}]]