local function exists(page)
	local success, title = pcall(mw.title.new, page)
	return success and title and title.exists or false
end

local p = {}

function p._main(args)
	local cats = {}
	local num = 0
	local result = ''
	local broken = false

	for k, v in pairs(args) do
		local param = v:gsub("[%[%]]*", "")
		if param:find("Category:") then
			if not exists(param) then
				broken = true
			end
			local page = param:gsub("Category:", "")
			table.insert(cats, page)
			num = num + 1
		end
	end
	
	if num ~= 0 then
		local mobile = {'<div id="related-catlinks-mobile" class="collapsible-menu mobile-only article-footer-item"><ul><span><b>Related Categories:</b> </span>'}
		local normal = {'<div id="related-catlinks" class="related-catlinks mobile-hide"><ul id="rel-catlist" class="categories"><li class="special-categories-label">Related categories:</li>'}
		for x, r in pairs(cats) do
			normal[#normal + 1] = string.format('<li class="category">[[:Category:%s|%s]]</li>', r, r)
			mobile[#mobile + 1] = string.format('<li class="category">[[:Category:%s|%s]]</li>', r, r)
		end
		
		normal[#normal + 1] = '</ul></div>'
		mobile[#mobile + 1] = '</ul></div>'
		result = table.concat(normal) .. table.concat(mobile)
	end
	if broken then
		result = '[[Category:Broken RelatedCategories category links]]' .. result
	end
	
	return result
end
	
function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$')
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p