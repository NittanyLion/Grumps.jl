




ComputeFugly( A, B, Λ ) = sum( A[k,:] * B[k,:]' /  Λ[k] for k ∈ eachindex( Λ ) )

function CombineToFormp!( p, Q, Qᵀg, QᵀK, Λ, r )
    p[:] = - ComputeFugly( Q, Qᵀg, Λ ) + ComputeFugly( Q, QᵀK * r, Λ )
end

# equation (4.38) in Nocedahl and Wright
function DetermineDirection!( p, λ, Q, Qᵀg, QᵀK, Λ )
    for m ∈ eachindex( Λ )
        Λ[m] .+= λ                                                                                # ridgefy
    end
    V = inv( ThreadsX.mapreduce( (x,y,z)-> ComputeFugly( x, y, z ), +, QᵀK, QᵀK, Λ ) + I )    # (I + K'H^{-1}K)^{-1}
    r = V * ThreadsX.mapreduce( (x,y,z) -> ComputeFugly( x, y, z ), +, QᵀK, Qᵀg, Λ  )         # (I + K'H^{-1}K)^{-1} K'H^{-1}g
    ThreadsX.map( (a,b,c,d,e) -> CombineToFormp!( a, b, c, d, e, r ), p, Q, Qᵀg, QᵀK, Λ )    # -Hʳ^{-1} g
    return p
end


function Computem( g, H, K, p )
    mval = ThreadsX.mapreduce( (x,y,z) -> dot( x, z ) + 0.5 * dot( z, y * z ), +, g, H, p )
    Kˢ = sum( K[m]' * p[m] for m ∈ eachindex( p ) )
    return mval + T(0.5) * dot( Kˢ, Kˢ )
end



function CholeskyOfRidge!( Hʳ, H, λ )
    for i ∈ axes( Hʳ, 1 )
        Hʳ[i,i] = H[i,i] + λ
    end
    return cholesky( Hermitian( Hʳ); check = false )
end


function Assign_to_p!( p, R, y, z )
    p .= R \ ( y - z )
    return p
end

q22sum( Rⱽ, A, Rp ) = sum( abs, Rⱽ' * A' * Rp )

import LinearAlgebra.norm

norm( v :: VVector{T} ) where {T<:Flt} = sqrt( sum( sum.( abs2, g ) ) )

function Newter_initial_safeguards( g :: VVector{T}, H :: VMatrix{T}, Δ, λ ) where {T<:Flt}
    λˢ = ThreadsX.mapreduce( x->maximum( -diag( x ) ), maximum, H )
    g_norm = norm( g ) 
    H_norm = sum( sum.( abs, H ) )
    λ̲ = max( zero( T ), λˢ, g_norm / Δ - H_norm )
    λ̄ = g_norm / Δ + H_norm
    λ = min( max( λ, λ̲ ), λ̄ )
    λ > λˢ && return λ
    return max( one( T ) * 0.001 * λ̄, sqrt( λ̄ * λ̲ ) )
end


function Newter_SolveSubproblem!(
    p :: VVector{ T };          # storage for direction vectors
    g :: VVector{ T },          # complete gradient (include PLM portion)
    H :: VMatrix{ T },          # Likelihood hessian 
    K :: VMatrix{ T },          # Likelihood K
    Δ :: T,                     # trust region size
    τ = 1e-10,                  # tolerance
    I⁺ = 5                      # maximum number of iterations
    ) where {T <: Flt}

    @info "solving subproblem"

    𝓂, interior, λ, 💼, 🍾 = T( Inf ), false, zero( T ), false, false

    failure = 𝓂, interior, λ, 💼, 🍾
    Δ² = Δ^2

    Hsym = Symmetric.( H )
    any( any.(!isfinite, Hsym) ) && return failure
    Heig = ThreadsX.map( x->eigen( x ), Hsym )

    any( map( x->isempty( x.values ), Heig ) ) &&  return failure
    Λ = ThreadsX.map( x->x.values, Heig )      
    Q = ThreadsX.map( x->x.vectors, Heig )
    minHev = minimum( minimum.( Λ ) )
    maxHev = maximum( maximum.( Λ ) )


    Hʳ = copy( H )

    Qᵀg = ThreadsX.map( (x,y)->x' * y, Q, g )
    QᵀK = ThreadsX.map( (x,y)->x' * y, Q, K )
              # vector of all eigenvalues of H

    # check if the unconstrained solution works
    if minHev ≥ 1e-8 
        DetermineDirection!( p, zero(T), Q, Qᵀg, QᵀK, Λ )
        sum( sum.(abs2, p) ) ≤ Δ² && return Computem( g, H, K, p ), true, λ, 💼, true 
    end

    @ensure minHev ≥ zero( T ) "hard case not programmed up"

    λ̲ = nextfloat( -minHev )
    λ = Newter_initial_safeguards( g, H, Δ, λ )

    interior = 🍾 = false
    for 𝒾 ∈ 1:I⁺
        @debug "$𝒾 $λ"
        λ⁻ = λ
        𝒞  = ThreadsX.map( (x,y)->CholeskyOfRidge!( x, y, λ ), Hʳ, H )
        if !all( issuccess.( 𝒞 ) )
            λ *= 2.0
            continue
        end

        R = [ C.U for C ∈ 𝒞 ]
        A = ThreadsX.map( (x,y)->x'\y, R, K )
        s = ThreadsX.map( (x,y)->x'\y, R, g )
        V = inv( ThreadsX.mapreduce( x-> x'x, +, A ) + I )
        r = ThreadsX.mapreduce( (X,y) -> X' * y, A, s )
        ThreadsX.map( (x,Y,z,a) -> Assign_to_p!( x, Y, z, a ), p, R, s, r )
        p2 = sum( sum.( abs2, p ) )
        Rⱽ = cholesky( V ).U 
        Rp = ThreadsX.map( (R,p) -> R'\p, R, p )
        q₁² = sum( sum.( abs2, Rp ) )
        q₂² = ThreadsX.mapreduce( (A,Rp) -> q22sum( Rⱽ,A, Rp ), +, A, Rp )
        q2 = q₁² + q₂²
        λ⁺ = p2 * ( sqrt(p2) - Δ ) / ( Δ * q2 )
        λ += λ⁺

        λ < λ̲ && (  λ = 0.5 * ( λ₋ - λ̲ ) + λ̲ )

        if abs( λ - λ₋ ) < τ
            🍾 = true
            return Computem( g, H, K, p ), false, λ, 💼, true 
        end
    end

    return Computem( g, H, K, p ), false, λ, 💼, false
end


NewterLoss( state, f = abs2 ) =  mapreduce( state->sum( f, state.x - state.x_previous ), +, state )
    

function NewterUpdateState!( newt :: Newter{T}, state :: NewterState{T}, method :: NewterMethod{T} ) where {T<:Flt}
    # fine the next step direction
    ( ℳ, state.interior, state.λ, state.reached_subproblem_solution ) = 
    Newter_SolveSubproblem!( state.p, gradient( newt ), Hessian( newt ), Kmat( newt ), state.Δ )

    # maintain a record of the previous position
    deepcopyto!( state.x_previous, state.x )
    state.f_x_previous = value( newt )

    # update the function value and gradient
    map!( x->x+y, state.x, state.x, state.s )
    deepcopyto!( state.g_previous, gradient( newt ) )
    value_gradient!( newt, state.x )         

    # update the trust region size (algorithm 4.1 in N&W 2006)
    f_x_diff = state.f_x_previous - value( newt )
    state.ρ = ( abs( ℳ ) ≤ eps( T ) ) ?  one( T ) : ( ( ℳ > 0 ) ? -one(T) : f_x_diff / ( 0 - ℳ ) )

    if state.ρ < method.ρ̲
        # @info "ρ less than lower bound, reducing Δ"
        state.Δ *= 0.25
    elseif state.ρ > method.ρ̄ && !state.interior
        # @info "ρ above upper and not in the interior "
        state.Δ = min( 2 * state.Δ, method.Δ̂ )
    else
        # @info "default situation"
    end

    if state.ρ ≤ state.η
        # The improvement is too small and we won't take it.
        # If you reject an interior solution, make sure that the next
        # delta is smaller than the current step. Otherwise you waste
        # steps reducing delta by constant factors while each solution
        # will be the same.
        state.Δ = 0.25 * sqrt( NewterLoss( state) )

        newt.F = state.f_x_previous
        deepcopyto!( state.x, state.x_previous )
        deepcopyto!( newt.DF, state.g_previous )
        deepcopyto!( newt.x_df, state.x_previous )
    else
        hessian!( newt, state.x )
    end

    return nothing
end





function NewterAssessConvergence( state::NewterState{T}, newt::Newter{T}, options::NewterOptions{T} ) where {T<:Flt}
    state.ρ ≤ state.η && return false, false, false, false
    # Accept the point and check convergence
    x_converged = ( NewterLoss( state, abs ) ≤ options.x_abs_tol ) 
    f_converged = ( abs( value( newt ) - state.f_x_previous ) ≤ options.f_rel_tol * abs( value( newt ) ) )
    f_increased = ( value( newt ) > state.f_x_previous )
    g_converged = ( sum( sum.( abs, gradient( newt ) ) )  ≤ options.g_abs_tol )
    return x_converged, f_converged, g_converged, f_increased
end



function NewterInitialState( method :: NewterMethod{T}, newt :: Newter{T}, initial_x :: VVector{ T } ) where { T<: Flt }
    n = length(initial_x)
    # Maintain current gradient in gr
    @assert( method.Δhat > 0, "Δhat must be strictly positive" )
    @assert( 0 < method.initial_Δ < method.Δhat, "Δ must be in (0, Δhat)")
    @assert(0 <= method.η < method.ρ_lower, "η must be in [0, ρ_lower)")
    @assert(method.ρ_lower < method.ρ_upper, "must have ρ_lower < ρ_upper")
    @assert(method.ρ_lower ≥ 0.)
    # Keep track of trust region sizes
    Δ = method.initial_Δ

    # Record attributes of the subproblem in the trace.
    reached_subproblem_solution = true
    interior = true
    λ = T( NaN )

    value_gradient_hessian!!( newt, initial_x )

    return NewterState( 
        deepcopy( initial_x ),
        deepcopy( initial_x ),
        T(Inf),
        deepcopy( gradient( newt ) ),
        deepcopy( gradient( newt ) ),
        T( Δ ),
        zero( T ),
        λ,
        T( method.η ),
        interior,
        reached_subproblem_solution
        )
end


function NewterTrace!( tr::NewterTrace{T}, newt::Newter{T}, state::NewterState{T}, iteration::Int, method::NewterMethod{T}, options::NewterOptions{T}, curr_time=time() ) where {T<:Flt}
    dt = Dict()
    dt["time"] = curr_time - tr.starttime
    if options.extended_trace
        dt["x"] = deepcopy( state.x )
        dt["g(x)"] = deepcopy( gradient(newt) )
        dt["h(x)"] = deepcopy( hessian(newt) )
        dt["delta"] = state.Δ
        dt["interior"] = state.interior
        dt["hard case"] = false
        dt["reached_subproblem_solution"] = state.reached_subproblem_solution
        dt["lambda"] = state.λ
    end
    g_norm = ntr_loss( gradient( newt ) )
    NewterUpdateState!(tr, iteration, value( newt ), state.x, g_norm, dt )
end





function NewterBest!( newt :: Newter{T}, best :: PMLFGH{T} ) where {T<:Flt}
    newt.F ≤ best.F[1] || return
    best.F[1] = ntr.F
    g = gradient( ntr )
    H = hessian( ntr )
    for m ∈ eachindex( best.market )
        copyto!( best.market[m].inside.Gδ, g[m] )
        copyto!( best.market[m].inside.Hδδ, H[m] )
        copyto!( best.market[m].δ, ntr.x_f[m] )
    end
    return nothing
end
