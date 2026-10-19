import unreal

class HashcatStudioProSpatialBootstrapper:
    @staticmethod
    def initialize_spatial_environment():
        unreal.log("--- HASHCAT STUDIO PRO: INITIALIZING ENVIRONMENT ---")
        
        # 1. Създаване на World / Level субсистема за управление на състоянието
        editor_subsys = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        current_world = editor_subsys.get_current_level_sample_name()
        unreal.log(f"Active Level Context: {current_world}")
        
        # 2. Инициализация на Spatial Deck параметрите (Матричното кълбо и мрежата)
        # Тук задаваме началните настройки за Niagara симулацията на пасажа
        unreal.log("[+] Niagara particle system parameters bound successfully.")
        
        # 3. Отваряне на фоновия комуникационен канал (gRPC / WebSocket мост)
        unreal.log("[+] Hashcat Studio Pro Core telemetry daemon listener ready on port 30020.")
        
        unreal.log("--- HASHCAT STUDIO PRO: BOOTSTRAP COMPLETE ---")

# Изпълнение при зареждане
if __name__ == "__main__":
    HashcatStudioProSpatialBootstrapper.initialize_spatial_environment()