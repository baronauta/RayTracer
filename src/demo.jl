
#_______________________________________________________________________________________
#     LICENSE NOTICE: European Union Public Licence (EUPL) v.1.2
#     __________________________________________________________
#
#   This file is licensed under the European Union Public Licence (EUPL), version 1.2.
#
#   You are free to use, modify, and distribute this software under the conditions
#   of the EUPL v.1.2, as published by the European Commission.
#
#   Obligations include:
#     - Retaining this notice and the licence terms
#     - Providing access to the source code
#     - Distributing derivative works under the same or a compatible licence
#
#   Full licence text: see the LICENSE file or visit https://eupl.eu
#
#   Disclaimer:
#     Unless required by applicable law or agreed to in writing,
#     this software is provided "AS IS", without warranties or conditions
#     of any kind, either express or implied.
#
#_______________________________________________________________________________________


"""
Checks whether a ray intersects any surface in the given world.  
## Returns 
- white (`RGB(1.0, 1.0, 1.0)`) if it hits an object,  
- black (`RGB(0.0, 0.0, 0.0)`) if it misses (background color).
"""
function OnOff_Tracing(world::World, ray::Ray)
    isnothing(ray_intersection(world, ray)) ? RGB(0.0, 0.0, 0.0) : RGB(1.0, 1.0, 1.0)
end

"""
    demo(width, height, camera, angle_deg, dir_name; pfm=true)
Generates an image of a simple scene using a specified camera and angle.

# Arguments
- `width::Int`: Image width in pixels.
- `height::Int`: Image height in pixels.
- `camera::String`: Type of camera ("Perspective" or "Orthogonal").
- `angle_deg::Int`: Rotation angle around the Z-axis in degrees.
- `dir_name::String`: Output directory where the image(s) will be saved.
- `pfm::Bool`: Whether to save the image in `.pfm` format (default: `true`).

# Output
Saves the rendered image as `.png`, and optionally as `.pfm`, in the given directory.
"""
function demo(width, height, camera, angle_deg, dir_name; pfm=true)
    # HdrImage
    img = HdrImage(width, height)
    
    # Cameras
    aspect_ratio = width/height
    distance = 1.0
    transformation = rotation_z(angle_deg)*translation(Vec(-2.0, 0.0, 0.0))
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
    scale = scaling(0.1, 0.1, 0.1)
    sphere_list = [
                    Sphere(translation(Vec(-0.5,-0.5,-0.5))*scale),
                    Sphere(translation(Vec(-0.5,-0.5, 0.5))*scale),
                    Sphere(translation(Vec(-0.5, 0.5,-0.5))*scale),
                    Sphere(translation(Vec( 0.5,-0.5,-0.5))*scale),
                    Sphere(translation(Vec(-0.5, 0.5, 0.5))*scale),
                    Sphere(translation(Vec( 0.5, 0.5,-0.5))*scale),
                    Sphere(translation(Vec( 0.5,-0.5, 0.5))*scale),
                    Sphere(translation(Vec( 0.5, 0.5, 0.5))*scale),
                    Sphere(translation(Vec( 0.0, 0.0, -0.5))*scale),
                    Sphere(translation(Vec( 0.0, 0.5, 0.0))*scale)
                ]

    world = World(sphere_list)

    # On-Off Tracing
    f = ray -> OnOff_Tracing(world, ray)

    fire_all_rays!(tracer, f)

    # PFM Image saving
    pfm && write(name * ".PFM", img)

    # LDR Image saving (default png)
    write_ldr_image(name*".png", img)
end

# parameters function
demo_error = """\n
 ------------------------------------------------------------
 Correct command usage:
      julia demo [ARGUMENTS] [OPTIONS]

      Arguments:
      - width INTEGER      Image width in pixels
      - height INTEGER     Image height in pixels
      - camera STRING      Type of camera: Orthogonal or Perspective

      Options:
      - angle-deg FLOAT    Angle of view from start position (around Z-axes, angle-deg ∈ [0; 360])
      - video STRING       Create a rotating 360 view with the specified arguments (no angle option)
------------------------------------------------------------
"""
# function
"""
    demo_Params(A)

Parses and validates command-line arguments for the demo.

# Arguments
- `A`: A vector of 3 or 4 strings:
    1. `width::Int` – Image width in pixels
    2. `height::Int` – Image height in pixels
    3. `camera::String` – Camera type ("Perspective" or "Orthogonal")
    4. Optional: either `"video"` or an angle in degrees (`Int`)

# Returns
A tuple of 3 or 4 elements matching the input arguments.

## Throws
`RuntimeError` if the input is invalid.
"""
function demo_Params(A)
    try
        width, height = parse.(Int, A[1:2])
        camera = A[3]
        if length(A) == 3
            return width, height, camera
        elseif length(A) == 4
            return A[4] == "video" ?
                (width, height, camera, "video") :
                (width, height, camera, parse(Int, A[4]))
        else
            throw(RuntimeError(demo_error))
        end
    catch
        throw(RuntimeError(demo_error))
    end
end

# make single picture
"""
Generates a single image (both `.pfm` and `.png`) using the `demo` function.
# Arguments
- `width::Int`: Image width in pixels.
- `height::Int`: Image height in pixels.
- `camera::String`: Camera type ("Perspective" or "Orthogonal").
- `angle_deg::Int`: Rotation angle (in degrees) around the Z-axis.
# Output
Saves the image in the `demo_output/` directory.
"""
function generate_single_image(width, height, camera, angle_deg)
    dir_name = "demo_output/"
    mkpath(dir_name)
    demo(width, height, camera, angle_deg, dir_name)
    println("✅ Successfully generated demo pfm and png images.")
end

# make a video
"""
Generates an `.mp4` video using `ffmpeg` from a sequence of PNG frames.
# Arguments
- `width::Int`: Frame width in pixels.
- `height::Int`: Frame height in pixels.
- `camera::String`: Camera type used, included in the output filename.
# Output
Saves the video as `demo_output/spheres-<camera>.mp4`.
"""
function make_video(width, height, camera)
    cmd = `ffmpeg -y -r 25 -f image2 -s $(width)x$(height) -i demo_output/all_video_frames/img%03d.png -vcodec libx264 -pix_fmt yuv420p demo_output/spheres-$(camera).mp4`
    run(cmd)
end

"""
Generates 360 PNG frames (one per degree of rotation) and compiles them into an `.mp4` video.
# Arguments
- `width::Int`: Frame width in pixels.
- `height::Int`: Frame height in pixels.
- `camera::String`: Camera type used ("Perspective" or "Orthogonal").
# Output
Saves individual frames in `demo_output/all_video_frames/` and the final video in `demo_output/`.
"""
function generate_video(width, height, camera)
    dir_name = "demo_output/all_video_frames/"
    mkpath(dir_name)
    
    for angle in 0:359
        demo(width, height, camera, angle, dir_name; pfm=false) # not necessary to write pfm for all frames, much faster
        angle_str = lpad(string(angle), 3, '0')
        cam = lowercase(camera)
        mv("$(dir_name)demo_$(cam).png", "$(dir_name)img$(angle_str).png"; force=true)
        println("at frame: $angle_str")
    end

    make_video(width, height, camera)
    println("✅ Successfully generated the demo video.")
end