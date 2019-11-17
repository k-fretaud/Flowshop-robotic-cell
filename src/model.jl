#-------------------------------------------------------------------------------
# File: model.jl
# Description: This files contains all functions that are used for the model.
# Date: November 17, 2019
# Authors: Killian Fretaud, Rémi Garcia,
#-------------------------------------------------------------------------------

mutable struct ModelVars
    x::Array{VariableRef, 3}
        # robot move job i to machine j on its kth move
    y::Array{VariableRef, 2}
        # job i treated before job j
    st::Array{VariableRef, 1}
        # kth setup time on the robot
    sm::Array{VariableRef, 2}
        # starting time of job i on the machine j
    bm::Array{VariableRef, 2}
        # blockage duration of machine j by job i
    sr::Array{VariableRef, 2}
        # starting time of transport of job i towards machine j by the robot
    br::Array{VariableRef, 2}
        # blockage duration of job i on the robot before machine j is free

    ModelVars(X, Y, ST, SM, BM, SR, BR) = new(X, Y, ST, SM, BM, SR, BR)
end


# High Value
const HV = 999

"""
    get_model_from_instance(instance::Instance; redundancy::Bool=false)

Model proposed by A. Soukhal and P. Martineau. Corrected for non-equidistant machines.
Redundant constraint can be activated.
"""
function get_model_from_instance(instance::Instance; redundancy::Bool=false)
    # Dimensions of datas
    n = instance.nb_jobs ; m = instance.nb_machines ; l = instance.nb_robot

    M = Model(with_optimizer(OPTIMIZER_SELECTED))
    set_silent(M)

    @variable(M, x[1:n, 1:(m+1), 1:l], Bin)
    @variable(M, y[1:n, 1:n], Bin)
    @variable(M, st[1:l] >= 0, Int)
    @variable(M, sm[1:n, 1:m] >= 0, Int)
    @variable(M, bm[1:n, 1:m] >= 0, Int)
    @variable(M, sr[1:n, 1:m+1] >= 0, Int)
    @variable(M, br[1:n, 1:m+1] >= 0, Int)
    @variable(M, Cmax >= 0, Int)

    @objective(M, Min, Cmax)

    @constraint(M, TacheOnRobot[i=1:n, j=1:(m+1)], sum(x[i, j, k] for k in 1:l) == 1)
    @constraint(M, OnlyOneOnPos[k=1:l], sum(x[i, j, k] for i in 1:n, j in 1:(m+1)) == 1)

    @constraint(M, ConservationPrec[i=1:n, j=1:m],
                   sum(x[i, j, k]*k for k in 1:l) <= sum(x[i, j+1, k]*k for k in 1:l))
    @constraint(M, Precedence[i=1:(n-1), I=(i+1):n], y[i, I] + y[I, i] == 1)

    @constraint(M, ConservationPrem[i=1:n, I=1:n, k=1:(l-1), K=(k+1):l; i != I],
                   y[i, I] >= - 1 + x[i, 1, k] + x[I, 1, K])

    @constraint(M, ValueStSensHor[k=1:(l-1)],
                   sum(x[i, j, (k+1)] * sum(instance.travel_times[J] for J in 1:(j-1)) for i in 1:n, j in 1:(m+1))
                 - sum(x[i, j, k] * sum(instance.travel_times[J] for J in 1:j) for i in 1:n, j in 1:(m+1)) <= st[k+1])
    @constraint(M, ValueStSensAntiHor[k=1:(l-1)],
                   sum(x[i, j, k] * sum(instance.travel_times[J] for J in 1:j) for i in 1:n, j in 1:(m+1))
                 - sum(x[i, j, (k+1)] * sum(instance.travel_times[J] for J in 1:(j-1)) for i in 1:n, j in 1:(m+1)) <= st[k+1])
    @constraint(M, st[1] == 0)

    @constraint(M, DisjonctionMachine[i=1:n, I=1:n, j=1:m; i != I],
                   sm[i, j] + instance.processing_times[i, j] + bm[i, j] <= sm[I, j] + HV*(1 - y[i, I]))
   if redundancy
       @constraint(M, DisjonctionMachineEquivalent[i=1:n, I=1:n, j=1:m; i != I],
                   sm[I, j] + inst.p[I, j] + bm[I, j] <= sm[i, j] + HV*y[i, I])
   end

    @constraint(M, NoStockMachine[i=1:n, j=1:m], sm[i, j] + instance.processing_times[i, j] + bm[i, j] == sr[i, j+1])
    @constraint(M, NoStockRobot[i=1:n, j=1:m], sr[i, j] + instance.travel_times[j] + br[i, j] == sm[i, j])

    @constraint(M, DisjonctionRobot[i=1:n, I=1:n, j=1:(m+1), J=1:(m+1), k=1:(l-1), K=(k+1):l; i!=I],
                   sr[I, J] + HV*(2 - x[i, j, k] - x[I, J, K]) >= sr[i, j] + instance.travel_times[j] + br[i, j] + st[K])

    @constraint(M, CMAX[i=1:n], Cmax >= sr[i, m+1] + instance.travel_times[m+1])

    # Ajout
    @constraint(M, PrecedenceDiag[i=1:n], y[i, i] == 0)

    vars = ModelVars(x, y, st, sm, bm, sr, br)

    return M, vars
end


#=function test_model()
    list_instances, list_instances_equi = data()
    # Equidistant with model non-equidistant
    println("=== Equidistant === ")
    for instance in list_instances_equi
        println(instance)
        model, sol = setModel(instance)
        GC.gc()
        @time optimize!(model)

        # Displaying the results
        if (termination_status(model) == MOI.OPTIMAL) || (termination_status(model) == MOI.TIME_LIMIT && has_values(model))
            print_solution(instance, objective_value(model), sol)
            println()
        end
    end

    # Non-equidistant
    println("===== Non-equidistant ===== ")
    for instance in list_instances
        println(instance)
        model, sol = get_model_from_instance(instance)
        GC.gc()
        @time optimize!(model)

        # Displaying the results
        if (termination_status(model) == MOI.OPTIMAL) || (termination_status(model) == MOI.TIME_LIMIT && has_values(model))
            print_solution(instance, objective_value(model), sol)
            println()
        end
    end
end

test_model()=#
