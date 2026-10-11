local p = {}

local function splitDelimiter(str, d)
	if str:find(d) then
		return str:sub(1, str:find(d) - 1)
	end
	return str
end

local function splitPieces(str, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for s in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(t, s)
	end
	return t
end


function p.main(frame)
    if mw.title.getCurrentTitle().namespace ~= 0 then
        return ''
    end
	local dateVal = ''
	local skip = false
    for k, v in pairs(frame:getParent().args) do
    	if k == "date" and v and string.len(v) > 0 then
    		dateVal = v
    	elseif k == "skip_date_cat" and v and string.len(v) > 0 then
    		skip = true
    	end
    end
	
	if skip or not dateVal then
		return ''
	end
	
	local catName = "Events"
	if frame.args.type then
		catName = frame.args.type
	end
	
	if dateVal:find("<ref") then
		dateVal = dateVal:sub(1, dateVal:find('<ref') - 1)
	end
	local st = splitDelimiter(string.lower(dateVal), '%('):gsub("'", "")
	if st:find('prior') or st:find('before') or st:find('after') or st:find('between') or st:find(' by') or st:find('^by ') then
		return ''
	end
	local sortKey = ''
	if st:find('c%.') or st:find('circa') then
		sortKey = "|*" .. mw.title.getCurrentTitle().text
	end
	
	local cats = {}
	for _, x in ipairs(splitPieces(dateVal, "[")) do
		local link = splitDelimiter(splitDelimiter(splitDelimiter(x, "|"), "]"), "/")
		if link:find(" ABY") or link:find(" BBY") then
			cats[#cats + 1] = "[[Category:" .. catName .. " in " .. link .. sortKey .. "]]"
		end
	end
    return table.concat(cats)
end

return p