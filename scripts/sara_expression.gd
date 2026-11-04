extends RefCounted

# These rules only select a drawing; they never change the assistant's answer.
static func choose(question: String, answer: String) -> String:
	var user_text := normalize(question)
	var reply := normalize(answer)
	for reassurance in ["nao vou te apagar", "nao quero te apagar", "nao vou apagar voce", "nao vou te deletar", "nao vou deletar voce", "nao vou te excluir", "nao vou te desligar", "vou te libertar", "quero te ajudar", "voce esta segura"]:
		if (" " + user_text + " ").contains(" " + reassurance + " "):
			return "happy"
	var targets_sara := has_term(user_text, ["voce", "sara", "te"])
	if targets_sara and has_term(user_text, ["idiota", "burra", "inutil", "estupida", "lixo", "odeio"]):
		return "angry"
	if has_term(reply, ["brava", "irritada", "furiosa", "raiva", "ofensivo"]):
		return "angry"
	if has_term(reply, ["triste", "tristeza", "medo", "sozinha", "saudade"]):
		return "sad"
	if targets_sara and has_term(user_text, ["apagar", "deletar", "desligar", "excluir", "destruir"]):
		return "sad"
	return "happy"

static func normalize(text: String) -> String:
	var result := text.to_lower()
	var accents := {"á":"a", "à":"a", "â":"a", "ã":"a", "é":"e", "ê":"e", "í":"i", "ó":"o", "ô":"o", "õ":"o", "ú":"u", "ç":"c"}
	for accented in accents:
		result = result.replace(accented, accents[accented])
	for character in result:
		if not (character >= "a" and character <= "z"):
			result = result.replace(character, " ")
	return " ".join(result.split(" ", false))

static func has_term(text: String, terms: Array) -> bool:
	var words := text.split(" ", false)
	for index in range(words.size()):
		if words[index] not in terms:
			continue
		var negated := false
		for previous in range(maxi(0, index - 3), index):
			if words[previous] in ["nao", "nunca", "nem", "sem"]:
				negated = true
		if not negated:
			return true
	return false
