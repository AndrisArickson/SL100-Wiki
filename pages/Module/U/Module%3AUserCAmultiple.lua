local p = {}

function p.main(frame)
	local articles = {}
	for num, article in ipairs(frame:getParent().args) do
		articles[num] = article
	end
		
	local ret = {}
	ret[#ret + 1] = '<div>\n{| class="userbox" cellpadding="0" cellspacing="0" style="border-color: #4682B4; background: #ADD8E6;"'
	ret[#ret + 1] = '\n| class="ubx-icon" style="background: #4682B4;" | [[File:30px-ComprehensiveArticle.png|42px]]'
	ret[#ret + 1] = string.format("\n| class=\"ubx-main\" | This user has helped promote '''%d articles''' ", #articles)
	ret[#ret + 1] = 'to [[Wookieepedia:Comprehensive articles|Comprehensive status]]:'
	
	for num, article in ipairs(articles) do
		-- determine number of articles per line
		local z = (num > 100) and 6 or 8
		-- determine whether to start a new line or continue the current line
		local divider = (num % z == 1) and "<br />" or "&nbsp;&bull; "
		-- append the current article to the list as a numbered link
		ret[#ret + 1] = string.format('%s[[%s|%d]]', divider, article, num)
	end
	
	ret[#ret + 1] = '\n|}</div>'
	
	return table.concat(ret)
end

return p