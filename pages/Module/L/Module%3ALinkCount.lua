local p = {}

function p.main(frame, ...)
	if frame.args ~= nil then
		if frame.args.value ~= nil and frame.args.value ~= "" and frame.args.threshold ~= nil and string.match(frame.args.threshold, "^%d+$") then
			local i = select(2, string.gsub(frame.args.value, "%[%[", "")) + select(2, string.gsub(frame.args.value, "{{", ""))
			if i >= tonumber(frame.args.threshold) then
				return 'true'
			end
		end
    end
    return ''
end

return p