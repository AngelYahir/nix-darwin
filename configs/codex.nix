{ ... }:

{
    programs.codex = {
        enable = true;

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
        '';
    };

    # Replace the empty file created by Codex before Home Manager takes over.
    home.file.".codex/AGENTS.md".force = true;
}
