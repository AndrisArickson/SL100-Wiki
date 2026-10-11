
-- <syntaxhighlight lang="lua">
local p = {}
local defaults = {
	preprocess = false
}



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

local join = function ( separator, ... )
    local args = { ... }
    local n = select( '#', ... )
    return tableconcat( args, separator, 1, n )
end

local append_table = function(tbl1, tbl2)
	if tbl2 ~= nil then
		if type(tbl2) ~= "table" then
			tableinsert(tbl1, tbl2)
		else
			for i, v in ipairs(tbl2) do
				tableinsert(tbl1, v)
			end
		end
	end
	return tbl1
end

-- for each table in "...", loop through and append the value to "tbl"
-- if an element in "..." is not a table, it is appended directly to "tbl"
table.append = function(tbl, ...)
	local arg={...}
	for i, v in ipairs(arg) do
		append_table(tbl, v)
	end
	return tbl
end

local tableappend = table.append
local __titleParts

function titleParts()
	if not __titleParts then
		__titleParts = require('Module:TitleParts')
	end
	return __titleParts
end

function _getTitleParts(pageName)
	return __titleParts.getTitleParts(pageName)
end

function Try_getTitleParts(pageName)
	if not __titleParts then
		__titleParts = require('Module:TitleParts')
	end
    local success, result = pcall(_getTitleParts, pageName)
    
    if success == false then
		mw.log('TitleParts Error: (' .. (type(pageName) == 'string' and pageName or (pageName == nil and 'NIL VLAUE GIVEN' or (type(pageName) .. '?'))) .. ') ' .. result)
        return nil
    end
    
    return result
end

function __getCurrentFrame(fr)
	local tFrame = mw.getCurrentFrame()
	if tFrame == nil then
		--[[
		if (fr and fr.args and fr:getParent().args) then
			return fr
		end
		]]--
		return nil
	end
	
	return tFrame
end

function Try_getCurrentFrame(fr)
	local success, result = pcall(__getCurrentFrame, fr)
	
	if success == true and result ~= nil then
		if fr and fr == result then
			return true, result, nil
		else
			return true, result, fr
		end
	else
		return false, nil, fr
	end
end

function toLower(str)
    if str == nil then
        return nil
    end
    
    return uslower(tostring(str))
end

local GROUP_COLLAPSED = 0
local GROUP_SHOW_IF_ONLY = 1 -- Page Partial Match
local GROUP_SHOW_IF_NO_EXACT = 2 -- Show if there is no exact page match (GROUP_ALWAYS_SHOW)
local GROUP_ALWAYS_SHOW = 3 -- Page Exact Match

local footerColors = {
	blockBorderColor = 'rgba(57, 94, 127, 0.7)',
	--blockBorderColor = '#4a7aa5',
	borderColor = '#5c7c99',
	
	--rgba(57, 94, 127,0.7)

	mainTableBGColor = 'rgba(6, 48, 83, 0.8)',
	headerBGColor = '#051e33',


	--BGColor = 'rgba(6, 48, 83, 0.8)',
	--BGColor = 'rgba(6, 48, 83, 1)',
	BGColor = 'rgba(0, 74, 127, 1)',
	thBGColor = 'rgb(6, 38, 65)',
	navboxSubgroupBGColor = '#063053',

	defaultLinkColor = '#008ee5',
	headerLinkColor = '#006CB0',


	defaultColor = '#FFF',
}


local footerData = {
	groups = {
		{
			title = 'General',
			iconList = {
				{sprite = 'heart',           spriteFilter = 'filter-red filter-crimson-hover',   spriteSize = 'small', linkText = 'Character',  link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Stats#Character_Stats'},
				{sprite = 'inventory',       spriteFilter = 'filter-darkorange filter-orange-hover',                     spriteSize = 'small', linkText = 'Stats',      link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Stats#Equipment_Stats'},
				{sprite = 'armory-chest',    spriteFilter = 'filter-purple filter-purple2-hover',                       spriteSize = 'small', linkText = 'Armory',     link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment'},
				{sprite = 'crew-management', spriteFilter = 'filter-exlite-green class-style opacity-70 hover-opacity-100',               spriteSize = 'small', linkText = 'Crew',       link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Crew'},
			},
			show = function(url, urlParts)
				if not urlParts then
					urlParts = Try_getTitleParts(url)
				end
				
				local subPageName = toLower(urlParts.SubPageName)
				local validSubPages = {
					['star wars: uprising super walkthrough'] = true,
					stats = true, equipment = true, crew = true,
					head = true, torso = true, back = true, hands = true, weapons = true, legs = true
				}
				
				if subPageName and validSubPages[subPageName] then
					return GROUP_ALWAYS_SHOW
				end
				
				return GROUP_COLLAPSED
			end
		},
		
		{
			title = 'Equipment',
			link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment',
			iconList = {
				{image = 'Uprising Icon Item Base M Helm 00020 V.png',      size = '75px', crop = '12', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Head",     linkText = "Head"},
				{image = 'Uprising Icon Item Base M Chest 00030 D.png',     size = '75px', crop = '12', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Torso",    linkText = "Torso"},
				{image = 'Uprising Icon Item Base M Backpack 00132 V.png',  size = '75px', crop = '12', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Back",     linkText = "Back"},
				{image = 'Uprising Icon Item Base M Gloves 00131 V.png',    size = '75px', crop = '12', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Hands",    linkText = "Hands"},
				{image = 'Uprising Icon Item Base Pistol 00030.png',        size = '75px', crop = '12', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Weapons",  linkText = "Weapons"},
				{image = 'Uprising Icon Item Base M Lowerbody 00032 D.png', size = '75px', crop = '10', link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Legs",     linkText = "Legs"},
			},
			show = function(url, urlParts)
				if not urlParts then
					urlParts = Try_getTitleParts(url)
				end
				
				local subPageName = toLower(urlParts.SubPageName)
				local validSubPages = {equipment = true, head = true, torso = true, back = true, hands = true, weapons = true, legs = true}
				
				if toLower(urlParts.getPart(-2, 1)) == 'wookieepedia:star_wars:_uprising_super_walkthrough' then
					if subPageName and validSubPages[subPageName] then
						return GROUP_ALWAYS_SHOW
					end
				end
				
				if subPageName and subPageName == 'equipment' then
					return GROUP_ALWAYS_SHOW
				end
				
				if toLower(urlParts.getPart(2, 1)) == 'equipment' then
					return GROUP_SHOW_IF_NO_EXACT
				end
				
				return GROUP_COLLAPSED
			end
		},
--[[
		{
			title = 'Equipment',
			link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Equipment',
			linkList = {
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Head",     text = "Head"},
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Torso",    text = "Torso"},
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Back",     text = "Back"},
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Hands",    text = "Hands"},
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Weapons",  text = "Weapons"},
				{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Legs",     text = "Legs"},
			},
			show = function(url, urlParts)
				urlParts = urlParts or Try_getTitleParts(url)
				
				local subPageName = toLower(urlParts.SubPageName)
				local validSubPages = {equipment = true, head = true, torso = true, back = true, hands = true, weapons = true, legs = true}
				
				if toLower(urlParts.getPart(-2, 1)) == 'wookieepedia:star_wars:_uprising_super_walkthrough' then
					if validSubPages[subPageName] then
						return GROUP_ALWAYS_SHOW
					end
				end
				
				if toLower(urlParts.getPart(2, 1)) == 'equipment' then
					return GROUP_SHOW_IF_NO_EXACT
				end
				
				return GROUP_COLLAPSED
			end
		},
]]--
		{
			title = 'Abilities',
			link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities',
			linkGrid = {
				{
					headerText = 'Non-Combat Passive', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Passive2',
					sprite = 'passive-ability', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Cartel_Savvy",  text = "Cartel Savvy"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/In_Demand",     text = "In Demand"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Insight",       text = "Insight"}
					}
				},
				{
					headerText = 'Combat Passive', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Passive',
					sprite = 'passive-ability', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Durable',    text = 'Durable'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Evasion',    text = 'Evasion'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Hit_and_Run',    text = 'Hit and Run'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Overcharge', text = 'Overcharge'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Relentless', text = 'Relentless'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Self-Preservation', text = 'Self-Preservation'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Streetwise', text = 'Streetwise'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Tenacity',   text = 'Tenacity'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Vigor',      text = 'Vigor'}
					}
				},
				{
					headerText = 'Directional', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Directional',
					sprite = 'hand-swipe-left', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Durasteel_Cutter',  text = 'Durasteel Cutter'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Flamethrower',      text = 'Flamethrower'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Hold_Out_Blaster',  text = 'Hold Out Blaster'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Scatter_Gun',       text = 'Scatter Gun'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Snipe',             text = 'Snipe'},
						{link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Wild_Swing',        text = 'Wild Swing'}
					}
				},
				{
					headerText = 'Targeted', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Targeted',
					sprite = 'hand-double-tap', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Charge",            text = "Charge"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Cryo_Grenade",      text = "Cryo Grenade"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Diving_Roll",       text = "Diving Roll"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Exploit_Weakness",  text = "Exploit Weakness"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Grenade",           text = "Grenade"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Holographic_Decoy", text = "Holographic Decoy"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Incendiary_Grenade",text = "Incendiary Grenade"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Sticky_Bomb",       text = "Sticky Bomb"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Tox_Bolas",         text = "Tox Bolas"}
					}
				},
				{
					headerText = 'Self', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Self',
					sprite = 'hand-self-tap', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Absolve",   text = "Absolve"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Armor_Piercing",   text = "Armor Piercing"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Berserk",          text = "Berserk"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Caltrops",         text = "Caltrops"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Cleave",           text = "Cleave"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Concentration",    text = "Concentration"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Cover_Smoke",      text = "Cover Smoke"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Crowd_Control",    text = "Crowd Control"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Ion_Wave",         text = "Ion Wave"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Powercell",        text = "Powercell"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Snare_Trap",       text = "Snare Trap"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Shield_Generator", text = "Shield Generator"}
					}
				},
				{
					headerText = 'Ultimate', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities#Ultimate',
					sprite = 'ultimate-ability', spriteFilter = 'filter-white', spriteSize = 'tiny', 
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Barrage",              text = "Barrage"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Diplomatic_Protection",text = "Diplomatic Protection"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Intimidate",           text = "Intimidate"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Minefield",            text = "Minefield"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Power_Knuckles",       text = "Power Knuckles"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Rocket_Launcher",        text = "Rocket Launcher"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Shock_Strikes",        text = "Shock Strikes"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Supply_Cache",         text = "Supply Cache"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Abilities/Think_Fast",           text = "Think Fast"}
					}
				}
			},
			show = function(url, urlParts)
				if not urlParts then
					urlParts = Try_getTitleParts(url)
				end
				
				local subPageName = toLower(urlParts.SubPageName)
				local validSubPages = {abilities = true}
				
				if ((subPageName and validSubPages[subPageName]) or toLower(urlParts.getPart(-2, 1)) == 'abilities') then
					return GROUP_ALWAYS_SHOW
				end
				
				return GROUP_COLLAPSED
			end
		},
		{
			title = 'Components',
			link = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components',
			center = true,
			separator = '',
			linkGrid = {
				{
					headerText = 'Crystals', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals',
					image = 'Uprising_Icon_evoSocketMaterials.png', size = '30x30px',
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Agrocite",     text = "Agrocite",     title="Agrocite - Weapon",     file = "Uprising_UI_Prop_Crystal_Weapon_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Aurodium",     text = "Aurodium",     title="Aurodium - Offense",    file = "SWUSW_Aurodium_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Berubium",     text = "Berubium",     title="Berubium - Trade",      file = "SWUSW_Berubium_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Carbonite",    text = "Carbonite",    title="Carbonite - Utility",   file = "Uprising_UI_Prop_Crystal_Utility_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Chunah",       text = "Chunah",       title="Chunah - Syndicate",    file = "SWUSW_Chunah_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Dathomite",    text = "Dathomite",    title="Dathomite - Kouhun",    file = "Uprising_UI_Prop_Crystal_Faction_Kouhun_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Electrum",     text = "Electrum",     title="Electrum - Event",      file = "SWUSW_Electrum_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Kiax",         text = "Kiax",         title="Kiax - Balance",        file = "Uprising_UI_Prop_Crystal_Balanced_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Havod",        text = "Havod",        title="Havod - Imperial",      file = "SWUSW_Havod_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Lanthanide",   text = "Lanthanide",   title="Lanthanide - Defense",  file = "Uprising_UI_Prop_Crystal_Defensive_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Lothalite",    text = "Lothalite",    title="Lothalite - Rebel",     file = "SWUSW_Lothalite_4.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Crystals#Valorumite",   text = "Valorumite",   title="Valorumite - Noble",    file = "Uprising_UI_Prop_Crystal_Faction_Noble_04.png"}
					}
				},
				{
					headerText = 'Materials', headerLink = 'Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components/Materials',
					image = 'Uprising_Icon_Currency_CartelResources.png', size = '30x30px',
					links = {
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components#Cortosis",      text = "Cortosis",     title="Cortosis - Disruption",    file = "Uprising_UI_Prop_Material_Disruption_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components#Desh",          text = "Desh",         title="Desh - Neutral",           file = "Uprising_UI_Prop_Material_Generic_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components#Durasteel",     text = "Durasteel",    title="Durasteel - Explosive",    file = "Uprising_UI_Prop_Material_Explosive_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components#Mephitine",     text = "Mephitine",    title="Mephitine - Toxic",        file = "Uprising_UI_Prop_Material_Toxic_04.png"},
						{link = "Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough/Components#Phrik",         text = "Phrik",        title="Phrik - Chemical",         file = "Uprising_UI_Prop_Material_Chemical_04.png"}
					}
				}
			},
			show = function(url, urlParts)
				if not urlParts then
					urlParts = Try_getTitleParts(url)
				end
				
				local subPageName = toLower(urlParts.SubPageName)
				local validSubPages = {crystals = true, materials = true, components = true}
				
				if subPageName and validSubPages[subPageName] then
					return GROUP_ALWAYS_SHOW
				end
				
				return GROUP_COLLAPSED
			end
		},
		{
			title = 'Factions',
			iconList = {
				{image = 'Icon Faction Rebel.png',                size = '40px', linkText = 'Alliance',     link = 'Alliance to Restore the Republic'},
				{image = 'Icon_Faction_Imperial.png',             size = '40px', linkText = 'Galactic Empire',     link = 'Galactic_Empire'},
				{image = 'IvaxSyndicate.png',                     size = '40px', linkText = 'Ivax',         link = 'Ivax Syndicate'},
				{image = 'Uprising_Icon_Faction_Kouhun.png',      size = '40px', linkText = 'The Kouhun',     link = 'Kouhun_(order)'},
				{image = 'Uprising_Icon_Faction_NobleCourt.png',  size = '40px', linkText = 'Noble Court',     link = 'Noble_Court'},
				{image = 'TradeSpineLeague.png',                  size = '40px', linkText = 'Trade Spine',  link = 'Trade Spine League'}
			},
			show = function(url, urlParts)
				return GROUP_COLLAPSED
			end
		}
	}
}

--filter-white small, heart inventory armory-chest crew-management

local rowSpacer = '<tr style="height:1px;"><td style="padding:2px;"></td></tr>'




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

function parseTierNum(str, def)
	if str == nil or str == '' then
		return def
	end
	if type(str) == "number" then
		return math.max(1, str)
	end
	
	local isTierNum = (type(str) == "string" and (txttrim(tostring(str)):match('^[Tt]?(%d)$')) or nil)
	
	if isTierNum ~= nil then
		return tonumber(isTierNum)
	end
	
	return def
end

function _extend(target, ...)
    target = target or {}
    local __extend = function(tbl)
        for key,val in pairs(tbl) do
            target[key] = val
        end
    end
    
    for i,v in ipairs(arg) do
        __extend(v)
    end
    
    return target
end

function _preprocess(frame, str)
	if frame then
		return frame:preprocess{text = str}
	else
		return nil
	end
end

function Try_preprocess(frame, str)
	if (not str or type(str) ~= 'string') then
		return nil
	end
	if str == '' then
		return str
	end
	
	local frameSuccess, tFrame, fr = Try_getCurrentFrame(frame)
	--local hasTFrame = ((frameSuccess and tFrame ~= nil and true) or false)
	local hasTFrame = (not (frameSuccess ~= true or tFrame == nil))
	
	local success, result = pcall(_preprocess, (hasTFrame and tFrame or nil), str)
	
	if hasTFrame and success == true and result ~= nil then
		return result
	end
	
	if (fr or frame) then
		local success2, result2 = pcall(_preprocess, (fr or frame), str)
		
		if success2 and result2 then
			return result2
		else
		
			if result or result2 then
				mw.log((success == false and result and (tostring(result) .. (result2 and '|' or '')) or '') .. tostring(result2 and result2 or ''))
			end
			
			return str
		end
	end
    
	if success == false and result then
		mw.log(result)
	elseif (not ((hasTFrame and tFrame) or fr)) then
		mw.log('Unable To preprocess: No Frame Available')
	end
	
    return str
end


function p.genNavbarVDE(frame, options)
	local templateVLink = 'Template:UprisingPageFooter'
	local templateDLink = 'Template_talk:UprisingPageFooter'
	local templateELink = 'Template:UprisingPageFooter'
	
	local textStyle = 'padding-left:1.2em; padding-right:1.2em;padding-left:0.0em; padding-right:0.0em;;background:none transparent;border:none;font-size:100%;'
	
	
	return tableconcat({
		'<span style="float:left;width:6em;text-align:left;">',
			'<span class="noprint plainlinks navbar" style="margin-left:5px;">',
				'<span style="white-space:nowrap;word-spacing:-.12em;">',
				
					'[[', templateVLink, '|<span style="', textStyle, '" title="View this template">v</span>]]',
					'<span style="', textStyle, '">&#32;<b>&middot;</b>&#32;</span>',
					'[http://starwars.wikia.com/wiki/', templateDLink, ' <span style="', textStyle, '" title="Discuss this template">d</span>]',
					'<span style="', textStyle, '">&#32;<b>&middot;</b>&#32;</span>',
					'[', tostring(mw.uri.fullUrl(templateDLink, 'action=edit')), ' <span style="', textStyle, '" title="Edit this template">e</span>]',
				
				'</span>',
			'</span>',
		'</span>'
	})
	
end

function p.genNavboxTitle(frame, options)
	
	local fontSize = (options.navboxTitleFontSize or ((options.subGroup ~= true and '110%') or options.fontSize or '100%'))
	local padding = (options.subGroup == true and '1.2em' or '0em')
	local title = (options.title or '&nbsp;')
	
	if options.link then
		title = '[[' .. options.link .. '|' .. title .. ']]'
	end
	
	local thStyle = tableconcat({
		'position:relative;',
		'padding-left:', padding, ';',
		'padding-right:', padding, ';',
		'border: 1px ', footerColors.borderColor, ' solid;',
		--'border: 1px ', (options.subGroup == true and footerColors.blockBorderColor or ('')), ' solid;',
		--'background-color:', (options.subGroup == true and footerColors.thBGColor or footerColors.headerBGColor), ';',
		'background-color:', footerColors.headerBGColor, ';',
		options.navboxTitleStyle or ''
	})
	
	return tableconcat({
		'<tr>',
			'<th style="', thStyle, '" colspan="2" class="navbox-title ', options.navboxTitleClass or '', '">',
				
				tostring(options.vde == true and p.genNavbarVDE(frame, options) or ''),
				
				'<div class="class-style position-absolute left-0 width-100-pct margin-left--50px" style="font-size:', fontSize, ';position:absolute;left:60px;right:60px;z-index:10;width:auto;margin-left:0;">',
					'<span class="magistral-font class-style letter-spacing-1px" style="text-align:center; padding-right:0;">',
						title,
					'</span>',
				'</div>',
			'</th>',
		'</tr>'
	})
	
end


function p.genNavboxSubGroup(frame, options)
	--[[
	local _options = _extend({}, options, {
		subGroup = true
	})
	]]--
	
	local tableStyle = tableconcat({
		'width:100%;',
		'background-color:', footerColors.navboxSubgroupBGColor, ';'
		
	})
	
	local out = {
		'<table data-expandtext="Show" data-collapsetext="Hide" class="nowraplinks mw-collapsible ', (options.collapsed and 'mw-collapsed' or 'mw-uncollapsed'), ' navbox-subgroup" style="', tableStyle, ';" cellspacing="0">',
			p.genNavboxTitle(frame, options),

			
	}
	
	
	local genIconList = function(tbl)
		local iconCount = ((type(tbl) == "table" and table.maxn(tbl)) or 0)
		if iconCount == 0 then
			return nil
		end
		
		local maxWidth = tostring(math.floor((1000 / iconCount) + 0.5) / 10)
		local width = tostring(math.floor(100 / iconCount))
		
		tableinsert(out, '<tr><td colspan="2" style="width:100%;padding:0px;' .. ('border:1px solid ' .. footerColors.blockBorderColor .. ';') .. '" class="navbox-list navbox-odd"><div style="padding:0 0"><center><table style="border:0 none;table-layout:fixed;font-size:0.8em;">')
		
		local iconRow = {'<tr>'}
		local linkRow = {'<tr>'}
		
		local genIcon = function(iconData)
			local isSprite = (iconData.sprite ~= nil and true or false)
			local image = ''
			
			local fullLink = tostring(mw.uri.fullUrl(iconData.link or ''))
			
			if isSprite then
				image = tableconcat({
					'[', fullLink, ' ',
						'<span><div title="', (iconData.alt and iconData.alt or iconData.linkText or ''), '" class="uprising-sprite ', iconData.sprite, ' ', iconData.spriteFilter or '' , ' ', iconData.spriteSize or 'small', '" style="margin:1px -5px -10px -5px;', iconData.spriteStyle or '', '"></div></span>',
					']',
				})
			else
				image = tableconcat({
					'[[File:', iconData.image or iconData.file or '',
						'|link=', fullLink,
						'|', (iconData.size or iconData.imageSize or '40px'),
					']]'
				})
			end
			
			if iconData.crop then
				image = '<div style="margin:-' .. tostring(iconData.crop or '1') .. 'px;">' .. image .. '</div>'
			end
			
			tableinsert(iconRow, tableconcat({'<td style="border:0 none;text-align:center;max-width:', maxWidth, '%;width:', width, '%;padding:0 5px 0 0;">', image, '</td>'}))
			
			tableinsert(linkRow, tableconcat({'<td style="border:0 none;text-align:center;max-width:', maxWidth, '%;width:', width, '%;padding:0 5px 0 0;line-height:1em;"><center>[', fullLink, ' ', iconData.linkText, ']</center></td>'}))
		end

		
		for i,v in ipairs(tbl) do
			genIcon(v)
		end
			
		tableinsert(out, tableconcat(iconRow) .. '</tr>' .. tableconcat(linkRow) .. '</tr></table></center></div></td></tr>')
	end
	
	local genLinkList = function(tbl)
		tableinsert(out, '<tr><td colspan="2" style="width:100%;padding:0px;' .. ('border:1px solid ' .. footerColors.blockBorderColor .. ';') .. '" class="navbox-list navbox-odd"><div style="padding:0 0;"><center>')
		
		local links = {}
		
		for i,v in ipairs(tbl) do
			tableinsert(links, '[[' .. v.link .. (v.text and ('|' .. v.text) or '') .. ']]')
		end
		
		tableinsert(out, tableconcat(links, '<span style="margin-left:2px;margin-right:2px;"><b>&middot;</b></span>'))
		
		tableinsert(out, '</center></div></td></tr>')
	end
	
	local genLinkGrid = function(tbl)
		
		tableinsert(out, '<tr><td colspan="2" style="width:100%;padding:0px;border: 0 none;" class="navbox-list navbox-odd"><div style="padding:0 0"><table style="width:100%;border-collapse:collapse;table-layout:fixed;">')
		
		
		local genLinkGridRow = function(rowData)
			local sprite = rowData.sprite
			local icon = rowData.image
			local image = ''
			
			local headerText = rowData.headerText or rowData.header
			local headerLink = rowData.headerLink or rowData.link
			
			local col1 = ''
			local col2 = '<td colspan="2" style="text-align:left; font-size:0.75em; line-height:145%;color:' .. footerColors.defaultColor .. ';padding-left:1em;min-width:66%;border-top:0 none;' .. ('border:1px solid ' .. footerColors.blockBorderColor .. ';') .. '">'
			
			local links = rowData.links
			
			if headerText or sprite or icon then
				local fullLink = headerLink and tostring(mw.uri.fullUrl(headerLink)) or nil
				
				if sprite then
					image = tableconcat({
						(fullLink and ('[' .. fullLink .. (rowData.linkText and (' ' .. rowData.linkText) or ' ')) or '' ),
							'<span><div style="display:inline-block;margin:3px -5px 0 5px;width:21px;"><div title="', (rowData.alt or rowData.linkText or headerText or ''), '" class="uprising-sprite ', sprite, ' ', rowData.spriteFilter or '' , ' ', rowData.spriteSize or 'tiny', '" style="', rowData.spriteStyle or '', '"></div></div></span>',
						(fullLink and ']' or '')
					})
				elseif icon then
					image = tableconcat({
						'<div style="display:inline-block;margin:3px -5px 0 5px;">[[File:', icon, (fullLink and ('|link=' .. fullLink) or ''),
							'|', ((rowData.alt or rowData.linkText or headerText) and ((rowData.alt or rowData.linkText or headerText) .. '|') or ''), (rowData.size or rowData.imageSize or '21px'),
						']]</div>'
					})
				end
			
				col1 = '<th class="magistral-font" style="white-space:nowrap;letter-spacing:1px;padding-left:1em; padding-right:1em; text-align:right;font-size:0.8em;border-top:0 none;max-width:30%;min-width:100px;width:-webkit-min-content;width:-moz-min-content;width:min-content;background-color:' .. footerColors.thBGColor .. ';' .. ('border:1px solid ' .. footerColors.blockBorderColor .. ';') .. '">' ..
						'<div style="display:inline-block;' .. (sprite and 'vertical-align:text-bottom;' or '') .. '">&nbsp;' ..
							(fullLink and ('[' .. fullLink .. (headerText and (' ' .. headerText) or '') .. ']') or (headerText or '')) ..
						'</div>' ..
						image ..
					'</th>'
			
				col2 = '<td style="text-align:left; font-size:0.75em; line-height:145%;color:' .. footerColors.defaultColor .. ';padding-left:1em;min-width:66%;border-top:0 none;' .. ('border:1px solid ' .. footerColors.blockBorderColor .. ';') .. '">'
				
				
			end
			
			if options.center then
				col2 = col2 .. '<center>'
			end
			
			if links then
				local linkArr = {}
				for int,val in ipairs(links) do
					if type(val) == "string" then
						tableinsert(linkArr, '[[' .. val .. ']]')
					elseif (val.link or val.title or val.text) then
						if val.file then
							tableinsert(linkArr, tableconcat({
								---'<span class="" style="">',
									'<table class="class-style display-inline-table" style="display:inline-table;border:0 none;table-layout:fixed;font-size:0.85em;">',
										'<tr><td class="class-style text-align-center" style="border:0 none;text-align:center;padding:0;min-height:30px;max-height:30px;height:30px;min-width:36px;">',
											'<div style="margin:0px -5px -5px -5px;">',
												('[[File:' .. (val.file or '') .. (val.link and ('|link=' .. val.link) or '') .. ((val.title or val.text) and ('|' .. (val.title or val.text)) or '') .. '|40x40px]]'),
											'</div>',
										'</td></tr>',
										'<tr><td class="class-style text-align-center" style="border:0 none;text-align:center;padding:0 2px;line-height:1em;">',
											(((val.link or val.title)) and ('[[' .. (val.link or val.title) .. (val.text and ('|' .. (val.title and ('<span title="' .. val.title .. '">' .. val.text .. '</span>') or val.text)) or '') .. ']]') or ('&nbsp;')),
										'</td></tr>',
									'</table>',
								---'</span>'
							}))
						
							--tableinsert(linkArr, '[[' .. (val.link or val.title) .. (val.text and ('|' .. val.text) or '') .. ']]')
						else
							tableinsert(linkArr, '[[' .. (val.link or val.title) .. (val.text and ('|' .. val.text) or '') .. ']]')
						end
					end
				end
				col2 = col2 .. tableconcat(linkArr, (options.separator or ('<span style="margin-left:2px;margin-right:2px;font-size:1.05em;">\'\'\'&middot;\'\'\'</span>')))
			end
			
			if options.center then
				col2 = col2 .. '</center>'
			end
			
			tableinsert(out, tableconcat({'<tr>', col1, col2, '</td></tr>'}))
		end
		
		for i,v in ipairs(tbl) do
			genLinkGridRow(v)
		end
		
		tableinsert(out, '</table></div></td></tr>')
	end
	
	if options.iconList then
		genIconList(options.iconList)
	elseif options.linkList then
		genLinkList(options.linkList)
	elseif options.linkGrid then
		genLinkGrid(options.linkGrid)
	end
	
	tableinsert(out, '</table>')
	
	return tableconcat(out)
end

function p.genFooter(frame)
	local currentTitle = mw.title.getCurrentTitle()
	--local _titleParts = titleParts()
	local fullPageName = currentTitle.nsText .. ':' .. currentTitle.text
	--local parts = _titleParts.getTitleParts(fullPageName)
	local parts = Try_getTitleParts(fullPageName)
	local maxShowState = 0
	local showStateTotal = 0
	local defaultOptions = {
		collapsible = true,
		collapsed = false
	}
	
	local isCollapsed = false
	
	local subGroupCount = 0
	
	local _genSubGroupRow = function(opts)
		subGroupCount = subGroupCount + 1
		
		local even = ((subGroupCount % 2 == 0) and true or false)
		
		local isShown = (opts._showState > 0 and ((opts._showState == GROUP_ALWAYS_SHOW or (opts._showState == GROUP_SHOW_IF_NO_EXACT and maxShowState == GROUP_SHOW_IF_NO_EXACT) or (showStateTotal == opts._showState)) and true) or false)
		
		local newGroup = p.genNavboxSubGroup(frame, _extend(opts, defaultOptions, {
			subGroup = true,
			isEven = even,
			collapsed = (not isShown)
		}))
		
		return tableconcat({
			rowSpacer,
			'<tr>',
				'<td colspan="2" style="width:100%;padding:0px;', ('border:1px solid ' .. footerColors.blockBorderColor .. ';'),'" class="navbox-list navbox-', (even and 'even' or 'odd'), '">',
					'<div style="padding:0em 0.25em;"></div>',
					newGroup,
				'</td>',
				'<div></div>',
			'</tr>'
		})
	end
	
	local function genGroups()
		local groupsOut = {}
		for i,v in ipairs(footerData.groups) do
			tableinsert(groupsOut, _genSubGroupRow(v))
		end
		return tableconcat(groupsOut)
	end
	
	
	for i,v in ipairs(footerData.groups) do
		if v.show then
			v._showState = v.show(fullPageName, parts)
			showStateTotal = showStateTotal + v._showState
			if v._showState > maxShowState then
				maxShowState = v._showState
			end
		end
	end
	--footerData.groups
	
	local mainTableStyle = tableconcat({
		'clear:both;',
		'width:100%;',
		'vertical-align:middle;',
		'text-align:center;',
		
		'background-color:', footerColors.BGColor, ';',
		'border: 1px ', footerColors.borderColor, ' solid;',
		
		'border-collapse: collapse;',
		'color:', footerColors.defaultColor, ';'
	})
	
	local out = {
	'<!--googleoff: all--><!--noindex-->',
		'<div class="robots-noindex robots-nocontent no-mobile mobile-hide UprisingPageFooterWrap PageFooterNoWideTablesWrapper">',
			'<table class="navbox wikitable" style="', mainTableStyle, '" cellspacing="0">',
				'<tr>',
					'<td style="padding:2px;">',
						'<table data-expandtext="Show" data-collapsetext="Hide" class="nowraplinks mw-collapsible ', (isCollapsed and 'mw-collapsed' or 'mw-uncollapsed'), '" style="width:100%;background:transparent;color:inherit;" cellspacing="0">',
							
							p.genNavboxTitle(frame, _extend({}, defaultOptions, {title = '[[Wookieepedia:Star_Wars:_Uprising_Super_Walkthrough|Star Wars: Uprising Super Walkthrough]]', vde = true, collapsible = true})),
							
							genGroups(),
							
						'</table>',
					'</td>',
				'</tr>',
			'</table>',
		'</div>',
	'<!--/noindex--><!--googleon: all-->'
	}
	
	return tableconcat(out)
end

function p._main(frame, args, getValue, argNames)
	return p.genFooter(frame)
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

function _getArgs(frame, uFrame, deep)
    local args = {}
    local argNames = {}
    local parentFrame = nil
    local uParentFrame = nil
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
	
	if uFrame and uFrame.args and uFrame ~= frame then
        if uFrame.args ~= nil then
            processArgList(uFrame.args)
        end
        uParentFrame = Try_getParentFrame(uFrame)
        if uParentFrame == nil and uFrame.args == nil then
            processArgList(uFrame)
        end
	end
	
	if uFrame and uParentFrame and uParentFrame.args ~= nil and uFrame ~= frame then
		--if uParentFrame and uParentFrame.args ~= nil then
			processArgList(uParentFrame.args)
		--end
	else
	
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
	local frameSuccess, tFrame, fr = Try_getCurrentFrame(frame)
	local hasTFrame = ((frameSuccess and tFrame ~= nil and true) or false)
	
	local uFrame = (frameSuccess and tFrame or fr)
	
	local getValue, setValue, args, argNames = _getArgs(frame, (hasTFrame and tFrame or nil), true)
	
	local r = p._main(uFrame or frame, args, getValue, argNames)
	
	if type(r) ~= 'string' or r == '' or (getValue('preprocess', true) ~= true and getValue('preprocess', true) ~= 'true' and getValue('preprocess', true) ~= '1') then
		return r
	else
		local processedResult = Try_preprocess(hasTFrame and tFrame or frame, r)
		return (processedResult or r)
	end
end

function p._debug()
    local result = p.main({args = {}})
    mw.log(result)
    return result
end

return p
-- </syntaxhighlight>
-- [[Category:Templates for Star Wars: Uprising]]