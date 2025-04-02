# RayTracer

RayTracer is a under-devolpment Julia software for image generation, released under EUPL license. It is available for Windows OS. The provided version allows just to convert images from PFM format into PNG format.

## Installation
### From GitHub
Straight installation from GitHub:
```
using Pkg
Pkg.add("https://github.com/baronauta/RayTracer")
```

## Usage
Suppose to have `image.pfm` that you want to convert in a PNG format. From command line
```
julia RayTracer image.pfm factor gamma output.png
```
where
 - `factor`: constant to tune the luminosity of the image;
 - `gamma`: computer-based constant for color visualization.