-- This module implements [[Template:SpecialCategorizer]].

local p = {}

local blacklist = {
	-- Don't categorize the following pages.
	'^Template:UnusedPage$',
	'^Template:UnusedPreloads$',
	'^Template:TOR updates$',
	'^Template:FFG$',
	'^Template:Multiple issues$',
	'^Template:Stub box$',
	'^Template:.*stub$',

	-- Don't categorize subpages of the following pages.
	'^Wookieepedia:Userbox proposal/',
	'^Wookieepedia:Template messages/',
	'^Wookieepedia:Templates/',
	'Wookieepedia:WookieeProjects/Templates'
}

local blacklist2 = {
	'^Wookieepedia:.* article nominations/',
	'^Wookieepedia:.* article reviews/',
	'^Forum:',
	'^Talk:',
	'^.* talk:'
}

local function matchList(values, s)
	for _, pattern in ipairs(values) do
		if mw.ustring.find(s, pattern) then
			return true
		end
	end
	return false
end

function p._main(value, simple, full)
	local page = mw.title.getCurrentTitle()
	local skip = false
	if simple ~= nil and simple ~= "" then
		skip = page.namespace ~= 0 and page.namespace ~= 6 and page.namespace ~= 120
	else
		skip = matchList(blacklist, page.prefixedText)
		if not skip and full ~= nil and full ~= "" then
			skip = matchList(blacklist2, page.prefixedText)
		end
	end
	if skip then
		return ''
	end
	return value or ''
end

function p.main(frame)
	return p._main(frame.args.value, frame.args.simple, frame.args.full)
end

return p