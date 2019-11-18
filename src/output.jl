#-------------------------------------------------------------------------------
# File: output.jl
# Description: This files contains all functions and strucutes that are used for
# outputs.
# Date: November 17, 2019
# Authors: Killian Fretaud, Rémi Garcia,
#-------------------------------------------------------------------------------

mutable struct Machine
    starting_times::Vector{Int}
    processing_times::Vector{Int}
end

mutable struct Robot
    moves::Vector{Int}
    set_up_times::Vector{Int}
    transport_times::Vector{Int}
end

mutable struct Solution
    C_max::Int
    order_of_jobs::Vector{Int}
    machines::Vector{Machine}
    robot::Robot
end

"""
    solve_to_represent(instance::Instance, z::Float64, sol::ModelVars)

Returns a solution converted from the instance and the model after optimization
into an structure easier to use for outputs.
"""
function solve_to_represent(instance::Instance, z::Float64, sol::ModelVars)
    m = instance.nb_machines
    n = instance.nb_jobs

    jobs_ordered = Vector{Int}(undef, n)
    machines = Vector{Machine}(undef, m)
    for j in 1:m
        times = zeros(Int, n)
        for i in 1:n
            times[i] = round(Int, value.(sol.sm[i, j]))
        end
        machines[j] = Machine(times, instance.processing_times[:, j])
        #machines[j] = Machine(value.(sol.sm[:, j]), instance.processing_times[:, j])
    end

    precedence = sum(value.(sol.y), dims=2)
    index = 1 ; next_is = n-1
    while index <= n
        job = 1
        while precedence[job] != next_is && job <= n
            job += 1
        end
        jobs_ordered[index] = job
        index += 1 ; next_is -= 1
    end

    moves = zeros(Int, instance.nb_robot)
    occurence = ones(Int, n) # sur quelle prochaine machine doit aller la tâche
    st = zeros(Int, instance.nb_robot)

    # For all move
    for pos in 1:instance.nb_robot
        st[pos] = round(Int, value.(sol.st[pos]))
        for job in 1:n
            # This is the job taken
            if occurence[job] <= (m + 1)
                if Bool(round(Int, value.(sol.x[job, occurence[job], pos])))
                    moves[pos] = job
                    occurence[job] += 1
                end
            end
        end
    end

    return Solution(round(Int, z), jobs_ordered, machines, Robot(moves, st, instance.travel_times))
end

"""
    print_solution(solution::Solution)

Prints `solution` in a human friendly form.
"""
function print_solution(solution::Solution)
    println("\t= Solution is =============================================")
    println("\tCmax = ", solution.C_max)
    println("\tMachines: processed job (starting time, ending time)")
    for j in 1:length(solution.machines)
        print("\t", j, ":")
        for i in solution.order_of_jobs
            start = solution.machines[j].starting_times[i]
            print("\tjob ", i, "(", start, ", ", start + solution.machines[j].processing_times[i], ")")
        end
        println()
    end
    occurences = ones(Int, length(solution.order_of_jobs))
    println("\tRobot: job moved (set up time + transport time)")
    print("\t\t")
    for k in 1:length(solution.robot.moves)
        job = solution.robot.moves[k]
        print("J", job, "(", solution.robot.set_up_times[k], "+", solution.robot.transport_times[occurences[job]], ") ")
        occurences[job] += 1
    end
    println()
    println("\t===========================================================")
end
