using Unitful

function parse_units(expr::AbstractString)
    num_left = count('(', expr)
    num_right = count(')', expr)
    num_left != num_right && return error("Number of opening and closing parentheses are not the same")
    # Split the input into tokens, handling parentheses and other characters
    tokens = collect(eachmatch(r"\(((?:[^()]*|(\([^()]*\)))*?)\)(\^[-+]?\d+)?|\S+", expr))

    result = String[]  # To store the final result

    for token in tokens
        t = token.match  # Get the matched string
        if startswith(t, "(") && endswith(t, r"\)\^[-]?\d+")
            index = findlast(')', t)
            str = t[begin+1:index-1]
            inner_fixed = "(" * parse_units(str) * t[index:end]
            push!(result, inner_fixed)
        elseif startswith(t, "(") && endswith(t, ")")
            # Remove parentheses and split the contents inside
            inner_str = t[begin+1:end-1]
            inner_fixed = "(" * parse_units(inner_str) * ")"
            # Add inner units, inserting '*' between them
            push!(result, inner_fixed)
        else
            # Add the token itself (like "m", "s^-1", "/")
            push!(result, t)
        end
    end

    final_expr = String[]
    for (idx, str) in enumerate(result)
        push!(final_expr, str)
        # Add "*" between units if not already a "/" or "*" and not at the end
        if idx < length(result) && (str != "*" && str != "/") && (result[idx+1] != "*" && result[idx+1] != "/")
            push!(final_expr, " * ")
        end
    end

    return join(final_expr, " ")
end

str1 = "m s^-1 / (m s)"
str2 = "m s s"
str3 = "(m s) s"
str4 = "((((m s))))"
uparse(parse_units(str1)) |> string == "s^-2"
uparse(parse_units(str2)) |> string == "m s^2"
uparse(parse_units(str3)) |> string == "m s^2"
uparse(parse_units(str4)) |> string == "m s"

