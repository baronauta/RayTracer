## 📝 Scene Description Guidelines

RayTracer uses a custom, text-based format to define what will be rendered.


### 🔢 1. Float Variables

You can define float constants to use later:

```julia
float angle(90)
```

### 🎨 2. Materials
Materials define how objects interact with light in the scene. Each material specifies two key properties:

- **Surface behavior** — how the material reflects or scatters incoming light.
- **Emittance** — how the material emits light (if any).

The general syntax to define a material is:

```julia
material <material_name>(<surface>, <emittance>)
```

Supported properties for both `<surface>` and `<emittance>`:

- **Types**:
    - `diffuse` — reflects incoming light uniformly in all directions.
    - `specular` — mirror-like reflection.

- **Pigments** (color or texture) used inside each type:
    - `uniform(<r, g, b>)` — solid color.
    - `checkered(<color1>, <color2>, squares_per_unit)` — checkerboard pattern.
    - `image("path/to/image.pfm")` — image-based texture.

#### **Example**:
```julia
material plane_material(
    diffuse(checkered(<0.7, 0.9, 0.4>, <1, 0.55, 0.2>, 6)),
    uniform(<0, 0, 0>)
)
```
This defines a material named plane_material with the following characteristics:

- A **diffuse surface** that uses a checkered pattern made of two colors: `<0.7, 0.9, 0.4>` (a light green) and `<1, 0.55, 0.2>` (an orange).

- An **emittance** of `<0, 0, 0>`, which means the material does **not** emit light (black is interpreted as zero light emission).


### 🧱 3. Objects

To create an object decide its **shape**, assign a **material** and place it into the scene choosing a **transformation**.

#### **Shapes**
- `sphere` — unit sphere with center in $(0,0,0)$.
- `plane` — $z=0$ plane.

#### **Transformation**
- `identity` — No transformation.
- `translation([x, y, z])` —  Translates the object by the vector $\vec{v} = (x, y, z)$.
- `scaling(sx, sy, sz)` — Scales the object along each axis. All values must be non-zero. Use negative values to apply reflections.
- `rotation_x(deg)` — Rotates the object around the **x-axis** by the given angle in degrees.
- `rotation_y(deg)` — Rotates the object around the **y-axis** by the given angle in degrees.
- `rotation_z(deg)` — Rotates the object around the **z-axis** by the given angle in degrees.


You can **combine transformations** using the `*` operator. Transformations are applied **right to left**.


#### **Example**:
```julia
sphere(plane_material, scaling(50, 50, 50) * translation([1, 1, 2]))
```
This creates a `sphere` with the material `plane_material`, a radius of $50$, and origin at $(1,1,2)$.

### 🎥 4. Camera Definition

The `camera` represents the viewpoint that **sees** the scene. It defines where the observer is located and how the scene is projected onto the image plane. The camera’s position and orientation are set using a **transformation**.

Two types of cameras are available:

- **Perspective Camera** — Simulates a realistic camera with perspective projection, where objects farther away appear smaller. It requires specifying the distance from the camera to the image plane (screen).
    ```julia
    camera(perspective, <transformation>, <screen_distance>)
    ```

- **Orthogonal** — Uses orthographic projection, which preserves object sizes regardless of depth. This is ideal for technical or architectural visualization where true dimensions are important.
    ```julia
    camera(orthogonal, <transformation>)
    ```
#### **Example**:
```julia
float angle(90)
camera(perspective, rotation_z(angle) * translation([-3, 0, 1]), 1.0)
```
This defines a perspective camera positioned at $(-3, 0, 1)$ and rotated around the **z-axis** by angle degrees, with a screen distance of $2$. The angle variable can also be overridden via the command line:
```shell
julia RayTracer <tracer> --angle <value>
```
If `--angle` is not specified, the value from the scene file ($90$) is used. This setup allows convenient previewing by adjusting the camera rotation without modifying the scene file.


### Working example
*Note* — You can write comment using `#`
```julia
# Float variable (can be overridden via CLI: --angle <value>)
float angle(90)

# Materials
material plane_material(
    diffuse(checkered(<0.7, 0.9, 0.4>, <1, 0.55, 0.2>, 6)),
    uniform(<0, 0, 0>)
)
material sphere_material(diffuse(uniform(<1, 0.314, 0.314>)), uniform(<0, 0, 0>))
material mirror_material(specular(uniform(<0.9, 0.9, 0.9>)), uniform(<0, 0, 0>))
material sky_material(diffuse(uniform(<0, 0, 0>)), uniform(<0.7, 0.8, 1>))
material earth_material(diffuse(image("./examples/reference_earth.pfm")), uniform(<0, 0, 0>))

# Object definitions
# Earth sphere at position (1, 1, 2)
sphere(earth_material, translation([1, 1, 2]))

# Red sphere scaled down and positioned at (-1, -1, 0.2)
sphere(sphere_material, translation([-1, -1, 0.2]) * scaling(0.2, 0.2, 0.2))

# Mirror sphere at origin
sphere(mirror_material, identity)

# Large sky sphere
sphere(sky_material, scaling(50, 50, 50))

# Plane with checkered pattern
plane(plane_material, identity)

# Camera with CLI-overridable angle and screen distance 2
camera(perspective, rotation_z(angle) * translation([-3, 0, 1]), 1.0)
```