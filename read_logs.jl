using Infiltrator

using DataFrames
function parse_table(line::String)
    # Define the regex pattern to capture each column in a line

    # \d|\? matches line to be number or ? so it works with files with space file names
  pattern = r"^\s*(\d+)\s+(\d+)\s+(.+?)\s+(\d+|\?)\s+(.+)$"

    # Store parsed rows in a DataFrame
    # using DataFrames
    # df = DataFrame(Count=Int[], Overhead=Int[], File=String[], Line=String[], Function=String[])

    if isnothing(match(pattern, line))
        return missing  # Skip headers or any non-matching lines
    end
    m = match(pattern, line)

    # Append to DataFrame
    return (parse(Int, m.captures[1]),   # Count
            parse(Int, m.captures[2]),   # Overhead
            m.captures[3],               # File
            m.captures[4],               # Line
            m.captures[5])              # Function

end

# ENV["DATAFRAMES_COLUMNS"] = 1000
# TODO can do it without messing with env
function display_df(df::DataFrame, truncate::Int=0)
    # Main.@infiltrate
    # truncate=0 -> all
    show(df, allcols=true, allrows=true, truncate=truncate)
end

function display_profile_table(df::DataFrame)
    rows, columns = Base.displaysize(stdout)
    println(columns)
    display_df(sort(df, :Overhead, rev=true)[1:min(20, nrow(df))     , :], Int(floor(columns/3)))
    display_df(sort(df, :Count,    rev=true)[1:min(rows-20-2*2, nrow(df)), :], Int(floor(columns/3)))
end

function print_lines_between_markers(filename::String)
    # Track position in the file to continue reading new lines only
    last_position = 0
    within_section = false

    df = DataFrame(Count=Int[], Overhead=Int[], File=String[], Line=String[], Function=String[])

    while true
        print(".")
        open(filename, "r") do file
            # Move to the last known position
            seek(file, last_position)

            for line in eachline(file)
                print("/")
                # Check for the start of the section
                if occursin("==> Date", line)
                    within_section = true
                    empty!(df)
                elseif occursin("<==", line)
                    # End of the section
                    within_section = false

                    display_profile_table(df)
                    # println(df)

                elseif within_section
                    res_split = parse_table(line)
                    if !ismissing(res_split)
                        push!(df, res_split)
                    end
                    # Print lines within the section
                    # print("@")
                    # println(line)
                end
            end

            # Update last position to the current end of file for the next loop
            last_position = position(file)
        end
        # Sleep briefly to avoid busy-waiting
        sleep(0.5)
        flush(stdout)
    end
end

# Run the function with the target file
print_lines_between_markers("a")
