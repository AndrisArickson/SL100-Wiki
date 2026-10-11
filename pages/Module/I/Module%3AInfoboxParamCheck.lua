local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

local function buildWarning(s)
	return string.format('<span style="color: red">\'\'\'Warning: %s\'\'\'</span>\n\n', s)
end

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local function strip(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

local function hasInvalidImages(images)
	for _, image in ipairs(images) do
		if image and #image > 0 and image:find('File:') then
			local x, _ = image:find('File:')
			local filename = image:sub(x):gsub('%|.*%]%]', ''):gsub('%]', '')
			if not exists(filename) then
				return true
			end
		end
	end
end

local function concatKeys(map)
	local s = ''
	for k, v in pairs(map) do
		if v ~= nil then
			if s == '' then
				s = '' .. k
			else 
				s = s .. ', ' .. k
			end
		end
	end
	return s
end

local function removebyKey(tab, val)
	local newTable = {}
    for i, v in ipairs (tab) do 
        if (v ~= val) then
        	newTable[#newTable + 1] = v
        end
    end
    return newTable
end

function getIndex(tab, v)
	for k, v in ipairs(tab) do
		return k
	end
	return "-1"
end

function hasFile(v)
	if v:find('<ref') then
		for s in v:gmatch('(.*?)<ref') do
			return s:find('File:')
		end
	elseif v:find('audiolink') then
		for s in v:gmatch('(.*?)audiolink') do
			return s:find('File:')
		end
	else
		return v:gsub('File:AurebeshSans', ''):find('File:')
	end
	return false
end

function handleComboParameters(comboMap, comboToCheck, comboParents, extra, missing, debug_data)
	local partial = {}
    for k, v in pairs(comboToCheck) do
    	local parent = comboMap[k]
    	if not missing[parent] then
			extra[k] = true
		else
			partial[parent] = true
	    	debug_data[#debug_data + 1] = (k or 'X').. "->" .. (v or 'X') .. "->" .. #comboParents[parent]..'->'..getIndex(comboParents[parent], k) .. "->" .. (partial[parent] and 'True' or 'False') .. "->" .. (missing[parent] and 'True' or 'False')..'<br />'
			comboParents[parent] = removebyKey(comboParents[parent], k)
		end
    end
    for k, v in pairs(partial) do
    	debug_data[#debug_data + 1] = (k or 'X').. "->" .. #comboParents[k]..'->'..table.concat(comboParents[k]) .. "->" .. (missing[k] and 'True' or 'False')..'<br />'
		missing[k] = nil
    	if comboParents[k] ~= nil and #comboParents[k] >= 0 then
    		for _, x in ipairs(comboParents[k]) do
    			missing[x] = true
    		end
    	end
    end
end

local function namesMatch(base, val)
	return base == val or base..'s' == val or string.lower(base:sub(0, 1))..base:sub(2) == val
end

function namesDoNotMatch(value)
	local title = mw.title.getCurrentTitle().text:gsub('/Legends', ''):gsub('/Canon', ''):gsub('/LEGO', '')
	if title:match('^(.*%((.-)%))%s*%((.-)%)$') then
		return ''
	end
	
	title = title:gsub("^(.*)%s%([0-9]+%)%s(.*)$", "%1 %2"):gsub("''", ""):gsub('"', '')
	local base, _ = title:match('^(.*)%s*%((.-)%) ?%d*$')
	if not base then
		base = title
	end
	base = strip(base)
	
	local val, _ = value:match('^(.*)%s*%((.-)%)( ?%d*)$')
	if not val then
		val = value
	end
	val = strip(val:gsub("''", ""):gsub('"', ''):gsub('<i>', ''):gsub('</i>', ''))
	val = val:gsub("<span.*>'</span>", "'"):gsub('</*su[bp]>', ''):gsub('</*small>', '')
	val = val:gsub("^(.*)%s%([0-9]+%)%s(.*)$", "%1 %2"):gsub('#', ''):gsub('&num;', ''):gsub('&#*39;', "'")
	val = val:gsub('&ndash;', '–'):gsub('&mdash;', '—')--:gsub("'`UNIQ--.*QINU`'", '')
	
	if value:find(' %(') and not base:find(' %(') and not value:find('<small') then
		return "Expected: ["..base.."], found: ["..value.."]"
	end
	
	br, br2 = val:match('^(.*)%s*<br */*>(.*)$')
	if br and br:match('^(.*)%s*<br */*>(.*)$') then
		br, br3 = br:match('^(.*)%s*<br */*>(.*)$')
	end
	if br and br:match('^(.*)%s*<br */*>(.*)$') then
		br = br:gsub('^(.*)%s*<br */*>(.*)$', '%1 %2')
	end
	if br then
		br = strip(br)
		br2 = strip(br2)
		val1 = val:gsub('<br */*>', ' '):gsub('   *', ' ')
		val2 = val:gsub('<br */*>', ''):gsub('   *', ' ')
		if namesMatch(base, val1) or namesMatch(base, val2) or namesMatch(base, br) or namesMatch(base, br2) then
			return ''
		else
			return "Expected: ["..base.."], found: ["..br.."]"
		end
	elseif title == val or namesMatch(base, val)then
		return ''
	else
		return "Expected: ["..base.."], found: ["..val.."]"
	end
end

function p.main(frame)
    if mw.title.getCurrentTitle().namespace ~= 0 then
        return ''
    end
    local pageTitle = mw.title.getCurrentTitle().text
    local missing = {}
    local empty = true
    local debug_mode = false
    local extra = {}
    for _, k in ipairs(frame.args) do
        missing[k:gsub('_', ' ')] = true
    end
    local ignore = {}
    if frame.args.ignore then
        for k in frame.args.ignore:gmatch('[^%,]+') do
            ignore[k:gsub('_', ' ')] = true
        end
    end
    local optional = {}
    if frame.args.optional then
        for k in frame.args.optional:gmatch('[^%,]+') do
            optional[k:gsub('_', ' ')] = true
        end
    end
    local comboMap = {}
    local comboParents = {}
    if frame.args.combo then
        for k in frame.args.combo:gmatch('[^%,]+') do
	        local masterField = nil
        	for s in k:gsub('_', ' '):gmatch('[^%:]+') do
        		if masterField == nil then
        			masterField = s
        			missing[s] = true
        			comboParents[masterField] = {}
        		else
        			comboMap[s] = masterField
        			comboParents[masterField][#comboParents[masterField] + 1] = s
        		end
        	end
        end
    end
    local nameOverride = false
    local imageInOtherField = false
    local multipleImages = false
    local hasGallery = false
    local hasCaption = false
    local nameValue = nil
    local balanced = 0
    local invalidImage = false
    local hasScrollBox = false
    local isBattle = missing["side1"] ~= nil
    
    local args = {}
    local unnamed = {}
    local images = {}
    local debug_data = {}
    local comboToCheck = {}
    for kx, v in pairs(frame:getParent().args) do
    	if kx == "debug_mode" or kx == "debug mode" then
    		debug_mode = true
    	elseif kx == "override" then
    		nameOverride = true
    	elseif kx == "skip_date_cat" or kx == "skip date cat" then
    		-- do nothing
    	elseif type(kx) == "number" then
    		unnamed[#unnamed + 1] = tostring(kx) .. '=' .. (v or 'no-value')
    	elseif kx ~= nil then
    		local k = tostring(kx):gsub('_', ' ')
    		local hasValue = v ~= nil and v ~= ""
	    	if k ~= 'image' and k ~= 'image2' and k ~= 'image3' and k ~= 'media' and hasValue and hasFile(v) then
	    		imageInOtherField = true
	    	elseif (k == 'image2' or k == 'image3') and hasValue then
	    		images[#images + 1] = v
	    	elseif k == 'image' then
	    		if v:find('gallery') then
	    			hasGallery = true
	    		end
	    		images[#images + 1] = v
	    	elseif k == 'caption' and hasValue then
	    		hasCaption = true
	    	elseif (k == 'name' or k == 'title') and hasValue then
	    		nameValue = v
	    	end
	    	
	    	if hasValue and (v:find('<table class="scrollbox"') or v:find('ScrollBox')) then
	    		hasScrollBox = true
	    	end
	    	
	    	if k == "image" and hasFile(v) and optional[k] then 
	    		if not v:match('^%[%[.ile:.*]]$') then
	    			invalidImage = true
	    		end
	    	end
	    	
	    	debug_data[#debug_data + 1] = (k or 'X').. "->" .. (comboMap[k] or 'X') .. "->" .. (missing[comboMap[k]] and 'True' or 'False') .. "->" .. (missing[k] and 'True' or 'False') .. "->" .. (optional[comboMap[k]] or 'X')..'<br />'
	    	if k == "no image" then
	    		missing["image"] = nil
	    		args["no image"] = nil
	    	elseif comboMap[k] then
	    		comboToCheck[k] = v
	        else
	        	if not missing[k] and not optional[k] then
	            	extra[k] = true
		        elseif empty and not ignore[k] and hasValue then
		            empty = false
		        end
				missing[k] = nil
	    	end
	    	if v then
	    		args[k] = true
	    	else
	    		args[k] = false
	    	end
	    end
    end
    handleComboParameters(comboMap, comboToCheck, comboParents, extra, missing, debug_data)
    
    local unbalanced = false
    if args['image2'] and not (args['image'] and args['option1'] and args['option2']) then
    	unbalanced = true
    end
    if args['image3'] and not (args['image'] and args['image2'] and args['option3']) then
    	unbalanced = true
    end
	
	local missingParams = concatKeys(missing)
	local extraParams = concatKeys(extra)
    local ret = {''}
    if debug_mode then
    	ret[#ret + 1] = table.concat(debug_data)
    end
    if #missingParams > 0 then
        ret[#ret + 1] = makeCategoryLink('Infoboxes with missing parameters')
    end
    if empty then
        ret[#ret + 1] = makeCategoryLink('Articles with empty infoboxes') 
    end
    if not nameValue then
		ret[#ret + 1] = makeCategoryLink('Infoboxes without name or title value')
    elseif not nameOverride then
    	mismatch = namesDoNotMatch(nameValue)
    	if mismatch ~= nil and mismatch ~= '' then
    		ret[#ret + 1] = buildWarning("The name or title field of this page's infobox does not match the page title. "..mismatch.."\n\n")
			ret[#ret + 1] = makeCategoryLink('Infobox page title mismatches|'..pageTitle)
		end
    end
	if invalidImage then
		ret[#ret + 1] = makeCategoryLink('Infoboxes with invalid image field values')
	end
	if imageInOtherField then
		ret[#ret + 1] = makeCategoryLink('Infoboxes with images in non-image fields')
	end
	if #images > 1 then
		ret[#ret + 1] = makeCategoryLink('Articles with infobox galleries')
	end
	if unbalanced then
		ret[#ret + 1] = makeCategoryLink('Improper usage of infobox gallery fields')
	end
	if hasGallery then
		ret[#ret + 1] = makeCategoryLink('Infoboxes with gallery tags in image field')
	end
	if hasCaption then
		ret[#ret + 1] = makeCategoryLink('Infoboxes with caption fields')
	end
    if hasScrollBox then
        ret[#ret + 1] = makeCategoryLink('Infoboxes with scrollboxes') 
    end
    if #extraParams > 0 then
        ret[#ret + 1] = makeCategoryLink('Infoboxes with unrecognized parameters')
    end
    if #unnamed > 0 then
    	ret[#ret + 1] = buildWarning('This infobox has unnamed parameters: ' .. table.concat(unnamed))
        ret[#ret + 1] = makeCategoryLink('Infoboxes with unnamed parameters')
    end
	if hasInvalidImages(images) then
    	ret[#ret + 1] = buildWarning('This infobox has a broken file link. Please double-check your filename.\n\n')
		ret[#ret + 1] = makeCategoryLink('Infoboxes with broken file links')
	end
	
	if #extraParams > 0 and #missingParams > 0 then
		ret[#ret + 1] = buildWarning('This infobox has missing parameters: ' .. missingParams .. ' and unrecognized parameters: ' .. extraParams)
	elseif #missingParams > 0 then
		ret[#ret + 1] = buildWarning('This infobox is missing the following parameters: ' .. missingParams)
	elseif #extraParams > 0 then
		ret[#ret + 1] = buildWarning('The following parameters in the infobox are unrecognized: ' .. extraParams)
	end
    return table.concat(ret)
end

return p