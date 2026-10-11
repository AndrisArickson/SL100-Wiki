local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

function p.main(frame)
    if mw.title.getCurrentTitle().namespace == 10 then
        return ''
    end
    if frame.args.namespace then
    	if mw.title.getCurrentTitle().nsText ~= frame.args.namespace then
    		return ''
    	end
    end
    local missing = false
    local empty = true
    local extra = false
    local arglist = {}
    for _, k in ipairs(frame.args) do
        arglist[k] = true
    end
    local ignore = {}
    if frame.args.ignore then
        for k in frame.args.ignore:gmatch('[^%,]+') do
            ignore[k] = true
        end
    end
    local optional = {}
    if frame.args.optional then
        for k in frame.args.optional:gmatch('[^%,]+') do
            optional[k] = true
        end
    end
    for k, v in pairs(frame:getParent().args) do
        if not arglist[k] and not optional[k] then
            extra = true
        elseif empty and not ignore[k] and #v > 0 then
            empty = false
        end
        arglist[k] = nil
    end
    if next(arglist) then
        -- nil if the table is empty, or a string key
        -- that evaluates to true if not empty
        missing = true
    end
    local ret = {''}
    if missing then
        ret[#ret + 1] = makeCategoryLink('Template usages with missing parameters')
    end
    if empty then
        ret[#ret + 1] = makeCategoryLink('Articles with empty templates')
    end
    if extra then
        ret[#ret + 1] = makeCategoryLink('Template usages with unrecognized parameters')
    end
    return table.concat(ret)
end

return p