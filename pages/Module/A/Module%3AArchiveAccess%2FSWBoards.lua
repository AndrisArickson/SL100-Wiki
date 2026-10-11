local p = {}

p.knownArchiveDates = {
	['ann.jspa?annID=3'] = '20110517215506', -- May 03, 2011 11:27 AM  --
	['message.jspa?messageID=10042225#10042225'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=10042225.html#10042225', -- Mar 25, 2005 10:39 AM --
	['message.jspa?messageID=11190039#11190039'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=11190039.html#11190039', -- Jun 06, 2005 04:00 PM --
	['message.jspa?messageID=11227257#11227257'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=11227257.html#11227257', -- Jun 04, 2005 08:41 AM --
	['message.jspa?messageID=14952461#14944330'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=14952461.html#14944330', -- Jun 02, 2006 06:29 PM --
	['message.jspa?messageID=15741200#15741200'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=15741200.html#15741200', -- Oct 05, 2006 03:36 PM --
	['message.jspa?messageID=16446203#16446203'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=16446203.html#16446203', -- Mar 30, 2007 10:52 AM --
	['message.jspa?messageID=17262421#17262421'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17262421.html#17262421', -- May 22, 2008 09:13 PM --
	['message.jspa?messageID=17356896#17356896'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17356896.html#17356896', -- Sep 05, 2008 10:06 PM --
	['message.jspa?messageID=17382153#17382153'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17382153.html#17382153', -- Sep 30, 2008 08:36 AM --
	['message.jspa?messageID=17382195#17382195'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17382195.html#17382195', -- Sep 30, 2008 09:12 AM --
	['message.jspa?messageID=17427002#17427002'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17427002.html#17427002', -- Nov 06, 2008 10:24 AM --
	['message.jspa?messageID=17480399#17480399'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17480399.html#17480399', -- Dec 18, 2008 12:25 PM --
	['message.jspa?messageID=17653340#17653340'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17653340.html#17653340', -- Jun 10, 2009 05:07 PM --
	['message.jspa?messageID=17661356#17661356'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17661356.html#17661356', -- Jun 22, 2009 03:09 PM --
	['message.jspa?messageID=17703919#17703919'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17703919.html#17703919', -- Aug 13, 2009 06:41 PM --
	['message.jspa?messageID=17704276#17704276'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17704276.html#17704276', -- Aug 14, 2009 09:35 AM --
	['message.jspa?messageID=17843490#17843486'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17843490.html#17843486', -- Feb 11, 2010 05:07 PM --
	['message.jspa?messageID=17888737#17888737'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17888737.html#17888737', -- May 04, 2010 04:01 PM --
	['message.jspa?messageID=17919822#17919822'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3FmessageID=17919822.html#17919822', -- Jul 19, 2010 10:54 AM -- -- also at https://archive.md/K8CjZ --
	['message.jspa?messageID=17933823#17933823'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3FmessageID=17933823.html#17933823', -- Oct 04, 2010 10:33 AM -- -- also at https://archive.is/tCAeC --
	['message.jspa?messageID=17950706#17950706'] = '20110205074344', -- Jan 28, 2011 12:13 PM --
	['message.jspa?messageID=17950706#17950733'] = '20110205074344', -- Jan 28, 2011 01:35 PM --
	['message.jspa?messageID=17960213#17960213'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=17960213.html#17960213', -- Mar 18, 2011 11:50 AM --
	['message.jspa?messageID=2975824#2975824'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=2975824.html#2975824', -- Nov 04, 2002 12:02 PM --
	['message.jspa?messageID=6393803#6393803'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=6393803.html#6393803', -- Apr 14, 2004 04:54 PM --
	['message.jspa?messageID=6393975#6393975'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=6393975.html#6393975', -- Apr 14, 2004 05:13 PM --
	['message.jspa?messageID=8960677#8960677'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=8960677.html#8960677', -- Dec 17, 2004 06:40 PM --
	['message.jspa?messageID=8972423#8972423'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=8972423.html#8972423', -- Dec 18, 2004 11:41 PM --
	['message.jspa?messageID=8972568#8972568'] = 'http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=8972568.html#8972568', -- Dec 18, 2004 11:59 PM --
	['thread.jspa?forumID=24&start=1003&threadID=161064&msRange=15#6815332'] = '20070321225716', -- Jun 04, 2004 10:40 AM --
	['thread.jspa?forumID=24&start=1003&threadID=161064&msRange=15#6816002'] = '20070321225716', -- Jun 04, 2004 12:09 PM --
	['thread.jspa?forumID=24&start=15&threadID=152583&msRange=15#5706120'] = '20070315065628', -- Jan 21, 2004 09:16 AM --
	['thread.jspa?forumID=24&start=2862&threadID=93010&msRange=15#4022911'] = '20070621165200', -- May 30, 2003 12:09 PM --
	['thread.jspa?forumID=24&start=4365&threadID=93010&msRange=15#5003349'] = '20071202011941', -- Oct 08, 2003 11:40 AM --
	['thread.jspa?forumID=24&start=9621&threadID=93010&msRange=15.html#3055963'] = 'https://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fforumID=24&start=9621&threadID=93010&msRange=15.html#3055963', -- Nov 15, 2002 11:24 AM --
	['thread.jspa?forumID=76&threadID=121259#4023912'] = '20070820092933', -- May 30, 2003 04:15 PM --
	['thread.jspa?messageID=14866609#14857902'] = '20070104184209', -- May 23, 2006 01:53 PM --
	['thread.jspa?messageID=14866609#14864813'] = '20070104184209', -- May 24, 2006 01:31 PM --
	['thread.jspa?messageID=14866609#14874305'] = '20070104184209', -- May 25, 2006 01:27 PM --
	['thread.jspa?messageID=14866609#14882262'] = '20070104184209', -- May 26, 2006 12:30 PM --
	['thread.jspa?messageID=15595474&#15595436'] = '20100213223010', -- Sep 03, 2006 07:53 AM --
	['thread.jspa?messageID=15595474&#15595495'] = '20100213223010', -- Sep 03, 2006 08:17 AM --
	['thread.jspa?messageID=15686091#15687580'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3FmessageID=15686091&.html#15687580', -- Sep 23, 2006 04:20 PM -- -- also at https://archive.is/Snc7V -- 
	['thread.jspa?messageID=15725996#15725996'] = '20070103022357', -- Oct 02, 2006 11:01 AM --
	['thread.jspa?messageID=16047412#15881207'] = '20070206194650', -- Nov 03, 2006 10:35 AM --
	['thread.jspa?messageID=17079483#17078201'] = '20090130142615', -- Jan 07, 2008 05:31 PM --
	['thread.jspa?messageID=17137740#17137740'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fmessageID=17137740.html#17137945', -- Quotes article desired --
	['thread.jspa?messageID=17849536#17848899'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fmessageID=17849536.html#17848899', -- Feb 20, 2010 07:44 AM --
	['thread.jspa?messageID=17880796#17880796'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fmessageID=17880796.html#17880796', -- Apr 19, 2010 11:25 AM --
	['thread.jspa?messageID=17909621#17909607'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3FmessageID=17909621.html#17909607', -- Jun 17, 2010 04:10 PM --
	['thread.jspa?messageID=17923716#17923653'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fmessageID=17923716.html#17923653', -- Aug 07, 2010 02:30 AM --
	['thread.jspa?threadID=118855&start=0#3887362'] = '20091124132158', -- Apr 29, 2003 06:38 PM --
	['thread.jspa?threadID=118855&start=15#3897382'] = '20041105010727', -- May 01, 2003 01:40 PM --
	['thread.jspa?threadID=118855&start=15#3902656'] = '20041105010727', -- May 02, 2003 01:03 PM --
	['thread.jspa?threadID=118855&start=281#4612881'] = '20100114004201', -- Aug 18, 2003 08:59 AM --
	['thread.jspa?threadID=118855&start=30#3929926'] = '20041105010449', -- May 08, 2003 09:28 AM --
	['thread.jspa?threadID=118855&start=60#4037723'] = '20090525065338', -- Jun 03, 2003 09:43 AM --
	['thread.jspa?threadID=118855&tstart=0#3887549'] = '20070911125115', -- Apr 29, 2003 06:59 PM --
	['thread.jspa?threadID=125719&start=0675#10095628'] = '20080205154052', -- Mar 29, 2005 11:02 AM --
	['thread.jspa?threadID=146095&start=60#5301701'] = '20080125080006', -- Nov 17, 2003 05:20 PM --
	['thread.jspa?threadID=151531#5575754'] = '20070913210923', -- Dec 31, 2003 09:56 PM --
	['thread.jspa?threadID=152583&start=0#5630559'] = '20070209002111', -- Jan 09, 2004 01:38 PM --
	['thread.jspa?threadID=152583&start=01005#15930568'] = '20070213020909', -- Nov 15, 2006 09:17 AM --
	['thread.jspa?threadID=152583&start=01200#16270670'] = '20070210160311', -- Feb 06, 2007 03:45 PM --
	['thread.jspa?threadID=152583&start=01515#16873740'] = '20080118155832', -- Aug 30, 2007 02:06 PM --
	['thread.jspa?threadID=152583&start=01725#17122037'] = '20100608073032', -- Feb 05, 2008 02:34 PM --
	['thread.jspa?threadID=152583&start=01755#17147721'] = '20070227204935', -- Feb 20, 2008 04:19 PM --
	['thread.jspa?threadID=152583&start=01779#17175930'] = '20070227204935', -- Mar 11, 2008 02:00 AM --
	['thread.jspa?threadID=152583&start=02178#13682994'] = '20101208104053', -- Dec 12, 2005 12:17 PM --
	['thread.jspa?threadID=152583&start=0735#14905348'] = '20071109215721', -- May 29, 2006 12:33 PM --
	['thread.jspa?threadID=152583&start=0783#15368158'] = '20090306064237', -- Jul 29, 2006 10:57 PM --
	['thread.jspa?threadID=152583&start=0960#15875597'] = '20070305085939', -- Nov 02, 2006 10:17 AM --
	['thread.jspa?threadID=152583&start=0960#15882292'] = '20070305085939', -- Nov 03, 2006 05:05 PM --
	['thread.jspa?threadID=152583&start=0960#15884843'] = '20070305085939', -- Nov 04, 2006 12:34 AM --
	['thread.jspa?threadID=152583&start=1005#15927177'] = '20070227172518', -- Nov 14, 2006 10:16 AM --
	['thread.jspa?threadID=152583&start=1020#15975856'] = '20070227172528', -- Nov 27, 2006 02:41 PM --
	['thread.jspa?threadID=152583&start=1050#16016055'] = '20070227204935', -- Dec 06, 2006 11:04 AM --
	['thread.jspa?threadID=152583&start=1050#16017778'] = '20070227204935', -- Dec 06, 2006 04:23 PM --
	['thread.jspa?threadID=152583&start=1062#16021160'] = '20071118073826', -- Dec 07, 2006 06:15 PM --
	['thread.jspa?threadID=152583&start=1075#16045442'] = '20070918154522', -- Dec 13, 2006 04:49 PM --
	['thread.jspa?threadID=152583&start=1075#16050074'] = '20070918154522', -- Dec 14, 2006 06:35 PM --
	['thread.jspa?threadID=152583&start=1095#16069962'] = '20070227204955', -- Dec 20, 2006 12:09 AM --
	['thread.jspa?threadID=152583&start=1125#16098316'] = '20070303055750', -- Dec 28, 2006 04:01 PM --
	['thread.jspa?threadID=152583&start=1170#16176459'] = '20070303055800', -- Jan 15, 2007 10:06 AM --
	['thread.jspa?threadID=152583&start=1185#16225670'] = '20071014214710', -- Jan 26, 2007 10:13 AM --
	['thread.jspa?threadID=152583&start=1230#16292515'] = '20081210132938', -- Feb 12, 2007 09:34 AM --
	['thread.jspa?threadID=152583&start=1290#16446203'] = '20070513210038', -- Mar 30, 2007 11:52 AM --
	['thread.jspa?threadID=152583&start=1335#16585930'] = '20090604132018', -- May 12, 2007 04:53 PM --
	['thread.jspa?threadID=152583&start=135#7316411'] = '20071030034540', -- Jul 26, 2004 01:54 AM --
	['thread.jspa?threadID=152583&start=1380#16660523'] = '20070702210157', -- Jun 04, 2007 03:28 PM --
	['thread.jspa?threadID=152583&start=1395#16675997'] = '20070702212436', -- Jun 08, 2007 06:48 AM --
	['thread.jspa?threadID=152583&start=1545#16926420'] = '20091128092741', -- Sep 26, 2007 05:34 PM --
	['thread.jspa?threadID=152583&start=165#7421450'] = '20070312004335', -- Aug 04, 2004 01:40 PM --
	['thread.jspa?threadID=152583&start=1695#17083464'] = '20080627063200', -- Jan 10, 2008 03:09 PM --
	['thread.jspa?threadID=152583&start=1701#17078201'] = '20090821071309', -- Jan 07, 2008 05:31 PM --
	['thread.jspa?threadID=152583&start=1755#17143245'] = '20080917092924', -- Feb 18, 2008 01:47 PM --
	['thread.jspa?threadID=152583&start=1838#17243049'] = '20070227204935', -- May 08, 2008 09:16 AM --
	['thread.jspa?threadID=152583&start=1838#17244593'] = '20070227204935', -- May 09, 2008 06:37 PM --
	['thread.jspa?threadID=152583&start=1860#17269953'] = '20081223232348', -- May 28, 2008 01:52 PM -- 
	['thread.jspa?threadID=152583&start=1980#17325828'] = '20081226002958', -- Aug 03, 2008 09:24 AM --
	['thread.jspa?threadID=152583&start=450#12104272'] = '20070301030335', -- Jul 31, 2005 08:13 AM --
	['thread.jspa?threadID=152583&start=480#13125742'] = '20070302040345', -- Oct 24, 2005 12:08 PM --
	['thread.jspa?threadID=152583&start=488#13131496'] = '20070906232057', -- Oct 25, 2005 09:28 AM --
	['thread.jspa?threadID=152583&start=495#13204255'] = '20060306023610', -- Nov 02, 2005 09:12 AM --
	['thread.jspa?threadID=152583&start=525#13396547'] = '20060306023622', -- Nov 22, 2005 10:32 AM --
	['thread.jspa?threadID=152583&start=525#13512475'] = '20060306023622', -- Dec 07, 2005 02:11 PM --
	['thread.jspa?threadID=152583&start=525#13513163'] = '20060306023622', -- Dec 07, 2005 04:07 PM --
	['thread.jspa?threadID=152583&start=552#13548069'] = '20070227204935', -- Dec 12, 2005 10:39 AM --
	['thread.jspa?threadID=152583&start=567#13561196'] = '20090204154212', -- Dec 13, 2005 05:01 PM --
--	['thread.jspa?messageID=14726348#14724917'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fmessageID=14726348&.html#14724917', -- May 03, 2006 05:45 PM --
	['thread.jspa?threadID=152583&start=690#14724917'] = '20070915041936', -- May 03, 2006 05:45 PM --
	['thread.jspa?threadID=152583&start=752#14952461'] = '20091004051007', -- Jun 04, 2006 03:05 AM --
	['thread.jspa?threadID=152583&start=840#15679046'] = '20080411235529', -- Sep 21, 2006 02:45 PM --
	['thread.jspa?threadID=152583&start=855#15714853'] = '20071201092136', -- Sep 29, 2006 12:30 PM --
	['thread.jspa?threadID=152583&start=870#15735034'] = '20061115064750', -- Oct 04, 2006 11:01 AM --
	['thread.jspa?threadID=152583&start=870#15778940'] = '20061115064750', -- Oct 12, 2006 06:13 PM -- -- also at message.jspa?messageID=15778940 / http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=15778940.1.html --
	['thread.jspa?threadID=152583&start=870#15782460'] = '20061115064750', -- Oct 13, 2006 08:50 AM --
	['thread.jspa?threadID=152583&start=900#15797286'] = '20070224114628', -- Oct 16, 2006 02:31 PM --
	['thread.jspa?threadID=152583&start=900#15800617'] = '20070224114628', -- Oct 17, 2006 09:58 AM --
	['thread.jspa?threadID=152583&start=900#15805386'] = '20070224114628', -- Oct 18, 2006 11:47 AM --
	['thread.jspa?threadID=152583&start=915#15828175'] = '20080921205233', -- Oct 23, 2006 11:28 AM --
	['thread.jspa?threadID=152583&start=930#15832349'] = '20070301145148', -- Oct 24, 2006 10:48 AM --
	['thread.jspa?threadID=152583&start=955#15870004'] = '20081202185124', -- Nov 01, 2006 12:47 PM --
	['thread.jspa?threadID=152583&start=960#15881257'] = '20070301145148', -- Nov 03, 2006 11:05 AM --
	['thread.jspa?threadID=152583&start=980#15895005'] = '20090131110522', -- Nov 06, 2006 06:03 PM --
	['thread.jspa?threadID=152583&start=980#15912108'] = '20090131110522', -- Nov 10, 2006 02:28 PM --
	['thread.jspa?threadID=152583&start=990#15923535'] = '20070227172437', -- Nov 13, 2006 01:42 PM --
	['thread.jspa?threadID=158725&start=0#16092867'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=158725&start=0.html#16092867', -- Dec 27, 2006 06:13 AM --
	['thread.jspa?threadID=158725&start=0#5978529'] = '20070224010212', -- Feb 25, 2004 05:53 PM --
	['thread.jspa?threadID=158725&start=0&tstart=0.html#15923277'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=158725&start=0&tstart=0.html#15923277', -- Nov 13, 2006 12:16 PM --
	['thread.jspa?threadID=158725&start=120#12150567'] = '20070224013819', -- Aug 03, 2005 12:46 PM --
	['thread.jspa?threadID=158725&start=75#11220749'] = '20070209003010', -- Jun 06, 2005 09:57 AM --
	['thread.jspa?threadID=158725&start=88#11212876'] = '20091116022748', -- Jun 05, 2005 08:25 PM --
	['thread.jspa?threadID=158725&start=97#11593602'] = '20090310180928', -- Jun 27, 2005 10:12 AM --
	['thread.jspa?threadID=158725&start=97#8047131'] = '20100820051251', -- Sep 27, 2004 10:18 AM --
	['thread.jspa?threadID=169992&start=120#9335559'] = '20070224114709', -- Jan 21, 2005 11:25 AM --
	['thread.jspa?threadID=169992&start=120#9393638'] = '20070224114709', -- Jan 26, 2005 02:18 PM --
	['thread.jspa?threadID=169992&start=135#9435937'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=169992&start=120.html#9435937', -- Jan 30, 2005 12:49 PM --
	['thread.jspa?threadID=169992&start=150#9571765'] = '20070227094146', -- Feb 11, 2005 06:06 AM --
	['thread.jspa?threadID=169992&start=152#9529539'] = '20100524173602', -- Feb 07, 2005 08:33 PM --
	['thread.jspa?threadID=189387#7516035'] = '20070205061347', -- Aug 12, 2004 11:44 AM --
	['thread.jspa?threadID=196444&start=105#9446385'] = '20090317055755', -- Jan 31, 2005 12:31 PM --
	['thread.jspa?threadID=196444&start=119#9996211'] = '20080918124740', -- Mar 21, 2005 04:41 PM --
	['thread.jspa?threadID=196444&start=255#10054094'] = '20070513210907', -- Mar 26, 2005 07:57 AM --
	['thread.jspa?threadID=196444&start=285#10095419'] = '20070510064239', -- Mar 29, 2005 10:49 AM --
	['thread.jspa?threadID=212251&start=30#10644261'] = '20070630210225', -- May 06, 2005 08:45 AM --
	['thread.jspa?threadID=219272&start=0#10841249'] = '20070301143005', -- May 18, 2005 02:22 PM --
	['thread.jspa?threadID=219272&tstart=175#10894723'] = '20070224235011', -- May 21, 2005 02:09 AM --
	['thread.jspa?threadID=219669&start=18#11152866'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=219669&start=18.html#11152866', -- Jun 02, 2005 01:01 PM --
	['thread.jspa?threadID=222689&messageID=13615282#13615282'] = '20071017001103', -- Dec 19, 2005 02:58 PM --
	['thread.jspa?threadID=222689&start=0#11013171'] = '20080604223852', -- May 26, 2005 07:31 AM --
	['thread.jspa?threadID=222689&start=01230#13479250'] = '20071212051307', -- Dec 03, 2005 02:06 PM --
	['thread.jspa?threadID=222689&start=01860#14602997'] = '20070819162141', -- Apr 18, 2006 08:53 AM --
	['thread.jspa?threadID=222689&start=02265#15031920'] = '20070918155811', -- Jun 14, 2006 01:08 PM --
	['thread.jspa?threadID=222689&start=03975#16213611'] = '20080303182723', -- Jan 23, 2007 09:21 AM --
	['thread.jspa?threadID=222689&start=04305#16361113'] = '20070519004547', -- Mar 05, 2007 04:13 PM --
	['thread.jspa?threadID=222689&start=04500#16459298'] = '20071115005218', -- Apr 03, 2007 01:58 PM --
	['thread.jspa?threadID=222689&start=04740#16631159'] = '20090701070455', -- May 28, 2007 09:06 AM --
	['thread.jspa?threadID=222689&start=04980#16712103'] = '20070713004016', -- Jun 18, 2007 09:57 AM --
	['thread.jspa?threadID=222689&start=07245#17383813'] = '20081006031935', -- Oct 01, 2008 04:35 PM --
	['thread.jspa?threadID=222689&start=07440#17398526'] = '20090228174822', -- Oct 14, 2008 11:47 AM --
	['thread.jspa?threadID=222689&start=08895#17646435'] = '20100504081324', -- Jun 02, 2009 02:09 PM --
	['thread.jspa?threadID=222689&start=09495#17704281'] = '20090903101745', -- Aug 14, 2009 09:38 AM --
	['thread.jspa?threadID=222689&start=1185#13440451'] = '20100329044945', -- Nov 28, 2005 10:46 AM --
	['thread.jspa?threadID=222689&start=1185#13440464'] = '20100329044945', -- Nov 28, 2005 10:50 AM --
	['thread.jspa?threadID=222689&start=1230#13464906'] = '20070918154701', -- Dec 01, 2005 01:46 PM --
	['thread.jspa?threadID=222689&start=1230#13478643'] = '20070918154701', -- Dec 03, 2005 12:48 PM --
	['thread.jspa?threadID=222689&start=1230#13480202'] = '20070918154701', -- Dec 03, 2005 04:01 PM --
	['thread.jspa?threadID=222689&start=1365#13853393'] = '20070823051907', -- Jan 16, 2006 02:00 AM --
	['thread.jspa?threadID=222689&start=1395#13928375'] = '20070513204314', -- Jan 25, 2006 05:41 PM --
	['thread.jspa?threadID=222689&start=1406#13935426'] = '20090707043906', -- Jan 26, 2006 03:20 PM --
	['thread.jspa?threadID=222689&start=1470#14050122'] = '20070821025430', -- Feb 09, 2006 01:18 PM --
	['thread.jspa?threadID=222689&start=1530#14157612'] = '20090703164648', -- Feb 21, 2006 01:44 PM --
	['thread.jspa?threadID=222689&start=1575#14229569'] = '20080210002619', -- Feb 28, 2006 06:28 PM --
	['thread.jspa?threadID=222689&start=1705#14323886'] = '20080213045726', -- Mar 13, 2006 10:06 AM --
	['thread.jspa?threadID=222689&start=1905#14621041'] = '20090129164252', -- Apr 20, 2006 11:42 AM -- -- also at message.jspa?messageID=14621041#14621041 --
	['thread.jspa?threadID=222689&start=2010#14756254'] = '20070302235108', -- May 08, 2006 10:05 AM --
	['thread.jspa?threadID=222689&start=2175#14968484'] = '20060614110353', -- Jun 06, 2006 12:53 PM --
	['thread.jspa?threadID=222689&start=2190#14975722'] = '20060614110411', -- Jun 07, 2006 09:52 AM --
	['thread.jspa?threadID=222689&start=3000#15740050'] = '20070912183346', -- Oct 05, 2006 09:45 AM --
	['thread.jspa?threadID=222689&start=3360#15903532'] = '20100106042229', -- Nov 08, 2006 01:55 PM --
	['thread.jspa?threadID=222689&start=3510#16008441'] = '20090221153529', -- Dec 04, 2006 10:22 AM --
	['thread.jspa?threadID=222689&start=3735#16142747'] = '20080303182729', -- Jan 08, 2007 09:14 AM --
	['thread.jspa?threadID=222689&start=4035#16240485'] = '20070302040630', -- Jan 30, 2007 11:04 AM --
	['thread.jspa?threadID=222689&start=4110#16279017'] = '20071224035620', -- Feb 08, 2007 12:19 PM --
	['thread.jspa?threadID=222689&start=4050#16245404'] = '20080307163615', -- Jan 31, 2007 11:32 AM --
	['thread.jspa?threadID=222689&start=4080#16269229'] = '20071018170207', -- Feb 06, 2007 09:00 AM --
	['thread.jspa?threadID=222689&start=4215#16327721'] = '20070305004659', -- Feb 23, 2007 10:11 AM --
	['thread.jspa?threadID=222689&start=4815#16660043'] = '20090216161410', -- Jun 04, 2007 01:12 PM --
	['thread.jspa?threadID=222689&start=5040#16718416'] = '20080317020622', -- Jun 19, 2007 09:28 PM --
	['thread.jspa?threadID=222689&start=5100#16739424'] = '20080328234612', -- Jun 25, 2007 07:52 PM --
	['thread.jspa?threadID=222689&start=612#12354630'] = '20070312104702', -- Aug 18, 2005 01:04 PM --
	['thread.jspa?threadID=222689&start=7260#17384444'] = '20081006174038', -- Oct 02, 2008 10:48 AM --
	['thread.jspa?threadID=222689&start=7262'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=222689&start=7262.html', -- XXX: Star Wars: Fate of the Jedi --
	['thread.jspa?threadID=222689&start=7590#17414023'] = '20090801093752',
	['thread.jspa?threadID=222689&start=8175#17541629'] = '20090218121042', -- Feb 12, 2009 12:58 PM --
	['thread.jspa?threadID=222689&start=840#12925824'] = '20080411235529', -- Oct 03, 2005 04:17 PM --
	['thread.jspa?threadID=222689&start=840#12926325'] = '20070326140128', -- Oct 03, 2005 05:15 PM --
	['thread.jspa?threadID=222689&start=9564#17707619'] = '20100525131608', -- Aug 18, 2009 02:45 PM --
	['thread.jspa?threadID=229415&start=60#11736018'] = '20090129174843', -- Jul 06, 2005 08:56 PM --
	['thread.jspa?threadID=237751&start=0'] = '20090118154454', -- Oct 05, 2005 08:11 PM --
	['thread.jspa?threadID=239051&start=15#13161930'] = '20070206221157', -- Oct 29, 2005 01:04 AM --
	['thread.jspa?threadID=239641&start=30'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=239641&start=30.html', -- Jan 28, 2006 08:58 PM --
	['thread.jspa?threadID=243200&start=360#15784824'] = '20070208050055', -- Oct 13, 2006 06:19 PM --
	['thread.jspa?threadID=243200&start=80&tstart=0#17626838'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=243200&start=80&tstart=0.html#17626838', -- May 09, 2009 02:02 PM  --
	['thread.jspa?threadID=243200&start=80&tstart=0#17953712'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3fthreadID=243200&tstart=0.html#17953712', -- Feb 10, 2011 09:46 PM --
	['thread.jspa?threadID=243200&tstart=0#13674476'] = '20060305222231', -- Dec 27, 2005 03:32 PM --
	['thread.jspa?threadID=245230&start=0#13983153'] = '20060223113709', -- Feb 01, 2006 12:56 PM --
	['thread.jspa?threadID=245230&start=1020#15199061'] = '20070821152823', -- Jul 07, 2006 03:59 PM --
	['thread.jspa?threadID=245230&start=1020#15199150'] = '20070821152823', -- Jul 07, 2006 04:12 PM --
	['thread.jspa?threadID=245230&start=615#14976871'] = '20080403054732', -- Jun 07, 2006 12:28 PM --
	['thread.jspa?threadID=245230&start=885#15151746'] = '20080403054739', -- Jun 30, 2006 11:20 AM --
	['thread.jspa?threadID=245631&start=0#14059351'] = '20071018074427', -- Feb 10, 2006 01:42 PM --
	['thread.jspa?threadID=246569&start=30#14235972'] = '20061129174511', -- Mar 01, 2006 02:18 PM --
	['thread.jspa?threadID=257947&start=0#16299262'] = '20091009061536', -- Feb 14, 2007 10:05 AM --
	['thread.jspa?threadID=266188#17649662'] = '20101019112857', -- Jun 05, 2009 02:06 PM --
	['thread.jspa?threadID=267192&tstart=0#17392805'] = '20090118153604', --  Oct 09, 2008 01:23 PM --
	['thread.jspa?threadID=270262&start=165#17701245'] = '20090815003405', -- Aug 11, 2009 11:04 AM --
	['thread.jspa?threadID=270737&start=0&tstart=0'] = '20100801040200', -- XXX: Paul S. Kemp --
	['thread.jspa?threadID=270737&start=01560#17882958'] = '20100519062209', -- Apr 23, 2010 04:43 PM --
	['thread.jspa?threadID=270737&start=1737#17895883'] = '20100527024414', -- May 18, 2010 09:08 AM --
	['thread.jspa?threadID=270737&start=645'] = '20100123220651', -- XXX: Imperial Commando 501st --
	['thread.jspa?threadID=278'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3FthreadID=278.html', -- XXX: Jaxxon --
	['thread.jspa?threadID=36969&start=29#927816'] = '20090311033042', -- Apr 20, 2002 08:45 AM --
	['thread.jspa?threadID=93010&start=1920#3701917'] = '20061125042116', -- Mar 24, 2003 03:44 PM --
	['thread.jspa?threadID=93010&start=1920#3704976'] = '20061125042116', -- Mar 25, 2003 09:36 AM --
	['thread.jspa?threadID=93010&start=4935#5509733'] = '20060213033225', -- Dec 19, 2003 03:02 PM --
	['thread.jspa?threadID=93010&start=5475#6053973'] = '20071015192703', -- Mar 05, 2004 11:09 AM --
	['thread.jspa?threadID=93010&start=8519'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3FthreadID=93010&start=8519.html', -- Oct 13, 2004 10:46 AM -- -- also at https://archive.vn/RzfSO --
	['thread.jspa?threadID=93010&start=9593&tstart=0#3076125'] = 'http://www.tm-travolta.net/archives/forums.sw.com/thread.jspa%3FthreadID=93010&start=9593&tstart=0.html#3076125', -- Nov 18, 2002 01:32 PM -- -- also at https://archive.is/mUY3B --,
  ["thread.jspa?threadID=152583&start=630"] = "20060306023704",
  ["thread.jspa?threadID=152583&start=630"] = "20060306023704",
  ["thread.jspa?threadID=222689&start=07440"] = "20090228174822",
  ["thread.jspa?threadID=169992&start=132"] = "https://web.archive.org/web/20070224114709/http://forums.starwars.com/thread.jspa?threadID=169992&start=120",
  ["message.jspa?messageID=14952461"] = "http://www.tm-travolta.net/archives/forums.sw.com/message.jspa%3fmessageID=14952461.html#14944330",
	["thread.jspa?threadID=173727&tstart=0"] = "20041105010945",
	["thread.jspa?threadid=173727&start=75"] = "20070919064154",
}

return p