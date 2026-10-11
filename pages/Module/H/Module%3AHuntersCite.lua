-- This module implements [[Template:HuntersCite]].

local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]] §', 'Category', cat)
end

local function makeWikitextError(msg)
	local ret = ''
	ret = ret .. string.format(
		'<strong class="error">[[Template:HuntersCite]] error: %s.</strong>',
		msg
	)
	if mw.title.getCurrentTitle().namespace == 0 then
		ret = ret .. makeCategoryLink('Articles with template errors')
	end
	return ret
end

local function check(str)
	if str == nil then
		str = ""
	end
	return str
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
		
function p.citation(args, data)
	local game = "Star Wars: Hunters"
	local mode = data.modes[args.type]
	
	local src = mode.a

	local image = "[[File:StarWarsHunters-Logo.png|text-top|x16px|link=" .. game .. "]] "

	local invalid = false
	local missingType = false
	local bonus = ''

	local result = image .. "''[[" .. game .. "]]'' &mdash; " .. src .. args.name
	if invalid or missingType then
		result = result .. makeCategoryLink("Invalid HuntersCite parameter arguments")
	end
	return result
end

function p.main(frame)
	local data = mw.loadData('Module:HuntersCite/data')
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