using Revise
using Pkg
Pkg.activate(normpath(@__DIR__))

using RayTracer
using Comonicon
using Dates

"""
Path tracer command to render a scene.

Each execution produces two output images:
- a high dynamic range `.pfm` file
- a tone-mapped image (`.png`, `.jpeg`, or `.tif`)

Both are saved in the `render/` folder. The tone-mapped image is generated using a basic built-in tone mapping, which may not produce optimal results for all scenes.  
For higher-quality control, load the `.pfm` file and apply a custom tone mapping using the `tonemapping` function.

Note: Rendering and producing the `.pfm` file can be time-consuming.

# Args

- `scene_file`: Path to the scene description file (String).
- `width`: Width of the output image (Integer).
- `height`: Height of the output image (Integer).

# Options

- `--output-name=<String>`: Base name for the output image files (without extension).  
  If not provided, a timestamped name like `render_2025-06-07_135023` will be used.  
  Output files will be saved as `render/<name>.<ext>` and `render/<name>.pfm`.

- `--extension=<String>`: File format for the tone-mapped image (`png`, `jpeg`, or `tif`). Default: `png`.

- `--n-rays=<Integer>`: Number of rays per pixel (default: `5`).
- `--max-depth=<Integer>`: Maximum ray recursion depth (default: `5`).
- `--russian-roulette-limit=<Integer>`: Depth at which to start Russian roulette termination (default: `3`).
"""
Comonicon.@cast function pathtracer(
    scene_file, 
    width, 
    height; 
    output_name::String="",
    extension::String = ".png",
    n_rays::Int=5,
    max_depth::Int=5,
    russian_roulette_limit::Int=3,
    )

    try
        # check if an output name is declared, if not use timestamp for default
        if isempty(output_name)
            timestamp = Dates.format(now(), "yyyy-mm-dd_HHMMSS")
            output_name = "render_$timestamp" 
        end

        # check correct output extension
        if !(extension in SUPPORTED_EXTS)
            throw(ExtensionError("unsupported file extension. Please use one of: $(join(SUPPORTED_EXTS, ", "))"))
        end

        # make the path for output images
        base_path = "render"
        mkpath(base_path)
        ldr_path = joinpath(base_path, output_name * extension)
        pfm_path = joinpath(base_path, output_name * ".pfm")

        # Parse the scene from text file
        scene = open(scene_file, "r") do io
            instream = RayTracer.InputStream(io, scene_file)
            RayTracer.parse_scene(instream)
        end

        # Prepare the canva to draw on
        img = HdrImage(parse(Int, width), parse(Int, height))
        # Prepare the environment made of the canva and the observer
        tracer = ImageTracer(img, scene.camera)

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


        RayTracer.fire_all_rays!(tracer, f; progress_flag = true)
        

        write(pfm_path, img)
        RayTracer.write_ldr_image(ldr_path, img)

        println("\n✅ Rendering completed successfully. Output files:")
        println("  • Tone-mapped image ($extension): $ldr_path")
        println("  • High dynamic range image (.pfm): $pfm_path")

    catch e
        if isa(e, CustomException)
            println(e)
        else
            rethrow()
        end
    end
end

# Commonicon.@cast function tonemapping()
# end

# Use a single @main somewhere to define the entry.
# Leave @main empty; it just activates the CLI parser and dispatcher.
Comonicon.@main