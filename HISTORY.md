# HEAD
## Breaking changes summary
-   **Breaking change:** The `demo` interface now supports multiple renderers (`onoff_tracer`, `flat_tracer`, `path_tracer`) and uses `ImagePigment` for advanced textures.[#10](https://github.com/baronauta/RayTracer/pull/10/)
-   **Breaking change:** Now `HitRecord` require a `shape` field.[#10](https://github.com/baronauta/RayTracer/pull/10/)
-   **Breaking change:** All `Shape` subtypes now require a `material` field.[#10](https://github.com/baronauta/RayTracer/pull/10/)
-   **Breaking change:** Reorganized `/test`. In addition to running all tests, it is now possible to import `setup.jl` and run individual test files with specific `@testset`s. [#11](https://github.com/baronauta/RayTracer/pull/11)

---
-   Implement shapes' colors and rendering equation solutions [#10](https://github.com/baronauta/RayTracer/pull/10/)
    -   Implement architecture for shapes' materials and light interaction via `Pigment`, `BRDF`, `Material`, `scatter_ray`.
    -   Implement `PCG`, a random number generator to support Monte Carlo importance sampling rendering.
    - Implement `onb` to generate Arbitrary Ortonormal Basis on shapes surface.
    -   *New Feature*: Implement two new rendering algorithms: `FlatTracer`, and `PathTracer`.
    -   *New Feature*: Add progress bar for better monitoring.
    -   *New Feature*: Add `read_ldr_image` and `ldr_to_pfm_image` for converting LDR images to PFM format.
    -   Change `demo` usage.
-   Fix issue with case sensitivity in camera names in `demo`[#13](https://github.com/baronauta/RayTracer/pull/13).
# Version 0.2.0
## Breaking changes summary
-   **Breaking change:** move the image PFM-to-LDR conversion from `RayTracer` to the new file `pfm2image` for better code organization.
-   **Breaking change:** Implement a `demo` functionality to present code capabilities.
---
-   Introduce basic shapes (e.g., sphere, plane) for scene population in rendering. Black and white image generation is now available [#6](https://github.com/baronauta/RayTracer/pull/6).
-   Fix an issue due to a fault in `write(filename::String, image::HdrImage; endianness = my_endian)`[#8](https://github.com/baronauta/RayTracer/pull/8).
-   Fix an issue with the vertical order of the images [#5](https://github.com/baronauta/RayTracer/pull/5).

# Version 0.1.0

-   First release of the code