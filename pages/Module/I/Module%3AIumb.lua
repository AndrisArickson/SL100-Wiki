--[[ Original template:
	<div id="{{{id|{{<includeonly>subst:</includeonly>PAGENAMEE}}}}}" class="mobile-hide headertemplate messagebox noprint iumb hidable" style="background: {{{bg|#aaa}}}; color: {{{fg|#000}}}; border-radius:10px">
	{| cellpadding="0px" cellspacing="0"
	|-
	| class="iumb-table-container" | 
	{| cellpadding="0" cellspacing="0" class="hidable-content"
	|-
	| class="iumb-icon" | {{{image|}}}
	| class="iumb-main" |
	<span class="iumb-caption">{{{caption|}}}</span>

	<span class="iumb-message">{{{message|}}}</span>

	<span class="iumb-comment">{{{comment|}}}</span>
	|}
	| class="iumb-hidable-button" | <span class="hidable-button"></span>
	|}
	</div>
]]

local p = {}
local a = require('Dev:Arguments')

--Defaults if values aren't passed to the template
local id = string.gsub(mw.title.getCurrentTitle().baseText, ' ', '_')
local bg = '#aaa'
local fg = '#000'

function p._main(args)
	-- Overides for defaults if passed through to the template
	if args['id'] then
		id = args['id']
	end
	
	if args['bg'] then 
		bg = args['bg']
	end
	
	if args['fg'] then
		fg = args['fg']
	end
	
	--<div id="{{{id|{{<includeonly>subst:</includeonly>PAGENAMEE}}}}}" class="mobile-hide headertemplate messagebox noprint iumb hidable" style="background: {{{bg|#aaa}}}; color: {{{fg|#000}}}; border-radius:10px">
	local iumb = mw.html.create('div')
	iumb:attr(id)
		:addClass('mobile-hide headertemplate messagebox noprint iumb hidable')
		:css(
				{
					['background'] = bg,
					['color'] = fg,
					['border-radius'] = '10px'
				}
			)
		--{| cellpadding="0px" cellspacing="0"
		:tag('table')
			:attr(
					{
						['cellpadding'] = 0,
						['cellspacing'] = 0
					}
				)
				-- |-
				:tag('tr')
					--| class="iumb-table-container" | 
					:tag('td')
						:addClass('iumb-table-container')
						-- {| cellpadding="0" cellspacing="0" class="hidable-content"
						:tag('table')
							:attr(
									{
										['cellpadding'] = 0,
										['cellspacing'] = 0
									}
								)
							:addClass('hidable-content')
							-- |-
							:tag('tr')
								-- | class="iumb-icon" | {{{image|}}}
								:tag('td')
									:addClass('iumb-icon')
									:wikitext(args['image'])
								:done()
								-- | class="iumb-main" |
								:tag('td')
									:addClass('iumb-main')
									-- <span class="iumb-caption">{{{caption|}}}</span>
									:tag('p')
										:tag('span')
											:addClass('iumb-caption')
											:wikitext(args['caption'])
										:done()
									:done()
									-- <span class="iumb-message">{{{message|}}}</span>
									:tag('p')
										:tag('span')
											:addClass('iumb-message')
											:wikitext(args['message'])
										:done()
									:done()
									-- <span class="iumb-comment">{{{comment|}}}</span>
									:tag('p')
										:tag('span')
											:addClass('iumb-comment')
											:wikitext(args['comment'])
										:done()
									:done()
								-- |}
								:done()
							:done()
						:done()
						-- | class="iumb-hidable-button" | <span class="hidable-button"></span>
						:tag('td')
							:addClass('iumb-hidable-button')
							:tag('span')
								:addClass('hidable-button')
		-- |}
		-- </div>
		:allDone()
	return iumb
end

function p.main(frame)
	local args = a.getArgs(frame)
	return p._main(args)
end