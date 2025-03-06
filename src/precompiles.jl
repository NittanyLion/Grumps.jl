





# precompile( grumps!, ( GrumpsCheapEstimator, Data{Float64}, OptimizationOptions, nothing, StandardErrorOptions ) )
# precompile( grumps!, ( GrumpsCLEER, Data{Float64}, OptimizationOptions, nothing, StandardErrorOptions ) )
# precompile( grumps!, ( GrumpsGMMEstimator, Data{Float64}, OptimizationOptions, nothing, StandardErrorOptions ) )
# precompile( GrumpsData, ( Symbol, Grumps) )


# precompile( Grumps.GrumopsSources, ( ))
precompile(Tuple{typeof(CSV.parsefilechunk!), CSV.Context, Int64, Int64, Int64, Int64, Array{CSV.Column, 1}, Type{Tuple{}}})
precompile(Tuple{Type{Grumps.GrumpsMacroData{T} where T}, Base.Val{:Grumps}, String, Float64, DataFrames.SubDataFrame{DataFrames.DataFrame, DataFrames.Index, Array{Int64, 1}}, Grumps.GrumpsVariables, Grumps.GrumpsNodesWeights{Float64}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsDataOptions{Float64}, Type{Float64}})
precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsCLEER, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}})
precompile(Tuple{Type{Grumps.GrumpsData{T} where T<:AbstractFloat}, Grumps.GrumpsCLEER, Grumps.GrumpsSources{Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV}, Grumps.GrumpsVariables})
precompile( Grumps.MicroObjectiveθ!, ( Float64, Array{Float64, 1}, Array{Float64, 2}, Array{Float64, 2}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool ) )
precompile( Grumps.MicroObjectiveθ!, ( Float64, Array{Float64, 1}, Nothing, Nothing, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool ) )
precompile( Grumps.MicroObjectiveθ!, ( Float64, Nothing, Nothing, Nothing, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool ) )
precompile( Grumps.MicroObjectiveθ!, ( Float64, Nothing, Array{Float64, 2}, Array{Float64, 2}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool ) )
precompile(Tuple{typeof(Grumps.FillZXθ!), Base.Val{:Grumps}, Array{Float64, 1}, Grumps.GrumpsCLEER, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMicroSpace{Float64}})


precompile(Tuple{typeof(Grumps.grumps!), Grumps.GrumpsCLEER, Grumps.GrumpsData{Float64}})
precompile(Tuple{typeof(Grumps.MacroObjectiveθ!), Float64, Array{Float64, 1}, Array{Float64, 2}, Array{Float64, 2}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsMacroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool})
precompile(Tuple{typeof(Grumps.ObjectiveFunctionθ1!), Grumps.PMLMarketFGH{Float64}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsCLEER, Grumps.GrumpsMarketData{Float64, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMacroDataAnt{Float64}}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMarketSpace{Float64, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsMacroSpace{Float64}}, Bool, Bool, Bool, Int64})
#=  290.8 ms =# precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsCLEER, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}}) # recompile
#=  853.0 ms =# precompile(Tuple{typeof(Grumps.MacroObjectiveδ!), Float64, Array{Float64, 1}, Array{Float64, 2}, Array{Float64, 1}, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsMacroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool})
#=  612.1 ms =# precompile(Tuple{typeof(Grumps.MicroObjectiveδ!), Float64, Array{Float64, 1}, Array{Float64, 2}, Array{Float64, 1}, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool})
#=  238.3 ms =# precompile(Tuple{typeof(Grumps.MacroObjectiveθ!), Float64, Nothing, Array{Float64, 2}, Array{Float64, 2}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsMacroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool})
#=  105.5 ms =# precompile(Tuple{typeof(Grumps.ObjectiveFunctionθ!), Grumps.PMLFGH{Float64}, Float64, Nothing, Nothing, Array{Float64, 1}, Array{Array{Float64, 1}, 1}, Grumps.GrumpsCLEER, Grumps.GrumpsData{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsSpace{Float64, Grumps.GrumpsNoSemaphores}, Array{Float64, 1}, Array{Array{Float64, 1}, 1}})
#=  105.3 ms =# precompile(Tuple{typeof(Grumps.MacroObjectiveθ!), Float64, Array{Float64, 1}, Nothing, Nothing, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsMacroSpace{Float64}, Grumps.GrumpsOptimizationOptions, Int64, Bool})
#=   20.6 ms =# precompile(Tuple{typeof(Grumps.AθZXθ!), Array{Float64, 1}, Grumps.GrumpsCLEER, Grumps.GrumpsMarketData{Float64, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMacroDataAnt{Float64}}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsSpace{Float64, Grumps.GrumpsNoSemaphores}, Int64})
#=   93.4 ms =# precompile(Tuple{typeof(Grumps.Template), Base.Val{:Grumps}, Grumps.GrumpsDataOptions{Float64}, DataFrames.DataFrame, Array{Array{Int64, 1}, 1}})
#=  313.7 ms =# precompile(Tuple{Type{Grumps.GrumpsData{T} where T<:AbstractFloat}, Grumps.GrumpsCheapEstimator, Grumps.GrumpsSources{Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV}, Grumps.GrumpsVariables})
#=  290.4 ms =# precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsCheapEstimator, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}})
#=   67.7 ms =# precompile(Tuple{typeof(Grumps.BalanceZConstants), Grumps.GrumpsMicroDataHog{Float64}, Int64})
#=  581.0 ms =# precompile(Tuple{typeof(Grumps.grumps!), Grumps.GrumpsCheapEstimator, Grumps.GrumpsData{Float64}})
#=  364.8 ms =# precompile(Tuple{typeof(Grumps.FillAθ!), Base.Val{:Grumps}, Array{Float64, 1}, Grumps.GrumpsCheapEstimator, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMacroSpace{Float64}})
#=   20.4 ms =# precompile(Tuple{typeof(Grumps.FillZXθ!), Base.Val{:Grumps}, Array{Float64, 1}, Grumps.GrumpsCheapEstimator, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMicroSpace{Float64}})
#=  189.6 ms =# precompile(Tuple{typeof(Grumps.grumpsδ!), Grumps.GrumpsSingleFGH{Float64}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsCheapEstimator, Grumps.GrumpsMarketData{Float64, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMacroDataAnt{Float64}}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMarketSpace{Float64, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsMacroSpace{Float64}}, Int64})
#=   82.4 ms =# precompile(Tuple{typeof(Grumps.Bread), Grumps.GrumpsCheapEstimator, Base.Val{:θ}, Base.Val{:δ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=   67.3 ms =# precompile(Tuple{typeof(Grumps.VarEst), Grumps.GrumpsCheapEstimator, Base.Val{:β}, Base.Val{:β}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=  150.8 ms =# precompile(Tuple{Type{Grumps.GrumpsData{T} where T<:AbstractFloat}, Grumps.GrumpsCLEER, Grumps.GrumpsSources{Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV}, Grumps.GrumpsVariables}) # recompile
#=  286.9 ms =# precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsCLEER, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}}) # recompile
#=  229.1 ms =# precompile(Tuple{typeof(Grumps.grumps!), Grumps.GrumpsCLEER, Grumps.GrumpsData{Float64}}) # recompile
#=  106.9 ms =# precompile(Tuple{typeof(Grumps.ObjectiveFunctionθ!), Grumps.PMLFGH{Float64}, Float64, Nothing, Nothing, Array{Float64, 1}, Array{Array{Float64, 1}, 1}, Grumps.GrumpsCLEER, Grumps.GrumpsData{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsSpace{Float64, Grumps.GrumpsNoSemaphores}, Array{Float64, 1}, Array{Array{Float64, 1}, 1}}) # recompile
#=   50.9 ms =# precompile(Tuple{typeof(Grumps.VarEst), Grumps.GrumpsCLEER, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    2.2 ms =# precompile(Tuple{typeof(Grumps.Bread), Grumps.GrumpsCLEER, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    2.0 ms =# precompile(Tuple{typeof(Grumps.Meat), Grumps.GrumpsCLEER, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=   16.7 ms =# precompile(Tuple{typeof(Grumps.Bread), Grumps.GrumpsCLEER, Base.Val{:θ}, Base.Val{:δ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    3.2 ms =# precompile(Tuple{typeof(Grumps.Meat), Grumps.GrumpsCLEER, Base.Val{:δ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    3.5 ms =# precompile(Tuple{typeof(Grumps.Meat), Grumps.GrumpsCLEER, Base.Val{:θ}, Base.Val{:δ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    5.6 ms =# precompile(Tuple{typeof(Grumps.Meat), Grumps.GrumpsCLEER, Base.Val{:δ}, Base.Val{:δ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=   69.6 ms =# precompile(Tuple{typeof(Grumps.VarEst), Grumps.GrumpsCLEER, Base.Val{:β}, Base.Val{:β}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=  271.5 ms =# precompile(Tuple{Type{Grumps.GrumpsData{T} where T<:AbstractFloat}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsSources{Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV}, Grumps.GrumpsVariables})
#=  288.9 ms =# precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}})
#=  168.7 ms =# precompile(Tuple{typeof(Grumps.grumps!), Grumps.GrumpsMDLEEstimator, Grumps.GrumpsData{Float64}})
#=   76.0 ms =# precompile(Tuple{typeof(Grumps.ObjectiveFunctionθ1!), Grumps.GrumpsMarketFGH{Float64}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsMarketData{Float64, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMacroDataAnt{Float64}}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsSpace{Float64, Grumps.GrumpsNoSemaphores}, Bool, Bool, Bool, Int64})
#=   12.7 ms =# precompile(Tuple{typeof(Grumps.FillAθ!), Base.Val{:Grumps}, Array{Float64, 1}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsMacroDataAnt{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMacroSpace{Float64}})
#=   20.1 ms =# precompile(Tuple{typeof(Grumps.FillZXθ!), Base.Val{:Grumps}, Array{Float64, 1}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMicroSpace{Float64}})
#=  190.8 ms =# precompile(Tuple{typeof(Grumps.grumpsδ!), Grumps.GrumpsSingleFGH{Float64}, Array{Float64, 1}, Array{Float64, 1}, Grumps.GrumpsMDLEEstimator, Grumps.GrumpsMarketData{Float64, Grumps.GrumpsMicroDataHog{Float64}, Grumps.GrumpsMacroDataAnt{Float64}}, Grumps.GrumpsOptimizationOptions, Grumps.GrumpsMarketSpace{Float64, Grumps.GrumpsMicroSpace{Float64}, Grumps.GrumpsMacroSpace{Float64}}, Int64})
#=   66.2 ms =# precompile(Tuple{typeof(Grumps.VarEst), Grumps.GrumpsMDLEEstimator, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    2.2 ms =# precompile(Tuple{typeof(Grumps.Bread), Grumps.GrumpsMDLEEstimator, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=    2.0 ms =# precompile(Tuple{typeof(Grumps.Meat), Grumps.GrumpsMDLEEstimator, Base.Val{:θ}, Base.Val{:θ}, Int64, Int64, Grumps.GrumpsIngredients{Float64}})
#=  277.2 ms =# precompile(Tuple{Type{Grumps.GrumpsData{T} where T<:AbstractFloat}, Grumps.GrumpsMixedLogitEstimator, Grumps.GrumpsSources{Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV, Grumps.SourceFileCSV}, Grumps.GrumpsVariables})
#=  287.1 ms =# precompile(Tuple{Type{Grumps.GrumpsPLMData{T} where T<:AbstractFloat}, Base.Val{:Grumps}, Grumps.GrumpsMixedLogitEstimator, Grumps.GrumpsSources{DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame, DataFrames.DataFrame}, Grumps.GrumpsVariables, Array{Array{Int64, 1}, 1}, Bool, LinearAlgebra.UniformScaling{Float64}, SparseArrays.SparseMatrixCSC{Bool, Int64}})
#=  432.7 ms =# precompile(Tuple{typeof(Grumps.grumps!), Grumps.GrumpsMixedLogitEstimator, Grumps.GrumpsData{Float64}})
