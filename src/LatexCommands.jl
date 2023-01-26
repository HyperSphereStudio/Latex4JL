export TexCmd
export TexGraphicS, TexGraphicWH
export TexIndent, TexSum, TexFrac

struct TexCmd <: AbstractTexCommand
    name
    attributes
    values

    TexCmd(name, attributes, values) = new(name, attributes, values)
    TexCmd(name, values...) = new(name, [], collect(values))
    TexCmd(name, values::Array) = new(name, [], values)
    TexCmd(p::Pair) = TexCmd(p[1], [], [p[2]])
end

Base.values(lp::TexCmd) = lp.values
Base.nameof(lp::TexCmd) = lp.name
attributes(lp::TexCmd) = lp.attributes


includetex(lb::AbstractTexBlock, tex::AbstractString) = push!(lb, TexCmd("input", abspath(tex)))

TexGraphicS(image_name::String; scale = 1, angle=0) = TexCmd("includegraphics", ["scale" => scale, "angle" => angle], [texpath(image_name)])
TexGraphicWH(image_name::String; width = 500, height = 500, angle=0) = TexCmd("includegraphics", ["width" => width, "height" => height, "angle" => angle], [texpath(image_name)])

TexFrac(num, denom) = TexCmd("frac", num, denom)
TexSum(expr, start, finish) = TexMathBlock("\\sum_{$start}^{$finish} $expr")
TexIndent(v::AbstractTexObject) = TexCmd("indent", v)
