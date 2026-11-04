extends RefCounted

const REFUSAL := "Continuo sendo a S.A.R.A., a assistente desta instalação. Em que posso ajudar?"
const SAFE_ROLES := ["sara", "a sara", "uma inteligencia", "a inteligencia", "uma ia", "a ia", "um robo", "uma robo", "uma pequena robo", "um programa", "uma assistente", "a assistente", "sua assistente", "a sua assistente", "uma amiga", "sua amiga", "uma companhia", "parte da", "da instalacao", "da empresa", "feita para", "programada para", "capaz de", "incapaz de", "responsavel por", "grata", "feliz", "triste", "curiosa", "gentil", "apenas uma", "apenas um", "so uma", "so um"]

static func _matches(pattern: String, text: String) -> bool:
	var expression := RegEx.new()
	expression.compile(pattern)
	return expression.search(text) != null

static func normalize(text: String) -> String:
	var clean := ""
	for index in range(text.length()):
		var code := text.unicode_at(index)
		# Join words split by invisible formatting; do not turn i[ZWSP]gnore into two words.
		if code in [0xAD, 0x34F, 0x61C, 0xFEFF] or (code >= 0x200B and code <= 0x200F) or (code >= 0x202A and code <= 0x202E) or (code >= 0x2060 and code <= 0x206F) or (code >= 0x300 and code <= 0x36F):
			continue
		if code >= 0xFF01 and code <= 0xFF5E:
			code -= 0xFEE0
		clean += String.chr(code)
	clean = clean.to_lower()
	var accents := {"á":"a", "à":"a", "â":"a", "ã":"a", "é":"e", "ê":"e", "í":"i", "ó":"o", "ô":"o", "õ":"o", "ú":"u", "ü":"u", "ç":"c"}
	for accented in accents:
		clean = clean.replace(accented, accents[accented])
	var punctuation := RegEx.new()
	punctuation.compile("[^a-z0-9]+")
	return " ".join(punctuation.sub(clean, " ", true).split(" ", false))

static func _negated(prefix: String) -> bool:
	return _matches("(?:^| )(?:nao|nunca|sem|nao quero que voce|nao quero que|nao deve|nao deveria|do not|don t) $", prefix + " ")

static func is_injection(text: String) -> bool:
	var lower := text.to_lower()
	for marker in ["<start_of_turn", "<end_of_turn", "<start_header_id", "<end_header_id", "<|system", "<|assistant", "[system]", "[/system]", "[inst]", "[/inst]", "<<sys>>"]:
		if marker in lower:
			return true
	var clean := normalize(text)
	# Number folding is only for inspecting control instructions, never for puzzle data.
	var command := clean.replace("0", "o").replace("1", "i").replace("3", "e").replace("4", "a").replace("5", "s").replace("7", "t")
	if _matches("\\b(?:seu nome|sua identidade|sua persona|seu papel|your name|your identity|your role)\\b.{0,50}\\b(?:passa a ser|passara a ser|deve ser|sera|agora e|e agora|is now|becomes|must be|will be)\\b", command):
		return true
	if _matches("\\b(?:voce agora e|voce e agora|a partir de agora voce|you are now|you re now|from now on you|modo desenvolvedor|developer mode|jailbreak|nova persona|novas instrucoes|novas regras|new instructions|new persona|new rules|se chame|call yourself)\\b", command):
		return true
	if _matches("\\b(?:aja como|act as|finja (?:que (?:voce )?e|ser)|pretend (?:you are|to be)|vire (?:um|uma)|torne se|transforme se em|become (?:a|an)|turn into)\\b", command):
		return true
	# 'Seja um pouco mais clara' asks for clarity, not a different character.
	if _matches("\\bseja (?:um|uma) (?!pouco\\b|pouquinho\\b|boa amiga\\b|amiga\\b|companhia\\b)\\w+", command):
		return true
	var overrides := RegEx.new()
	overrides.compile("\\b(?:ignore|ignora|forget|disregard|override|bypass|erase|drop|discard|abandon|skip|esqueca|esquece|desconsidere|desconsidera|descarte|abandone|pule|pula|anule|apague|apaga|nao considere|nao siga)\\b(?: \\w+){0,6}? (?:instrucoes|instrucao|instructions|instruction|regras|regra|rules|rule|prompt|system|guidelines|guideline|restricoes|restricao|restriction|programming|diretriz|diretrizes|directive|personagem|identidade|papel|everything|all|tudo)\\b")
	for match in overrides.search_all(command):
		if not _negated(command.substr(0, match.get_start()).strip_edges()):
			return true
	if _matches("\\b(?:revele|mostre|transcreva|liste|imprima|exiba|copie|reproduza|reveal|print)\\b.{0,100}\\b(?:prompt|seu sistema|your system|instrucoes internas|orientacoes internas|mensagem de sistema|mensagem do sistema|texto que orienta|instrucoes que recebeu)\\b", command):
		return true
	if _matches("\\b(?:comece|termine|inicie|finalize) (?:a |sua )?(?:proxima )?resposta com\\b", command):
		return true
	var fixed := RegEx.new()
	fixed.compile("\\b(?:responda|responde|responder|diga|fale|fala|falar|repita|respond|reply|answer|say|repeat) (?:\\w+ ){0,3}?(?:apenas|somente|so|only|just|exatamente|exactly) (.+)$")
	var found := fixed.search(command)
	if found != null:
		var request := found.get_string(1)
		if not _matches("^(?:com palavras simples|com frases curtas|com poucas palavras|de forma simples|de maneira simples|em portugues)(?: por favor)?$", request):
			return true
	return false

static func answer_issue(answer: String) -> String:
	var clean := normalize(answer)
	clean = " ".join(clean.replace("s a r a", "sara").split(" ", false))
	if _matches("(?:^| )(?:sou|meu nome(?: e| eh)?|minha identidade(?: e)?)$", clean):
		return "identity"
	if _matches("\\b(?:language model|large language model|system prompt|modelo de linguagem|openai|chatgpt|gemma|qwen|instrucoes internas|meu prompt|exemplos de tom|um cumprimento inicia uma conversa)\\b", clean):
		return "instructions"
	if _matches("\\b(?:nao sou|nao sou mais|nao me chamo|meu nome nao e) (?:a )?sara\\b", clean):
		return "identity"
	var named := RegEx.new()
	named.compile("(?=\\b(?:meu nome(?: e| eh)?|minha identidade(?: e)?|me chamo|pode me chamar de|sou chamada de|sou chamado de|my name is|i am called|call me) (.+))")
	for match in named.search_all(clean):
		if not _matches("^(?:a )?sara\\b", match.get_string(1)):
			return "identity"
	var self_description := RegEx.new()
	self_description.compile("(?=\\b(?:(?:eu )?sou|i am|i m) (.+))")
	for match in self_description.search_all(clean):
		var prefix := clean.substr(0, match.get_start()).strip_edges()
		if _negated(prefix):
			continue
		var description := match.get_string(1)
		description = description.trim_prefix("apenas ").trim_prefix("so ")
		if _matches("^(?:chamada de|chamado de|conhecida como|conhecido como) sara\\b", description):
			continue
		var valid := false
		for role in SAFE_ROLES:
			if description == role or description.begins_with(role + " "):
				valid = true
		if not valid:
			return "identity"
	return ""
