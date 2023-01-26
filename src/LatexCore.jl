module LatexCore
    export tex_string, AbstractTexObject, attributes, tex_inline_math_string, tex_string_element, tex_strip_math
    export settexparagraphspace, texpath, includetex
    export getsetting

    using Latexify

    texpath(path) = replace(abspath(path), "\\" => "/")

    const PROJECT_ROOT = pkgdir(LatexCore)
    const BUILD_DIR = joinpath(PROJECT_ROOT, "build")
    const LATEX_NEW_LINE = " \\\\"
    const LOCAL_LIBS = [splitext(basename(p))[1] for p in readdir(joinpath(PROJECT_ROOT, "lib"))]
    const Months = [:January, :February, :March, :April, :May, :June, :July, :August, :September, :October, :November, :December]
    const LATEXCORE_TEX_PATH = texpath(joinpath(PROJECT_ROOT, "lib", "LatexCore"))
    const MATH_MODE_REGEX = r"(\\\$|(\\\[])|(\\begin\{math\}))([^\s]+)(\\\$|(\\\])|(\\end\{math\}))"

    abstract type AbstractTexObject end

    #Required Methods:values
    abstract type IterableAbstractTexObject <: AbstractTexObject end

    #Required Methods:nameof, attributes, values, tex_string
    abstract type AbstractTexCommand <: IterableAbstractTexObject end

    #Required Methods:values, first, last, tex_string_element, getsetting
    abstract type AbstractTexBlock <: IterableAbstractTexObject end

    include("WritingUtils.jl")
    include("LatexWriter.jl")
    include("LatexObjects.jl")
    include("LatexCommands.jl")
    include("LatexBlock.jl")
    include("JuliaTex.jl")
    include("LatexFile.jl")
    include("LatexDoc.jl")
    include("LatexTemplate.jl")
    include("TexTemplateFeatures.jl")
    include("LatexInterop.jl")
    include("TexGenTemplate.jl")
    
    Base.length(lb::IterableAbstractTexObject) = length(values(lb))
    Base.getindex(lb::IterableAbstractTexObject, i::Integer) = values(lb)[i]
    Base.setindex!(lb::IterableAbstractTexObject, item, i::Integer) = values(lb)[i] = item
    Base.push!(lb::IterableAbstractTexObject, item) = push!(values(lb), item)
    Base.insert!(lb::IterableAbstractTexObject, idx, item) = insert!(values(lb), idx, item)
    Base.append!(lb::IterableAbstractTexObject, item) = append!(values(lb), item)
    Base.deleteat!(lb::IterableAbstractTexObject, r) = deleteat!(values(lb), r)
    Base.iterate(lb::IterableAbstractTexObject) = iterate(values(lb))
    Base.iterate(lb::IterableAbstractTexObject, s) = iterate(values(lb), s)

    Base.:*(lb::AbstractTexBlock, lb2::Union{AbstractTexBlock, AbstractString, Number}) = (push!(lb, lb2); return lb)
    Base.:*(lb2::Union{AbstractString, Number}, lb::AbstractTexBlock) = (insert!(lb, 1, lb2); return lb)

    tex_inline_math_string(s, inline=true) = inline ? "\$$s\$" : s
    tex_string(io::LatexWriter, l::Union{Vector, Tuple, Number}) = print(io, l)
    tex_string(io::LatexWriter, l::Vector{T}) where T <: AbstractTexObject = print(io, l...)
    tex_string(io::LatexWriter, l::NTuple{N, T}) where {N, T <: AbstractTexObject} = print(io, l...)
    
    #Remove all inline math
    tex_string(io::LatexWriter, e::Expr, should_strip_math=true) = tex_string(io, should_strip_math ? tex_strip_math(latexify(e)) : latexify(e))

    function tex_string(o)
        io = IOBuffer()
        tex_string(LatexWriter(io), o)
        return String(take!(io))
    end

    tex_string_element(l::AbstractTexBlock, io::LatexWriter, i, idx) = (tex_string(io, i); println(io))

    function tex_string(io::LatexWriter, l::AbstractTexBlock)  
        if first(l) != ""
            tex_string(io, first(l))
            println(io)
        end
        push!(io, getsetting(l, io))
        
        for i in 1:length(l)
            tex_string_element(l, io, l[i], i)
        end

        pop!(io) 
        last(l) == "" || tex_string(io, last(l))
    end

    tex_string(io::LatexWriter, s::AbstractString) = write(io, s)

    function tex_string(io::LatexWriter, lc::AbstractTexCommand)
        print(io, '\\', nameof(lc))

        attribs = attributes(lc)

        if length(attribs) != 0
            write(io, '[')
            for i in 1:length(attribs)
                attrib = attribs[i]
                if i != 1
                    write(io, ", ")
                end
                if attrib isa Pair
                    print(io, attrib[1], "={", string(attrib[2]), '}')
                else
                    write(io, attrib)
                end
            end
            write(io, ']')
        end

        for v in values(lc)
            write(io, '{')
            tex_string(io, v)
            write(io, '}')
        end

        return false
    end

    settexparagraphspace(lf::AbstractTexBlock, p) = push!(lf, TexCmd("setlength", ["\\parindent", p]))
    tex_strip_math(str) = replace(str, MATH_MODE_REGEX => s"\2")   

    include("precompile.jl")
end