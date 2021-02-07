using Pkg

packages = [
    "IJulia",
    "Plots",
    "PyPlot"]

for package=packages
    println("installing $package")
    Pkg.add(package)
end

Pkg.update()
Pkg.precompile()