-- See http://semeb.com/dpldemo/index.php?title=Template:Extension_DPL_continue
-- See http://starwars.wikia.com/wiki/Template:Extension_DPL_continue

local p = {}
local defaults = {}

function toLower(str)
    if str == nil then
        return nil
    end
    
    return mw.ustring.lower(tostring(str))
end

function toNum(str, def)
	if type(str) == "number" then
		return str
	elseif str == '' then
		return nil
	elseif type(str) == "boolean" then
		return (str == true and 1 or 0)
	end
	
	local isNum = (type(str) == "string" and (mw.text.trim(tostring(str)):match('^(%d+)$')) or nil)
	
	if isNum ~= nil then
		return tonumber(isNum)
	end
	
	if def == true and str ~= nil then
		return tonumber(str)
	end
	
	if type(def) == "number" or type(def) == "string" then
		return tonumber(def)
	end
	
	return str
end

function _preprocess(frame, str)
    return frame:preprocess{text = str}
end

function Try_preprocess(frame, str)
    local success, result = pcall(_preprocess, frame, str)
    
    if success == false then
        return str
    end
    
    return result
end

function getParentFrame(frame)
    return frame:getParent()
end

function getParentFrame2(frame)
    return frame.getParent()
end

function Try_getParentFrame(frame)
    local success,result = pcall(getParentFrame, frame)
    
    if success == false or result == nil or result.args == nil then
        local success2,result2 = pcall(getParentFrame2, frame)
        if success2 == false or result2 == nil or result2.args == nil then
            return nil
        end
        return result2
    end
    
    return result
end

function _getArgs(frame, deep)
    local args = {}
    local argNames = {}
    local parentFrame = nil
    local parentFrame2 = nil

    
    local processArgList = function(_args)
        for k,v in pairs(_args) do
            local lKey = toLower(k)
            argNames[lKey] = k
            
            if v ~= nil and mw.text.trim(tostring(v)) ~= '' then
                local isNum = mw.text.trim(tostring(v)):match('^(%d+)$')
                if isNum ~= nil then
                    args[lKey] = tonumber(isNum)
                elseif type(v) == 'string' then
                    args[lKey] = mw.text.trim(v)
                else
                    args[lKey] = v
                end
            end
        end
    end
    
    if frame then
        if frame.args ~= nil then
            processArgList(frame.args)
        end
        parentFrame = Try_getParentFrame(frame)
        if parentFrame == nil and frame.args == nil then
            processArgList(frame)
        end
    end
    
    if parentFrame and parentFrame.args ~= nil then
        processArgList(parentFrame.args)
        if deep then
            parentFrame2 = Try_getParentFrame(parentFrame)
            
			-- Allow page to be called by another page/template with own request
            if parentFrame2 and parentFrame2.args and parentFrame2.args.get ~= nil and type(parentFrame2.args.get) == 'string' then
                processArgList(parentFrame2.args)
            end
        end
    end

    
    --if frame == mw.getCurrentFrame() then
    
    local getValue = function(name, useDefault)
        local key = toLower(name)
    
        if not args[key] then
            if type(useDefault) == 'string' or type(useDefault) == 'number' then
                return useDefault
            elseif not useDefault then
                return nil
            else
                return defaults[key]
            end
        end
        
        return args[key]
        
    end
	
	local setValue = function(name, val)
		local key = toLower(name)
		if key ~= nil then
			args[key] = val
			if argNames[key] == nil and argNames[name] == nil then
				argNames[key] = name
			end
		end
		return val
	end
    
    return getValue, setValue, args, argNames
    --return p._main(frame, args, getValue, argNames)
end

function p.getDPLTableContinue(frame, getValue)
    if type(getValue) ~= "function" then
        getValue = _getArgs((frame and frame.args ~= nil and frame) or ({args = frame}), false)
    end
    if type(getValue) ~= "function" then
        mw.log('Invalid argument')
        return nil
    end
	
	local page = getValue('page', false)
	local pages = toNum(getValue('pages', '0'))
	local total = toNum(getValue('total', '0'))
    
	local purge = getValue('purge', false)
	local refresh = getValue('refresh', false)
    
	--local dir = getValue('dir', false)
	local count = getValue('count', false)
	local offset = getValue('offset', false)
	--local firsttitle = getValue('firsttitle', false)
	--local lasttitle = getValue('lasttitle', false)
    
    
	local tableClass = getValue('tableClass', '')
	local tableStyle = getValue('tableStyle', '')
	
	local tdClass = getValue('tdClass', '')
	local tdStyle = getValue('tdStyle', '')
	
	local startClass = getValue('startClass', '')
	local startStyle = getValue('startStyle', '')
	local startLinkClass = getValue('startLinkClass', '')
	local startLinkStyle = getValue('startLinkStyle', '')
    
	local backClass = getValue('backClass', '')
	local backStyle = getValue('backStyle', '')
	local backLinkClass = getValue('backLinkClass', '')
	local backLinkStyle = getValue('backLinkStyle', '')
    
	local nextClass = getValue('nextClass', '')
	local nextStyle = getValue('nextStyle', '')
	local nextLinkClass = getValue('nextLinkClass', '')
	local nextLinkStyle = getValue('nextLinkStyle', '')
    
    local startButton = ''
    local backButton = ''
    local nextButton = ''
    
	--DPL_refresh
	--((refresh == true or tostring(refresh) == '1' or tostring(refresh) == 'true') and 'DPL_refresh=yes&' or '')
	
    if toNum(offset) and toNum(offset) > 0 then
        local prevOffset = math.max(0, toNum(offset or 0) - (toNum(count or pages or 25)))
        --&DPL_toTitle={{urlencode:', firsttitle or '~', '}}
        
        startButton = table.concat({'<span class="plainlinks ', startClass, '" style="padding-right: 24px;', startStyle, '">[{{fullurl:', page, '}} <span class="', startLinkClass, '" style="', startLinkStyle, '">start</span>]</span>'})
        backButton = table.concat({
            '<span class="plainlinks ', backClass, '" style="padding-right: 24px; font-weight: bold;', backStyle, '">',
                '[{{fullurl:', page, '|', ((purge == true or tostring(purge) == '1' or tostring(purge) == 'true') and 'action=purge&' or ''), ((refresh == true or tostring(refresh) == '1' or tostring(refresh) == 'true') and 'DPL_refresh=yes&' or ''), 'DPL_scrollDir=dn&DPL_count=', (count and tostring(count) or ''), '&DPL_offset=', tostring(prevOffset or 0), '}} <span class="', backLinkClass, '" style="', backLinkStyle, '">back</span>]',
            '</span>'
        })
    else
        startButton = table.concat({'<span class="', startClass, '" style="padding-right: 24px;', startStyle, '">start</span>'})
        backButton = table.concat({
            '<span class="', backClass, '" style="padding-right: 24px;', backStyle, '">back</span>'
        })
    end
    
    if total == nil or total == 0 or pages >= total then
        nextButton = table.concat({
            '<span class="', nextClass, '" style="padding-right: 24px;', nextStyle, '">next</span>'
        })
    else
        local nextOffset = math.min((total and total > 0 and math.max(toNum(count or pages or 25), (total - (toNum(count or pages or 25))))) or 5000, toNum(offset or 0) + (toNum(count or pages or 25)))
        --'&DPL_fromTitle={{urlencode:', lasttitle or '~', '}}
        nextButton = table.concat({
            '<span class="plainlinks ', nextClass, '" style="padding-right: 24px; font-weight: bold;', nextStyle, '">',
                '[{{fullurl:', page, '|', ((purge == true or tostring(purge) == '1' or tostring(purge) == 'true') and 'action=purge&' or ''), ((refresh == true or tostring(refresh) == '1' or tostring(refresh) == 'true') and 'DPL_refresh=yes&' or ''), 'DPL_scrollDir=dn&DPL_count=', count, '&DPL_offset=', tostring(nextOffset or 0), '}} <span class="', nextLinkClass, '" style="', nextLinkStyle, '">next</span>]',
            '</span>'
        })
    end
    
	local remaining = ((total or 0) - (pages or 0) - (toNum(offset or 0)))

    return Try_preprocess(frame, table.concat({
        '<table class="', tableClass, '" style="', tableStyle, '">',
            '<tr>',
                '<td class="', tdClass, '" style="background-color: #f9f9f9; padding: .1em .7em .2em .7em;', tdStyle, '">',
                    
                    startButton,
                    
                    backButton,
                    
                    nextButton,
                    
                    '(', pages or '0', ' listed', ((total or 0) > (pages or 0) and ('&nbsp;/ ' .. tostring(remaining) .. ' left') or ''), ')',
                    
                '</td>',
            '</tr>',
        '</table>'
    }))
end

function p.main(frame)
    local getValue, setValue, args, argNames = _getArgs(frame, false)
    return p.getDPLTableContinue(frame, getValue)
end

function p._debugDPLContinue()
    local result = p.main({args = {page = "User:Jgjake2/Sandbox5", pages = "123", total = "234", count = "123", offset = "10"}})
    mw.log(result)
    return result
end

return p