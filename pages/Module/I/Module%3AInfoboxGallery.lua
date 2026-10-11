local p = {}

function p.main(frame)
	local fields = {["image"] = "", ["image2"] = "", ["image3"] = "", ["caption1"] = "", ["caption2"] = "", ["caption3"] = ""}
    for k, v in pairs(frame:getParent().args) do
		if fields[k] ~= nil then
			fields[k] = v
		end
    end

	if fields['image'] and (fields['image2'] or fields['image3']) then
		local gallery = "<gallery>\n" .. fields['image']:gsub('%[', ''):gsub('%]', '') .. '|' .. fields['caption1']
		if fields['image2'] then
			gallery = gallery .. '\n' .. fields['image2']:gsub('%[', ''):gsub('%]', '') .. '|' .. fields['caption2']
		end
		if fields['image3'] then
			gallery = gallery .. '\n' .. fields['image3']:gsub('%[', ''):gsub('%]', '') .. '|' .. fields['caption3']
		end
		return frame:preprocess(gallery .. '\n</gallery>')
	elseif fields['image'] then
		return '[[' .. fields['image'] .. ']]'
	elseif fields['image2'] or fields['image3'] then
		return '[[Category:Other image fields used without image1]]'
	else
		return ''
	end
end

return p