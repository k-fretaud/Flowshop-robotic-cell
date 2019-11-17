#-------------------------------------------------------------------------------
# File: genetic.jl
# Description: This files contains all functions that are used for genetic.
# Date: November 17, 2019
# Authors: Killian Fretaud.
#-------------------------------------------------------------------------------

"""

"""
function selection(roulette_wheel, population, instance::Instance, population_size::Int)
    parent_1 = rand(1:roulette_wheel[population_size])
    i = 1
    while parent_1 > roulette_wheel[i] && i < population_size
        i += 1
    end
    parent_1 = i
    parent_2 = parent_1
    while parent_2 == parent_1
        parent_2 = rand(1:roulette_wheel[population_size])
        i = 1
        while parent_2 > roulette_wheel[i] && i < population_size
            i += 1
        end
        parent_2 = i
    end

    return parent_1, parent_2
end

"""

"""
function crossover(parent_1, parent_2, population, instance::Instance)
    index = rand(1:instance.nb_jobs)
    start = parent_1[index]

    offspring_1 = zeros(Int, instance.nb_jobs) ; offspring_1[index] = start
    offspring_2 = zeros(Int, instance.nb_jobs) ; offspring_2[index] = parent_2[index]

    while parent_2[index] != start
        i = 1
        while (parent_1[i] != parent_2[index])
            i += 1
        end
        index = i
        offspring_1[index] = parent_1[index]
        offspring_2[index] = parent_2[index]
    end

    for index in 1:instance.nb_jobs
        if offspring_1[index] == 0
            offspring_1[index] = parent_2[index]
            offspring_2[index] = parent_1[index]
        end
    end

    return offspring_1, offspring_2
end

"""

"""
function mutation(genotype, phenotype)
    n = length(genotype)
    indice_1 = rand(1:n) ; indice_2 = indice_1
    while indice_1 == indice_2
        indice_2 = rand(1:n)
    end

    gene_1 = genotype[indice_1] ; gene_2 = genotype[indice_2]
    genotype[indice_1] = gene_2 ; genotype[indice_2] = gene_1

    for k in 1:length(phenotype)
        if phenotype[k] == gene_1
            phenotype[k] = gene_2
        elseif phenotype[k] == gene_2
            phenotype[k] = gene_1
        end
    end

    return genotype, phenotype
end

"""

"""
function evaluation(phenotype, instance::Instance)
    m = instance.nb_machines
    K = length(phenotype)
    n = instance.nb_jobs
    occurence = zeros(Int, n) # sur quelle machine est la tâche
    machines  = zeros(Int, m) # quelle tâche est sur la machine
    C_of_m = zeros(Int, m)
    C_of_task = zeros(Int, m)
    time_robot = 0 ; travel = 0 # last machine visited

    # For all move
    for pos in 1:K
        # A job goes to a machine
        job = phenotype[pos]
        occurence[job] = occurence[job] + 1
        j = occurence[job]

        # Compute the robot's set-up time
        travel_time = 0
        for i in j:travel
            travel_time = travel_time + instance.travel_times[i]
        end
        for i in (travel+1):(j-1)
            travel_time = travel_time + instance.travel_times[i]
        end
        travel = j

        # Is it a machine or the end of our cycle ?
        if j < m+1
            # Process start when :
            #   - machine is available
            #   - job is available and delivered,
            #   - robot has finish is set-up and delivered the job
            debut = max(C_of_m[j], max(C_of_task[job], time_robot + travel_time) + instance.travel_times[j])
            time_robot = debut
            C_of_m[j] = debut + instance.processing_times[job, j]
            C_of_task[job] = C_of_m[j]
        else
            debut = max(C_of_task[job], time_robot + travel_time) + instance.travel_times[j]
            time_robot = debut
        end
    end

    return time_robot
end

"""

"""
# should give cmax without more calcul after its call
function construction_and_evaluation(genotype, instance::Instance)
    #Step 1: Initialization
    n = instance.nb_jobs ; m = instance.nb_machines
    phenotype = [] ; pos = 1 # position a remplir
    occurence = zeros(Int, n) # sur quelle machine est la tâche
    machines  = zeros(Int, m) # quelle tâche est sur la machine

    # evaluation
    C_of_m = zeros(Int, m)
    time_robot = 0 ; travel = 0 # last machine visited
    # end evaluation

    # At first, there is only one job available
    E = [1] # set of indexes

    #Step 2: General procedure
    while pos <= n*(m+1)
        # Next job is chosen randomly
        k = rand(1:length(E))
        indice = E[k] ; job = genotype[indice]
        # We push it
        push!(phenotype, job) ; pos = pos + 1
        occurence[job] = occurence[job] + 1
        j = occurence[job]

        # Was the job on a machine ?
        if j > 1 && j <= m
            machines[j-1] = 0
        end

        # Is next job available ?
        if occurence[job] == 1 && indice < n
            push!(E, indice+1)
        end

            # evaluation
                travel_time = 0
                for i in j:travel
                    travel_time = travel_time + instance.travel_times[i]
                end
                for i in (travel+1):(j-1)
                    travel_time = travel_time + instance.travel_times[i]
                end
                travel = j

                if j <= m
                    temp = 0
                    if j > 1
                        temp = C_of_m[j-1]
                    end
                    debut = max(C_of_m[j], max(temp, time_robot + travel_time) + instance.travel_times[j])
                    time_robot = debut
                    C_of_m[j] = debut + instance.processing_times[job, j]
                else
                    debut = max(C_of_m[j-1], time_robot + travel_time) + instance.travel_times[j]
                    time_robot = debut
                end
            # end evaluation

        # The machine was not available
        while (j <= m && machines[j] != 0)
            # Swap
            Tk = machines[j] ; machines[j] = job
            job = Tk
            # Again we push it
            push!(phenotype, job) ; pos = pos + 1
            occurence[job] = occurence[job] + 1
            j = occurence[job]

                # evaluation
                    travel = j
                    if j <= m
                        debut = max(C_of_m[j], time_robot + instance.travel_times[j])
                        time_robot = debut
                        C_of_m[j] = debut + instance.processing_times[job, j]
                    else
                        time_robot = time_robot + instance.travel_times[j]
                    end
                # end evaluation
        end

        if j == m + 1
            deleteat!(E, 1)
            if machines[m] == job
                machines[m] = 0
            end
        elseif j <= m
            machines[j] = job
        end
    end

    return phenotype, time_robot
end

"""

"""
function evaluate_genotype(genotype, instance::Instance, nb_of_constructions::Int)
    phenotype, score = construction_and_evaluation(genotype, instance)
    for j in 1:nb_of_constructions
        p, s = construction_and_evaluation(genotype, instance)
        if s < score
            phenotype = p ; score = s
        end
    end
    return (genotype, phenotype, score)
end

"""

"""
function first_generation(instance::Instance, population_size::Int, nb_of_constructions::Int)
    population = []
    for i in 1:population_size
        genotype = randperm(instance.nb_jobs)
        push!(population, evaluate_genotype(genotype, instance, nb_of_constructions))
    end
    return population
end

"""
    genetic(instance::Instance,
            probability_of_crossover::Float64 = 0.8,
            probability_of_mutation::Float64 = 0.2,
            population_size::Int = 100, nb_max_of_generation::Int = 100,
            nb_of_constructions::Int = 5)

Applies the genetic algorithm on `instance`. Uses a few parameters. Default
values are from the article. Return the best solution found.
"""
function genetic(instance::Instance,
                 probability_of_crossover::Float64 = 0.8,
                 probability_of_mutation::Float64 = 0.2,
                 population_size::Int = 100, nb_max_of_generation::Int = 100,
                 nb_of_constructions::Int = 5
                 ;
                 verbose = false)
    if verbose
        println("----------------------------  START of GA's execution")
    end

    # inital population
    population = first_generation(instance, population_size, nb_of_constructions)
    sort!(population, by = x -> x[3])

    maximum_score = population[population_size][3]
    score_for_roulette_wheel = zeros(Int, population_size)
    total = 0
    for i in 1:population_size
        score_for_roulette_wheel[i] = maximum_score .- population[i][3]
        total += score_for_roulette_wheel[i]
        score_for_roulette_wheel[i] = total
    end

    # time pass
    generation = 1
    while generation <= nb_max_of_generation
        if verbose
            if (generation-1) % 10 == 0
                println("it. ", generation)
            end
        end

        nb_offsprings = 0
        while nb_offsprings < (population_size * probability_of_crossover)

            p1, p2 = selection(score_for_roulette_wheel, population, instance, population_size)

            o1, o2 = crossover(population[p1][1], population[p2][1], population, instance)
            o1, o1_phenotype, o1_score = evaluate_genotype(o1, instance, nb_of_constructions)
            o2, o2_phenotype, o2_score = evaluate_genotype(o2, instance, nb_of_constructions)

            if rand() <= probability_of_mutation
                o1, o1_phenotype = mutation(o1, o1_phenotype)
                o1_score = evaluation(o1_phenotype, instance)
            end
            if rand() <= probability_of_mutation
                o2, o2_phenotype = mutation(o2, o2_phenotype)
                o2_score = evaluation(o2_phenotype, instance)
            end

            push!(population, (o1, o1_phenotype, o1_score))
            push!(population, (o2, o2_phenotype, o2_score))

            nb_offsprings = nb_offsprings + 2
        end

        sort!(population, by = x -> x[3])
        for i in 1:nb_offsprings
            pop!(population)
        end

        if verbose
            if generation % 10 == 0
                println("\tbest  Cmax: ", population[1][3])
                println("\tworst Cmax: ", population[100][3])
            end
        end

        generation = generation + 1
    end
    if verbose
        println()
        println()
        println("----------------------------  END of GA's execution")
        println("Best solution: ", population[1][1])
        println("\t", population[1][2])
        println("Cmax is ", population[1][3])
    end

    return population[1]
end

"""

"""
function construction(genotype, instance)
    #Step 1: Initialization
    n = instance.nb_jobs ; m = instance.nb_machines
    phenotype = [] ; pos = 1 # position a remplir
    occurence = zeros(Int, n) # sur quelle machine est la tâche
    machines  = zeros(Int, m) # quelle tâche est sur la machine

    # At first, there is only one job available
    E = [1] # set of indexes

    #Step 2: General procedure
    while pos <= n*(m+1)

        # Next job is chosen randomly
        k = rand(1:length(E))
        indice = E[k] ; job = genotype[indice]
        # We push it
        push!(phenotype, job) ; pos = pos + 1
        occurence[job] = occurence[job] + 1
        j = occurence[job]

        # Was the job on a machine ?
        if j > 1 && j <= m
            machines[j-1] = 0
        end

        # Is next job available ?
        if occurence[job] == 1 && indice < n
            push!(E,indice+1)
        end

        # The machine was not available
        while (j <= m && machines[j] != 0)
            # Swap
            Tk = machines[j] ; machines[j] = job
            job = Tk
            # Again we push it
            push!(phenotype, job) ; pos = pos + 1
            occurence[job] = occurence[job] + 1
            j = occurence[job]
        end

        if j == m+1
            deleteat!(E,1)
            if machines[m] == job
                machines[m] = 0
            end
        elseif j <= m
            machines[j] = job
        end
    end

    return phenotype
end
