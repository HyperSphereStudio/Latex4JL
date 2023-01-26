export TexTemplate, check, CustomizableObject 

#The What The Fuck Regex
#So like my goal with this is to parse stuff that starts and ends with a jl_something{MultilineStuffInHere}jl_something.
#You cant have it contain anything thats {jl_somethingelse} though....
#To break it down....
#jl_something{
#   No string inside has suffex jlstuff{
#   for every line until }jl_something
const JL_REGEX = r"jl(.+)\{(((?!jl(?:[a-zA-Z])*\{)(?:.|\n))*)\}jl\1"
const VALID_JL_CMDS = ["eval", "runtime", "ignore"]

struct TexTemplate <: AbstractTexBlock
    lf::TexFile
    replaceable_items::Dict{Symbol, AbstractTexObject}
    replaceable_values::Dict{Symbol, Array}
    template_items::Array{AbstractTexObject}
    template_file::String

    function TexTemplate(lf::TexFile, template_file::String)
        replaceable_items = Dict{Symbol, AbstractTexObject}()
        replaceable_values = Dict{Symbol, Array}()
        template_items = AbstractTexObject[]

        lt = new(lf, replaceable_items, replaceable_values, template_items, template_file)

        last_offset = 1
        s = read(joinpath(PROJECT_ROOT, "templates", template_file, "$template_file.jtex"), String)

        for jl in eachmatch(JL_REGEX, s)
            push!(template_items, s[last_offset:(jl.offset - 1)])
            (!(jl[1] in VALID_JL_CMDS)) && throw(error("Unknown Command:\n$jl"))            
            (jl[1] == "ignore") && continue
            
            try
                payload = Meta.parse(jl[2])

                if jl[1] == "eval"
                    inner = eval(payload)
                    if inner isa CustomizableObject
                        if !inner.isHidden
                            replaceable_items[nameof(inner)] = inner
                            inner.isReplacable && (replaceable_values[nameof(inner)] = [])             
                        end
                        inner.templ[] = lt
                        inner.on_parse_f(inner)
                    end
                    push!(template_items, inner)
                elseif jl[1] == "runtime"
                    push!(template_items, JLEval(payload))
                end
            catch e
                println("Error while processing:$jl")
                throw(e)
            end

            last_offset = jl.offset + length(jl.match)
        end
        push!(template_items, s[last_offset:end])

        #Strip the document class from TexFile
        deleteat!(lf.attributes, 1)   

        return lt 
    end

    Base.first(lt::TexTemplate) = ""
    Base.last(lt::TexTemplate) = ""
    Base.keys(lt::TexTemplate) = keys(lt.replaceable_values)
    Base.values(lt::TexTemplate) = lt.template_items

    function Base.print(io::IO, lt::TexTemplate)
        print(io, "Template:$(lt.template_file)\nItems:\n\t")
        print(io, join(values(lt.replaceable_items), "\n\t"))
    end 

    Base.getindex(lt::TexTemplate, s::Symbol) = lt.replaceable_items[s]
end  

getsetting(d::TexTemplate, io::LatexWriter) = WriterSetting(nextindent(io))
getvalue(lt::TexTemplate, s::Symbol) = lt.replaceable_values[s]

function check(lt::TexTemplate, stopOnError::Bool=true)
    cnt = 1
    for i in lt.template_items
        i isa CustomizableObject || continue

        k = check(i)
        if k !== nothing
            if stopOnError
                throw(error(k))
            else
                println("Error:$cnt")
                println(k)
                println()
            end
            cnt += 1
        end
    end
    println("Error Count:$(cnt - 1)")
end

struct CustomizableObject <: IterableAbstractTexObject
    name::Symbol
    print_f::Function
    check_proccessor::Function
    tex_f::Function
    callable_f::Function
    on_parse_f::Function
    isReplacable::Bool
    isHidden::Bool
    templ::Ref{TexTemplate}

    CustomizableObject(name, print_f, check_f, tex_f, callable_f, on_parse_f, isReplacable, isHidden) = 
        new(Symbol(name), print_f, check_f, tex_f, something(callable_f, push!), something(on_parse_f, (x) -> ()), isReplacable, isHidden, Ref{TexTemplate}())
    
    Base.values(co::CustomizableObject) = getvalue(co.templ[], co.name)
    Base.setindex!(co::CustomizableObject, v) = push!(values(co), v)
    (co::CustomizableObject)(values...) = co.callable_f(co, values...)
end

check(co::CustomizableObject) = co.check_proccessor(co)
tex_string(io::LatexWriter, co::CustomizableObject) = (try; co.tex_f(io, co); catch e; println("Error getting tex_string of $co"); throw(e); end)
Base.print(io::IO, co::CustomizableObject) = co.print_f(io)
Base.nameof(co::CustomizableObject) = co.name

JLEval(e::Expr) = CustomizableObject(:def, io -> print(io, "JLEVAL($e)"), co -> (eval(e); return nothing), (io, co) -> (eval(e); return nothing), nothing, nothing, false, true)