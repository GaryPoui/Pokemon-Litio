# Jugar en itch.io desde el navegador

Se utiliza Godot 4.7 (la versión del proyecto), sus plantillas de exportación de la misma versión y el compresor ZIP de Windows. No hace falta instalar servidores, plugins ni herramientas de publicación.

## Configuración incluida

- El preset **Web - itch.io** exporta a `build/web/index.html`.
- Web utiliza **Compatibility** (`gl_compatibility`); la versión de escritorio conserva su renderizador.
- **Thread Support** y **Extensions Support** están desactivados. No se necesitan cabeceras de aislamiento ni SharedArrayBuffer.
- PWA está desactivado para evitar el caché del service worker entre versiones.
- Se exportan todos los recursos del juego, incluidos los que se cargan por nombre durante la partida. También se incluyen los JSON de pesos, máquinas, naturalezas y tipos, que se leen con FileAccess.
- El material de arte fuente, la documentación y las exportaciones anteriores se excluyen del paquete.
- Web empieza dentro del marco de itch.io. La pantalla completa se solicita con una acción del jugador, sin restaurarla automáticamente al iniciar.

## Exportar y preparar el ZIP

1. Abrir `project.godot` en Godot y dejar que termine la importación inicial.
2. En **Editor > Administrar plantillas de exportación**, comprobar que están instaladas las plantillas correspondientes exactamente a la versión del editor. Si faltan, descargarlas desde ese mismo administrador.
3. Ir a **Proyecto > Exportar** y seleccionar **Web - itch.io**.
4. Pulsar **Exportar proyecto**, desactivar **Exportar con depuración** y guardar como `build/web/index.html`. Si la carpeta no existe, crearla desde el selector de archivos.
5. Abrir `build/web` en el Explorador de Windows. Seleccionar **todos los archivos generados** y usar **Comprimir en > Archivo ZIP** (o **Enviar a > Carpeta comprimida**).
6. Guardar el ZIP fuera de `web`, por ejemplo `build/Pokemon-Litio-web.zip`. Al abrirlo, `index.html` debe aparecer directamente, junto con `index.js`, `index.wasm`, `index.pck` y los demás archivos generados. No renombrarlos ni omitirlos.

**No usar «Exportar PCK/ZIP» para este paso.** Ese botón genera un paquete de recursos, no el juego web completo. Un ZIP que solo contiene recursos no puede iniciar Godot en el navegador.

Para reemplazar una exportación, usar una carpeta vacía y comprimir únicamente los archivos de esa exportación; no mezclar versiones anteriores.

## Subir a itch.io

1. Editar la página del juego y elegir **Kind of project: HTML** (juego ejecutable en navegador).
2. Subir el ZIP y marcar **This file will be played in the browser**.
3. Usar **Embed in page**, con un tamaño inicial de **1024 × 768** (también puede usarse 768 × 576). El juego mantiene su proporción 4:3.
4. Activar **Click to play** y el botón de pantalla completa. Con este preset, no hace falta habilitar **SharedArrayBuffer**.
5. Guardar la página, abrir la vista previa y esperar a que itch.io procese el ZIP. Hacer clic dentro del juego para que reciba el teclado y el navegador permita el audio.

Controles: flechas o WASD para moverse; Enter/Z para aceptar; X/Retroceso para volver; Escape para el menú; Shift para correr. La publicación está pensada para teclado: no marcar Mobile friendly sin probar controles táctiles.

## Si algo falla

| Síntoma | Solución dentro de Godot, Windows o itch.io |
| --- | --- |
| Falta `index.html` o itch.io no encuentra el juego | Usar Exportar proyecto, guardar como index.html y comprimir el contenido de la carpeta de salida. |
| Mensaje sobre SharedArrayBuffer | Verificar que Thread Support esté desactivado y subir una nueva exportación completa. |
| Error de renderizador o pantalla negra | Verificar `rendering > renderer > rendering_method.web = gl_compatibility` y usar un navegador con WebGL 2 habilitado. |
| Datos de tipos, naturalezas o máquinas faltantes | Mantener los cuatro JSON del filtro de inclusión del preset. |
| Al abrir el HTML con doble clic no carga | No probar mediante `file://`. Usar Ejecutar en navegador desde Godot (el botón aparece con el preset Web configurado) o la vista previa de itch.io. |
| No responde el teclado o no hay audio | Hacer clic dentro del juego; mantener Click to play habilitado en itch.io. |
| Aparece una versión anterior | Reemplazar el ZIP y recargar la página. Si una exportación anterior usaba PWA, borrar su service worker/caché desde las herramientas del navegador. Esto puede borrar partidas locales. |

Las partidas se guardan en `user://`, que en web depende del almacenamiento del navegador. Probar guardar, recargar y continuar desde itch.io; el modo privado o el bloqueo de almacenamiento del iframe pueden impedir la persistencia.

Los límites por defecto de itch.io son 1000 archivos, 500 MB descomprimidos y 200 MB por archivo. Revisar especialmente el tamaño de `index.pck`; comprimirlo en ZIP no reduce su tamaño una vez extraído.

## Referencias

- [Exportación web de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Publicar juegos HTML5 en itch.io](https://itch.io/docs/creators/html5)
