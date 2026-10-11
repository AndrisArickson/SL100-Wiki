local p = {}

p.knownArchiveDates = {
	["disneybrandedtelevision/pressrelease/february-2024-programming-highlights"] = "20240201004131",
	
	["disneychannel/press-releases"] = "20191220233823",
	["disneychannel/pressrelease/february-2019-programming-highlights-for-disney-channel-disney-xd-and-disney-junior"] = "20190123223611",
	["disneychannel/pressrelease/november-2018-programming-highlights-for-disney-channel-disney-xd-and-disney-junior"] = "20181020223829",
	["disneychannel/shows/star-wars-resistance/episodes"] = "20200229102930",
	["disneychannel/shows/star-wars-resistance/episodes/a-quick-salvage-run"] = "20191012032621",
	["disneychannel/shows/star-wars-resistance/episodes/bibo"] = "20191012032720",
	["disneychannel/shows/star-wars-resistance/episodes/breakout-2"] = "20191205181614", -- https://archive.vn/HjSxv
	["disneychannel/shows/star-wars-resistance/episodes/dangerous-business"] = "20190116033543",
	["disneychannel/shows/star-wars-resistance/episodes/descent"] = "20200229102912",
	["disneychannel/shows/star-wars-resistance/episodes/from-beneath"] = "20191117221250", -- https://archive.vn/mnHsc
	["disneychannel/shows/star-wars-resistance/episodes/fuel-for-the-fire"] = "20180925041050",
	["disneychannel/shows/star-wars-resistance/episodes/hunt-on-celsor-3"] = "20200312060128",
	["disneychannel/shows/star-wars-resistance/episodes/kazs-curse"] = "20191205172824", -- https://archive.vn/YUDVF
	["disneychannel/shows/star-wars-resistance/episodes/live-fire"] = "20200921093427",
	["disneychannel/shows/star-wars-resistance/episodes/no-escape-part-1"] = "20191012032621",
	["disneychannel/shows/star-wars-resistance/episodes/no-escape-part-2"] = "20191026131953",
	["disneychannel/shows/star-wars-resistance/episodes/rebuilding-the-resistance"] = "20200229102928", -- https://archive.vn/CxMl1
	["disneychannel/shows/star-wars-resistance/episodes/secrets-and-holograms"] = "20190116034307",
	["disneychannel/shows/star-wars-resistance/episodes/station-theta-black"] = "20190116034035",
	["disneychannel/shows/star-wars-resistance/episodes/station-to-station"] = "20191205164743", -- https://archive.vn/gWCbO
	["disneychannel/shows/star-wars-resistance/episodes/the-children-from-tehar"] = "20191012032732",
	["disneychannel/shows/star-wars-resistance/episodes/the-core-problem"] = "20190219075351",
	["disneychannel/shows/star-wars-resistance/episodes/the-disappeared-1"] = "20191026131954",
	["disneychannel/shows/star-wars-resistance/episodes/the-doza-dilemma"] = "20191012032725",
	["disneychannel/shows/star-wars-resistance/episodes/the-engineer"] = "20191113044314", -- https://archive.vn/BKE1l
	["disneychannel/shows/star-wars-resistance/episodes/the-escape-2"] = "20200127192457", -- https://archive.vn/lfJ2d
	["disneychannel/shows/star-wars-resistance/episodes/the-high-tower"] = "20190116040416",
	["disneychannel/shows/star-wars-resistance/episodes/the-missing-agent"] = "20191205172259", -- https://archive.vn/NSzF1
	["disneychannel/shows/star-wars-resistance/episodes/the-mutiny"] = "20200229102928", -- https://archive.vn/QHPDK
	["disneychannel/shows/star-wars-resistance/episodes/the-new-trooper"] = "20190211165643",
	["disneychannel/shows/star-wars-resistance/episodes/the-new-world-no-place-safe"] = "20200113153352",
	["disneychannel/shows/star-wars-resistance/episodes/the-recruit-part-1"] = "20190116041708",
	["disneychannel/shows/star-wars-resistance/episodes/the-relic-raiders"] = "20191113041119", -- https://archive.vn/Ex9vY
	["disneychannel/shows/star-wars-resistance/episodes/the-triple-dark"] = "20190116040142",
	["disneychannel/shows/star-wars-resistance/episodes/the-voxx-vortex-5000"] = "20191215175221", -- https://archive.vn/7Rn9V
	
	["disneyxd/executives"] = "20150315175934",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes"] = "20160625023751",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/a-hero-discovered"] = "20160623144001",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/a-new-home"] = "20170623192843",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/a-perilous-rescue"] = "20171027084540",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/crossing-paths"] = "20160802212016",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/duel-of-destiny"] = "20170623192822",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/escape-from-coruscant"] = "20171027084204",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/flight-of-the-arrowhead"] = "20171027084459",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/free-fall-1"] = "20171027084246",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/peril-on-kashyyyk"] = "20170623192828",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/race-on-tatooine"] = "20170623192748",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/return-of-the-kyber-saber"] = "20170623192752",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/return-of-the-return-of-the-jedi"] = "20171027084402",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/return-to-the-wheel"] = "20171027084438",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/showdown-on-hoth"] = "20170623192833",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-embersteel-blade"] = "20171027084250",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-kyber-saber-crystal-case"] = "20011007091125",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-lost-crystals-of-qalydon"] = "20171027084504",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-lost-crystals-of-qalydon/Disney"] = "20250404171932",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-lost-treasure-of-cloud-city"] = "20170623192848",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-maker-of-zoh"] = "20170623192758",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-mines-of-graballa"] = "20160625072924",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-pit-and-the-pinnacle"] = "20171027084407",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-storms-of-taul"] = "20171027084336",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-test"] = "20170623192838",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/the-tower-of-aliston-nor"] = "20171027084529",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/trouble-on-tibalt"] = "20170623192853",
	["disneyxd/shows/lego-star-wars-the-freemaker-adventures/episodes/zanders-joyride"] = "20170623192922",
	
	["storage/uploads/f6/49/f6494aef-9053-4035-9f1b-4e555fc822ab/press-release-9-1328657.pdf"] = "20240422013239",
}

return p