# This file contains:
# - Scene creation and object/material setup
# - Functions for generating demo images and videos
# - CLI parameter parsing and usage instructions for demo execution

# ─────────────────────────────────────────────────────────────
# SCENE AND SINGLE IMAGE CREATION
# choose the scene for demo or demo_onoff
# ─────────────────────────────────────────────────────────────

function demo_image(width, height, camera, angle_deg, renderer_name; dir_name = "./demo_output/", pfm = true, progress_flag = true, bkg_color=BLACK, n_rays=10, max_depth=10, russian_roulette_limit=3)
    # HdrImage
    width = width
    height = height
    angle_deg = angle_deg
    img = HdrImage(width, height)

    # Cameras
    aspect_ratio = width / height
    distance = 1.0
    transformation = rotation_z(angle_deg) * translation(Vec(-3.0, 0.0, 1.0))
    
    if lowercase(camera) == "orthogonal"
        cam = OrthogonalCamera(aspect_ratio,transformation)
        name = dir_name*"demo_orthogonal"
    elseif lowercase(camera) == "perspective"
        cam = PerspectiveCamera(distance,aspect_ratio,transformation)
        name = dir_name*"demo_perspective"
    else
        throw(RuntimeError("Invalid camera name. Use 'Perspective' or 'Orthogonal'."))
    end

    # Image Generation

    # ImageTracer
    tracer = ImageTracer(img, cam)

    # World

    # Plane
    plane_brdf = DiffuseBRDF(CheckeredPigment(RGB(0.78, 0.902, 0.471), RGB(0.953, 0.718, 1), 6))
    plane_material = Material(plane_brdf, UniformPigment(BLACK))

    # Spheres aspect
        # earth
    earth_pfm = RayTracer.read_pfm_image("./earth.pfm") # ./examples/earth.pfm
    earth_brdf = DiffuseBRDF(ImagePigment(earth_pfm))
    earth_material = Material(earth_brdf, UniformPigment(BLACK))
    earth = Sphere(translation(Vec(1., 1., 2.)) , earth_material)

        # diffuse sphere
    sphere_brdf = DiffuseBRDF(UniformPigment(RGB(1, 0.314, 0.314)))
    sphere_material = Material(sphere_brdf, UniformPigment(BLACK))
    sphere = Sphere(translation(Vec(-1., -1., 0.2)) * scaling(0.2,0.2,0.2) , sphere_material)
    
        # mirror sphere
    mirror_material = Material(SpecularBRDF(UniformPigment(RGB(0.9,0.9,0.9))), UniformPigment(BLACK))

    # Source of light
    lumi_brdf = DiffuseBRDF(UniformPigment(BLACK))
    lumi_material = Material(lumi_brdf, UniformPigment(RGB(0.7, 0.8, 1)))

    # shapes for normal and basic demo
    # demo
    if lowercase(renderer_name) != "onoff_tracer"
        sky = Sphere(scaling(50.0,50.0,50.0), lumi_material)
        shape_list = [
            sky,
            earth,
            Plane(plane_material),
            sphere,
            Sphere(mirror_material),
        ]
    else # onoff demo
        scale = scaling(0.1, 0.1, 0.1)
        shape_list = [
                    Sphere(translation(Vec(-0.5,-0.5,-0.5))*scale,sphere_material),
                    Sphere(translation(Vec(-0.5,-0.5, 0.5))*scale,sphere_material),
                    Sphere(translation(Vec(-0.5, 0.5,-0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.5,-0.5,-0.5))*scale,sphere_material),
                    Sphere(translation(Vec(-0.5, 0.5, 0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.5, 0.5,-0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.5,-0.5, 0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.5, 0.5, 0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.0, 0.0, -0.5))*scale,sphere_material),
                    Sphere(translation(Vec( 0.0, 0.5, 0.0))*scale,sphere_material)
                ]
    end
    world = World(shape_list)

    # Rendering
    if lowercase(renderer_name) == "path_tracer"
        pcg = RayTracer.PCG()
        renderer = path_tracer
    else
        if lowercase(renderer_name) == "onoff_tracer"
            renderer = onoff_tracer
            progress_flag && println("\n<onoff_tracer> option use an on/off renderer that return white when there is an object and black otherwise. For these reason has a different dedicated scene to avoid generating a white image.\n")
        elseif lowercase(renderer_name) == "flat_tracer"
            renderer = flat_tracer
        else
            println("ERROR, undefined renderer, plees select a valid renderer \n $(renderer_name)")
            return 1
        end
        pcg = nothing
    end

    RayTracer.fire_all_rays!(tracer, my_renderer(renderer, world, pcg = pcg; bkg_color=bkg_color, n_rays=n_rays, max_depth=max_depth, russian_roulette_limit=russian_roulette_limit); progress_flag)

    # PFM Image saving
    pfm && write(name * "_$renderer_name.PFM", img)

    # LDR Image saving (default png)
    RayTracer.write_ldr_image(name * "_$renderer_name.png", img; gamma = 0.80)

    progress_flag && println("\n ✅ Successfully generated the demo image. Files are saved in the < /demo_output/ > folder")
end

# ─────────────────────────────────────────────────────────────
# VIDEO CREATION
# ─────────────────────────────────────────────────────────────
function make_video(width, height, camera, renderer_name)
    cmd = `ffmpeg -y -r 25 -f image2 -s $(width)x$(height) -i ./demo_output/all_video_frames/img%03d.png -vcodec libx264 -pix_fmt yuv420p ./demo_output/demo-$(camera)-$(renderer_name).mp4`
    run(cmd)
end

function demo_video(width, height, camera, renderer_name; pfm = false, progress_flag = false, bkg_color=BLACK, n_rays=10, max_depth=10, russian_roulette_limit=3)
    dir_name = "demo_output/all_video_frames/"
    mkpath(dir_name)
    (renderer_name == "onoff_tracer") && println("\n<onoff_tracer> option use an on/off renderer that return white when there is an object and black otherwise. For these reason has a different dedicated scene to avoid generating a white image.\n")
    for angle in 0:359
        demo_image(width, height, camera, angle, renderer_name; dir_name = dir_name, pfm = pfm, progress_flag = progress_flag, bkg_color=bkg_color, n_rays=n_rays, max_depth=max_depth, russian_roulette_limit=russian_roulette_limit)
        angle_str = lpad(string(angle), 3, '0')
        mv("$(dir_name)demo_$(camera)_$(renderer_name).png", "$(dir_name)img$(angle_str).png"; force=true)
        RayTracer.simple_progress_bar(angle + 1, 360, item = "frame")
    end
    # make the video
    make_video(width, height, camera, renderer_name)
    println("\n ✅ Successfully generated the demo video. Files are saved in the < /demo_output/ > folder")

end

# ─────────────────────────────────────────────────────────────
# PARAMETERS FOR DEMO
# ─────────────────────────────────────────────────────────────

# demo
demo_error = """\n
 ------------------------------------------------------------
 Correct command usage:
      julia demo [ARGUMENTS]

      BASIC USAGE:
      Arguments:
      - mode STRING        <image> for image creation, <video> for 360° .mp4 animation
      - width INTEGER      Image width in pixels
      - height INTEGER     Image height in pixels
      - camera STRING      Type of camera: Orthogonal or Perspective
      - renderer STRING    Type of renderer: onoff_tracer* , flat_tracer, path_tracer

      ADVANCED USAGE
      Additional Arguments (after basic usage Args)**:
      - angle-deg FLOAT    Angle of view from start position (around Z-axes, angle-deg ∈ [0; 360])
      - n_rays INTEGER     number of rays generated for surface reflection, used in <path_tracer> (default = 5)***
      - max_depth INTEGER  maximum number of reflection for a ray, used in <path_tracer> (default = 5)***

      Note*:   <onoff_tracer> has a different dedicated scene to avoid generating a white image.
      Note**:  All advanced arguments need to be specified when using Advanced mode.
      Note***: Image generation with <path_tracer> can be slow with high resolution or large n_rays/max_depth.
            For quick demos, low or default values are recommended.

      the created files will be saved in the < /demo_output/ > folder
------------------------------------------------------------
"""
mutable struct demo_Params
    mode::String
    width::Integer
    height::Integer
    camera::String
    renderer::String
    angle_deg::AbstractFloat
    n_rays::Integer
    max_depth::Integer
end

function demo_Params(args)
    try
        nargs = length(args)
        if nargs < 5 || nargs > 8
            throw(RuntimeError(demo_error))
        end

        mode = lowercase(args[1])
        width = parse(Int, args[2])
        height = parse(Int, args[3])
        camera = lowercase(args[4])
        renderer = lowercase(args[5])

        angle_deg = nargs >= 6 ? parse(Float64, args[6]) : 0.0
        n_rays    = nargs >= 7 ? parse(Int, args[7])      : 5
        max_depth = nargs == 8 ? parse(Int, args[8])      : 5

        return demo_Params(mode, width, height, camera, renderer, angle_deg, n_rays, max_depth)
    catch
        throw(RuntimeError(demo_error))
    end
end