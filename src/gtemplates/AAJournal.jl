module AAJournalModule
    using ..LatexCore
    
    export AAJournal, author, abstract

    struct AAJournal <: LatexCore.AbstractTexBlock
        items::Vector{AbstractTexObject}

        function AAJournal(lf::TexFile, layout, other_options...)
            empty!(attributes(lf))
            push!(attributes(lf), TexCmd("documentclass", [layout, other_options...], ["aastex631"]))
            return new(AbstractTexObject[])
        end

        Base.first(ld::AAJournal) = "\\begin{document}"
        Base.last(ld::AAJournal) = "\\end{document}"
        Base.values(ld::AAJournal) = ld.items
    end

    function author(j::AAJournal, author, affiliations...)
        push!(j, TexCmd("author", author))
        for a in affiliations
            push!(j, TexCmd("affiliation", a))
        end
    end

    abstract(j::AAJournal, abstract) = push!(j, TexBeginEnd("abstract", abstract))
    LatexCore.title(j::AAJournal, title::String) = push!(j, TexCmd("title", title))
end



