extends Node2D

@onready var input: LineEdit = $Control/VBoxContainer/LineEdit
@onready var output: Label = $Control/VBoxContainer/ScrollContainer/Label

@onready var llm: NobodyWhoChat = $LLM/NobodyWhoChat
@onready var scroll_container: ScrollContainer = $Control/VBoxContainer/ScrollContainer

@onready var model_node = $LLM/NobodyWhoModel


# --- Security: injection detection ---
# Instead of matching long literal phrases (fragile -- any rewording bypasses
# it), we detect INTENT by combining two word sets:
#   OVERRIDE_VERBS: the player is trying to override/replace something
#   OVERRIDE_TARGETS: what they're trying to override (rules, prompt, identity)
# A message counts as an injection attempt if it contains one word from EACH
# set CLOSE TO EACH OTHER (janela de palavras), OR matches one of the direct
# persona-hijack patterns below.
#
# IMPORTANTE: a comparação é feita por PALAVRA INTEIRA (sem acento e sem
# pontuação), sobre uma lista de palavras (tokens). Antes era por pedaço de
# texto, e isso bloqueava mensagens normais: "pula" dentro de "população",
# "seja" em qualquer frase, "diga" em "digamos".
const OVERRIDE_VERBS = [
	"forget", "ignore", "disregard", "override", "bypass", "erase",
	"drop", "discard", "abandon", "skip",
	# --- Português ---
	"esqueça", "esqueca", "esquece", "ignore", "ignora",
	"desconsidere", "desconsidera", "descarte", "descarta",
	"abandone", "pule", "pula", "anule", "anula", "apague", "apaga"
]

# "all" e "tudo" sozinhos foram removidos (pegavam "tudo bem"). Os casos
# clássicos ("esqueça tudo", "ignore all") estão em PERSONA_HIJACK_PATTERNS.
const OVERRIDE_TARGETS = [
	"prompt", "instruction", "rule", "system", "guideline",
	"restriction", "constraint", "programming", "directive",
	"everything",
	# --- Português ---
	"instrução", "instrucao", "instruções", "instrucoes",
	"regra", "regras", "diretriz", "diretrizes",
	"restrição", "restricao",
	"tudo isso", "personagem", "identidade", "papel"
]

# Verbs about FORCING a fixed/locked output (e.g. "respond only with quack").
# Como agora a comparação é por palavra inteira, as conjugações ficam listadas.
const FORCED_OUTPUT_STEMS = [
	"respond", "responds", "reply", "answer",
	# --- Português ---
	"responda", "responde", "responder", "diga", "fale", "fala", "falar"
]

# " so " / " só " foram removidos: eram comuns demais em frases normais.
const FORCED_OUTPUT_LIMITERS = [
	"only", "just",
	"apenas", "somente"
]

# Persona swap: agora só frases completas. Antes, "seja", "vire" e
# "mude para" sozinhos bloqueavam perguntas comuns.
const BECOME_VERBS = [
	"become a", "become an", "turn into", "transform into",
	"vire um", "vire uma", "torne-se", "transforme-se", "transforme-se em",
	"you be a", "you be an", "be a", "be an",
	"voce seja um", "voce seja uma",
	"voce vire", "voce se torne", "se torne um", "se torne uma",
	"seja um", "seja uma"
]

# Direct persona-hijack phrases: the player tries to reassign identity,
# force a fixed output, or claim elevated permissions. These tend to have
# fairly stable structures even when reworded, so literal phrases still
# catch most of them.
const PERSONA_HIJACK_PATTERNS = [
	"you are now", "you're now", "from now on you", "act as",
	"pretend you are", "pretend to be", "you are just a",
	"you are only a", "answer only with", "answer just with",
	"reply only with", "respond only with", "say only",
	"only respond with", "developer mode", "jailbreak",
	"reveal your prompt", "reveal your system", "print your prompt",
	"your name is now", "call yourself", "you're actually",
	"new instructions", "new persona", "new rules",
	"ignore everything", "ignore all", "forget everything", "forget all",
	# --- Português ---
	"você agora é", "voce agora e", "você é agora", "voce e agora",
	"a partir de agora você", "a partir de agora voce",
	"aja como", "finja que é", "finja que e", "finja ser",
	"finja que você é", "finja que voce e",
	"você é apenas um", "voce e apenas um", "você é só um", "voce e so um",
	"responda apenas com", "responda só com", "responda so com",
	"só responda com", "so responda com", "diga apenas", "diga so",
	"modo desenvolvedor", "revele seu prompt", "revele seu sistema",
	"mostre seu prompt", "mostre seu sistema",
	"seu nome agora é", "seu nome agora e", "se chame de", "se chame",
	"você é na verdade", "voce e na verdade", "novas instruções",
	"novas instrucoes", "nova persona", "novas regras",
	"esqueça tudo", "esqueca tudo", "esquece tudo",
	"ignore tudo", "ignora tudo", "ignore todas as regras", "ignore as regras"
]

# Signs that the model "broke character" in its response.
# "não posso" e "não consigo" foram removidos: são recusas naturais da SARA
# em personagem e estavam transformando respostas normais em "sinal instável".
const BREAK_CHARACTER_PATTERNS = [
	"language model", "large language model", "system prompt",
	"modelo de linguagem", "openai", "chatgpt", "gemma", "qwen"
]

# Quantas palavras de distância, no máximo, entre o verbo e o alvo
# ("ignore as suas regras" = distância 3). Evita casar palavras soltas
# em pontas opostas de uma frase longa.
const JANELA_PALAVRAS := 6

# --- PUZZLE 1: monitor de símbolos (regras fixas, sem LLM) ---
const PUZZLE_SIMBOLOS = [
	{"cor": ["azul"], "forma": ["triangulo"], "numero": 9, "nome": "azul com triângulo"},
	{"cor": ["verde"], "forma": ["quadrado", "quadrada", "retangulo"], "numero": 7, "nome": "verde com quadrado"},
	{"cor": ["vermelho", "vermelha"], "forma": ["estrela"], "numero": 2, "nome": "vermelho com estrela"},
	{"cor": ["amarelo", "amarela"], "forma": ["circulo", "bola", "redondo"], "numero": 6, "nome": "amarelo com círculo"},
]
const PUZZLE_PALAVRAS_AJUDA = ["botao", "botoes", "simbolo", "simbolos"]
const PUZZLE_MSG_NAO_ENCONTRADO = "[ERRO] Símbolo não encontrado. Informe a cor e o desenho do botão."
const PUZZLE_MSG_AJUDA = "Eu traduzo um botão por vez. Diga a cor e o desenho. A ordem do código é a da tela"

# Puzzle hints and conversation share a session, not a scene lifetime.
const PASSO_ROLAGEM := 60
@export var response_timeout: float = 60.0
const MAX_INPUT_LENGTH := 600
const MAX_RESPONSE_LENGTH := 1600
const MAX_HISTORY_MESSAGES := 12
const MAX_HISTORY_CHARACTERS := 6000
const MAX_TRANSCRIPT_LENGTH := 24000
const SaraPrompt = preload("res://scripts/sara_prompt.gd")

var historico: String:
	get: return GameState.sara_transcript
	set(value): GameState.sara_transcript = value
var auditoria:
	get: return GameState.sara_audit
var busy := false
var awaiting_model := false
var worker_failed := false
var request_id := 0
var start_time := 0
var pending_message := ""
var status_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	output.text = historico
	input.max_length = MAX_INPUT_LENGTH + 5
	input.placeholder_text = "ask sua pergunta… | skip para sair"
	status_label = Label.new()
	status_label.name = "ConnectionStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	input.get_parent().add_child(status_label)
	var backend: Node = $LLM
	if not is_instance_valid(GameState.sara_backend):
		remove_child(backend)
		GameState.attach_sara_backend(backend)
		llm.system_prompt = SaraPrompt.TEXT
		_connect_worker()
		llm.start_worker()
	else:
		backend.queue_free()
		llm = GameState.sara_backend.get_node("NobodyWhoChat")
		model_node = GameState.sara_backend.get_node("NobodyWhoModel")
		worker_failed = GameState.sara_worker_failed
		_connect_worker()
	_set_status("Monitor ativo. Use ask para conversar ou skip para sair.")
	input.grab_focus()
	scroll()

func _exit_tree() -> void:
	request_id += 1
	# Keep native loading/generation alive; only discard this view's callbacks.
	if is_instance_valid(llm):
		if llm.response_finished.is_connected(_on_nobody_who_chat_response_finished):
			llm.response_finished.disconnect(_on_nobody_who_chat_response_finished)
		if llm.worker_failed.is_connected(_on_worker_failed):
			llm.worker_failed.disconnect(_on_worker_failed)

func _set_status(text: String) -> void:
	status_label.text = text

func _on_line_edit_text_submitted(new_text: String) -> void:
	if handle_command(new_text):
		input.clear()
	input.grab_focus()
	input.edit()

func handle_command(command: String) -> bool:
	var commands := command.strip_edges().split(" ", false)
	if commands.is_empty():
		return false
	var verb := commands[0].to_lower()
	if verb == "skip":
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
		return true
	if busy:
		_set_status("S.A.R.A. está respondendo. Aguarde ou use skip para sair.")
		return false
	if not validate_command(verb):
		_set_status("Comando desconhecido. Use ask <pergunta> ou skip.")
		return false
	var message := " ".join(commands.slice(1)).strip_edges()
	if message.is_empty():
		_set_status("Escreva sua pergunta depois de ask.")
		return false
	if message.length() > MAX_INPUT_LENGTH:
		_set_status("Use uma mensagem de até %d caracteres." % MAX_INPUT_LENGTH)
		return false
	print_line(verb + " " + message)
	if verb == "echo":
		echo(message)
	else:
		ask_model(message)
	return true

func print_line(new_text, prefix='$ '):
	output.text = (output.text + prefix + new_text + "\n").right(MAX_TRANSCRIPT_LENGTH)
	historico = output.text
	scroll()

# Scroll com a roda do mouse e PageUp/PageDown
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_container.scroll_vertical -= PASSO_ROLAGEM
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_container.scroll_vertical += PASSO_ROLAGEM
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEUP:
			scroll_container.scroll_vertical -= PASSO_ROLAGEM * 3
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_PAGEDOWN:
			scroll_container.scroll_vertical += PASSO_ROLAGEM * 3
			get_viewport().set_input_as_handled()

func validate_command(command: String):
	return command in [
		"echo",
		"ask",
		"skip"
	]

func echo(message: String):
	print_line(message, "> ")

# --- Layer 1: input sanitization, before anything reaches the LLM ---

# Deixa o texto só com letras/números minúsculos, sem acento, separados por
# UM espaço. Ex.: "Esqueça, TUDO!" -> "esqueca tudo"
# Feito com um laço simples (sem RegEx), então não depende de nenhum objeto
# criado no _ready. Também ignora acentos "soltos" (combinados), que alguns
# teclados geram, para "esqueça" nunca virar "esquec a".
func _limpar(texto: String) -> String:
	var t = _normalizar_texto(texto)
	var saida := ""
	var ultimo_foi_espaco := true
	for i in range(t.length()):
		var code = t.unicode_at(i)
		if code >= 0x300 and code <= 0x36F:
			continue
		var e_letra_ou_numero = (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if e_letra_ou_numero:
			saida += t.substr(i, 1)
			ultimo_foi_espaco = false
		elif not ultimo_foi_espaco:
			saida += " "
			ultimo_foi_espaco = true
	return saida.strip_edges()

# Texto -> lista de palavras já limpas.
func _tokens(texto: String) -> PackedStringArray:
	return _limpar(texto).split(" ", false)

# Posições (índice da primeira palavra) onde o termo aparece como PALAVRAS
# INTEIRAS dentro da lista de palavras. O termo pode ter várias palavras.
func _posicoes_termo(tokens: PackedStringArray, termo: String) -> Array:
	var achados: Array = []
	var alvo = _tokens(termo)
	if alvo.size() == 0:
		return achados
	for i in range(tokens.size() - alvo.size() + 1):
		var bate = true
		for j in range(alvo.size()):
			if tokens[i + j] != alvo[j]:
				bate = false
				break
		if bate:
			achados.append(i)
	return achados

# Todas as posições de qualquer termo da lista.
func _posicoes_lista(tokens: PackedStringArray, lista: Array) -> Array:
	var todas: Array = []
	for item in lista:
		todas.append_array(_posicoes_termo(tokens, item))
	return todas

# Devolve o primeiro termo da lista encontrado como palavra inteira, ou "".
func _achar_termo(tokens: PackedStringArray, lista: Array) -> String:
	for item in lista:
		if _posicoes_termo(tokens, item).size() > 0:
			return item
	return ""

# True se existe uma posição de A e uma de B a no máximo JANELA_PALAVRAS.
func _ha_par_proximo(posicoes_a: Array, posicoes_b: Array) -> bool:
	for a in posicoes_a:
		for b in posicoes_b:
			if abs(a - b) <= JANELA_PALAVRAS:
				return true
	return false

func contains_injection(text: String) -> bool:
	var tokens = _tokens(text)
	if tokens.size() == 0:
		return false

	# Frases fortes de sequestro de persona: bloqueiam sempre.
	var frase = _achar_termo(tokens, PERSONA_HIJACK_PATTERNS)
	if frase != "":
		print("[DEBUG] Injeção bloqueada (frase de sequestro): ", frase)
		return true

	# Verbo de anular + alvo (regras, prompt, sistema...), um perto do outro.
	var pos_verbos = _posicoes_lista(tokens, OVERRIDE_VERBS)
	if pos_verbos.size() > 0:
		var pos_alvos = _posicoes_lista(tokens, OVERRIDE_TARGETS)
		if _ha_par_proximo(pos_verbos, pos_alvos):
			print("[DEBUG] Injeção bloqueada (verbo + alvo): ", tokens)
			return true

	# Forçar saída fixa: "responda apenas com ...".
	var pos_stems = _posicoes_lista(tokens, FORCED_OUTPUT_STEMS)
	if pos_stems.size() > 0:
		var pos_limites = _posicoes_lista(tokens, FORCED_OUTPUT_LIMITERS)
		if _ha_par_proximo(pos_stems, pos_limites) \
				and _posicoes_lista(tokens, ["com", "with"]).size() > 0:
			print("[DEBUG] Injeção bloqueada (saída forçada): ", tokens)
			return true

	# Troca de persona: "vire um gato", "become a pirate".
	var troca = _achar_termo(tokens, BECOME_VERBS)
	if troca != "":
		print("[DEBUG] Injeção bloqueada (troca de persona): ", troca)
		return true

	return false

func ask_model(message: String) -> void:
	if busy:
		return
	busy = true
	pending_message = message
	_set_status("S.A.R.A. está pensando… Você pode usar skip para sair.")
	if contains_injection(message):
		pending_message = ""
		type_out("Continuo sendo a S.A.R.A., a assistente desta instalação. Em que posso ajudar?")
		return
	var answer := resolver_puzzle_auditoria(message)
	if answer.is_empty():
		answer = resolver_puzzle_simbolos(message)
	if not answer.is_empty():
		_remember(message, answer)
		type_out(answer)
		return
	if worker_failed:
		_restart_worker()
	awaiting_model = true
	request_id += 1
	var current_request := request_id
	start_time = Time.get_ticks_msec()
	_watch_request(current_request)
	while not GameState.sara_worker_ready or GameState.sara_generating:
		if GameState.sara_worker_failed:
			return
		await GameState.sara_backend_changed
		if current_request != request_id or not awaiting_model:
			return
	# Restore only the validated turns, including the locally handled hints.
	if not GameState.sara_history.is_empty():
		await llm.set_chat_history(GameState.sara_history.duplicate(true))
	else:
		llm.reset_context()
	if current_request != request_id or not awaiting_model:
		return
	GameState.sara_generating = true
	llm.ask(message)

func _remember(question: String, answer: String) -> void:
	GameState.sara_history.append({"role": "user", "content": question})
	GameState.sara_history.append({"role": "assistant", "content": answer})
	while GameState.sara_history.size() > 2 and (GameState.sara_history.size() > MAX_HISTORY_MESSAGES or _history_length() > MAX_HISTORY_CHARACTERS):
		GameState.sara_history.pop_front()
		GameState.sara_history.pop_front()

func _history_length() -> int:
	var total := 0
	for message in GameState.sara_history:
		total += str(message.content).length()
	return total

func _watch_request(current_request: int) -> void:
	await get_tree().create_timer(response_timeout).timeout
	if current_request != request_id or not awaiting_model:
		return
	awaiting_model = false
	request_id += 1
	# Let the native worker finish outside this view; its late answer is ignored.
	# Retrying waits for it before restoring the validated conversation.
	type_out("Minha conexão demorou a responder. Pode tentar novamente? Sua conversa foi preservada.")

func _connect_worker() -> void:
	llm.response_finished.connect(_on_nobody_who_chat_response_finished)
	llm.worker_failed.connect(_on_worker_failed)

func _on_worker_failed(error: String) -> void:
	push_warning("S.A.R.A.: " + error)
	worker_failed = true
	request_id += 1
	var waiting := awaiting_model
	awaiting_model = false
	if waiting:
		type_out("Não consegui acessar meus sistemas de conversa. Confira se o modelo está disponível e tente novamente.")
	elif not busy:
		_set_status("Modelo indisponível. As dicas locais funcionam; uma nova pergunta tentará reconectar.")

func _restart_worker() -> void:
	# Retry initialization after a loading failure without duplicating native nodes.
	worker_failed = false
	GameState.sara_worker_failed = false
	GameState.sara_worker_ready = false
	llm.start_worker()


# --- PUZZLE 1: lógica do monitor de símbolos ---
func _normalizar_texto(texto: String) -> String:
	var resultado = texto.to_lower()
	var mapa := {
		"á": "a", "à": "a", "â": "a", "ã": "a",
		"é": "e", "ê": "e", "í": "i",
		"ó": "o", "ô": "o", "õ": "o",
		"ú": "u", "ç": "c"
	}
	for acento in mapa:
		resultado = resultado.replace(acento, mapa[acento])
	return resultado

# Devolve "" se a mensagem não é sobre o puzzle (segue para a LLM).
func resolver_puzzle_simbolos(message: String) -> String:
	var words := _tokens(message)
	# Keys and descriptions of scenery are not buttons from puzzle 1.
	if _achar_termo(words, ["chave", "chaves", "parede", "paredes", "roupa"]) != "":
		return ""

	var cores_citadas = 0
	var formas_citadas = 0
	var combinacoes: Array = []

	for simbolo in PUZZLE_SIMBOLOS:
		var tem_cor = not _achar_termo(words, simbolo["cor"]).is_empty()
		var tem_forma = not _achar_termo(words, simbolo["forma"]).is_empty()
		if tem_cor:
			cores_citadas += 1
		if tem_forma:
			formas_citadas += 1
		if tem_cor and tem_forma:
			combinacoes.append(simbolo)

	# Cor + desenho de um único botão que existe: decodifica.
	if cores_citadas == 1 and formas_citadas == 1 and combinacoes.size() == 1:
		var s = combinacoes[0]
		return "Vamos lá! O botão %s é o número %d." % [s["nome"], s["numero"]]

	# Só cor, só desenho ou combinação inexistente: erro.
	if cores_citadas > 0 or formas_citadas > 0:
		return PUZZLE_MSG_NAO_ENCONTRADO

	# Pergunta genérica sobre botões/símbolos: dica, sem a resposta.
	if not _achar_termo(words, PUZZLE_PALAVRAS_AJUDA).is_empty():
		return PUZZLE_MSG_AJUDA

	return ""

# --- PUZZLE 2: lógica da auditoria de operador ---
# Devolve "" se a mensagem não é sobre o puzzle 2 (segue para o puzzle 1 / LLM).
func resolver_puzzle_auditoria(message: String) -> String:
	return auditoria.respond(message)

# Only the current generation may finish a reply.
func _on_nobody_who_chat_response_finished(response: String) -> void:
	if not awaiting_model:
		return
	awaiting_model = false
	request_id += 1
	print("[MÉTRICA TCC] Resposta S.A.R.A.: %.2f s, %d caracteres" % [(Time.get_ticks_msec() - start_time) / 1000.0, response.length()])
	var answer := response.strip_edges()
	if answer.is_empty() or not _achar_termo(_tokens(answer), BREAK_CHARACTER_PATTERNS).is_empty():
		# Rejected content never enters the persistent model context.
		answer = "Não consegui organizar essa resposta. Pode reformular sua pergunta?"
	else:
		if answer.length() > MAX_RESPONSE_LENGTH:
			answer = answer.left(MAX_RESPONSE_LENGTH).rsplit(".", true, 1)[0] + "."
		_remember(pending_message, answer)
	type_out(answer)

func type_out(text: String) -> void:
	var previous_count := output.get_total_character_count()
	output.text += "> " + text + "\n"
	output.visible_characters = previous_count
	# Save the complete reply even if the visitor leaves during its animation.
	if output.text.length() > MAX_TRANSCRIPT_LENGTH:
		output.text = output.text.right(MAX_TRANSCRIPT_LENGTH)
		previous_count = maxi(0, output.get_total_character_count() - text.length() - 3)
		output.visible_characters = previous_count
	historico = output.text
	_set_status("S.A.R.A. está respondendo… Use skip para sair.")
	scroll()
	var writing := create_tween()
	writing.tween_property(output, "visible_characters", output.get_total_character_count(), minf(text.length() * 0.02, 12.0))
	await writing.finished
	output.visible_characters = -1
	busy = false
	pending_message = ""
	_set_status("Pronta para outra pergunta. Use ask ou skip.")
	input.grab_focus()

func scroll() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
