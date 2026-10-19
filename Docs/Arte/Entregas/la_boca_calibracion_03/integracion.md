# Integración de la calibración 03

La textura `Assets/Overworld/LaBoca/conventillo_amarillo.png` se actualizó en la ruta que ya usa `ConventilloAmarilloExterior.tscn`. Se conservaron el lienzo 80×64, `Fachada.position=(0,-24)`, el origen centrado, el ancla `(40,56)` y la colisión 80×48 centrada en `(0,-16)`.

La textura `Assets/Personajes/npc/LaBoca/pintora.png` se actualizó en la ruta que ya usa `Recursos/Personajes/boca_pintora.tres`. `Escenas/Mapa.tscn` ahora instancia ese recurso como un NPC interactivo en `(184,168)` con el cuerpo, la colisión y el sistema de diálogo existentes.

La textura y el recurso están conectados en las escenas. Al abrir el proyecto, Godot debe reimportar ambos PNG. Comprobar visualmente la cumbrera en las cuatro esquinas, recorrer el paso junto a la escalera e interactuar con la pintora desde las cuatro direcciones. No pude ejecutar esa comprobación en el motor porque el ejecutable Godot no está disponible en esta sesión.
