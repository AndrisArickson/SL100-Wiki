local p = {}

function p.main(frame, ...)
    if frame.args ~= nil and frame.args.template ~= nil and frame.args.value ~= nil and frame.args.value ~= nil then
    	if frame.args.value:find('%[%[') and mw.title.getCurrentTitle().namespace == 0 then
    		return '[[Category:' .. frame.args.template .. ' usages with links|' .. mw.title.getCurrentTitle().text .. ']]'
    	end
    end
    return ''
end

return p