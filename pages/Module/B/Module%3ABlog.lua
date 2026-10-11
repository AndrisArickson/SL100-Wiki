-- <nowiki>
-- This module implements [[Template:Blog]].

local p = {}

function p._main(args)
	local ret = {}
	local function add(v)
		ret[#ret + 1] = v
	end

	-- Validate positional args
	for i = 1, 5 do
		args[i] = args[i] or string.format('{{{%d}}}', i)
	end

	-- Build the citation
	if args.official then
		add('[[File:Star_Wars_Blog.png|x15px|link=Star Wars Blog]]')
	else
		add('[[File:StarWarsDotComBlogsLogoStacked.png|link=Star Wars: Blogs]]')
	end
	add('&nbsp;')
	if args.official then
		if args.int then
			if args.new then
				add(string.format(
					"\"[[%s|%s]],\" [[Star Wars Blog|The Official ''Star Wars'' Blog]] " ..
					'<small>([http://www.starwars.com/news/%s link])</small>',
					args.int, args[2], args.new
				))
			else
				add(string.format(
					"\"[[%s|%s]],\" [[Star Wars Blog|The Official ''Star Wars'' Blog]] " ..
					'<small>([http://starwarsblog.starwars.com/%s link])</small>',
					args.int, args[2], args[1]
				))
			end
		else
			if args.new then
				add(string.format(
					'"[http://starwarsblog.starwars.com/%s %s]," ' ..
					"[[Star Wars Blog|The Official ''Star Wars'' Blog]]" ..
					'<small>([http://www.starwars.com/news/%s archive])</small>',
					args[1], args[2], args.new
				))
			else
				add(string.format(
					'"[http://starwarsblog.starwars.com/%s %s]," ' ..
					"[[Star Wars Blog|The Official ''Star Wars'' Blog]]",
					args[1], args[2]
				))
			end
		end
	else
		if args.listing then
			add(string.format(
				"''[https://web.archive.org/web/%shttp://blogs.starwars.com/%s %s]'', [[%s]]'s",
				args.archivedate and args.archivedate .. '/' or '',
				args[1],
				args[2],
				args[3]
			))
		elseif args.webcite then
			add(string.format(
				'"[http://www.webcitation.org/query?id=%s %s]" &ndash; ' ..
				"''[https://web.archive.org/web/http://blogs.starwars.com/%s %s]'', [[%s]]'s",
				args.webcite, args[3],
				args[1], args[4], args[5]
			))
		else
			add(string.format(
				'"[https://web.archive.org/web/%shttp://blogs.starwars.com/%s/%s %s]" &ndash; ' ..
				"''[https://web.archive.org/web/http://blogs.starwars.com/%s %s]'', [[%s]]'s",
				args.archivedate and args.archivedate .. '/' or '',
				args[1], args[2], args[3],
				args[1], args[4], args[5]
			))
		end
		local archiveService = args.webcite
			and '[[wikipedia:WebCite|WebCite]]'
			or '[[wikipedia:Internet Archive|Archive.org]]'
		add(string.format(
			' [[StarWars.com]] [[Star Wars: Blogs|Blog]] ' ..
			'<small>(content now obsolete; backup link on %s)</small>',
			archiveService
		))
	end

	return string.format(
		'<span class="plainlinks">%s</span>',
		table.concat(ret)
	)
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

-- </nowiki>