export TexJuliaBlock, SourceExprResolve, TexJuliaFile

TexJuliaFile(path::String) = TexCmd("jlinputlisting", texpath(path))
TexJuliaBlock(code::String) = TexBeginEnd("jllisting", TexMultilineString(code, setting = WriterSetting(0, false)), name=:JuliaBlock)

@enum SourceExprResolve begin
    Nothing
    LazyCollapse
    SourceFile
end

function TexJuliaBlock(code::Expr; resolve::SourceExprResolve = SourceFile)    
    str = nothing
    if resolve == SourceFile
        
        function Walk_Expr(x, M, m, f)
            if x isa Expr
                for a in x.args
                    M, m, f = Walk_Expr(a, M, m, f)
                end
            elseif x isa LineNumberNode
                m = min(m, x.line) 
                M = max(M, x.line)    
                (f === nothing) && (f = x.file)
                (f != x.file) && throw(ArgumentError("Unable to use Source File Resolver due to multiple files!"))      
            end
            return (M, m, f)
        end

        M, m, f = Walk_Expr(code, typemin(Int), typemax(Int), nothing)
        str = join(remove_lefthandside_white_space(readlines(string(f))[m:(M + 1)]), "\n")
    else
        buf = IOBuffer()
        Base.show_unquoted(buf, Base.remove_linenums!(code).args[1])
        str = String(take!(buf))

        #The goal of lazy collapse is to convert single line lambdas etc back to single line rather then having multi line begin ends
        if resolve == LazyCollapse
            str = replace(str, r"begin\n\s*([^\n]+)\n\s*end" => s"\1")
        end
    end

    return TexJuliaBlock(str)
end

