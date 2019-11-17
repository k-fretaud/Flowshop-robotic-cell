#-------------------------------------------------------------------------------
# File: main.jl
# Description: This files contains all functions that are used for experiment.
# Date: November 17, 2019
# Authors: Killian Fretaud, Rémi Garcia,
#-------------------------------------------------------------------------------

using JuMP
using Random

#--------------------------------------------------
#
#               Choose a solver
#
#using Cbc; const OPTIMIZER_SELECTED = Cbc.Optimizer
#using Gurobi; const OPTIMIZER_SELECTED = Gurobi.Optimizer
using CPLEX; const OPTIMIZER_SELECTED = CPLEX.Optimizer
#using GLPK; const OPTIMIZER_SELECTED = GLPK.Optimizer
#
#--------------------------------------------------

# Instance & structures
include("instances.jl")
include("data.jl")
include("model.jl")
include("genetic.jl")
include("output.jl")

"""
    params_exact:
        time limit in seconds

    params_genetic:
        probability of crossover
        probability of mutation
        population size
        number of generations
        number of constructions
"""
function solve(instance;
               solve_exact = true, params_exact = (Float64(60*20), ),
               use_genetic = true, params_genetic = (0.8, 0.2, 100, 100, 5),
               print_solutions = false, print_times = true)
    if solve_exact
        println("Exact:")
        model, vars = get_model_from_instance(instance)
        set_time_limit_sec(model, params_exact[1])
        time_for_solving = @timed optimize!(model)
        if print_times
            println("\tTime: ", time_for_solving[2])
        end
        if print_solutions
            if termination_status(model) == MOI.OPTIMAL
                print_solution(solve_to_represent(instance, objective_value(model), vars))
            elseif termination_status(model) == MOI.TIME_LIMIT && has_values(model)
                println("\tSolution is not proved optimal")
                print_solution(solve_to_represent(instance, objective_value(model), vars))
            else
                println("\tNo solution found")
            end
        end
    end
    if use_genetic
        println("Genetic:")
        time_for_solving = @timed genetic(instance, params_genetic[1], params_genetic[2], params_genetic[3], params_genetic[4], params_genetic[5])
        if print_times
            println(time_for_solving[2])
        end
    end

    return
end


function main()
    list_instances, _ = data()
    for instance in list_instances
        println("Instance:\tnb_jobs = "*string(instance.nb_jobs)*"\tnb_machines = "*string(instance.nb_machines))
        solve(instance, params_exact = (1200.0, ), use_genetic = false, print_solutions = true)
        println()
    end
    
    return
end
