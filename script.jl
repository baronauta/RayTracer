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

Both images are saved in the `render/` folder. The tone-mapped image is generated using a basic built-in tone mapping, which may not produce optimal results for all scenes.  
For higher-quality control, load the `.pfm` file and apply a custom tone mapping using the `tonemapping` function.

Note: This command uses the path tracing algorithm, that estimates a solution of the rendering equation via Monte Carlo integration.
    It allows to obtain an exact solution for the rendering equation, although rendering and producing the `.pfm` file can be time-consuming.

# Args

- `scene_file`: Path to the scene description file (String).
- `width`: Width of the output image (Integer).
- `height`: Height of the output image (Integer).

# Options

- `--output-name=<String>`: Base name for the output image files (without extension).  
  If not provided, a timestamped name like `render_2025-06-07_135023` will be used.  
  Output files will be saved as `render/<name>.<ext>` and `render/<name>.pfm`.

- `--extension=<String>`: File format for the tone-mapped image (`.png`, `.jpeg`, or `.tif`). Default: `.png`.

- `--angle=<float>`: Angle for rotating the camera around the Z axis.  
  The distance from the origin is maintained.  
  Useful for quickly changing the view without modifying the `scene_file` (default: `0.0`).

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
        img_width = parse(Int, width)
        img_height = parse(Int, height)
        # check if there are variables passed from outside (e.g. angle, calculate aspect_ratio)
        aspect_ratio = img_width/img_height
        variables = Dict(
            "angle" => angle,
            "aspect_ratio" => aspect_ratio,
            )

        # Parse the scene from text file
        scene = open(scene_file, "r") do io
            instream = RayTracer.InputStream(io, scene_file)
            RayTracer.parse_scene(instream; variables)
        end
        println("✓ Scene parsing completed.")

        println("🖼️  Setting up the image canvas and camera...")
        # Prepare the canva to draw on
        img = HdrImage(img_width, img_height)
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

# ─────────────────────────────────────────────────────────────
# FLAT TRACER
# ─────────────────────────────────────────────────────────────

"""
Flat tracer command to render a 3D scene with a minimal ray tracer algorithm.

This tool generates two output images for each rendering:
- a high dynamic range `.pfm` file
- a tone-mapped image (`.png`, `.jpeg`, or `.tif`)

Both images are saved in the `render/` folder. The tone-mapped image is generated using a basic built-in tone mapping, which may not produce optimal results for all scenes.  
For higher-quality control, load the `.pfm` file and apply a custom tone mapping using the `tonemapping` function.

Note: This algorithm returns the sum of the surface color and
    emitted radiance at the intersection point of a `ray`.
    If the ray does not intersect any object, the function returns `bkg_color`.

    This tracer ignores lighting, shadows, and reflections, and is typically used
    for quick previews, debugging geometry, or visualizing base materials and emissive surfaces.

# Args

- `scene_file`: Path to the scene description file (String).
- `width`: Width of the output image (Integer).
- `height`: Height of the output image (Integer).

# Options

- `--output-name=<String>`: Base name for the output image files (without extension).  
  If not provided, a timestamped name like `render_2025-06-07_135023` will be used.  
  Output files will be saved as `render/<name>.<ext>` and `render/<name>.pfm`.

- `--extension=<String>`: File format for the tone-mapped image (`.png`, `.jpeg`, or `.tif`). Default: `.png`.

- `--angle=<float>`: Angle for rotating the camera around the Z axis.  
  The distance from the origin is maintained.  
  Useful for quickly changing the view without modifying the `scene_file` (default: `0.0`).
"""
Comonicon.@cast function flattracer(
    scene_file, 
    width, 
    height; 
    output_name::String="",
    extension::String = ".png",
    angle::Float64=0.0,
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
        img_width = parse(Int, width)
        img_height = parse(Int, height)
        # check if there are variables passed from outside (e.g. angle, calculate aspect_ratio)
        aspect_ratio = img_width/img_height
        variables = Dict(
            "angle" => angle,
            "aspect_ratio" => aspect_ratio,
            )

        # Parse the scene from text file
        scene = open(scene_file, "r") do io
            instream = RayTracer.InputStream(io, scene_file)
            RayTracer.parse_scene(instream; variables)
        end
        println("✓ Scene parsing completed.")

        println("🖼️  Setting up the image canvas and camera...")
        # Prepare the canva to draw on
        img = HdrImage(img_width, img_height)
        # Prepare the environment made of the canva and the observer
        tracer = ImageTracer(img, scene.camera)
        println("✓ Canvas and camera setup completed.")
        
        println("🚀 Starting ray tracing (this may take a while)...")
        # RayTracing algorithm that need as input ...
        f =
            ray -> flat_tracer(
                scene.world,
                ray;
                bkg_color = BLACK,
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

# ─────────────────────────────────────────────────────────────
# ON-OFF TRACER
# ─────────────────────────────────────────────────────────────

"""
On-Off tracer command to render a 3D scene with a binary ray tracer algorithm
that returns `WHITE` if the given `ray` intersects
any object in the `world`, and `bkg_color` otherwise.

This is a basic tracer useful for debugging or silhouette rendering.

This tool generates two output images for each rendering:
- a high dynamic range `.pfm` file
- a tone-mapped image (`.png`, `.jpeg`, or `.tif`)

Both images are saved in the `render/` folder. The tone-mapped image is generated using a basic built-in tone mapping, which may not produce optimal results for all scenes.  
For higher-quality control, load the `.pfm` file and apply a custom tone mapping using the `tonemapping` function.

# Args

- `scene_file`: Path to the scene description file (String).
- `width`: Width of the output image (Integer).
- `height`: Height of the output image (Integer).

# Options

- `--output-name=<String>`: Base name for the output image files (without extension).  
  If not provided, a timestamped name like `render_2025-06-07_135023` will be used.  
  Output files will be saved as `render/<name>.<ext>` and `render/<name>.pfm`.

- `--extension=<String>`: File format for the tone-mapped image (`.png`, `.jpeg`, or `.tif`). Default: `.png`.

- `--angle=<float>`: Angle for rotating the camera around the Z axis.  
  The distance from the origin is maintained.  
  Useful for quickly changing the view without modifying the `scene_file` (default: `0.0`).
"""
Comonicon.@cast function onofftracer(
    scene_file, 
    width, 
    height; 
    output_name::String="",
    extension::String = ".png",
    angle::Float64=0.0,
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
        img_width = parse(Int, width)
        img_height = parse(Int, height)
        # check if there are variables passed from outside (e.g. angle, calculate aspect_ratio)
        aspect_ratio = img_width/img_height
        variables = Dict(
            "angle" => angle,
            "aspect_ratio" => aspect_ratio,
            )

        # Parse the scene from text file
        scene = open(scene_file, "r") do io
            instream = RayTracer.InputStream(io, scene_file)
            RayTracer.parse_scene(instream; variables)
        end
        println("✓ Scene parsing completed.")

        println("🖼️  Setting up the image canvas and camera...")
        # Prepare the canva to draw on
        img = HdrImage(img_width, img_height)
        # Prepare the environment made of the canva and the observer
        tracer = ImageTracer(img, scene.camera)
        println("✓ Canvas and camera setup completed.")
        
        println("🚀 Starting ray tracing (this may take a while)...")
        # RayTracing algorithm that need as input ...
        f =
            ray -> onoff_tracer(
                scene.world,
                ray;
                bkg_color = BLACK,
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


"""
Performs tone mapping on an HDR (High Dynamic Range) image read from the specified `filename`.
The function reads a PFM image, normalizes its luminance, and then writes the result
as an LDR (Low Dynamic Range) image with a specified extension and gamma correction.

# Args

- `filename`: The path to the input HDR image file (e.g., a PFM file).

# Options

- `--output-name=<String>`: Optional. The desired name for the output LDR image file, without an extension.
                            If empty, the base name of the input `filename` will be used.
- `--extension=<String>`: The desired file extension for the output LDR image (e.g., ".png", ".jpg").
                        Defaults to ".png". Must be one of the `SUPPORTED_EXTS`.
- `--factor=<Float64>`: A scaling factor applied during image normalization. Defaults to 1.0.
- `--mean=<Symbol>`: The type of mean calculation to use during normalization. Defaults to `:`.
                    (Note: The current `normalize_image!` call explicitly uses `:max_min`.)
- `--gamma=<Float64>`: The gamma correction value applied when writing the LDR image. Defaults to 1.0.
- `--weights=<Vector{Float64}>`: A vector of weights used for luminance calculation during normalization.
                                Defaults to `[1., 1., 1.]` (typically for R, G, B channels).
"""
Comonicon.@cast function tonemapping(
    filename;
    output_name::String="",
    extension::String = ".png",
    factor::Float64=1.,
    mean::Symbol=:max_min,
    gamma::Float64=1.,
    weights::Vector{Float64}=[1., 1., 1.]
)
    try
        hdrimage = read_pfm_image(filename)
        RayTracer.normalize_image!(
            hdrimage;
            factor = factor,
            lumi = nothing,
            delta = 1e-10,
            mean_type = mean,
            weights = weights,
            )
        RayTracer.clamp_image!(hdrimage)
        # Determine the base output filename
        base_output_name = if isempty(output_name)
            splitext(filename)[1] # Get filename without its original extension
        else
            output_name
        end
        
        if !(extension in SUPPORTED_EXTS)
            throw(ExtensionError("unsupported file extension. Please use one of: $(join(SUPPORTED_EXTS, ", "))"))
        end
        newfilename = base_output_name * extension
        @info "Saving figure to $newfilename"
        RayTracer.write_ldr_image(newfilename, hdrimage; gamma=gamma)
    catch e
        if isa(e, CustomException)
            println(e)
        else
            rethrow()
        end
    end
end

# Use a single @main somewhere to define the entry.
# Leave @main empty; it just activates the CLI parser and dispatcher.
Comonicon.@main