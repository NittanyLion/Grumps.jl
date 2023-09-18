

function Heigen( H :: VMatrix{T} ) where {T<:Flt}
    M = length( H )
    H_eig = Vector{ Eigen{T, T, Matrix{T}, Vector{T} } }(undef, M)
    @threads :dynamic for m ∈ 1:M
        H_eig[m] = eigen( Symmetric( H[m] ) )
        for j ∈ eachindex( H_eig[m].values )
            H_eig[m].values[j] ≥ zero( T ) && break
            H_eig[m].values[j] = zero( T )
        end
    end
    H_eig
end


function HeigenQgQK( H :: VMatrix{T}, G, K:: Vector{  <: AbstractMatrix{T} }  ) where {T<:Flt}
    M = length( H )
    H_eig = Heigen( H )
    QG = Vector{ Array{T, min( size(G[1],2), 2 ) } }( undef, M )
    QK = Vector{ Matrix{T} }( undef, M )
    vectors = [ H_eig[m].vectors for m ∈ 1:M ]
    values = [ H_eig[m].values for m ∈ 1:M ]
    @threads :dynamic for m ∈ 1:M
        QG[m] = vectors[m]' * G[m]
        QK[m] = vectors[m]' * K[m]
    end
    vectors, values, QG, QK
end







function ntr_find_direction!( p :: VVector{ T },  Qg :: VVector{T}, QK :: VMatrix{T}, values::VVector{T},  vectors::VMatrix{T}, λ :: T, Z::VMatrix{T} ) where {T<:Flt}
    M = length( p )
    @ensure  λ ≥ 0.0 "something went wrong in the algorithm; λ should be nonnegative"
    cols_k = size( QK[1], 2 )
    @ensure cols_k > 0 "something went wrong in the algorithm cols_k should be positive, but it is $(cols_k);  size of QK[1] is $(size(QK[1]))"
    J = [ length( p[m] ) for m ∈ 1:M ]
    A = zeros(T, cols_k, cols_k )
    for m ∈ 1:M
        for j ∈ 1:J[m]
            for i ∈ 1:cols_k
                for t ∈ 1:cols_k
                    A[i,t] += QK[m][j,i] * QK[m][j,t] / ( λ + values[m][j] )
                end
            end
        end
    end
    A += I
    C = cholesky( Symmetric( A ); check = false )
    for m ∈ 1:M
         Z[m] .=  C.U' \ ( QK[m]' ) 
    end
    r = zeros( T, cols_k )
    for m ∈ 1:M
        for j ∈ 1:J[m]
            for i ∈ 1:cols_k
                r[i] += Z[m][i,j] * Qg[m][j] / ( λ + values[m][j] )
            end
        end
    end
    @threads :dynamic for m ∈ 1:M
        p[m] .= T(0.0)
        for j ∈ 1:J[m]
            mult = ( Qg[m][j] - sum( Z[m][t,j] * r[t] for t ∈ 1:cols_k ) ) / ( λ + values[m][j] )
            for i ∈ 1:J[m]
                p[m][i] -= vectors[m][i,j] * mult
            end
        end
    end
    p
end 

@todo 2 "REMOVE DUPLICATION WITH PREVIOUS FUNCTION"

function ntr_find_direction(  P :: VMatrix{ T },  QG :: VMatrix{T}, QK :: VMatrix{T}, values::VVector{T},  vectors::VMatrix{T}, λ :: T, Z::VMatrix{T} ) where {T<:Flt}
    M = length( P )
    λ ≥ 0.0 || println( λ )
    @assert( λ ≥ 0.0 )
    cols_k = size( QK[1], 2 )
    J = [ size( P[m], 1 ) for m ∈ 1:M ]
    A = zeros(T, cols_k, cols_k )
    for m ∈ 1:M
        for j ∈ 1:J[m]
            for i ∈ 1:cols_k
                for t ∈ 1:cols_k
                    A[i,t] += QK[m][j,i] * QK[m][j,t] / ( λ + values[m][j] )
                end
            end
        end
    end
    A += I
    C = cholesky( Symmetric( A ); check = false )
    for m ∈ 1:M
         Z[m] .=  C.U' \ ( QK[m]' ) 
    end
    cols_g = size( QG[1], 2 )
    R = zeros( T, cols_k, cols_g )
    for m ∈ 1:M
        for j ∈ 1:J[m]
            for i ∈ 1:cols_k
                R[i,:] += Z[m][i,j] * QG[m][j,:] / ( λ + values[m][j] )
            end
        end
    end
    @threads :dynamic for m ∈ 1:M
        P[m] .= T(0.0)
        for j ∈ 1:J[m]
            local mult = [ ( QG[m][j,i] - sum( Z[m][t,j] * R[t,i] for t ∈ 1:cols_k ) ) / ( λ + values[m][j] ) for i ∈ 1:cols_g ]
            for i ∈ 1:J[m]
                P[m][i,:] -= vectors[m][i,j] * mult
            end
        end
    end
    P
end 





#==
Returns a tuple of initial safeguarding values for λ. Newton's method might not
work well without these safeguards when the Hessian is not positive definite.
==#
function initial_safeguards(H, gr, Δ, K, λ, plmspace::PLMSpace{T} ) where {T<:Flt}
    # equations are on p. 560 of [MORESORENSEN]
    M = length( K );  cols_k = size( K[1], 2 )
    # they state on the first page that ||⋅|| is the Euclidean norm
    dδ = [ size( K[m], 1 ) for m ∈ 1:M ]
    som = plmspace.som
    function computesom( left, right, U )
        for m ∈ left:right
            for c ∈ 1:dδ[m]
                som[m][c] = zero(T)
                for r ∈ 1:dδ[m]
                    som[m][c] += abs( H[m][r,c] + sum( K[m][r,j] * K[m][c,j] for j ∈ 1:cols_k ) )
                end
                for mm ∈ 1:M
                    m == mm && continue
                    for r ∈ 1:dδ[mm]
                        som[m][c] += abs( sum( K[mm][r,j] * K[m][c,j] for j ∈ 1:cols_k ) )
                    end
                end
            end
        end
    end
    binaryrun( computesom, 1, M, 1, nothing )
    Hnorm = maximum( maximum( som[m] ) for m ∈ 1:M )
    gr_norm = sqrt( grumps_dot( gr, gr ) )       
    λL = max( zero(T), gr_norm / Δ - Hnorm)
    λU = gr_norm / Δ + Hnorm
    λS = zero(T)
    λ = min( max(λ, λL), λU )
    if λ ≤ λS
        λ = max( T(1) /1000*λU, sqrt(λL*λU) )
    end
    λ
end


function ntr_m( H::VMatrix{T}, gr::VVector{T}, x :: VVector{T}, s::VVector{T}, K :: VMatrix{T} ) where {T<:Flt}
    mval = zero( T )
    for m ∈ eachindex( s )
        mval += dot( gr[m], s[m] ) + T(0.5) * dot( s[m], H[m] * s[m] )
    end
    Ks  = sum( K[m]' * s[m] for m ∈ eachindex( s ) )
    mval += T(0.5) * dot( Ks, Ks ) 
    mval
end




function ntr_solve_subproblem( 
    gr              :: VVector{ T },        # full gradient
    H               :: VMatrix{T},          # Hessian 
    K               :: VMatrix{T},          # K matrices
    Δ               :: T,                   # NTR Δ
    s               :: VVector{T},          # direction
    x               :: VVector{T},          # current x
    plmspace        :: PLMSpace{T};         # space
    tolerance = 1.0e-10,                    # tolerance
    max_iters = 5                           # maximum number of subproblem iterations
    ) where {T<:Flt}

    M = length( H )
    !grumps_isfinite( H ) && return T(Inf), false, zero(T), false, false

    ( vectors, values, Qg, QK ) = HeigenQgQK( H, gr, K )

    min_H_ev, max_H_ev = minmax( values )


    if min_H_ev ≥ 1.0e-8
        ntr_find_direction!( s, Qg, QK, values, vectors, zero(T), plmspace.Z )
        if dot(s,s) ≤ Δ^2 
            return ntr_m( H, gr, x, s, K ), true, zero(T), false, true
        end
    end

    λlb = T( 0.0 )
    λ = initial_safeguards( H, gr, Δ, K, zero( T ), plmspace )

    # Algorithim 4.3 of N&W (2006)

    reached_solution = false
    Qs = [ similar( Qg[m] )  for m ∈ 1:M ]    
    for iter ∈ 1:max_iters
        λ_previous = λ

        ntr_find_direction!( s, Qg, QK, values, vectors, λ, plmspace.Z  )
        ss = deepcopy( s )
        for m ∈ 1:M
            Qs[m][:] = vectors[m]' * s[m]  
        end

        ntr_find_direction!( ss, Qs, QK, values, vectors, λ, plmspace.Z )
        norm2_s = grumps_dot( s, s )
        λ_update = ( norm2_s / abs( grumps_dot( s, ss ) ) ) * ( sqrt( norm2_s ) - Δ ) /  Δ 
        λ += λ_update
        if λ < λlb
            λ = max( 0.5 * ( λ_previous + λlb ), λlb )
        end

        if abs(λ - λ_previous) < tolerance
            reached_solution = true
            break
        end
    end

    return ntr_m( H, gr, x, s, K ), false, λ, reached_solution
end


function fulladd!( y, x )
    for i ∈ eachindex( x )
        y[i][:] += x[i]
    end
end

function fulldiff( y, x )
    [ y[i] - x[i] for i ∈ eachindex(y) ]
end




function ntr_update_state!( ntr :: NTR{T}, state :: NTRState{T}, method :: NTRMethod{T}, plmspace :: PLMSpace{T} ) where {T<:Flt}
    # fine the next step direction
    ( ℳ, state.interior, state.λ, state.reached_subproblem_solution ) = 
            ntr_solve_subproblem( gradient( ntr ), hessian( ntr ), ntr.K, state.Δ, state.s, state.x, plmspace )

    # maintain a record of the previous position
    deepcopyto!( state.x_previous, state.x )
    state.f_x_previous = value( ntr )

    # update the function value and gradient
    fulladd!( state.x, state.s )
    deepcopyto!( state.g_previous, gradient( ntr ) )
    value_gradient!( ntr, state.x )         

    # update the trust region size (algorithm 4.1 in N&W 2006)
    f_x_diff = state.f_x_previous - value( ntr )
    state.ρ = ( abs( ℳ ) ≤ eps( T ) ) ?  1.0 : ( ( ℳ > 0 ) ? -1.0 : f_x_diff / ( 0 - ℳ ) )

    if state.ρ < method.ρ_lower
        # @info "ρ less than lower bound, reducing Δ"
        state.Δ *= 0.25
    elseif state.ρ > method.ρ_upper && !state.interior
        # @info "ρ above upper and not in the interior "
        state.Δ = min( 2 * state.Δ, method.Δhat )
    else
        # @info "default situation"
    end

    if state.ρ ≤ state.η
        # The improvement is too small and we won't take it.
        # If you reject an interior solution, make sure that the next
        # delta is smaller than the current step. Otherwise you waste
        # steps reducing delta by constant factors while each solution
        # will be the same.
        x_diff = fulldiff( state.x, state.x_previous )
        state.Δ = 0.25 * norm( vcat( x_diff... ) )    

        ntr.F = state.f_x_previous
        deepcopyto!( state.x, state.x_previous )
        deepcopyto!( ntr.DF, state.g_previous )
        deepcopyto!( ntr.x_df, state.x_previous )
    else
        hessian!( ntr, state.x )
    end

    nothing
end




function ntr_loss( x )
    y = vcat( x... )
    maximum( abs.( y ) )
end


function ntr_assess_convergence( state::NTRState{T}, ntr::NTR{T}, options::NTROptions{T} ) where {T<:Flt}
    if state.ρ ≤ state.η 
        # @info "ρ less than η   $(state.ρ) ≤ $(state.η)"
        return false, false, false, false
    end
    # Accept the point and check convergence
    x_converged = ( ntr_loss( fulldiff( state.x, state.x_previous ) )  ≤ options.x_abs_tol ) 
    f_converged = ( abs( value( ntr ) - state.f_x_previous ) ≤ options.f_rel_tol * abs( value( ntr ) ) )
    f_increased = ( value( ntr ) > state.f_x_previous )
    g_converged = ( ntr_loss( gradient( ntr ) ) ≤ options.g_abs_tol )
    # printstyled("convergence measures:\n"; color = :green)
    # println( "xloss = ", ntr_loss( fulldiff( state.x, state.x_previous ) ) )
    # println( "floss = ", abs( value( ntr ) - state.f_x_previous ) )
    # println( "gloss = ", ntr_loss( gradient( ntr ) ) )
    return x_converged, f_converged, g_converged, f_increased
end


function ntr_initial_state( method :: NTRMethod{T}, ntr :: NTR{T}, initial_x :: VVector{ T } ) where { T<: Flt }
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

    value_gradient_hessian!!( ntr, initial_x )

    return NTRState( 
        deepcopy( initial_x ),
        deepcopy( initial_x ),
        T(Inf),
        deepcopy( gradient( ntr ) ),
        deepcopy( gradient( ntr ) ),
        T( Δ ),
        zero( T ),
        λ,
        T( method.η ),
        interior,
        reached_subproblem_solution
        )
end







function ntr_trace!( tr::NTRTrace{T}, ntr::NTR{T}, state::NTRState{T}, iteration::Int, method::NTRMethod{T}, options::NTROptions{T}, curr_time=time() ) where {T<:Flt}
    dt = Dict()
    dt["time"] = curr_time - tr.starttime
    if options.extended_trace
        dt["x"] = deepcopy( state.x )
        dt["g(x)"] = deepcopy( gradient(ntr) )
        dt["h(x)"] = deepcopy( hessian(ntr) )
        dt["delta"] = state.Δ
        dt["interior"] = state.interior
        dt["hard case"] = false
        dt["reached_subproblem_solution"] = state.reached_subproblem_solution
        dt["lambda"] = state.λ
    end
    g_norm = ntr_loss( gradient( ntr ) )
    ntr_update_trace!(tr, iteration, value( ntr ), state.x, g_norm, dt )
end





# function ntr_best!( ntr :: NTR{T}, best :: NTRFGH{T} ) where {T<:Flt}
#     ntr.F ≤ best.f || return
#     best.f = ntr.F
#     best.g[:] = vcat( gradient( ntr )... )
#     best.H[:,:] = hessian( ntr )
#     best.x[:] = vcat( ntr.x_f... )
#     nothing
# end


@todo 4 "must check ntr_best! for bugs"


function ntr_best!( ntr :: NTR{T}, best :: PMLFGH{T} ) where {T<:Flt}
    ntr.F ≤ best.F[1] || return
    best.F[1] = ntr.F
    gr = gradient( ntr )
    H = hessian( ntr )
    for m ∈ eachindex( best.market )
        copyto!( best.market[m].inside.Gδ, gr[m] )
        copyto!( best.market[m].inside.Hδδ, H[m] )
        copyto!( best.market[m].δ, ntr.x_f[m] )
    end
    return nothing
end

@todo 4 "must rewrite ntr_result!"

function ntr_result!( best :: PMLFGH{T}, status :: Symbol ) where {T<:Flt}
    # best.status = status
    # best
end

