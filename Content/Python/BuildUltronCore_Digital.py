import unreal

def build():
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    
    # 1. Clean existing UltronCore actors
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
            
    unreal.log(f"[BuildUltronCore] Cleaned {len(actors_to_delete)} legacy actors.")

    # 2. Load Assets
    mat_holo = unreal.load_asset("/Game/M_Ultron_DigitalHolo.M_Ultron_DigitalHolo")
    mesh_plane = unreal.load_asset("/Engine/BasicShapes/Plane.Plane")
    mesh_sphere = unreal.load_asset("/Engine/BasicShapes/Sphere.Sphere")
    mesh_ring = unreal.load_asset("/Engine/InteractiveToolsFramework/Meshes/GizmoFullCircleHandle.GizmoFullCircleHandle")
    mesh_arc = unreal.load_asset("/Engine/InteractiveToolsFramework/Meshes/GizmoQuarterCircleHandle.GizmoQuarterCircleHandle")
    
    if not mat_holo:
        unreal.log_error("[BuildUltronCore] Failed to load M_Ultron_DigitalHolo!")
        return

    center_loc = unreal.Vector(0.0, 0.0, 165.0)

    # Helper function
    def spawn_holo_element(name, mesh, scale, rot, spin_rate=None):
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
        smc.set_material(0, mat_holo)
        smc.set_world_scale3d(unreal.Vector(scale[0], scale[1], scale[2]))
        smc.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        
        if spin_rate:
            try:
                rot_comp = actor.add_component_by_class(unreal.RotatingMovementComponent, False, unreal.Transform(), False)
                rot_comp.rotation_rate = unreal.Rotator(spin_rate[0], spin_rate[1], spin_rate[2])
            except Exception:
                pass
        return actor

    # 3. Holographic Planar HUD Dials (These display the concentric rings, radial tick marks, and arcs)
    # Equatorial Main Dial
    spawn_holo_element("EquatorialDial", mesh_plane, (1.8, 1.8, 1.8), (0.0, 0.0, 0.0), (0.0, 8.0, 0.0))
    # Polar Dial
    spawn_holo_element("PolarDial", mesh_plane, (1.65, 1.65, 1.65), (90.0, 0.0, 0.0), (0.0, 0.0, -10.0))
    # Oblique Gimbal Dials
    spawn_holo_element("GimbalDialA", mesh_plane, (1.7, 1.7, 1.7), (45.0, 30.0, 0.0), (6.0, 15.0, 8.0))
    spawn_holo_element("GimbalDialB", mesh_plane, (1.6, 1.6, 1.6), (-45.0, 60.0, 20.0), (-8.0, -12.0, 10.0))
    spawn_holo_element("InnerCoreDial", mesh_plane, (0.85, 0.85, 0.85), (25.0, -45.0, 30.0), (25.0, 40.0, 15.0))

    # 4. Concentric Holographic Spherical Cages (Fresnel Shells with data lattice)
    spawn_holo_element("OuterHoloSphere", mesh_sphere, (1.5, 1.5, 1.5), (0.0, 0.0, 0.0), (5.0, 12.0, 3.0))
    spawn_holo_element("MidHoloSphere", mesh_sphere, (1.1, 1.1, 1.1), (30.0, 45.0, 0.0), (-10.0, 18.0, -8.0))
    spawn_holo_element("NucleusHoloSphere", mesh_sphere, (0.45, 0.45, 0.45), (0.0, 0.0, 0.0), (15.0, -25.0, 20.0))

    # 5. Fine Additive Telemetry Ring Filaments (Floating boundary tracks)
    spawn_holo_element("FilamentRing1", mesh_ring, (0.75, 0.75, 0.75), (60.0, -20.0, 45.0), (18.0, 32.0, -15.0))
    spawn_holo_element("FilamentRing2", mesh_ring, (0.95, 0.95, 0.95), (-30.0, 140.0, -70.0), (-22.0, -28.0, 10.0))
    spawn_holo_element("FilamentArc1", mesh_arc, (1.05, 1.05, 1.05), (0.0, 35.0, 0.0), (4.0, 24.0, 0.0))
    spawn_holo_element("FilamentArc2", mesh_arc, (1.05, 1.05, 1.05), (0.0, 215.0, 0.0), (4.0, 24.0, 0.0))

    # 6. Warm Amber Light
    light_actor = subsystem.spawn_actor_from_class(unreal.PointLight, center_loc, unreal.Rotator(0.0, 0.0, 0.0))
    light_actor.set_actor_label("Ultron_Core_PointLight")
    light_actor.tags.append("UltronCore")
    try:
        light_actor.set_folder_path("UltronCore")
    except Exception:
        pass
        
    plc = light_actor.point_light_component
    plc.set_intensity(5000.0)
    plc.set_light_color(unreal.LinearColor(1.0, 0.58, 0.10, 1.0))
    plc.set_attenuation_radius(450.0)
    plc.set_cast_shadows(False)

    unreal.log_warning("[BuildUltronCore_Digital] SUCCESS: True digital Ultron Hologram assembled!")

build()
