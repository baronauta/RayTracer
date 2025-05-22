# HEAD
# Version 0.2.0

-   **Breaking change:** move the image PFM-to-LDR conversion from `RayTracer` to the new file `pfm2image` for better code organization.
-   **Breaking change:** Implement a `demo` functionality to present code capabilities.
-   Introduce basic shapes (e.g., sphere, plane) for scene population in rendering. Black and white image generation is now available [#6](https://github.com/baronauta/RayTracer/pull/6).
-   Fix an issue due to a fault in `write(filename::String, image::HdrImage; endianness = my_endian)`[#8](https://github.com/baronauta/RayTracer/pull/8).
-   Fix an issue with the vertical order of the images [#5](https://github.com/baronauta/RayTracer/pull/5).

# Version 0.1.0

-   First release of the code