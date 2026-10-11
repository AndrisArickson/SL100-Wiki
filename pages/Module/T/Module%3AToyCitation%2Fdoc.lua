A general-use Lua module used to construct toy citation templates as a more specialized version of [[Module:BaseCitation]]. It has built-in support for the [[Module:ArchiveAccess]] system, and will read the parameters from the template's usages (archivedate, archiveurl, etc.) so no need to pass those into the module directly.

It accepts the following parameters, most of which should be given the parameter values from the template call itself.
*<code>template</code> &mdash; name of the template itself, without the Template: prefix
*<code>image</code> &mdash; image to be used in the template
*<code>set</code> &mdash; the name of the set
*<code>stext</code> &mdash; formatted name of the set, only needed when it's partially italicized
*<code>noitalics</code> &mdash; suppresses the default italicization of the set name
*<code>pack</code> &mdash; the name of the toy or pack
*<code>packtype</code> &mdash; modifies the "Pack: " prefix applied in front of the pack name
*<code>nopacktype</code> &mdash; suppresses the default "Pack: " prefix
*<code>itemlink</code> and <code>itext</code> &mdash; an alternative to the pack parameters; these generate links to Wookieepedia articles instead of links to other websites.
*<code>baseUrl</code> &mdash; if we rely on a single site primarily to cite the toy line, add that site's domain here; the value of the <code>link</code> parameter will be appended to this value to create a full URL
*<code>link</code> &mdash; the path (everything after the .com/) of the URL on the primary site.
*<code>url</code> &mdash; an alternative URL that is not on the standard baseURL; some templates call this <code>altlink</code>
*<code>skipArchive</code> &mdash; suppresses the built-in implementation of [[Module:ArchiveAccess]]