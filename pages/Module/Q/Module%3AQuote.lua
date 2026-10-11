-- This module implements [[Template:Quote]].

local p = {}

function p._main(args)
	-- Create the surrounding div.
	local root = mw.html.create('div')
	root
		:addClass('quote')
	
	-- Start a new line and add the span containing the quote.
	root
		:newline()
		:wikitext(':')
	local quoteSpan = root:tag('span')
	if args[3] then
		quoteSpan:attr('title', 'Source: ' .. args[3])
	end
	quoteSpan
		:wikitext(string.format(
			"%s''%s''%s",
			args.noquote and '' or '"',
			args[1] or '{{{1}}}',
			args.trans and '' or '"'
		))
	
	-- Add the attribution.
	root
		:newline()
		:wikitext(':&#8213;')
		:wikitext(args[2] or '{{{2}}}')

	-- Add everything that needs to go inside a noprint span.
	if args.audio or args.url or args[3] then
		local noprintSpan = root:tag('span'):addClass('noprint')

		-- Audio link
		if args.audio then
			noprintSpan
				:wikitext(string.format('&nbsp;&mdash; [[File:Quote-audio.png|20px|(audio)|link=Media:%s]] ', args.audio))
				:wikitext(string.format(
					'[[Media:%s|Listen]] <small>([[:File:%s|file info]])</small>',
					args.audio, args.audio
				))
		end

		-- Source link
		if args.url or args[3] then
			local sourceSup = noprintSpan:tag('sup')
			local display = mw.text.nowiki('[src]')
			if args.url then
				sourceSup
					:addClass('plainlinks')
					:wikitext(string.format('[%s %s]', args.url, display))
			else
				-- We have already checked that args[3] is present.
				sourceSup:wikitext(string.format('[[%s|%s]]', args[3], display))
			end
		end
	end

	-- Add the tracking category. The function passed to
	-- [[Module:SpecialCategorizer]] is called if the page being processed is
	-- not blacklisted.
	if not args.url and not args[3] then
		if mw.title.getCurrentTitle():inNamespace(0) then
			require('Module:SpecialCategorizer')._main(function ()
				-- The category link is split up so that this page isn't categorised.
				root:wikitext('[[' .. 'Category:Unsourced quotes]]')
			end)
		end
	end

	return tostring(root)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p._main(args)
end

return p