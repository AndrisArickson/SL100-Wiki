local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local function yes(v)
	return v ~= nil and v ~= ""
end

local function isCanon(title)
	if title.text:find('/Legends') then
		return 'false'
	elseif title.text:find('/Canon') then
		return 'true'
	elseif exists(title.text..'/Canon') then
		return 'false'
	end
	
    for index, v in ipairs(title.categories) do
    	if v == "Non-canon Legends articles" or v == "Legends cut content" then
    		return 'ncl'
        elseif v == "Legends articles" or v == "Articles from unlicensed sources" then
            return 'false'
        elseif v == "Non-canon articles" or v:sub(0, 11) == "Cut content" then
        	return '*'
        elseif v == "Canon articles" then
        	return 'true'
        end
    end
    return 'true'
end

function separateLines(txt)
	lines = {}
	if txt:find("\r\n") == nil then
		table.insert(lines, txt)
		return lines
	end
	
	for s in txt:gmatch("[^\r\n]+") do
		if s ~= nil then
			if s:find("<ref") ~= nil then
				table.insert(lines, s:sub(0, s:find("<ref") - 1))
			else
				table.insert(lines, s)
			end
		end
	end
	return lines
end

local function char(num)
  return string.char(string.byte("A")+num-1)
end

local function isUnlicensed(page)
	for index, v in ipairs(page.categories) do
        if v == "Articles from unlicensed sources" then
            return true
        end
	end
	return false
end

REGION_ORDER = {
	["Deep Core"] = "0",
	["Hutt Space"] = "7",
	["Wild Space"] = "8",
	["Unknown Regions"] = "9",
	["Core Worlds"] = "1",
	["Colonies"] = "2",
	["Inner Rim"] = "3",
	["Expansion Region"] = "4",
	["Mid Rim"] = "5",
	["Outer Rim"] = "6",
}

local function determineSorting(val)
	for k, v in pairs(REGION_ORDER) do
		if val:find(k) then
			return "|"..v
		end
	end
	return ""
end

local function checkSector(val)
	local CHECK_SECTORS = {"Vak Combine", "Garwian Unity", "Tower Dimension"}
	for _, k in ipairs(CHECK_SECTORS) do
		if val:find(k) then
			return true
		end
	end
	return false
end

local function searchForGrid(txt, lnum, num)
	local s = char(lnum) .. "%-" .. num
	if txt:find(s .. "[0-9]") then
		return false
	else
		return txt:find(s)
	end
end

function determineGridCategories(txt, catName)
	local ret = {''}
	local mobile, unknown, canonOnly = false, false, false
	local lines = separateLines(txt)
	for i, t in pairs(lines) do
		if not mobile then
			if t and string.len(t) > 0 then
				if txt:find('Mobile') then
					mobile = true
				elseif txt:lower():find('canon%-only') then
					canonOnly = true
				elseif txt:find('N/A') then
					unknown = true
				else
					for lnum=1, 26, 1 do  
						for num=1,26,1 do
							if searchForGrid(txt, lnum, num) then
								ret[#ret + 1] = makeCategoryLink(catName .. " in grid square " .. char(lnum) .. "-" .. num)
							end
						end
					end
				end
			end
		end
	end
	if unknown then
		return makeCategoryLink("Locations with unknown or extragalactic grid coordinates")
	elseif canonOnly then
		return makeCategoryLink("Legends locations with canon-only grid coordinates")
	end
	return table.concat(ret)
end

local function checkCoordinates(gridCats, mobile, hasCoordinates, templateName, c, unlisted, checkGrid)
	if string.len(gridCats) > 0 then
		return gridCats, true
	elseif mobile then
		return '', false
	elseif hasCoordinates then
		return makeCategoryLink('Locations with invalid grid coordinates'), false
	elseif isUnlicensed(mw.title.getCurrentTitle()) then
		return '', false
	elseif unlisted or not checkGrid then
		return '', false
	end
	local catName = 'Locations without grid coordinates'
	if templateName and string.len(templateName) > 0 then
		catName = catName .. '/' .. templateName
	end
	if c == nil then
		c = isCanon(mw.title.getCurrentTitle())
	end
	if c == "false" then
		catName = catName .. '/Legends'
	elseif c == "ncl" then
		return '', false
	end
	return makeCategoryLink(catName), false
end

local function extractLink(cx)
	local c = cx:gsub('%[', ''):gsub('%]', ''):gsub('/Canon', ''):gsub('/Legends', '')
	if c:find('|') then
		c = c:sub(0, c:find('|') - 1)
	end
	return c
end

local function systemSort(args)
	local cx = ""
	if yes(args.system) and args.system ~= "N/A" and args.system ~= "None" then
		cx = extractLink(args.system)
	end
	if not yes(cx) and yes(args.orbited) then
		cx = extractLink(args.orbited)
	end
	if yes(cx) then
		return "|"..cx
	end
	return ""
end

local function validateFields(args, ret)
	local hasAllData = true
	if not yes(args.region) then
		hasAllData = false
		if args.system == "N/A" then
			ret[#ret + 1] = makeCategoryLink("Systems and sectors without region")
		else
			ret[#ret + 1] = makeCategoryLink("Locations without region"..systemSort(args))
		end
	end
	
	local sx = args.system == "N/A" and "Systems" or "Locations"
	local i = yes(args.region) and determineSorting(args.region) or ""
	if (args.sector == nil or args.sector == "") then
		if i ~= "|0"  and i ~= "|7" and i ~= "|8" and i ~= "|9" then
			ret[#ret + 1] = makeCategoryLink(sx.." without sector")
		end
		hasAllData = false
	elseif args.sector == "None" then
		if i == "|0"  or i == "|7" or i == "|8" or i == "|9" then
			i = "/Expected"..i
		end
		ret[#ret + 1] = makeCategoryLink(sx.." with unknown sector"..i)
	elseif (args.sector == "N/A" or args.sector:find("Freestanding")) and yes(args.outside) then
		if i ~= "|8" and i ~= "|9" then
			if args.system == "N/A" then
				ret[#ret + 1] = makeCategoryLink("Star systems outside of established sectors")
			else
				ret[#ret + 1] = makeCategoryLink("Locations outside of established sectors"..systemSort(args))
			end
		end
	end
	
	if (args.system == nil or args.system == "") then
		ret[#ret + 1] = makeCategoryLink("Locations without system")
		hasAllData = false
	end
	return hasAllData
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	local categoryName = 'Locations'
	if args.category_name then
		categoryName = args.category_name
	end
	local templateName = ''
	if args.template_name then
		templateName = args.template_name
	end
	if mw.title.getCurrentTitle().namespace ~= 0 then
		return ''
	end
	local checkGrid = true
	if args.no_grid_check then
		checkGrid = false
	end
	
	local gridCats = ''
	local hasCoordinates = false
	local mobile = false
	local vx = ''
	for k, v in pairs(frame:getParent().args) do
		if k == "coord" or k == "coordinates" then
			if v and string.len(v) > 0 then
				hasCoordinates = true
				if v:find('Mobile') then
					mobile = true
				end
				vx = v
				local c = determineGridCategories(v, categoryName)
				if checkGrid and c and string.len(c) > 0 then
					gridCats = gridCats .. c
				end
			end
		end
	end
	
	local c = nil
	local t = mw.title.getCurrentTitle()
	local unidentified = t.text:sub(0, 12) == "Unidentified" or t.text:find('homeworld') or t.text:find('home planet') or t.text:sub(0, 7) == "Unnamed"
	local ret = {}
	if yes(args.unlisted) then
		cx = "|"..args.unlisted
		if args.unlisted == "2" then
			cx = "|*"
		elseif args.unlisted == "1" then
			cx = systemSort(args)
		end
		ret[#ret + 1] = makeCategoryLink("Locations unlisted in the Appendix"..cx)
	else
		local hasAllData = validateFields(args, ret)
		if not hasAllData then
			c = isCanon(t)
			if unidentified and (c == '*' or c == 'false' or c == 'ncl') then
				if #gridCats == 0 then
					return ''
				end
				ret = {}
			elseif unidentified then
				local tu = t.text:gsub("Unidentified ", "")
				ret = {makeCategoryLink("Unidentified locations with incomplete astronomical data|"..string.upper(tu:sub(0, 1))..'Z-'..tu)}
			elseif c == "*" then
				return makeCategoryLink("Non-canon locations with incomplete astronomical data")
			elseif c == 'false' or c == 'ncl' then
				ret = {}
			end
		end
	end
	
	local gridCat, coordinatesKnown = checkCoordinates(gridCats, mobile, hasCoordinates, templateName, c, args.unlisted, checkGrid)
	if coordinatesKnown then	-- add grid coordinates if they're defined
		ret[#ret + 1] = gridCat
	elseif not unidentified and not yes(args.unlisted) then -- skip the missing-coordinates category for unlisted
		ret[#ret + 1] = gridCat
	end
	
	if yes(args.sector) and checkSector(args.sector) then
		ret[#ret + 1] = makeCategoryLink("Incorrect sector values")
	end
	
	return table.concat(ret)
end

return p