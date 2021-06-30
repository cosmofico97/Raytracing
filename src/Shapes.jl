# -*- encoding: utf-8 -*-
#
# The MIT License (MIT)
#
# Copyright © 2021 Matteo Foglieni and Riccardo Gervasoni
#

##########################################################################################92

@doc raw"""
    sphere_point_to_uv(point::Point) :: Vec2d

Convert a 3D `point` ``P = (P_x, P_y, P_z)`` on the surface of the unit sphere
into a 2D `Vec2d` using the following spherical coordinates:

```math
u = \frac{\phi}{2\pi} = \frac{\arctan (P_y / P_x)}{2\pi}, 
    \quad 
v = \frac{\theta}{\pi} = \frac{\arccos (P_z)}{\pi}
```

See also: [`Point`](@ref), [`Vec2d`](@ref), [`Sphere`](@ref)
"""
function sphere_point_to_uv(point::Point)
    v = acos(point.v[3]) / π
    u = atan(point.v[2], point.v[1]) / (2.0 * π)
    u = u>=0 ? u : u + 1.0
    return Vec2d(u,v)
end

@doc raw"""
    plane_point_to_uv(point::Point) :: Vec2d

Convert a 3D `point` ``P = (P_x, P_y, P_z)`` on the surface of the unit plane
into a 2D `Vec2d` using the following periodical coordinates:

```math
u = P_x - \lfloor P_x \rfloor,
    \quad 
v = P_y - \lfloor P_y \rfloor,
```
    
where ``\lfloor \cdot \rfloor`` indicates the rounding down approximation,
in order to guarantee that ``u, v \in [0, 1)``.

See also: [`Point`](@ref), [`Vec2d`](@ref), [`Plane`](@ref)
"""
function plane_point_to_uv(point::Point)
    u = point.v[1] - floor(point.v[1])
    v = point.v[2] - floor(point.v[2])
    return Vec2d(u,v)
end

@doc raw"""
    cube_point_to_uv(point::Point) :: Vec2d

Convert a 3D `point` ``P = (P_x, P_y, P_z)`` on the surface of the unit cube
into a 2D `Vec2d` using the following  coordinates:

```math
P_x = \frac{1}{2} \lor P_x = -\frac{1}{2} 
\quad \Rightarrow \quad 
u = P_y +  \frac{1}{2} \; , \;   v = P_z +  \frac{1}{2}
```
```math
P_y = \frac{1}{2} \lor P_y = -\frac{1}{2} 
\quad \Rightarrow \quad 
u = P_x +  \frac{1}{2} \; , \;   v = P_z +  \frac{1}{2}
```
```math
P_z = \frac{1}{2} \lor P_z = -\frac{1}{2} 
\quad \Rightarrow \quad 
u = P_x +  \frac{1}{2} \; , \;   v = P_y +  \frac{1}{2}
```
```math
P_x \neq \frac{1}{2},  -\frac{1}{2} \land
P_y \neq \frac{1}{2},  -\frac{1}{2} \land
P_z \neq \frac{1}{2},  -\frac{1}{2} 
\quad \Rightarrow \quad 
\mathrm{throw Exception}
```

See also: [`Point`](@ref), [`Vec2d`](@ref), [`Cube`](@ref)
"""
function cube_point_to_uv(point::Point)
#=    X = point.v[1]
    Y = point.v[2]
    Z = point.v[3]

    if (abs(X) ≈ 0.5)
        u, v  = Y + 0.5, Y + 0.5
    elseif (abs(Y) ≈ 0.5)
        u, v  = X + 0.5, Y + 0.5
    elseif (abs(Z) ≈ 0.5) 
        u, v  = X + 0.5, Y + 0.5 
    else
        throw(ArgumentError("the given point do not belong to the unit cube."))
    end   
=#
if (abs(point.v[1]) ≈ 0.5)
    u, v  = point.v[2] + 0.5, point.v[2] + 0.5
elseif (abs(point.v[2]) ≈ 0.5)
    u, v  = point.v[1] + 0.5, point.v[2] + 0.5
elseif (abs(point.v[3]) ≈ 0.5) 
    u, v  = point.v[1] + 0.5, point.v[2] + 0.5 
else
    throw(ArgumentError("the given point do not belong to the unit cube."))
end
    return Vec2d(u,v)
end


function torus_point_to_uv(point::Point)
    len_point = norm(point)
    u = asin(point.v[2]/len_point) / π
    v = atan(point.v[3], point.v[1]) / (2.0 * π)
    v>=0 ? nothing : v+= 1.0
    u>=0 ? nothing : u+= 1.0
    return Vec2d(u,v)
end


@doc raw"""
    triangle_point_to_uv(triangle::Triangle, point::Point) :: Vec2d

Return the barycentic coordinates of the given `point` for the input
`triangle`.

If the triangle is made of the vertexes ``(A,B,C)`` (memorized in this order),
then the point ``P`` has coordinates ``(u,v) = (\beta, \gamma)`` such that:
```math
    P(\beta, \gamma) = A + \beta \,(B - A) + \gamma \,(C-A)
```
The analitic resolution of this linear system is:
```math
\begin{aligned}
&\beta = \frac{
            (P_x - A_x)(C_y - A_y) - (P_y - A_y)(C_x - A_x)
        }{
            (B_x - A_x)(C_y - A_y) - (B_y - A_y)(C_x - A_x)
        } \\
&\gamma = \frac{
            (P_x - A_x)(B_y - A_y) - (P_y - A_y)(B_x - A_x)
        }{
            (C_x - A_x)(B_y - A_y) - (C_y - A_y)(B_x - A_x)
        }
\end{aligned}
```

**NOTE**: this function do not check if ``P`` is on the plane defined by ``(A,B,C)``, 
neither if ``P`` is inside the triangle made of them!

See also: [`Triangle`](@ref), [`Vec2d`](@ref), [`Point`](@ref)
"""
function triangle_point_to_uv(triangle::Triangle, point::Point)
    A, B, C = Tuple(P for P in triangle.vertexes)
#=    P1 = point - A
    P2 = B-A
    P3 = C-A


    β_num = (P1.v[1])*(P3.v[2]) - (P1.v[2])*(P3.v[1])
    β_den = (P2.v[1])*(P3.v[2]) - (P2.v[2])*(P3.v[1])
    β = β_num/β_den

    γ_num = (P1.v[1])*(P2.v[2]) - (P1.v[2])*(P2.v[1])
    γ_den = (P3.v[1])*(P2.v[2]) - (P3.v[2])*(P2.v[1])
=#
#=    β_num = (point.v[1] - A.v[1])*(C.v[2]-B.v[2]) - (B.v[2]-A.v[2])*(C.v[1]-A.v[1])
    β_den = (B.v[1]-A.v[1])*(C.v[2]-A.v[2]) - (B.v[2]-A.v[2])*(C.v[1]-A.v[1])
    β = β_num/β_den

    γ_num = (point.v[1] - A.v[1])*(B.v[2]-A.v[2]) - (B.v[2]-A.v[2])*(B.v[1]-A.v[1])
    γ_den = (C.v[1]-A.v[1])*(B.v[2]-A.v[2]) - (C.v[2]-B.v[2])*(B.v[1]-A.v[1])

    γ = γ_num/γ_den

    Vec2d(β, γ)
=#

    Vec2d(((point.v[1] - A.v[1])*(C.v[2]-B.v[2]) - (B.v[2]-A.v[2])*(C.v[1]-A.v[1])) / ((B.v[1]-A.v[1])*(C.v[2]-A.v[2]) - (B.v[2]-A.v[2])*(C.v[1]-A.v[1])),
          ((point.v[1] - A.v[1])*(B.v[2]-A.v[2]) - (B.v[2]-A.v[2])*(B.v[1]-A.v[1])) / ((C.v[1]-A.v[1])*(B.v[2]-A.v[2]) - (C.v[2]-B.v[2])*(B.v[1]-A.v[1]))
    )
end

##########################################################################################92

@doc raw"""
    sphere_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit sphere.

The normal is computed for the given `Point` ``point = (P_x, P_y, P_z)`` 
(with ``\sqrt{P_x^2 + P_y^2 + P_z^2}=1``) on the 
surface of the sphere, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Sphere`](@ref)
"""
function sphere_normal(point::Point, ray_dir::Vec)
    result = Normal(point.v...) # (point.v[1], point.v[2], point.v[3])
    Vec(point) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

@doc raw"""
    plane_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit plane.

The normal is computed for the given `point` ``P = (P_x, P_y, 0)`` on the 
surface of the plane, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Plane`](@ref)
"""
function plane_normal(point::Point, ray_dir::Vec)
    result = Normal(0., 0., 1.)
    Vec(0., 0., 1.) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

@doc raw"""
    cube_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit cube.

The normal is computed for the given `point` on the 
surface of the cube, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Cube`](@ref)
"""
function cube_normal(point::Point, ray_dir::Vec)
    if (abs(point.v[1]) ≈ 0.5)
        result = Normal(1., 0., 0.)
    elseif (abs(point.v[2]) ≈ 0.5)
        result = Normal(0., 1., 0.)
    elseif (abs(point.v[3]) ≈ 0.5) 
        result = Normal(0., 0., 1.)
    else
        throw(ArgumentError("the given point do not belong to the unit cube."))
    end 

    result ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

"""
    torus_normal(p::Point, ray_dir::Vec, R::Float64) -> Normal

Compite the [`Normal`](@ref) of a torus

The normal is computed for [`Point`](@ref) (a point on the surface of the
torus), and it is chosen so that it is always in the opposite
direction with respect to `ray_dir` ([`Vec`](@ref)).
"""
function torus_normal(p::Point, ray_dir::Vec, R::Float64)
    R_z = copysign(R / √(1+(p.x/p.z)^2), p.z)
    R_x = copysign(p.x / p.z * R_z, p.x)
    R_p = Vec(R_x, 0, R_z)
    result = Normal(Vec(p - R_p))
    result ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

@doc raw"""
    triangle_normal(triangle::Triangle, ray_dir::Vec) :: Normal

Compute the `Normal` of a given triangle.

The normal for a triangle with vertexes ``(A, B, C)`` is computed as follows:
```math
    n = \pm (B-A) \times (C-A)
```
where the sign is chosen so that it is always in the opposite
direction with respect to the given `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Triangle`](@ref)
"""
function triangle_normal(triangle::Triangle, ray_dir::Vec)
    result = (triangle.vertexes[2] -  triangle.vertexes[1]) ×
                (triangle.vertexes[3] -  triangle.vertexes[1])
    result ⋅ ray_dir < 0.0 ? nothing : result = -result
    return Normal(result)
end


@doc raw"""
    triangle_barycenter(triangle::Triangle) :: Point

Return the barycenter of the given `triangle`.

For a triangle with vertexes ``(A, B, C)``, the barycenter
is ``M``:
```math
    M = \frac{A + B + C}{3}
```

See also: [`Triangle`](@ref), [`Point`](@ref)
"""
function triangle_barycenter(triangle::Triangle)
#    A, B, C = Tuple(P for P in triangle.vertexes)
#    P = sum(triangle.vertexes)
#    result = Point(A.v[1]+B.v[1]+C.v[1], A.v[2]+B.v[2]+C.v[2], A.v[3]+B.v[3]+C.v[3])*1/3
    result = Point((sum(triangle.vertexes))...)*1/3
    return result
end


##########################################################################################92


"""
    ray_intersection(shape::Shape, ray::Ray) :: Union{HitRecord, Nothing}

Compute the intersection between a `Ray` and a `Shape`.

See also: [`Ray`](@ref), [`Shape`](@ref)
"""
function ray_intersection(shape::Shape, ray::Ray)
    return ErrorException(
            "ray_intersection is an abstract method"*
            "and cannot be called directly"
            )
end


"""
    ray_intersection(AABB::AABB, ray::Ray) :: Bool

Check if the `ray` intersects the `AABB`.
Return `true` if intersection occurs, `false` otherwise.

See also: [`Ray`](@ref), [`AABB`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(AABB::AABB, ray::Ray)
#    P1 = (AABB.m - ray.origin) / ray.dir
#    P2 = (AABB.M - ray.origin) / ray.dir
    (tmin, tmax) = Tuple( sort( [ 
                        (AABB.m.v[1] - ray.origin.v[1]) / ray.dir.v[1], 
                        (AABB.M.v[1] - ray.origin.v[1]) / ray.dir.v[1]
#                            P1.v[1], P2.v[1]
                    ]) )
    (tymin, tymax) = Tuple( sort( [ 
                        (AABB.m.v[2] - ray.origin.v[2]) / ray.dir.v[2], 
                        (AABB.M.v[2] - ray.origin.v[2]) / ray.dir.v[2]
#                            P1.v[2], P2.v[2]
                    ]) )
 
    ((tmin > tymax) || (tymin > tmax)) && (return false)
 
    (tymin > tmin) && (tmin = tymin)
    (tymax < tmax) && (tmax = tymax)

    (tzmin, tzmax) = Tuple( sort( [ 
                        (AABB.m.v[3] - ray.origin.v[3]) / ray.dir.v[3], 
                        (AABB.M.v[3] - ray.origin.v[3]) / ray.dir.v[3]
#                            P1.v[3], P2.v[3]
                    ]) )
 
    ((tmin > tzmax) || (tzmin > tmax)) && (return false)
 
    (tzmin > tmin) && (tmin = tzmin)
    (tzmax < tmax) && (tmax = tzmax)
 
    if (ray.tmin ≤ tmin ≤ ray.tmax) || ( ray.tmin ≤ tmax ≤ ray.tmax)
        return true
    else
        return false
    end
end


"""
    ray_intersection(sphere::Sphere, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `sphere`.
Return a `HitRecord`, or `nothing` if no intersection is found.

See also: [`Ray`](@ref), [`Sphere`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(sphere::Sphere, ray::Ray)

    (ray_intersection(sphere.AABB, ray) == true) || (return nothing)

    inv_ray = inverse(sphere.T) * ray
    origin_vec = Vec(inv_ray.origin)

    a = squared_norm(inv_ray.dir)
    b = 2.0f0 * origin_vec ⋅ inv_ray.dir
    c = squared_norm(origin_vec) - 1.0f0
    Δ = b * b - 4.0f0 * a * c 
     
    (Δ > 0.0f0) || (return nothing)

    tmin = (-b - √Δ) / (2.0f0 * a)
    tmax = (-b + √Δ) / (2.0f0 * a)

    if (tmin > inv_ray.tmin) && (tmin < inv_ray.tmax)
        first_hit_t = tmin
    elseif (tmax > inv_ray.tmin) && (tmax < inv_ray.tmax)
        first_hit_t = tmax
    else
        return nothing
    end

    hit_point = at(inv_ray, first_hit_t)
    
    return HitRecord(
        sphere.T * hit_point,
        sphere.T * sphere_normal(hit_point, inv_ray.dir),
        sphere_point_to_uv(hit_point),
        first_hit_t,
        ray, 
        sphere
    )
end


"""
    ray_intersection(plane::Plane, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `plane`.
Return a `HitRecord`, or `nothing` if no intersection is found.

See also: [`Ray`](@ref), [`Plane`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(plane::Plane, ray::Ray)
    inv_ray = inverse(plane.T) * ray

    !(inv_ray.dir.v[3] ≈ 0.0f0) || (return nothing)

    hit_t = - inv_ray.origin.v[3] / inv_ray.dir.v[3]

    ( (hit_t > inv_ray.tmin) && (hit_t < inv_ray.tmax) ) || (return nothing)

    hit_point = at(inv_ray, hit_t)

    return HitRecord(
        plane.T * hit_point,
        plane.T * plane_normal(hit_point, inv_ray.dir),
        plane_point_to_uv(hit_point),
        hit_t,
        ray,
        plane
    )
end


"""
    ray_intersection(cube::Cube, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `cube`.
Return a `HitRecord`, or `nothing` if no intersection is found.

The implementation is only a long boring list of `if`-`else` block statements,
and may have to be optimized.

See also: [`Ray`](@ref), [`Cube`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(cube::Cube, ray::Ray)
    (ray_intersection(cube.AABB, ray) == true) || (return nothing)

    inv_ray = inverse(cube.T) * ray
    d = inv_ray.dir
    O = inv_ray.origin

    (tmin, tmax) = Tuple( sort( [ (-0.5f0 - O.v[1]) / d.v[1], (0.5f0 - O.v[1]) / d.v[1] ]) )
    (tymin, tymax) = Tuple( sort( [ (-0.5f0 - O.v[2]) / d.v[2], (0.5f0 - O.v[2]) / d.v[2] ]) )
 
    ((tmin > tymax) || (tymin > tmax)) && (return false)
 
    (tymin > tmin) && (tmin = tymin)
    (tymax < tmax) && (tmax = tymax)

    (tzmin, tzmax) = Tuple( sort( [ (-0.5f0 - O.v[3]) / d.v[3], (0.5f0 - O.v[3]) / d.v[3] ]) )
 
    ((tmin > tzmax) || (tzmin > tmax)) && (return false)
 
    (tzmin > tmin) && (tmin = tzmin)
    (tzmax < tmax) && (tmax = tzmax)
 
    if (inv_ray.tmin ≤ tmin ≤ inv_ray.tmax) 
        hit_point = at(inv_ray, tmin)
        return HitRecord(
            cube.T * hit_point,
            cube.T * cube_normal(hit_point, inv_ray.dir),
            cube_point_to_uv(hit_point),
            tmin,
            ray,
            cube
        )
    elseif ( inv_ray.tmin ≤ tmax ≤ inv_ray.tmax)
        hit_point = at(inv_ray, tmax)
        return HitRecord(
            cube.T * hit_point,
            cube.T * cube_normal(hit_point, inv_ray.dir),
            cube_point_to_uv(hit_point),
            tmax,
            ray,
            cube
        )
    else
        return nothing
    end
end


function ray_intersection(torus::Torus, ray::Ray)
    inv_ray = inverse(torus.T) * ray

    d = normalize(inv_ray.dir)
    o = inv_ray.origin
    norm²_d = squared_norm(d)
    norm²_o = squared_norm(Vec(o))
    r = torus.r
    R = torus.R
    c4 = norm²_d^2
    c3 = 4 * norm²_d * (Vec(o) ⋅ d)
    c2 = 2 * norm²_d * (norm²_o - r^2 - R^2) + 4 * (Vec(o) ⋅ d)^2 + 4 * R^2 * (d.y)^2
    c1 = 4 * (norm²_o - r^2 - R^2) *  (Vec(o) ⋅ d) + 8 * R^2 * o.y * d.y
    c0 = (norm²_o - r^2 - R^2)^2 - 4 * R^2 * (r^2 - (o.y)^2)

    t_ints = roots(Polynomial([c0, c1, c2, c3, c4]))

    hit_t = Union{Float64, Nothing}
    hit_t = nothing
    for i in t_ints
        if typeof(i) == Float64
            if (i > inv_ray.tmin) && (i < inv_ray.tmax)
                hit_t = i
            end
        end
    end

    if hit_t == nothing
        return nothing
    end
    
    hit_point = at(inv_ray, hit_t)

    return HitRecord(
        torus.T * hit_point,
        torus.T * torus_normal(hit_point, inv_ray.dir, torus.R),
        torus_point_to_uv(hit_point), # manca la funzione
        hit_t,
        ray, 
        torus
    )
end


@doc raw"""
    ray_intersection(triangle::Triangle, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `triangle`.
Return a `HitRecord`, or `nothing` if no intersection is found.

For a triangle with vertexes ``(A, B, C)`` and a ray defined with the
simple equation ``r(t) = O + t \, \vec{d}``, the coordinates ``(u,v) = (\beta, \gamma)``
and the `t` value of intersection are obtained solving this linear system:
```math

\begin{bmatrix}
    B_x-A_x & C_x-A_x & -d_x \\
    B_y-A_y & C_y-A_y & -d_y \\
    B_z-A_z & C_z-A_z & -d_z 
\end{bmatrix}

\begin{bmatrix}
u \\
v \\
t
\end{bmatrix}
= 
\begin{bmatrix}
O_x - A_x\\
O_z - A_z\\
O_z - A_z
\end{bmatrix}
```

See also: [`Ray`](@ref), [`Triangle`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(triangle::Triangle, ray::Ray)

    A, B, C = Tuple(P for P in triangle.vertexes)
    m = [ray.origin.v[1]-A.v[1];  ray.origin.v[2]-A.v[2]; ray.origin.v[3]-A.v[3]]
#    P1 = (B-A)
#    P2 = (C-A)
    M = [
        (B.v[1]-A.v[1]) (C.v[1]-A.v[1]) -ray.dir.v[1] ;
        (B.v[2]-A.v[2]) (C.v[2]-A.v[2]) -ray.dir.v[2] ;
        (B.v[3]-A.v[3]) (C.v[3]-A.v[3]) -ray.dir.v[3] ;
    ]

    try
        w = transpose(m) / transpose(M)
        u, v, hit_t = Tuple(x for x in w)
        ( ray.tmin < hit_t < ray.tmax ) || (return nothing)
        ( (u>0.) && (v>0.) && (1-u-v>0.) ) || (return nothing)
        hit_point = at(ray, hit_t)
        return HitRecord(
            hit_point,
            triangle_normal(triangle, ray.dir),
            Vec2d(u,v),
            hit_t,
            ray,
            triangle
        )
    catch Excep
        return nothing
    end
end


"""
    ray_intersection(world::World, ray::Ray) :: Union{HitRecord, Nothing}

Determine whether the `ray` intersects any of the objects of the given `world`.
Return a `HitRecord`, or `nothing` if no intersection is found.

See also: [`Ray`](@ref), [`World`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(world::World, ray::Ray)
    closest = nothing

    for shape in world.shapes
        intersection = ray_intersection(shape, ray)

        # The ray missed this shape, skip to the next one
        !(isnothing(intersection)) || continue

        # There was a hit, and it was closer than any other hit found before
        ( isnothing(closest) || (intersection.t < closest.t) ) &&  (closest = intersection)
    end
    
    return closest
end

##########################################################################################92

"""
    add_shape!(world::World, shape::Shape)

Append a new `shape` to the given `world`.

See also: [`Shape`](@ref), [`World`](@ref)
"""
function add_shape!(world::World, S::Shape)
    push!(world.shapes, S)
    return nothing
end


"""
    add_light!(world::World, pointlight::PointLight)

Append a new `pointlight` to the given `world`.

See also: [`PointLight`](@ref), [`World`](@ref)
"""
function add_light!(world::World, pointlight::PointLight)
    push!(world.point_lights, pointlight)
    return nothing
end

##########################################################################################92

"""
    quick_ray_intersection(shape::Shape, ray::Ray) :: Bool

Quickly determine whether the `ray` hits the `shape` or not.

See also: [`Shape`](@ref), [`Ray`](@ref)
"""
function quick_ray_intersection(shape::Shape, ray::Ray)
    return ErrorException(
            "quick_ray_intersection is an abstract method"*
            "and cannot be called directlly")
end

"""
    quick_ray_intersection(sphere::Sphere, ray::Ray) :: Bool

Quickly checks if the `ray` intersects the `sphere` or not.

See also: [`Sphere`](@ref), [`Ray`](@ref)
"""
function quick_ray_intersection(sphere::Sphere, ray::Ray)
    inv_ray = inverse(sphere.T) * ray
    origin_vec = Vec(inv_ray.origin)

    a = squared_norm(inv_ray.dir)
    b = 2.0f0 * origin_vec ⋅ inv_ray.dir
    c = squared_norm(origin_vec) - 1.0f0
    Δ = b * b - 4.0f0 * a * c 
     
    (Δ > 0.0) || (return false)

    tmin = (-b - √Δ) / (2.0f0 * a)
    tmax = (-b + √Δ) / (2.0f0 * a)

    return ((inv_ray.tmin < tmin < inv_ray.tmax) || (inv_ray.tmin < tmax < inv_ray.tmax))
end

"""
    quick_ray_intersection(plane::Plane, ray::Ray) :: Bool

Quickly checks if the `ray` intersects the `plane` or not.

See also: [`Plane`](@ref), [`Ray`](@ref)
"""
function quick_ray_intersection(plane::Plane, ray::Ray)
    inv_ray = inverse(plane.T) * ray
    !(inv_ray.dir.v[3] ≈ 0.0f0) || (return false)

    t = -inv_ray.origin.v[3] / inv_ray.dir.v[3]
    return (inv_ray.tmin < t < inv_ray.tmax)
end


"""
    is_point_visible(
            world::World, 
            point::Point, 
            observer_pos::Point
            ) :: Bool

Return `true` if the straight line connecting `observer_pos` to `point`
do not intersect any of the shapes of `world` between the two points,
otherwise return `false`.

See also: [`World`](@ref), [`Point`](@ref)
"""
function is_point_visible(world::World, point::Point, observer_pos::Point)
    direction = point - observer_pos
    dir_norm = norm(direction)

    ray = Ray(observer_pos, direction, 1e-2 / dir_norm, 1.0f0)
    for shape in world.shapes
        if (quick_ray_intersection(shape, ray) == true) && (shape.flag_pointlight==false) 
            return false
        end
    end

    return true
end
