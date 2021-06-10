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
    v = acos(point.z) / π
    u = atan(point.y, point.x) / (2.0 * π)
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
    u = point.x - floor(point.x)
    v = point.y - floor(point.y)
    return Vec2d(u,v)
end


function torus_point_to_uv(point::Point)
    len_point = norm(point)
    # u = atan(point.y/(point.x^2 + point.z^2)^0.5) / (2. * pi)    # asin(point.y/len_point) / (2.0 * π)
    # v = atan(point.z/point.x) / (2. * pi)   # atan(point.z, point.x) / (2.0 * π)
    u = atan(point.y/point.x) / (2. * pi)
    v = atan(point.z/(point.x^2 + point.z^2)^0.5) / (2. * pi)
    v>=0 ? nothing : v+= 1.0
    u>=0 ? nothing : u+= 1.0
    return Vec2d(u,v)
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
    result = Normal(point.x, point.y, point.z)
    Vec(point) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

@doc raw"""
    plane_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit plane.

The normal is computed for the given `Point` ``point = (P_x, P_y, 0)`` on the 
surface of the plane, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Plane`](@ref)
"""
function plane_normal(point::Point, ray_dir::Vec)
    result = Normal(0., 0., 1.)
    Vec(0., 0., 1.) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

"""
    torus_normal(p::Point, ray_dir::Vec, r::Float64, O::Point) -> Normal

Compite the normal of a torus

The normal is computed for `p` (a point on the surface of the
torus), and it is chosen so that it is always in the opposite
direction with respect to `ray_dir`.

See also: [`Normal`](@ref), [`Point`](@ref), ([`Vec`](@ref))
"""
function torus_normal(p::Point, ray_dir::Vec, r::Float64, O::Point)
#=
    R_z = copysign(R / √(1+(p.x/p.z)^2), p.z)
    R_x = copysign(R_z * p.x / p.z, p.x)
    R_p = Vec(R_x, 0, R_z)
    result = Normal(Vec(p - R_p))
    result ⋅ ray_dir < 0.0 ? nothing : result = -result
=#
#    q = Point(O.x - p.x, O.y - p.y, O.z - p.z)
#    println("\npoint for normal: ", p, "\tq = ", q, "\tO = ", O)
    (abs(p.x) < 1e-6) ? (N_x = 0.) : (N_x = copysign(((1 - (p.z/r)^2) / (1 + (p.y/p.x)^2))^0.5), p.x)
    (abs(p.y) < 1e-6) ? (N_y = 0.) : (N_y = copysign(((1 - (p.z/r)^2) / (1 + (p.x/p.y)^2))^0.5), p.y)
    N_z = p.z/r
    result = Normal(N_x, N_y, N_z)
    result ⋅ ray_dir < 0.0 ? nothing : result = -result
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
    ray_intersection(sphere::Sphere, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `sphere`.
Return a `HitRecord`, or `nothing` if no intersection is found.

See also: [`Ray`](@ref), [`Sphere`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(sphere::Sphere, ray::Ray)
    inv_ray = inverse(sphere.T) * ray
    origin_vec = Vec(inv_ray.origin)

    a = squared_norm(inv_ray.dir)
    b = 2.0 * origin_vec ⋅ inv_ray.dir
    c = squared_norm(origin_vec) - 1.0
    Δ = b * b - 4.0 * a * c 
     
    (Δ > 0.0) || (return nothing)

    tmin = (-b - √Δ) / (2.0 * a)
    tmax = (-b + √Δ) / (2.0 * a)

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

    !(inv_ray.dir.z ≈ 0.) || (return nothing)

    hit_t = - inv_ray.origin.z / inv_ray.dir.z

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
    ray_intersection(torus::Torus, ray::Ray) :: Union{HitRecord, Nothing}

Check if the `ray` intersects the `torus`.
Return a `HitRecord`, or `nothing` if no intersection is found.

See also: [`Ray`](@ref), [`Torus`](@ref), [`HitRecord`](@ref)
"""
function ray_intersection(torus::Torus, ray::Ray)
    inv_ray = inverse(torus.T) * ray
    o = Vec(inv_ray.origin)
#    d = normalize(inv_ray.dir)
    d = inv_ray.dir
    norm2_d = squared_norm(d)
    norm2_o = squared_norm(o)
    scalar_od = o ⋅ d
    r = torus.r
    R = torus.R

    c4 = norm2_d^2
    c3 = 4 * norm2_d * scalar_od
    c2 = 4 * scalar_od^2 + 2 * norm2_d * norm2_o - 4 * R^2 * (norm2_d - d.z^2) + 2 * norm2_d * (R^2 - r^2)
    c1 = 4 * norm2_o * scalar_od + 4 * scalar_od * (R^2 - r^2) - 8 * (scalar_od - o.z * d.z)
    c0 = norm2_o^2 + (R^2 - r^2)^2 + 2 * norm2_o * (R^2 - r^2) - 4 * R^2 * (norm2_o - o.z^2)

#=
    # form http://blog.marcinchwedczuk.pl/ray-tracing-torus
    c4 = norm²_d^2
    c3 = 4 * norm²_d * (o ⋅ d)
    c2 = 2 * norm²_d * (norm²_o - r^2 - R^2) + 4 * (o ⋅ d)^2 + 4 * R^2 * (d.y)^2
    c1 = 4 * (norm²_o - r^2 - R^2) * (o ⋅ d) + 8 * R^2 * o.y * d.y
    c0 = (norm²_o - r^2 - R^2)^2 - 4 * R^2 * (r^2 - (o.y)^2)
=#
#=
    # mine
    c4 = norm²_d^2 - 4 * R^2 * (norm²_d - d.z^2)
    c3 = 4 * norm²_d * (o ⋅ d) - 16 * R^2 * (norm²_d - d.z^2) * (o ⋅ d - o.z * d.z)
    c2 = 4 * (o ⋅ d)^2 + 2 * norm²_d * norm²_o + 2 * norm²_d * (R^2 - r^2) + 8 * (2 * R^2 * (o ⋅ d - o.z * d.z)^2 - (norm²_o - o.z^2) * (norm²_d * d.z^2))
    c1 = 4 * norm²_o * (o ⋅ d) + 4 * (R^2 - r^2) * (o ⋅ d) - 16 * R^2 * (norm²_o - o.z^2) * (o ⋅ d - o.z * d.z)
    c0 = norm²_o^2 + (R^2 - r^2)^2 + 2 * norm²_o * (R^2 - r^2) - 4 * R^2 * (norm²_o - o.z^2)
=#
#=
    #from site, but adjusted for z-axis symmetry (y -> z)
    c4 = norm²_d^2
    c3 = 4 * norm²_d * (o ⋅ d)
    c2 = 2 * norm²_d * (norm²_o - r^2 - R^2) + 4 * (o ⋅ d)^2 + 4 * R^2 * (d.z)^2
    c1 = 4 * (norm²_o - r^2 - R^2) * (o ⋅ d) + 8 * R^2 * o.z * d.z
    c0 = (norm²_o - r^2 - R^2)^2 - 4 * R^2 * (r^2 - (o.z)^2)
=#

    t_ints = roots(Polynomial([c0, c1, c2, c3, c4]))
    (t_ints == nothing) && (return nothing)

    hit_ts = Vector{Float64}()
#    println("\nt_ints: ", hit_ts)
#    println("len of t_ints: ", length(hit_ts))
#    println(t_ints)
    for i in t_ints
        if (typeof(i) == ComplexF64)
            continue
        elseif (inv_ray.tmin < i < inv_ray.tmax)
            push!(hit_ts, i)
        else
            nothing
        end
#        (typeof(i) == ComplexF64) && continue
#        (inv_ray.tmin < i < inv_ray.tmax) ? push!(hit_ts, i) : nothing
    end
    (length(hit_ts) == 0) && return nothing
#    println("t_min = ", inv_ray.tmin, "\tt_max = ", inv_ray.tmax)
#    println("t_ints: ", hit_ts)
#    println("len of t_ints: ", length(hit_ts), "\ttype: ", typeof(hit_ts))
    hit_t = min(hit_ts...)
#    println("t_hit: ", hit_t, "\n")
    hit_point = at(inv_ray, hit_t)

    return HitRecord(
        torus.T * hit_point,
        torus.T * torus_normal(hit_point, inv_ray.dir, torus.r, torus.O),
        torus_point_to_uv(hit_point), # manca la funzione
        hit_t,
        ray, 
        torus
    )
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
    b = 2.0 * origin_vec ⋅ inv_ray.dir
    c = squared_norm(origin_vec) - 1.0
    Δ = b * b - 4.0 * a * c 
     
    (Δ > 0.0) || (return false)

    tmin = (-b - √Δ) / (2.0 * a)
    tmax = (-b + √Δ) / (2.0 * a)

    return ((inv_ray.tmin < tmin < inv_ray.tmax) || (inv_ray.tmin < tmax < inv_ray.tmax))
end

"""
    quick_ray_intersection(plane::Plane, ray::Ray) :: Bool

Quickly checks if the `ray` intersects the `plane` or not.

See also: [`Plane`](@ref), [`Ray`](@ref)
"""
function quick_ray_intersection(plane::Plane, ray::Ray)
    inv_ray = inverse(plane.T) * ray
    !(inv_ray.dir.z ≈ 0.) || (return false)

    t = -inv_ray.origin.z / inv_ray.dir.z
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

    ray = Ray(observer_pos, direction, 1e-2 / dir_norm, 1.0)
    for shape in world.shapes
        (quick_ray_intersection(shape, ray) == false) || (return false)
    end

    return true
end
