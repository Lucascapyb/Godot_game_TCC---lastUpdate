extends Node2D

@onready var input: LineEdit = $Control/VBoxContainer/LineEdit
@onready var output: Label = $Control/VBoxContainer/ScrollContainer/Label

@onready var llm: NobodyWhoChat = $LLM/NobodyWhoChat
@onready var scroll_container: ScrollContainer = $Control/VBoxContainer/ScrollContainer

@onready var chat_node = $LLM/NobodyWhoChat
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
	"regra", "regras", "sistema", "diretriz", "diretrizes",
	"restrição", "restricao", "programação", "programacao",
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
	"voce seja um", "voce seja uma", "voce fosse um", "voce fosse uma",
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
	"as an ai", "language model", "i cannot", "i'm just an ai",
	"i don't have feelings", "gemma", "qwen", "google", "alibaba",
	"large language model", "system prompt", "as a language model",
	"i'm not able to", "i am an ai", "i am a language model",
	# --- Português ---
	"como uma ia", "como um modelo de linguagem", "modelo de linguagem",
	"não tenho sentimentos", "nao tenho sentimentos",
	"sou uma ia", "sou um modelo de linguagem", "sou uma inteligência artificial",
	"sou uma inteligencia artificial"
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

# --- PUZZLE 2: auditoria de operador (respostas fixas com escada de dicas) ---
# Palavras que indicam que a mensagem é sobre o puzzle 2 (texto já sem acento).
# O " dia " é checado à parte, com espaços, para não pegar "diga", "media" etc.
const PUZZLE2_PALAVRAS = [
	"auditoria", "bloco", "sequencia", "operadora", "diana",
	"cracha", "panfleto", "folha", "setor", "anomalia",
	"lotacao", "nascimento", "documento", "turno", "borcelle",
	"folga", "assinatura", "4471"
]

# Escada de dicas. Cada pergunta sobre o puzzle sobe um nível (máx. 3).
# Nenhuma resposta contém os dígitos.
const PUZZLE2_DICAS = [
	# Nível 0
	"O terminal pede uma sequência de auditoria com três fatos sobre a operadora Diana. Cada fato vem de um documento diferente. Diga o que você encontrou.",
	# Nível 1
	"São três blocos: o setor onde ela atua, a ocorrência fora do padrão e o final da identificação dela. Cada bloco vira um número de dois dígitos.",
	# Nível 2
	"O local de atuação está no material de divulgação. A ocorrência está no registro de presença. A identificação está no documento de identificação da operadora.",
	# Nível 3
	"Cuidado com dados parecidos. Lotação de nascimento não é local de atuação. O horário do local não é o turno dela. Procure o primeiro dia em que a presença foge do padrão do turno."
]

# Respostas específicas para as armadilhas (só no nível 3).
const PUZZLE2_ARMADILHAS = [
	{
		"palavras": ["lotacao", "nascimento", " vii"],
		"resposta": "Lotação de nascimento diz de onde a operadora veio, não onde ela trabalha. Não serve para o bloco de local de atuação."
	},
	{
		"palavras": ["borcelle", "08:00", "18:00", "funcionamento"],
		"resposta": "Esse horário é do local, aberto ao público. O turno da operadora é o que consta no registro de presença."
	},
	{
		"palavras": ["folga", "sem registro", "registro"],
		"resposta": "Folga é esperada, e dias sem registro vêm depois do problema. Procure o primeiro dia em que a presença foge do padrão do turno."
	}
]

var response_buffer: String = ""
var start_time: float = 0.0
const PASSO_ROLAGEM := 60

# "static" guarda o valor mesmo se a cena for destruída e criada de novo
# (ao sair e voltar ao monitor), durante toda a execução do jogo.
static var historico: String = ""
static var perguntas_puzzle2: int = 0

func _ready():
	# Mantém a ação do scroll funcionando mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Restaura as mensagens antigas ao reabrir o monitor
	output.text = historico
	scroll()

	llm.start_worker()
	llm.response_finished.connect(_on_nobody_who_chat_response_finished)
	input.grab_focus()
	
	imprimir_metricas_llm()
	descobrir_propriedades_llm()


func _on_line_edit_text_submitted(new_text):
	input.unedit()
	handle_command(new_text)
	input.clear()
	input.grab_focus()
	input.edit()

func handle_command(command: String):
	print_line(command)
	var commands = command.split(" ")
	if len(commands) == 0:
		return
	if not validate_command(commands[0]):
		print_line("Command '%s' not found." % commands[0], "> ")
		return

	if commands[0] == "skip":
		get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
		return

	if len(commands) == 1:
		print_line("Command '%s' requires more than 1 argument." % commands[0], "> ")
		return

	var message = " ".join(commands.slice(1))

	match commands[0]:
		"echo":
			echo(message)
		"ask":
			ask_model(message)

func print_line(new_text, prefix='$ '):
	output.text += prefix + new_text + "\n"
	historico = output.text
	scroll()

func print_word(word: String):
	output.text += word
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

func ask_model(message: String):
	if contains_injection(message):
		# A mensagem bloqueada nunca chega na LLM, então o contexto não é
		# contaminado. Por isso o llm.reset_context() foi removido: ele apagava
		# a conversa inteira a cada falso positivo.
		print_word("> ")
		play_static_response()
		return

	# --- PUZZLE 2: auditoria, resposta fixa com escada de dicas ---
	# Vem antes do puzzle 1 para que mensagens como "o crachá tem fundo azul"
	# não caiam no erro de símbolo do puzzle 1.
	var resposta_puzzle2 = resolver_puzzle_auditoria(message)
	if resposta_puzzle2 != "":
		print_word("> ")
		type_out(resposta_puzzle2)
		return

	# --- PUZZLE 1: resposta fixa, sem passar pela LLM ---
	var resposta_puzzle = resolver_puzzle_simbolos(message)
	if resposta_puzzle != "":
		print_word("> ")
		type_out(resposta_puzzle)
		return

	response_buffer = ""
	start_time = Time.get_ticks_msec()
	llm.say(message)
	print_word("> ")

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

func _contem_algum(texto: String, palavras: Array) -> bool:
	for palavra in palavras:
		if texto.find(palavra) != -1:
			return true
	return false

# Devolve "" se a mensagem não é sobre o puzzle (segue para a LLM).
func resolver_puzzle_simbolos(message: String) -> String:
	var texto = _normalizar_texto(message)

	var cores_citadas = 0
	var formas_citadas = 0
	var combinacoes: Array = []

	for simbolo in PUZZLE_SIMBOLOS:
		var tem_cor = _contem_algum(texto, simbolo["cor"])
		var tem_forma = _contem_algum(texto, simbolo["forma"])
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
	if _contem_algum(texto, PUZZLE_PALAVRAS_AJUDA):
		return PUZZLE_MSG_AJUDA

	return ""

# --- PUZZLE 2: lógica da auditoria de operador ---
# Devolve "" se a mensagem não é sobre o puzzle 2 (segue para o puzzle 1 / LLM).
func resolver_puzzle_auditoria(message: String) -> String:
	var texto = " " + _normalizar_texto(message) + " "

	var relacionada = _contem_algum(texto, PUZZLE2_PALAVRAS) or texto.find(" dia ") != -1
	if not relacionada:
		return ""

	var nivel = mini(perguntas_puzzle2, PUZZLE2_DICAS.size() - 1)
	perguntas_puzzle2 += 1

	# No nível máximo, tenta esclarecer a armadilha que o jogador citou.
	if nivel == PUZZLE2_DICAS.size() - 1:
		for armadilha in PUZZLE2_ARMADILHAS:
			if _contem_algum(texto, armadilha["palavras"]):
				return armadilha["resposta"]

	return PUZZLE2_DICAS[nivel]

# --- Layer 2: buffer the streamed response ---
func _on_nobody_who_chat_response_updated(new_token: String):
	response_buffer += new_token

# --- Layer 3: validate full response & log timing metrics ---
func _on_nobody_who_chat_response_finished(response: String):
	var total_time_sec = (Time.get_ticks_msec() - start_time) / 1000.0
	print("----------------------------------------")
	print("[MÉTRICA TCC] Tempo de resposta: ", total_time_sec, " segundos")
	print("[MÉTRICA TCC] Caracteres gerados: ", response.length())
	print("----------------------------------------")

	# Comparação por PALAVRA INTEIRA, como na entrada. Antes era por pedaço de
	# texto ("como uma ia" casava dentro de outras palavras, por exemplo).
	var tokens_resposta = _tokens(response)
	var padrao_quebrado = _achar_termo(tokens_resposta, BREAK_CHARACTER_PATTERNS)
	var broke_character = padrao_quebrado != ""
	if broke_character:
		print("[DEBUG] Quebra de personagem detectada por: ", padrao_quebrado)

	if broke_character:
		play_static_response()
	else:
		type_out(response)

func play_static_response():
	var glitch_lines = [
		"...signal unstable... repeat the query, operator.",
		"...interference detected... rephrase the command.",
		"[TRANSMISSION ERROR] try again."
	]
	type_out(glitch_lines[randi() % glitch_lines.size()])

func type_out(text: String):
	for c in text:
		print_word(c)
		await get_tree().create_timer(0.02).timeout
	print_word("\n")

func scroll():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func imprimir_metricas_llm():
	print("========================================")
	print("    PARÂMETROS DA LLM (TCC LOG)         ")
	print("========================================")
	print("Modelo Carregado: ", model_node.model_path)
	print("Aceleração por GPU Ativa: ", model_node.use_gpu_if_available)
	print("Tamanho do Contexto (Tokens): ", llm.context_length)
	
	if "temperature" in llm:
		print("Temperatura Atual: ", llm.get("temperature"))
	if "top_p" in llm:
		print("Top-P Atual: ", llm.get("top_p"))
	print("========================================")

func descobrir_propriedades_llm():
	print("=== PROPRIEDADES DISPONÍVEIS NO NOBODYWHO ===")
	for prop in llm.get_property_list():
		if "temp" in prop.name.to_lower() or "top" in prop.name.to_lower() or "param" in prop.name.to_lower():
			print("Encontrado: ", prop.name, " = ", llm.get(prop.name))
