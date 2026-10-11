local App = {}
App.__index = App

function App.new(args)
	local obj = setmetatable({}, App)
	
	obj.m_characters = false
	obj.m_creatures = false
	obj.m_droids = false
	obj.m_events = false
	obj.m_locations = false
	obj.m_organizations = false
	obj.m_species = false
	obj.m_vehicles = false
	obj.m_technology = false
	obj.m_miscellanea = false
	obj.args = args
	
	if (args.characters or args.dramatis_personae or args.other_characters or args.c_characters or args.l_characters) then
		obj.m_characters = true
	end
	if (args.creatures or args.c_creatures or args.l_creatures) then
		obj.m_creatures = true
	end
	if (args.droids or args.c_droids or args.l_droids) then
		obj.m_droids = true
	end
	if (args.events or args.c_events or args.l_events) then
		obj.m_events = true
	end
	if (args.locations or args.c_locations or args.l_locations) then
		obj.m_locations = true
	end
	if (args.organizations or args.c_organizations or args.l_organizations) then
		obj.m_organizations = true
	end
	if (args.species or args.c_species or args.l_species) then
		obj.m_species = true
	end
	if (args.vehicles or args.c_vehicles or args.l_vehicles) then
		obj.m_vehicles = true
	end
	if (args.technology or args.c_technology or args.l_technology) then
		obj.m_technology = true
	end
	if (args.miscellanea or args.c_miscellanea or args.l_miscellanea) then
		obj.m_miscellanea = true
	end
	
	return obj
end

function App:renderTOC()
	local title = "<b>By type</b>&nbsp;"
	local button = mw.html.create('span')
	button
		:addClass('hidable-button')
	title = title .. tostring(button)
		
	local root = mw.html.create('table')
	root
		:attr('id', 'appearancesTOC')
		:css('padding', '5px')
		:css('border', '1px solid #AAAAAA')
		:css('-moz-border-radius', '6px')
		:css('margin', '0 auto 4px auto')
		
	
	local row1 = root:tag('tr')
	local row2 = root:tag('tr')
	
	local function makeCell(val, id, label)
		local cell = mw.html.create('td')
		if val then
			cell
				:css('padding', '0 1em')
				:wikitext('[[' .. id .. '|' .. label .. ']]')
		else
			cell
				:css('padding', '0 1em')
				:css('color', 'gray')
				:css('font-style', 'italic')
				:wikitext(label)
		end
		return cell
	end
	
	row1:node(makeCell(self.m_characters, '#app_characters', 'Characters'))
	row1:node(makeCell(self.m_creatures, '#app_creatures', 'Creatures'))
	row1:node(makeCell(self.m_droids, '#app_droids', 'Droids'))
	row1:node(makeCell(self.m_events, '#app_events', 'Events'))
	row1:node(makeCell(self.m_locations, '#app_locations', 'Locations'))
	row2:node(makeCell(self.m_organizations, '#app_organizations', 'Organizations and titles'))
	row2:node(makeCell(self.m_species, '#app_species', 'Sentient species'))
	row2:node(makeCell(self.m_vehicles, '#app_vehicles', 'Vehicles and vessels'))
	row2:node(makeCell(self.m_technology, '#app_technology', 'Weapons and technology'))
	row2:node(makeCell(self.m_miscellanea, '#app_miscellanea', 'Miscellanea'))
	
	return title .. tostring(root)
end

function App:renderAppearances()
	local root = mw.html.create('div')
	root
		:addClass('hidable-content')
		:css('clear', 'both')
		:css('text-align', 'left')
	
	local tab = root:tag('table')
	tab
		:attr('id', 'appearancesSection')
		:css('width', '100%')
		
	x = false
	
	local function subTable(text)
		if x then
			text = '<ul>' .. text .. '</ul>'
		else
			text = '<ul></ul>' .. text
			x = true
		end
			
		local cell = mw.html.create('table')
		cell
			:addClass('appearances')
			:tag('tr')
				:tag('td')
					:wikitext(text)
					:done()
				:done()
		return cell
	end
	
	local function makeCharSection(main, dp, oc, c, l)
		local s = mw.html.create('tr')
		local section = s:tag('td')
		
		section:tag('p')
			:attr('name', 'app_characters')
			:attr('id', 'app_characters')
			:css('font-weight', 'bold')
			:css('font-size', 'larger')
			:wikitext('Characters')
		
		if main then
			if c or l then
				section:tag('p')
					:css('color', '#900')
					:wikitext("'''Warning''': This template is being incorrectly used. You may not use the <code><nowiki>|characters=</nowiki></code> field if you use <code><nowiki>|c-characters=</nowiki></code> or <code><nowiki>|l-characters=</nowiki></code>. Please [{{fullurl:{{FULLPAGENAME}}|action=edit}} edit this page] and correct the template's usage.")
			end
			if dp or oc then
				section:tag('p')
					:css('color', '#900')
					:wikitext("'''Warning''': This template is being incorrectly used. You may not use the <code><nowiki>|characters=</nowiki></code> field if you use <code><nowiki>|dramatis personae=</nowiki></code> or <code><nowiki>|other characters=</nowiki></code>. Please [{{fullurl:{{FULLPAGENAME}}|action=edit}} edit this page] and correct the template's usage.")
			end
			section:node(subTable(main))
			
		else
			if dp or oc then
				if dp then
					section:tag('p')
						:attr('name', 'app_dramatis_personae')
						:attr('id', 'app_dramatis_personae')
						:css('font-weight', 'bold')
						:wikitext('Dramatis personae')
					section:node(subTable(dp))
				end
				if oc then
					section:tag('p')
						:attr('name', 'app_other_characters')
						:attr('id', 'app_other_characters')
						:css('font-weight', 'bold')
						:wikitext('Other characters')
					section:node(subTable(oc))
				end
			else
				if c then
					section:tag('p')
						:attr('name', 'app_canon_characters')
						:attr('id', 'app_canon_characters')
						:css('font-weight', 'bold')
						:wikitext('Canon characters')
					section:node(subTable(c))
				end
				if l then
					section:tag('p')
						:attr('name', 'app_legends_characters')
						:attr('id', 'app_legends_characters')
						:css('font-weight', 'bold')
						:wikitext('Legends characters')
					section:node(subTable(l))
				end
			end
		end
		
		return s
	end
	
	local function makeSection(id, title, lc_title, main, c, l)
		local s = mw.html.create('tr')
		local section = s:tag('td')
		
		section:tag('p')
			:attr('name', string.format('app_%s', id))
			:attr('id', string.format('app_%s', id))
			:css('font-weight', 'bold')
			:css('font-size', 'larger')
			:wikitext(title)
		
		if main then
			if c or l then
				section:tag('p')
					:css('color', '#900')
					:wikitext(string.format("'''Warning''': This template is being incorrectly used. You may not use the <code><nowiki>|%s=</nowiki></code> field if you use <code><nowiki>|c-%s=</nowiki></code> or <code><nowiki>|l-%s=</nowiki></code>. Please [{{fullurl:{{FULLPAGENAME}}|action=edit}} edit this page] and correct the template's usage.", id, id, id))
			end
			section:node(subTable(main))
		else
			if c then
				section:tag('p')
					:attr('name', string.format('app_canon_%s', id))
					:attr('id', string.format('app_canon_%s', id))
					:css('font-weight', 'bold')
					:wikitext(string.format('Canon %s', lc_title))
				section:node(subTable(c))
			end
			if l then
				section:tag('p')
					:attr('name', string.format('app_legends_%s', id))
					:attr('id', string.format('app_legends_%s', id))
					:css('font-weight', 'bold')
					:wikitext(string.format('Legends %s', lc_title))
				section:node(subTable(l))
			end
		end
		
		return s
	end
	
	if self.m_characters then
		tab:node(makeCharSection(self.args.characters, self.args.dramatis_personae, self.args.other_characters, self.args.c_characters, self.args.l_characters))
	end
	if self.m_creatures then
		tab:node(makeSection('creatures', 'Creatures', 'creatures', self.args.creatures, self.args.c_creatures, self.args.l_creatures))
	end
	if self.m_droids then
		tab:node(makeSection('droids', 'Droid models', 'droid models', self.args.droids, self.args.c_droids, self.args.l_droids))
	end
	if self.m_events then
		tab:node(makeSection('events', 'Events', 'events', self.args.events, self.args.c_events, self.args.l_events))
	end
	if self.m_locations then
		tab:node(makeSection('locations', 'Locations', 'locations', self.args.locations, self.args.c_locations, self.args.l_locations))
	end
	if self.m_organizations then
		tab:node(makeSection('organizations', 'Organizations and titles', 'organizations and titles', self.args.organizations, self.args.c_organizations, self.args.l_organizations))
	end
	if self.m_species then
		tab:node(makeSection('species', 'Sentient species', 'sentient species', self.args.species, self.args.c_species, self.args.l_species))
	end
	if self.m_vehicles then
		tab:node(makeSection('vehicles', 'Vehicles and vessels', 'vehicles and vessels', self.args.vehicles, self.args.c_vehicles, self.args.l_vehicles))
	end
	if self.m_technology then
		tab:node(makeSection('technology', 'Weapons and technology', 'weapons and technology', self.args.technology, self.args.c_technology, self.args.l_technology))
	end
	if self.m_miscellanea then
		tab:node(makeSection('miscellanea', 'Miscellanea', 'miscellanea', self.args.miscellanea, self.args.c_miscellanea, self.args.l_miscellanea))
	end
	
	return tostring(root)
end
	
function App:__tostring()
	local comp = {}
	comp[#comp + 1] = self:renderTOC()
	comp[#comp + 1] = self:renderAppearances()
	local box = table.concat(comp)
	
	local root = mw.html.create('div')
	root
		:attr('class', 'hidable start-hidden')
		:css('text-align', 'center')
		:wikitext(box)

	return tostring(root)
end

local p = {}
function p._main(args)
	local function getAppResult()
		local appObj = App.new(args)
		return tostring(appObj)
	end
	result = getAppResult()
	return result
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		k = k:gsub("[- ]", "_")
		v = v:match('^%s*(.-)%s*$') 
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p