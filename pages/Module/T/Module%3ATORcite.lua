-- This module implements [[Template:TORcite]].

local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]] §', 'Category', cat)
end

local function makeWikitextError(msg)
	local ret = ''
	ret = ret .. string.format(
		'<strong class="error">[[Template:TORcite]] error: %s.</strong>',
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
	local game = "Star Wars: The Old Republic"
	if args.exp then
		game = data.expansions[args.exp]
	end
	
	local image = "[[File:SWTOR_mini.png|text-top|x16px|link=" .. game .. "]] "
	
	local src = ''
	local invalid = false
	local missingType = false
	if args.chapter then
		local chap = tonumber(args.chapter)
		if not chap then
			src = args[1] or '{{{1}}}'
		else
			if args.exp then
				src = data.chapters[args.exp][chap]
			else
				src = data.chapters.kotfe[chap]
			end
		end
	else		
		local mode = data.modes[string.lower(args.type or '')]
		if not mode then
			src = args[1] or '{{{1}}}'
			if args.exp then
				missingType = true
			end
		elseif string.lower(args.type) == 'location' and not args[2] then
			src = check(args[1])
		else
			src = check(mode.a) .. check(args[1]) .. check(mode.b) .. check(args[2]) .. check(mode.c) .. check(args[3])
			
			if check(mode.c) == '' and check(args[3]) ~= '' then
				invalid = true
			end
		end
	end
	
	local result = image .. "''[[" .. game .. "]]'' &mdash; " .. src
	if invalid or missingType then
		result = result .. makeCategoryLink("Invalid TORcite parameter arguments")
	end
	if not args.exp and mw.title.getCurrentTitle().namespace ~= 2 then
		if check(args[2]) and has_value(data.planetChecks, args[2]) then
			result = result .. makeCategoryLink("TORcite usages missing expansion argument")
		end
		if check(args[3]) and has_value(data.planetChecks, args[3]) then
			result = result .. makeCategoryLink("TORcite usages missing expansion argument")
		end
		if check(args[1]) and has_value(data.flashpointChecks, args[1]) then
			result = result .. makeCategoryLink("TORcite usages missing expansion argument")
		end
		if check(args[1]) and has_value(data.operationChecks, args[1]) then
			result = result .. makeCategoryLink("TORcite usages missing expansion argument")
		end
		if check(args.type) == 'tactical' then
			result = result .. makeCategoryLink("TORcite usages missing expansion argument")
		end
	end
	return result
end

function p.main(frame)
	local data = mw.loadData('Module:TORcite/data')
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