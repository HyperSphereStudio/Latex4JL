export SingleListReplace, ListReplace, MultiListReplace, TexReplaceListProc, TexBlockReplace, TexCmdReplace, TexReplace

TexReplaceListProc(x, delim=", ") = join(x, delim)

function ListReplace(name, description, list, min_count = 1, max_count = 1E10, proc = TexReplaceListProc)
    function print_f(io::IO)
        if length(list) != 0
            print(io, "\tListReplace(name=$name, min=$min_count, max=$max_count, \n\t\tdesc:$description\n\n\t\t")
            print(io, join([l[1] * ": " * l[2] for l in list], "\n\n\t\t"))
            print(io, "\n\t)")
        else
            print(io, "\tReplace(name=$name, min=$min_count, max=$max_count, desc:$description)")
        end
    end

    function check_f(co)
        v = values(co)
        l = length(v)
        (l < min_count) && (return "Not enough items in $name. \n\n$co")
        (l > max_count) && (return "To many items in $name. \n\n$co")
        return nothing
    end

    function tex_string_f(io, co)
        k = check_f(co)
        k !== nothing && throw(error(k))
        tex_string(io, proc(values(co)))
    end

    return CustomizableObject(name, print_f, check_f, tex_string_f, push!, nothing, true, false)
end

SingleListReplace(name, description, list, optional=false, proc = TexReplaceListProc) = ListReplace(name, description, list, optional ? 0 : 1, 1, proc)
MultiListReplace(name, description, list, min_count = 1, max_count = 1E10, proc = TexReplaceListProc) = ListReplace(name, description, list, min_count, max_count, proc)
TexReplace(name, description, optional=false, proc = TexReplaceListProc) = SingleListReplace(name, description, [], optional, proc)


"Pushes a TexBlock to the current position of the template token stream so that it will be replaced in sequence"
function TexBlockReplace(name, description, proccessor; tex_block = TexBlock(), check_f = x -> nothing)
    print_f(io::IO) = print(io, "\tTexBlockReplace(name=$name, desc:$description)")
    function tex_string_f(io, co)
        k = check_f(co)
        k !== nothing && throw(error(k))
        proccessor(tex_block, values(co))
    end
    return CustomizableObject(name, print_f, check_f, tex_string_f, push!, x -> push!(x.templ[], tex_block), true, false)
end

"Pushes a TexCmd to the current position of the template token stream so that it will be replaced in sequence"
function TexCmdReplace(name, description, proccessor = append!; check_f = nothing)
    tex_cmd = TexCmd(name, [], [])
    check_f = something(check_f, co -> (length(co) == 0 ? "Value cannot be Empty! $co" : nothing))
    print_f(io::IO) = print(io, "\tTexCmdReplace(name=$name, desc:$description)")
    function tex_string_f(io, co)
        k = check_f(co)
        k !== nothing && throw(error(k))
        proccessor(tex_cmd, values(co))
    end
    return CustomizableObject(name, print_f, check_f, tex_string_f, push!, x -> push!(x.templ[], tex_cmd), true, false)
end