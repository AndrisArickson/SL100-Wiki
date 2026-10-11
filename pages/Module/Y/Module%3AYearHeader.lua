local p = {}

local function check(str)
	if str == nil then
		str = ""
	end
	return str
end

function p.buildHeader(args)
	local pagename = args.name
	local entries = {}
	local parentType = "current"
	if args.parent_type then
		parentType = args.parent_type
	end
	
	if args.pre then
		entries[#entries + 1] = "/" .. args.pre .. "|" .. args.pre
	end
	
    if args.decades then
        for k in args.decades:gmatch('[^%,]+') do
            entries[#entries + 1] = "/" .. k .. "|" .. k
        end
    end
	
	if args.start then
		for y = args.start, os.date("%Y") do
			if parentType == "current" and tostring(y) == tostring(os.date("%Y")) then
				entries[#entries + 1] = "|" .. y
			else
				entries[#entries + 1] = "/" .. y .. "|" .. y
			end
		end
	end
	
	if #entries == 0 then
		return string.format('<span style="color: red">\'\'\'Warning: No entries could be calculated from start=%s, pre=%s, decades=%s, total=%s\'\'\'</span>\n\n', check(args.start), check(args.pre), check(args.decades), check(args.total))
	end
	
	local slices = 4
	if args.slices ~= nil then
		slices = args.slices
	end
	
	local sliceSize = math.floor(#entries / slices)
	if #entries % slices ~= 0 then
		sliceSize = sliceSize + 1
	end
	
	local width = 600
	if args.width then
		width = args.width
	end
	local divSize = math.floor(width / slices)
	
	local ret = {}
	local sectionStart = true
	for i = 1, #entries do
		if sectionStart then
			ret[#ret + 1] = "<div style=\"width:" .. divSize .. "px; float:left\">\n"
			sectionStart = false
		end
		ret[#ret + 1] = "*[[" .. pagename .. entries[i] .. "]]\n"
		if i % sliceSize == 0 and i ~= #entries then
			ret[#ret + 1] = "</div>\n"
			sectionStart = true
		end
	end
	
	if parentType == 'total' then
		ret[#ret + 1] = "*[[" .. pagename .. "|Totals]]\n"
	elseif args.total then
		ret[#ret + 1] = "*[[" .. pagename .. "/" .. args.total .. "|Totals]]\n"
	end
	ret[#ret + 1] = "</div>"
	
	return table.concat(ret)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do 
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.buildHeader(args) or '{{{1}}}'
end

return p