-- <nowiki>
-- This module implements [[Template:FacebookCite]].
-- {{Delete|obsolete in favor of regular template code}}

local p = {}
local lang = mw.language.getContentLanguage()
local currentTitle = mw.title.getCurrentTitle()

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

local function makeWikitextError(msg)
	local ret = ''
	ret = ret .. string.format(
		'<strong class="error">[[Template:FacebookCite]] error: %s.</strong>',
		msg
	)
	if currentTitle.namespace == 0 then
		ret = ret .. makeCategoryLink('Pages with template parameter errors')
	end
	return ret
end

local function formatDate(format, date)
	local success, date = pcall(lang.formatDate, lang, format, date)
	if success then
		return date
	end
end

local function makeLinkedDate(date)
	return formatDate('[[F j]], [[Y]]', date)
end

local function formatDateAndTime(date, time)
	date = makeLinkedDate(date)
	if not date then
		return nil
	end

	if time then
		time = formatDate('g:i a', time)
		if not time then
			return nil
		end
	end

	if time then
		time = string.format(',&nbsp;%s', time)
	else
		time = ''
	end

	return date .. time
end

local function makeArchiveLink(archive, description)
	if archive:find('^http') then
		return string.format('[%s %s]', archive, description)
	else
		return string.format('[[:File:%s|%s]]', archive, description)
	end
end

function p._main(args)
	-- Validate parameters that are always needed
	if not args.description then
		return makeWikitextError(
			"the 'description' parameter must be specified"
		)
	end

	local ret = {}

	-- Shortcut function for adding new strings
	local function add(val)
		ret[#ret + 1] = val
	end

	-- Facebook icon
	add('[[File:Facebook_icon.svg|14px|link=https://facebook.com]]&nbsp;')

	-- Start citation details. If a userpage was specified, we ignore the other
	-- citation details.
	if args.userpage then
		add(string.format(
			'[https://www.facebook.com/%s %s] on [https://www.facebook.com/ Facebook]',
			args.userpage, args.description
		))
	else
		-- Validate parameters that are only required if args.userpage is not
		-- set.
		if not args.author or not args.dateposted then
			return makeWikitextError(
				"if the 'userpage' parameter is not set, parameters " ..
				"'author' and 'dateposted' must be specified"
			)
		elseif not args.link and not args.archive then
			return makeWikitextError(
				"if the 'userpage' parameter is not set, either 'link' or " ..
				"'archive' must be specified"
			)
		end

		-- Link or archive link
		if args.link then
			add(string.format(
				'[https://www.facebook.com/%s %s].',
				args.link, args.description
			))
		elseif args.archive then
			add(makeArchiveLink(args.archive, args.description) .. '.')
		end

		-- Author
		add(' ')
		add(args.author)

		-- Date posted
		do
			local date = formatDateAndTime(args.dateposted)
			if date then
				add(string.format(' (%s).', date))
			else
				return makeWikitextError(
					"invalid date in parameter 'dateposted'"
				)
			end
		end

		-- Date accessed
		if args.dateaccessed then
			local date = formatDateAndTime(args.dateaccessed)
			if date then
				add(string.format(' Retrieved on %s.', date))
			else
				return makeWikitextError(
					"invalid date in parameter 'dateaccessed'"
				)
			end
		end

		-- Quote
		if args.quote then
			add(string.format(' "%s"', args.quote))
		end

		-- Archive
		if args.link and args.archive then
			local archive = makeArchiveLink(args.archive, 'archive copy')
			if args.archivedate then
				local date = makeLinkedDate(args.archivedate)
				if not date then
					return makeWikitextError(
						"invalid date in parameter 'archivedate'"
					)
				end
				archive = archive .. ' created on ' .. date
			end
			add(string.format(' <small>(%s)</small>', archive))
		elseif args.archivedate and not args.link then
			local date = makeLinkedDate(args.archivedate)
			if not date then
				return makeWikitextError(
					"invalid date in parameter 'archivedate'"
				)
			end
			add(string.format(
				' <small>(archive copy created on %s)</small>',
				date
			))
		end
	end

	-- Image
	if args.image then
		add(string.format(' <small>([[:%s|screenshot]])</small>', args.image))
	end
	if args.noimage then
		add(string.format(' <small>(Content no longer available)</small>'))
	end

	-- Screenshot tracking category
	if not args.userpage 
		and not args.archive 
		and not args.image
		and not args.noimage
		and currentTitle.namespace == 0
	then
		add('[[Category:Social media citations without screenshots]]')
	end

	return table.concat(ret)
end

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