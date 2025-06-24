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
    - `image("path/to/image.pfm")` — image-based texture, both HDR (`.pfm`) and LDR (`.jpg`, `.png`, `.tif`) image formats are supported.

#### **Example**:
```julia
material plane_material(
    diffuse(
        checkered(<1.0, 1.0, 0.2>, <0.1, 0.2, 0.5>, 4)
    ),
    uniform(<0, 0, 0>)
)
```

This defines a material named `plane_material` with the following characteristics:


- A **diffuse surface** that uses a checkered pattern made of two colors: `<1.0, 1.0, 0.2>` (britght yellow) and `<0.1, 0.2, 0.5>` (dark blue).

- An **emittance** of `<0, 0, 0>`, which means the material does **not** emit light (black is interpreted as zero light emission).


### 🧱 3. Objects

To create an object, define its **shape**, assign a **material**, and place it into the scene using a **transformation**.

Each shape **must** be declared with an **identifier**. This is required because it facilitates constructing more complex shapes using *Constructive Solid Geometry ([CSG](#-4-constructive-solid-geometry-csg))*.  
The general syntax to define a shape is:

```julia
shape <shape_name>(<material>, <transformation>)
```

Each object can be duplicated using the `copy` keyword.  This is useful for reusing the same [CSG](#-4-constructive-solid-geometry-csg) structure in multiple compositions within a single scene:

```julia
copy <new_shape_name>(<original_shape_name>)
```

---

#### **Basic Shapes**
- `sphere` $-$ Unit sphere centered at $(0, 0, 0)$. 
- `plane` $-$ Infinite plane at $z = 0$. 
- `cube` $-$ Cube with $l = 1.0$ centered at $(0.5, 0.5, 0.5)$. 

---

#### **Transformation**
- `identity` — No transformation.
- `translation([x, y, z])` — Translates the object by the vector $\vec{v} = \left( x, y, z \right)$.
- `scaling(sx, sy, sz)` — Scales the object along each axis. All values must be non-zero. Use negative values to apply reflections.
- `rotation_x(deg)` — Rotates the object around the **x-axis** by the given angle in degrees.
- `rotation_y(deg)` — Rotates the object around the **y-axis** by the given angle in degrees.
- `rotation_z(deg)` — Rotates the object around the **z-axis** by the given angle in degrees.

You can **combine transformations** using the `*` operator. Transformations are applied **right to left**.

#### **Example**:
```julia
shape small_sphere(sphere_material, translation([-2.5, -1, 0.2]) * scaling(0.2, 0.2, 0.2))
```
This creates a `sphere` with the material `sphere_material`, a radius of $0.2$, and origin at $(-2.5,\, -1,\, 0.2)$.

---

### 🧩 4. Constructive Solid Geometry (CSG)

CSG allows the composition of shapes using boolean operations: `union`, `fusion`, `intersection`, and `difference`.  
A `csg` is a shape object, so it must be declared with an identifier. Since it behaves like any other shape, you can build complex objects by nesting multiple CSGs.

- A global transformation can be applied to the entire CSG block, preserving the relative positions of its internal components (if no needed use `identity`).
- Shapes inside a CSG are not automatically added to the world. If you want to use them independently, you must duplicate them using `copy` and assign a new name.
The general syntax to define a CSG is:

```julia
csg my_csg_shape(<shape_1>, <shape_2>, <operation>, <transformation>)
```
**Operations**
- `Union` $-$ Merges the volumes: both shapes are kept, and all intersections between them are detected and included.
- `Fusion` $-$ Like union, but only the external surfaces are retained, removing internal overlaps.
- `Intersection` $-$ Only the common volume is preserved: intersections are kept only if occur on a part of one shape that lies inside the other.
- `Difference` $-$ Subtracts the second shape from the first: only the parts of the first shape that are **not** inside the second are retained, or intersections from the second shape that occur within the first.

#### **Example**:
```julia
csg partial_csg(sphere_1, cube_2, difference, identity)
csg total_csg(partial_csg, plane_3, fusion, translation([1.0, 2.0, 3.0]))
copy cube_2_copy(cube_2)  # This creates a copy of object cube_2 that will be visible in the scene

```
This sequence builds a CSG object by subtracting `cube_2` from `sphere_1`, then combining the result with `plane_3` using a `fusion` operation. `cube_2_copy` is a duplicate of `cube_2`, placed in the scene independently.

---

### 🎥 5. Camera

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
camera(perspective, rotation_z(angle) * translation([-4, -1, 1]), 1.0)
```
This defines a perspective camera positioned at $(5, -1, 1)$ (starting from $x = -1$ and translating by $-4$) and rotated around the **z-axis** by `angle` degrees, with a screen distance of $1$. The angle variable can also be overridden via the command line:
```shell
julia RayTracer <tracer> --angle <value>
```
If `--angle` is not specified, the value from the scene file ($90$) is used. This setup allows convenient previewing by adjusting the camera rotation without modifying the scene file.


### 6. Working example
*Note* — You can write comment using `#`
```julia
# Float variable (can be overridden via CLI: --angle <value>)
float angle(0.0)

# Materials
material plane_material(
    diffuse(
        checkered(<1.0, 1.0, 0.2>, <0.1, 0.2, 0.5>, 4)
    ),
    uniform(<0, 0, 0>)
)
material sky_material(diffuse(uniform(<0, 0, 0>)), uniform(<0.5, 0.5, 1>))
material mirror_material(specular(uniform(<0.5, 0.5, 0.5>)), uniform(<0, 0, 0>))
material sphere_material(diffuse(uniform(<1, 0.314, 0.314>)), uniform(<0, 0, 0>))
material sphere_sky_material(diffuse(image("./examples/reference_nightsky.jpg")), uniform(<0, 0, 0>))

# Object definitions
# Night sky sphere at position (1, 1, 2)
sphere(sphere_sky_material, translation([-1, -2, 2.5]) * rotation_z(60) * scaling(1.2, 1.2, 1.2))

# Red little sphere
sphere(sphere_material, translation([-2.5, -1, 0.2]) * scaling(0.2, 0.2, 0.2))

# Mirror sphere at origin
sphere(mirror_material, scaling(1.5, 1.5, 1.5))

# Large sky sphere
sphere(sky_material, scaling(50, 50, 50))

# Plane with checkered pattern
plane(plane_material, identity)

# Camera with CLI-overridable angle and screen distance 1
camera(perspective, rotation_z(angle) * translation([-4, -1, 1]), 1.0)
```
