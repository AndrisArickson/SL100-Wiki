local p = {}
local a = require('Dev:Arguments')
local switch = require('Module:Multiple issues/switch')
local sc = require('Module:SpecialCategorizer')

-- Moved to function as more than one call
local function updateContent(updateText)
	return ' The article needs to be updated with \'\'' .. updateText
	.. '\'\'.'
end

-- Moved to function as more than one call
local function expandContent(expandText)
	return ' Reasoning: \'\'' .. expandText .. '\'\'.'
end

function p.main(frame)
	local args = a.getArgs(frame)

	local title = mw.title.getCurrentTitle()
	
	--Grab the talkpage
	local namespace = mw.site.namespaces[title.namespace].talk.name
	 title = namespace .. ':' .. title.talkPageTitle.text
	 
	-- Flag to apply args['updatecontent'] is update is not present
	local updateFlag
	local expandFlag
	
	--Content items, saves digging through the actual code to find the text
	local displayFile = '[[File:Got A Bad feeling.jpg|125px]]'
	local warningCaption = 'I have a bad feeling about this&hellip;'
	local warningMessage = 'This article has multiple issues and is in need' ..
		' of major additions and/or work. '
		
	local warningComment = 'Please help Wookieepedia by editing this article. '
		.. 'Once you have fixed an issue, you may remove it from the list of issues. '
		.. 'See this article\'s [[' .. title
		..'|talk page]] for more information.'
		
	if args then
		local issues = ''
		
		--Add each issue to the bullet list of issues. Theoretically infinite
		for k, v in pairs(args) do
			--[[ updatecontent is handled slightly differently so we don't want 
				it adding to the list ]]
			if k == "image" then
				if v == "person" then
					issues = issues .. '\n*' .. frame:preprocess(switch["imagePerson"])
				elseif v == "real" then 
					issues = issues .. '\n*' .. frame:preprocess(switch["imageReal"])
				else
					issues = issues .. '\n*' .. frame:preprocess(switch["image"])
				end
			elseif k ~= 'updatecontent' and k ~= 'expandcontent' and switch[v] and k ~= 'test' then
				issues = issues .. '\n*' .. frame:preprocess(switch[v])
				--Add additional text for update if updatecontent parameter exists
				if v == 'update' and args['updatecontent'] then
					issues = issues .. updateContent(args['updatecontent'])
					updateFlag = true
				elseif v == 'expand' and args['expandcontent'] then
					issues = issues .. expandContent(args['expandcontent'])
					expandFlag = true
				end
			end
		end
		
		if not updateFlag and args['updatecontent'] then
			issues = issues .. '\n*' .. frame:preprocess(switch['update']) 
			.. updateContent(args['updatecontent'])
		end
		if not expandFlag and args['expandcontent'] then
			issues = issues .. '\n*' .. frame:preprocess(switch['expand']) 
			.. expandContent(args['expandcontent'])
		end
		
		--[[ Add a new line after the last bullet, if removed the last list
			element will have a larger bullet than previous elements
		]]
		issues = issues .. '\n' 
		
		-- Styles applied to outer div
		local inlineStyles = {
			['background'] = '#E8E7ED',
			['color'] = '#000',
			['border-radius'] = '10px'
		}
		
		--attributes for <table> 
		local padding = {
			['cellspacing'] = '0',
			['cellpadding'] = '0'
		}
		
		--Builds notice's html structure and insert text/style elements
		local container = mw.html.create('div')
			container:addClass('mobile-hide')
				:addClass('headertemplate')
				:addClass('messagebox')
				:addClass('noprint')
				:addClass('iumb')
				:css(inlineStyles)
				:tag('table')
					:attr(padding)
					:tag('tr')
						:tag('td')
						:addClass('iumb-table-container')
							:tag('table')
								:attr(padding)
								:tag('tr')
									:tag('td')
										:addClass('iumb-icon')
										:wikitext(displayFile)
									:done()
								:tag('td')
									:addClass('iumb-main')
									:tag('p')
										:tag('span')
											:addClass('iumb-caption')
											:wikitext(warningCaption)
										:done()
									:done()
									:tag('p')
										:tag('span')
											:addClass('iumb-message')
											:tag('div')
												:addClass('hidable')
												:addClass('start-hidden')
												:tag('p')
													:wikitext(warningMessage)
												:tag('span')
													:addClass('hidable-button')
												:done()
												:tag('div')
													:addClass('hidable-content')
													:css('margin-left',
														'10px')
													:tag('small')
														:wikitext(issues)
													:done()
												:done()
											:done()
										:done()
									:done()
									:tag('p')
										:tag('span')
											:addClass('iumb-comment')
											:wikitext(warningComment)
										:allDone()
		return container
	end
	
	return ''
end

function p.test(frame)
	local args = a.getArgs(frame)

	local title = mw.title.getCurrentTitle()
	
	--Grab the talkpage
	local namespace = mw.site.namespaces[title.namespace].talk.name
	 title = namespace .. ':' .. title.talkPageTitle.text
	 
	-- Flag to apply args['updatecontent'] is update is not present
	local updateFlag
	local expandFlag
	
	--Content items, saves digging through the actual code to find the text
	local displayFile = '[[File:Got A Bad feeling.jpg|125px]]'
	local warningCaption = 'I have a bad feeling about this&hellip;'
	local warningMessage = 'This article has multiple issues and is in need' ..
		' of major additions and/or work. '
		
	local warningComment = 'Please help Wookieepedia by editing this article. '
		.. 'Once you have fixed an issue, you may remove it from the list of issues. '
		.. 'See this article\'s [[' .. title
		..'|talk page]] for more information.'
		
	if args then
		local issues = ''
		local categories = ''
		--Add each issue to the bullet list of issues. Theoretically infinite
		for k, v in pairs(args) do
			--[[ updatecontent is handled slightly differently so we don't want 
				it adding to the list ]]
			local current = switch[v]
			if k ~= 'updatecontent' and current then
				mw.log(type(current))
				--Check if the item in the switch is a string or a table
				if type(current) == 'table' then
					-- Table route
					mw.log(current.category)
					issues = issues .. '\n*' .. frame:preprocess(current.text)
					if current.category and title.namespace == 0 then
						--Go into SpecialCategorizer directly
						categories = categories .. sc._main(frame:preprocess('[[Category:' 
							.. current.category .. ']]'))
					end
					mw.log(issues)
					mw.log(category)
				else
					--Fallback to original process
					issues = issues .. '\n*' .. frame:preprocess(switch[v])
					--Add additional text for update if updatecontent parameter exists
					if v == 'update' and args['updatecontent'] then
						issues = issues .. updateContent(args['updatecontent'])
						updateFlag = true
					elseif v == 'expand' and args['expandcontent'] then
						issues = issues .. expandContent(args['expandcontent'])
						expandFlag = true
					end
				end
			end
		end
		
		if not updateFlag and args['updatecontent'] then
			issues = issues .. '\n*' .. frame:preprocess(switch['update']) 
			.. updateContent(args['updatecontent'])
		end
		if not expandFlag and args['expandcontent'] then
			issues = issues .. '\n*' .. frame:preprocess(switch['expand']) 
			.. expandContent(args['expandcontent'])
		end
		
		--[[ Add a new line after the last bullet, if removed the last list
			element will have a larger bullet than previous elements
		]]
		issues = issues .. '\n' 
		
		-- Styles applied to outer div
		local inlineStyles = {
			['background'] = '#E8E7ED',
			['color'] = '#000',
			['border-radius'] = '10px'
		}
		
		--attributes for <table> 
		local padding = {
			['cellspacing'] = '0',
			['cellpadding'] = '0'
		}
		
		--Builds notice's html structure and insert text/style elements
		local container = mw.html.create('div')
			container:addClass('mobile-hide')
				:addClass('headertemplate')
				:addClass('messagebox')
				:addClass('noprint')
				:addClass('iumb')
				:css(inlineStyles)
				:tag('table')
					:attr(padding)
					:tag('tr')
						:tag('td')
						:addClass('iumb-table-container')
							:tag('table')
								:attr(padding)
								:tag('tr')
									:tag('td')
										:addClass('iumb-icon')
										:wikitext(displayFile)
									:done()
								:tag('td')
									:addClass('iumb-main')
									:tag('p')
										:tag('span')
											:addClass('iumb-caption')
											:wikitext(warningCaption)
										:done()
									:done()
									:tag('p')
										:tag('span')
											:addClass('iumb-message')
											:tag('div')
												:addClass('hidable')
												:addClass('start-hidden')
												:tag('p')
													:wikitext(warningMessage)
												:tag('span')
													:addClass('hidable-button')
												:done()
												:tag('div')
													:addClass('hidable-content')
													:css('margin-left',
														'10px')
													:tag('small')
														:wikitext(issues)
													:done()
												:done()
											:done()
										:done()
									:done()
									:tag('p')
										:tag('span')
											:addClass('iumb-comment')
											:wikitext(warningComment)
										:allDone()
		return container
	end
	
	return ''
end

return p