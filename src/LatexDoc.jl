export TexDoc, title

struct TexDoc <: AbstractTexBlock
    items::Vector{AbstractTexObject}

    function TexDoc(lf::TexFile, items; author="", title="")
        attribs = attributes(lf)

        push!(attribs, TexCmd("title" => title))
        push!(attribs, TexCmd("author" => author))
        date = string(Months[Dates.month(Dates.now())]) * " $(Dates.year(Dates.now()))"
        push!(attribs, TexCmd("date" => date))

        ld = TexDoc(items)
        push!(ld, TexCmd("maketitle"))
        return ld
    end

    TexDoc(items) = new(items)

    Base.first(ld::TexDoc) = "\\begin{document}"
    Base.last(ld::TexDoc) = "\\end{document}"
    Base.values(ld::TexDoc) = ld.items
end

getsetting(d::TexDoc, io::LatexWriter) = WriterSetting(nextindent(io))


title(j::TexDoc, title::String) = push!(j, TexCmd("title", title))
