
local p = {}
local argDefaults = {}
local _compData
function p.getCompData()
    if not _compData then
        if _G.globalCompData then
            _compData = _G.globalCompData
        else
            --_compData = mw.loadData('Module:UprisingComponents/data')
            _compData = require('Module:UprisingComponents/data')
            _G.globalCompData = _compData
        end
    end
    return _compData
end

local testFrameArgs = {
    get = 'genReferenceTable',
    type = "crystal"
}
--[[
local testFrameArgs = {
    type = "material"
}
]]--
local testParentFrameArgs = {}

-- test frame
p.childFrame = {
    args = testFrameArgs,
    getParent = function()
        local pArgs = testParentFrameArgs
        return { args = pArgs }
    end
}

--[[
local strJoin = function ( separator, ... )
    local args = { ... }
    local n = select( '#', ... )
    return table.concat( args, separator, 1, n )
end
]]--

function packStyleArray(arr)
    if type(arr) == "string" then return {arr} end
    local styles = {}
    for k, v in pairs(arr) do
        table.insert(styles, k .. ':' .. v .. ';')
    end
    return styles
end

function packStyleArrayToString(arr)
    if type(arr) == "string" then return arr end
    return table.concat(packStyleArray(arr), '')
end

function packClassArrayToString(arr)
    if type(arr) == "string" then return arr end
    return table.concat(arr, ' ')
end

function p.childFrame:getParent()
    local pArgs = testParentFrameArgs
    return { args = pArgs }
end

function toLower(str)
    if str == nil then
        return nil
    end
    
    return mw.ustring.lower(tostring(str))
end

function isNum(v)
    return ((v ~= nil and (type(v) == "number" or mw.text.trim(tostring(v)):match('^%s*(%d+)%s*$') ~= nil) and true) or false)
end

function toUpper(str)
    if str == nil then
        return nil
    end
    
    return mw.ustring.upper(tostring(str))
end

function keyExists(tbl, key, noCase)
    local lKey = toLower(key) ---(noCase == true && toLower(k) or k)
    for k, v in pairs(p.getCompData()) do
        if (key == k or (noCase == true and lKey == toLower(k))) then
            return true
        end
    end
    return false
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
                local isNum = mw.text.trim(tostring(v)):match('^%s*(%d+)%s*$')
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
            elseif not useDefault  then
                return nil
            else
                return argDefaults[key]
            end
        end
        
        return args[key]
        
    end
    
    return getValue, args, argNames
    --return p._main(frame, args, getValue, argNames)
end


function p.getComponentByName(name)
    if name == nil then
        return nil
    end
    
    local lName = toLower(name)
    
    for k, v in pairs(p.getCompData()) do
        if mw.ustring.find(lName, toLower(k), 1, true) ~= nil then
            return v
        end
    end
    
    return nil
end

function p.getComponentTier(d, tier)
    local data = nil
    if type(d) == "string" then
        data = p.getComponentByName(d)
    elseif type(d) == "table" then
        data = d
    end
    
    if data ~= nil then
        return (data["T" .. tostring(tier)] or data[toUpper(tier)])
    end
    
    return nil
end

function p.getComponentLevel(d, tier, level)
    local isNum = level ~= nil and mw.text.trim(tostring(level)):match('^%s*(%d+)%s*$')
    
    if type(d) == "string" then
        data = p.getComponentTier(d, tier)
    elseif type(d) == "table" then
        data = d
        if level == nil then
            level = tier
            tier = nil
            isNum = level ~= nil and mw.text.trim(tostring(level)):match('^%s*(%d+)%s*$')
        end
    end
    
    if data ~= nil and data.prefixes ~= nil then
        
        if isNum ~= nil then
            local levelNum = tonumber(isNum)
            local prefixName = data.prefixes[tostring(levelNum)]
            if prefixName ~= nil then
                return (data[prefixName] or data[toLower(prefixName)])
            end
            return nil
        end
        local lLevel = nil
        if level ~= nil then
            lLevel = toLower(level)
            if data[lLevel] ~= nil then
                return data[lLevel]
            end
        end
        
        for k, v in pairs(data) do
            if mw.ustring.find(lLevel or (type(d) == "string" and d) or level or tier, toLower(k), 1, true) ~= nil then
                return v
            end
        end
        
    end
    
    return nil
end

function p.getComponentValueGetter(compName, tier, level)

    
    local comp = p.getComponentByName(compName)
    local tierData = nil
    local levelData = nil
    
    if comp ~= nil then
        tierData = p.getComponentTier(comp, tier or 1)
    end
    
    if tierData ~= nil then
        levelData = p.getComponentLevel(tierData, level or compName)
    end
    
    local getValue = function(n)
        local lN = toLower(n)
        local success = false
        local result = nil
        
        if levelData ~= nil then
            result = (levelData[n] or levelData[lN])
            success = ((result ~= nil and true) or keyExists(levelData, n, true))
            if success == true then
                return result
            end
        end
        
        if lN == 'image' and comp ~= nil then
            return (comp.defaulticon or comp.defaultimage)
        end
        
        if tierData ~= nil then
            result = (tierData[n] or tierData[lN])
            success = ((result ~= nil and true) or keyExists(tierData, n, true))
            if success == true then
                return result
            end
        end
        
        if comp ~= nil then
            result = (comp[n] or comp[lN])
            success = ((result ~= nil and true) or keyExists(comp, n, true))
            if success == true then
                return result
            end
        end
        
        return nil
    end
    
    return getValue, comp, tierData, levelData
end

function p.getComponentValue(n, compName, tier, level)
    local getValue = p.getComponentValueGetter(compName, tier, level)
    return getValue(n)
end

function _getStarFilterColor(starLevel)
    if starLevel == nil or tostring(starLevel) == '' or tonumber(starLevel) <= 1 then
        return 'filter-darkgray'
    elseif tostring(starLevel) == '2' then
        return 'filter-gray'
    elseif tostring(starLevel) == '3' then
        return 'filter-green'
    elseif tostring(starLevel) == '4' then
        return 'filter-blue'
    elseif tostring(starLevel) == '5' then
        return 'filter-purple2'
    elseif tostring(starLevel) == '6' or tonumber(starLevel) >= 6 then
        return 'filter-orange'
    end
    
    return ''
end

function p.__genIconBorder(frame, args, getValue, getCompValue)
    -- Get Component Values
    local compFullName = (getCompValue('fullname') or getCompValue('name'))
    local tier = getCompValue('tier') or '1'
    local level = getCompValue('level')
    local image = getCompValue('image')
    local maxLevel = getCompValue('maxlevel')
    local subtype = getCompValue('subtype')
    
    if maxLevel == nil or tonumber(maxLevel) < 1 then
        mw.log('Invalid component level')
    end
    
    if maxLevel == nil or (tonumber(maxLevel) < (level ~= nil and tonumber(level) or 1)) then
        mw.log('Invalid component maxLevel')
    end
    
    local lElement = toLower(getCompValue('element'))
    local elementIconName = nil
    
    if lElement == 'toxic' then
        elementIconName = 'toxic-hexagon'
    elseif lElement == 'explosive' then
        elementIconName = 'explosive-hexagon'
    elseif lElement == 'disruption' then
        elementIconName = 'disruption-hexagon'
    elseif lElement == 'chemical' then
        elementIconName = 'chemical-hexagon'
    elseif lElement == 'omni' then
        elementIconName = 'filter-purple2 generic-hexagon'
    end
    
    
    -- Get Arg values
    local size = getValue('size', 'small')
    
    
    local iconHeight = 100
    local iconWidth = 100
	local fontStyle = 'font-size-14px line-height-18px'
    if size == 'medium' then
        iconHeight = 130
        iconWidth = 130
    elseif size == 'small' then
        iconHeight = 100
        iconWidth = 100
    elseif size == 'exsmall' then
        iconHeight = 65
        iconWidth = 65
		fontStyle = 'font-size-12px line-height-18px'
    else
        size = 'small'
    end
    
    local out = ''
    
    

    
    local starFilterColor = _getStarFilterColor(level)
    local altText = 'T' .. tier .. ' ' .. compFullName .. ' &#10;&#x0a;' .. (level or '?') .. ' Star' .. (level and tonumber(level) > 1 and 's' or '')
    local containerSpriteName = (level and tonumber(level) >= 7 and 'material-container-gold' or ('material-container-white ' .. starFilterColor))
	
    local starSpriteName = ((level and tonumber(level) >= 7) and 'star-gold' or ('star-3d ' .. starFilterColor))
    local starSpriteClass = 'uprising-sprite ' .. starSpriteName .. (starSpriteName == 'star-gold' and 'margin-left--2px margin-top--2px margin-right-2px margin-bottom--2px' or '') .. ' tiny tiny class-style float-left'
    
    out = out .. '<div class="class-style position-relative display-inline-block width-' .. tostring(iconWidth) .. '-px height-' .. tostring(iconHeight) .. '-px" style="position:relative;display:inline-block;width:' .. tostring(iconWidth) .. 'px;height:' .. tostring(iconHeight) .. 'px;image-rendering:-webkit-optimize-contrast;image-rendering:-moz-crisp-edges;image-rendering:-o-crisp-edges;image-rendering:crisp-edges;image-rendering:optimizequality;">' ..
        '<div class="uprising-sprite ' .. size .. ' material-container-white-bg ' .. ((tier == nil or tostring(tier) == '1') and 'filter-blue' or 'filter-darkorange2') .. ' class-style position-absolute top-0 left-0" style="position:absolute;top:0;left:0;"></div>' ..
        '<div class="uprising-sprite ' .. size .. ' ' .. containerSpriteName .. ' class-style position-absolute top-0 left-0" style="position:absolute;top:0;left:0;"></div>'
        
        if elementIconName ~= nil then
            out = out .. '<div class="class-style position-absolute bottom-0px left-5px margin-bottom-5px margin-left-25px" style="position:absolute;bottom:0px;margin-bottom:5px;margin-left:25px;"><div class="uprising-sprite ' .. elementIconName .. ' exsmall class-style"></div></div>'
        end
        
        out = out ..
            '<div class="class-style position-absolute bottom-5px width-' .. (size == 'exsmall' and '30' or '40') .. '-px right-0px margin-bottom-3px" style="position:absolute;bottom:5px;right:0;z-index:100;">' ..
                '<div class="' .. starSpriteClass .. '"></div>' ..
                '<div class="magistral-font class-style float-left ' .. fontStyle .. ' color-white">' .. tostring(level) .. '</div>' ..
            '</div>' ..
            '<div class="no-figure-caption-mobile class-style position-relative top-0px left-0px thumb-no-margin width-' .. tostring(iconWidth) .. '-px height-' .. tostring(iconHeight) .. '-px" style="position:relative;top:0;left:0;">' ..
                '[[File:' .. image .. '|frameless|link=Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components|alt=' .. altText .. '|' .. altText .. '|' .. tostring(iconWidth) .. 'x' .. tostring(iconHeight) .. 'px]]' ..
            '</div>' ..
        '</div>'
    
    return ((frame ~= nil and getValue('nopreprocess', false) == nil and Try_preprocess(frame, out)) or out)
end

function p._genIconBorder(frame, args, getValue)
    local compName = getValue('name', false) or getValue('fullname', false) or getValue('componentname', false)
    local tier = getValue('tier', '1')
    local level = getValue('level', false)
    
    if compName == nil then
        mw.log('Missing Component Name')
        return ''
    else
        local getCompValue = p.getComponentValueGetter(compName, tier, level)
        if getCompValue ~= nil then
            return p.__genIconBorder(frame, args, getValue, getCompValue)
        end
    end
    
    return ''
end

function p.genIconBorder(frame)
    local getValue = nil
    local args = nil
    local argNames = nil
    getValue, args, argNames = _getArgs(frame)
    return p._genIconBorder(frame, args, getValue)
end



function p._getReferenceTableRow(compName, getCompValue, options)
    local out = ''
    local rowCount = 0
    
    options = options or {}
    
    local name = getCompValue('name')
    local lName = toLower(name)
    local _type = toLower(getCompValue('type'))
    local tier = (getCompValue('tier') or 1)
    local subtype = getCompValue('subtype')
    local element = getCompValue('element')
    
    local minLevel = getCompValue('minlevel')
    local maxLevel = getCompValue('maxlevel')
    
    local prefixes = getCompValue('prefixes')
    
    local sortPrefix = 'T' .. tostring(tier) .. ','
    local sortPrefix2 = sortPrefix .. lName
    local sortPrefix3 = sortPrefix2 .. ','
    
    local isMaterial = (toLower(_type) == 'material' and true or false)
    
    local rowspan = (isMaterial and 7 or 6)
    
    local cellStyleDefaults = '' ..
        'padding:0 4px;' ..
        'line-height:1.6em;' ..
        (type(options.cellStyle) == "string" and options.cellStyle or '')
    
    local makeCell = function(h)
        return ('<td ' .. (h.colspan and ('colspan="' .. h.colspan .. '" ') or '') .. (h.rowspan and ('rowspan="' .. h.rowspan .. '" ') or '') .. ' data-sort-value="' .. (h.sort or '') .. '" class="' .. (h.class or '') .. '" style="' .. (h.style or '') .. '">' .. (h.content or '') .. '</td>')
    end
	
	local getCompBaseValue = p.getComponentValueGetter(name, tier)
	
	local defaultImage = nil
	
	if getCompBaseValue then
		defaultImage = (getCompBaseValue('defaulticon') or getCompBaseValue('defaultimage'))
	
	end
    
    local getLevelDataCells = function(level)
        local getCompLevelValue = p.getComponentValueGetter(name, tier, level)
        
        
        local levelNum = level
        local image = nil
        
        local prefix = nil
        local sell = nil
        local use = nil
        local upgrade = nil
        local upgradecount = nil
        local xp = nil
        
        local exists = false
        local hasUpgrade = false
        
        
        if getCompLevelValue ~= nil then
            levelNum = getCompLevelValue('level')
            image = getCompLevelValue('image')
            prefix = getCompLevelValue('prefix')
            sell = getCompLevelValue('value')
            use = getCompLevelValue('useprice')
            upgrade = getCompLevelValue('upgradecost')
            upgradecount = getCompLevelValue('upgradecount')
            xp = getCompLevelValue('xp')
            
            
            if prefix ~= nil then
                exists = true
                if upgrade ~= nil then
                    hasUpgrade = true
                end
            end
        end
        
        if (exists and upgrade and tonumber(upgrade) > 0) then
            hasUpgrade = true
        end
        if (hasUpgrade and (exists == false or (upgrade and (tonumber(upgrade) <= 0 and tonumber(levelNum or level) >= tonumber(maxLevel or 7))))) then
            hasUpgrade = false
        end
        
        local levelOut = ''
        
        -- Level
        levelOut = levelOut .. makeCell{content = (levelNum or level), sort = (sortPrefix3 .. tostring(levelNum or level)), class = 'class-style text-align-center', style = ('text-align:center;' .. cellStyleDefaults)}
        
        -- Prefix
        levelOut = levelOut .. makeCell{content = (prefix or '&nbsp;'), sort = (sortPrefix3 .. tostring(prefix or '-1')), class = '', style = (cellStyleDefaults)}
        
        -- Sell Value
        levelOut = levelOut .. makeCell{content = (sell and sell > 0 and sell or (exists and '?' or '&nbsp;')), sort = (tostring(exists and sell and sell > 0 and sell or '-1') .. ',' .. sortPrefix2), class = 'class-style text-align-right', style = ('text-align:right;' .. cellStyleDefaults)}
        
        -- Use Price
        levelOut = levelOut .. makeCell{content = (use and use > 0 and use or (exists and '?' or '&nbsp;')), sort = (tostring(exists and use and use > 0 and use or '-1') .. ',' .. sortPrefix2), class = 'class-style text-align-right', style = ('text-align:right;' .. cellStyleDefaults)}
        
        -- Upgrade Cost
        local tUpgrade = (hasUpgrade == false and '&nbsp;' or tostring(upgrade or '?'))
        local tUpgrade2 = (hasUpgrade == false and '-1' or tostring(upgrade or '-1'))
        local upgradeCountElement = (hasUpgrade == false and '' or ('<div class="class-style float-left margin-right-5px font-size-0-8em" style="float: left; margin-right: 5px; font-size: 0.9em; letter-spacing: 0px;" title="# of components required to upgrade.">\'\'\'\'\'<span class="letter-spacing-2px" style="letter-spacing:2px;">' .. ((upgradecount == nil or tonumber(upgradecount) < 10) and '&nbsp;' or '') .. tostring((upgradecount and tonumber(upgradecount) > 0 and upgradecount) or '?') .. '</span>\'\'\'&nbsp;x&nbsp;&nbsp;\'\'</div>'))
        levelOut = levelOut .. makeCell{content = ((exists and upgradeCountElement or '') .. (tUpgrade or (exists and '?' or '&nbsp;'))), sort = (tostring(exists and tUpgrade2 or '-1') .. ',' .. sortPrefix2), class = 'class-style text-align-right', style = ('text-align:right;' .. cellStyleDefaults)}
        
        -- XP Gain
        if isMaterial == true then
            levelOut = levelOut .. makeCell{content = (xp and xp > -1 and xp or (exists and '?' or '&nbsp;')), sort = (tostring(exists and xp or '-1') .. ',' .. sortPrefix2), class = 'class-style text-align-right', style = ('text-align:right;' .. cellStyleDefaults)}
        end
        
        return levelOut
    end
    
    out = out .. '<tr style="font-size:0.8em;">'
        
        -- Name
        out = out ..
            '<th rowspan="' .. rowspan .. '" data-sort-value="' .. (lName .. ',T' .. tostring(tier)) .. '" style="padding:0 4px;font-size:1.4em;background:#3c3c3c;">' ..
                '\'\'\'[[Wookieepedia:Star Wars: Uprising Super Walkthrough/Components/' .. (isMaterial == true and 'Materials' or 'Crystals') .. '#' .. name .. '|<span class="class-style letter-spacing-1px margin-left-10px margin-right-10px" style="letter-spacing:1px;color:#cfcfcf;margin:0 10px;">' .. name .. '</span>]]\'\'\'' ..
				(defaultImage ~= nil and defaultImage and ('<br /><center><div style="margin: -10px 0px;">[[File:' .. tostring(defaultImage) .. '|link=Wookieepedia:Star Wars: Uprising Super Walkthrough/Components/' .. (isMaterial == true and 'Materials' or 'Crystals') .. '#' .. name .. '|' .. subtype .. '|80x80px]]</div></center>') or '') ..
            '</th>'
        
        -- Type
        out = out .. '<td rowspan="' .. rowspan .. '" data-sort-value="' .. (toLower(subtype) or '-1') .. '" class="class-style text-align-center width-fit-content" style="padding:0 4px;text-align:center;font-size:1.1em;width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;">' .. subtype .. '</td>'
        
        -- Element
        if isMaterial == true then
            out = out .. '<td rowspan="' .. rowspan .. '" data-sort-value="' .. (toLower(element) or '-1') .. '" class="class-style text-align-center width-fit-content" style="padding:0 4px;text-align:center;font-size:1.1em;width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;">' .. (element or 'N/A') .. '</td>'
        end
        
        out = out .. getLevelDataCells(1)
    
    out = out .. '</tr>'
    rowCount = rowCount + 1
    
    for i=2,rowspan do
        -- class="expand-child"
        out = out .. '<tr style="font-size:0.8em;">' .. getLevelDataCells(i) .. '</tr>'
        rowCount = rowCount + 1
    end
    
    return out, rowCount
end

function p.getReferenceTableRow(frame, args, getValue)
    local compName = getValue('name', false) or getValue('fullname', false) or getValue('componentname', false)
    local tier = getValue('tier', '1')
    
    if compName == nil then
        mw.log('Missing Component Name')
        return ''
    else
        local getCompValue, comp, tierData = p.getComponentValueGetter(compName, tier)
        if getCompValue ~= nil and tierData ~= nil then
            local options = {}
            options.cellStyle = getValue('cellStyle', false)
            options.cellClass = getValue('cellClass', false)
            return p._getReferenceTableRow(compName, getCompValue, options)
        end
    end
    
    return ''
end

function p.genReferenceTableRow(frame)
    local getValue = nil
    local args = nil
    local argNames = nil
    getValue, args, argNames = _getArgs(frame)
    return p.getReferenceTableRow(frame, args, getValue)
end


function p._getReferenceTable(tier, _type, options)
    local out = ''
    local isMaterial = (toLower(_type) == 'material' and true or false)
    
    options = options or {}
    
    local headerStyleDefaults = '' ..
        'padding:1px 4px;' ..
        'background:#1c1c1c;' ..
        'color:#AFAFAF;'
    
    local caption = ((options.useCaption == false and '') or ('<caption>' .. (type(options.useCaption) == "string" and options.useCaption or '<span class="class-style letter-spacing-1px" style="letter-spacing:1px;">Quick Reference<br><small><small>Click item for more information</small></small></span>') .. '</caption>'))
    
    local makeHeader = function(h)
        return ('<th data-sort-type="' .. (h.sort or 'text') .. '" class="class-style std-background-1c1c1c ' .. (h.class or '') .. '" style="' .. headerStyleDefaults .. (h.style or '') .. '">' .. (h.content or '') .. '</th>')
    end
    
    -- sortable
    out = out ..
        '<table class="wikitable magistral-font class-style width-100-pct ' .. (type(options.tableClass) == "string" and options.tableClass or '') .. '" style="width:100%;background:#fff none no-repeat scroll center bottom;border:1px solid #000;' .. (type(options.tableStyle) == "string" and options.tableStyle or '') .. '">' ..
            caption ..
            '<tr>' ..
                        makeHeader{content = "Tier", class = "", style = ""} ..
                        makeHeader{content = "Name", class = "", style = ""} ..
                        makeHeader{content = "Type", class = "width-fit-content", style = "width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;"} ..
(isMaterial == true and makeHeader{content = "Element", class = "width-fit-content", style = "width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;"} or '') ..
                        makeHeader{content = "&#9733;", class = "", style = ""} ..
                        makeHeader{content = "Prefix", class = "", style = ""} ..
                        makeHeader{content = "Sell", class = "", style = ""} ..
                        makeHeader{content = "Use", class = "", style = ""} ..
                        makeHeader{content = "Upgrade", class = "", style = ""} ..
(isMaterial == true and makeHeader{content = "XP", class = "", style = ""} or '') ..
            '</tr>'
    
    local totalRowCount = 0
    local addTierData = function(_tier)
        local _rowCount = 0
        local rowCount = 0
        local rows = {}
        for k, v in pairs(p.getCompData()) do
            if toLower(v.type) == toLower(_type or 'crystal') then
                local getCompValue, comp, tierData = p.getComponentValueGetter(k, _tier)
                if getCompValue ~= nil and tierData ~= nil then
                    local tVal, tRowCount = p._getReferenceTableRow(k, getCompValue, options)
                    table.insert(rows, {key = getCompValue('name'), value = tVal})
                    _rowCount = _rowCount + 1
                    rowCount = rowCount + tRowCount
                end
            end
        end
        table.sort(rows, function (a, b)
            return toLower(a.key) < toLower(b.key)
        end)
        
        local currentRow = 0
        for k, v in pairs(rows) do
            if v and v.value then
                if currentRow == 0 then
                    local tierClasses = {'class-style', 'padding-0'}
                    local tierStyles = {
                        background = '#395873',
                        color = '#EBEBEB'
                    }
                    
                    if tostring(_tier) == '2' then
                        table.insert(tierClasses, 'std-background-grad-orange2')
                        tierStyles.background = '#d87504'
                        --tierStyles.color = '#EBEBEB'
                    else
                        table.insert(tierClasses, 'std-background-grad-blue')
                    end
                    
                    tierStyles['border-top-color'] = tierStyles['background']
                    
                    if totalRowCount > 0 then
                        tierStyles['border-bottom-color'] = tierStyles['background']
                    else
                        tierStyles['border-bottom'] = '2px solid black'
                    end
                    
                    out = out ..
                        '<tr>' ..
                            '<th rowspan="' .. tostring(rowCount + _rowCount + (totalRowCount > 0 and 1 or 0)) .. '" class="' .. packClassArrayToString(tierClasses) .. '" style="' .. packStyleArrayToString(tierStyles) .. '" title="Tier ' .. tostring(_tier) .. '">' ..
                                '<div class="class-style position-relative" style="position: relative;">' ..
                                    '<div class="class-style position-absolute left-50-pct" style="position: absolute;left: 50%;">' ..
                                        '<div class="magistral-font class-style position-relative left--50-pct letter-spacing-2px white-space-pre" style="position:relative;transform: rotate(-90deg);letter-spacing:2px;white-space:pre;left:-50%;font-size:1.5em;">Tier&nbsp;' ..
                                            (tostring(_tier) == '2' and 'II' or 'I') ..
                                        '</div>' ..
                                    '</div>' ..
                                '</div>' ..
                            '</th>' ..
                            '<td colspan="1" class="class-style border-top-black padding-0 display-none" style="border-top:1px solid black;padding:0;border-bottom-color:#3c3c3c;display:none;"></td>' ..
                            '<td colspan="' .. tostring(isMaterial and 8 or 6) .. '" class="class-style border-top-black padding-0 display-none" style="border-top:1px solid black;padding:0;display:none;"></td>' ..
                        '</tr>'
                end
                if totalRowCount > 0 then
                    out = out .. '<tr><td colspan="' .. tostring(isMaterial and 9 or 7) .. '" class="class-style border-top-black padding-0" style="border-top:2px solid black;padding:0;"></td></tr>'
                end
                out = out .. v.value
                currentRow = currentRow + 1
                totalRowCount = totalRowCount + 1
            end
        end
    end
    
    if tier == nil or isNum(tier) == false then
        -- Make into a loop when T3 items are released
        addTierData(1)
        addTierData(2)
    else
        addTierData(tier)
    end
    
    out = out .. '</table>'
    
    return out
end

function p.getReferenceTable(frame, args, getValue)
    local tier = getValue('tier', false)
    local _type = toLower(getValue('type', 'crystal'))
    local options = {}
    options.useCaption = getValue('useCaption', false)
    options.tableStyle = getValue('tableStyle', false)
    options.tableClass = getValue('tableClass', false)
    options.cellStyle = getValue('cellStyle', false)
    options.cellClass = getValue('cellClass', false)
    
    return p._getReferenceTable(tier, _type, options)
end

function p.genReferenceTable(frame)
    local getValue = nil
    local args = nil
    local argNames = nil
    getValue, args, argNames = _getArgs(frame)
    return p.getReferenceTable(frame, args, getValue)
end


function p._getValue(frame, args, getValue)
    local n = getValue('get', false)
    local compName = getValue('name', false) or getValue('fullname', false) or getValue('componentname', false)
    local tier = getValue('tier', '1')
    local level = getValue('level', false)
    
    local getCompValue = p.getComponentValueGetter(compName, tier, level)
    return (getCompValue and getCompValue(n) or '')
end

function p.getValue(frame)
    local getValue = nil
    local args = nil
    local argNames = nil
    getValue, args, argNames = _getArgs(frame)
    return p._getValue(frame, args, getValue)
end

function p.main(frame)
    local getValue, args, argNames = _getArgs(frame)
    local _get = getValue('get', false)
    local fn = getValue('fn', false)
    
    if fn ~= nil and type(fn) == "string" and fn ~= 'main' then
        if p[fn] ~= nil then
            return p[fn](frame, args, getValue)
        end
    end
    
    if _get ~= nil and type(_get) == "string" then
        if _get ~= 'main' and p[_get] ~= nil then
            return p[_get](frame, args, getValue)
        end
        
        return p._getValue(frame, args, getValue)
    end
    
    mw.log('Invalid fn or get value')
    
    return nil
end

function p._debug(fn)
    -- main
    -- getValue
    -- genIconBorder
    -- genReferenceTableRow
    -- genReferenceTable
    local result = p[fn or 'main'](p.childFrame)
    mw.log(result)
    return result
end

return p