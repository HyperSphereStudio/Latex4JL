export TexBlock
export TexList, TexBeginEnd, TexDelimBlock
export TexMathBlock, TexMultilineString, TexMultilineMathBlock, TexMultilineBlock, texified
export TexSection, TexSubSection, TexSection!, TexSubSection!, issection

struct TexBlock <: AbstractTexBlock
    first
    last
    elf
    name::Symbol
    items::Array{AbstractTexObject}
    setting::WriterSetting
    new_line::Bool

    TexBlock(items::Tuple; elf=nothing, name=nothing, setting = WriterSetting(), new_line = true) = TexBlock("", "", collect(items), elf=elf, name=name, setting=setting, new_line=new_line)
    TexBlock(items::Array; elf=nothing, name=nothing, setting = WriterSetting(), new_line = true) = TexBlock("", "", items, elf=elf, name=name, setting=setting, new_line=new_line)
    TexBlock(items...; elf=nothing, name=nothing, setting = WriterSetting(), new_line = true) = TexBlock("", "", collect(items), elf=elf, name=name, setting=setting, new_line=new_line)
    TexBlock(first, last, items=[]; elf=nothing, name=nothing, setting = WriterSetting(), new_line = true) = new(first, last, elf, name === nothing ? :DEF : name, convert(Array{AbstractTexObject}, items), setting, new_line)
    
    Base.values(lb::TexBlock) = lb.items
    Base.first(lb::TexBlock) = lb.first
    Base.last(lb::TexBlock) = lb.last
end

function getsetting(block::TexBlock, io::LatexWriter)
    indent_level = block.setting.indent_level == -1 ? lastindent(io) + (first(block) != "" ? 1 : 0) : block.setting.indent_level
    return WriterSetting(indent_level, block.setting.convert_unicode)
end


function tex_string_element(l::TexBlock, io::LatexWriter, i, idx)
    if l.elf === nothing
        tex_string(io, i)
    else
        l.elf(io, i, idx)
    end
    l.new_line && println(io)
end








TexMultilineString(s; name=nothing, setting = WriterSetting()) = s isa AbstractString ? TexBlock("", "", split(s, "\n"); name=name, setting=setting) : s
TexBeginEnd(cmd, items...; elf = nothing, name = nothing, setting = WriterSetting()) = TexBlock("\\begin{$cmd}", "\\end{$cmd}", collect(items); elf = elf, name=name, setting=setting)
TexSection(name, items...) = TexBlock("\\section{$name}", "", collect(items), name=:Section)
TexSubSection(name, items...) = TexBlock("\\subsection{$name}", "", collect(items), name=:SubSection)
TexSection!(name, items...) = TexBlock("\\section*{$name}", "", collect(items), name=:Section!)
TexSubSection!(name, items...) = TexBlock("\\subsection*{$name}", "", collect(items), name=:SubSection!)
TexMathBlock(items...) = TexBeginEnd("math", collect(items)...; name=:MathBlock, setting = WriterSetting(-1, true, MathBlock))


TexDelimBlock(delim, items...; first = "", last = "", name, new_line = true, setting = WriterSetting()) = TexBlock(first, last, collect(items);
    elf=function (io, i, idx)
        tex_string(io, i)
        (idx != length(items)) && tex_string(io, delim)
    end, name=name, new_line=new_line, setting=setting)

TexList(items...; numbered=false) = TexBeginEnd(
    numbered ? "enumerate" : "itemize",
    items...;
    elf = function (io, i, idx)
            tex_string(io, "\\item{")
            tex_string(io, i)
            write(io, "}")
    end, name = numbered ? :NumberedList : :BulletList)

TexMultilineBlock(items::Array) = TexDelimBlock(LATEX_NEW_LINE, items...; name=:MultiLineBlock)
TexMultilineBlock(items...) = TexMultilineBlock(collect(items))
TexMultilineBlock(items::Tuple) = TexMultilineBlock(collect(items))
TexMultilineMathBlock(items...) = TexDelimBlock(LATEX_NEW_LINE, items...; first="\\begin{math}", last="\\end{math}", name=:MultiLineMathBlock, setting = WriterSetting(-1, true, MathBlock))

texified(s) = TexMultilineString(latexify(s); name=:LatexifiedBlock)


issection(v) = false
issection(tb::TexBlock) = tb.name == :Section || tb.name == :SubSection || tb.name == :Section! || tb.name == :SubSection!

