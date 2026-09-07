# Informe de orquestación — 2026-09-05

Tarea: `.ai/tasks/2026-09-05-agents-sketchybar-notch.md`
Base: `merge` @ `89c793c` (más los cambios sin commit del checkout principal).
Este informe se rastrea en Git a petición del usuario; el de 2026-09-03 se
retiró de `.gitignore` y su contenido esencial vive en
`.ai/tasks/2026-09-03-repo-hardening.md`.

## Topología

| Rol | Agente | Panel | Rama / worktree |
| --- | --- | --- | --- |
| Orquestador | Claude Fable 5.1 | `wM:p1` (izquierda) | `merge`, checkout principal |
| Worker | Codex `gpt-6-astra` (`codex-notch`) | `wM:p4` (arriba derecha) | `agent/codex/2026-09-05-notch` → `~/.herdr/worktrees/nix-darwin/agent-codex-2026-09-05-notch` |
| Worker | Copilot CLI 1.0.61 (`copilot -p`) | `wM:p5` (abajo derecha) | `agent/copilot/2026-09-05-agents` → `~/.herdr/worktrees/nix-darwin/agent-copilot-2026-09-05-agents` |

Ningún worker hizo commit, merge ni push. Cada uno trabajó en su worktree; el
orquestador revisó los diffs, ejecutó las validaciones e integró en el checkout
principal. Los worktrees y ramas quedan para inspección.

## Cambios y mejoras

### 1. SketchyBar: modo con notch conmutable (Codex)

Archivos: `configs/sketchybar/settings.lua`, `bar.lua`, `items/init.lua`,
`items/media.lua`, `items/weather.lua`, `items/calendar.lua`.

- **Un solo interruptor.** Primera línea de `settings.lua`:
  `local notch = false`. Es el único cambio necesario para alternar. Por
  defecto queda en modo sin notch.
- **Modo sin notch** (por defecto): la barra queda idéntica a la actual. Codex
  lo verificó con un stub de SbarLua comparando los atributos generados con
  HEAD (`PASS: notch=false ... identical to HEAD`).
- **Modo con notch** (`notch = true`): barra pegada al borde superior
  (`y_offset = 0`, `margin = 0`, `corner_radius = 0`), altura 38 px,
  `notch_display_height = 38`, `notch_width = 200`, `notch_offset = 0`.
  El grupo central se divide para no quedar bajo el notch: los ítems de media
  pasan a la posición `q` (izquierda del notch) y clima/fecha/hora a `e`
  (derecha), cada bloque con su propio bracket (`bracket.media` y
  `bracket.info`).
- **Diseño mínimo.** Una tabla `mode` en `settings.lua` expone
  `settings.notch`, `settings.position.{media,info}` y los campos nuevos de
  `settings.layout`. Los ítems leen la posición desde `settings` en lugar de
  duplicar archivos. En modo sin notch los campos específicos del notch son
  `nil` y SbarLua los omite.
- Ajuste fino disponible sin tocar más código: `notch_width` (200 px) y las
  alturas viven en la misma tabla `mode`.

### 2. Configuración de agentes e IA (Copilot)

Archivos: `configs/agents/default.nix`, `configs/codex.nix`, `.gitignore`.

- **Skills sin duplicar.** Los 16 bloques `home.file` (8 skills × `.claude/skills`
  y `.agents/skills`) se sustituyen por un attrset `skills = { nombre = ruta; }`
  y una generación con `lib.listToAttrs`/`lib.concatMap`. Añadir una skill
  para Claude y Codex a la vez es ahora una línea. El conjunto resultante de
  `home.file` es idéntico (16 entradas, mismas rutas de origen; verificado con
  `nix eval --json` antes y después).
- **Reglas de worker para Codex.** `programs.codex.context` incorpora las
  reglas que ya estaban en la plantilla `AGENTS.md`: en ramas/worktrees
  `agent/*` no hacer merge/push/force-push, no tocar otros worktrees ni el
  checkout principal, el orquestador integra, y reportar archivos, checks,
  riesgos y bloqueos.
- **Informe rastreado.** Se elimina `/ORCHESTRATION-REPORT.md` de `.gitignore`
  (con su comentario). `git check-ignore` confirma que ya no se ignora.

### 3. Mejoras ya presentes en el árbol de trabajo (sesión anterior, integradas aquí)

Se conservan tal cual: `configs/agents/CLAUDE.md` y la plantilla de proyecto
refuerzan el modelo "Claude orquesta, workers implementan" y el modo de
delegación obligatoria; `agent-project-init` ahora actualiza siempre
`CLAUDE.md`, `AGENTS.md` y las skills `orchestrate`, `knowledge-export` y
`herdr`; `codex.nix` declara `package = null` (Homebrew gestiona el CLI).

## Validación (ejecutada por el orquestador en el checkout principal)

| Comprobación | Resultado |
| --- | --- |
| `nix eval .#darwinConfigurations.angel-flake.system.drvPath` | OK → `/nix/store/i5a4w1m6lra47zxbdkh3qxsw1z5d0ji5-darwin-system-26.11.4cff07d.drv` |
| `luac -p` sobre todos los `.lua` de `configs/sketchybar` | OK |
| `git diff --check` | OK |
| Entradas `home.file` de skills antes/después | 16 = 16, mismas rutas |
| `git check-ignore ORCHESTRATION-REPORT.md` | no ignorado |

Los workers ejecutaron además: Codex `luac -p`, `nix eval` y la comparación
con stub de SbarLua; Copilot no pudo ejecutar `nix` por la política de
permisos del modo `-p`, así que el orquestador cubrió esa validación.

## Riesgos y pendientes

- **No se ha renderizado la barra en modo notch.** Este Mac no tiene notch y
  no se ejecutó `darwin-rebuild` ni `sketchybar --reload`. Al probar en un Mac
  con notch conviene revisar `notch_width` (200 px) y que los dos grupos
  laterales quepan en pantalla.
- **Aplicar los cambios** requiere `darwin-rebuild switch --flake .` y, si la
  barra ya está corriendo, `sketchybar --reload`.
- Herdr sigue sin clasificar Copilot CLI 1.0.61 aunque `copilot` aparece como
  tipo de agente; la delegación se hizo con `copilot -p` en un panel shell.
- Codex necesitó una aprobación para `luac`/`nix eval` (caché de Nix fuera del
  sandbox). El orquestador la concedió por tratarse de las validaciones
  exigidas en el contrato, de solo lectura.
- Nada se ha commiteado; todo el trabajo está en el árbol de trabajo de `merge`.

## Considerado y descartado

- Instrucciones globales para Copilot (`~/.copilot/...`): no hay una ruta
  verificada en la versión instalada; se apoya en el `AGENTS.md` del proyecto.
- Gestionar `~/.claude/settings.json` desde Nix: riesgo de pisar ajustes
  vivos del usuario; fuera del alcance.
