-- This module implements vote counting for article nominations.

local p = {}

function p._main(args)
	-- Capture variables
	local pageTitle = args.title
	local archive = args.archive
	local ANType = args.type
	local vip = args.count
	local redux = args.redux

	if not pageTitle then
		return ''
	end

	local title = mw.title.new(pageTitle)
	if not title then
		return ''
	end
	local nomTitle = pageTitle
	if nomTitle:find('/') then
		nomTitle = nomTitle:sub(nomTitle:find('/') + 1, #nomTitle)
	end
	
	local pageText = title:getContent()
	if not pageText then
		return ''
	end

	local vipFullname = ''
	if vip == 'AC' then
		vipFullname = 'AgriCorps'
	elseif vip == 'EC' then
		vipFullname = 'EduCorps'
	elseif vip == 'Inq' then
		vipFullname = 'Inquisitorius'
	end
	--Match text:
	--  ====Support====
	--  Match anything text found here
	--  ====Object====
	local supportText = pageText:match("Support\=+\n(.*)\n+%=+Object")
	if not supportText then
		supportText = pageText:match("Support votes\=+\n(.*)\n+%=+Object")
	end
	if not supportText then
		-- for redux nominations
		if redux then
			return '===(0) <small>('..vipFullname..' votes only)</small>==='
		-- for all other nominations
		else
			return '===(0 '..vip..'s/0 Users/0 Total)==='
		end
	end

	local vipCount = 0
	local userCount = 0
	local totalCount = 0
	local vipSummaryText

	for line in mw.text.gsplit(supportText, '\n', true) do
		line = mw.text.trim(line)

		-- Check if this vote was cast by an user with special standing for this nomination
		-- (i.e. Inquisitorius members for FANs and GANs, AgriCorps and Inquisitorius for GANs and EduCorps for CANs)
		if
		((ANType == 'FAN' or ANType == 'FAR') and mw.ustring.find(line, '#{{Inq}}', 1, true)) or
			-- Both AgriCorps and Inquisitorius members have special standing when it comes to approving GANs
			((ANType == 'GAN' or ANType == 'GAR') and (mw.ustring.find(line, '#{{Inq}}', 1, true) or mw.ustring.find(line, '#{{AC}}', 1, true))) or
			((ANType == 'CAN' or ANType == 'CAR') and mw.ustring.find(line, '#{{EC}}', 1, true))
		then
			vipCount = vipCount + 1
		-- Not a special user, check if regular
		elseif mw.ustring.find(line, '^#[^:|^%*]') then
			userCount = userCount + 1
		end
	end

	vipSummaryText = vipCount..' '..vip..'s/'
	totalCount = userCount + vipCount
	
	local msg = {}

	-- Avoid rendering tracking categories outside of active nomination subpages
	local isActiveNominationPage = not archive and mw.title.getCurrentTitle().isSubpage
	
	-- for redux nominations
	if redux then
		msg[#msg + 1] = '===(+'..vipCount..') <small>('..vipFullname..' votes only)</small>==='
		
		if ANType == 'CAN' and isActiveNominationPage then
			if vipCount == 2 then
				msg[#msg + 1] = '\n[[Category:Comprehensive article nominations requiring one more EC vote|'..nomTitle..']]'
			elseif vipCount >= 3 then
				msg[#msg + 1] = '\n[[Category:Comprehensive article nominations with sufficient votes|'..nomTitle..']]'
			end
		elseif ANType == 'GAN' and isActiveNominationPage then
			if vipCount == 2 then
				msg[#msg + 1] = '\n[[Category:Good article nominations requiring one more AC vote|'..nomTitle..']]'
			elseif vipCount >= 3 then
				msg[#msg + 1] = '\n[[Category:Good article nominations with sufficient votes|'..nomTitle..']]'
			end
		elseif ANType == 'FAN' and isActiveNominationPage then
			if vipCount == 3 then
				msg[#msg + 1] = '\n[[Category:Featured article nominations requiring one more Inq vote|'..nomTitle..']]'
			elseif vipCount >= 4 then
				msg[#msg + 1] = '\n[[Category:Good article nominations with sufficient votes|'..nomTitle..']]'
			end
		end
		return table.concat(msg)
	end
	
	msg[#msg + 1] = '===('..vipSummaryText..userCount..' Users/'..totalCount..' Total)==='

	msg[#msg + 1] = '\n(Votes required: '

	local requiredVotes

	--Voting requirements:

	--FAN:
	--5 Inq votes, or
	--4 Inq + 2 user votes, or
	--3 Inq + 4 user votes.
	--Alternatively, if a nomination is between 2-7 days old + has no active objections, it can pass with a total of 7 Inq votes.
	if ANType == 'FAN' then

		if (vipCount >= 3 and userCount >= 4) or (vipCount >= 4 and userCount >= 2) then
			if isActiveNominationPage then
				msg[#msg + 1] = '[[Category:Featured article nominations with sufficient votes|'..nomTitle..']]'
			end
		end

		if vipCount < 3 then
			msg[#msg + 1] = 3 - vipCount..' Inq vote(s) required to reach minimum.'
		end

		if vipCount <= 3 then
			if userCount >= 4 then
				msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'
			else
				if userCount >= 2 then
					requiredVotes = '1 Inq vote'
				else
					requiredVotes = '2 Inq votes'
				end
				msg[#msg + 1] = ' Additional '..4 - userCount..'  user or '..requiredVotes..' required to pass.'

				if isActiveNominationPage then
					msg[#msg + 1] = '[[Category:Featured article nominations in need of user votes|'..nomTitle..']]'
				end
			end

		elseif vipCount == 4 then
			if userCount >= 2 then
				msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'
			else
				msg[#msg + 1] = ' Additional '..2 - userCount..'  user or 1 Inq vote required to pass.'

				if isActiveNominationPage then
					msg[#msg + 1] = '[[Category:Featured article nominations in need of user votes|'..nomTitle..']]'
				end
			end

		else
			msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'

			if isActiveNominationPage then
				msg[#msg + 1] = '[[Category:Featured article nominations with sufficient votes|'..nomTitle..']]'
			end
		end

		if vipCount == 2 and isActiveNominationPage then
			msg[#msg + 1] = '[[Category:Featured article nominations requiring one more Inq vote|'..nomTitle..']]'
		end

	end

	--GAN:
	--4 AC / Inq votes:
	--3 AC votes, or
	--5 votes, min 3 AC / Inq votes
	--2 AC votes.
	--Alternatively, if a nomination is between 2-7 days old + has no active objections, it can pass with a total of 5 AC / Inq votes (min 3 AC votes).
	if ANType == 'GAN' then

		if vipCount >= 3 and userCount >= 2 and isActiveNominationPage then
			msg[#msg + 1] = '[[Category:Good article nominations with sufficient votes]]'
		end

		if vipCount < 3 then
			msg[#msg + 1] = 3 - vipCount..' AC vote(s) required to reach minimum.'
		end

		if vipCount <= 3 then
			if userCount >= 2 then
				msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'

			else
				if userCount >= 1 then
					requiredVotes = '1 user or 1 AC vote '
				else
					requiredVotes = '2 user or 1 AC votes'
				end

				msg[#msg + 1] = ' Additional '..requiredVotes..' required to pass.'

				if isActiveNominationPage then
					msg[#msg + 1] = '[[Category:Good article nominations requiring user votes|'..nomTitle..']]'
				end
			end

		else
			msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'

			if isActiveNominationPage then
				msg[#msg + 1] = '[[Category:Good article nominations with sufficient votes|'..nomTitle..']]'
			end
		end

		if vipCount == 2 and isActiveNominationPage then
			msg[#msg + 1] = '[[Category:Good article nominations requiring one more AC vote|'..nomTitle..']]'
		end

	end

	--CAN:
	--3 EC votes or
	--2 EC and 3 user votes.
	--Alternatively, if a nomination is between 2-7 days old + has no active objections, it can pass with a total of 4 EC votes.
	if ANType == 'CAN' then
			
		if vipCount >= 3 or (vipCount >= 2 and userCount >= 3) then
			msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'
			if isActiveNominationPage then
				msg[#msg + 1] = '[[Category:Comprehensive article nominations with sufficient votes|'..nomTitle..']]'
			end
			
		elseif vipCount == 2 and userCount < 3 then
			msg[#msg + 1] = ' Additional '..3 - userCount..' user or 1 EC vote required to pass.'
			if isActiveNominationPage then
				msg[#msg + 1] = '[[Category:Comprehensive article nominations requiring one more EC vote|'..nomTitle..']]'
				msg[#msg + 1] = '[[Category:Comprehensive article nominations requiring user votes|'..nomTitle..']]'
			end
		
		elseif vipCount < 2 then
			msg[#msg + 1] = 2 - vipCount..' EC vote(s) required to reach minimum.'
		
			if userCount >= 3 then
				msg[#msg + 1] = ' No additional votes required to pass, please consider reviewing another article.'
				if vipCount == 1 and isActiveNominationPage then
					msg[#msg + 1] = '[[Category:Comprehensive article nominations requiring one more EC vote|'..nomTitle..']]'
				end
			else
				msg[#msg + 1] = ' Additional '..3 - userCount..' user or 1 EC vote required to pass.'
				if isActiveNominationPage then
					msg[#msg + 1] = '[[Category:Comprehensive article nominations requiring user votes|'..nomTitle..']]'
				end
			end

		end

	end

	msg[#msg + 1] = ')'
	return table.concat(msg)
end

local getArgs = require('Module:Arguments').getArgs
function p.main(frame)
	local args = getArgs(frame)
	return p._main(args)
end

return p