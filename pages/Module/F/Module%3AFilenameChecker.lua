p = {}
function yes(s)
	return s ~= nil and s ~= ''
end

function isValue(s, expected)
	return s ~= nil and s ~= '' and s == expected
end

function shouldFlagCategory(s)
	return s == nil or s == '' or s == '1'
end

local function makeCategoryLink(cat)
	return string.format('[[Category:%s]]', cat)
end

function buildDeleteTemplate(title, msg)
	-- Styles applied to outer div
	local inlineStyles = {
		['background'] = '#B0B0B0',
		['color'] = '#000',
		['border-radius'] = '10px'
	}
	
	--attributes for <table> 
	local padding = {
		['cellspacing'] = '0',
		['cellpadding'] = '0'
	}
	
	local container = mw.html.create('div')
	container:addClass('mobile-hide')
		:addClass('headertemplate')
		:addClass('messagebox')
		:addClass('noprint')
		:addClass('iumb')
		:css(inlineStyles)
		:tag('table')
			:attr(inlineStyles)
			:tag('tr')
				:tag('td')
				:addClass('iumb-table-container')
					:tag('table')
						:attr(padding)
						:tag('tr')
							:tag('td')
								:addClass('iumb-icon')
								:wikitext('[[File:Superlaser2.jpg|160px|Death Star]]')
							:done()
							:tag('td')
								:addClass('iumb-main')
								:tag('p')
									:tag('span')
										:addClass('iumb-caption')
										:wikitext('You may fire when ready.')
									:done()
								:done()
								:tag('p')
									:tag('span')
										:addClass('iumb-message')
										:wikitext('This page is a [[Wookieepedia:Speedy_deletions|candidate for speedy deletion]], because: '..msg..'.')
									:done()
								:done()
								:tag('p')
									:tag('span')
										:addClass('iumb-comment')
										:wikitext('If you disagree with its speedy deletion, please replace this template with {{Tl|Holdon}} and explain why on the [[File talk:'..title.text..'|talk page]]. If this page obviously does not meet the criteria for speedy deletion, or you intend to fix it, please remove this notice, but do not remove this notice from articles that you have created yourself.<br />\'\'[[Wookieepedia:Administrators|Administrators]] - Remember to check [[Special:Whatlinkshere/File:'..title.text..'|if anything links here]] and ['..title:fullUrl()..'?action=history the page history] (['..title:fullUrl()..'?diff=0 last edit]) before deleting.\'\''..makeCategoryLink('Candidates for speedy deletion'))
									:allDone()
	return container
end

function checkArtistCategory(val, args, filename)
	if filename:find('%.pdf') or filename:find('%.ogg') or yes(args.nonsw_artist) then
		return val or ''
	elseif not yes(args.author) and not yes(args.artist) then
		return val or ''
	elseif isValue(val, 'nonsw') then
		return ''
	elseif shouldFlagCategory(val) then
		return makeCategoryLink('Files without artist categorization')
	elseif isValue(val, 'skip') then
		return makeCategoryLink('Files with skipped artist category field')
	end
	return val or ''
end

function checkSubjectCategory(val, args, filename)
	if filename:find('%.pdf') then
		return val or ''
	elseif isValue(val, 'social') then
		return ''
	elseif isValue(val, 'wookyt') then
		return ''
	elseif shouldFlagCategory(val) then
		return makeCategoryLink('Files without subject categorization')
	elseif isValue(val, 'skip') then
		if yes(args.attention) and args.attention:find('user page') then
			return ''
		end
		return makeCategoryLink('Files with skipped subject category field')
	end
	return val or ''
end

function checkLicensingCategory(val, args, filename)
	if filename:find('%.pdf') then
		return val or ''
	elseif isValue(val, 'social') then
		return ''
	elseif shouldFlagCategory(val) then
		return makeCategoryLink('Files without licensing categorization')
	elseif isValue(val, 'skip') then
		if yes(args.attention) and args.attention:find('user page') then
			return ''
		end
		return makeCategoryLink('Files with skipped licensee category field')
	end
	return val or ''
end

function checkTypeCategory(val, args, filename)
	if filename:find('%.pdf') then
		return val or ''
	elseif val == 'skip' then
		return ''
	end
	return val or ''
end

function isPlainText(val)
	return yes(val) and not (val:find('%[') or val:sub(0, 1) == '[')
end

function hasLinkOrTemplate(val)
	return yes(val) and (val:find('%[') or val:find('%{'))
end

function doesSiteHaveTemplate(url, domain, sc)
	local detectSites = require('Module:WebCite').detectSitesSimple
	local result = detectSites(url, domain)
	if yes(result) and domain ~= "archive.org" then
		return 'Files with bare URL source/Convert'
	end
	return 'Files with bare URL source'
end

function hasException(val) 
	if val:find('20100227075400/http://wizards') or val:find('20220528154744/https://www.starwars') or val:find('20091217092716/http://wizards.com') or val:find('<span class="mti">') then
		return true
	end
	return false
end


function p.checkParameters(filename, args)
	local ret = {}
	local ignore = false
	if yes(args.cat_subject) and args.cat_subject:find('Category:Wookieepedia meeting header images') then
		ignore = true
	elseif yes(args.cat_licensee) and args.cat_licensee:find('Category:Wookieepedia meeting header images') then
		ignore = true
	end
	
	ret[#ret + 1] = checkArtistCategory(args.cat_artist, args, filename)
	ret[#ret + 1] = checkSubjectCategory(args.cat_subject, args, filename)
	ret[#ret + 1] = checkLicensingCategory(args.cat_licensee, args, filename)
	ret[#ret + 1] = checkTypeCategory(args.cat_type, args, filename)

	if isPlainText(args.attention) then
		ret[#ret + 1] = makeCategoryLink('Files with plaintext attention')
	end
	
	if isPlainText(args.description) then
		ret[#ret + 1] = makeCategoryLink('Files with plaintext description')
	elseif not yes(args.description) then
		ret[#ret + 1] = makeCategoryLink('Files with no description')
	end
	
	if yes(args.source) and not ignore then
		local src = args.source:gsub('{{UnknownListing.*}}', ''):gsub('%[%[Category:Unrecognized URL listings found in image sources', ''):gsub('%[%[Category:Unrecognized listings found in image sources', '')
		if src:find('http') then
			if not (src:find('%[http') and src:find('%[File:')) and not src:find('Commons:File:') then
				local domain = src:gsub('www%.', ''):gsub('www.%.', ''):match('%w+://([^/ ]+)')
				if domain and not domain:find('fandom') and not hasException(src) then
					local categoryName = doesSiteHaveTemplate(src, domain, args.cat_subject)
					if yes(domain) then
						ret[#ret + 1] = makeCategoryLink(categoryName..'|'..string.lower(domain))
						ret[#ret + 1] = '(Domain: '..domain..')'
					else
						ret[#ret + 1] = makeCategoryLink(categoryName)
					end
				end
			end
		elseif isPlainText(src) then
			ret[#ret + 1] = makeCategoryLink('Files with plaintext source')
		end
	elseif not ignore then
		ret[#ret + 1] = makeCategoryLink('Files with unknown source')
	end
	
	if yes(args.licensing) and not hasLinkOrTemplate(args.licensing) then
		ret[#ret + 1] = makeCategoryLink('Files with plaintext licensing')
	elseif not yes(args.licensing) then
		ret[#ret + 1] = makeCategoryLink('Files with unknown copyright status')
	end
	
	if yes(args.artist) and not yes(args.nonsw_artist) and not isValue(args.cat_artist, 'nonsw') and not hasLinkOrTemplate(args.artist) then
		ret[#ret + 1] = makeCategoryLink('Files with plaintext artist')
	end
	if yes(args.other_versions) and not args.other_versions:find('<gallery>') and not hasLinkOrTemplate(args.other_versions) then
		ret[#ret + 1] = makeCategoryLink('Files with plaintext other versions')
	end
	
	return table.concat(ret)
end

function p.checkFilename(filename)
	local ret = {''}
	local filename2 = mw.ustring.lower(filename)
	if mw.ustring.match(filename2, '%.png%.png$') or mw.ustring.match(filename2, '%.jpg%.jpg$') or mw.ustring.match(filename2, '%.jpeg%.jpeg$') or mw.ustring.match(filename2, '%.svg%.svg$') or mw.ustring.match(filename2, '%.ogg%.ogg$') then
		ret[#ret + 1] = makeCategoryLink('Images with double extensions in filename')
	end
	if mw.ustring.match(filename2, '%.jpeg$') then
		ret[#ret + 1] = makeCategoryLink('Images with extended extensions in filename')
	end
	if mw.ustring.match(filename2, '%.webp$') then
		ret[#ret + 1] = makeCategoryLink('Images with .webp extensions to be converted')
	end
	if mw.ustring.match(filename, '%.JPG$') or mw.ustring.match(filename, '%.JPEG$') or mw.ustring.match(filename, '%.PNG$') or mw.ustring.match(filename, '%.SVG$') or mw.ustring.match(filename, '%OGG$')then
		ret[#ret + 1] = makeCategoryLink('Images with capitalized extensions in filename')
	end
	if mw.ustring.match(filename2, 'img') or mw.ustring.match(filename2, 'picture') or mw.ustring.match(filename2, 'screenshot') or mw.ustring.match(filename2, 'screen shot') then
		ret[#ret + 1] = makeCategoryLink('Images with generic strings in filename')
	elseif mw.ustring.match(filename2, 'file') and not (
		mw.ustring.match(filename2, 'files') or
		mw.ustring.match(filename2, 'defile') or
		mw.ustring.match(filename2, 'profile') or
		mw.ustring.match(filename2, 'fact ?file')
	) then
		ret[#ret + 1] = makeCategoryLink('Images with generic strings in filename')
	elseif mw.ustring.match(filename2, 'image') and not (
		mw.ustring.match(filename2, 'images') or
		mw.ustring.match(filename2, 'userimage') or
		mw.ustring.match(filename2, 'imagecaster') or
		mw.ustring.match(filename2, 'imagery') or
		mw.ustring.match(filename2, 'pilgrimage')
	) then
		ret[#ret + 1] = makeCategoryLink('Images with generic strings in filename')
	end
	if filename:find(" ") then
		ret[#ret + 1] = makeCategoryLink("Filenames with spaces")
	end
	if mw.ustring.match(filename, "[%/%,%?%,%+%!%(%)%=’”]") then
		ret[#ret + 1] = makeCategoryLink('Images with annoying characters in filename')
	elseif mw.ustring.match(filename, "[%']") then
		ret[#ret + 1] = makeCategoryLink('Images with apostrophes in filename')
	elseif mw.ustring.match(filename, "[%&]") then
		ret[#ret + 1] = makeCategoryLink('Images with ampersands in filename')
	elseif mw.ustring.match(filename, "[%@]") then
		ret[#ret + 1] = makeCategoryLink('Images with at signs in filename')
	else
		for code in mw.ustring.gcodepoint(filename) do
			if code < 32 or code > 122 then
				ret[#ret + 1] = makeCategoryLink('Images with annoying characters in filename')
				break
			end
		end
	end
	return table.concat(ret)
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if type(k) == "number" then
			args[k] = v
		else
			args[k:gsub(' ', '_')] = v
		end
	end

	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	local title = mw.title.getCurrentTitle()
	if title.namespace ~= 6 then
		return ''
	end
	local msg = p.checkFilename(title.text) .. p.checkParameters(title.text, args)
	if not yes(args.source) then
		return buildDeleteTemplate(title, 'No source provided' .. msg)
	elseif not yes(args.licensing) then
		return buildDeleteTemplate(title, 'No licensing information provided' .. msg)
	else
		return msg
	end
end

return p