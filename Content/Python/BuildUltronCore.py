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
    mat_amber = unreal.load_asset("/Game/MI_UltronAmber.MI_UltronAmber")
    mat_bright = unreal.load_asset("/Game/MI_UltronAmber_BrightCore.MI_UltronAmber_BrightCore")
    mesh_ring = unreal.load_asset("/Engine/InteractiveToolsFramework/Meshes/GizmoFullCircleHandle.GizmoFullCircleHandle")
    mesh_arc = unreal.load_asset("/Engine/InteractiveToolsFramework/Meshes/GizmoQuarterCircleHandle.GizmoQuarterCircleHandle")
    mesh_sphere = unreal.load_asset("/Engine/BasicShapes/Sphere.Sphere")
    
    if not mat_amber or not mat_bright:
        unreal.log_error("[BuildUltronCore] Failed to load Ultron materials!")
        return

    # Hover comfortably above the pedestal (Pedestal top is ~30cm)
    center_loc = unreal.Vector(0.0, 0.0, 165.0)

    # 3. Helper to create a static mesh actor
    def create_mesh_actor(name, mesh, mat, scale, rot, spin_rate=None):
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
            except Exception as e:
                unreal.log_warning(f"[BuildUltronCore] RotatingMovement fallback for {name}: {e}")
                
        return actor

    # 4. Dense Astrolabe Neural Shells (Ultron Mind Stone architecture)
    # Tier 0: Radiant Singular Nucleus
    create_mesh_actor("Nucleus", mesh_sphere, mat_bright, (0.16, 0.16, 0.16), (0.0, 0.0, 0.0), (0.0, 15.0, 0.0))
    create_mesh_actor("InnerAura", mesh_sphere, mat_amber, (0.24, 0.24, 0.24), (0.0, 0.0, 0.0), (10.0, -20.0, 5.0))

    # Tier 1: Inner High-Speed Gyroscope Cage
    create_mesh_actor("CoreGyro1", mesh_ring, mat_bright, (0.42, 0.42, 0.42), (25.0, -75.0, 15.0), (35.0, 55.0, 20.0))
    create_mesh_actor("CoreGyro2", mesh_ring, mat_bright, (0.46, 0.46, 0.46), (-55.0, 30.0, 45.0), (-40.0, 30.0, -25.0))
    create_mesh_actor("InnerArc1", mesh_arc, mat_bright, (0.52, 0.52, 0.52), (45.0, 10.0, 90.0), (20.0, -45.0, 30.0))

    # Tier 2: Mid Dynamic Astrolabe Shells
    create_mesh_actor("MidPolar", mesh_ring, mat_amber, (0.68, 0.68, 0.68), (-80.0, 15.0, 0.0), (-15.0, 25.0, -10.0))
    create_mesh_actor("MidTiltedA", mesh_ring, mat_amber, (0.78, 0.78, 0.78), (35.0, 40.0, 10.0), (12.0, -18.0, 8.0))
    create_mesh_actor("MidTiltedB", mesh_ring, mat_amber, (0.86, 0.86, 0.86), (-40.0, -50.0, 65.0), (-14.0, 20.0, -12.0))
    create_mesh_actor("MidArc1", mesh_arc, mat_bright, (0.92, 0.92, 0.92), (60.0, -20.0, 45.0), (18.0, 32.0, -15.0))
    create_mesh_actor("MidArc2", mesh_arc, mat_bright, (0.94, 0.94, 0.94), (-30.0, 140.0, -70.0), (-22.0, -28.0, 10.0))

    # Tier 3: Outer Horizon & Telemetry Rings
    create_mesh_actor("OuterEquatorial", mesh_ring, mat_amber, (1.05, 1.05, 1.05), (0.0, 0.0, 0.0), (0.0, 8.0, 0.0))
    create_mesh_actor("OuterOblique", mesh_ring, mat_amber, (1.12, 1.12, 1.12), (18.0, -25.0, 12.0), (6.0, -12.0, 14.0))

    # Tier 4: Broken Telemetry Arcs (Floating data tracks)
    create_mesh_actor("TelemetryTrack1", mesh_arc, mat_bright, (1.20, 1.20, 1.20), (0.0, 40.0, 0.0), (4.0, 24.0, 0.0))
    create_mesh_actor("TelemetryTrack2", mesh_arc, mat_bright, (1.20, 1.20, 1.20), (0.0, 220.0, 0.0), (4.0, 24.0, 0.0))
    create_mesh_actor("TelemetryTrack3", mesh_arc, mat_bright, (1.28, 1.28, 1.28), (40.0, 115.0, -35.0), (-8.0, -16.0, 15.0))
    create_mesh_actor("TelemetryTrack4", mesh_arc, mat_bright, (1.32, 1.32, 1.32), (-50.0, -85.0, 20.0), (10.0, 18.0, -8.0))

    # 5. Core Holographic Point Light
    light_actor = subsystem.spawn_actor_from_class(unreal.PointLight, center_loc, unreal.Rotator(0.0, 0.0, 0.0))
    light_actor.set_actor_label("Ultron_Core_PointLight")
    light_actor.tags.append("UltronCore")
    try:
        light_actor.set_folder_path("UltronCore")
    except Exception:
        pass
        
    plc = light_actor.point_light_component
    plc.set_intensity(4500.0)
    plc.set_light_color(unreal.LinearColor(1.0, 0.58, 0.10, 1.0))
    plc.set_attenuation_radius(480.0)
    plc.set_cast_shadows(False)

    unreal.log_warning(f"[BuildUltronCore] SUCCESS: Ultron Mind Stone Core complete (16 elements) at {center_loc}")

build()
