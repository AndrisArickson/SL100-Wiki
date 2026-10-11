This module is a general-purpose base citation template builder that serves as the foundation for most of our citation templates. It is highly customizable, taking in a variety of parameters (most of which are optional); as this is a module used to '''build''' other templates, the invocation of this module should ''accept'' the result of a parameter in the template itself, i.e. <code>|parent={{{book|}}}</code>. When in doubt, it's totally okay to just copy an existing template and tweak it from there to serve your uses.

They fall into three categories:
*Parent parameters:
**The following parameters are used to build a template that cites a single piece of media:
***<code>parent</code> &mdash; the primary parameter for a single piece of parent media; this will be used to generate a single link to the media.
***<code>ptext</code> &mdash; formatting text for the <code>parent</code> value.
**The following parameters are used to build a template for a media series, like magazines.
***<code>series</code> &mdash; an alternate way to define the parent media, used primarily for magazine citation templates; this defines the series name that will be concatenated (joined together with a space) with the <code>issue</code> parameter value to create the link to the individual magazine issue. Please note, it is the part of the ''issue title'', and not the magazine series itself&mdash;so {{Tl|EncyclopediaCite}} passes in "Star Wars Encyclopedia" to this parameter, rather than [[Star Wars Encyclopedia (series)]]
***<code>stext</code> &mdash; Custom formatting for the series text; used only when it is partially italicized.
***<code>issue</code> &mdash; the issue number field, used primarily for magazines. Will be concatenated with the <code>series</code> parameter.
***<code>issue1</code> and <code>issue2</code> &mdash; used to support the use of <code>issue1</code> and <code>issue2</code> parameters in the citation template, for child stories/articles that span multiple issues.
***For series with more complex titles, like changing names after a certain issue or a parenthetical descriptor, the module also accepts the following parameters:
****<code>noitalics</code> &mdash; suppresses automatic italicization of the parent/series value.
****<code>series2</code> &mdash; a secondary series name to be used for issues under the threshold. (ex: [[Template:InsiderCite]])
****<code>stext2</code> &mdash; formatting text for <code>series2</code>
****<code>threshold</code> &mdash; a threshold value for issue # under which the <code>series2</code>, <code>suffix2</code> and <code>image2</code> parameters will be used. This is for cases like ''[[Star Wars Insider]]'', which was published under a different name for the first 22 issues. (ex: [[Template:InsiderCite]])
****<code>suffix</code> &mdash; used to add a suffix to the issue name, like "(2013)" for [[The Official Star Wars Fact File Part 1 (2013)|''The Official Star Wars Fact File'' Part 1 (2013)]] (ex: [[Template:FactFile2013]])
****<code>suffix2</code> &mdash; like <code>suffix</code> but for the issues under the threshold (ex: [[Template:FactFile2014]])
****<code>showsuffix</code> &mdash; causes the suffix to be shown in the actual link's text, like for the 2013 Fact Files; this defaults to false, for cases like [[Star Wars: Darth Vader 1 (magazine)]]. (ex: [[Template:FactFile2013]])
*Child parameters:
**<code>child</code> &mdash; the child media that was published in or part of the parent media.
**<code>ctext</code> &mdash; formatting text for the child media.
**<code>noquotes</code> &mdash; disables the enclosing quotation marks around the child media; this is done automatically for child media that starts with "Untitled".
**<code>nolink</code> &mdash; allows the template to list the child media without a link to a Wookieepedia article.
*And the rest:
**<code>image</code> &mdash; the image to be included at the start of the citation template.
**<code>invert</code> &mdash; applies the "invert-image" class to the image.
**<code>mode</code> &mdash; enables most of the below parameters in common modes, such as "magazine", "tv" and "ref".
**<code>nospaces</code> &mdash; removes the spacing between the child, parent and dash
**<code>ndash</code> &mdash; changes the separating dash from an mdash to an ndash
**<code>small</code> &mdash; causes the child value to be displayed using {{Tl|C}} instead of with a dash separator; this is used for reference magazines.
**<code>parentfirst</code> &mdash; causes the parent media to be listed first, as opposed to the default of "child - parent". 
**<code>audiobook</code> &mdash; enables the template to support the automatic use of the {{Tl|Ab}} template.
**<code>reprint</code> &mdash; enables the template to support the automatic use of the {{Tl|Reprint}} template.
**<code>abbr</code> &mdash; text to strip off of the names of reprinted material, like removing ''Star Wars Insider'' from the reprints of Insider articles.
**<code>reprintParent</code> &mdash; edge case flag for {{Tl|WEGCite}}, which uses the book name as the reprint lookup key rather than the child story.

Templates that use BaseCitation have the following maintenance categories:
*[[:Category:BaseCitation usages with invalid child parameters]] &mdash; tracks usages with missing/invalid child (episode/story/etc) parameter values.
*[[:Category:BaseCitation usages with invalid parent parameters]] &mdash; tracks templates that do not define the parent or series parameters.
*[[:Category:BaseCitation usages with invalid issue parameters]] &mdash; tracks usages of a citation template where only the <code>issue1</code> parameter has been provided without a corresponding <code>issue2</code> parameter.

An example implementation for {{Tl|GalaxyCite}}:
<pre>
{{#invoke:BaseCitation|main|template=GalaxyCite
|mode=magazine
|image=[[File:GalaxyCite.png|baseline|link=Star Wars Galaxy Magazine]]
|series=Star Wars Galaxy Magazine
|issue={{{1}}}
|issue1={{{issue1|}}}
|issue2={{{issue2|}}}
|child={{#if:{{{issue1|}}}|{{{1|}}}|{{{2|}}}}}
|ctext={{#if:{{{issue1|}}}|{{{2|}}}|{{{3|}}}}}
|noquotes={{{noquotes|}}}
}}</pre>