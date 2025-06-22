"""
    onoff_tracer(world::World, ray::Ray; bkg_color=BLACK) -> RGB

A binary ray tracer that returns `WHITE` if the given `ray` intersects
any object in the `world`, and `bkg_color` otherwise.

This is a basic tracer useful for debugging or silhouette rendering.

# Arguments
- `world::World`: The scene containing objects to test against.
- `ray::Ray`: The ray to be traced through the scene.
- `bkg_color`: The background color to return if the ray hits nothing (default: `BLACK`).
"""
function onoff_tracer(world::World, ray::Ray; bkg_color = BLACK)
    isnothing(ray_intersection(world, ray)) ? bkg_color : WHITE
end

"""
    flat_tracer(world::World, ray::Ray; bkg_color=BLACK) -> RGB

A minimal ray tracer that if the given `ray` intersects
any object in the `world` returns the sum of the surface color and
emitted radiance at the intersection point.
If the ray does not intersect any object, the function returns `bkg_color`.

This tracer ignores lighting, shadows, and reflections, and is typically used
for quick previews, debugging geometry, or visualizing base materials and emissive surfaces.

# Arguments
- `world::World`: The 3D scene containing objects with material properties.
- `ray::Ray`: The ray to be traced through the scene.
- `bkg_color`: The background color to return if the ray hits nothing (default: `BLACK`).
"""
function flat_tracer(world::World, ray::Ray; bkg_color = BLACK)
    hit_record = ray_intersection(world, ray)
    isnothing(hit_record) ? bkg_color :
    (
        get_color(hit_record.shape.material.brdf.pigm, hit_record.surface_point) +
        get_color(hit_record.shape.material.emitted_radiance, hit_record.surface_point)
    )
end

"""
    path_tracer(world::World, ray::Ray, pcg::PCG; 
                bkg_color=BLACK, 
                n_rays=10, 
                max_depth=10, 
                russian_roulette_limit=3) -> RGB

Path tracer that estimates a solution of the rendering equation via Monte Carlo integration.

# Arguments
- `world::World`: The 3D scene containing objects with material properties.
- `ray::Ray`: The ray to be traced through the scene.
- `pcg::PCG`: A random number generator for stochastic sampling.
- `bkg_color`: The background color to return if the ray hits nothing (default: `BLACK`).
- `n_rays`: Number of secondary rays for Monte Carlo sampling (default: 10).
- `max_depth`: Maximum recursion depth (default: 10).
- `russian_roulette_limit`: Depth at which Russian Roulette begins (default: 3).
"""
function path_tracer(
    world::World,
    ray::Ray,
    pcg::PCG;
    bkg_color = BLACK,
    n_rays = 10,
    max_depth = 10,
    russian_roulette_limit = 3,
)
    # Truncate the recursion
    if ray.depth > max_depth
        return BLACK
    end

    # Find the intersection of the ray with any object in the world
    hit_record = ray_intersection(world, ray)
    if isnothing(hit_record)
        return bkg_color
    end
    hit_material = hit_record.shape.material    # material of the hit object
    # Each material is defined by a BRDF (Bidirectional Reflectance Distribution Function),
    # which describes how the surface reflects incoming light, 
    # and by emitted radiance, which indicates if the material emits light.
    hit_color = get_color(hit_material.brdf.pigm, hit_record.surface_point)                   # reflected radiance
    emitted_radiance = get_color(hit_material.emitted_radiance, hit_record.surface_point)     # emitted radiance

    hit_color_lum = max(hit_color.r, hit_color.g, hit_color.b)

    # Russian Roulette
    # This remove the bias (radiance understimation) caused by truncating the recursion.
    # Let q ∈ [0,1] be a threshold, draw a random number x:
    # - if x ≥ q, compute the radiance L and return L / (1 - q);
    # - otherwise, terminate recursion and return 0 (BLACK).
    # Note: The threshold 0.05 is chosen to reduce variance. 
    # When the luminance is very low, the probability to stop the recursion and return 0 is close to 1, 
    # but the points where L is returned tend to be very bright, which can cause high variance.
    if ray.depth >= russian_roulette_limit
        # Makes q smaller when the surface is bright, 
        # and larger when it’s dark.
        q = max(0.05, 1 - hit_color_lum)
        if random_float!(pcg) > q
            # Continue the recursion
            hit_color = hit_color / (1 - q)
        else
            # Kill the recursion
            return emitted_radiance
        end
    end

    # MonteCarlo Integration
    cum_radiance = BLACK
    if hit_color_lum > 0.0
        for i = 1:n_rays
            new_ray = scatter_ray(
                hit_material.brdf,
                pcg,
                hit_record.ray.dir,
                hit_record.world_point,
                hit_record.normal,
                hit_record.ray.depth + 1,   # secondary ray: increase depth by 1
            )
            # Recursive call! Pass the same default arguments
            new_radiance = path_tracer(
                world,
                new_ray,
                pcg;
                bkg_color = bkg_color,
                n_rays = n_rays,
                max_depth = max_depth,
                russian_roulette_limit = russian_roulette_limit,
            )
            cum_radiance += hit_color * new_radiance
        end
    end
    return emitted_radiance + cum_radiance / n_rays
end

# generic closure function for renderer
"""
    my_renderer(renderer, world; pcg=nothing, kwargs...) -> Function

Creates a closure using the specified renderer.

# Arguments
- `renderer`: the rendering function to use (e.g., `onoff_tracer`, `flat_tracer`, `path_tracer`).
- `world::World`: the scene to be traced.
- `pcg::PCG`: (optional) needed for `path_tracer`.
- `bkg_color::RGB`: the background color (default=BLACK)
- `n_rays::Integer`: number of rays generated for surface reflection, used in `path_tracer`(default=10)
- `max_depth::Integer`: maximum number of reflection for a ray, used in `path_tracer`(default=10)
- `russian_roulette_limit::Integer`: minimum number of iteration before possible iteration kill (default=3)

# Returns
- A function `ray -> RGB` that takes a ray and returns the color computed by the renderer.
"""
function my_renderer(
    renderer,
    world;
    pcg = nothing,
    bkg_color = BLACK,
    n_rays = 10,
    max_depth = 10,
    russian_roulette_limit = 3,
)
    isnothing(pcg) ? (ray -> renderer(world, ray; bkg_color = bkg_color)) :
    (
        ray -> renderer(
            world,
            ray,
            pcg;
            bkg_color = bkg_color,
            n_rays = n_rays,
            max_depth = max_depth,
            russian_roulette_limit = russian_roulette_limit,
        )
    )
end


"""
    pointlight_tracer(
    world::World,
    ray::Ray,
    pcg::PCG;
    bkg_color = BLACK,
    )

TBW
"""
function pointlight_tracer(
    world::World,
    ray::Ray,
    pcg::PCG;
    bkg_color = BLACK,
    )
    #...
end
