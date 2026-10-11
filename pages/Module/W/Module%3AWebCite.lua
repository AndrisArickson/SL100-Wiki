-- This module implements [[Template:WebCite]].

local p = {}

-- Lazily load a mw.language object.
local lang

local NS_MAIN = 0
local NS_USER = 2
local NS_FILE = 6
local NS_INDEX = 120
local currentPageTitle = mw.title.getCurrentTitle()
local namespace = currentPageTitle.namespace
	
-- Avoid rendering tracking categories outside of main or file namespaces
local isAllowedNamespace = (namespace == NS_MAIN or namespace == NS_FILE or namespace == NS_INDEX) and true

local TEMPLATE_SEARCH = {'abramsbooks', 'acmearchivesdirect', 'acmelimited', 'altaya', 'amazon', 'ameet', 'apple', 'arcanautstudios', 'archive', 'artstation', 'asmodee', 'atomicmassgames', 'audible', 'barnesandnoble', 'bdd', 'beckermayer', 'blackstonelibrary', 'blogs.starwars', 'blogspot', 'brawlhalla', 'bsky.app', 'cara.app', 'cardboardconnection', 'cartoonnetwork', 'chronbooks', 'chroniclebooks', 'clubpenguin', 'comixology', 'costco', 'd23', 'darkhorse', 'deagostini', 'decipher', 'deviantart', 'dgepress', 'disney', 'disneyabcpress', 'disneydreamlightvalley', 'disneynow', 'disneyparksblog', 'disneyplus', 'dk', 'dorlingkindersley-uk', 'downpour', 'dreamtivity', 'ea', 'edelweiss.plus', 'egmont', 'endorexpress', 'epicgames', 'facebook', 'fandom.com', 'fanhome', 'fantasyflightgames', 'farawaypress', 'fathead', 'flickr', 'fortnite.com', 'gettyimages', 'hachette', 'hachettebookgroup', 'hardiegrant', 'harpercollins', 'hasbro', 'hasbropulse', 'haynes', 'highbridgeaudio', 'holonetnews', 'idwpublishing', 'ilm', 'imdb', 'incredibuilds', 'insighteditions', 'instagram', 'jazwares', 'joebooks', 'kabam', 'kobo', 'kodansha', 'lccn.loc.gov', 'lego', 'linecorp', 'linkedin', 'lizzie', 'lucasarts', 'lucasfilm', 'madcavestudios', 'marvel', 'minecraft.net', 'mobygames', 'mombooks', 'panini', 'paninishop', 'papercutz', 'pedigreebooks', 'penguin', 'penguingroup', 'penguinrandomhouse', 'penguinrandomhouseretail', 'pikidsmedia', 'planetadeagostini', 'play.google', 'previewsworld', 'prhcomics', 'prhinternationalsales', 'quartoknows', 'quirkbooks', 'randomhouse', 'randomhousebooks', 'randomhouseretail', 'rebelscum', 'reddit', 'rhcbooks', 'roblox', 'rocketleague', 'scholastic', 'sfbc', 'shopdisney', 'silverdolphinbooks', 'simonandschuster', 'skysound', 'spotify', 'square-enix', 'starwars', 'starwars.yahoo', 'starwarscelebration', 'starwarsgalacticracer', 'starwarshunters', 'starwarskids', 'starwarsunlimited', 'station.sony', 'steampowered', 'studiofun', 'substack', 'suvudu', 'swtor', 'target', 'taschen', 'boards.theforce.net', 'thewaltdisneycompany', 'threads.net', 'thunderbaybooks', 'tiendapanini', 'tiktok', 'titan-comics', 'titanbooks', 'titanmagazines', 'topps', 'toppsapps', 'toppsonlinestore', 'toptrumps', 'tumblr', 'tv.com', 'twitch', 'twitter', 'ubisoft', 'unboundworlds', 'unexpectedgames', 'universal-music', 'viz', 'wdtvpress', 'webtoons', 'wikia', 'wizards', 'wizkidsgames', 'wordpress', 'workman', 'wtdvpress', 'yenpress', 'youtube'}
local TEMPLATE_EXCEPTIONS = {'internet-today'}

local DEAD_SITES  = {"channelchk.com", "cuswe.org", "danielhornestudios.com", "jadbean.com", "justsayah.com", "lavender.fortunecity.com", "lucasforums.com", "mmolab.com", "red12.org"}
local DOMAINS = {
	["abcnews.com"] = "[[Wikipedia:ABC News (United States)|ABC News]]", ["abcnews.go.com"] = "[[Wikipedia:ABC News (United States)|ABC News]]",
	["advancedgraphics.com"] = "[https://advancedgraphics.com Advanced Graphics]",
	["adventuresinpoortaste.com"] = "[https://aiptcomics.com Adventures In Poor Taste]", ["aiptcomics.com"] = "[https://aiptcomics.com Adventures In Poor Taste]",
	["avclub.com"] = "[[Wikipedia:The A.V. Club|''The A.V. Club'']]",
	["aveleyman.com"] = "[https://aveleyman.com Aveleyman.com]",
	["bafta.org"] = "[[Wikipedia:British Academy of Film and Television Arts|BAFTA]]",
	["bbc.co.uk"] = "the [[Wikipedia:BBC|BBC]]", ["bbc.com"] = "the [[Wikipedia:BBC|BBC]]", ["bbc.com/news"] = "[[Wikipedia:BBC News Online|BBC News]]",
	["bfi.org.uk"] = "the [[Wikipedia:British Film Institute|British Film Institute]]",
	["biography.com"] = "[[Wikipedia:Biography (TV program)#Biography.com|''Biography'']]",
	["bleedingcool.com"] = "[[Wikipedia:Bleeding Cool|''Bleeding Cool'']]",
	["boardgamegeek.com"] = "[[Wikipedia:BoardGameGeek|BoardGameGeek]]",
	["books.google.com"] = "[[Wikipedia:Google Books|Google Books]]",
	["britannica.com"] = "[[Wikipedia:Encyclopædia Britannica|''Encyclopædia Britannica'']]",
	["cbsnews.com"] = "[[Wikipedia:CBS News|''CBS News'']]",
	["cinemablend.com"] = "[https://www.cinemablend.com ''Cinemablend'']",
	["clubjade.net"] = "[https://cludjade.net Club Jade]",
	["cnn.com"] = "[[Wikipedia:CNN|CNN]]",
	["collider.com"] = "[[Wikipedia:Valnet#Collider|''Collider'']]",
	["comicbook.com"] = "[[Wikipedia:ComicBook.com|''ComicBook.com'']]",
	["comicbookresources.com"] = "[[Wikipedia:Comic Book Resources|''Comic Book Resources'']]", ["cbr.com"] = "[[Wikipedia:Comic Book Resources|''CBR'']]",
	["dailymail.com"] = "[[Wikipedia:Daily Mail|''Daily Mail'']]", ["dailymail.co.uk"] = "[[Wikipedia:Daily Mail|''Daily Mail'']]",
	["deadline.com"] = "[[Wikipedia:Deadline Hollywood|''Deadline'']]",
	["digitalfoundry.net"] = "[[Wikipedia:Eurogamer#Digital Foundry|''Digital Foundry'']]",
	["directories.wga.org"] = "the [[Wikipedia:Writers Guild of America|Writers Guild of America]]'s [https://directories.wga.org Directory]",
	["discogs.com"] = "[[Wikipedia:Discogs|Discogs]]",
	["empireonline.com"] = "[[Wikipedia:Empire (magazine)|''Empire'']]",
	["engadget.com"] = "[[Wikipedia:Engadget|''Engadget'']]",
	["eonline.com"] = "[[Wikipedia:E!|E! Entertainment Television]]",
	["esquire.com"] = "[[Wikipedia:Esquire (magazine)|''Esquire'']]",
	["esrb.org"] = "the [[Wikipedia:Entertainment Software Rating Board|ESRB]]'s [https://www.esrb.org official website]",
	["eurogamer.net"] = "[[Wikipedia:Eurogamer|''Eurogamer'']]",
	["ew.com"] = "[[Wikipedia:Entertainment Weekly|''Entertainment Weekly'']]", ["shelf-life.ew.com"] = "[[Wikipedia:Entertainment Weekly|''Entertainment Weekly'']]",
	["fanthatracks.com"] = "[https://fanthatracks.com Fantha Tracks]",
	["forbes.com"] = "[[Wikipedia:Forbes|''Forbes'']]",
	["gameinformer.com"] = "[[Wikipedia:Game Informer|''Game Informer'']]",
	["gamerant.com"] = "[[Wikipedia:Valnet#Screen_Rant|''Game Rant'']]",
	["gamespot.com"] = "[[Wikipedia:GameSpot|GameSpot.com]]",
	["gamesradar.com"] = "[[Wikipedia:GamesRadar+|''GamesRadar+'']]",
	["gizmodo.com"] = "[[Wikipedia:Gizmodo|''Gizmodo'']]",
	["goodmorningamerica.com"] = "[[Wikipedia:Good Morning America|''Good Morning America'']]",
	["hollywood.com"] = "[[Wikipedia:Hollywood.com|''Hollywood.com'']]",
	["hollywoodreporter.com"] = "[[Wikipedia:The Hollywood Reporter|''The Hollywood Reporter'']]",
	["huffpost.com"] = "[[Wikipedia:HuffPost|''HuffPost'']]", ["huffingtonpost.com"] = "[[Wikipedia:The Huffington Post|''The Huffington Post'']]",
	["io9.gizmodo.com"] = "[[Wikipedia:Io9|''io9'']]",
	["ign.com"] = "[[Wikipedia:IGN|''IGN'']]",
	["independent.co.uk"] = "[[Wikipedia:The Independent|''The Independent'']]",
	["inverse.com"] = "[[Wikipedia:Inverse (website)|''Inverse'']]",
	["jedi-bibliothek.de"] = "[https://jedi-bibliothek.de Jedi-Bibliothek]",
	["jedinews.co.uk"] = "[https://jedinews.co.uk Jedi News]", ["jedinews.com"] = "[https://jedinews.com Jedi News]",
	["kotaku.com"] = "[[Wikipedia:Kotaku|''Kotaku'']]", ["kotaku.com.au"] = "[[Wikipedia:Kotaku|''Kotaku'']]",
	["latimes.com"] = "the [[Wikipedia:Los Angeles Times|''Los Angeles Times'']]", ["herocomplex.latimes.com"] = "the [[Wikipedia:Los Angeles Times|''Los Angeles Times'']]",
	["mashable.com"] = "[[Wikipedia:Mashable|''Mashable'']]",
	["merriam-webster.com"] = "[[Wikipedia:Merriam-Webster|Merriam-Webster]]",
	["metro.co.uk"] = "[[Wikipedia:Metro (British newspaper)|''Metro'']]",
	["midtowncomics.com"] = "[[Wikipedia:Midtown Comics|Midtown Comics]]",
	["model-space.com"] = "[[De Agostini]]'s [https://web.archive.org/web/20200922003406/https://www.model-space.com/gb/ Model Space website]",
	["mtv.com"] = "[[Wikipedia:MTV|MTV]]",
	["nbc.com"] = "[[Wikipedia:NBC|NBC]]",
	["nerdist.com"] = "[[Wikipedia:Nerdist|''Nerdist'']]",
	["newsarama.com"] = "[[Wikipedia:Newsarama|''Newsarama'']]",
	["newyorker.com"] = "[[Wikipedia:The New Yorker|''The New Yorker'']]",
	["npr.org"] = "the [[National Public Radio|NPR]]",
	["nypost.com"] = "the [[Wikipedia:New York Post|''New York Post'']]",
	["nytimes.com"] = "[[Wikipedia:The New York Times|''The New York Times'']]",
	["oscars.org"] = "the [[Wikipedia:Academy of Motion Picture Arts and Sciences|Academy of Motion Picture Arts and Sciences]]' [https://www.oscars.org official website]",
	["oswfc.de"] = "the [https://www.journal-of-the-whills.de Journal of the Whills' official website]",
	["pcgamer.com"] = "[[Wikipedia:PC Gamer|''PC Gamer'']]",
	["pcgames.de"] = "[[Wikipedia:PC Games|''PC Games'']]",
	["pegi.info"] = "the [[Wikipedia:PEGI|PEGI]]'s [https://pegi.info official website]",
	["planetdagobah.com"] = "[https://planetdagobah.com JMY's Planet Dagobah]",
	["playstarwarsuprising.com"] = "''[[Star Wars: Uprising]]''{{'s} [https://www.playstarwarsuprising.com official website]",
	["polygon.com"] = "[[Wikipedia:Polygon (website)|''Polygon'']]",
	["qidian.com"] = "[[Wikipedia:Qidian|Qidian]]",
	["qobuz.com"] = "[[Wikipedia:Qobuz|Qobuz]]",
	["rollingstone.com"] = "[[Wikipedia:Rolling Stone|''Rolling Stone'']]",
	["screenrant.com"] = "[[Wikipedia:Screen Rant|''Screen Rant'']]",
	["slashfilm.com"] = "[[Wikipedia:/Film|''/Film'']]",
	["starwars-media.de"] = "[https://www.starwars-media.de Star Wars-Media.de]",
	["starwarscommander.com"] = "''[[Star Wars: Commander]]''{{'s}} [https://www.starwarscommander.com official website]",
	["starwarsinterviews.com"] = "[[Star Wars Interviews]]",
	["swtor.jedipedia.net"] = "[[Jedipedia]]'s [https://swtor.jedipedia.net/en SWTOR Database]",
	["syfy.com"] = "[[Wikipedia:Syfy|SYFY]]",
	["talkingbay94.libsyn.com"] = "[https://talkingbay94.libsyn.com Talking Bay 94]",
	["tcdb.com"] = "the [https://tcdb.com Trading Card Database]",
	["techradar.com"] = "[[Wikipedia:TechRadar|''TechRadar'']]",
	["telegraph.co.uk"] = "[[Wikipedia:The Daily Telegraph|''The Telegraph'']]",
	["tfaw.com"] = "[https://www.tfaw.com Things From Another World]",
	["time.com"] = "[[Wikipedia:Time (magazine)|''Time'']]",
	["thedirect.com"] = "[https://thedirect.com The Direct]",
	["theforce.net"] = "[[TheForce.net]]",
	["theguardian.com"] = "[[Wikipedia:The Guardian|''The Guardian'']]",
	["thetimes.com"] = "[[Wikipedia:The Times|''The Times'']]",
	["theverge.com"] = "[[Wikipedia:The Verge|''The Verge'']]",
	["tmz.com"] = "[[Wikipedia:TMZ|''TMZ'']]",
	["universal-music.de"] = "[[Wikipedia:Universal Music Group|Universal Music Group Germany]]",
	["usatoday.com"] = "[[Wikipedia:USA Today|''USA Today'']]",
	["vanityfair.com"] = "[[Wikipedia:Vanity Fair (magazine)|''Vanity Fair'']]", ["archive.vanityfair.com"] = "[[Wikipedia:Vanity Fair (magazine)|''Vanity Fair'']]",
	["variety.com"] = "[[Wikipedia:Variety (magazine)|''Variety'']]",
	["venturebeat.com"] = "[[Wikipedia:VentureBeat|''VentureBeat'']]",
	["washingtonpost.com"] = "[[Wikipedia:The Washington Post|''The Washington Post'']]",
	["wired.com"] = "[[Wikipedia:Wired (magazine)|''Wired'']]",
	["yahoo.com"] = "[[Wikipedia:Yahoo|Yahoo]]"
}

function yes(s)
	return s ~= nil and s ~= '' and s ~= ' ' and s ~= false
end

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function isExceptionCase(u)
	for _, t in ipairs(TEMPLATE_EXCEPTIONS) do
		if u:find(t, 1, true) then
			return true
		end
	end
	return false
end
-- Formats all error messages and adds appropriate tracking category
local function makeWikitextError(msg, missing)
	-- styling for the error message
	local ret = '<span style="color: red;">[[Template:WebCite]] error: '..msg..'.</span>'
	-- add appropriate tracking category
	if isAllowedNamespace then
		if missing then
			ret = ret..'[[Category:Template usages with missing parameters]]'
		else
			ret = ret..'[[Category:Template usages with invalid parameter values]]'
		end
	end
	return ret
end

-- Formats all dates including wookieepedia linking
local function makeDateLink(date)
	lang = lang or mw.language.getContentLanguage()
	local success, dateLink
	if date and #date == 7 then 
		-- YYYY-MM
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[F]], [[Y]]',
			date .. '-01'
		)
	elseif date and #date == 4 then
		-- YYYY
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[Y]]',
			date .. '-01-01'
		)
	else
		-- YYYY-MM-DD
		success, dateLink = pcall(
			lang.formatDate, lang,
			'[[F j]], [[Y]]',
			date
		)
	end
	
	return dateLink
end

function p.detectSitesSimple(url, domain)
	local urlMatch = nil
	local _, c = (domain or ''):gsub('%.', '')
	for _, t in ipairs(TEMPLATE_SEARCH) do
		local _, x = t:gsub('%.', '')
		if (domain == t or domain:sub(0, #t + 1) == t..'.') and (c == 1 or x == 1) then
			urlMatch = t
			break
		elseif domain:sub(-(#t + 1)) == '.'..t and t:find('%.', 1, true) then
			urlMatch = t
			break
		elseif domain:find('%.'..t:gsub('%-', '%%-')..'%.', 1) then
			urlMatch = t
			break
		end
	end
	if (url:find('twitter') and not url:find('status')) or domain == 'fandom.wikia.com' or url:find('files%.wordpress') then
		urlMatch = nil
	end
	if string.find(domain, 'comicstore.marvel.com', 1, true) then
		return 'comicstore.marvel.com'
	end
	return urlMatch
end

function isPerson(page)
	for index, v in ipairs(page.categories) do
		if v == "Real-world people" then
			return true
		end
	end
	return false
end

function p.detectSites(url, isAllowedNamespace, suppress)
	if isAllowedNamespace and url and not suppress and not isExceptionCase(url) then
		local domain = string.lower(url:match('^%w+://([^/]+)'))
		local result = p.detectSitesSimple(url, domain)
		if result ~= nil and result == 'comicstore.marvel.com' then
    		return '[[Category:Comicstore links that should be converted to Marvel.com]]'
		elseif result == "archive" and not url:find('archive%.org') then
			return nil
		elseif result ~= nil then
			return '[[Category:WebCite usages instead of proper citation templates|' .. result .. ']] §'
    	end
	end
	return nil
end

function p._main(args)
	-- Capture variables
	local url = args.url
	local text = args.text
	if not text then
		text = args.title
	end
	
	-- Validate input
	if not url then
		-- missing url parameter
		return makeWikitextError("missing '''url''' parameter must be specified", true)
	end
	
	if not text then
		-- missing title parameter
		return makeWikitextError("missing '''text''' parameter must be specified", true)
	end
	
	-- Capture remaing variables
	local author = args.author
	local citeDate = args.date
	local citeFormat = args.format
	local work = args.work
	local publisher = args.publisher
	local pages = args.pages
	local language = args.language
	local quote = args.quote
	local archiveDate = args.archivedate
	local isOldVersion = args.oldversion ~= nil and args.oldversion ~= "" and args.oldversion ~= '1'
	if isOldVersion then
		archiveDate = args.oldversion or archiveDate
	end
	local archiveUrl = args.archiveurl
	local archiveFile = args.archivefile
	local noBackup = yes(args.nobackup)
	local noLive = yes(args.nolive) or yes(args.dead_site)
	local deadSite = yes(args.dead_site)
	local isInternetArchive = url:gsub('www%.', ''):find('//archive.org', 1, true)
	local isOtherArchive = url:gsub('www%.', ''):find('//archive%.%a+/') 
	local noWork = nil
	local extraWork = nil
    
    -- grab the website's domain name which we'll use for the website title
    local website = url:match('^(%w+://[^/]+)')
    local domain = url:match('^%w+://([^/]+)')
    if not deadSite and hasValue(DEAD_SITES, domain:gsub('www%.', ''):gsub('www2%.', '')) then
    	deadSite = true
    	noLive = true
    end
	
	-- check for any badly formatted urls
	if not mw.ustring.find(url, 'http://') and not mw.ustring.find(url, 'https://')  then
		local ret = {}
		ret[#ret + 1] = makeWikitextError("badly formatted '''url''' parameter", false)
		if isAllowedNamespace then
			ret[#ret + 1] = '[[Category:Web citation template usages with invalid URL parameters]]'
			return table.concat(ret)
		end
	end

	local middle = {}
	-- Language
	if language then
		middle[#middle + 1] = '&#32;('..language..')'
	end

	-- Format or Pages
	if citeFormat or pages then
		-- opening (
		middle[#middle + 1] = '&#32;('
		
		-- Format
		if citeFormat then
			middle[#middle + 1] = citeFormat
		end
		
		-- add a space if both
		if citeFormat and pages then
			middle[#middle + 1] = '&#32;'
		end
		
		-- Pages
		if pages then
			middle[#middle + 1] = pages
		end
		
		-- closing )
		middle[#middle + 1] = ')'
	end
	
	-- Author
	if author then
		middle[#middle + 1] = '&#32;by '..author
	end

	-- Publisher
	if publisher then
		middle[#middle + 1] = ',&#32;published by '..publisher
	end
	
	-- Work
	if isInternetArchive then
		middle[#middle + 1] = "&#32;on the [https://archive.org Internet Archive]"
    else
    	-- if work parameter hasn't been provided, we can create a link to the website's homepage automatically
    	-- grab the website's homepage - including http(s)://
        if domain ~= "" and DOMAINS[domain:gsub('www%.', ''):gsub('www2%.', '')] ~= nil then
        	local dx = DOMAINS[domain:gsub('www%.', ''):gsub('www2%.', '')]
			if work and namespace ~= NS_USER then
				extraWork = domain:gsub('www%.', ''):gsub('www2%.', ''):gsub('cdn%.', '')
				dx = '<u>'..dx..'</u>'
			end
			middle[#middle + 1] = "&#32;on "..dx
        elseif work then
			middle[#middle + 1] = "&#32;on "..work
		else
        	middle[#middle + 1] = "&#32;on ["..website..' '..domain.."]"
        	noWork = domain:gsub('www%.', ''):gsub('www2%.', ''):gsub('cdn%.', '')
        end
	end
	
	-- Date
	if citeDate then
		-- add a formatted data
		middle[#middle + 1] = '&#32;('..makeDateLink(citeDate)..')'
		-- check if date contains letters
		-- we only want dates formatted as YYYY-MM-DD e.g. 2020-11-23)
		if mw.ustring.find(citeDate, 'a') or mw.ustring.find(citeDate, 'e') or mw.ustring.find(citeDate, 'u') then
    		-- any dates containing the above letters, e.g. Jan 12, 2019
    		-- add the appropriate tracking category
    		if isAllowedNamespace then
				middle[#middle + 1] = '[[Category:WebCite date argument usages with incorrect date formats]]'
			end
        end
	end
	
	-- Quote
	if quote then
		middle[#middle + 1] = '&#58;&#32;"'..quote..'"'
	end
	
	local middleText = table.concat(middle)
	
	local ret = {'[[File:Premium-Era-real.png|text-top|x14px|class=darkmodeinvert]]&#32;'}
	local backupLink = ''
	if archiveUrl then
		backupLink = archiveUrl
    elseif archiveDate then
		backupLink = 'https://web.archive.org/web/'..archiveDate..'/'..url
    end

    if noBackup then
    	ret[#ret + 1] = '['..url..' '..text..']'
    	ret[#ret + 1] = middleText
    	ret[#ret + 1] = ' <small>(content obsolete and backup link not available)</small>'
    	
    elseif isInternetArchive or isOtherArchive then 
    	ret[#ret + 1] = '['..url..' '..text..']'
    	ret[#ret + 1] = middleText
    	
    elseif yes(backupLink) and noLive then
		ret[#ret + 1] = '['..backupLink..' '..text..']'
		ret[#ret + 1] = middleText
    	if not deadSite then
			ret[#ret + 1] = ' <small>(['..url..' original page] now obsolete)</small>'
		end
		
    else
    	ret[#ret + 1] = '['..url..' '..text..']'
    	ret[#ret + 1] = middleText
    	ret[#ret + 1] = '&#32;<small>('
        if noLive then
             ret[#ret + 1] = 'content now obsolete;&#32;'
        end
		
		-- Full Wayback URL given
    	if archiveUrl and archiveUrl:find('web%.archive%.org/web') then
    		-- so return it with appropriate tracking categories
    		if isAllowedNamespace then
    			local st = string.lower(url:gsub('http://', ''):gsub('https://', ''):gsub('www%.', ''):gsub('%/$', ''))
				local tx = string.lower(archiveUrl:gsub('http://', ''):gsub('https://', ''):gsub('www%.', ''))
				if tx:find(st, 1, true) then
					ret[#ret + 1] = '[[Category:Archiveurl usages instead of archivedate]]'
				else
					ret[#ret + 1] = '[[Category:Archiveurl usages with Wayback URLs]]'
				end
			end
    	end
	
		if archiveDate and archiveDate:find('-') and namespace ~= NS_USER then
			ret[#ret + 1] = '[[Category:Usages of archivedate with incorrect format]]'
		end
        
        if archiveFile ~= nil and archiveFile ~= "" then
        	ret[#ret + 1] =	'[[:' .. archiveFile .. '|screenshot]]'
        elseif backupLink ~= nil and backupLink ~= "" then
        	ret[#ret + 1] = '['..backupLink..' backup link]'
		else
			-- format unverifie backup link message
	        local verifyBackupLink = '[[Template:WebCite|<span style="color: red;">\'\'\'not verified!\'\'\'</span>]]'
	        -- create a temporary Wayback link from the url
	        ret[#ret + 1] = '[https://web.archive.org/web/'..url..' backup link]&#32;'..verifyBackupLink
	        -- add a tracking category for the missing archival links
    		if isAllowedNamespace then
    			local targetDomain = url:match('^%w+://([^/]+)')
    			local sx = (targetDomain and '|'..targetDomain or ''):gsub('www.', '')
				ret[#ret + 1] = '[[Category:Pages with missing permanent archival links'..sx..']]'
			end
		end
		ret[#ret + 1] = ')</small>'
    end
    
    local siteCat = p.detectSites(url, isAllowedNamespace, args.suppress)
	if siteCat ~= nil then
		ret[#ret + 1] = siteCat
    end
    
    if text and not url:find('starwarsuprising')  then
    	if string.find(string.lower(text), 'official website') or string.find(string.lower(text), 'official site') or string.find(string.lower(text), 'official home') or string.find(string.lower(text), 'official page') then
    		ret[#ret + 1] = '[[Category:WebCite usages with official in text field]]'
    	elseif string.find(currentPageTitle.text, '%(') then
    		local tx = string.sub(0, string.find(currentPageTitle.text, ' %(') - 1)
    		if string.find(string.lower(text), string.lower(currentPageTitle.text)) and string.find(string.lower(text), 'site') then
    			ret[#ret + 1] = '[[Category:WebCite usages with official in text field]]'
    		end
		elseif string.find(string.lower(text), string.lower(currentPageTitle.text)) and string.find(string.lower(text), 'site') then
			ret[#ret + 1] = '[[Category:WebCite usages with official in text field]]'
		end
    end
    if extraWork ~= nil and isAllowedNamespace then
    	ret[#ret + 1] = '[[Category:WebCite usages with unnecessary work parameters|'..extraWork..']]'
    elseif noWork ~= nil and isAllowedNamespace then
    	local px = ''
		if isPerson(currentPageTitle) then
			px = '/Person'
		end
    	if author then
    		ret[#ret + 1] = '[[Category:WebCite usages with author but no work parameter|'..noWork..']]'
    	else
    		ret[#ret + 1] = '[[Category:WebCite usages without work parameter'..px..'|'..noWork..']]'
    	end
    end
    if args.unnamed and isAllowedNamespace then
    	ret[#ret + 1] = '[[Category:Web citation template usages with positional parameters]] §'
    end
    if args.empty and isAllowedNamespace then
    	ret[#ret + 1] = '[[Category:Web citation template usages with empty parameters]] §'
    end
    if string.find(string.lower(text), 'solicit') and url ~= "https://www.newsarama.com/48729-marvel-comics-april-2020-solicitations.html" then
		ret[#ret + 1] = '[[Category:WebCite solicitation listings]]'
	end
	
	-- final output
	return table.concat(ret)
end

-- this has slightly slower performance than the next function
--local getArgs = require('Module:Arguments').getArgs
--function p.main(frame)
--	local args = getArgs(frame)
--	return p._main(args)
--end

function p.detection(frame)
	local args = {}
	for k, v in pairs(frame.args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		end
	end
	return p.detectSites(args.url, isAllowedNamespace, args.suppress) or ''
end

function p.main(frame)
	local args = {}
	for k, v in pairs(frame:getParent().args) do
		v = v:match('^%s*(.-)%s*$') -- trim whitespace
		if v ~= '' then
			args[k] = v
		elseif v ~= nil then
			args['empty'] = true
		end
		if type(k) == "number" then
			args.unnamed = true
		end
	end
	return p._main(args)
end

return p