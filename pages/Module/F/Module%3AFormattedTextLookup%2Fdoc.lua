'''Module:FormattedTextLookup''' is a Lua module that serves as a centralized repository of the formatted names for various commonly-linked values, such as card sets. It serves to eliminate the need to manually define the custom italicization in templates. Currently there are two dataset subpages: [[Module:FormattedTextLookup/Cards]] and [[Module:FormattedTextLookup/RefMagazine]], which store the data for card citation templates and reference magazine templates respectively.

To add text for additional links, simply add a new entry into the dataset with the <nowiki>["set name"] = "formatted name",</nowiki> format; if it's a new template, just add a new top-level entry with the template name as the key.

The following parameters are passed into the #invoke function within a citation template's code:
*<code>type</code> &mdash; determines what subpage to use a lookup table. Card citation templates use [[Module:FormattedTextLookup/Cards]], so this parameter is given as "Cards" in the template code. If no value is given, it defaults to "data".
*<code>template</code> &mdash; the name of the template, without the Template: prefix
*<code>target</code> &mdash; the target article title, which is used as the key for lookup in the dataset.
*<code>issue</code> &mdash; an optional parameter for use when a department is repeated in multiple issues of a magazine; if this is present, the lookup key in the dataset becomes "<issue>-<target>".
*<code>text</code> &mdash; the manual text field previously used by the calling template; this is used to add manual usages to a maintenance category.
*<code>textOnly</code> &mdash; if true, will return just the formatted text present in the lookup table, rather than a pipelink. 

The following example is how {{Tl|BuildFalconCite}} invokes this module and its dataset:
<pre>
{{#invoke:FormattedTextLookup|main|type=RefMagazine|template=BuildFalconCite
  |textOnly=true
  |target={{{2}}}
  |issue={{{1}}}
  |text={{#if:{{{3|}}}|{{{2}}}: {{{3}}}|}}
}}
</pre>