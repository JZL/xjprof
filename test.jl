# Accumulator to prevent optimization
global_accumulator = Ref(0.0)

function func_a(n)
    local_acc = 0.0
    for i in 1:100000
        local_acc += sqrt(i)  # Add result to local accumulator
    end
    global_accumulator[] += local_acc  # Side effect to avoid optimization
    func_b(n - 1)
end

# Expensive function with intensive computation
function func_b(n)
    local_acc = 0.0
    for i in 1:5000000  # Large iteration count makes this function expensive
        local_acc += sin(i) * cos(i) + log1p(i)
    end
    global_accumulator[] += local_acc  # Side effect to avoid optimization
    func_c(n - 1)
end

function func_c(n)
    local_acc = 0.0
    for i in 1:500000
        local_acc += exp(i % 10)  # Smaller calculation
    end
    global_accumulator[] += local_acc  # Side effect to avoid optimization
    func_d(n - 1)
end

function func_d(n)
    if n > 0
        func_a(n - 1)
    else
        local_acc = 0.0
        for i in 1:250000
            local_acc += log(i)
        end
        global_accumulator[] += local_acc  # Side effect to avoid optimization
    end
end

# Main function to start the profiling test

using Profile
# function _peek_report()
    # iob = IOBuffer()
    # ioc = IOContext(IOContext(iob, stderr), :displaysize=>displaysize(stderr))
    # print(ioc, groupby = [:thread, :task])
    # Base.print(stderr, String(take!(iob)))
    # flush(stderr)

#     iob = IOBuffer()
#     ioc = IOContext(IOContext(iob, stderr), :displaysize=>displaysize(stderr))
#     print(ioc, groupby = [:thread, :task])
# end


# SIGINFO - https://sourcegraph.com/github.com/JuliaLang/julia@e474e0b470936110f689282c62a775ed4f0f4f81/-/blob/src/signals-unix.c?L923
# -> trigger_profile_peek, sets profile_autostop_time
# jl_check_profile_autostop periodically checks for this timeup -> "Profile collected."

# Start profile listener - https://sourcegraph.com/github.com/JuliaLang/julia@cd99cfc4d39c09b3edbb6040639b4baa47882f6e/-/blob/base/Base.jl?L619
# -> profile_printing_listener -> calls peek_report[]

# https://sourcegraph.com/github.com/JuliaLang/julia@cd99cfc4d39c09b3edbb6040639b4baa47882f6e/-/blob/base/Base.jl?L605
# JULIA_PROFILE_PEEK_HEAP_SNAPSHOT=true -> save heap snapshot

# https://sourcegraph.com/github.com/JuliaLang/julia@e474e0b470936110f689282c62a775ed4f0f4f81/-/blob/stdlib/Profile/src/Profile.jl?L64
Profile.peek_report[] = function my_peek_report()
    iob = IOBuffer()
    ioc = IOContext(IOContext(iob, stderr),
                    # :displaysize=>displaysize(stderr))
                    :displaysize=>(18, 500))
    Profile.print(
    ioc,
    format=:flat,
    # format=:tree, recur=:flat,
    C=true, combine=true,

    # Samples which *include* the function (to get stracktrace), or actual
    # use by this exact function
    # sortedby=:count
    sortedby=:overhead
    )
    Base.println(stderr, "==> Date")
    Base.print(stderr, String(take!(iob)))
    Base.println(stderr, "<==")
    flush(stderr)
end
# This is a ref so that it can be overridden by other profile info consumers.
# const peek_report = Ref{Function}(_peek_report)

while true
    func_a(1)
    sleep(.01)
end

# using Profile
# function test_profiling(n)
#     @profile func_a(n)
# end

# # Run the profiling test with a small number for easy observation
# test_profiling(3)

# # Print the profiling result
# Profile.print(
#     format=:flat,
#     # format=:tree, recur=:flat,
#               C=true, combine=true,
#               sortedby=:count)
