import unreal

def build():
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    
    # 1. Clean ALL existing UltronCore actors
    actors_to_delete = []
    for a in list(subsystem.get_all_level_actors()):
        try:
            label = a.get_actor_label()
            if "Ultron" in label or a.actor_has_tag("UltronCore") or "Matrix_EnergyCore" in label:
                actors_to_delete.append(a)
        except Exception:
            pass
            
    for a in actors_to_delete:
        try:
            subsystem.destroy_actor(a)
        except Exception:
            pass
            
    unreal.log(f"[AssembleUltronCinematic] Cleaned {len(actors_to_delete)} legacy actors.")

    # 2. Load Assets
    mat_holo = unreal.load_asset("/Game/M_Ultron_DigitalHolo.M_Ultron_DigitalHolo")
    mat_nucleus = unreal.load_asset("/Game/MI_UltronAmber_BrightCore.MI_UltronAmber_BrightCore")
    mesh_plane = unreal.load_asset("/Engine/BasicShapes/Plane.Plane")
    mesh_sphere = unreal.load_asset("/Engine/BasicShapes/Sphere.Sphere")
    
    if not mat_holo:
        unreal.log_error("[AssembleUltronCinematic] Failed to load M_Ultron_DigitalHolo!")
        return

    center_loc = unreal.Vector(0.0, 0.0, 165.0)

    # 3. Spawn Helper
    def spawn_element(name, mesh, mat, scale, rot, spin_rate=None):
        actor = subsystem.spawn_actor_from_class(unreal.StaticMeshActor, center_loc, unreal.Rotator(rot[0], rot[1], rot[2]))
        actor.set_actor_label(f"Ultron_{name}")
        actor.tags.append("UltronCore")
        try:
            actor.set_folder_path("UltronCore")
        except Exception:
            pass
            
        smc = actor.static_mesh_component
        smc.set_mobility(unreal.ComponentMobility.MOVABLE)
        smc.set_static_mesh(mesh)
        smc.set_material(0, mat)
        smc.set_world_scale3d(unreal.Vector(scale[0], scale[1], scale[2]))
        smc.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        
        if spin_rate:
            try:
                rot_comp = actor.add_component_by_class(unreal.RotatingMovementComponent, False, unreal.Transform(), False)
                rot_comp.rotation_rate = unreal.Rotator(spin_rate[0], spin_rate[1], spin_rate[2])
            except Exception:
                pass
        return actor

    # 4. Cinematic Digital Astrolabe Hologram Elements
    # A. Intersecting Razor-Thin Planar HUD Dials (Planar meshes scaled to 2.2m - 2.8m diameter)
    spawn_element("Dial_Equatorial", mesh_plane, mat_holo, (2.6, 2.6, 2.6), (0.0, 0.0, 0.0), (0.0, 10.0, 0.0))
    spawn_element("Dial_Polar", mesh_plane, mat_holo, (2.4, 2.4, 2.4), (90.0, 0.0, 0.0), (0.0, 0.0, -12.0))
    spawn_element("Dial_Meridian", mesh_plane, mat_holo, (2.35, 2.35, 2.35), (0.0, 90.0, 0.0), (8.0, 0.0, 0.0))
    
    # B. Tilted Gyroscopic Data Dials
    spawn_element("Dial_ObliqueA", mesh_plane, mat_holo, (2.5, 2.5, 2.5), (45.0, 35.0, 15.0), (12.0, -15.0, 8.0))
    spawn_element("Dial_ObliqueB", mesh_plane, mat_holo, (2.3, 2.3, 2.3), (-45.0, 55.0, -25.0), (-14.0, 18.0, -10.0))
    spawn_element("Dial_ObliqueC", mesh_plane, mat_holo, (2.7, 2.7, 2.7), (65.0, -25.0, 45.0), (16.0, 22.0, -6.0))
    spawn_element("Dial_InnerCore", mesh_plane, mat_holo, (1.2, 1.2, 1.2), (30.0, -45.0, 60.0), (25.0, 35.0, 15.0))

    # C. Outer Detached Telemetry Tracks (Orbiting outside the main sphere)
    spawn_element("Track_OuterOrbitA", mesh_plane, mat_holo, (3.2, 3.2, 3.2), (15.0, 20.0, -10.0), (-5.0, 14.0, 3.0))
    spawn_element("Track_OuterOrbitB", mesh_plane, mat_holo, (3.4, 3.4, 3.4), (-35.0, -40.0, 25.0), (4.0, -12.0, 8.0))

    # D. Concentric Digital Spherical Shells (Produces Latitude/Longitude Digital Wireframe & Synaptic Nodes)
    spawn_element("Shell_OuterConstellation", mesh_sphere, mat_holo, (2.1, 2.1, 2.1), (0.0, 0.0, 0.0), (4.0, 10.0, 2.0))
    spawn_element("Shell_MidConstellation", mesh_sphere, mat_holo, (1.5, 1.5, 1.5), (25.0, -40.0, 15.0), (-8.0, 16.0, -6.0))
    spawn_element("Shell_InnerConstellation", mesh_sphere, mat_holo, (0.85, 0.85, 0.85), (-50.0, 30.0, 70.0), (18.0, -20.0, 12.0))

    # E. Radiant Core Nucleus (Mind Stone energetic focus point)
    spawn_element("Core_Nucleus", mesh_sphere, mat_nucleus, (0.14, 0.14, 0.14), (0.0, 0.0, 0.0), (0.0, 25.0, 0.0))

    # F. Warm Amber Holographic Light
    light_actor = subsystem.spawn_actor_from_class(unreal.PointLight, center_loc, unreal.Rotator(0.0, 0.0, 0.0))
    light_actor.set_actor_label("Ultron_Core_PointLight")
    light_actor.tags.append("UltronCore")
    try:
        light_actor.set_folder_path("UltronCore")
    except Exception:
        pass
        
    plc = light_actor.point_light_component
    plc.set_intensity(4200.0)
    plc.set_light_color(unreal.LinearColor(1.0, 0.58, 0.10, 1.0))
    plc.set_attenuation_radius(480.0)
    plc.set_cast_shadows(False)

    unreal.log_warning("[AssembleUltronCinematic] SUCCESS: Digital HUD Hologram updated with outer telemetry tracks!")

build()
