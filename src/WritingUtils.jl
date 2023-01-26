export remove_lefthandside_white_space, get_min_lefthandside_white_space_count, get_lefthandside_white_space_count

is_white_space(s) = match(r"^\s*$", s) !== nothing

function get_lefthandside_white_space_count(line, f)
    i = 1
    s = 0

    while length(line) >= i && (line[i] == ' ' || line[i] == '\t')
        s += line[i] == ' ' ? 1 : 4
        f(s, i)
        i += 1
    end

    return (s, i)
end

function get_min_lefthandside_white_space_count(lines)
    min_count = typemax(Int)
    for line in lines
        is_white_space(line) && continue
        min_count = min(min_count, get_lefthandside_white_space_count(line, (x, i) -> ())[1])
    end
    return min_count
end

function remove_lefthandside_white_space(lines)
    count = get_min_lefthandside_white_space_count(lines)

    for i in 1:length(lines)
        line = lines[i]
        if is_white_space(line)
            lines[i] = ""
        else
            start_trim_idx = 1
            get_lefthandside_white_space_count(line, 
                function(x, i)
                    if x <= count
                        start_trim_idx = i + 1
                    end
                end)[1]          
            lines[i] = line[start_trim_idx:end]
        end
    end
    return lines
end