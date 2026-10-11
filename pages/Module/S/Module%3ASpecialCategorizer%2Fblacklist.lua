-- This is a blacklist for [[Module:SpecialCategorizer]]. It is loaded
-- with mw.loadData, which means it is only processed once per page rather than
-- once per template.

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

local function isBlacklisted()
	local pagename = mw.title.getCurrentTitle().prefixedText
	local ret = {}
	for _, pattern in ipairs(blacklist) do
		if mw.ustring.find(pagename, pattern) then
			return true
		end
	end
	return false
end

local function isFullyBlacklisted()
	local pagename = mw.title.getCurrentTitle().prefixedText
	local ret = {}
	for _, pattern in ipairs(blacklist2) do
		if mw.ustring.find(pagename, pattern) then
			return true
		end
	end
	return false
end

return {
	isBlacklisted = isBlacklisted(),
	isFullyBlacklisted = isFullyBlacklisted()
}