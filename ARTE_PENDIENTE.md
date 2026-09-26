# Arte pendiente

Estos archivos son marcadores provisorios. Reemplazá cada PNG por tu versión con **el mismo nombre y ruta**: el juego los toma automáticamente, sin tocar código.
La pantalla base es de 256×192 px; medidas en píxeles del juego.

## Combate (`Assets/Batalla/ui_nueva/`)

| Archivo | Tamaño | Uso | Notas |
|---|---|---|---|
| `panel.png` | libre (hoy 24×24) | Paneles de nombre/PS propio y rival | Se estira como 9-slice con márgenes de 5 px: las esquinas (5×5) no se deforman. |
| `boton.png` | libre (hoy 24×18) | Botones Luchar / Mochila / Pokémon / Huir | 9-slice, márgenes de 5 px. Se muestran de 62×17. |
| `boton_sel.png` | igual que `boton.png` | Botón seleccionado | Mismo tamaño y márgenes que `boton.png`. |
| `boton_movimiento.png` | libre (hoy 24×18) | Botones de los 4 movimientos | Dibujalo en **grises/blanco**: el juego lo tiñe con el color del tipo del movimiento. 9-slice, márgenes de 5 px; se muestran de 92×17. |
| `cursor_mano.png` | 8×10 | Mano que señala el comando elegido | Apuntando a la derecha. |
| `tipos/<tipo>.png` | 12×12 | Íconos de tipo en paneles y botones | Uno por tipo: `normal, fuego, agua, planta, electrico, hielo, lucha, veneno, tierra, volador, psiquico, bicho, roca, fantasma, dragon, siniestro, acero`. |
| `categoria_fisico.png`, `categoria_especial.png`, `categoria_estado.png` | 32×14 | Categoría del movimiento seleccionado | Hoy son los íconos originales de Gen 4/5 (vía Pokémon Showdown). Opcional reemplazarlos. |

## Fondos de combate por zona

| Dónde | Tamaño | Notas |
|---|---|---|
| Propiedad `fondo_batalla` de cada mapa (nodo raíz del mapa, inspector) | 256×192 | Si un mapa no tiene fondo asignado, se usa el fondo liso actual. Las bases de combate se dibujan encima. |
