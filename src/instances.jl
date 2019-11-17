#-------------------------------------------------------------------------------
# File: instances.jl
# Description: This files contains the instance sructure.
# Date: November 17, 2019
# Authors: Killian Fretaud, Rémi Garcia,
#-------------------------------------------------------------------------------

mutable struct Instance
    nb_jobs::Int # Nb of jobs
    nb_machines::Int # Nb of machines
    nb_robot::Int # Nb of position on the robot
    travel_times::Array{Int, 1} # t_j is the time taken to travel from j-1 to j
    processing_times::Array{Int, 2} # p_ij is the processing time for the job i on machine j

    Instance(N, M, T, P) = new(N, M, N*(M+1), T, P)
end
