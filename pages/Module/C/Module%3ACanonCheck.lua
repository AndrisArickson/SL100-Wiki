local p = {}

local function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

function p.main(frame)
	local value = frame.args.value or ''
	if value == nil or value == "" then
		return ''
	end
	local page = mw.title.getCurrentTitle()
	if page.text:find('/Legends') then
		return ''
	elseif page.text:find('/Canon') then
		return value
	elseif exists(page.text..'/Legends') then
		return value
	elseif exists(page.text..'/Canon') then
		return ''
	end
	
    for index, v in ipairs(page.categories) do
        if v == "Legends articles" or v == "Non-canon Legends articles" or v == "Articles from unlicensed sources" then
            return ''
        end
    end
    return value
end

return p