export TexInlineMath, TexString, WrappedTexObject

struct TexString <: AbstractTexObject 
    s::AbstractString 
    TexString(s) = new(s)
    Base.convert(::Type{AbstractTexObject}, x::AbstractString) = TexString(x)
end
tex_string(io::LatexWriter, ls::TexString) = tex_string(io, ls.s)

struct WrappedTexObject <: AbstractTexObject 
    v
    WrappedTexObject(v) = new(v)
    WrappedTexObject(v::AbstractTexObject) = v
    WrappedTexObject(v::AbstractString) = TexString(v)
end
tex_string(io::LatexWriter, ls::WrappedTexObject) = tex_string(io, ls.v)

struct TexInlineMath <: AbstractTexObject 
    v
    TexInlineMath(v) = new(v)
end
tex_string(io::LatexWriter, ls::TexInlineMath) = (write(io, '\$'); tex_string(io, ls.v); write(io, '\$'))