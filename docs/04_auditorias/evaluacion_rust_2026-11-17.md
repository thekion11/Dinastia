# Evaluación de Rust (godot-rust / gdext) para Dinastía — 17-11-2026

Encargo: idea del dueño de usar Rust en las partes «inseguras» (memoria y estabilidad); la Auditoría pidió una evaluación con cifras antes de que entre
nada de Rust en `main`. **No se ha reescrito nada**; el prototipo vive fuera del repo (scratchpad de la sesión C++), y aquí va su código completo.

## Resumen y recomendación

**No adoptar Rust ahora.** Mantener C++ + GDScript, y la red de seguridad nueva: la extensión C++ saneada con ASan + UBSan
(`herramientas/sanear_nativo.sh`, en `especiales.sh todo`), que el 17-11 dio **0 accesos fuera de rango, 0 comportamiento indefinido y 0 fugas en
`nativo/src`** en probar_nativo, igualdad_motor y un partido C4 entero.

Por qué:
1. **Velocidad**: en la función de prueba (`roles_base`), Rust (gdext) queda a la par de GDScript y ~50 % más lento que C++. Nuestras funciones
   nativas son casi todas «de intercambio» (leen diccionarios y metas de Godot), y ahí gdext paga conversiones y comprobaciones de tipo por cada
   acceso. La meta del dueño (orden 58) es ganar tiempo de CPU: Rust no lo daría en este tipo de código.
2. **Tamaño**: el mínimo de gdext ya pesa ~3 MB por plataforma con una sola función; toda nuestra extensión C++ pesa 0,8 MB en Linux.
3. **Coste de mantener tres versiones**: hoy cada función nativa tiene gemela GDScript (para Android/Web y como respaldo) y prueba de igualdad. Con
   Rust serían tres implementaciones de cada función, dos cadenas de compilación por plataforma, y el doble de binarios en `bin_nativo/`.
4. **Plataformas**: Linux y Windows compilan; Android necesita el NDK (como C++); **Web es experimental en gdext** (necesita Rust *nightly*,
   `-Zbuild-std` y la versión de Emscripten exacta de Godot), mientras la extensión C++ ya funciona en Web sin hilos.
5. **La seguridad que se busca ya se puede medir**: ASan/UBSan no encontró ningún fallo de memoria en nuestro C++. El riesgo real de nuestras
   funciones nativas no es la memoria sino la **igualdad con la gemela** (que ya vigilan `probar_nativo` y las huellas).

Cuándo reconsiderarlo: si aparece código nativo NUEVO y GRANDE, de cálculo puro con poca interacción con Godot (por ejemplo, un simulador de
temporada entero que reciba datos planos y devuelva resultados), con hilos o con mucha gestión de memoria propia. Ahí Rust sí aporta seguridad
sin perder velocidad. Y también si ASan/UBSan empieza a encontrar fallos de memoria en el C++.

## Cifras

### Compatibilidad
| Pregunta | Resultado |
|---|---|
| ¿gdext con Godot 4.7.2? | Sí: crate `godot` 0.5.5 (09-08-2026) con la opción `api-4-7`. Cargó en Godot 4.7.2 y se llamó desde GDScript sin problemas. |
| Linux x86_64 | Compila y funciona (medido). |
| Windows x86_64 | Compila desde Linux con mingw (`x86_64-pc-windows-gnu`); no se pudo cargar aquí (sin Windows). |
| Android arm64 | `rustup target add aarch64-linux-android` funciona; falta el NDK en el contenedor (igual que para C++: lo hace el CI). Sin probar. |
| Web wasm32 | gdext lo marca experimental: Rust *nightly* + `rust-src` + `-Zbuild-std`, `wasm32-unknown-emscripten` y Emscripten de la versión de Godot; opción `experimental-wasm-nothreads` para la plantilla sin hilos que usamos. Sin probar (no hay emsdk aquí). Con C++ ya funciona. |
| Toolchain | rustc/cargo 1.97.0 ya instalados en el contenedor. |

### Tamaño del binario (release, con LTO, `codegen-units=1`, sin símbolos)
| | Linux x86_64 | Windows x86_64 |
|---|---|---|
| Rust (gdext), **una** función | 3,07 MB | 2,99 MB |
| C++ (godot-cpp), **toda** la extensión (~40 funciones) | 0,80 MB | 2,01 MB |

### Velocidad (`roles_base`, gemela de `MotorRoles.base`; 6.600 llamadas en un partido C4 entre clubes de ESP y ARG; 3 pasadas)
| Versión | µs por llamada | Igualdad |
|---|---|---|
| GDScript (`MotorRoles.base`) | 4,0-4,8 | (referencia) |
| C++ (`roles_base`, godot-cpp) | 2,5-3,0 (−38 %) | 0 distintos de 6.600 |
| Rust (gdext), primera versión directa | 7,0-7,3 (+75 %) | 0 distintos |
| Rust + `AnyDictionary` (sin comprobar tipos) | 7,0-7,3 | 0 distintos |
| Rust + opción `safeguards-release-disengaged` | 4,5-5,0 | 0 distintos |
| Rust + claves `StringName` guardadas en el objeto | **3,8-4,4 (−6 %)** | 0 distintos |

Coste de la llamada vacía (200.000 llamadas): Rust con parámetros tipados 0,77 µs; Rust con `Variant` 0,40 µs; C++ 0,38 µs.

Notas: (1) la primera versión guardaba las claves en variables de hilo y daba un *panic* al cerrar Godot («engine not available»): en gdext los
valores de Godot no pueden vivir más que el motor; (2) para acercarse a C++ hay que desactivar las comprobaciones de seguridad de gdext en release,
que es justo lo que se buscaba ganar con Rust.

### Tiempo de compilación (limpia, 4 núcleos)
Rust: 55 s-2 min 40 s por plataforma para una función (casi todo es compilar gdext). C++: godot-cpp ya compilado, cada fuente nueva tarda segundos.

## Coste de mantener tres versiones
- Cada función: GDScript (gemela obligatoria: Android/Web y respaldo), C++ y Rust; tres pruebas de igualdad.
- Dos cadenas de compilación por plataforma (scons + cargo) en el CI: Linux, Windows, Android, Web (esta última con Rust *nightly*).
- `bin_nativo/` con el doble de binarios (~3 MB más por plataforma solo de base).
- Dos estilos de interoperabilidad que conocer (godot-cpp y gdext), con trampas distintas (claves `StringName` vs `String`, ciclo de vida de los valores).

## Código del prototipo (no está en el repo)
```rust
// Cargo.toml: godot = { version = "=0.5.5", features = ["api-4-7", "safeguards-release-disengaged"] }, crate-type = ["cdylib"]
use godot::prelude::*;

struct DinastiaRust;
#[gdextension]
unsafe impl ExtensionLibrary for DinastiaRust {}

#[derive(GodotClass)]
#[class(base = RefCounted)]
struct RustNativo {
    base: Base<RefCounted>,
    k_local: Variant, k_id: Variant, k_base: Variant, k_t: Variant, k_mapa: Variant,
    k_rl: StringName, k_rv: StringName,
}

#[godot_api]
impl IRefCounted for RustNativo {
    fn init(base: Base<RefCounted>) -> Self {
        Self { base,
            k_local: StringName::from("es_local").to_variant(), k_id: StringName::from("id").to_variant(),
            k_base: StringName::from("base_pos").to_variant(), k_t: "t".to_variant(), k_mapa: "mapa".to_variant(),
            k_rl: StringName::from("_roles_l"), k_rv: StringName::from("_roles_v") }
    }
}

#[godot_api]
impl RustNativo {
    #[func]
    fn roles_base(&self, m: Gd<Object>, p: VarDictionary, t: f64, jugadores: VarArray) -> Variant {
        let local: bool = p.at(&self.k_local).to();
        let clave = if local { &self.k_rl } else { &self.k_rv };
        if !m.has_meta(clave) { return Variant::nil(); }
        let e: AnyDictionary = m.get_meta(clave).to();
        let et: f64 = e.at(&self.k_t).to();
        if !(t >= et && t - et < 0.5) { return Variant::nil(); }
        let mapa: AnyDictionary = e.at(&self.k_mapa).to();
        let id = p.at(&self.k_id);
        let dueno = mapa.get(&id).unwrap_or_else(|| id.clone());
        if dueno == id { return p.at(&self.k_base); }
        for v in jugadores.iter_shared() {
            let q: AnyDictionary = v.to();
            if q.at(&self.k_id) == dueno { return q.at(&self.k_base); }
        }
        p.at(&self.k_base)
    }
}
```
