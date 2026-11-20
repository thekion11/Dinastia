# Cómo conseguir el token de Mixamo (para `herramientas/mixamo_descargar.py`)

Mixamo no tiene descarga directa: pide cuenta de Adobe. La API no oficial acepta el **token de acceso** de tu sesión. Úsalo solo con tu cuenta y para clips que vayas a usar en el juego (los términos de Mixamo permiten el uso en juegos, no redistribuir los archivos).

1. Entra en https://www.mixamo.com con tu cuenta de Adobe.
2. Abre la consola del navegador: `Ctrl+Shift+I` (Mac: `Cmd+Opción+I`), o clic derecho → Inspeccionar, pestaña **Consola**. (F12 en muchos laptops pide `Fn`.)
3. Escribe `localStorage.access_token` y pulsa Enter. Si Chrome muestra el aviso de «allow pasting», no pasa nada: solo lee un valor y estás escribiendo tú.
4. Sale un texto largo entre comillas que empieza por `eyJ…`. Clic derecho → **Copy string contents** (sin comillas). Ver `mixamo_token_consola.jpg` (el token está tapado a propósito).
5. Guárdalo SOLO donde no se publique: el formulario seguro de la sesión de la nube (`request_credential`, el proxy lo inyecta) o `export MIXAMO_TOKEN=…` en tu terminal.

**Nunca** pegues el token en el chat, en una captura, en un commit ni en este repositorio (es público y el historial de git no se borra). Si se filtra: cierra sesión en adobe.com. Caduca solo en ~24 horas.

Uso: `python3 herramientas/mixamo_descargar.py buscar "soccer header"` y luego `bajar ID mx_cabezazo.fbx`. Los FBX se bajan fuera del repo y se convierten con `dinastia-godot/herramientas/mixamo_a_res.gd`.
Estado (18-11): la búsqueda funciona sin token; con el token del dueño la API dio `401013 Oauth token is not valid` (ver más abajo), así que exportar y bajar no están probados.

## Si da 401013
Comprueba que copiaste `access_token` (no `refresh_token` ni otra clave), sin comillas ni espacios, y que la sesión no se haya cerrado. Prueba a recargar mixamo.com, volver a copiar y reemplazar el secreto.
