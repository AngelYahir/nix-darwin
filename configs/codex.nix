{ ... }:

{
    programs.codex = {
        enable = true;
        package = null; # The CLI is installed and updated by Homebrew.

        # Codex Desktop updates config.toml with projects, plugins, and MCPs.
        settings = null;
        context = ''
            # Instrucciones globales de Codex

            - Responde en el idioma del usuario.
            - Revisa las convenciones y las instrucciones locales del repositorio antes de editar.
            - Prefiere el cambio correcto más pequeño y reutiliza lo que ya existe.
            - Conserva los cambios ajenos a la tarea y no hagas commits salvo que se soliciten.
            - Ejecuta las comprobaciones pertinentes después de editar e indica lo que no pudiste verificar.
            - Trata `.ai/` como memoria de agentes, no como documentación técnica canónica; respeta las convenciones documentales y de ADR del repositorio.
            - Como trabajador delegado en una rama o worktree `agent/*`, nunca hagas merge, push, force-push ni reescribas el historial compartido.
            - Como trabajador delegado, no toques otros checkouts; el orquestador es el dueño de la integración.
            - Trabaja directamente salvo que delegar aporte una ventaja concreta o se solicite; carga solo skills y referencias necesarias y evita releer contexto disponible.
            - Conserva el modelo y el nivel de razonamiento elegidos; reduce contexto redundante, salidas extensas y consultas de progreso innecesarias.
            - Reporta archivos modificados, comprobaciones ejecutadas, riesgos restantes y bloqueos.
        '';
    };

    # Replace the empty file created by Codex before Home Manager takes over.
    home.file.".codex/AGENTS.md".force = true;
}
