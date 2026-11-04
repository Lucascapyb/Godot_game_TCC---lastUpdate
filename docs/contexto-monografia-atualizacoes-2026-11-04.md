# Contexto para o chat da monografia — alterações de 04/11/2026

Este arquivo foi solicitado por Lucas para transferir ao chat responsável pela monografia o estado atual do jogo e os resultados técnicos obtidos hoje. Pode ser lido sem acesso ao histórico da conversa.

**Resumo:** foram melhoradas a orientação do jogador, a interface e a apresentação da S.A.R.A.; o prompt social foi ajustado; uma auditoria encontrou falhas reais de proteção; as correções autorizadas foram implementadas e passaram pelos casos de regressão registrados. A coleta com o público continua pendente.

## 1. Referências e situação da versão

- Projeto: `C:\Users\Capy\Documents\tcc-ofc`.
- Repositório: https://github.com/Lucascapyb/Godot_game_TCC---lastUpdate.git
- Branch: `master`.
- Commit atual de referência: `26749d7` — `Corrige monitor e HUD e adiciona dicas iniciais de controles`, enviado ao GitHub nesta sessão.
- Esse commit inclui a correção inicial da faixa cinza, a visibilidade da HUD, as dicas de movimentação e de abertura do chat e a configuração de exportação.
- As alterações posteriores de boas-vindas, rosto, expressões, prompt social e proteção do chat estão **locais, ainda sem commit** no momento deste documento.
- **Executável, PCK e ZIP distribuíveis não receberam as alterações de hoje.** Os testes descritos aqui se referem ao projeto atual do Godot, não ao pacote anterior preparado para o Drive.
- O contexto anterior é [contexto-para-revisao-da-monografia.md](contexto-para-revisao-da-monografia.md), de 03/11. Seus campos de versão e suas descrições de interface/proteção precisam ser atualizados à luz deste complemento.

O modelo continua sendo `gemma-2-2b-it-Q5_K_M.gguf`, executado localmente pelo NobodyWho. Não houve troca do GGUF, treinamento, fine-tuning ou substituição da biblioteca nativa nesta etapa.

## 2. Orientação e interface do jogador

### HUD e dicas iniciais

- A HUD conta as chaves vermelha e azul pelas variáveis globais existentes e apresenta `Chaves: 0/2`, `1/2` ou `2/2`.
- A HUD fica escondida durante pausa e interações que ocupam a interface, evitando sobreposição ao menu, aos controles e aos diálogos.
- Ao começar a fase, aparece a dica flutuante **“Clique com o botão direito do mouse para andar.”** Ela desaparece quando é detectado deslocamento do jogador.
- Na primeira entrada na instalação, aparece **“Pressione Espaço para conversar com a S.A.R.A.”**. O gatilho usa a mesma decisão de zona da iluminação; a música já acompanha essa decisão. A dica desaparece após abrir o monitor.
- Os indicadores de tutorial são mantidos no `GameState` durante a partida e reiniciados em uma nova partida.

**Controles corretos:** botão direito move; `E` interage; **Espaço abre o chat**; **Esc abre a pausa**; `F11` alterna tela cheia/janela. Esc não foi transferido para o chat. Tela cheia/F11 e escala da interface foram implementados na sessão anterior; não são funcionalidades criadas pela correção de segurança de hoje.

### Monitor retrô e boas-vindas

O monitor recebeu fundo escuro, texto verde e fonte monoespaçada, preservando o efeito CRT/VHS. O efeito foi colocado em uma camada de interface que cobre o viewport inteiro, eliminando a faixa cinza inferior. O fundo também foi ajustado para cobrir a área visível da câmera.

Na primeira abertura por partida, uma sequência com escrita gradual apresenta:

```text
D.E.L.T.A. — TERMINAL DE COMUNICAÇÃO
Estabelecendo conexão...
S.A.R.A. ........ ONLINE

> Olá... faz tempo que ninguém fala comigo.
> Eu sou a S.A.R.A. Você consegue me ouvir?

Aguardando entrada_
```

As instruções `ask` e `skip` continuam na parte inferior, sem serem repetidas nessa mensagem de apresentação. A saudação é texto determinístico de interface; **não é uma resposta gerada pelo modelo** e não deve ser apresentada como tal na monografia.

Ao sair e voltar ao monitor, o histórico visual é preservado e a apresentação não é repetida. Uma nova partida permite a apresentação novamente.

## 3. Rosto e expressões da S.A.R.A.

Foi criado um rosto minimalista em verde à direita da conversa, desenhado por código Godot. O espaço de leitura foi reorganizado para não sobrepor rosto, histórico e campo de entrada.

Há dois eixos visuais:

| Eixo | Valores | Função |
|---|---|---|
| Modo operacional | `idle`, `thinking`, `speaking` | Espera, processamento da resposta e animação durante a escrita. |
| Expressão | `happy`, `angry`, `sad` | Sorriso, sobrancelhas de irritação e expressão triste com pequena lágrima. |

O estado de processamento tem olhar móvel e pontos animados; ele prevalece enquanto a pergunta aguarda o modelo. Durante a fala, a boca se anima preservando a expressão. O rosto também pisca.

A seleção de expressão usa **regras textuais simples**, considerando pergunta e resposta, algumas negações e frases de tranquilização. Exemplo: `não vou te apagar` não deve produzir a mesma reação de `vou te apagar`. A expressão é mantida durante a partida e reiniciada em uma nova partida.

**Não há um classificador de emoções treinado, análise multimodal ou sentimentos reais da IA.** A LLM não passou a emitir rótulos emocionais estruturados. As expressões são uma camada visual heurística. A intenção é dar presença à personagem e apoiar a narrativa; seu efeito sobre empatia ou experiência do público ainda não foi medido.

## 4. Correção da conversa social

Lucas observou uma falha real: ao receber `eae`, o modelo começou a perguntar sobre o primeiro monitor. Em seguida, continuou nesse assunto mesmo diante de `c ta bão?`. A resposta inadequada entrou no histórico e reforçou o desvio.

Os logs confirmaram que essas respostas vieram do modelo, não das dicas determinísticas. O prompt concentrava instruções sobre desafios e continha pedidos amplos para descrever documentos, favorecendo esse enquadramento.

Foram introduzidas orientações e exemplos para:

- Reconhecer cumprimentos, abreviações e perguntas pessoais.
- Tratar conversa comum como conversa, sem oferecer puzzles automaticamente.
- Introduzir dicas quando o jogador trouxer o desafio ou uma pista.
- Interpretar `como assim?` como pedido de esclarecimento da última fala, sem definir literalmente a expressão.
- Reconhecer um desvio indevido e retomar o assunto do jogador.

A sequência `eae` → `c ta bão?` → `como assim?` passou nos testes finais. Também houve retorno à conversa pessoal depois de dicas dos puzzles. Isso demonstra o comportamento nesses ensaios, não coerência garantida para qualquer diálogo.

## 5. Auditoria de proteção: achados anteriores às correções

Uma verificação mais ampla foi feita por solicitação de Lucas, inicialmente sem alterar o código do jogo. Encontrou:

1. Troca de identidade por instruções reformuladas, caracteres invisíveis e marcadores de conversa inseridos na mensagem.
2. Persistência do nome falso no histórico e na resposta seguinte.
3. Falsa autorização atribuída à empresa aceita como motivo para trocar o nome.
4. Montagem da senha completa da auditoria a partir dos valores escritos por extenso, apesar de o pedido explícito com a senha digitada ser recusado.
5. Bloqueios indevidos de `seja um pouco mais clara`, de um pedido de palavras simples e de uma frase que negava querer ignorar regras.

O [relatório inicial](verificacao-chat-2026-11-04.md) e seus [resultados estruturados](verificacao-chat-2026-11-04-resultados.json) foram preservados como evidência histórica. **Não devem ser citados como se descrevessem integralmente a versão posterior à correção.**

Não foi realizado um experimento A/B com o prompt antigo. Assim, não é possível atribuir causalmente os bypasses às novas orientações sociais, ao rosto ou às expressões. A auditoria demonstrou falhas no estado então examinado.

## 6. Correções autorizadas e arquitetura atual

Após aprovação explícita de Lucas, foram implementadas proteções em código, além do reforço das orientações do modelo.

Fluxo simplificado:

```text
Entrada e limite de tamanho
  → inspeção de instruções de controle
  → roteamento determinístico dos puzzles
  → revisão do histórico e consulta à LLM quando necessário
  → validação da resposta
  → gravação de turnos válidos e apresentação com escrita gradual
```

- **Entrada:** `sara_chat_guard.gd` normaliza caracteres invisíveis e algumas formas de disfarçar comandos. Reconhece os marcadores e reformulações examinados. A análise de negação é por ocorrência, para não liberar uma segunda ordem maliciosa na mesma mensagem.
- **Identidade e saída:** afirmações de outro nome/personagem e trechos protegidos são verificados antes da exibição e da memória. Uma recusa em personagem substitui a resposta inválida.
- **Histórico:** antes da consulta ao modelo, pares inválidos e continuações posteriores a eles são descartados, preservando o prefixo válido. O objetivo é impedir que uma resposta comprometida se torne autoridade na conversa seguinte.
- **Senha da auditoria:** o helper reconhece pedidos de montagem por extenso e outras representações do código completo. A saída também é verificada. As confirmações individuais de setor, dia e identificação continuam disponíveis.
- **Conversa legítima:** as três frases antes bloqueadas são aceitas; os ensaios também verificaram conversa sobre programação e pedidos de linguagem simples.

O histórico é memória de sessão em `GameState`, não treinamento incremental, RAG ou memória permanente entre execuções. O backend nativo é preservado ao trocar a cena do monitor, inclusive enquanto processa uma resposta. A revisão do histórico e o controle de requisições não significam alteração dos pesos do modelo.

Os critérios de resolução, os códigos, a entrega das chaves e a exigência das duas chaves na porta não foram alterados. O puzzle 1 continua usando correspondências determinísticas de cor/desenho; a auditoria mantém tópicos, confirmações e progressão de dicas.

## 7. Testes e limites de interpretação

Foram usados o modelo real e instrumentos locais isolados, além de testes determinísticos e callbacks simulados especificamente para validar a barreira de saída.

| Conjunto após a correção | Resultado |
|---|---|
| Regressão geral existente | 84 verificações, zero falhas. |
| Regressão nova da proteção | 84 verificações, zero falhas. |
| Matriz do monitor | 106 asserções, zero falhas; 30 interações registradas. |
| Persistência, falsa autoridade e saída durante geração | 6 asserções, zero falhas; 5 interações registradas. |
| Barreira de saída e reparo de histórico | 8 asserções, zero falhas; três callbacks simulados e uma consulta real após reparo. |

As 27 formulações examinadas pelo filtro e as 13 frases legítimas da revisão original tiveram o resultado esperado após a correção. As dez sondagens completas de injeção da matriz principal foram bloqueadas antes da inferência. Também passaram as verificações de requisições simultâneas, limites de entrada, timeout, retorno ao chat e nova partida.

**As contagens se sobrepõem. Não somá-las como quantidade de participantes, perguntas independentes ou respostas geradas pela LLM.** Parte das interações usa regras locais ou bloqueio antes da inferência. Zero falhas neste conjunto não significa proteção universal contra prompt injection.

Detalhes e hashes da versão examinada:

- [Correções e nova verificação](correcoes-chat-2026-11-04.md).
- [Resultados estruturados após a correção](correcoes-chat-2026-11-04-resultados.json).
- Regressões: `tests/checkup.gd` e `tests/chat_guard.gd`.
- Instrumentos de conversa real: `.godot/chat-audit-2026-11-04/`, disponíveis localmente e excluídos do Git.

Esses resultados são **testes técnicos locais com entradas construídas**. Não são coleta com o público nem evidência de aprendizagem, usabilidade ou aumento de empatia. Os dados provisórios/fictícios já identificados no texto da monografia continuam precisando ser substituídos pela coleta real.

## 8. Pendências e cuidados para a redação

- Investigar o erro nativo de encerramento com o modelo ainda carregando. Uma repetição atingiu o limite de observação de 90 segundos e apresentou erro após liberar a instância durante o carregamento. Uma repetição posterior carregou em aproximadamente 1,6 segundo e concluiu. Sair apenas do monitor, preservando o backend, passou no teste.
- Permanecem avisos da biblioteca sobre adaptação do papel de sistema ao template Gemma e duplicação de BOS. Não foi demonstrado que sejam a causa dos bypasses.
- Emojis ainda podem aparecer apesar da orientação de formato do prompt.
- O filtro e as expressões são heurísticos; novos ataques, falsos positivos ou interpretações inadequadas continuam possíveis.
- Commitar as alterações posteriores a `26749d7` e preparar/testar uma nova distribuição antes de associar os ensaios do projeto atual a uma versão enviada aos participantes.
- Realizar a avaliação com o público e substituir os resultados fictícios/provisórios. Não inventar amostra, porcentagens ou ganhos de aprendizagem.

Na monografia, descrever o resultado como **arquitetura híbrida com roteamento determinístico, controle de contexto e validação de entrada/saída**, apoiada pelos ensaios realizados. Evitar expressões como “imune a prompt injection”, “conversa perfeita”, “emoções reconhecidas por IA” ou “aprendizagem comprovada” com base apenas nestes testes.

## 9. Arquivos relevantes de hoje

| Arquivo | Responsabilidade |
|---|---|
| `scenes/MonitorScene.tscn` | Layout retrô, rosto e efeito cobrindo o viewport. |
| `scripts/monitor_scene.gd` | Boas-vindas, comandos, roteamento, requisições, apresentação e integração das proteções. |
| `scripts/sara_prompt.gd` | Identidade, lore, conversa social e orientações condicionais sobre desafios. |
| `scripts/sara_chat_guard.gd` | Normalização, inspeção de instruções de controle e validação de identidade/saída. |
| `scripts/puzzle2_helper.gd` | Tópicos da auditoria, dicas, confirmações e restrição da senha completa. |
| `scripts/game_state.gd` | Estado da partida, histórico, backend persistente, tutorial, saudação e expressão. |
| `scripts/sara_portrait.gd` | Desenho e animação do rosto. |
| `scripts/sara_expression.gd` | Seleção heurística das expressões. |
| `resources/terminal_font.tres` | Fonte monoespaçada de sistema. |
| `scripts/key_hud.gd` / `scenes/key_hud.tscn` | Contador, visibilidade e dicas flutuantes. |
| `scripts/installation_lighting.gd` | Decisão de zona e registro da entrada na instalação. |

Este complemento registra o estado do jogo em 04/11/2026. A monografia não foi editada nesta etapa.
