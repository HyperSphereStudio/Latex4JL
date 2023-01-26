export TexPackage
export TexFile
export compile
export adddependency

using Dates

struct TexPackage <: AbstractTexCommand
    name
    attributes
    is_local::Bool
    TexPackage(name, attributes = []) = new(name in LOCAL_LIBS ? texpath(joinpath(PROJECT_ROOT, "lib", name)) : name, attributes)
    Base.isequal(lp::TexPackage, lp2::TexPackage) = lp.name == lp2.name
end

Base.nameof(lp::TexPackage) = "usepackage"
attributes(lp::TexPackage) = lp.attributes
Base.values(lp::TexPackage) = [lp.name]

const DefaultPackages = [
                            TexPackage("graphicx"), 
                            TexPackage("jlcode", ["theme" => "darkbeamer", "linenumbers" => "true"]), 
                            TexPackage("inputenc", ["utf8"]),
                            TexPackage("gensymb"),
                            TexPackage("amsmath")
                        ]

struct TexFile <: AbstractTexBlock
    file
    packages::Vector{TexPackage}
    attributes::Vector{AbstractTexCommand}
    items::Vector{AbstractTexObject}
    dependent_files::Vector{TexFile}

    function TexFile(file, packages = TexPackage[]; documentclass = "article")
        attributes = AbstractTexCommand[]
        push!(attributes, TexCmd("documentclass", documentclass))
        push!(attributes, TexCmd("input", LATEXCORE_TEX_PATH))

        lf = new(file, packages, attributes, [], [])
        
        append!(lf, DefaultPackages)
        append!(lf, packages)

        return lf
    end

    Base.values(lf::TexFile) = lf.items
    Base.append!(lf::TexFile, items) = (for f in items; push!(lf, f); end)
    function Base.push!(lf::TexFile, lp::TexPackage)
        if (i = findfirst(x -> isequal(x, lp), lf.packages)) === nothing
            push!(lf.attributes, lp)
            push!(lf.packages, lp)
        end
    end
end

attributes(lf::TexFile) = lf.attributes
adddependency(lf::TexFile, lf2::TexFile) = push!(lf.dependent_files, lf2)

function tex_string(io::LatexWriter, lc::TexFile)
    for a in lc.attributes
        tex_string(io, a)
        println(io)
    end

    for item in lc
        tex_string(io, item)
    end
end

function generate_tex(lf::TexFile)
    for dp in lf.dependent_files
        generate_tex(dp)
    end

    file_name = basename(lf.file)
    path =  "$file_name.tex"
    p = joinpath(BUILD_DIR, path)
    
    open(p, "w") do io
        tex_string(LatexWriter(io), lf)     
    end

    cp(p, lf.file * ".tex", force=true)

    return p
end

function compile(lf::TexFile)
    file_name = basename(lf.file)
    path =  "$file_name.tex"
    dest_path = lf.file
    build_path = joinpath(BUILD_DIR, file_name)
    log_file = joinpath(dirname(lf.file), "$file_name.log")
    excep = nothing
    tx = generate_tex(lf)

    println("Building PDF...")
    cmd = Cmd(Cmd(["pdflatex", "-interaction=nonstopmode", "-quiet", path]), dir = BUILD_DIR)
    
    try
        println(read(cmd, String))
        cp("$build_path.pdf", "$dest_path.pdf", force=true)
        rm(log_file, force=true)
        println("Built PDF!!!")
    catch e
        cp(joinpath(BUILD_DIR, "$file_name.log"), log_file, force=true)
        excep = e
    end

    println("Cleaning Directory....")
    
    for f in readdir(BUILD_DIR)
        s = splitext(f)
        if s[1] == file_name
            rm(joinpath(BUILD_DIR, f))
        end
    end

    (excep !== nothing) && throw(excep)

    return (tx, "$dest_path.pdf")
end