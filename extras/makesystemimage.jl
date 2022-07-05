using PackageCompiler


PackageCompiler.create_sysimage([:FastGaussQuadrature, :CSV, :DataFrames]; sysimage_path="image.so", precompile_execution_file="precompile.jl")

