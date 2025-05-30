# RayTracer
_Photorealistic Image Generator – Developed in Julia_

[![GitHub Release](https://img.shields.io/github/v/release/baronauta/RayTracer)](https://github.com/baronauta/RayTracer/releases)
[![License: EUPL-1.2](https://img.shields.io/badge/license-EUPL%201.2-blue.svg)](https://github.com/baronauta/RayTracer/blob/master/LICENSE.md)
[![Julia Version](https://img.shields.io/badge/Julia-1.x-purple.svg)](https://julialang.org/)
[![Platform](https://img.shields.io/badge/OS-Linux%20%7C%20Windows-green.svg)](https://github.com/baronauta/RayTracer#requirements)
[![Status](https://img.shields.io/badge/status-active--development-yellow.svg)](https://github.com/baronauta/RayTracer)
[![CI Tests](https://github.com/baronauta/RayTracer/actions/workflows/action.yml/badge.svg)](https://github.com/baronauta/RayTracer/actions/workflows/action.yml)


A command-line ray tracing tool written in Julia, designed to generate photorealistic images and handle high-dynamic-range (PFM) format.

⚠️ **NOTICE**: This tool is under active development and currently supports two main functionalities:

1. **PFM to LDR Image Conversion**  
   Converts PFM files to standard LDR formats (PNG, JPEG, etc.), with configurable tone mapping.

2. **Ray-Traced Demo Scene Rendering**  
   Renders a built-in scene using three different types of renderers (see the Demo Examples [section](?tab=readme-ov-file#demo-example)), producing either a single image or a 360° `.mp4` animation.

## Installation
### Requirements
- Julia v1.x (see [Julia official website](https://julialang.org/))
- A supported operating system (latest stable release of Linux or Windows)
- FFmpeg (for video generation, see [ffmpeg.org](https://ffmpeg.org/)). Make sure it is available in your system's PATH.

### Installation and Environment Setup

1. Download the [latest release](https://github.com/baronauta/RayTracer/releases/tag/v0.3.0) and extract the archive. Navigate to the extracted directory.

2. Launch Julia from within the project directory and set up the environment:

```bash
julia
```

In the Julia REPL, execute:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

This will:
- Activate the project environment;
- Install all required dependencies.

#### (Optional) Run Tests
To ensure everything works as expected, you can run the test suite with the following command:

```julia
Pkg.test()
```

## Usage Instructions
To display usage instructions for either tool, run:
```
julia pfm2image
``` 
or 
```
julia demo
```

### Conversion Example:
```
julia pfm2image ./examples/reference_earth.pfm 1.0 1.0 output.png
```

This reads the HDR image `./examples/reference_earth.pfm`, normalizes and clamps the data, and exports it as an LDR file with gamma correction to `output.png`.

Note: This code uses the _images.jl_ package. A list of supported output formats is available [here](https://github.com/JuliaIO/ImageIO.jl).

### Demo Example:
There are three different renderers:
- `onoff_tracer`: simply returns a white pixel when there is an object, black otherwise.
- `flat_tracer`: a more advanced yet still basic renderer. Returns the surface color of the object, ignoring reflections and contributions from other light.
- `path_tracer`: the main and most advanced renderer of this project; it is able to produce unbiased rendering equation solutions.

The demo scene for `onoff_tracer` represents a cube made from 8 white spheres, with 2 additional ones placed for visual reference.

The demo scene for `path_tracer` and `flat_tracer` features a checkered plane with a sky background and three spheres: one is a mirror, one is textured using a custom PFM image, and one has a uniform color.

#### To generate a single image (perspective projection, using the `path_tracer` renderer):
  ```
  julia demo image 300 300 perspective path_tracer
  ```

#### To generate an `.mp4` animation (a 360° camera orbit around the scene, using the `flat_tracer` renderer):
  ```
  julia demo video 300 300 perspective flat_tracer
  ```
  Note: Individual animation frames are saved in `/demo_output/all_video_frames/` and the final video or single image in `/demo_output/`.

### Output Examples:
<div style="display: flex; gap: 20px; justify-content: center;">
  <figure>
    <img src="./examples/reference_demo_onoff.png" alt="onoff_tracer, 20° angle" width="300">
    <figcaption><em><strong>onoff_tracer</strong>, 20° angle</em></figcaption>
  </figure>
  <figure>
    <img src="./examples/reference_demo_flat_video.gif" alt="flat_tracer, 360° animation" width="300">
    <figcaption><em><strong>flat_tracer</strong>, 360° animation</em></figcaption>
  </figure>
  <figure>
    <img src="./examples/reference_demo_path.png" alt="path_tracer, static image" width="300">
    <figcaption><em><strong>path_tracer</strong>, static image</em></figcaption>
  </figure>
</div>



## History
See the file [HISTORY.md](https://github.com/baronauta/RayTracer/blob/master/HISTORY.md).

## License
The code is released under the European Union Public Licence (EUPL), version 1.2. See the file [LICENSE.md](./LICENSE.md).

## Authors
Developed by [baronauta](https://github.com/baronauta) and [Stefano-Bozzi](https://github.com/Stefano-Bozzi).
