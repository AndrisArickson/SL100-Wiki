
-- <pre>
local p = {}
local titleParts = require("Module:TitleParts")

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

local testFrame = {
    -- Child frame's arguments (change as needed)
    args = {
		link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Ndaya', forceLegends = '1'
	},
 
    getParent = function()
        -- Parent frame's arguments (change as needed)
        local pArgs = {}
 
        return { args = pArgs }
    end
}


local selectedBGColor = '002e54'
local notSelectedBGColor = 'd8e9fc'
local redLinkTabBGColor = 'be003c'


local tabTata = {
    canon = {
        id = 'canontab-canon',
        selected = {
            image = 'Tab-canon-white.png',
            alt = 'This article covers the Canon version of this subject.'
        },
        notSelected = {
            image = 'Tab-canon-black.png',
            alt = 'Click here for Wookieepedia\'s article on the Canon version of this subject.'
        }
    },
    legends = {
        id = 'canontab-legends',
        selected = {
            image = 'Tab-legends-white.png',
            alt = 'This article covers the Legends version of this subject.'
        },
        notSelected = {
            image = 'Tab-legends-black.png',
            alt = 'Click here for Wookieepedia\'s article on the Legends version of this subject.'
        }
    },
    uprising = {
        id = 'canontab-uprising',
        selected = {
            image = 'StarWarsUprisingLogoTransparent.png',
            alt = 'This article covers the Star Wars: Uprising game information for this subject.'
        },
        notSelected = {
            image = 'StarWarsUprisingLogoTransparent_Invert.png',
            alt = 'Click here for Wookieepedia\'s article on the Star Wars: Uprising version of this subject.'
        }
    },
}

function p.genSelectedTab(options)
    local backgroundColor = (options.redLink and redLinkTabBGColor) or (options.selected and selectedBGColor or notSelectedBGColor)
    
    local thisTab = options.type and tabTata[options.type] or {}
    
    local id = options.id or thisTab.id or ''
    local imageFileName = (options.selected ~= true and not options.redLink and thisTab.notSelected.image or thisTab.selected.image)
    local alt = (options.selected ~= true and thisTab.notSelected.alt or thisTab.selected.alt or thisTab.alt or '') .. (options.redLink and ' (page does not exist)' or '')
    
    local tdStyle = 'padding:0 0 5px 0;background-color:#' .. backgroundColor .. ';line-height:0.95em;font-size:150%;font-weight:bold;width:20px;vertical-align:top;'
    
    local rClass = 'display-block std-background-', backgroundColor, ' padding-0 margin-top-0px margin-bottom-0px'
    
    
    local image = ''
    
    
    
    if options.type == 'uprising' then
        image = tableconcat({
			'<div class="class-style display-inline-block width-76-px height-35-px margin-left-auto margin-right-auto margin-top-0 margin-bottom-0 thumb-no-margin" style="display:block;width:76px;height:35px;margin:0 auto;">',
                '[[File:', imageFileName, '|frameless|link=', options.link, '|alt=', alt, '|', alt, '|x35px]]',
            '</div>'})
    else
        image = tableconcat({'[[File:', imageFileName, '|frameless|link=', options.link, '|alt=', alt, '|', alt, '|170x35px]]'})
    end
    
    return tableconcat({
        '<td id="canontab-uprising" style="', tdStyle, '" class="class-style std-background-', backgroundColor, ' vertical-align-top padding-0 width-170-px padding-bottom-5px">',
            '<span class="content-bg rtop class-style std-background-white display-block padding-0 margin-0" style="background:#ffffff;">',
                '<span class="r1 ', rClass,' height-1-px margin-left-5px margin-right-5px" style="background:#', backgroundColor, ';"></span>',
                '<span class="r2 ', rClass,' height-1-px margin-left-3px margin-right-3px" style="background:#', backgroundColor, ';"></span>',
                '<span class="r3 ', rClass,' height-1-px margin-left-2px margin-right-2px" style="background:#', backgroundColor, ';"></span>',
                '<span class="r4 ', rClass,' height-2-px margin-left-1px margin-right-1px" style="background:#', backgroundColor, ';"></span>',
            '</span>',
            '<div class="class-style display-block width-170-px height-30-px" style="display:block;width:170px;height:30px;">',
                image,
            '</div>',
        '</td>'
    })
end


function p.getTabs(getValue, setValue, args, argNames)
	local currentTitle = mw.title.getCurrentTitle()
	
	local namespace = currentTitle.namespace
	local namespaceName = currentTitle.nsText
	local titleNoNamespace = currentTitle.text
	local subPageName = currentTitle.subpageText
	local fullPageName = (namespace ~= 0 and (namespaceName .. ':') or '') .. titleNoNamespace
	
	
    local noCat = getValue('noCat')
    local noCanon = getValue('noCanon')
    local noLegends = getValue('noLegends')
    
	local selected = getValue('selected')
	
    local link = getValue('link')
	local linkTitleParts = nil
	
    local canon = getValue('canon') or getValue('canonLink')
	local canonTitleParts = nil
	
    local legends = getValue('legends') or getValue('legendsLink')
	local legendsTitleParts = nil
	
	if not link and namespace == 828 or namespace == 4 then
		link = fullPageName
	elseif not legends and not canon and not link then
		if toLower(subPageName) == 'legends' then
			legends = fullPageName
		else
			canon = fullPageName
		end
	end
	
	if not link then
		if legends and not noLegends then
			legendsTitleParts = legendsTitleParts or titleParts.getTitleParts(legends)
			if toLower(legendsTitleParts.getPart(-1)) == 'legends' then
				link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/' .. legendsTitleParts.getPart(1, -1)
			else
				link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/' .. legendsTitleParts.PageName
			end
		elseif canon and not noCanon then
			canonTitleParts = canonTitleParts or titleParts.getTitleParts(canon)
			if toLower(canonTitleParts.getPart(-1)) == 'canon' then
				link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/' .. canonTitleParts.getPart(1, -1)
			else
				link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/' .. canonTitleParts.PageName
			end
		end
	end
	
	linkTitleParts = titleParts.getTitleParts(link)
	
	if not canon and not noCanon then
		canon = linkTitleParts.SubPageName
	end
	
	canonTitleParts = canonTitleParts or (canon and titleParts.getTitleParts(canon)) or nil
	
	if not legends and not noLegends then
		legends = linkTitleParts.SubPageName .. '/Legends'
	end
	
	legendsTitleParts = legendsTitleParts or (legends and titleParts.getTitleParts(legends)) or nil
	
	if toLower(currentTitle.subpageText) == 'legends' and legends and not noLegends then
		selected = selected or 'legends'
	end
	
	if toLower(currentTitle.subpageText) == 'canon' and canon and not noCanon then
		selected = selected or 'canon'
	end
	
	if namespace == 828 then -- Module Namespace
		selected = selected or 'uprising'
		noCat = true
	elseif namespace == 4 then -- Wookieepedia
		selected = selected or 'uprising'
	elseif namespace == 0 and not noCanon then -- Main
		selected = selected or 'canon'
	end
	
	local cats = {}
	local addCat = function(name)
		if not noCat then tableinsert(cats, '[[' .. 'Category:' .. name .. ']]') end
	end
	
    local out = {'<table id="canontab" style="text-align:center;padding:0;margin:0 0 5px 0;border-left:0;border-right:0;border-top:0;border-bottom:7px solid #002e54;border-spacing:0;border-collapse:collapse;width:100%;vertical-align:top;" class="class-style margin-bottom-5px text-align-center border-collapse-collapse vertical-align-top border-bottom-width-7px border-bottom-color-002e54 border-bottom-style-solid width-100-pct"><tr>'}
	
	local separatorCount = 0
	local addSeparator = function(isLast)
		separatorCount = separatorCount + 1
		tableinsert(out, '<td id="canontab-separator' .. tostring(separatorCount) .. '" style="width:' .. (isLast and '3000' or '3') .. 'px;" class="class-style width-' .. (isLast and '200' or '3') .. '-px">&nbsp;</td>')
	end
	
	local canonAdded = false
	local legendsAdded = false
	
	if canon and (getValue('forceCanon', false) or (not noCanon and (getValue('canon') or canonTitleParts.exists()))) then
		tableinsert(out, p.genSelectedTab({
			type = 'canon',
			selected = (selected == 'canon' and true or false),
			link = canon,
			redLink = not canonTitleParts.exists() and true or false
		}))
		addSeparator()
		canonAdded = true
		
		if selected == 'canon' then
			addCat('Canon articles')
		end
	end
	
	if legends and (getValue('forceLegends', false) or (not noLegends and (getValue('legends') or legendsTitleParts.exists()))) then
		tableinsert(out, p.genSelectedTab({
			type = 'legends',
			selected = (selected == 'legends' and true or false),
			link = legends,
			redLink = not legendsTitleParts.exists() and true or false
		}))
		addSeparator()
		legendsAdded = true
		
		if selected == 'legends' then
			addCat('Legends articles')
		end
	end
	
	tableinsert(out, p.genSelectedTab({
		type = 'uprising',
		selected = (selected == 'uprising' and true or false),
		link = link
	}))
	
	addSeparator(true)
    
	tableinsert(out, '</tr></table>')
	
	
	if selected == 'canon' and canonAdded then
		if linkTitleParts and linkTitleParts.exists() then
			addCat('Canon articles with Star Wars: Uprising counterparts')
		end
		if legendsAdded and legendsTitleParts and legendsTitleParts.exists() then
			addCat('Canon articles with Legends counterparts')
		end
	end
	
	if selected == 'legends' and legendsAdded then
		if linkTitleParts and linkTitleParts.exists() then
			addCat('Legends articles with Star Wars: Uprising counterparts')
		end
		if canonAdded and canonTitleParts and canonTitleParts.exists() then
			addCat('Legends articles with canon counterparts')
		end
	end
	
	if selected == 'uprising' then
		if canonAdded and canonTitleParts and canonTitleParts.exists() then
			addCat('Star Wars: Uprising articles with canon counterparts')
		end
		if legendsAdded and legendsTitleParts and legendsTitleParts.exists() then
			addCat('Star Wars: Uprising articles with legends counterparts')
		end
	end
	
	tableinsert(out, tableconcat(cats))
	
    
    return tableconcat(out)
    
end


function getParentFrame(frame)
    return frame:getParent()
end
function Try_getParentFrame(frame)
    local success,result = pcall(getParentFrame, frame)
    
    if success == false or result == nil or result.args == nil then
        return nil
    end
    
    return result
end


function _getArgs(frame)
    local args = {}
    local argNames = {}
    local parentFrame = nil
    local parentFrame2 = nil

    frame = frame or mw.getCurrentFrame()
    
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
    end
    
    local getValue = function(name, def)
        local key = toLower(name)
    
        if not args[key] then
            return def
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
end

function p.main(frame)
	local getValue, setValue, args, argNames = _getArgs(frame)
	return p.getTabs(getValue, setValue, args, argNames)
end

function p._debug(frame)
    local result = p.main(testFrame)
    mw.log(result)
    return result
end

return p
-- </pre>
-- <noinclude>[[Category:Templates for Star Wars: Uprising]]</noinclude>