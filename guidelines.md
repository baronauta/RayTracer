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

- Shapes used inside a CSG are not added to the world as standalone objects. They only exist as part of the CSG.  
To use a shape both inside and outside a CSG, you must duplicate it using the `copy` command with a new name.

```julia
copy <new_shape_name>(<original_shape_name>)
```
> ℹ️ **Note:** This is especially useful when working with a complex CSG (e.g., `csg1`) that you want to reuse multiple times inside a larger structure (e.g., `csg_global`).  
Instead of reconstructing `csg1` every time, you can define it once and then duplicate it wherever needed using `copy`, saving time and avoiding repetition.

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

### 🎬 6. Animations 
Rendering a scene from a single, static viewpoint can be limiting—animations allow you to explore the scene through dynamic camera movements over time.

To define an animation, add the following line to your scene description file:
```bash
motion(<transformation>, <num_of_frames>)
```
- `<transformation>`: a predefined movement or transformation (e.g., `rotatation_x`, `translation`)

- `<num_of_frames>`: the number of frames to render along the motion path

**Note**: concatenation of multiple transformations using `*` is _not_ supported—only a single transformation can be applied per animation.

### 7. Working example
*Note* — You can write comment using `#`
```bash
# Float variable (can be overridden via CLI: --angle <value>)
float angle(0.0)

#============== MATERIALS ==============
# SKY
material sky_material(
    diffuse(uniform(<0.3, 0.3, 0.3>)),
    uniform(<0, 0, 0>)
)

# FLOOR
material ground_material(
    diffuse(checkered(<0.5, 0.5, 0.5>, <0, 0, 0>, 2)),
    uniform(<0, 0, 0>)
)

# RED CUBE
material red_material(
    diffuse(uniform(<10, 0.1, 0.1>)),
    uniform(<0, 0, 0>)
)

# BLUE SPHERE
material blue_material(
    diffuse(uniform(<0.1, 0.1, 10>)),
    uniform(<0, 0, 0>)
)

#============== OBJECTS ==============
# SKY
sphere sky(sky_material, scaling(50,50,50))

#---

# FLOOR PLANE
plane ground(ground_material, identity)

#---

# SPHERE - lifted and slightly offset to cut into cube
sphere sphere_1(blue_material, translation([1, -1, 2]) * scaling(0.8,0.8,0.8))

#---

# CUBE - scaled and translated
cube cube_1(red_material, translation([-1, -1, 0]) * scaling(2, 2, 2))

#---

# CSG - cube and sphere

# To change the CSG operation, uncomment one of the alternatives below and comment out the current operation.

csg csg_diff(cube_1, sphere_1, difference, rotation_z(-60))
# csg csg_union(cube_1, sphere_1, union, rotation_z(-60))
# csg csg_inter(cube_1, sphere_1, intersection, rotation_z(-60))

#============== CAMERA ==============

camera(perspective, translation([-4, 0, 3]) * rotation_y(25), 2)
```
