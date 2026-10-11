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
		link = 'Canon'
	},
	leg = {
		image = 'Premium-Eras-legends.png',
		tooltip = 'This article details a subject that falls under the Legends brand.',
		link = 'Star Wars Legends'
	},
	pre = {
		image = "Premium-Era-pre.png",
		tooltip = "The subject of this article appeared before the Before the Republic era.",
		link = "Pre-Republic era"
	},
	btr = {
		image = "Premium-Era-pre.png",
		tooltip = "The subject of this article appeared Before the Republic.",
		link = "Before the Republic"
	},
	old = {
		image = "Premium-Era-old.png",
		tooltip = "The subject of this article appeared in the Old Republic era.",
		link = "Old Republic era"
	},
	imp = {
		image = "Premium-Era-imp.png",
		tooltip = "The subject of this article appeared in the Rise of the Empire era.",
		link = "Rise of the Empire era"
	},
	reb = {
		image = "Premium-Era-reb.png",
		tooltip = "The subject of this article appeared in the Rebellion era.",
		link = "Rebellion era"
	},
	new = {
		image = "Premium-Era-new.png",
		tooltip = "The subject of this article appeared in the New Republic era.",
		link = "New Republic era"
	},
	njo = {
		image = "Premium-Era-njo.png",
		tooltip = "The subject of this article appeared in the New Jedi Order era.",
		link = "New Jedi Order era"
	},
	lgc = {
		image = "Premium-Era-leg.png",
		tooltip = "The subject of this article appeared in the Legacy era.",
		link = "Legacy era"
	},
	inf = {
		image = "Premium-Era-inf.png",
		tooltip = "The subject of this article is considered part of Star Wars Infinities.",
		link = "Infinities"
	},
	real = {
		image = "Premium-Era-real.png",
		tooltip = "The subject of this article exists in or is relevant to the real world.",
		link = "Category:Real-world articles",
		category = "Real-world articles"
	},
	audio = {
		image = "Youtube-top.png|20px",
		tooltip = "Listen to an audio version of this article on Wookieepedia's official YouTube channel.",
		category = "Articles with audio counterparts"
	},
	fa = {
		image = "Premium-FeaturedIcon.png",
		tooltip = "This is a Wookieepedia Featured Article.",
		link = "Wookieepedia:Featured articles",
		category = "Wookieepedia Featured articles"
	},
	ffa = {
		image = "Premium-DefeaturedIcon.png",
		tooltip = "This is a former Wookieepedia Featured Article.",
		link = "Wookieepedia:Featured articles",
		category = "Wookieepedia former Featured articles"
	},
	ga = {
		image = "Premium-GoodIcon.png",
		tooltip = "This is a Wookieepedia Good Article.",
		link = "Wookieepedia:Good articles",
		category = "Wookieepedia Good articles"
	},
	fga = {
		image = "Premium-FormerGAicon.png",
		tooltip = "This is a former Wookieepedia Good Article.",
		link = "Wookieepedia:Good articles",
		category = "Wookieepedia former Good articles"
	},
	ca = {
		image = "Premium-ComprehensiveArticle.png",
		tooltip = "This is a Wookieepedia Comprehensive Article.",
		link = "Wookieepedia:Comprehensive articles",
		category = "Wookieepedia Comprehensive articles"
	},
	fca = {
		image = "Premium-FormerCAIcon.png",
		tooltip = "This is a former Wookieepedia Comprehensive Article.",
		link = "Wookieepedia:Comprehensive articles",
		category = "Wookieepedia former Comprehensive articles"
	},
	fprot = {
		protectionAction = "edit",
		protectionLevel = "sysop",
		image = "Premium-Era-Fprotect.png",
		tooltip = "This article is protected from editing.",
		link = "Wookieepedia:Protection_policy#Full_protection",
		category = "Protected"
	},
	sprot = {
		protectionAction = "edit",
		protectionLevel = "autoconfirmed",
		image = "Premium-Era-Sprotect.png",
		tooltip = "This article is semi-protected.",
		link = "Wookieepedia:Protection_policy#Semi-protection",
		category = "Semi-protected articles"
	},
	ssprot = {
		image = "Premium-Era-Ssprotect.png",
		tooltip = "This article is super-semi-protected.",
		link = "Wookieepedia:Protection_policy#Super-semi-protection",
		category = "Super-semi-protected articles"
	},
	mprot = {
		protectionAction = "move",
		protectionLevel = "sysop",
		image = "Premium-Era-Mprotect.png",
		tooltip = "This article is move protected.",
		link = "Wookieepedia:Protection_policy#Move protection",
		category = "Move protected articles"
	},
	uprot = {
		protectionAction = "upload",
		protectionLevel = "sysop",
		image = "Premium-Era-Uprotect.png",
		tooltip = "This file is upload protected.",
		link = "Wookieepedia:Protection_policy#Upload protection",
		category = "Upload protected files"
	},
	noncanon = {
		image = "Premium-Era-inf.png",
		tooltip = "The subject of this article is considered non-canon."
	}
}

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

	-- Set audio version link if present
	obj.audio = args.audio

	-- Set hidden status
	obj.isHidden = args.hide
	
	-- Set notoc value
	obj.hideToc = args.notoc

	-- Set canon and legends article names for the subject
	obj.legendsArticle = args.legends
	obj.canonArticle = args.canon
	
	if args.canon then
		obj.check = true
	end

	-- Get the icon data.
	do
		local icons = {}
		for _, v in ipairs(args) do
			local t = iconData[string.lower(v)]
			if t then
				icons[string.lower(v)] = t
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
function Eras:addCategory(cat, sort)
	table.insert(self.categories, {category = cat, sortKey = sort})
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
	if not dBase or not dParen then
		-- Analyse the pagename to find base part and any ending parentheses.
		-- /Canon is removed, and parentheses are only recognised if they are
		-- at the end of the pagename.
		local trimmedPagename = pagename:gsub('/Canon$', '')
		trimmedPagename = trimmedPagename:gsub('/Legends$', '')
		local base, paren = trimmedPagename:match('^(.*)%s*%((.-)%)$')
		if not base then
			base = trimmedPagename
		end
		-- Use the values we found, but only if a value has not already been
		-- specified.
		dBase = dBase or base
		dParen = dParen or paren
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
		'{{DISPLAYTITLE:%s}}',
		display
	))
end

-- Renders an eras icon from the given icon data. It deals with the image,
-- tooltip, link, and the category, but not the protection fields.
function Eras:renderIcon(data)
	-- Render the category at the end if it exists.
	if data.category then
		self:addCategory(data.category)
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
	if self.check then
		self:addCategory('Differing article titles')
	end

	-- First, find what continuity to use, if any.
	local continuity, isUsingCategory
	if self:hasAnyOfIcons('leg') then
		continuity = 'legends'
		if not self:hasAnyOfIcons('real') then
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
		elseif exists(self.title.text .. '/Legends') then
			continuity = 'canon'
			isUsingCategory = true
		elseif exists(self.title.text .. '/Canon') then
			continuity = 'legends'
			isUsingCategory = true
		elseif self:hasAnyOfIcons('pre', 'btr', 'old', 'imp', 'reb', 'new',
			'njo', 'lgc')
		then
			continuity = 'legends'
			if self:hasAnyOfIcons('real') then
				isUsingCategory = false
			else
				isUsingCategory = true
			end
		elseif self:hasAnyOfIcons('inf', 'noncanon') then
			continuity = 'legends'
			isUsingCategory = false
		elseif self:hasAnyOfIcons('real') then
			if self:hasAnyOfIcons('can') then
				continuity = 'canon'
			end
			isUsingCategory = false
		else
			continuity = 'canon'
			isUsingCategory = true
		end
	end

	-- Generate the icon data and make the icon.
	if continuity == 'canon' then
		local data = iconData['can']
		if isUsingCategory then
			data.category = 'Canon articles'
		end
		return self:renderIcon(data)
	elseif continuity == 'legends' then
		local data = iconData['leg']
		if isUsingCategory then
			data.category = 'Legends articles'
		end
		return self:renderIcon(data)
	end
end

-- Renders the icons that respond to a publishing era.
function Eras:renderPublishingIcons()
	if not self:hasAnyOfIcons('can')
		and not self.legendsArticle
		and not self:hasCanonTitle()
	then
		local ret = {}
		local codes = {'pre', 'btr', 'old', 'imp', 'reb', 'new', 'njo', 'lgc', 'inf'}
		for _, code in ipairs(codes) do
			local data = self:getIconData(code)
			if data then
				ret[#ret + 1] = self:renderIcon(data)
			end
		end
		return table.concat(ret)
	end
end

-- Renders other icons, e.g. featured article status and protection status.
function Eras:renderNonPublishingIcons()
	local ret = {}
	local codes = {'real', 'audio', 'fa', 'ffa', 'ga', 'fga', 'ca', 'fca'}
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

	local root = mw.html.create('div')
	root
		:attr('id', 'title-eraicons')
		:css('float', 'right')
		:css('position', 'static')
		:css('display', 'none')
		:wikitext(icons)

	return tostring(root)
end

-- Renders the Canon and Legends tabs for articles that are in both
-- continuities.
function Eras:renderCanonTab()
	if self.isHidden or self.title.namespace ~= 0 then
		-- Exit if we have been explicitly hidden or if we are not in the main
		-- namespace.
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
	elseif exists(self.title.text .. '/Legends') then
		pageType = 'canon'
		legendsTitle = self.title.text .. '/Legends'
		canonTitle = self.title.text
	elseif exists(self.title.text .. '/Canon') then
		pageType = 'legends'
		canonTitle = self.title.text .. '/Canon'
		legendsTitle = self.title.text
	else
		-- Could not determine that the article has both a Canon and a Legends
		-- version, so exit.
		return nil
	end
	
	if self:hasCanonTitle() then
		self:addCategory('Articles with /Canon')
	end

	-- Add categories.
	if pageType == 'canon' then
		self:addCategory('Canon articles with Legends counterparts')
	elseif pageType == 'legends' then
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
	local function renderCategory(cat, sort)
		return string.format(
			'[[%s:%s|%s]]', 'Category', cat, sort or pagename
		)
	end

	local ret = {}

	-- Render categories from Eras:addCategory
	for i, t in ipairs(self.categories) do
		ret[i] = renderCategory(t.category, t.sortKey)
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