<includeonly>{| class="article-table" style="width:100%;"
|- style="font-size:18px;"
! Module documentation follows
|-
| ''Note: the module above may sometimes be partially or fully invisible.''
|-
| Visit [[{{FULLPAGENAMEE}}/doc]] to edit this documentation.
|}
[[Category:Modules]]</includeonly>
==Usage instructions==
<code><nowiki>{{#invoke:Votes|main|title={{{1|}}}|archive={{{2|}}}|type=|count=|redux=}}</nowiki></code>

===Required parameters===
*{{Para|title}} Use to capture the full page name (including the namespace where needed) of the nomination page. The module will then automatically identify the page's '''Support''' section and count individual votes. Templates can use <code><nowiki>{{{1|}}}</nowiki></code> to capture the value.
*{{Para|archive}} Used to identify an archived nomination page. Templates can use <code><nowiki>{{{2|}}}</nowiki></code> to capture the value.
*{{Para|type}} Use one of the following: '''FAN''', '''GAN''', or '''CAN'''.
*{{Para|count}} Use one of the following: '''Inq''', '''AC''', and '''EC'''.

===Optional parameters===
*{{Para|redux}} Used to identify a redux nomination page. Templates can use <code><nowiki>|redux=1</nowiki></code> to capture the value.

This module is used in the following templates:
*{{Tl|FANvotes}}
*{{Tl|GANvotes}}
*{{Tl|CANvotes}}
*{{Tl|FANvotesRedux}}
*{{Tl|GANvotesRedux}}
*{{Tl|CANvotesRedux}}
<noinclude>[[Category:Module documentation]]</noinclude>