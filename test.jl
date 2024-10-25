using Unitful
using Test
function _format_for_unitful(expr::AbstractString)
    # Check that parentheses are balanced
    count_parenthesis = 0
    for char in expr
        char == "(" && (count_parenthesis += 1)
        char == ")" && (count_parenthesis -= 1)
        count_parenthesis < 0 && error("Parentheses are not balanced")
    end
    count_parenthesis != 0 && error("Parentheses are not balanced")

    num_left = count('(', expr)
    num_right = count(')', expr)
    num_left != num_right && return error(
        "Number of opening and closing parentheses are not the same",
    )
    # Split the input into matches, handling parentheses and other characters
    matches = collect(eachmatch(r"\(([^()]|(?R))*\)\^\S+|\(([^()]|(?R))*\)|\S+", expr))

    result = String[]  # To store the final result

    for match in matches
        t = match.match
        # Deal with cases that look like: (m * s)^-2
        if startswith(t, "(") && endswith(t, r"\)\^[-]?\d+")
            # Remove parentheses and ^ and recurse
            index = findlast(')', t)
            str = t[(begin + 1):(index - 1)]
            inner_fixed = "(" * _format_for_unitful(str) * t[index:end]
            push!(result, inner_fixed)
        # Deal with cases that look like: (m * s)
        elseif startswith(t, "(") && endswith(t, ")")
            # Remove parentheses and recurse
            inner_str = t[(begin + 1):(end - 1)]
            inner_fixed = "(" * _format_for_unitful(inner_str) * ")"
            push!(result, inner_fixed)
        # Deal with cases that look like m, s^-1, *, /
        else
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

# Positive cases - should be parseable
# Include cases that are already parseable by Unitful, but useful to have for testing
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
str18 = "(m s) (s)"
str19 = "(m)^2"
str20 = "(m)(s)(s)"

# Negative cases - should not be parseable
nstr1 = "(m"
nstr2 = "m)"
nstr3 = "W-2"

@testset "Constructors and helper functions" begin
    @test uparse(_format_for_unitful(str1)) |> string == "m"
    @test uparse(_format_for_unitful(str2)) |> string == "m"
    @test uparse(_format_for_unitful(str3)) |> string == "m s"
    @test uparse(_format_for_unitful(str4)) |> string == "m s"
    @test uparse(_format_for_unitful(str5)) |> string == "m s^2"
    @test uparse(_format_for_unitful(str6)) |> string == "m s"
    @test uparse(_format_for_unitful(str7)) |> string == "m s^2"
    @test uparse(_format_for_unitful(str8)) |> string == "m s^-1"
    @test uparse(_format_for_unitful(str9)) |> string == "m s"
    @test uparse(_format_for_unitful(str10)) |> string == "m"
    @test uparse(_format_for_unitful(str11)) |> string == "m^2"
    @test uparse(_format_for_unitful(str12)) |> string == "m^2 s"
    @test uparse(_format_for_unitful(str13)) |> string == "m^2 s^2"
    @test uparse(_format_for_unitful(str14)) |> string == "s^2 m^-2"
    @test uparse(_format_for_unitful(str15)) |> string == "s^4 m^-2"
    @test uparse(_format_for_unitful(str16)) |> string == "s^4 m^-2"
    @test uparse(_format_for_unitful(str17)) |> string == "s^-2"
    @test uparse(_format_for_unitful(str18)) |> string == "m s^2"
    @test uparse(_format_for_unitful(str19)) |> string == "m^2"
    @test uparse(_format_for_unitful(str20)) |> string == "m s^2"

    @test_throws ErrorException uparse(_format_for_unitful(nstr1)) |> string
    @test_throws ErrorException uparse(_format_for_unitful(nstr2)) |> string
    @test_throws MethodError uparse(_format_for_unitful(nstr3)) |> string
end
