#-------------------------------------------------------------------------------
# File: data.jl
# Description: This files contains data that is used for experiment.
# Date: November 17, 2019
# Authors: Killian Fretaud, Rémi Garcia,
#-------------------------------------------------------------------------------

"""
    data()

Return 2 lists of instances used for tests. The second list has a constant
travel time.
"""
function data()
    P2_2 = [1 4; 3 2]
    P2_3 = [1 4 2; 3 2 1]
    P3_3 = [1 4 2; 3 2 1; 6 2 1]
    P4_4 = [6 1 2 3; 2 3 2 1; 4 6 2 1; 5 3 2 3]
    P4_5 = [6 1 2 3 2; 2 3 5 2 1; 4 6 3 2 1; 4 5 3 2 3]
    P4_5_bis = [1 1 1 1 1; 2 4 5 1 2; 2 6 1 2 3; 1 2 2 1 2]

    T2 = [2, 3, 1]
    T3 = [1, 1, 2, 1]
    T4 = [2, 3, 1, 5, 1]
    T5 = [2, 3, 1, 5, 1, 1]
    T5_bis = [3, 1, 2, 1, 1, 3]

    list_instances = [
        Instance(2, 2, T2, P2_2),
        Instance(2, 3, T3, P2_3),
        Instance(3, 3, T3, P3_3),
        Instance(4, 4, T4, P4_4)
        #Instance(4, 5, T5, P4_5),
        #Instance(4, 5, T5_bis, P4_5_bis)
    ]

    list_instances_equi = [
        Instance(2, 2, ones(Int, 3), P2_2),
        Instance(2, 3, ones(Int, 4), P2_3),
        Instance(3, 3, ones(Int, 4), P3_3),
        Instance(4, 4, ones(Int, 5), P4_4)
    #    Instance(4, 5, ones(Int, 5), P4_5),
    #    Instance(4, 5, ones(Int, 5), P4_5_bis)
    ]

    println("\n***** Instances loaded *****\n")

    return list_instances, list_instances_equi
end
