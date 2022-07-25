

print_tree( t ) = println( join( tt( t ), "" ) )

function GrumpsTypes()
    print_tree( Estimator )
    print_tree( Data )
    print_tree( Options )
    print_tree( Sources )
    print_tree( OptimizationOptions )
    print_tree( Variables )
    print_tree( Solution )
    print_tree( GrumpsIntegrators )
    print_tree( GrumpsIntegrator )
    print_tree( NodesWeights )
end
