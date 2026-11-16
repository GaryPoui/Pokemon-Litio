extends Node2D

@export var objeto_requerido: String= "boleto_primera"
@export var premio :String= "tm30"
@export var cantidad:= 1
@export var clave: String= "r9_coche"
@export_multiline var texto_cerrado :String= "El coche de 1.ª clase está cerrado. En la puerta dice: «Solo pasajeros con boleto de primera»."
@export_multiline var texto_abre: String= "Mostraste el boleto de 1.ª clase en la ventanilla… ¡clac! La puerta del coche se abrió. Sobre un asiento de cuero había algo."
@export_multiline var texto_vacio :String= "El coche de 1.ª clase está vacío. Solo quedan los asientos de cuero y el olor a madera vieja."

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(_jugador: Node) -> void:
	if clave!= "" and Estado.tiene(clave):
		await Dialogo.mostrar(texto_vacio)
		return
	if Inventario.cantidad_de(objeto_requerido)<= 0:
		await Dialogo.mostrar(texto_cerrado)
		return
	await Dialogo.mostrar(texto_abre)
	Estado.marcar(clave)
	Inventario.add_item(premio, cantidad)
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Recibiste %s!" % Inventario.get_item_name(premio))
	Sonido.cortar_jingle()
