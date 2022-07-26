
IsCompatible( :: Estimator, :: DefaultMicroIntegrator ) = true
IsCompatible( :: Estimator, :: DefaultMacroIntegrator ) = true
IsCompatible( :: Estimator, :: GrumpsIntegrator ) = false
IsCompatible( :: DefaultMicroIntegrator, :: Val{:Hog} ) = true
IsCompatible( :: DefaultMicroIntegrator, :: Val{:Ant} ) = true
IsCompatible( :: DefaultMacroIntegrator, :: Val{:Hog} ) = true
IsCompatible( :: DefaultMacroIntegrator, :: Val{:Ant} ) = true
IsCompatible( :: MSMMicroIntegrator, :: Val{:Hog} ) = true
IsCompatible( :: GrumpsIntegrator, :: Val ) = false

function CheckCompatible( e :: Estimator, i :: BothIntegrators, options :: DataOptions )
    for im ∈ [ microintegrator(i), macrointegrator(i) ]
        @ensure IsCompatible( e, im ) "integrator type $im is incompatible with estimator type $e"
    end
    for mm ∈ [ micromode( options ) ]
        @ensure IsCompatible( microintegrator( i ), Val( mm ) ) "integrator type $i is incompatible with memory mode $mm"
    end
    for mm ∈ [ macromode( options ) ]
        @ensure IsCompatible( macrointegrator( i ), Val( mm ) ) "integrator type $i is incompatible with memory mode $mm"
    end
    return nothing
end