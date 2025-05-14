function OnOff_Tracing(world::World, ray::Ray)
    isnothing(ray_intersection(world, ray)) ? RGB(0.0, 0.0, 0.0) : RGB(1.0, 1.0, 1.0)
end

function demo(width, height, camera, angle_deg, dir_name; pfm=true)
    # HdrImage
    img = HdrImage(width, height)
    
    # Cameras
    aspect_ratio = width/height
    distance = 1.0
    transformation = rotation_z(angle_deg)*translation(Vec(-2.0, 0.0, 0.0))
    if camera == "Orthogonal"
        cam = OrthogonalCamera(aspect_ratio,transformation)
        name = dir_name*"demo_orthogonal"
    else
        cam = PerspectiveCamera(distance,aspect_ratio,transformation)
        name = dir_name*"demo_perspective"
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