using LatexCore
using LatexCore.AAJournalModule

lf = TexFile(joinpath(@__DIR__, "AA"))


#= The default is a single spaced, 10 point font, single spaced article.
   There are 5 other style options available via an optional argument. They
 can be invoked like this:

 \documentclass[arguments]{aastex631}
 
 where the layout options are:

  twocolumn   : two text columns, 10 point font, single spaced article.
                This is the most compact and represent the final published
                derived PDF copy of the accepted manuscript from the publisher
  manuscript  : one text column, 12 point font, double spaced article.
  preprint    : one text column, 12 point font, single spaced article.  
  preprint2   : two text columns, 12 point font, single spaced article.
  modern      : a stylish, single text column, 12 point font, article with
 		  wider left and right margins. This uses the Daniel
 		  Foreman-Mackey and David Hogg design.
  RNAAS       : Supresses an abstract. Originally for RNAAS manuscripts 
                but now that abstracts are required this is obsolete for
                AAS Journals. Authors might need it for other reasons. DO NOT
                use \begin{abstract} and \end{abstract} with this style.

 Note that you can submit to the AAS Journals in any of these 6 styles.

 There are other optional arguments one can invoke to allow other stylistic
 actions. The available options are:

   astrosymb    : Loads Astrosymb font and define \astrocommands. 
   tighten      : Makes baselineskip slightly smaller, only works with 
                  the twocolumn substyle.
   times        : uses times font instead of the default
   linenumbers  : turn on lineno package.
   trackchanges : required to see the revision mark up and print its output
   longauthor   : Do not use the more compressed footnote style (default) for 
                  the author/collaboration/affiliations. Instead print all
                  affiliation information after each name. Creates a much 
                  longer author list but may be desirable for short 
                  author papers.
 twocolappendix : make 2 column appendix.
   anonymous    : Do not show the authors, affiliations and acknowledgments 
                  for dual anonymous review.
=#
journal = AAJournal(lf, "twocolumn")
push!(lf, journal)


title(journal, "My Title")
author(journal, "Johnathan Bizzano")
abstract(journal, "My Abstract")


LatexCore.tex_string(LatexWriter(stdout), lf)


