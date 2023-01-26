export indent, LatexWriter, incindent, lastindent, nextindent, WriterSetting, LatexContext, ismathcontext, texcontext

@enum LatexContext begin
    MathBlock
    MathInline
    Text
end

ismathmode(m::LatexContext) = m == MathBlock || m == MathInline

struct WriterSetting
    indent_level::Int16
    convert_unicode::Bool
    context::LatexContext
    
    function WriterSetting(indent_level = -1, convert_unicode = true, context=Text)
        return new(Int16(indent_level), convert_unicode, context)
    end
end

mutable struct LatexWriter
    buffer::IO
    indent::Bool
    setting_stack::Vector{WriterSetting}
    should_fix_errors::Bool
    error_tracer::IO

    LatexWriter(buffer = IOBuffer(), should_fix_errors=true, error_tracer=stdout) = new(buffer, false, [WriterSetting(0, true)], should_fix_errors, error_tracer)
    Base.push!(io::LatexWriter, ws::WriterSetting) = push!(io.setting_stack, ws)
    Base.pop!(io::LatexWriter) = pop!(io.setting_stack)
    Base.last(io::LatexWriter)::WriterSetting = last(io.setting_stack)

    function Base.write(io::LatexWriter, s)
        io.indent && indent(io)
        print(io.buffer, s)
    end

    function Base.write(io::LatexWriter, s::AbstractString)
        io.indent && indent(io)
        str = string(s)
        str = last(io).convert_unicode ? Latexify.unicode2latex(str) : str
        did_find_error = false

        function error_function(modification, message, regex, fixer)
            message = io.should_fix_errors ? "$modification $message" : message
            if io.error_trace !== nothing
                for m in eachmatch(regex, str)
                    did_find_error = true
                    println(io.error_tracer, message, m.match)                
                end
                println(io.error_tracer, "In String:$str")
            end
            return io.should_fix_errors ? fixer(str) : str
        end

        if ismathmode(texcontext(io))
            str = error_function("Stripped", "Math Block:", MATH_MODE_REGEX, tex_strip_math)
        else
            #str = error_function("Inserted", "Neeed Math Block:", NEEDED_MATH_REGEX, tex_inline_required_math)
        end
        
        write(io.buffer, str)
    end

    function Base.print(io::LatexWriter, s...)
        for w in s
            write(io, w)
        end
    end

    function Base.println(io::LatexWriter, s...)
        print(io, s...)
        write(io, '\n')
        io.indent = true
    end
end

lastindent(io::LatexWriter) = last(io).indent_level
nextindent(io::LatexWriter) = lastindent(io) + 1
incindent(io::LatexWriter, context=Text) = push!(io, WriterSetting(nextindent(io), true, context))
texcontext(io::LatexWriter) = last(io).context

function indent(io::LatexWriter)
    lastindent(io) < 0 && throw(ArgumentError("Cannot have Negative Indent Level!"))
    for i in 1:lastindent(io)
        write(io.buffer, "\t")
    end
    io.indent = false
end