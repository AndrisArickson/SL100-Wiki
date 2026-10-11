
-- <pre>
local p = {}

-- See https://springrts.com/wiki/Lua_Performance
local uslower = mw.ustring.lower
local usmatch = mw.ustring.match
local usfind = mw.ustring.find
local usgsub = mw.ustring.gsub
local usrep = mw.ustring.rep
local uslen = mw.ustring.len

local txttrim = mw.text.trim
local txtsplit = mw.text.split

local tableconcat = table.concat
local tableinsert = table.insert


local _lang
local _UprisingComponents
local defaults = {
    image = "",
    name = "",
    description = "",
    tier = "",
    baseStarLevel = "",
    evolution = "",
    stars = "",
    maxstarcount = "",
    type = "",
    gearsetname = "",
    gearSetBaseName = "",
    gearSetDisplayName = "",
    gearSetPrefix = "",
    
    faction = "",
    geartype = "",
    location = "",
    
    baselevel = "",
    levelcap = "?",
    navnext = "",
    basestat = "",
    credits = "",
    
    -- Attack
    attack = "",
    attackmin = "",
    attackbase = "",
    attackmax = "",
    
    -- Armor
    armor = "",
    armormin = "",
    armorbase = "",
    armormax = "",
    
    -- Utility
    utility = "",
    utilitymin = "",
    utilitybase = "",
    utilitymax = "",
    
    -- Mods
    mod1name = "",
    mod1value = "",
    mod2name = "",
    mod2value = "",
    mod3name = "",
    mod3value = "",
    mod4name = "",
    mod4value = "",
    mod5name = "",
    mod5value = "",
    mod6name = "",
    mod6value = "",
    
    
    upgradecomponent1name = "",
    upgradecomponent1type = "",
    upgradecomponent1prefix = "",
    upgradecomponent1count = "",
    
    
    upgradecomponent2name = "",
    upgradecomponent2type = "",
    upgradecomponent2prefix = "",
    upgradecomponent2count = "",
    
    
    upgradecomponent3name = "",
    upgradecomponent3type = "",
    upgradecomponent3prefix = "",
    upgradecomponent3count = "",
    
    
    upgradecost = "",
    sellpricemin = "",
    sellpricemax = "",
    
    noimagebg = ""
}

function lang()
    if not _lang then
        _lang = mw.getContentLanguage()
    end
    return _lang
end

function UprisingComponents()
    if not _UprisingComponents then
        _UprisingComponents = require('Module:UprisingComponents')
    end
    return _UprisingComponents
end

--[[
local testFrameArgs = {
    get = "infobox",
    image = "Uprising_Icon_Item_Base_M_Chest_00022_W.png",
    name = "Perfect Bodyguard Chestplate",
    description = "Defensive gear used by the Trade Spine League.",
    stars = "4",
    maxstarcount = "6",
    type = "torso",
    faction = "Trade",
    levelCap = "120",
    navPrev = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment/Refitted_Bodyguard_Chestplate",
    baseStat = "200",
    attack = "24.5%",
    armor = "?",
    utility = "23%"
}
]]--
local testFrameArgs = {
    get = "",
	image = 'Uprising_Icon_Item_Base_M_Chest_00060_V.png',
	name = 'Elemental Bounty Hunter Jacket',
	description = 'Defensive gear used by the Ivax Syndicate. This improved variant also gives the wearer resistance to Toxic damage!',
	tier = '2',
    baseStarLevel = '',
	evolution = '0',
	stars = '5',
	maxstarcount = '7',
	type = 'torso',
	location = 'Bespin',
	gearSetName = 'Elemental Bounty Hunter',
	gearSetBaseName = 'Bounty Hunter',
	gearSetDisplayName = 'Elemental Bounty Hunter',
    faction = 'Ivax Syndicate',
    gearType = 'Defensive',
	baseLevel = '90',
	levelCap = '120',
	navNext = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment/Elemental_Improved_Bounty_Hunter_Jacket/T2',
	baseStat = '250',
	attack = '21.5%',
	attackMin = '660',
	attackBase = '1964',
	attackMax = '2796',
	armor = '49.5%',
	armorMin = '1518',
	armorBase = '4521',
	armorMax = '6435',
	utility = '29%',
	utilityMin = '889',
	utilityBase = '2648',
	utilityMax = '3770',
	mod1Name = 'Control',
	mod1Value = '+5%',
	mod2Name = 'Attack Speed',
	mod2Value = '+4%',
	mod3Name = 'Accuracy',
	mod3Value = '+3%',
	mod4Name = 'Toxic Protection',
	mod4Value = '+10%',
	upgradeComponent1Name = 'Polished Carbonite',
	upgradeComponent1Type = 'Carbonite',
	upgradeComponent1Prefix = 'Polished',
	upgradeComponent1Count = '3',
	upgradeComponent2Name = 'Polished Chunah',
	upgradeComponent2Type = 'Chunah',
	upgradeComponent2Prefix = 'Polished',
	upgradeComponent2Count = '3',
	upgradeComponent3Name = 'Polished Electrum',
	upgradeComponent3Type = 'Electrum',
	upgradeComponent3Prefix = 'Polished',
	upgradeComponent3Count = '3',
	upgradeCost = '432000',
	sellPriceMin = '64800',
	sellPriceMax = '194400'
}

local testParentFrameArgs = {
    --get = "iconborder",
	--arg1 = "size:exsmall"
}

function reduceTable(tbl, depth)
	if tbl == nil then return nil end
	for i,v in ipairs(tbl) do
		--if type(v) == "number" then
			--tbl[i] = tostring(v)
		--elseif v == nil then
			--tbl[i] = ''
		--elseif v == true then
			--tbl[i] = 'true'
		--elseif v == false then
			--tbl[i] = 'false'
		if type(v) == "table" then
			tbl[i] = concatAll(v, (depth or 1) + 1)
		end
	end
	return tbl
end

function concatAll(tbl, depth)
	if tbl == nil then return '' end
	if type(tbl) ~= "table" then return tostring(tbl) end
	if depth and depth > 20 then return '<table>' end
	return tableconcat(reduceTable(tbl, depth or 0) or {})
end

-- test frame
p.childFrame = {
    -- Child frame's arguments (change as needed)
    --args = mw.clone(testFrameArgs),
    args = testFrameArgs,
    getParent = function()
        --local pArgs = _extend({}, testFrameArgs, testParentFrameArgs)
        local pArgs = testParentFrameArgs
        return { args = pArgs }
    end
}

function p.childFrame:getParent()
    --local pArgs = _extend({}, testFrameArgs, testParentFrameArgs)
    local pArgs = testParentFrameArgs
    return { args = pArgs }
end


function toLower(str)
    if str == nil then
        return nil
    end
    
    return uslower(tostring(str))
end

function toNum(str, def)
	if type(str) == "number" then
		return str
	elseif str == '' then
		return nil
	elseif type(str) == "boolean" then
		return (str == true and 1 or 0)
	end
	
	local isNum = (type(str) == "string" and (txttrim(tostring(str)):match('^([%d]+%.?[%d]*)$')) or nil)
	
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

function toPrecision(num, prec, asNum)
	local _prec = (prec or 0)
    local deci, frac = math.modf(num)
    if frac == 0 then
      return (tostring(deci) .. '.' .. usrep('0', _prec))
    end
    local deci2 = tostring(math.floor((frac * math.pow(10, math.min(uslen(tostring(frac)), prec or 1))) + 0.5))
	local deci2len = uslen(deci2)
	
	local result = (tostring(deci) .. ((_prec > 0 and deci2len > 0 and ('.' .. deci2)) or ''))
	
	if asNum ~= true and deci2len < _prec then
		result = result .. (usrep('0', math.max(1, _prec - deci2len)))
	end
	
	return (asNum == true and tonumber(result) or result)
end

function getTierNum(str)
	if str and str ~= '' then
		if tostring(str) == '2' or (type(str) == "string" and (s == 'II' or s == 'ii')) then
			return 2
		end
	end
	return 1
end

function firstToUpper(str)
    if str == nil then
        return nil
    end
    --return (str:gsub("^%l", mw.ustring.upper))
    --return (usgsub(str, "^%l", mw.ustring.upper))
    return lang():ucfirst(str)
end

function ternary(cond, T, F)
    if cond then
        return T
    else
        return F
    end
end

--[[
function table_val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table_key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table_val_to_str( k ) .. "]"
  end
end

function table_tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    tableinsert( result, table_val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      tableinsert( result,
        table_key_to_str( k ) .. "=" .. table_val_to_str( v ) )
    end
  end
  return "{" .. tableconcat( result, ",\r\n\t" ) .. "}"
end
]]--

function table_towikiargs( tbl )
  local result = {}
  for k, v in pairs( tbl ) do
      tableinsert( result, k .. "=" .. v )
  end
  return tableconcat( result, "|" )
end


function Yesno(val, default)
    val = type(val) == 'string' and toLower(val) or val
    if val == nil then
        return nil
    elseif val == true 
        or val == 'yes'
        or val == 'y'
        or val == 'true'
        or val == 't'
        or tonumber(val) == 1
    then
        return true
    elseif val == false
        or val == 'no'
        or val == 'n'
        or val == 'false'
        or val == 'f'
        or tonumber(val) == 0
    then
        return false
    else
        return default
    end
end

function stripNS(str)
  local result = usmatch(str, "^[^/:]:(.+)$")
  if result ~= nil then
    return result
  end
  
  return str
end

function stripWalkthrough(str)
  local result = usmatch(str, "Star[%s_]+Wars:[%s_]+Uprising[%s_]+Super[%s_]Walkthrough/(.+)$")
  if result ~= nil then
    return result
  end
  
  return stripNS(str)
end

function stripFirstSubpage(str)
  local result = usmatch(str, "Star[%s_]+Wars:[%s_]+Uprising[%s_]+Super[%s_]Walkthrough/[%w_]+/(.+)$")
  if result ~= nil then
    return result
  end
  
  return stripWalkthrough(str)
end

function stripPrefix(str)
  local result = stripFirstSubpage(str)
  if result ~= nil then
    return result
  end
  
  return str
end

function replaceAllWhitespace(str, repl)
    if str == nil or str == '' then return str or nil end
    --return usgsub(str, "%s+", repl or '') or nil
    --return string.gsub(str, "%s+", repl or '') or nil
	return tableconcat(txtsplit(str or '', '%s+') or {}, repl or '')
end

function _isCalcStatValue(key)
    if key == nil or key == '' then
        return nil
    end
    local root,suffix = usmatch(toLower(key or ''), '^(.-)([bB]?[Mma][sia][enx])$')
    
    if root == nil or suffix == nil or root == '' or suffix == '' or (suffix ~= 'min' and suffix ~= 'max' and suffix ~= 'base' and suffix ~= 'ase') or (root ~= 'attack' and root ~= 'armor' and root ~= 'utility') then
        return nil
    end
    return {
        name = root,
        suffix = (suffix == 'ase' and 'base' or suffix)
    }
end

function _getGearTypeData(_name)
    local _lName = toLower(replaceAllWhitespace(_name, ''))
    
    if _lName == nil then
        return nil
    elseif _lName == 'balance' or _lName == 'balanced' then
        return {
            name = 'Balanced',
            icon = 'defense-offense-box',
            iconFilterColor = 'filter-exlite-yellow',
            salvage = 'Kiax Crystals'
        }
    elseif _lName == 'util' or _lName == 'utility' then
        return {
            name = 'Utility',
            icon = 'utility-box',
            iconFilterColor = '',
            salvage = 'Carbonite Crystals'
        }
    elseif _lName == 'offense' or _lName == 'offensive' then
        return {
            name = 'Offensive',
            icon = 'weapon-box',
            iconFilterColor = '',
            salvage = 'Aurodium Crystals'
        }
    elseif _lName == 'def' or _lName == 'defense' or _lName == 'defensive' then
        return {
            name = 'Defensive',
            icon = 'defense-box',
            iconFilterColor = '',
            salvage = 'Lanthanide Crystals'
        }
    elseif _lName == 'weapon' then
        return {
            name = 'Weapon',
            icon = 'salvage-equipment',
            iconFilterColor = 'filter-white',
            salvage = 'Agrocite Crystals'
        }
    end
    
    return nil
end

function _getFactionData(_name)
    local _lName = toLower(replaceAllWhitespace(_name, ''))
    
    if _lName == nil then
        return nil
    elseif _lName == 'rebel' or _lName == 'alliance' or _lName == 'rebelalliance' then
        return {
            name = 'Rebel',
            icon = 'salvage-alliance',
            iconFilterColor = '',
            salvage = 'Lothalite Crystals'
        }
    elseif _lName == 'trade' or _lName == 'tradespine' or _lName == 'tradespineleague' then
        return {
            name = 'Trade Spine',
            icon = 'salvage-trade-spine',
            iconFilterColor = '',
            salvage = 'Berubium Crystals'
        }
    elseif _lName == 'ivax' or _lName == 'syndicate' or _lName == 'ivaxsyndicate' then
        return {
            name = 'Ivax Syndicate',
            icon = 'salvage-ivax',
            iconFilterColor = '',
            salvage = 'Chunah Crystals'
        }
    elseif _lName == 'kouhun' then
        return {
            name = 'Kouhun',
            icon = 'salvage-kouhun',
            iconFilterColor = '',
            salvage = 'Dathomite Crystals'
        }
    elseif _lName == 'noble' or _lName == 'court' or _lName == 'noblecourt' or _lName == 'noble court' then
        return {
            name = 'Noble Court',
            icon = 'salvage-nobles',
            iconFilterColor = '',
            salvage = 'Valorumite Crystals'
        }
    elseif _lName == 'imperial' or _lName == 'empire' or _lName == 'imperialempire' or _lName == 'galacticempire' then
        return {
            name = 'Imperial',
            icon = 'salvage-empire',
            iconFilterColor = '',
            salvage = 'Havod Crystals'
        }
    end
    
    return nil
end



function p._genStars(frame, args, getValue, argNames, _minWidth, style)
    local stars = tonumber(getValue('stars', false) or 0)
    local maxStarCount = tonumber(getValue('maxstarcount', '0') or 0)
    if maxStarCount > 7 then
        maxStarCount = 7
    end
    local noMinWidth = getValue('nominwidth', false)
    local minWidth = _minWidth or getValue('minwidth', false) or '250px'
    
    local minWidthStr = ''
    
    if noMinWidth == nil or Yesno(noMinWidth, false) == false then
        minWidthStr = 'min-width:' .. minWidth .. ';'
    end
    

    local out = '<div style="font-size:25px;color:#063053;text-align:center;cursor:default;' .. minWidthStr .. (style or '') .. '" title="Base Level / Max Level"><span>'
    
    if stars > 0 then
        for i=1,stars do
            out = out .. '&#9733;'
        end
    end
    
    if maxStarCount > stars then
        for i=stars,(maxStarCount - 1) do
            out = out .. '&#9734;'
        end
    end
    
    out = out .. '</span></div>'
    
    return out
end

function resolveType(_type)
    _type = toLower(_type)
    if type == 'weapon' then
        return 'weapon'
    end
    return ''
end

function p._genInfo(frame, args, getValue)
    local _type = getValue('type', '')
    local _lType = toLower(_type)
    --local base = getValue('baseStat', false) or getValue('base', '')
    local baseLevel = getValue('baseLevel', false)
    local element = getValue('element', false)
    local lElement = toLower(element)
    local faction = getValue('faction', false)
    local gearType = getValue('gearType', false) or getValue('archetype', false)
    local typeIcon = nil
    local typeIconLink = ''
    local typeIconSize = '75px'
    local typeIconStyle = 'top:-15px;left:-15px;'
    
    if _lType == 'weapon' or _lType == 'weapons' then
        typeIcon = 'Uprising_Icon_SlotWeapon.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Weapons'
    elseif _lType == 'chest' or _lType == 'torso' then
        typeIcon = 'Uprising_Icon_SlotTorso.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Torso'
    elseif _lType == 'lowerbody' or _lType == 'legs' or _lType == 'leg' or _lType == 'lower' then
        typeIcon = 'Uprising_Icon_SlotLegs.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Legs'
    elseif _lType == 'helm' or _lType == 'helmet' or _lType == 'head' then
        typeIcon = 'Uprising_Icon_SlotHead.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Head'
    elseif _lType == 'gloves' or _lType == 'glove' or _lType == 'hands' or _lType == 'hand' then
        typeIcon = 'Uprising_Icon_SlotHands.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Hands'
    elseif _lType == 'backpack' or _lType == 'back' then
        typeIcon = 'Uprising_Icon_SlotBackpack.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Back'
    else
        typeIcon = 'Uprising_Icon_Status_Missing.png'
        typeIconLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment'
        typeIconStyle = 'top:-8px;left:-8px;'
        typeIconSize = '55px'
    end
    
    -- background-color:#ced7e0;
    local defaultHeight = '30px'
    local underlineStyle = 'cursor:help;border-bottom:1px dotted black;'
    local dtStyle = 'margin-bottom:0;margin-right:5px;float:left;width:105px;letter-spacing:1px;font-size:0.8em;height:' .. defaultHeight .. ';min-height:' .. defaultHeight .. ';display:table;'
    local ddStyle = 'margin-bottom:0;margin-left:0;width: 100%;font-size:1.1em;height:' .. defaultHeight .. ';line-height:' .. defaultHeight .. ';'
    
    
    local makeDT = function(_content, _class, _style, _title)
        return ('<dt class="' .. (_class or '') .. '" style="' .. dtStyle .. (_style or '') .. '" ' .. (_title and (' title="' .. _title .. '"') or '') .. '><div class="class-style " style="width:80px;max-width:80px;overflow:hidden;white-space:normal;vertical-align:middle;line-height:1em;display:table-cell;padding-left:2px;">' .. _content .. '</div><div style="display:table-cell;min-width: 0px;">&nbsp;</div></dt>')
    end
    
    local rowCount = 0
    local makeDD = function(_content, _class, _style, _title)
        rowCount = rowCount + 1
        return ('<dd class="' .. (_class or '') .. '" style="' .. ddStyle .. (rowCount % 2 == 0 and ('background-color: rgba(128, 128, 128, 0.2);') or '' ) .. (_style or '') .. '" ' .. (_title and (' title="' .. _title .. '"') or '') .. '>' .. _content .. '</dd>')
    end
    
    local makeSprite = function(_name, _size, _marginLeft, _class, _style)
        return ('<div class="uprising-sprite ' .. _name .. (_size and (' ' .. _size) or 'small') .. (_class and (' ' .. _class) or '') .. '" style="position:absolute;margin: 0px 0px 0px ' .. (_marginLeft or '-33px') .. ';' .. (_style or '') .. '"></div>')
    end
    

    local out = '<div class="magistral-font" style="width:100%;min-width:240px;text-align:left;margin-top:-5px;margin-bottom:-5px;position:relative;">'
        
        --if typeIcon ~= nil then
            --out = out ..
                --'<div class="type-icon" style="position:absolute;top:0px;right:0px;height:45px;width:45px;margin-top:3px;margin-right:0px;overflow:hidden;">' ..
                    --'<div style="position:absolute;' .. typeIconStyle .. '">' ..
                        --'[[File:' .. typeIcon .. '|link=' .. typeIconLink .. '|' .. typeIconSize .. ']]' ..
                    --'</div>' ..
                --'</div>'
        --end
        
        
        out = out .. '<dl style="margin:0 0 3px 0;white-space: nowrap;overflow:hidden;">'
        
            out = out .. makeDT('Type:') .. makeDD(firstToUpper(_type))
            
            if baseLevel and baseLevel ~= '' then
                out = out .. makeDT('<span style="' .. underlineStyle .. '">Base Level</span>:', '', '', 'The item\'s initial \'Power Up Level\' level (used when calculating item\'s stats) &#10;&#x0a;Note: New items generally start at a level far below this number.') .. makeDD(tostring(baseLevel))
            end
            
            if faction and faction ~= '' then
                
                local factionData = _getFactionData(faction)
                if factionData ~= nil and factionData.icon then
                    out = out .. makeDT('Faction:') .. makeDD(makeSprite((factionData.iconFilterColor or '') .. ' ' .. factionData.icon, 'small', '-33px') .. factionData.name)
                else
                    out = out .. makeDT('Faction:') .. makeDD(firstToUpper(faction))
                end
            end
            
            if gearType and gearType ~= '' then
                local gearTypeData = _getGearTypeData(gearType)
                if gearTypeData ~= nil and gearTypeData.icon then
                    out = out .. makeDT('Gear Type:') .. makeDD(makeSprite((gearTypeData.iconFilterColor or '') .. ' ' .. gearTypeData.icon, 'small', '-33px') .. gearTypeData.name)
                else
                    out = out .. makeDT('Gear Type:') .. makeDD(firstToUpper(gearType))
                end
            end
            
            if element and element ~= '' then
                
                
                local elementIconName = nil
                local elementContentPrefix = ''
                
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
                elseif lElement == 'neutral' then
                    elementIconName = 'generic-hexagon'
                end
                
                if elementIconName ~= nil then
                    elementContentPrefix = makeSprite(elementIconName, 'small', '-33px')
                end
                
                out = out .. makeDT('Element:') .. makeDD(elementContentPrefix .. firstToUpper(element))
            end
        
        out = out .. '</dl>'
    
    out = out .. '</div>'
    
    return out
end


function p._genNav(frame, args, getValue)
    local navNext = getValue('navNext', false)
    local navPrev = getValue('navPrev', false)
    

    local out = '<div style="width:100%;min-height:18px;">'
    
        out = out .. '<div class="magistral-font" style="float:right;margin-right:5px;letter-spacing:1px;">'
            if navNext then
                out = out .. '[[' .. navNext .. '|Next &#62;]]'
            else
                out = out .. '<span style="opacity:0.3;">Next &#62;</span>'
            end
        out = out .. '</div>'
        
        
        out = out .. '<div class="magistral-font" style="float:left;margin-left:5px;letter-spacing:1px;">'
            if navPrev then
                out = out .. '[[' .. navPrev .. '|&#60; Prev]]'
            else
                out = out .. '<span style="opacity:0.3;">&#60; Prev</span>'
            end
        out = out .. '</div>'
            
    out = out .. '</div>'
    
    return out
end

function _getStatsTableCellProps(name, value, style, styleTitle, styleText)
    style = style or ''
    styleTitle = styleTitle or ''
    styleText = styleText or ''
    local _name = toLower(name)
    
    local tdClass = ''
    local titleColor = 'rgba(54, 148, 202, 0.4)'
    local bgColor = 'rgb(18, 48, 98)'
    local txtColor = 'rgba(54, 148, 202, 1)'
    local displayName = ''
    local shortName = ''
    
    if _name == 'attack' then
        bgColor = 'rgb(18, 48, 98)'
        titleColor = 'rgba(54, 148, 202, 0.4)'
        txtColor = 'rgba(54, 148, 202, 1)'
        displayName = 'Attack'
        shortName = 'Attack'
    elseif _name == 'armor' then
        bgColor = 'rgb(33, 29, 66)'
        titleColor = 'rgba(120, 93, 136, 0.4)'
        txtColor = 'rgba(120, 93, 136, 1)'
        displayName = 'Armor'
        shortName = 'Armor'
    elseif _name == 'utility' then
        bgColor = 'rgb(23, 38, 46)'
        titleColor = 'rgba(35, 149, 115, 0.4)'
        txtColor = 'rgba(35, 149, 115, 1)'
        displayName = 'Utility'
        shortName = 'Utility'
    elseif _name == 'ranged' then
        bgColor = 'rgb(18, 48, 98)'
        titleColor = 'rgba(54, 148, 202, 0.4)'
        txtColor = 'rgba(54, 148, 202, 1)'
        displayName = 'Ranged'
        shortName = 'Ranged'
    elseif _name == 'dodge' then
        bgColor = 'rgb(33, 29, 66)'
        titleColor = 'rgba(120, 93, 136, 0.4)'
        txtColor = 'rgba(120, 93, 136, 1)'
        displayName = 'Dodge'
        shortName = 'Dodge'
    elseif _name == 'attackspeed' or _name == 'attack speed' then
        bgColor = 'rgb(18, 48, 98)'
        titleColor = 'rgba(54, 148, 202, 0.4)'
        txtColor = 'rgba(54, 148, 202, 1)'
        displayName = 'Attack Speed'
        shortName = 'Attk Spd'
    elseif _name == 'levelcap' or _name == 'level cap' or _name == 'max upgrade level' or _name == 'max level' then
        bgColor = 'rgb(206, 204, 77)'
        titleColor = 'rgba(0, 0, 0, 0.4)'
        txtColor = 'rgba(0, 0, 0, 0.8)'
        displayName = 'Max Upgrade Level'
        shortName = 'Max Level'
        styleText = styleText .. 'font-size: 1.75em;line-height: 25px;'
    elseif _name == 'tier' then
        bgColor = 'rgba(255, 255, 255, 0.8)'
        --titleColor = 'rgba(0, 0, 0, 0.4)'
        --txtColor = 'rgba(0, 0, 0, 0.8)'
        --bgColor = 'rgb(6,48,83)'
        titleColor = 'rgba(255, 255, 255, 0.5)'
        txtColor = 'rgba(255, 255, 255, 0.9)'
        displayName = 'Tier'
        shortName = 'Tier'
        styleText = styleText .. 'font-size: 1.75em;line-height: 25px;letter-spacing: 1px;'
        tdClass = 'class-style std-background-grad-blue2'
        
        if value == nil or value == '' or tostring(value) == '1' or toLower(value) == 'i' then
            value = 'I'
        elseif value == '?' then
            value = '?'
        elseif tostring(value) == '2' or toLower(value) == 'ii' then
            value = 'II'
            bgColor = 'rgb(216,117,4)'
            titleColor = 'rgba(255, 255, 255, 0.5)'
            txtColor = 'rgba(255, 255, 255, 0.9)'
            tdClass = 'class-style std-background-grad-orange2'
            
        elseif tostring(value) == '3' or toLower(value) == 'iii' then
            value = 'III'
            -- T3 colors are still unknown. Will update when T3 items are available.
            bgColor = 'rgb(216,117,4)'
            titleColor = 'rgba(255, 255, 255, 0.5)'
            txtColor = 'rgba(255, 255, 255, 0.9)'
            tdClass = 'class-style std-background-grad-orange'
        end
    else
        if type(_name) == 'string' then
            displayName = _name
            shortName = _name
        end
    end
    
    local props = {
        name = name,
        value = value,
        style = style,
        styleTitle = styleTitle,
        styleText = styleText,
        
        tdClass = tdClass,
        titleColor = titleColor,
        bgColor = bgColor,
        txtColor = txtColor,
        displayName = displayName,
        shortName = shortName
    }
    
    return props
end

function _genStatsTableCellContent(props)
    local out = ''
    out = out .. '<div style="font-size: 1.5em; font-weight: 400; color: ' .. props.titleColor .. ';white-space:nowrap;line-height:0.75em;' .. (props.styleTitle or '') .. '">' .. props.shortName .. '</div>'
    out = out .. '<div style="line-height:15px;color:' .. props.txtColor .. ';' .. (props.styleText or '') .. '">' .. (props.value or '') .. '</div>'
    return out
end


function _genStatsTableCell(name, value, colspan, style, styleTitle, styleText)
    local _colspan = colspan and (' colspan="' .. colspan .. '" ') or ''
    style = style or ''
    styleTitle = styleTitle or ''
    styleText = styleText or ''
    local props = _getStatsTableCellProps(name, value, style, styleTitle, styleText)
    
    local out = '<td ' .. _colspan .. 'class="' .. props.tdClass .. '" style="text-align:center;' .. 'background-color:' .. props.bgColor .. ';padding:10px 5px 5px;border-color:#BFDAEB;' .. (props.style or '') .. '" title="' .. props.displayName .. '">'
    
    out = out .. _genStatsTableCellContent(props)
    --out = out .. '<div style="font-size: 1.5em; font-weight: 400; color: ' .. props.titleColor .. ';white-space:nowrap;line-height:0.75em;' .. (props.styleTitle or '') .. '">' .. props.shortName .. '</div>'
    --out = out .. '<div style="line-height:15px;color:' .. props.txtColor .. ';' .. (props.styleText or '') .. '">' .. (props.value or value) .. '</div>'
    
    out = out .. '</td>'
    
    return out
end

function p._genStatsTable(frame, args, getValue)
    local attack = getValue('attack', '?')
    local armor = getValue('armor', '?')
    local utility = getValue('utility', '?')
    
    --local ranged = getValue('ranged', '?')
    --local dodge = getValue('dodge', '?')
    --local attackspeed = getValue('attackspeed', '?')
    
    
    local levelCap = getValue('levelcap', false)
    local tier = getValue('tier', false)
    
    local tierProps = _getStatsTableCellProps('tier', tier)
    local levelCapProps = _getStatsTableCellProps('levelcap', levelCap)
    
    local rowTemplate = '<tr class="magistral-font">'

    local out = '<table class="infobox-nav-table" style="background-color:#BFDAEB;table-layout:fixed;cursor:default;width:100%;width:calc(100% + 8px);margin:-4px;" cellspacing="0" cellpadding="0" rules="all">' ..
        '<tr>' ..
            '<th class="infobox-nav-table-title" colspan="3" style="background-color:rgb(191, 218, 235);border-color:rgb(0, 0, 0);padding:5px 4px;text-align: left;letter-spacing:1px;">' ..
                'Base Stats&nbsp;&nbsp;&nbsp;[[Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Stats|<span style="font-size:10px;text-decoration:none;color:rgba(255,255,255,0.7) !important;">What is this?</span>]]' ..
            '</th>' ..
        '</tr>'
    

    out = out .. rowTemplate .. '<td colspan="3" style="padding: 0px; width: 100%;border-color: rgba(255, 255, 255, 0.1);">' ..
            '<div class="' .. tierProps.tdClass .. '" style="text-align: center; background-color: ' .. tierProps.bgColor .. '; padding: 5px 0px; width: 49.8%; float: left;" title="' .. tierProps.displayName .. '">' .. _genStatsTableCellContent(tierProps) .. '</div>' ..
            '<div class="' .. levelCapProps.tdClass .. '" style="text-align: center; background-color: ' .. levelCapProps.bgColor .. '; padding: 5px 0px; width: 49.8%; float: right;" title="' .. levelCapProps.displayName .. '">' .. _genStatsTableCellContent(levelCapProps) .. '</div>' ..
        '</td></tr>'
    
    
    out = out .. rowTemplate .. _genStatsTableCell('attack', attack) .. _genStatsTableCell('armor', armor) .. _genStatsTableCell('utility', utility) .. '</tr>'
    
    -- ToDo:
    --     Update to use mods instead of just static names
    --out = out .. rowTemplate .. _genStatsTableCell('ranged', ranged) .. _genStatsTableCell('dodge', dodge) .. _genStatsTableCell('attackspeed', attackspeed) .. '</tr>'
    
    --[[
    if levelCap ~= nil then
        out = out .. rowTemplate .. _genStatsTableCell('levelcap', levelCap, '3') .. '</tr>'
    end
    
    out = out .. rowTemplate .. _genStatsTableCell('tier', tier, '3') .. '</tr>'
    ]]--
    
    out = out .. '</table>'
    
    return out
end


local _modColorLists = {
    blue = {
        ["accuracy"] = true,
        ["armor penetration"] = true,
        ["attack speed"] = true,
        ["ranged damage"] = true,
        ["critical chance"] = true,["crit chance"] = true,
        ["critical damage"] = true,["crit damage"] = true,
        ["melee damage"] = true,["melee damage"] = true,
    },
    purple = {
        ["control"] = true,
        ["dodge chance"] = true,
        ["block chance"] = true,
        ["resistance"] = true,
        ["ranged protection"] = true,
        ["toxic protection"] = true,
    }
}
-- position:
--     -1: First
--      0: Middle
--      1: Last
--      2: Last and Only
function _getModLine(name, value, style, position)
    local bgColor = nil
    local txtColor = nil
    local lName = toLower(name)
    
    if _modColorLists.blue[lName] then
        bgColor = 'rgb(18, 48, 98)'
        txtColor = 'rgb(54, 148, 202)'
    elseif _modColorLists.purple[lName] then
        bgColor = 'rgb(33, 29, 66)'
        txtColor = 'rgb(120, 93, 136)'
    end
    --'margin:' .. (position > 0 and '-4px -4px -5px -4px' or '-4px -4px') .. ';' ..
    local divWrapperStyle = 'width:100%;height:100%;position:relative;min-width:250px;min-height:25px;margin:-4px -4px -5px -4px;' ..
        (position ~= -1 and 'border-top:1px solid rgba(255, 255, 255, 0.2);' or '') ..
        (bgColor and ('background-color:' .. bgColor .. ';') or '') ..
        (txtColor and ('color:' .. txtColor .. ';') or '') ..
        (style or '')
    
    
    local out = '' ..
        '<div class="magistral-font" style="' .. divWrapperStyle .. '">' ..
            '<table style="width: 100%; height: 100%;">' ..
                '<tr>' ..
                    '<th style="text-align:left;padding-left:5px;letter-spacing: 1px;">\'\'\'' ..
                        name ..
                    '\'\'\'</th>' ..
                    '<td style="text-align:right;padding-right:5px;">' ..
                        value ..
                    '</td>' ..
                '</tr>' ..
            '</table>' ..
        '</div>'
    return out
end


function p._genUpgradeTable(frame, args, getValue)
	--background-color: rgba(6, 48, 83, 0.6);
	--background-color:rgba(0, 0, 0, 0.8);
	local upgradeList = {'<div class="full-width-container class-style position-relative margin--4px" style="position:relative;min-width:100%;width:100%;width:calc(100% + 8px);margin:-4px;color: white;"><table class="class-style width-100-pct border-collapse-collapse" style="width:100%;border-collapse:collapse;"><tr><td colspan="2" class="magistral-font class-style letter-spacing-1px white-space-nowrap" style="text-align:center;vertical-align:middle;letter-spacing:1px;font-size:1.3em;white-space:nowrap;padding:5px 0;color:#3a3a3a;" title="Upgrade Cost">Total&nbsp;Cost:&nbsp;<div style="display: inline; position: relative; top: -2px;vertical-align:middle;">[[File:Uprising_Icon_Credits.png|middle|link=|18px]]</div>' .. tostring(getValue('upgradeCost', 'N/A')) .. '</td></tr>'}
	local upgradeCount = 0
	
	local UC = UprisingComponents()
	
	local processUpgradeComponent = function(index)
		local isOddRow = (upgradeCount > 0 and math.fmod(upgradeCount, 2) == 1 and true or false)
		
		-- Component Values
		local keyPrefix = 'upgradeComponent' .. tostring(index)
		local name = getValue(keyPrefix .. 'name', false)
		local count = getValue(keyPrefix .. 'count', false)
		if count == nil or tostring(count) == '' or tonumber(count) == 0 then return nil end
		local _type = getValue(keyPrefix .. 'type', false)
		local prefix = getValue(keyPrefix .. 'prefix', false)
		
		-- Get Icon
		local UCIcon = UC.genIconBorder{name = (prefix and _type or name), level = prefix, tier = getValue('tier', '1'), size = 'exsmall', nopreprocess = true}
		if UCIcon == nil then
			UCIcon = 'Icon Missing'
			
		end
		
		-- Define Default Values and Styles
		--rgba(0, 0, 0, 0.5)
		--rgba(18, 48, 98, 0.9)
		local rowStyle = 'background-color: rgba(128, 128, 128, 0.2);color:#3a3a3a;'
		local titleText = (name ~= '' and name or ((prefix and prefix .. ' ' or '') .. (_type or '')))
		local titleLength = mw.ustring.len(titleText)
		local underlineColor = 'white'
		local titleLeftPadding = math.max(0, (math.min(11, 23 - titleLength)))
		--local tierFontSizeStyle = (titleLength >= 18 or titleLeftPadding == 0 and 'font-size:0.8em;' or (titleLength <= 12 and 'font-size:1.1em;' or ''))
		
		if titleText == '' then return nil end
		
		-- Modify Even/Odd Styles
		if isOddRow then
			rowStyle = 'color:#3a3a3a;'
			--underlineColor = ''
		end
		

		

		-- Polished Chunah
		-- Perforated Mephitine
		
		
		local usePrice = (UCIcon == 'Icon Missing' and '?' or (UC.getValue{get = 'useprice', name = (prefix and _type or name), level = prefix, tier = getValue('tier', '1'), size = 'exsmall', nopreprocess = true} or '?'))
		
		-- transparent linear-gradient(to bottom, rgba(6, 48, 83, 0) 0%, rgb(51, 81, 119) 100%) repeat scroll 0% 0%
		-- ', (underlineColor ~= '' and ('-' .. underlineColor) or ''), '
		--background-color: rgba(18, 48, 98, 0.5);
		local ucRowTbl = {
			'<tr style="', rowStyle, '">',
				'<td class="magistral-font class-style max-width-min-content width-fit-content" style="',
						'max-width:-webkit-min-content;max-width:-moz-min-content;max-width:min-content;width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;vertical-align:middle;padding:3px 1px 3px 0px;',
					'">', UCIcon, '</td>',
				'<td class="magistral-font class-style position-relative text-align-left" style="position:relative;text-align:left;padding:3px 5px 3px 2px;">',
					'<div class="class-style white-space-nowrap text-align-justify text-align-last-justify" style="text-align: justify;-webkit-text-align-last:justify;-moz-text-align-last:justify;text-align-last:justify;white-space:nowrap;padding-bottom:5px;">',
						'<span class="class-style vertical-align-middle underline-dotted cursor-pointer" style="font-size:0.7em;vertical-align:middle;cursor:pointer;border-bottom:1px dotted #3a3a3a;" title="Tier Level">\'\'\'T', tostring(getValue('tier', '1')), '\'\'\'</span>&nbsp;',
						'<span class="class-style text-overflow-ellipsis vertical-align-middle" style="font-size:1.2em;vertical-align:middle;text-overflow:ellipsis;padding-left:', tostring(titleLeftPadding), '%;" title="', titleText, '">', titleText, '</span>',
					'</div>',
					'<div class="class-style position-relative text-align-left" style="position:relative;width:100%;line-height: 1em;text-align:left;">',
						'<div class="class-style cursor-pointer underline-dotted float-left text-align-left" style="font-size:1em;float:left;text-align:left;letter-spacing:0px;cursor:pointer;padding-bottom: 2px;border-bottom:1px dotted #3a3a3a;" title="# required to upgrade">x&nbsp;', tostring(count), '</div>',
						'<div class="class-style float-right text-align-right" style="font-size:1.1em;float:right;text-align:right;" title="Use Price">',
							'<div class="class-style display-inline position-relative top--2px" style="display: inline; position: relative; top: -2px;vertical-align:middle;">[[File:Uprising_Icon_Credits.png|middle|link=|13px]]</div>',
								usePrice,
							'</div>',
					'</div>',
				'</td>',
			'</tr>'
		}
		
		tableinsert(upgradeList, concatAll(ucRowTbl))
		upgradeCount = upgradeCount + 1
	end
	
	for i=1,6 do
		if getValue('upgradeComponent' .. tostring(i) .. 'name', false) ~= nil then
			processUpgradeComponent(i)
		else
			break
		end
	end
	
	if upgradeCount == 0 then return nil end
	
	tableinsert(upgradeList, '</table></div>')
	
	return tableconcat(upgradeList, '')

end


function callInfoboxTemplate(frame, args)
    return frame:expandTemplate{title = 'UprisingEquipmentInfobox/main2', args = args}
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

function p._genInfobox(frame, args, getValue, argNames)
    local tier = getValue('tier', '1')
    local noImageBG = getValue('noimagebg', true)
    local sellPriceMin = getValue('sellPriceMin', false)
    local sellPriceMax = getValue('sellPriceMax', false)
    local upgradeCost = getValue('upgradeCost', false)
    
    
    local infoboxArgs = {
        name = '',
        description = '',
        tier = '1',
        stars = '0',
        maxStarCount = '0',
        credits = '?'
    }
    
    local setIBoxValue = function(key, oKey, val)
        local _lKey = toLower(key)
        
        local statKeyInfo = _isCalcStatValue(_lKey)
        
        if statKeyInfo ~= nil and statKeyInfo.suffix ~= nil then
            
            local statTitle = ''
            
            if statKeyInfo.suffix == 'min' then
                statTitle = 'Calculated at level 1'
            elseif statKeyInfo.suffix == 'base' then
                statTitle = 'Calculated at level ' .. (getValue('baseLevel', '?'))
            elseif statKeyInfo.suffix == 'max' then
                statTitle = 'Calculated at level ' .. (getValue('levelCap', '?'))
            end
            infoboxArgs[oKey] = '<div class="magistral-font" style="font-size:1.2em;letter-spacing:1px;text-align:center;' .. (statTitle ~= '' and ('cursor:help;') or '') .. '" title="' .. statTitle .. '">' .. val .. '</div>'
        else
            infoboxArgs[oKey] = val
        end
    end
    
    for k, v in pairs(args) do
        if argNames[k] ~= nil then
            -- infoboxArgs[argNames[k]] = getValue(k, true)
            setIBoxValue(k, argNames[k], getValue(k, true))
        else
            setIBoxValue(k, k, getValue(k, true))
            -- infoboxArgs[k] = getValue(k, true)
        end
    end
    
    infoboxArgs.name = '<div style="text-align:center;letter-spacing:1px;">' .. infoboxArgs.name .. '</div>'
    infoboxArgs.description = '<div style="text-align:center;margin-top:5px;margin-bottom:4px;min-width:250px;"><div style="padding: 0px 5px;">' .. (infoboxArgs.description or '') .. '</div></div>'
    infoboxArgs.stars = p._genStars(frame, args, getValue, argNames)
    infoboxArgs.info = p._genInfo(frame, args, getValue)
    infoboxArgs.credits = '<div class="magistral-font class-style text-align-center" style="font-size:1.3em;text-align:center;">' ..
        ((sellPriceMin or sellPriceMax) and ((sellPriceMin and ('<div style="display: inline; position: relative; top: -2px;">[[File:Uprising_Icon_Credits.png|middle|link=|18px]]</div><span title="Min">' .. sellPriceMin .. '</span>') or '?') .. '&nbsp;-&nbsp;' .. (sellPriceMax and ('<div style="display: inline; position: relative; top: -3px;">[[File:Uprising_Icon_Credits.png|middle|link=|18px]]</div><span title="Max">' .. sellPriceMax .. '</span>') or '')) or ('<div style="display: inline; position: relative; top: -2px;">[[File:Uprising_Icon_Credits.png|middle|link=|18px]]</div><span title="Max">' .. (infoboxArgs.credits or '?') .. '</span>')) .. '</div>'
    infoboxArgs.statTable = p._genStatsTable(frame, args, getValue)
	infoboxArgs.upgradeComponents = p._genUpgradeTable(frame, args, getValue)
    infoboxArgs.navigation = p._genNav(frame, args, getValue)
    
    local c = 0
    
    for i=6,1,-1 do
        if getValue('mod' .. tostring(i) .. 'Name', false) ~= nil and getValue('mod' .. tostring(i) .. 'Value', false) ~= nil then
            infoboxArgs['mod' .. tostring(i)] = _getModLine(getValue('mod' .. tostring(i) .. 'Name', false), getValue('mod' .. tostring(i) .. 'Value', false), '', (i == 0 and (c == 0 and 2 or -1) or (c == 0 and 1 or 0)))
            c = c + 1
        end
    end
    
    local out = {'<div class="UprisingEquipmentInfoboxWrapper ', noImageBG, ' ', ((tier == '2' or tier == 2) and 'tier2' or ''), '">'}
        
	local success, result = pcall(callInfoboxTemplate, frame, infoboxArgs)
	
	if success == false then
		mw.log(result)
		
		tableinsert(out, '{{UprisingEquipmentInfobox/main2|')
		tableinsert(out, table_towikiargs(infoboxArgs))
		tableinsert(out, '}}</div>')
		return Try_preprocess(frame, tableconcat(out))
	end
	
    tableinsert(out, result)
    tableinsert(out, '</div>')
    --out = out .. '</div>'
   return tableconcat(out)
    -- return frame:preprocess(out)
end




function p._genTableRow(frame, args, getValue, argNames)
    local navPrev = getValue('navPrev', false)
    local navPrevTitle = nil
    local navNext = getValue('navNext', false)
    local navNextTitle = nil
    
    local name = getValue('name', false) or ''
    local maxstarcount = getValue('maxstarcount', false)
    local stars = getValue('stars', false)
    local image = getValue('image', true)
    local tier = getValue('tier', false)
	local tierNum = getTierNum(tier)
    
    local starSort = 0
    
    local tierPath = ''
    local tierPath2 = ''
    
    
    if navPrev ~= nil then
        navPrevTitle = stripPrefix(txttrim(tostring(navPrev)))
    end
    if navNext ~= nil then
        navNextTitle = stripPrefix(txttrim(tostring(navNext)))
    end
    
    if tier ~= nil and (tier == '2' or tier == '3' or tonumber(tier) > 1) then
        tierPath = '/T' .. tostring(tier)
        tierPath2 = 'T' .. tostring(tier) .. '/'
    end
    
    if maxstarcount ~= nil and maxstarcount ~= '?' and tonumber(maxstarcount) > 0 then
        starSort = starSort + (tonumber(maxstarcount) * 10)
    end
    
    if stars ~= nil and stars ~= '?' and tonumber(stars) > 0 then
        starSort = starSort + tonumber(stars)
    end

    local out = ''
    
    -- mw.uri.encode(navPrev, 'WIKI')
    
    out = out .. '<tr class="class-style counter-increment-9">' ..
        '<td data-sort-value="'
        if navPrevTitle ~= nil then
            out = out .. mw.uri.encode(navPrevTitle, 'WIKI') .. ','
        end
        
        out = out .. mw.uri.encode(name .. tierPath, 'WIKI') .. ','
        
        if navNextTitle ~= nil then
            out = out .. mw.uri.encode(navNextTitle, 'WIKI') .. ','
        end
		
        
        out = out .. '" class="class-style white-space-nowrap text-overflow-clip max-width-85px ' .. ((tier and tierNum == 2 and 'std-background-grad-orange') or 'std-background-grad-blue2') .. '" style="width:85px;overflow:hidden;letter-spacing:1px;white-space:nowrap;text-overflow:clip;max-width:85px;">[[File:' .. (image ~= nil and image ~= '' and image or 'Uprising_Icon_Status_Missing.png') .. '|frameless|link=Wookieepedia:Star Wars: Uprising Super Walkthrough/Equipment/' .. name .. tierPath .. '|85px]]</td>' ..
		tableconcat({
            '<td class="magistral-font class-style counter-increment-', tostring(tierNum),'" style="text-align:center;font-size:20px;min-width:40px;" data-sort-value="', tostring(tierNum), '">',
                mw.ustring.rep('I', tierNum),
            '</td>',
            '<td class="magistral-font" style="text-align:center;font-size:15px;min-width:160px;" data-sort-value="', tierPath2, name, '">',
                '[[Wookieepedia:Star Wars: Uprising Super Walkthrough/Equipment/', name, tierPath, '|', name, ']]',
            '</td>',
            '<td style="text-align:center;min-width:85px;" data-sort-value="', tostring(starSort), '">',
                p._genStars(frame, args, getValue, argNames, '120px', 'font-size:21px;'),
            '</td>',
            '<td class="magistral-font" style="text-align:center;font-size:20px;min-width:50px;" data-sort-value="', getValue('levelCap', '0'), '">',
                getValue('levelCap', '?'),
            '</td>',
            '<td class="magistral-font" style="text-align:center;font-size:15px;min-width:60px;" data-sort-value="', getValue('attackMax', '0'), ',', getValue('attackMin', '0'), '">',
                '<sup><span style="font-size:14px;">', getValue('attackMin', '?'), '</span></sup>&nbsp;&#8260;&nbsp;<sub><span style="font-size:14px;">', getValue('attackMax', '?'), '</span></sub>',
            '</td>',
            '<td class="magistral-font" style="text-align:center;font-size:16px;min-width:60px;" data-sort-value="', getValue('armorMax', '0'), ',', getValue('armorMin', '0'), '">',
                '<sup><span style="font-size:14px;">', getValue('armorMin', '?') .. '</span></sup>&nbsp;&#8260;&nbsp;<sub><span style="font-size:14px;">', getValue('armorMax', '?'), '</span></sub>',
            '</td>',
            '<td class="magistral-font" style="text-align:center;font-size:16px;min-width:60px;" data-sort-value="', getValue('utilityMax', '0'), ',', getValue('utilityMin', '0'), '">',
                '<sup><span style="font-size:14px;">', getValue('utilityMin', '?'), '</span></sup>&nbsp;&#8260;&nbsp;<sub><span style="font-size:14px;">', getValue('utilityMax', '?'), '</span></sub>',
            '</td>',
		}) ..
        '</tr>'
		
    
    return out
end


function _getStarFilterColor(starLevel)
    if starLevel == nil or tostring(starLevel) == '' or tostring(starLevel) == '1' then
        return 'filter-darkgray'
    elseif tostring(starLevel) == '2' then
        return 'filter-gray'
    elseif tostring(starLevel) == '3' then
        return 'filter-green'
    elseif tostring(starLevel) == '4' then
        return 'filter-blue'
    elseif tostring(starLevel) == '5' then
        return 'filter-lite-purple2'
    elseif tostring(starLevel) == '6' or tostring(starLevel) == '7' or tostring(starLevel) == '8' then
        return 'filter-orange'
    end
    
    return ''
end

function p._genIconBorder(frame, args, getValue, argNames)
    local _get = toLower(args.get ~= nil and type(args.get) == "string" and args.get or '')
    local image = getValue('image', 'Uprising_Icon_Status_Missing.png')
    local name = getValue('name', '')
    local tier = getValue('tier', false)
    local stars = getValue('stars', false)
    local baseStarLevel = getValue('basestarlevel', false)
    local evolution = getValue('evolution', false)
    local _arg1 = toLower(getValue('arg1', false))
    local _arg2 = toLower(getValue('arg2', false))
    local _arg3 = toLower(getValue('arg3', false))
    local lElement = toLower(getValue('element', false))
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
    
    local what = _get
    local size = 'small'
    local color = 'level'
    local bg = 'level'
    local _max = false
    --local legacyArgs = ((type(_get) == "string" and get ~= '' and txtsplit(_get or '', '%', true)) or {})
    local legacyArgs = ((type(_get) == "string" and get ~= '' and txtsplit(_get or '', '%%')) or {})
    
    if legacyArgs ~= nil then
        for i,v in ipairs(legacyArgs) do
            local _v = toLower(v)
            if i == 0 then
                what = _v
                if usfind(what, 'exsmall') ~= nil then
                    size = 'exsmall'
                elseif usfind(what, 'small') ~= nil then
                    size = 'small'
                end
            elseif _v == 'max' then
                _max = true
            end
        end
    end
    
    local processArg = function(_arg)
        if _arg == 'max' then
            _max = true
        elseif usfind(_arg, '^size:') ~= nil then
            local tmpSize = usmatch(_arg, 'size:(.+)$')
            if tmpSize then
                size = toLower(tmpSize)
            end
        elseif usfind(_arg, '^color:') ~= nil then
            local tmpColor = usmatch(_arg, 'color:(.+)$')
            if tmpColor then
                color = toLower(tmpColor)
            end
        elseif usfind(_arg, '^bg:') ~= nil then
            local tmpBg = usmatch(_arg, 'bg:(.+)$')
            if tmpBg then
                bg = toLower(tmpBg)
            end
        end
    end
    
    if _arg1 then
        processArg(_arg1)
    end

    if _arg2 then
        processArg(_arg2)
    end
    
    if _arg3 then
        processArg(_arg3)
    end
----------------------------------------------------------------
-- ToDo:
--     Clean Up arguments and reduce # of time "size" is checked
----------------------------------------------------------------
	
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
		fontStyle = 'font-size-12px line-height-12px'
    else
        size = 'small'
    end
    
    local out = ''

    local starFilterColor = _getStarFilterColor(stars)
    local altText = 'T' .. (tier or '1') .. ' ' .. name .. ' &#10;&#x0a;' .. (stars or '?') .. ' Stars &#10;&#x0a;(' .. 'B' .. (baseStarLevel or '?') .. ',E' .. (evolution or '?') .. ')'
    
    local starSpriteName = ((color == 'gold' or (color == 'level' and tonumber(stars) >= 7)) and 'star-gold' or ('star-3d ' .. starFilterColor))
    local starSpriteClass = 'uprising-sprite ' .. starSpriteName .. (starSpriteName == 'gold' and 'margin-left--2px margin-top--2px margin-right-2px margin-bottom--2px ' or ' ') .. (size == 'exsmall' and 'extiny' or 'tiny') .. ' class-style float-left'
    --local starSpriteStyle = ''
    
    out = out .. '<div class="class-style position-relative display-inline-block width-' .. tostring(iconWidth) .. '-px height-' .. tostring(iconHeight) .. '-px" style="position:relative; display:inline-block;">' ..
        '<div class="uprising-sprite ' .. size .. ' equipment-container-white-bg ' .. ((tier == nil or tostring(tier) == '1') and 'filter-blue' or 'filter-darkorange2') .. ' class-style position-absolute top-0 left-0" style="position:absolute;top:0;left:0;"></div>' ..
        '<div class="uprising-sprite ' .. size .. ' ' .. ((color == 'gold' or (color == 'level' and tonumber(stars) >= 7)) and 'equipment-container-gold margin--2px' or ('equipment-container-white ' .. starFilterColor)) .. ' class-style position-absolute top-0 left-0" style="position:absolute;top:0;left:0;"></div>'
        
        if _max then
            out = out ..
                '<div class="uprising-sprite corner-flag-top-left-crop small filter-exlite-yellow class-style position-absolute top-0 left-0 magistral-font font-size-8px line-height-8px" style="font-size:9px;line-height:9px;position:absolute;top:0;left:0;">' ..
                    '<div class="class-style margin-left-3px margin-top-5px"><b>MAX</b></div>' ..
                '</div>'
        end
        
        if elementIconName ~= nil then
            out = out .. '<div class="class-style position-absolute bottom-0px left-5px margin-bottom-2px margin-left-1px" style="position:absolute;bottom:0;left:5px;"><div class="uprising-sprite ' .. elementIconName .. ' exsmall class-style"></div></div>'
        end
        
        out = out ..
			'<div class="class-style position-absolute ' .. (size == 'exsmall' and 'bottom-3px width-30-px ' or 'bottom-5px width-40-px ') .. (starSpriteName == 'gold' and 'right-3px margin-bottom-5px' or 'right-0px margin-bottom-3px') .. '" style="position:absolute;z-index:100;' .. (size == 'exsmall' and 'bottom:3px;' or 'bottom:5px;') .. '">' ..
				'<div class="' .. starSpriteClass .. '"></div>' ..
				'<div class="magistral-font class-style float-left ' .. fontStyle .. ' color-white" style="float:left;color:white;">' .. tostring(stars) .. '</div>' ..
			'</div>' ..
			'<div class="no-figure-caption-mobile class-style position-relative top-0px left-0px thumb-no-margin width-' .. tostring(iconWidth) .. '-px height-' .. tostring(iconHeight) .. '-px" style="position:relative;top:0;left:0;">' ..
				'[[File:' .. ((image and image ~= '' and image) or 'Uprising_Icon_Status_Missing.png') .. '|frameless|link=Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment/' .. name .. ((tier == nil or tostring(tier) == '1') and '' or ('/T' .. tier)) .. '|alt=' .. altText .. '|' .. altText .. '|' .. tostring(iconWidth) .. 'x' .. tostring(iconHeight) .. 'px]]' ..
			'</div>' ..
		'</div>'
    
    return out
end



function p._main(frame, args, getValue, argNames)
    local _get = toLower(args.get)
    
    if _get ~= nil and _get ~= '' and _get ~= 'infobox' then
        --_get = toLower(tostring(_get))
        if _get == 'starsrender' then
            return p._genStars(frame, args, getValue, argNames)
        elseif _get == 'row' or _get == 'rowfull' then
            return p._genTableRow(frame, args, getValue, argNames)
        elseif _get ~= nil and usmatch(_get, '^iconborder') ~= nil then
            -- ToDo
            return p._genIconBorder(frame, args, getValue, argNames)
        elseif getValue(_get, true) ~= nil then
            return getValue(_get, true)
        end
    end
    
    
    local notitle = getValue('notitle', false)
    local nocat = getValue('nocat', false)
    local name = getValue('name', false)
    local tier = getValue('tier', false)
    local _type = toLower(getValue('type', true))
    local boxPrefix = ''
    local boxSuffix = ''
	
	local categories = {}
	local addCat = function(cat)
		tableinsert(categories, tableconcat({
			'[[',
			'Category:',
			cat,
			']]'
		}))
	end
    
    
    if (notitle == nil or Yesno(notitle, false) == false) and name ~= nil then
        local _boxPrefix = '{{DISPLAYTITLE:' .. name .. '}}'
        boxPrefix = Try_preprocess(frame, _boxPrefix)
    end
    
    if nocat == nil or Yesno(nocat, false) == false then
        addCat('Star Wars: Uprising Super Walkthrough')
        
        if tier == nil then
            addCat('Equipment Missing Tier Value')
        elseif tonumber(tier) > 0 and tonumber(tier) < 5 then
            addCat('Tier ' .. tostring(tier) .. ' Equipment in Star Wars: Uprising')
        else
            addCat('Equipment With Invalid Tier Value')
        end
		
		if getValue('image', false) == nil then
			addCat('Equipment Missing Image')
		end
		
		if getValue('levelCap', false) == nil then
			addCat('Equipment Missing Level Cap Value')
		end
        
        if _type == 'weapon' or _type == 'weapons' then
            addCat('Weapons in Star Wars: Uprising')
        elseif _type == 'chest' or _type == 'torso' then
            addCat('Torso items in Star Wars: Uprising')
        elseif _type == 'lowerbody' or _type == 'legs' or _type == 'leg' or _type == 'lower' then
            addCat('Legs items in Star Wars: Uprising')
        elseif _type == 'helm' or _type == 'helmet' or _type == 'head' then
            addCat('Head items in Star Wars: Uprising')
        elseif _type == 'gloves' or _type == 'glove' or _type == 'hands' or _type == 'hand' then
            addCat('Hand items in Star Wars: Uprising')
        elseif _type == 'backpack' or _type == 'back' then
            addCat('Backpack items in Star Wars: Uprising')
        else
            addCat('Missing Equipment Type')
        end
		
		boxSuffix = boxSuffix .. tableconcat(categories)
        --boxSuffix = boxSuffix .. Try_preprocess(frame, _boxSuffix)
    end
    
    local boxOut = tableconcat({boxPrefix, p._genInfobox(frame, args, getValue, argNames), boxSuffix})
    
    return boxOut
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

--[[
function p._gearSetMain(frame, args, getValue, argNames)
    
    
    
    local out = '<table class="wikitable magistral-font" style="width:100%;text-align:center;letter-spacing:1px;background:#fff none no-repeat scroll center bottom;border:1px solid #000;">'
    
    local headerRow = '';
    local bodyRow = '';
    
    local addItem = function(name)
        local nValue = getValue(name, false)
        local nDisplayName = getValue(name .. 'DisplayName', false)
        
        local tHeadOut = ''
        local tBodyOut = ''
        
        if nValue then
            if nDisplayName == nil then
                
            end
            
            tHeadOut = tHeadOut .. '<th><small>'
                
            tHeadOut = tHeadOut .. '</small></th>'
            
            
            tBodyOut = tBodyOut .. '<rd>'
                
            tBodyOut = tBodyOut .. '</td>'
        end
        
        headerRow = headerRow .. tHeadOut
        bodyRow = bodyRow .. tBodyOut
    end
    
    out = out .. '<tr>' .. headerRow .. '</tr>' .. '<tr>' .. bodyRow .. '</tr>' .. '</table>'
    
end

function p.gearSetMain(frame)
    
    local args = {}
    local argNames = {}
    local tmp = {}
    local parentFrame = nil
    local parentFrame2 = nil

    
    local processArgList = function(_args)
        for k,v in pairs(_args) do
            local lKey = toLower(k)
            argNames[lKey] = k
            
            if v ~= nil and txttrim(tostring(v)) ~= '' then
                local isNum = txttrim(tostring(v)):match('^%s*(%d+)%s*$')
                if isNum ~= nil then
                    args[lKey] = tonumber(isNum)
                elseif type(v) == 'string' then
                    args[lKey] = txttrim(v)
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
    end
    
    if parentFrame and parentFrame.args ~= nil then
        processArgList(parentFrame.args)
        parentFrame2 = Try_getParentFrame(parentFrame)
            
        if parentFrame2 and parentFrame2.args and parentFrame2.args.get ~= nil and type(parentFrame2.args.get) == 'string' then
            processArgList(parentFrame2.args)
        end
    end
    
    local getValue = function(name, useDefault)
        local key = toLower(name)
    
        if not args[key] then
            if type(useDefault) == 'string' or type(useDefault) == 'number' then
                return useDefault
            elseif not useDefault  then
                return nil
            else
                return defaults[key]
            end
        end
        
        return args[key]
        
    end
    
    
    return p._gearSetMain(frame, args, getValue, argNames)
end
]]--
function _getArgs(frame, deep)
    local args = {}
    local argNames = {}
    local parentFrame = nil
    local parentFrame2 = nil

    
    local processArgList = function(_args)
        for k,v in pairs(_args) do
            local lKey = toLower(k)
            argNames[lKey] = k
            
            if v ~= nil and txttrim(tostring(v)) ~= '' then
                local isNum = txttrim(tostring(v)):match('^(%d+)$')
                if isNum ~= nil then
                    args[lKey] = tonumber(isNum)
                elseif type(v) == 'string' then
                    args[lKey] = txttrim(v)
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
            elseif not useDefault  then
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


function p.main(frame)
	local getValue, setValue, args, argNames = _getArgs(frame, true)
	
	return p._main(frame, args, getValue, argNames)
end

function p.getTableRow(frame)
	local getValue, setValue, args, argNames = _getArgs(frame, true)
	setValue('get', 'row')
	return p._main(frame, args, getValue, argNames)
end

function p.getDPLTableHeader(title, sortable, categoryName, scrollCount, scrollOffset)
	local headerDefaultStyle = 'background-color:#1c1c1c;color:#afafaf;font-weight:400 !important;'
	
	local header = {
			'<table class="wikitable', (sortable ~= nil and ' sortable' or ''), ' class-style counter-reset-all" style="width:100%;">',
				'<caption>',
					'<span class="magistral-font class-style letter-spacing-1px" style="letter-spacing:1px;">',
						'<span class="class-style font-size-1-2em" style="font-size:1.2em;">', (title or categoryName), '</span>',
						--'<br>',
						--'<small><small>',
							--'<span class="" style="">Showing {%DPL_count:', scrollCount ~= nil and (':' .. tostring(scrollCount)) or '', '%} pages starting from page {<noinclude></noinclude>{<noinclude></noinclude>#expr:{%DPL_offset', (scrollOffset ~= nil and (':' .. tostring(scrollOffset)) or ''),'%} + 1<noinclude></noinclude>}<noinclude></noinclude>}</span>',
						--'</small></small>',
					'</span>',
				'</caption>',
				'<tr class="magistral-font">',
					'<th style="', headerDefaultStyle, '" data-sort-type="text"><span style="margin-right:2px;font-size:0.85em;letter-spacing:1px;">Image</span><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="text"><span style="margin-right:2px;font-size:0.85em;letter-spacing:1px;">Tier</span><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="text"><span style="margin-right:2px;font-size:0.85em;letter-spacing:1px;">Name</span><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="number"><div style="display:block;font-size:0.85em;letter-spacing:1px;">Stars</div><div style="font-size:0.7em;margin-right:2px;">Initial / Max</div><div></div></th>',
					'<th style="', headerDefaultStyle, 'line-height: 0.5em;" data-sort-type="number"><span style="margin-right:2px;font-size:0.75em;letter-spacing:1px;">Max<br>Level</span><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="number"><div style="display:block;font-size:0.85em;letter-spacing:1px;">Attack</div><div style="font-size:0.7em;margin-right:2px;">Min / Max</div><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="number"><div style="display:block;font-size:0.85em;letter-spacing:1px;">Armor</div><div style="font-size:0.7em;margin-right:2px;">Min / Max</div><div></div></th>',
					'<th style="', headerDefaultStyle, '" data-sort-type="number"><div style="display:block;font-size:0.85em;letter-spacing:1px;">Utility</div><div style="font-size:0.7em;margin-right:2px;">Min / Max</div><div></div></th>',
				'</tr>\n'
	}
	
	return tableconcat(header)
end

function p.getDPLTable(frame)
	local getValue, setValue, args, argNames = _getArgs(frame, true)
	
	local sortable = getValue('sortable', false)
	local categoryName = getValue('categoryName', false)
	local scrollCount = getValue('scrollCount', false)
	local scrollOffset = getValue('scrollOffset', false)
	local allowCachedResults = getValue('allowCachedResults', false)
	--local dplCachePeriod = getValue('dplCachePeriod', false)
	local reset = getValue('reset', false)
	
	
	if categoryName == nil or categoryName == '' then
		return 'Unable to gen DPL: <span style="color: red;">Missing Category Name!</span> '
	end
	
	local title = getValue('title', false) or getValue('tableTitle', false)
	
		--'{{#dpl:\r\n',
		--'}}'
	local header = p.getDPLTableHeader(title, sortable, categoryName, scrollCount, scrollOffset)
	--²{Extension DPL continue¦dir=%SCROLLDIR%¦pages=%PAGES%¦total=%TOTALPAGES%¦page={{FULLPAGENAME}}¦count={%DPL_count', (scrollCount ~= nil and (':' .. tostring(scrollCount)) or ''), '%}¦offset={%DPL_offset', (scrollOffset ~= nil and (':' .. tostring(scrollOffset)) or ''), '%}¦purge=true¦tableStyle=margin:0 0 0 auto;¦tdClass=magistral-font class-style letter-spacing-1px¦tdStyle=letter-spacing:1px;}² %DPLTIME%\\n\r\n',
	
	local mainDPL = {
		'|category          =', categoryName ,'\n',
		'|uses              =Template:UprisingEquipmentInfobox2\n',
		'|includepage       ={UprisingEquipmentInfobox2}/getTableRow\n',
		'|distinct          =true\n',
		'|count             =\n',
		--'|count             ={%DPL_count', scrollCount ~= nil and (':' .. tostring(scrollCount)) or '', '%}\n',
		--'|offset={%DPL_offset' .. (scrollOffset ~= nil and (':' .. tostring(scrollOffset)) or '') .. '%}\n',
		--(scrollOffset ~= nil and ('|offset={%DPL_offset:' .. tostring(scrollOffset) .. '%}\n') or ''),
		--'|scroll            =yes\n',
		'|resultsheader     =\n',
		'|resultsfooter     =\n',
		'|suppresserrors    =true\n',
		'|mode              =userformat\n',
	}
	
	local legacyDPL = {
		'|category          =', categoryName ,'\n',
		'|uses              =Template:UprisingEquipmentInfobox\n',
		'|includepage       ={UprisingEquipmentInfobox¦UprisingEquipmentInfobox2/getTableRow}\n',
		'|distinct          =true\n',
		'|count             =\n',
		--'|count             ={%DPL_count', scrollCount ~= nil and (':' .. tostring(scrollCount)) or '', '%}\n',
		--'|offset={%DPL_offset' .. (scrollOffset ~= nil and (':' .. tostring(scrollOffset)) or '') .. '%}\n',
		--(scrollOffset ~= nil and ('|offset={%DPL_offset:' .. tostring(scrollOffset) .. '%}\n') or ''),
		--'|scroll            =yes\n',
		'|resultsheader     =\n',
		'|resultsfooter     =\n',
		'|suppresserrors    =true\n',
		'|mode              =userformat\n',
	}
	
	local appendArg = function(name, val)
		local a = tableconcat({'|', name, '=', val or '', '\n'})
		tableinsert(mainDPL, a)
		tableinsert(legacyDPL, a)
	end
	
	if allowCachedResults ~= nil then
		appendArg('allowcachedresults', ((allowCachedResults == true and 'true') or (allowCachedResults == false and 'false') or tostring(allowCachedResults)))
	end
	
	--[[
	if dplCachePeriod ~= nil then
		appendArg('dplcacheperiod', tostring(dplCachePeriod))
	end
	]]--
	
	if type(reset) == 'string' then
		appendArg('reset', reset)
	end
	
	local counterPlaceholder = '<div class="class-style display-none display-none-important" style="display:inline-block;border-bottom: 1px dotted black;cursor:pointer;" title="Stylesheet not loaded">\'\'\'?\'\'\'</div>'
	
	return Try_preprocess(frame, tableconcat({
		header,
		'{{#dpl:execandexit=geturlargs}}\n{{#dpl:\n', tableconcat(mainDPL), '}}\n',
		'{{#dpl:\n', tableconcat(legacyDPL), '}}\n',
		'</table>',
		'<br>',
		'<div class="magistral-font" style="margin:0 0 0 auto;width:-webkit-fit-content;width:-moz-fit-content;width:fit-content;text-align:right;">',
			'<div style="font-size:1.1em;">Showing <div class="class-style counter-value-9 zero-error letter-spacing-1px display-inline-block" style="font-size:1.1em;letter-spacing:1px;display:inline-block;">', counterPlaceholder, '</div> Result(s)</div>',
			'<small>',
				'<div style="">Tier 1 Results: <div class="class-style counter-value-1 display-inline-block" style="display:inline-block;">', counterPlaceholder, '</div></div>',
				'<div style="">Tier 2 Results: <div class="class-style counter-value-2 display-inline-block" style="display:inline-block;">', counterPlaceholder, '</div></div>',
			'</small>',
		'</div>'
	}))
	
end


function p._genProgressTable(frame, args, getValue, argNames)
	local totalGearItems = 945
	local totalWeapons = 464
	local totalItems = totalGearItems + totalWeapons
	
	local pagesInCategory = mw.site.stats.pagesInCategory
	local getPagesInCat = function(name, def)
		return toNum(pagesInCategory(name, 'pages'), def or 0)
	end
	
	local genProgressRow = function(val, max, task, text)
		local pct = (max >= val and 100 or 0)
		if max ~= 0 then
			pct = math.min(100, math.max(0, ((toNum(val or 0, 0) / toNum(max or 1, 1)) * 100)))
		end
		local pctStr = '100'
		local pctStr2 = '100'
		
		if pct <= 0 then
			pctStr = '0'
			pctStr2 = '0'
		elseif pct ~= 100 then
			pctStr = toPrecision(pct, 2)
			pctStr2 = mw.ustring.sub(pctStr, 1, -1)
			if pct > 100 then
				pctStr = '100'
			end
		end
		
		return tableconcat({
			'<table class="magistral-font" style="margin: 0 auto; width: 75%; background: transparent">',
				'<tr><td class="class-style text-align-center" style="text-align: center;">', task, ':&nbsp;<big><b>', pctStr2, '%</b></big> ', text, '</td></tr>',
				'<tr><td>',
					'<table class="class-style width-100-pct" style="width: 100%; border: 1px solid gray" cellspacing="1">',
						'<tr><td style="background: #5FDB00; width: ', pctStr, '%"></td><td style="background: #E2E2E2;"></td></tr>',
					'</table>',
				'</td></tr>',
			'</table>'
		})
	end
	
	local totalBackpackPages = getPagesInCat('Backpack items in Star Wars: Uprising‎', 0)
	local totalHandPages = getPagesInCat('Hand items in Star Wars: Uprising‎', 0)
	local totalHeadPages = getPagesInCat('Head items in Star Wars: Uprising‎', 0)
	local totalLegsPages = getPagesInCat('Legs items in Star Wars: Uprising‎', 0)
	local totalTorsoPages = getPagesInCat('Torso items in Star Wars: Uprising‎', 0)
	local totalWeaponsPages = getPagesInCat('Weapons in Star Wars: Uprising‎', 0)
	
	local totalGearPages = (totalBackpackPages + totalHandPages + totalHeadPages + totalLegsPages + totalTorsoPages)
	local totalEquipmentPages = (totalGearPages + totalWeaponsPages)
	
	local totalMissingAttack = getPagesInCat('Equipment Missing Attack Value‎', 0)
	local totalMissingArmor = getPagesInCat('Equipment Missing Armor Value‎', 0)
	local totalMissingUtility = getPagesInCat('Equipment Missing Utility Value‎', 0)
	
	local totalMissingValues = (totalMissingAttack + totalMissingArmor + totalMissingUtility)
	
	local out = {
		genProgressRow(totalEquipmentPages, totalItems, '[[:Category:Equipment in Star Wars: Uprising|Equipment Pages Made]]', 'Complete'),
		genProgressRow(math.max(0, totalEquipmentPages - totalMissingValues), totalEquipmentPages, '[[:Category:Equipment Missing Value|Equipment Missing Values]]', 'Complete'),
		genProgressRow(totalEquipmentPages - totalMissingAttack, totalEquipmentPages, '[[:Category:Equipment Missing Attack Value|Equipment Missing Attack Values]]', 'Complete'),
		genProgressRow(totalEquipmentPages - totalMissingArmor, totalEquipmentPages, '[[:Category:Equipment Missing Armor Value|Equipment Missing Armor Values]]', 'Complete'),
		genProgressRow(totalEquipmentPages - totalMissingUtility, totalEquipmentPages, '[[:Category:Equipment Missing Utility Value|Equipment Missing Utility Values]]', 'Complete'),
	}
	
	return tableconcat(out)
end

function p.progressTable(frame)
	local getValue, setValue, args, argNames = _getArgs(frame, true)
	return p._genProgressTable(frame, args, getValue, argNames)
end



function p._debug()
    local result = p.main(p.childFrame)
    mw.log(result)
    return result
end

function p._debugDPL()
    local result = p.getDPLTable({args = {categoryName = "Torso items in Star Wars: Uprising"}})
    mw.log(result)
    return result
end

function p._debugProgressTable()
    local result = p.progressTable({args = {}})
    mw.log(result)
    return result
end

return p
-- </pre>