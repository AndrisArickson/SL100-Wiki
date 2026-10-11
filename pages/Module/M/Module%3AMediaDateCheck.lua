local p = {}

local SORT_KEYS = {
	["AudiobookSeries"] = "0",
	["BookSeries"] = "0",
	["ComicSeries"] = "1",
	["ComicArc"] = "2",
	["MagazineSeries"] = "3",
	["multimedia"] = "4",
	["TelevisionSeason"] = "5",
	["TelevisionSeries"] = "5",
	["ToyLine"] = "6",
	["VideoGameSeries"] = "7",
	["Website"] = "8",
	["Movie"] = "9",
	
	["ActivityBook"] = "A",
	["Book"] = "B",
	["Audiobook"] = "C",
	["BoardGame"] = "D",
	["TabletopGame"] = "D",
	["ExpansionPack"] = "E",
	["ComicBook"] = "F",
	["GraphicNovel"] = "G",
	["ComicCollection"] = "H",
	["ComicStory"] = "I",
	["ComicStrip"] = "J",
	["Webstrip"] = "J",
	["Documentary"] = "K",
	["Media"] = "L",
	["MagazineIssue"] = "M",
	["ComicMagazine"] = "M",
	["ReferenceMagazine"] = "M",
	["HomeVideo"] = "N",
	["Music"] = "O",
	["Soundtrack"] = "O",
	["RealEvent"] = "P",
	["LiveShow"] = "P",
	["ReferenceBook"] = "Q",
	["Adventure"] = "R",
	["ShortStory"] = "S",
	["TelevisionEpisode"] = "T",
	["TradingCardSet"] = "U",
	["VideoGame"] = "V",
	["WebArticle"] = "W",
	["MagazineDepartment"] = "Y",
	["MagazineArticle"] = "Y",
	["Unlicensed"] = "Z",
}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

local LOST = {
	"Star Wars Adventures 22 (magazine)", "Star Wars Adventures 23 (magazine)",
	"Star Wars Adventures 25 (magazine)", "Star Wars Adventures 26 (magazine)", 
	"Star Wars Adventures 27 (magazine)", 
	"Star Wars Comic 4.22", "Star Wars Comic 4.23", "Star Wars Comic 4.34",
	"Star Wars Comic 4.35", "Star Wars Comic 4.38", "Star Wars: The Clone Wars Comic 6.46"
}

local function isLost(t, i)
	if hasValue(LOST, t) then
		return true
	elseif i == "ReferenceMagazine" and t:find('Star Wars: Darth Vader') then
		return true
	end
	return false
end

local function isNonCanon(c)
	for index, value in ipairs(c) do
		if value:sub(0, 9) == "Non-canon" or value:find("Star Wars Manga.*stories") or value == "Star Wars: Visionaries stories" then
			return true
		end
	end
	return false
end

local function isUnlicensed(c)
	for index, value in ipairs(c) do
		if value == "Unlicensed media and sources" then
			return true
		end
	end
	return false
end

local function isFuture(c)
	for index, value in ipairs(c) do
		if value:sub(0, 7) == "Future " then
			return true
		end
	end
	return false
end

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function separateLines(txt)
	lines = {}
	if txt:find("\n") == nil then
		table.insert(lines, txt)
		return lines
	end
	
	for s in txt:gmatch("[^\n]+") do
		if s ~= nil then
			if s:find("-ref-") ~= nil then
				table.insert(lines, s:sub(0, s:find("-ref") - 1))
			else
				table.insert(lines, s)
			end
		end
	end
	return lines
end

function extractDay(s)
	if string.find(s, " %d%d[%], ]") then
		local x, y = string.find(s, " %d%d[%], ]")
		return string.sub(s, x + 1, y - 1)
	elseif string.find(s, " %d[%], ]") then
		local x, y = string.find(s, " %d[%], ]")
		return "0" .. string.sub(s, x + 1, y - 1)
	end
	return "XX"
end

MAPPING = {
	['10'] = 'A',
	['11'] = 'B',
	['12'] = 'C',
	['13'] = 'D',
	['14'] = 'E',
	['15'] = 'F',
	['16'] = 'G',
	['17'] = 'H',
	['18'] = 'I',
	['19'] = 'J',
	['20'] = 'K',
	['21'] = 'L',
	['22'] = 'M',
	['23'] = 'N',
}

local function toSortKey(n)
	if n ~= nil and n ~= "" then
		if #n == 3 and MAPPING[n:sub(0, 2)] ~= nil then
			return MAPPING[n:sub(0, 2)]..n:sub(2, 3)..'-'
		end
		return n..'-'
	end
	return ''
end
	

function extractMonth(s)
	if string.find(s, "January") then
		return "1"
	elseif string.find(s, "February") then
		return "2"
	elseif string.find(s, "March") then
		return "3"
	elseif string.find(s, "April") then
		return "4"
	elseif string.find(s, "May") then
		return "5"
	elseif string.find(s, "June") then
		return "6"
	elseif string.find(s, "July") then
		return "7"
	elseif string.find(s, "August") then
		return "8"
	elseif string.find(s, "September") then
		return "9"
	elseif string.find(s, "October") then
		return "A"
	elseif string.find(s, "November") then
		return "B"
	elseif string.find(s, "December") then
		return "C"
	elseif string.find(s, "Spring") then
		return "4Y"
	elseif string.find(s, "Summer") then
		return "7Y"
	elseif string.find(s, "Fall") or string.find(s, "Autumn") then
		return "AY"
	elseif string.find(s, "Winter") then
		return "1Y"
	else
		return "X"
	end
end

function strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function buildSortDate(x)
	if string.find(x, "<ref") then
		x = string.sub(x, string.find(x, "<ref"))
	end
	local month = extractMonth(x)
	if month:find('Y') then
		return month
	end
	local day = extractDay(x)
	return month .. '-' .. day
end

function checkForYear(ret, t, year, decades, catName)
	if t:find(year) then
		local sortText = buildSortDate(t)
		ret[#ret + 1] = makeCategoryLink(year .. ' ' .. catName .. '|' .. sortText)
		return true
	end
	return false
end


function determineYearCategories(txt, catName, decades)
	local ret = {''}
	local lines = separateLines(txt)
	for year=1970, 2030, 1 do
		for i, t in pairs(lines) do
			if t and string.len(t) > 0 then
				local found = checkForYear(ret, t, year, decades, catName)
				if found then
					break
				end
			end
		end
	end
	return table.concat(ret)
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	local categoryName = 'releases'
	if args.misc then 
		categoryName = 'miscellaneous releases'
	elseif args.stories then
		categoryName = 'articles and stories'
	end
	local templateName = args.template_name or ''
	local sortKey = SORT_KEYS[templateName] or (args.sort_key or '')
    local decades = {}
    if args.decades then
        for k in args.decades:gmatch('[^%,]+') do
            decades[#decades + 1] = k:sub(1, 3)
        end
    end
    local currentTitle = mw.title.getCurrentTitle()
	if currentTitle.namespace ~= 0 then
		return ''
	end
	local checkYear = true
	if args.no_year_check then
		checkYear = false
	end
	local special = ''
	if args.special then
		special = '/Other'
	end
	local checkTimeline = true
	if args.no_timeline then
		checkTimeline = false
	end
	local isbnCheck = false
	local publisherCheck = false
	local network = false
    for _, k in ipairs(frame.args) do
    	if k == "isbn" then
            isbnCheck = true
        elseif k == "published in" then
        	publisherCheck = true
        elseif k == "network" then
			network = true
        end
    end

	local lego = string.lower(currentTitle.text):find('lego') or currentTitle.text:find("Angry Birds")
	local unlicensed = false
	local anthology = false
	local reprint = false
	local missingIsbn = false
	local shortIsbn = false
	local hasIsbn = false
	local missingImage = false
	local noImage = false
	local canceled = false
	local missingDate = true
	local unreferenced = 0
	local noTimelineRef = false
	local hasPublishedIn = false
	local multipleDates = false
	local skipDate = false
	local fields = {'publication_date', 'publish_date', 'released', 'release_date', 'airdate', 'first_date', 'last_date', 'start_date', 'end_date', 'first_aired', 'last_aired'}
	
	local p = ''
	local issueNumber = nil
	local yearCats = {}
	for k, v in pairs(frame:getParent().args) do
		if type(k) == "number" then
			--
		elseif k == "image" then
			if not (v and string.len(v) > 0) then
				missingImage = true
			end
		elseif (k == "no_image" or k == "no image") and v and string.len(v) > 0 then
			noImage = true
		elseif k == "unlicensed" then
			unlicensed = true
		elseif k == "anthology" then
			anthology = true
		elseif k == "isbn" then
			if v and string.len(v) > 0 then
				hasIsbn = string.lower(v) ~= "none"
				if templateName ~= "MagazineIssue" and templateName ~= "ExpansionPack" then
					shortIsbn = string.len(v) < 13 or v:find('-')
				end
			elseif isbnCheck then
				missingIsbn = true
			end
		elseif k == "canceled" and v and string.len(v) > 0 then
			canceled = true
		elseif k == "reprint" and v and string.len(v) > 0 then
			reprint = true
		elseif k == "timeline" and v and string.len(v) > 0 then
			if checkTimeline and not string.find(v, '-ref') then
				noTimelineRef = true
			end
		elseif k == "series" and v and string.len(v) > 0 then
			if string.find(string.lower(v), "lego") then
				lego = true
			end
		elseif k and k == "network" and v and string.len(v) > 0 and network then
			hasPublishedIn = true
		elseif k and k:gsub(" ", "_") == "published_in" and v and string.len(v) > 0 then
			hasPublishedIn = true
			if v:find("LEGO Star Wars") or v:find("LEGO.com") or v:find("LEGO Magazine") or v:find('LEGO Club') or v:find('Star Wars Manga: Black') or v:find('Star Wars Manga: Silver') then
				lego = true
			end
			issueNumber = v:match('.*%Insider (%d+)')
		elseif hasValue(fields, k:gsub(" ", "_")) then
			if v and string.len(v) > 0 then
				missingDate = false
				if string.lower(v):find("canceled") or string.lower(v):find("cancelled") then
					canceled = true
				elseif not string.find(v, '-ref') and not (v == 'Future' or v == 'None') then
					unreferenced = unreferenced + 1
				elseif v == 'Future' or v == 'None' then
					skipDate = true
				end
				if string.find(strip(v), '\n') then
					multipleDates = true
				end
				if checkYear then
					local y = determineYearCategories(v, categoryName, decades)
					if y and string.len(y) > 0 then
						yearCats[#yearCats + 1] = y
					end
				end
			end
		end
	end
	table.sort(yearCats)

	local isbnCat = ''
	if hasIsbn then
		isbnCat = makeCategoryLink("Media with defined ISBN")
		if shortIsbn and templateName:find('Comic') then
			isbnCat = isbnCat .. makeCategoryLink("Media with defined ISBN/Comic")
		elseif shortIsbn then
			isbnCat = isbnCat .. makeCategoryLink("Media with defined ISBN/Short")
		end
	elseif missingIsbn and not canceled then
		isbnCat = makeCategoryLink("Media without ISBN")
	end
	
	local dateCat = ''
	if (missingDate or 0 < unreferenced) and (unlicensed or isUnlicensed(currentTitle.categories)) then
		unlicensed = true
		sortKey = SORT_KEYS["unlicensed"]
		dateCat = makeCategoryLink('Unlicensed media with missing or unreferenced publication dates')
	elseif missingDate and not canceled then
		dateCat = makeCategoryLink('Media without publication dates|' .. sortKey .. ':' .. currentTitle.text)
	elseif 0 < unreferenced and not templateName:find('Toy') then
		dateCat = makeCategoryLink('Media with unreferenced publication dates|' .. sortKey .. ':' .. currentTitle.text)
	end
	if multipleDates then
		dateCat = dateCat .. makeCategoryLink('Media with multiple publication dates|' .. sortKey .. ':' .. currentTitle.text)
	end
	if noTimelineRef and not (canceled or reprint or lego or unlicensed or anthology) then
		if not isNonCanon(currentTitle.categories) then
			dateCat = dateCat .. makeCategoryLink('Media with unreferenced timeline placements|' .. sortKey .. ':' .. currentTitle.text)
		end
	end
	if lego and templateName:find("Comic") and missingImage then
		missingImage = false
	end
	if missingImage and not canceled and not skipDate and not noImage and not args.unlicensed and not unlicensed then
		if args.template_name == "MagazineArticle" then
			dateCat = dateCat .. makeCategoryLink('Magazine articles without infobox images|' .. toSortKey(issueNumber) .. currentTitle.text)
		elseif not args.image_optional then
			local clx = ''
			if isLost(currentTitle.text, templateName) then
				clx = '/Expected'
			elseif isFuture(currentTitle.categories) then
				clx = '/Future'
			end
			dateCat = dateCat .. makeCategoryLink('Media without infobox images' .. clx .. '|' .. sortKey .. ':' .. currentTitle.text)
		end
	end
	
	local pubCat = ''
	if publisherCheck and not hasPublishedIn and not canceled then
		pubCat = makeCategoryLink('Media without published in parameter')
	end
	
	return string.format('%s%s%s%s', dateCat, isbnCat, pubCat, table.concat(yearCats))
end

return p