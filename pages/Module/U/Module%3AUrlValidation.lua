local p = {}

local title = mw.title.getCurrentTitle()
	
function category(c)
	return string.format('[[Category:%s|%s]] §', c, title.text)
end

function p.validate(args)
	if title.namespace ~= 0 and title.namespace ~= 6 and title.namespace ~= 120 then
		return ''
	end
	local r = {}
	if args.unnamed then
		r[#r + 1] = category("Web citation template usages with positional parameters")
	elseif args.url ~= nil then
		if args.url:find('http') then 
			r[#r + 1] = category("Templates with invalid URL parameters")
		end
	else
		r[#r + 1] = category("Web citation template usages without URL parameter")
	end
	if args.text == nil or args.text == "" then
		r[#r + 1] = category("Web citation template usages without text parameter")
	end
	return table.concat(r)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.validate(args)
end

return p