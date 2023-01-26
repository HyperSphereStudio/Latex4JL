export TexInterop, TexInteropSett, TexInteropMultilineBlock, TexInteropMultilineMathBlock, TexInteropBlock
export NumberInterop, NumberProc, BoolInterop

function TexInterop(s::String, values, value_processor::Function = (x, idx) -> x; first = "", last = "", new_line = false)
    items = []
    last_offset = 1
    for m in eachmatch(r"\\(\d+)", s)
        push!(items, s[last_offset:(m.offset - 1)])
        idx = parse(Int, m[1])
        push!(items, WrappedTexObject(value_processor(values[idx], idx)))
        last_offset = m.offset + length(m.match)
    end
    push!(items, s[last_offset:end])
    return TexDelimBlock("", items...; first=first, last=last, name=:TexInterop, new_line=new_line)
end

struct TexInteropSett
    s::String
    value_processor::Function
    first
    last
    new_line::Bool

    TexInteropSett(s::String, value_processor = (x, idx) -> x; first = "", last = "", new_line = false) = new(s, value_processor, first, last, new_line)
    (lis::TexInteropSett)(values) = TexInterop(lis.s, values, lis.value_processor; first=lis.first, last=lis.last, new_line=lis.new_line)
end

TexInterop(s::String, value_processor::Function = (x, idx) -> x; first = "", last = "", new_line = true) = TexInteropSett(s, value_processor; first=first, last=last, new_line=new_line)
TexInteropBlock(values, settings::TexInteropSett...; delim = "", first = "", last = "", new_line = true) = TexDelimBlock(delim, [s(values) for s in settings]..., first=first, last=last, name=:LatexInteropBlock, new_line=new_line)
TexInteropMultilineBlock(values, settings::TexInteropSett...) = TexMultilineBlock([s(values) for s in settings]...)
TexInteropMultilineMathBlock(values, settings::TexInteropSett...) = TexMultilineMathBlock([s(values) for s in settings]...)

function NumberProc(digits=3)
    return function (x, idx)
        if digits > 0
            return round(x, digits=digits)
        end
        return x
    end
end

function NumberInterop(name, units, idx::Integer; digits=3, first = "", last = "")
    interop = ""
    interop *= (name !== nothing ? name * " = " : "")
    interop *= "\\$idx"
    interop *= (units !== nothing ? " " * units : "")
    return TexInteropSett(interop, NumberProc(digits), first=first, last=last)
end

BoolInterop(idx, invert=false; first = "", last = "") = TexInteropSett("\\$idx", 
    function (x, idx)
        v = (x === nothing || x === missing) ? false : convert(Bool, x)
        return invert ? !v : v
    end, first=first, last=last)