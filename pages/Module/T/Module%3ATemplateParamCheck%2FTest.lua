local p = {}

local function makeCategoryLink(cat)
	-- "Category" is split out here so that the module isn't put into the
	-- category "%s" when the page is saved.
	return string.format('[[%s:%s]]', 'Category', cat)
end

function p.main(frame)
    local ret = {''}
    if frame.args.namespace then
    	if mw.title.getCurrentTitle().nsText ~= frame.args.namespace then
    		return 'PASS'
    	end
    end
    ret[#ret + 1] = mw.title.getCurrentTitle().nsText
    ret[#ret + 1] = ' : '
    ret[#ret + 1] = frame.args.namespace
    return table.concat(ret)
end

return p