'''Module:HideParanthetical''' is a (relatively) simple Lua module that is used in many templates to automatically hide parenthetical descriptors in pagenames when creating links to them. In most cases, this renders formatting-text parameters of other templates unnecessary, like needing to do {{Tlp|TCW|Orders (episode)|Orders}} instead of just {{Tlp|TCW|Orders (episode)}}.

To use this module, simply use the {{Tl|HideParanthetical}} template:
*<nowiki>{{HideParanthetical|{{{1|}}|{{{2|}}}}}</nowiki>