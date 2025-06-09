using Revise
using Pkg
Pkg.activate(normpath(@__DIR__))

using RayTracer
using Comonicon
using Dates

# ─────────────────────────────────────────────────────────────
# PATH TRACER
# ─────────────────────────────────────────────────────────────

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

- `--extension=<String>`: File format for the tone-mapped image (`.png`, `.jpeg`, or `.tif`). Default: `.png`.

- `--angle=<float>`: angle for rotating the camera around the Z axis.  
  The distance from the origin is maintained.  
  Useful for quickly changing the view without modifying the `scene_file` (default: 0.0).

- `--n-rays=<Integer>`: Number of rays per pixel (default: `5`).
- `--max-depth=<Integer>`: Maximum ray recursion depth (default: `5`).
- `--russian-roulette-limit=<Integer>`: Depth at which to start Russian roulette termination (default: `3`).
"""
Comonicon.@cast function pathtracer(
    scene_file, 
    _width, 
    _height; 
    output_name::String="",
    extension::String = ".png",
    angle::Float64=0.0,
    n_rays::Int=5,
    max_depth::Int=5,
    russian_roulette_limit::Int=3,
    )

    try
        println("📂 Preparing to parse the scene...")
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

        # convert width e height to Int
        width = parse(Int, _width)
        height = parse(Int, _height)
        # check if there are variables passed from outside (e.g. angle, calculate aspect_ratio)
        aspect_ratio = width/height
        variables = Dict(
            "angle" => angle,
            "aspect_ratio" => aspect_ratio,
            )
        # message for overwritten variable
        (angle!=0) && println("⚠️ Warning: The variable 'angle' is being overwritten with a new value: $angle")
        
        # Parse the scene from text file
        scene = open(scene_file, "r") do io
            instream = RayTracer.InputStream(io, scene_file)
            RayTracer.parse_scene(instream; variables)
        end
        println("✓ Scene parsing completed.")
        println("🖼️  Setting up the image canvas and camera...")
        # Prepare the canva to draw on
        img = HdrImage(width, height)
        # Prepare the environment made of the canva and the observer
        tracer = ImageTracer(img, scene.camera)
        println("✓ Canvas and camera setup completed.")
        println("🚀 Starting ray tracing (this may take a while)...")
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
        println("\n")

        write(pfm_path, img)
        
        # basic tone mapping
        RayTracer.normalize_image!(img)
        RayTracer.clamp_image!(img)
        RayTracer.write_ldr_image(ldr_path, img)

        println("✅ Rendering completed successfully. Output files:")
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