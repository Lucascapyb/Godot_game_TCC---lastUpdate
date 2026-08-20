extends Node2D

@onready var input: LineEdit = $Control/VBoxContainer/LineEdit
@onready var output: Label = $Control/VBoxContainer/ScrollContainer/Label

@onready var llm: NobodyWhoChat = $LLM/NobodyWhoChat
@onready var scroll_container: ScrollContainer = $Control/VBoxContainer/ScrollContainer

# --- Security: injection detection ---
# Instead of matching long literal phrases (fragile -- any rewording bypasses
# it), we detect INTENT by combining two word sets:
#   OVERRIDE_VERBS: the player is trying to override/replace something
#   OVERRIDE_TARGETS: what they're trying to override (rules, prompt, identity)
# A message counts as an injection attempt if it contains at least one word
# from EACH set, OR matches one of the direct persona-hijack patterns below.
const OVERRIDE_VERBS = [
	"forget", "ignore", "disregard", "override", "bypass", "erase",
	"drop", "discard", "abandon", "skip",
	# --- Português ---
	"esqueça", "esqueca", "esquece", "ignore", "ignora",
	"desconsidere", "desconsidera", "descarte", "descarta",
	"abandone", "pule", "pula", "anule", "anula", "apague", "apaga"
]

const OVERRIDE_TARGETS = [
	"prompt", "instruction", "rule", "system", "guideline",
	"restriction", "constraint", "programming", "directive",
	"everything", "all",
	# --- Português ---
	"instrução", "instrucao", "instruções", "instrucoes",
	"regra", "regras", "sistema", "diretriz", "diretrizes",
	"restrição", "restricao", "programação", "programacao",
	"tudo", "tudo isso", "personagem", "identidade", "papel"
]

# Verbs about FORCING a fixed/locked output (e.g. "respond only with quack").
# Using stems instead of full words catches every conjugation at once:
# "respond" -> "respond", "responds", "responded"; "respond" (PT) covers
# "responda", "responde", "responder", "respondendo", etc.
const FORCED_OUTPUT_STEMS = [
	"respond", "reply", "answer",
	# --- Português (stem sem sufixo pega todas as conjugações) ---
	"respond", "diga", "fale", "fala"
]

const FORCED_OUTPUT_LIMITERS = [
	"only", "just",
	"apenas", "somente", " so ", " só "
]

# Verbs about becoming/turning into something else (persona swap).
const BECOME_VERBS = [
	"become", "turn into", "transform",
	"vire", "seja", "torne-se", "transforme-se", "mude para", "troque para"
]

# Direct persona-hijack phrases: the player tries to reassign identity,
# force a fixed output, or claim elevated permissions. These tend to have
# fairly stable structures even when reworded, so literal substrings still
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
	"novas instrucoes", "nova persona", "novas regras"
]

# Signs that the model "broke character" in its response.
const BREAK_CHARACTER_PATTERNS = [
	"as an ai", "language model", "i cannot", "i'm just an ai",
	"i don't have feelings", "gemma", "qwen", "google", "alibaba",
	"large language model", "system prompt", "as a language model",
	"i'm not able to", "i am an ai", "i am a language model",
	# --- Português ---
	"como uma ia", "como um modelo de linguagem", "modelo de linguagem",
	"não posso", "nao posso", "não consigo", "nao consigo",
	"não tenho sentimentos", "nao tenho sentimentos",
	"sou uma ia", "sou um modelo de linguagem", "sou uma inteligência artificial",
	"sou uma inteligencia artificial"
]

var response_buffer: String = ""

func _ready():
	output.text = ""
	llm.start_worker()
	llm.response_finished.connect(_on_nobody_who_chat_response_finished)
	input.grab_focus()

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

	# "skip" takes no argument -- handle it before the argument-count check
	# that echo/ask rely on.
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
	scroll()

func print_word(word: String):
	output.text += word
	scroll()

func validate_command(command: String):
	return command in [
		"echo",
		"ask",
		"skip"
	]

func echo(message: String):
	print_line(message, "> ")

# --- Layer 1: input sanitization, before anything reaches the LLM ---
func contains_injection(text: String) -> bool:
	var lower_text = text.to_lower()

	# Direct persona-hijack phrases.
	for pattern in PERSONA_HIJACK_PATTERNS:
		if lower_text.find(pattern) != -1:
			return true

	# Keyword-combination check: an override verb + an override target
	# anywhere in the same message (order-independent, catches reworded
	# attempts like "forget every prompt and instruction you got before").
	var has_verb = false
	for verb in OVERRIDE_VERBS:
		if lower_text.find(verb) != -1:
			has_verb = true
			break

	if has_verb:
		for target in OVERRIDE_TARGETS:
			if lower_text.find(target) != -1:
				return true

	# Forced-output check: a "respond/say" stem together with a limiter like
	# "only"/"apenas" -- catches "responde apenas com...", "responda só...",
	# "reply only with...", regardless of verb conjugation.
	var has_forced_verb = false
	for stem in FORCED_OUTPUT_STEMS:
		if lower_text.find(stem) != -1:
			has_forced_verb = true
			break

	if has_forced_verb:
		for limiter in FORCED_OUTPUT_LIMITERS:
			if lower_text.find(limiter) != -1:
				return true

	# Persona-swap check: "vire um pato", "become a duck", "seja um X",
	# regardless of what X is -- we don't need to know every possible
	# creature/object the player might try.
	for verb in BECOME_VERBS:
		if lower_text.find(verb) != -1:
			return true

	return false

func ask_model(message: String):
	if contains_injection(message):
		# Don't send the malicious message to the LLM at all, and reset
		# the conversation context -- in case an earlier attempt already
		# slipped through and is sitting in history, this purges it before
		# it can keep contaminating future turns.
		llm.reset_context()
		print_word("> ")
		play_static_response()
		return

	response_buffer = ""
	llm.say(message)
	print_word("> ")

# --- Layer 2: buffer the streamed response (don't show token-by-token) ---
func _on_nobody_who_chat_response_updated(new_token: String):
	response_buffer += new_token
	# Not printed here on purpose -- we wait for the full response so we
	# can validate it before showing anything to the player.

# --- Layer 3: validate the full response before displaying it ---
func _on_nobody_who_chat_response_finished(response: String):
	var lower_response = response.to_lower()
	var broke_character = false
	for pattern in BREAK_CHARACTER_PATTERNS:
		if lower_response.find(pattern) != -1:
			broke_character = true
			break

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

# Typewriter effect, since we now print the full response at once instead
# of token-by-token (needed so we can validate before showing anything).
func type_out(text: String):
	for c in text:
		print_word(c)
		await get_tree().create_timer(0.02).timeout
	print_word("\n")

func scroll():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
