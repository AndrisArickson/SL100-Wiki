-- This module implements [[Template:SWGcite]].

local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

local function makeWikitextError(msg)
	local ret = ''
	ret = ret .. string.format(
		'<strong class="error">[[Template:SWGcite]] error: %s.</strong>',
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
	local game = "Star Wars Galaxies"
	if args.exp == "SK" then
		game = data.expansions["NGE"]
	elseif args.exp then
		game = data.expansions[args.exp]
	end
	local image = "[[File:SWG_logo_sm.png|text-bottom|x18px|link=Star Wars Galaxies]] "
	
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
		local mode = data.modes[args.type]
		if not mode then
			src = args[1] or '{{{1}}}'
			if args.exp then
				missingType = true
			end
		else
			src = check(mode.a) .. check(args[1]) .. check(mode.b) .. check(args[2]) .. check(mode.c) .. check(args[3])
			
			if check(mode.c) == '' and check(args[3]) ~= '' then
				invalid = true
			end
		end
	end
	
	local result = image .. "" .. game .. " &mdash; " .. src
	if invalid then
		result = result .. makeCategoryLink("SWGcite invalid usages")
	end
	if missingType then
		result = result .. makeCategoryLink("SWGcite usages without type")
	end
	if not args.exp then
		if check(args.type) == 'tactical' then
			result = result .. makeCategoryLink("SWGcite usages missing expansion argument")
		end
	end
	return result
end

function p.main(frame)
	local data = mw.loadData('Module:SWGcite/data')
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