## 📝 Scene Description Guidelines

RayTracer uses a custom, text-based format to define what will be rendered.

---

### 🔢 1. Float Variables

You can define float constants to use later:

```julia
float angle(0.0)
float pos(1.0)
```

The identifier `angle` is somehow special because you can over-ride it directly from the CLI (see julia RayTracer <tracer> -h for further information). Our purpose is to use it inside camera orientation to make available fast scene preview from CLI. If the option --angle is not used this is a identifier as the other.

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
    - `diffuse` — reflects incoming light uniformly in all directions
    - `specular` — mirror-like reflection

- **Pigments** (color or texture) used inside each type:
    - `uniform(<r, g, b>)` — solid color
    - `checkered(<color1>, <color2>, squares_per_unit)` — checkerboard pattern
    - `image("path/to/image.pfm")` — image-based texture

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


### 🧱 3. Object Definitions

To create an object decide its **shape**, assign a **material** and place it into the scene choosing a **transformation**.

#### **Shapes**
- `sphere` — unit sphere with center in $(0,0,0)$
- `plane` — $z=0$ plane

#### **Transformation**
- `identity` — No transformation
- `translation([x, y, z])` —  Translates the object by the vector $\vec{v} = (x, y, z)$
- `scaling(sx, sy, sz)` — Scales the object along each axis. All values must be non-zero. Use negative values to apply reflections.
- `rotation_x(deg)` — Rotates the object around the **x-axis** by the given angle in degrees.
- `rotation_y(deg)` — Rotates the object around the **y-axis** by the given angle in degrees.
- `rotation_z(deg)` — Rotates the object around the **z-axis** by the given angle in degrees.


You can **combine transformations** using the `*` operator. Transformations are applied **right to left**, like function composition. ??????


#### **Example**:
```julia
sphere(plane_material, scaling(50, 50, 50) * translation([1, 1, 2]))
```
This creates a `sphere` with material identified by `plane_material` (previously defined) that has 
radius $50$ and origin in $(1,1,2)$.

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

### Working example
*Note* — You can write comment using `#`
```julia
TBD
```