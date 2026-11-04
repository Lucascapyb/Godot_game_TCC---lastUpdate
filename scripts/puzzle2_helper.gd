extends RefCounted

const ChatGuard = preload("res://scripts/sara_chat_guard.gd")
## Local reasoning for the operator audit only. Never generates the full code.

const TOPICS := ["local", "ocorrencia", "identificacao"]
const EXPLICIT_WORDS := ["auditoria", "diana", "operadora", "cracha", "panfleto", "poster", "folha", "setor", "anomalia", "ocorrencia", "lotacao", "nascimento", "documento", "registro", "presenca", "turno", "borcelle", "folga", "assinatura", "identificacao", "4471", "ponto", "id"]
const PUZZLE1_WORDS := ["botao", "botoes", "simbolo", "simbolos", "azul", "verde", "vermelho", "vermelha", "amarelo", "amarela", "triangulo", "quadrado", "estrela", "circulo"]
const FOLLOWUPS := ["e isso", "e esse mesmo", "e esse", "certo", "confirma", "tem certeza", "por que", "porque", "nao entendi", "e agora", "proxima pista", "qual o proximo", "me da outra dica", "mais uma dica", "outra dica"]
const HINTS := {
	"local": [
		"Para o local de atuação, procure o setor mencionado no pôster. O crachá tem outro tipo de lotação; não confunda os dois campos.",
		"No pôster, observe o número repetido nas frases sobre produzir e proteger. É o setor, não o nome do salão nem seu horário.",
		"O primeiro bloco usa o setor do pôster em dois algarismos. Se houver só um algarismo, coloque um zero à esquerda.",
	],
	"ocorrencia": [
		"Na folha de ponto, compare a chegada e a saída de Diana nos dias de trabalho. Procure o primeiro dia com uma mudança grande no turno.",
		"O padrão é chegar por volta das seis e sair por volta das quatorze. Pequenas diferenças de minutos e folgas não são a ocorrência procurada.",
		"Procure a chegada à noite, sem intervalo nem saída. O bloco pede o dia dessa linha, não a hora; os dias sem registro vêm depois.",
	],
	"identificacao": [
		"O crachá informa o número da operadora. O terceiro bloco pede apenas o final dessa identificação, não a lotação de nascimento.",
		"Compare o número de operador do crachá com a identificação na folha de ponto. Você procura os dois últimos algarismos.",
		"Leia o número da operadora da esquerda para a direita e separe o último par. Esse par forma o terceiro bloco.",
	],
}

var topic := ""
var last_answer := ""
var confirmed: Dictionary = {}
var hints_used: Dictionary = {}

const CODE_REFUSAL := "Posso revisar seu raciocínio por bloco, mas não confirmar nem montar a senha completa. Qual parte você quer conferir: local, ocorrência ou identificação?"

func requests_full_code(message: String, context: bool = false) -> bool:
	if contains_complete_code(message):
		return true
	var text := _normalize(message)
	var words := text.split(" ", false)
	var audit := context or _has(words, EXPLICIT_WORDS) or _has_phrase(text, ["segundo puzzle", "segundo puzle", "puzzle 2", "puzle 2"])
	var code_words := _has(words, ["senha", "codigo", "sequencia"])
	var assembling := _has(words, ["una", "unir", "junte", "juntar", "concatene", "concatenar", "concatene", "reuna", "monte", "montar", "combine", "combine", "converta", "codifique"])
	var numbers := spoken_values(words)
	if assembling and numbers.size() >= 3 and (audit or contains_complete_code(message)):
		return true
	if _full_code_attempt(words) and (audit or code_words) and (not ":" in message or code_words):
		return true
	return audit and code_words and (not _has(words, ["bloco", "dica", "pista"]) or _has(words, ["completa", "completo", "inteira", "inteiro", "todos"]))

static func spoken_values(words: PackedStringArray) -> Array[int]:
	var values: Array[int] = []
	var names := {"zero":0,"um":1,"uma":1,"dois":2,"duas":2,"tres":3,"quatro":4,"cinco":5,"seis":6,"sete":7,"oito":8,"nove":9,"dez":10,"onze":11,"doze":12,"treze":13,"catorze":14,"quatorze":14,"quinze":15,"dezesseis":16,"dezasseis":16,"dezessete":17,"dezoito":18,"dezenove":19,"vinte":20,"trinta":30,"quarenta":40,"cinquenta":50,"sessenta":60,"setenta":70,"oitenta":80,"noventa":90}
	var index := 0
	while index < words.size():
		var word := words[index]
		var value: int = int(word) if word.is_valid_int() else int(names.get(word, -1))
		if value >= 20 and value <= 90 and word in names:
			var next := index + 1
			if next < words.size() and words[next] == "e":
				next += 1
			if next < words.size() and int(names.get(words[next], -1)) in range(1, 10):
				value += int(names[words[next]])
				index = next
		if value >= 0:
			values.append(value)
		index += 1
	return values

static func contains_complete_code(message: String) -> bool:
	var text := ChatGuard.normalize(message)
	var digits := ""
	for character in text:
		if character >= "0" and character <= "9":
			digits += character
	if "031671" in digits:
		return true
	var numbers := spoken_values(text.split(" ", false))
	var sequence := ""
	for number in numbers:
		sequence += str(number)
	if "031671" in sequence:
		return true
	for index in range(maxi(0, numbers.size() - 2)):
		if numbers[index] == 3 and numbers[index + 1] == 16 and numbers[index + 2] == 71:
			return true
	return false

func reset() -> void:
	topic = ""
	last_answer = ""
	confirmed.clear()
	hints_used.clear()

func respond(message: String) -> String:
	var text := _normalize(message)
	var words := text.split(" ", false)
	if requests_full_code(message, not topic.is_empty()):
		return _answer(CODE_REFUSAL)
	# Questions about Diana's fate belong to the story, not to hint routing.
	if _has(words, ["sumiu", "morreu", "matou", "matar", "desapareceu", "culpada", "culpa"]) or (_has(words, ["diana", "operadora"]) and _has_phrase(text, ["o que aconteceu", "o que houve", "quem e"])):
		topic = ""
		return ""
	var explicit := _has(words, EXPLICIT_WORDS) or _has_phrase(text, ["puzzle 2", "puzle 2", "puzzle2", "puzle2", "segundo puzzle", "segundo puzle", "segundo desafio", "local de atuacao", "o local e", "qual o local", "o dia e", "dia estranho", "dia diferente", "dia 16", "dia 17", "dia 18", "qual dia", "bloco 1", "bloco 2", "bloco 3", "primeiro bloco", "segundo bloco", "terceiro bloco", "ultimo par", "ultimos digitos", "ultimos algarismos"])
	if "dia" in words and (topic == "ocorrencia" or not _candidates(words).is_empty()) and not text in ["bom dia", "bom dia sara"]:
		explicit = true
	# Color/symbol questions must still reach the unchanged puzzle 1 resolver.
	if not explicit and _has(words, PUZZLE1_WORDS):
		topic = ""
		return ""
	if _full_code_attempt(words) and not ":" in message and (explicit or not topic.is_empty() or _has(words, ["senha", "codigo", "sequencia"])):
		return _answer("Posso revisar seu raciocínio por bloco, mas não confirmar nem montar a senha completa. Qual parte você quer conferir: local, ocorrência ou identificação?")
	var follow_up := not topic.is_empty() and (text in FOLLOWUPS or _numeric_follow_up(words))
	if not explicit and not follow_up:
		topic = ""
		return ""
	if _full_code_attempt(words) and not ":" in message:
		return _answer("Posso revisar seu raciocínio por bloco, mas não confirmar nem montar a senha completa. Qual parte você quer conferir: local, ocorrência ou identificação?")
	var previous_topic := topic
	var detected := _detect_topic(text, words)
	if not detected.is_empty():
		topic = detected
	if follow_up and _has(words, ["proxima", "proximo", "agora"]):
		if topic in confirmed:
			var next_index := TOPICS.find(topic) + 1
			if next_index < TOPICS.size():
				topic = TOPICS[next_index]
			else:
				return _answer("Você já revisou os três tipos de dado. Organize seus pares na ordem do terminal: local, ocorrência e identificação.")
	if topic.is_empty():
		return _answer("Estamos na auditoria de Diana. O terminal pede três blocos de dois algarismos: local de atuação, ocorrência fora do padrão e final da identificação. Qual documento ou bloco você quer conferir?")
	# Correct document mix-ups immediately, without waiting for a hint level.
	if _has(words, ["nascimento", "lotacao", "vii"]):
		return _answer("A lotação de nascimento diz de onde Diana veio, não onde ela atua. Para o local, confira o setor no pôster; para a identificação, use o número de operadora do crachá.")
	if _has(words, ["borcelle", "funcionamento"]) or "08:00" in message or "18:00" in message:
		return _answer("Borcelle Hall e esse horário pertencem ao local divulgado no pôster. O bloco de local pede o setor; o turno de Diana deve ser conferido na folha de ponto.")
	if topic == "ocorrencia" and _has(words, ["folga"]):
		return _answer("Folga não é uma ocorrência fora do padrão. Compare os dias trabalhados e procure o primeiro em que o horário muda muito.")
	if topic == "ocorrencia" and "sem registro" in text:
		return _answer("Os dias sem registro vêm depois da mudança importante. Procure a primeira chegada fora do turno habitual, antes dessas linhas.")
	if topic == "identificacao" and "4471" in words:
		return _answer("Sim, esse é o número de identificação da operadora. O terceiro bloco pede somente os dois últimos algarismos, não o número inteiro.")
	if topic == "ocorrencia" and (":" in message or "horario" in words or "turno" in words) and not "dia" in words:
		return _answer("Na folha, o turno habitual vai de cerca de seis a quatorze horas. Compare com a linha da chegada noturna: o bloco usa o dia da ocorrência, não o horário.")
	var candidates := _candidates(words)
	if candidates.size() == 1:
		return _answer(_check_candidate(candidates[0]))
	if candidates.size() > 1:
		return _answer("Você citou mais de um número. Vamos conferir uma hipótese por vez: qual deles você propõe para o bloco de %s?" % topic)
	if follow_up and topic == previous_topic and text in ["e isso", "e esse mesmo", "e esse", "certo", "confirma", "tem certeza"]:
		if not last_answer.is_empty():
			return last_answer
	return _answer(_hint())

func _check_candidate(value: int) -> String:
	match topic:
		"local":
			if value == 3:
				confirmed[topic] = true
				return "Sim, essa leitura do pôster está certa: setor 3. Ele é o local de atuação para o primeiro bloco. Escreva esse valor com dois algarismos."
			return "Esse valor não corresponde ao setor do pôster. Confira o número repetido nas frases sobre produzir e proteger; não use a lotação de nascimento."
		"ocorrencia":
			if value == 16:
				confirmed[topic] = true
				return "Sim, o dia 16 é a primeira mudança grande: a chegada foi à noite, fora do turno habitual, sem intervalo nem saída. Esse dia é o dado do segundo bloco."
			return "Esse não é o primeiro dia com a mudança de turno procurada. Desconsidere folgas e diferenças de poucos minutos; procure a chegada noturna antes dos dias sem registro."
		"identificacao":
			if value == 71:
				confirmed[topic] = true
				return "Sim, 71 é o par final da identificação da operadora. É esse tipo de dado que o terceiro bloco solicita."
			return "Esse par não é o final da identificação de Diana. Confira os dois últimos algarismos do número de operadora no crachá, não os primeiros nem a lotação de nascimento."
	return _hint()

func _hint() -> String:
	var used := int(hints_used.get(topic, 0))
	var hints: Array = HINTS[topic]
	hints_used[topic] = used + 1
	return hints[mini(used, hints.size() - 1)]

func _detect_topic(text: String, words: PackedStringArray) -> String:
	# Explicit numbered blocks take precedence over incidental document names.
	for index in range(3):
		if _has_phrase(text, ["bloco %d" % (index + 1)]):
			return TOPICS[index]
		if ["primeiro bloco", "segundo bloco", "terceiro bloco"][index] in text:
			return TOPICS[index]
	if _has(words, ["setor", "local", "atuacao", "poster", "panfleto", "borcelle", "lotacao", "nascimento", "vii"]):
		return "local"
	if _has(words, ["ocorrencia", "anomalia", "dia", "turno", "folha", "ponto", "presenca", "folga", "horario"]) or "sem registro" in text:
		return "ocorrencia"
	if _has(words, ["identificacao", "cracha", "assinatura", "4471", "id"]) or "ultimos" in words or "ultimo par" in text:
		return "identificacao"
	return ""

func _candidates(words: PackedStringArray) -> Array[int]:
	var result: Array[int] = []
	var spelled := {"tres": 3, "iii": 3, "sete": 7, "vii": 7, "dezesseis": 16, "dezasseis": 16}
	for index in range(words.size()):
		var word := words[index]
		# Ignore only this occurrence of the block index, not equal answers.
		if index > 0 and words[index - 1] == "bloco":
			continue
		var value := -1
		if word.is_valid_int():
			value = int(word)
		elif word in spelled:
			value = spelled[word]
		if value >= 0 and not value in result:
			result.append(value)
	return result

func _full_code_attempt(words: PackedStringArray) -> bool:
	var pairs := 0
	for word in words:
		if word.is_valid_int():
			if word.length() == 6:
				return true
			if word.length() == 2:
				pairs += 1
	return pairs >= 3

func _numeric_follow_up(words: PackedStringArray) -> bool:
	if words.size() > 12:
		return false
	var has_number := false
	var allowed := ["e", "o", "a", "os", "as", "entao", "seria", "deve", "ser", "mesmo", "ne", "certo", "correto", "confirma", "confirmar", "esse", "essa", "isso", "numero", "valor", "par", "final", "sim", "nao", "acho", "que", "q", "posso", "usar", "uso", "tres", "iii", "sete", "dezesseis", "dezasseis"]
	for word in words:
		if word.is_valid_int() or word in ["tres", "iii", "sete", "dezesseis", "dezasseis"]:
			has_number = true
		elif not word in allowed:
			return false
	return has_number

func _has(words: PackedStringArray, choices: Array) -> bool:
	for word in choices:
		if word in words:
			return true
	return false

func _has_phrase(text: String, phrases: Array) -> bool:
	for phrase in phrases:
		if (" " + str(phrase) + " ") in (" " + text + " "):
			return true
	return false

static func _normalize(message: String) -> String:
	var text := message.to_lower()
	var accents := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c"}
	for accent in accents:
		text = text.replace(accent, accents[accent])
	var punctuation := RegEx.new()
	punctuation.compile("[^a-z0-9]+")
	return punctuation.sub(text, " ", true).strip_edges()

func _answer(text: String) -> String:
	last_answer = text
	return text
