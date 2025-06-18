#!/usr/bin/env julia

using Pkg
Pkg.activate(normpath(@__DIR__))

using RayTracer
using Comonicon
using BenchmarkTools
using Base.Threads

Comonicon.@main function benchmark_raytracer(;
    scenefile::String="examples/demo.txt",
    width::Int=100,
    height::Int=100,
    )
    n_rays=5
    max_depth=5
    russian_roulette_limit=3
    try
        print_welcome()

        #check input name
        RayTracer.check_name(scenefile, [".txt"])
        #---
        println("📊  This script benchmarks performance for single-threaded and multi-threaded comparison")
        if nthreads() == 1
            @info("🧵 Using 1 thread")
        else
            @info("🧵 Using $(nthreads()) threads")
        end
        println("\n📂 Preparing to parse the scene...")

        aspect_ratio = width/height
        
        # no external variables available
        external_variables = Dict{String, Float64}()

        # Parse the scene from text file
        scene = open(scenefile, "r") do io
            instream = RayTracer.InputStream(io, scenefile)
            RayTracer.parse_scene(instream, aspect_ratio; external_variables)
        end
        println("✓ Scene parsing completed.")

        println("🖼️  Setting up the image canvas and camera...")
        # Prepare the canva to draw on
        img = HdrImage(width, height)
        # Prepare the environment made of the canva and the observer
        tracer = ImageTracer(img, scene.camera)
        println("✓ Canvas and camera setup completed.")
        
        println("\n⏱️ Starting ray tracing benchmark(this may take a while)...")
        
        println()
        # RayTracing algorithm that need as input ...
        pcg = PCG()
        f =
            ray -> path_tracer(
                scene.world,
                ray,
                pcg;
                bkg_color = BLACK,
                n_rays = n_rays,
                max_depth = max_depth,
                russian_roulette_limit = russian_roulette_limit,
            )


    # Using $ to interpolate variables inside the @benchmark macro.
    # Macros operate on code expressions, not values, so without $ the macro only sees the variable names.
    # With $, the macro gets the actual variable values, ensuring correct execution.

    # b = @benchmark RayTracer.fire_all_rays!($tracer, $f; progress_flag = false)
    @btime RayTracer.fire_all_rays!($tracer, $f; progress_flag = false)

    # # print the results
    println("📈 Benchmark results:")
    # #BenchmarkTools.print(b)
    # println("Minimum time: $(minimum(b).time / 1e6) ms")
    # println("Median time: $(median(b).time / 1e6) ms")
    # println("Mean time: $(mean(b).time / 1e6) ms")
    catch e
        if isa(e, CustomException)
            println(e)
        else
            rethrow()
        end
    end
end