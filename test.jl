using Unitful
using Test
function parse_units(expr::AbstractString)
    num_left = count('(', expr)
    num_right = count(')', expr)
    num_left != num_right && return error(
        "Number of opening and closing parentheses are not the same",
    )
    # Split the input into matches, handling parentheses and other characters
    matches = collect(eachmatch(r"\(.*\)\^\S*|\(.*\)|\S+", expr))

    result = String[]  # To store the final result

    for match in matches
        # Get the matched string
        t = match.match

        if startswith(t, "(") && endswith(t, r"\)\^[-]?\d+")
            # Remove parentheses and ^ and recurse
            index = findlast(')', t)
            str = t[(begin + 1):(index - 1)]
            inner_fixed = "(" * parse_units(str) * t[index:end]
            push!(result, inner_fixed)
        elseif startswith(t, "(") && endswith(t, ")")
            # Remove parentheses and recurse
            inner_str = t[(begin + 1):(end - 1)]
            inner_fixed = "(" * parse_units(inner_str) * ")"
            push!(result, inner_fixed)
        else
            # Add the match itself (like "m", "s^-1", "/")
            push!(result, t)
        end
    end

    final_expr = String[]
    for (idx, str) in enumerate(result)
        push!(final_expr, str)
        # Add "*" between units if the current string is not already a "/" or "*", the next
        # string is not "/" or "*", and not at the end
        if idx < length(result) &&
           (str != "*" && str != "/") &&
           (result[idx + 1] != "*" && result[idx + 1] != "/")
            push!(final_expr, " * ")
        end
    end

    return join(final_expr, " ")
end

# Positive cases
str1 = "m"
str2 = "(m)"
str3 = "((((m s))))"
str4 = "m s"
str5 = "m s s"
str6 = "(m s)"
str7 = "(m s) s"
str8 = "m / s"
str9 = "m * s"
str10 = "m * s / s"
str11 = "m^2"
str12 = "m^2 s"
str13 = "m^2 s s"
str14 = "m^-2 s s"
str15 = "m^-2 s^3 s"
str16 = "m^-2 s s^3"
str17 = "m s^-1 / (m s)"
@testset "Constructors and helper functions" begin
    @test uparse(parse_units(str1)) |> string == "m"
    @test uparse(parse_units(str2)) |> string == "m"
    @test uparse(parse_units(str3)) |> string == "m s"
    @test uparse(parse_units(str4)) |> string == "m s"
    @test uparse(parse_units(str5)) |> string == "m s^2"
    @test uparse(parse_units(str6)) |> string == "m s"
    @test uparse(parse_units(str7)) |> string == "m s^2"
    @test uparse(parse_units(str8)) |> string == "m s^-1"
    @test uparse(parse_units(str9)) |> string == "m s"
    @test uparse(parse_units(str10)) |> string == "m"
    @test uparse(parse_units(str11)) |> string == "m^2"
    @test uparse(parse_units(str12)) |> string == "m^2 s"
    @test uparse(parse_units(str13)) |> string == "m^2 s^2"
    @test uparse(parse_units(str14)) |> string == "s^2 m^-2"
    @test uparse(parse_units(str15)) |> string == "s^4 m^-2"
    @test uparse(parse_units(str16)) |> string == "s^4 m^-2"
    @test uparse(parse_units(str17)) |> string == "s^-2"

end
