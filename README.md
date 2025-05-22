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
   Renders a built-in scene using a basic on/off ray tracer, producing either a single image or a 360° `.mp4` animation.

## Installation
### Requirements
- Julia v1.x (see [Julia official website](https://julialang.org/))
- A supported operating system (latest stable release of Linux or Windows)
- FFmpeg (for video generation, see [ffmpeg.org](https://ffmpeg.org/)). Make sure it is available in your system's PATH.

### Installation and Environment Setup

1. Download the [latest release](https://github.com/baronauta/RayTracer/releases/tag/v0.2.0) and extract the archive. Navigate to the extracted directory.

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
julia pfm2image image.pfm 1.0 1.0 output.png
```

This reads the HDR image `image.pfm`, normalizes and clamps the data, and exports it as an LDR file with gamma correction to `output.png`.

Note: This code uses the _images.jl_ package. A list of supported output formats is available [here](https://github.com/JuliaIO/ImageIO.jl).

### Demo Example:
The demo scene represents a cube made from 8 white spheres, with 2 additional ones placed for visual reference.
- To generate a single image (perspective projection with a 20° field of view):
  ```
  julia demo 512 512 Perspective 20
  ```

To generate an `.mp4` animation (a 360° camera orbit around the scene):
  ```
  julia demo 512 512 Perspective video
  ```
  Note: Saves individual animation frames in `/demo_output/all_video_frames/` and the final video or single image in `/demo_output/`.
<table>
  <tr>
    <td align="center" width="50%">
      <img src="./examples/reference_demo.png" width="50%"/>
      <br/>
      <em>Fig. 1: Static render with 20° field of view</em>
    </td>
    <td align="center" width="50%">
      <img src="./examples/reference_demo_video.gif" width="50%"/>
      <br/>
      <em>Fig. 2: 360° orbit animation</em>
    </td>
  </tr>
</table>



## History
See the file [HISTORY.md](https://github.com/baronauta/RayTracer/blob/master/HISTORY.md).

## License
The code is released under the European Union Public Licence (EUPL), version 1.2. See the file [LICENSE.md](./LICENSE.md).

## Authors
Developed by [baronauta](https://github.com/baronauta) and [Stefano-Bozzi](https://github.com/Stefano-Bozzi).
