This is a Lua-based template builder for internet citation templates. It accepts the standard archive parameters directly from the individual template usages, and does not need to be defined in the template code itself. The following parameters ''do'' need to be defined in the template itself:
{| class="wikitable" ! Parameter ! Description
|-
| {{Para|template}} || The name of the template; used to look up the corresponding ArchiveAccess datastore.
|-
| {{Para|image}} || The image or icon for the website to display in the template.
|-
| {{Para|site_text}} || The descriptive text for the website; will be displayed after the individual webpage with ' on <site text>'. The module will also read in the <code>lang</code> and <code>domain</code> parameters and will adjust the site text accordingly with the parsed language name.
|-
| {{Para|base_url}} || The base URL of the webpage, including any subdomain or domain parameters, but without the target URL. This will be combined with the target_url value to create the full URL. In most cases, you can provide just this and not redefine the the URL path (the target_url value). 
|-
| {{Para|target_url}} || The ArchiveAccess lookup part of the URL; in most cases, this is just the path part of the URL, aka the {{Para|url}} parameter.
|-
| {{Para|use_lua_subpage|1}}<br />{{Para|no_archive|1}} || Enables usage of the template's ArchiveAccess subpage, or marks the template as a template without one. You must provide one of these.
|-
|colspan="2"|NOTE: for edge cases where you need to provide an entirely different URL, the module will automatically read in the full_url parameter from a template call and use that instead.
|}

Social media sites, art galleries and blogs have an additional set of parameters:
{| class="wikitable" ! Parameter ! Description
|-
| {{Para|social_media|1}}<br />{{Para|blog|1}} || Designates the template as a social media citation template, which tweaks certain maintenance categories, enables the below parameters, and adjusts the overall text layout of the template. The <code>blog</code> flag is for sites such as {{Tl|Blogspot}} and {{Tl|Tumblr}}, which gives users unique subdomains and site names.
|-
| {{Para|is_post|<nowiki>{{{url|}}}</nowiki>}} || Trigger parameter so that the template knows whether the citation is a link to an individual post or a link to the user's profile; in most cases, you should simply just pass the URL parameter into it.
|-
| {{Para|no_profile}} || Trigger parameter that disables the profile link for cases where one cannot be generated. Should usually just pass in the value from the template call.
|-
| {{Para|username}} || The username or profile for the given user on the website, or the unique subdomain if it's a blog. This is used to construct the link to the user's profile.
|-
| {{Para|usertext}} || The display-text counterpart to the username parameter, this is for the unique name of the blog that you're citing.
|-
| {{Para|post_type}} || The default text used for the link to the specific post if no value is given in the {{Para|text}} parameter. 
|}

The following optional parameters can be defined within the template code to enable certain functionality.
{| class="wikitable" ! Parameter ! Description
|-
| {{Para|int}} || Link to a Wookieepedia article about the webpage; must be explicitly defined in the individual template code to be supported.
|-
| {{Para|text}} || The display text for the URL; you only need to define this if your template is using a parameter name ''other'' than text for this value.
|-
| {{Para|author}} || Author of the webpage; only needs to be explicitly defined if your template uses a different parameter name. Alternatively, {{Para|author_text}} can be used to define custom text instead of the standard "by <author>".
|-
| {{Para|separator}} || Defines the text used between the webpage link and the site text; defaults to "on"
|-
| {{Para|series}} || Appends a series name to the start of the citation, before the webpage link. Typically reserved for YouTube series' templates, such as {{Tl|ThisWeek}}.
|-
| {{Para|site_name}}<br />{{Para|site_base_url}}<br />{{Para|site_template}} || Used to enable custom "Reposted on <Other Site>" functionality for your template, under the {{Para|site_url}} parameter. Requires the name of the website, its base URL, and the name of the citation template used for that site (which is used to look up the backup link)
|-
|colspan=2| NOTE: the date, time, and quote parameters are supported automatically by every template build with this module, and do not need to be manually defined in the template's code. 
|}

And to round it out, there are a number of flags that can be passed in to the Lua module:
{| class="wikitable" ! Parameter ! Description
|-
| {{Para|site_first}} || Moves the site description to in front of the webpage link, and forgoes the separator.
|-
| {{Para|defunct_site|1}} || If populated, will cause all usages of the template to automatically be treated as nolive. Used for sites that are completely offline, such as {{Tl|SWArchive}} and {{Tl|Wizards}}.
|-
| {{Para|exclude_at_symbol|1}} || Kind of self-explanatory; drops the @ symbol that's automatically added to the start of the profile/username in social media templates.
|-
| {{Para|domain_not_allowed|1}} || If populated, will flag usages of the <code>domain</code> parameter with a maintenance category; used for sites with only a single domain.
|-
| {{Para|allow_unnamed|1}} || Disables the automatic flagging of unnamed parameter usages. Should only be set for the occasional exception case.
|-
| {{Para|backup_optional|1}} || Suppresses the warning text and maintenance categories when a backup link cannot be generated for the given URL. Restricted to edge cases; ask in Discord before using this.
|-
| {{Para|optional|1}} || An advanced  version of backup_optional that drops out the archival text entirely if there is no backup URL. Reserved for rare cases, primarily for crowd-sourced sites such as {{Tl|MobyGames}}.
|-
| {{Para|is_profile}} || Trigger parameter that adjusts the ArchiveAccess missing-backup maintenance category; only needed for non-social media sites that still have dedicated user pages, like {{Tl|YouTube}} and {{Tl|LinkedIn}}. Should be populated by a parameter or parser function, like how {{Tl|YouTube}} sets it to true if there's no video parameter.
|}