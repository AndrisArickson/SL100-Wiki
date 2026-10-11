--<nowiki>
local p = {}
local sc = require('Module:SpecialCategorizer')
local a = require('Dev:Arguments')

--[[
	Check if the talkpage flagged for expand exists and if there is a marker to 
	indicate the issue has been resolved
]]
local function checkTalk(t)
	local talkpage = mw.title.getCurrentTitle().talkPageTitle
	if string.find(talkpage:getContent(), '{{['..t:sub(0, 1)..string.lower(t:sub(0, 1))..']'..t:sub(2, string.len(t)) .. '^|') then
		return 'Additional information on expansion can be found on the '
			.. '[[' .. talkpage.prefixedText .. '|talkpage]]'
	end
	return ''
end

function p.main(frame)
	local args = a.getArgs(frame)
	
	-- We want this on talkpages if there is additional content, but we don't
	-- want to display anything (for now)
	local title = mw.title.getCurrentTitle()
	if title.isTalkPage then
		return ''
	end
	
	--base variable for the expand reason text
	local additionalText = ''
	
	--Add expansion reason from template
	if args[1] and args[1] ~= '1' then
		 additionalText = args['reason'] .. ': ' .. args[1] .. ' '
	end
	
	-- If the talk page exists, check if the expansion reasons may also be here
	-- (in depth detail)
	if title.talkPageTitle.exists then
		additionalText = additionalText .. checkTalk(args['id'])
	end
	
	-- Replaces {{#ifeq:{{NAMESPACENUMBER}}|0|{{SpecialCategorizer|
	-- [[Category:Articles to be expanded|{{PAGENAME}}]]
	-- }}{{#if:{{{1|}}}|
	-- |[[Category:Pages using Template:Expand without a parameter]]}}}}
	if (additionalText == '' or args[1] == '1') then
		additionalText = mw.html.create('span'):css(
			{
				['color'] = '#00ff7e',
				['font-size'] = '1.4em'
			}
		):wikitext('No reason has been supplied; please provide a reason on the template or talkpage')
		additionalText = tostring(additionalText)
		if title:inNamespace( 0 ) then
			additionalText = additionalText .. sc._main('[[Category:Pages using maintenance header templates without a parameter|'..title.text..']]', false, false)
		end
	end

	if mw.title.getCurrentTitle():inNamespace( 0 ) then 
		additionalText = additionalText 
			.. sc._main('[[' .. args['category'] .. '|' 
			.. title.text .. ']]', false, false)
	end
	local comment = ''
	if args['comment'] ~= nil and args['comment'] ~= "" then
		comment = string.gsub(args['comment'] or '', '{TALKPAGE}', '[[' 
			.. title.talkPageTitle.prefixedText 
			.. '|talkpage]]') .. ' ' .. additionalText
	end
	
	-- build the iumb template and populate with the results.
	return frame:expandTemplate{ title = 'iumb', args = {
		id = args['id'], 
		bg = args['bg'],
		image = args['image'],
		caption = args['caption'],
		message = args['message'],
		comment = comment
		}
	}
end

return p
--</nowiki>