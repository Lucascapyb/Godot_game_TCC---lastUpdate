# Contexto para o Codex responsável pela monografia

Atualizado em **03/11/2026**. Este documento resume a leitura da monografia e a inspeção do jogo para permitir a continuidade em outro chat, sem depender do histórico da conversa.

## 1. Arquivos e versão de referência

- Projeto Godot: `C:\Users\Capy\Documents\tcc-ofc`.
- Repositório: https://github.com/Lucascapyb/Godot_game_TCC---lastUpdate.git
- Branch: `master`.
- Último commit enviado: `8256158` — `Corrige SARA, progresso dos puzzles e layout da apresentacao apos revisao`.
- Monografia analisada: `D:\TCC_2026\TCC_projeto_atualizado\TCC.pdf`.
- PDF com **81 páginas**, modificado em 03/11/2026 às 10h23, conforme informação local do arquivo.
- Fonte LaTeX disponível na mesma pasta: `TCC.tex`, diretório `capitulos`, bibliografia `TCC.bib` e diretório `images`.
- Relatório anterior do jogo: `docs/checkup-2026-10-30.md`.

O commit identifica a versão de referência do código. Capturas, configurações e resultados de ensaios devem identificar a versão efetivamente utilizada; não presumir que todos os materiais do PDF correspondem a esse commit.

## 2. Trabalho e intenção do autor

Título: **S.A.R.A. Protocol: Uma Abordagem Híbrida de Modelo de Linguagem e Máquina de Estados para NPCs em Jogos**.

Autor: Lucas Araujo e Silva Cruz, curso de Ciência da Computação do Centro Universitário do Distrito Federal — UDF. A folha de rosto identifica a professora Kadidja Valeria Reginaldo De Oliveira como orientadora.

A proposta central combina:

1. Conversa livre com uma LLM executada localmente.
2. Regras determinísticas para respostas relacionadas aos puzzles.
3. Controle por estados para organizar as dicas da auditoria.
4. Exploração e resolução de desafios que incentivam descrição de pistas, seleção de contexto e reformulação de perguntas.

O problema de pesquisa apresentado na introdução pergunta como combinar modelo local, regras e estados para manter os diálogos coerentes com o avanço do jogador.

A pesquisa é descrita como aplicada e exploratória, com abordagem qualitativa e quantitativa. A avaliação educativa foi delimitada à **aprendizagem percebida**, não à demonstração de ganho de conhecimento por pré/pós-teste.

## 3. Situação real da coleta com participantes

**O autor confirmou que os resultados de usuários atualmente apresentados são fictícios/provisórios. A coleta real ainda será realizada.**

Na seção 3.3, página 28, aparecem números como:

- 87% consideraram a interface intuitiva;
- duração média de 4 minutos e 27 segundos;
- satisfação média de 4 em uma escala de 1 a 5.

Esses valores não devem ser tratados como evidência empírica. O autor pretende substituí-los após os testes com o público. Enquanto permanecerem no rascunho, é necessário identificá-los explicitamente como exemplos fictícios de apresentação de resultados, ou manter a seção como planejamento.

A introdução, a metodologia e a conclusão já afirmam que a avaliação com participantes está pendente. A seção 3.3 precisa ser conciliada com essas afirmações.

Não inventar amostra, respostas, procedimentos executados, ganhos de aprendizagem ou resultados para completar a versão final.

## 4. Jogo atual: narrativa e fluxo

O jogo é isométrico. O jogador explora uma instalação associada à D.E.L.T.A. e conversa com a S.A.R.A., uma IA assistente que guarda arquivos confidenciais e passou a ser considerada uma ameaça. O jogador foi enviado para apagá-la. As conversas e os NPCs aproximam o jogador da personagem e introduzem dúvidas sobre os acontecimentos e os registros dos operadores.

A S.A.R.A. ajuda o jogador mesmo temendo ser apagada. O destino dos operadores permanece incerto; o prompt atual orienta a personagem a não inventar mortes, culpados ou provas de inocência.

Fluxo implementado:

- Menu inicial, créditos e apresentação narrativa.
- Exploração do mapa, NPCs, objetos interativos e documentos.
- Dois puzzles, cada um entregando uma chave diferente.
- Porta que exige as chaves vermelha e azul.
- Computador final que abre a escolha entre apagar ou libertar a S.A.R.A.
- Final de apagamento com despedida; final de libertação com autorização de conexão externa e saída da instalação.
- Retorno ao menu e limpeza do progresso ao iniciar uma nova partida.

Controles principais: botão direito do mouse para movimentação, `E` para interação, espaço para abrir o monitor, `ask <pergunta>` para conversar e `skip` para sair do monitor. Os comandos do chat atualmente aceitam maiúsculas e minúsculas.

O final de libertação tem uma ação explícita no jogo: autorizar a conexão externa. Convém conferir se a descrição narrativa do PDF representa esse desfecho com precisão, sem acrescentar acontecimentos que não são mostrados.

## 5. Arquitetura realmente implementada

### Encaminhamento das mensagens

O fluxo em `scripts/monitor_scene.gd`, função `ask_model`, é:

1. Verificar se já existe uma resposta em andamento.
2. Aplicar filtros heurísticos contra alteração de identidade/instruções.
3. Tentar responder pelas regras da auditoria, o puzzle 2.
4. Tentar responder pelas regras dos símbolos, o puzzle 1.
5. Encaminhar as demais mensagens à LLM.
6. Verificar a resposta gerada e então exibi-la.

As respostas reconhecidas pelas regras são exibidas diretamente: **não são produzidas pela LLM**. Essa distinção é parte da arquitetura híbrida e deve continuar explícita no texto e na defesa.

### Modelo e integração

- Godot 4.7.2 no ambiente utilizado.
- Extensão nativa NobodyWho para inferência local.
- Modelo indicado na cena: `res://ggufs/gemma-2-2b-it-Q5_K_M.gguf`.
- Prompt atual: `scripts/sara_prompt.gd`.
- A pasta do modelo GGUF e o addon nativo NobodyWho estão ignorados no Git. Isso não significa que estejam ausentes da instalação local.

O PDF informa NobodyWho v9.6.0 e contexto de 2.048 tokens para os ensaios documentados. Esses dados devem ser conferidos para a versão usada na nova avaliação. **Não substituir automaticamente por outro valor**: a cena atual não contém um `context_length` explícito, portanto é necessário consultar o valor efetivo na execução para documentar a configuração atual.

### Persistência e contexto

`scripts/game_state.gd` mantém o processo nativo da IA entre cenas. A abertura do monitor não exige recriar o modelo a cada visita. Uma pergunta aguarda a prontidão do modelo e o término de uma geração anterior.

O histórico visual e os turnos enviados à LLM são distintos:

- Texto visível: limitado a 24.000 caracteres.
- Contexto persistente: até seis pares recentes de pergunta/resposta, com limite adicional de 6.000 caracteres.
- Os turnos preservados são restaurados no componente de inferência.
- Respostas locais dos puzzles também podem entrar nesse histórico de contexto.
- Nova partida limpa conversa e progresso das dicas.

Portanto, não descrever a versão atual apenas como uma variável estática que preserva a aparência do chat, nem afirmar que a LLM possui memória ilimitada ou recorda tudo com exatidão.

## 6. Puzzles e controle por estados

### Puzzle 1: símbolos

O jogador descreve a cor e a forma de um botão. As regras associam:

| Descrição | Número |
|---|---:|
| Azul com triângulo | 9 |
| Verde com quadrado | 7 |
| Vermelho com estrela | 2 |
| Amarelo com círculo | 6 |

O terminal valida a sequência e entrega a chave vermelha. Trata-se de reconhecimento por regras, não de uma demonstração de compreensão semântica pela LLM.

### Puzzle 2: auditoria de Diana

O jogador reúne três dados dos documentos:

- Local de atuação: setor do pôster.
- Ocorrência fora do padrão: primeiro dia da mudança importante na folha de ponto.
- Identificação final: últimos algarismos do número da operadora no crachá.

O terminal entrega a chave azul. A ajuda atual está em `scripts/puzzle2_helper.gd` e mantém:

- `topic`: assunto atual — local, ocorrência ou identificação;
- `hints_used`: progressão das dicas por assunto;
- `confirmed`: hipóteses já confirmadas;
- `last_answer`: última orientação para certas retomadas curtas.

Cada assunto possui três dicas progressivamente mais específicas; a seleção satura na última dica. Existem confirmações de hipóteses, correção de confusões entre documentos e retomadas como “e agora?”. Perguntas narrativas sobre o destino de Diana são encaminhadas à conversa livre. O sistema procura evitar fornecer ou confirmar a senha inteira.

**O PDF descreve a implementação anterior:** um contador global `perguntas_puzzle2` e quatro níveis de dicas. Isso não corresponde ao gerenciador atual.

Para a descrição da FSM, representar os estados efetivos, entradas, condições de transição e saídas da implementação atual. O controle está expresso por variáveis e regras; a inspeção não constituiu uma prova formal de equivalência a uma FSM. Não afirmar que há uma FSM global controlando toda a narrativa ou toda resposta da LLM.

Os estados acompanham a conversa e as hipóteses informadas. A assistente não observa automaticamente a tela nem lê todos os documentos ou todo o progresso do mapa.

## 7. Alinhamento com os objetivos acadêmicos

| Proposta | Avaliação da inspeção |
|---|---|
| Conversa livre com modelo local | Implementada. |
| Combinação de LLM e respostas controladas | Implementada, com separação verificável no código. |
| Progressão de dicas por estados | Implementada como gerenciador contextual; atualizar a descrição e os diagramas. |
| Exploração, dois puzzles, chaves e escolha final | Fluxo implementado. |
| Prática de descrição, contexto e reformulação | O jogo oferece essa oportunidade; a contribuição educativa depende da avaliação. |
| Avaliação com participantes | Ainda pendente. Os números provisórios não são resultados reais. |

**Parecer:** o núcleo técnico da proposta está presente. A inspeção não autoriza afirmar que todos os objetivos de pesquisa foram concluídos, nem que a aprendizagem foi demonstrada.

Um acerto por reconhecimento de cor e forma evidencia o funcionamento da regra. Isoladamente, não demonstra melhora da interpretação da LLM ou aquisição de conhecimento sobre engenharia de prompt. O PDF já reconhece essa distinção em parte da fundamentação; preservá-la na apresentação dos resultados e nas conclusões.

A máquina de estados é um mecanismo interno da implementação. O jogo atual não demonstra, por si só, ensinar FSMs ou Gramáticas Livres de Contexto ao participante.

## 8. Pontos concretos para revisar no PDF/LaTeX

1. **Seção 3.3, página 28:** identificar/remover os resultados fictícios e manter coerência com a coleta pendente.
2. **Páginas 37 e 40:** existem marcações “coloque a imagem aqui”. Substituir pelas imagens e referências adequadas.
3. **Apêndices D a J:** confrontar os trechos com a versão atual. Mudaram persistência, chat, filtros, dicas, instrumentação e prompt. O apêndice de movimentação também mostra um trecho anterior; se for mantido como simplificação, identificá-lo como tal.
4. **Seções 2.2, 2.7, metodologia e descrição do puzzle 2:** substituir a explicação dos quatro níveis globais pelo controle contextual atual.
5. **Histórico do chat:** atualizar o texto que descreve apenas persistência visual por variável estática e reinício somente ao fechar a aplicação.
6. **Questionário, Apêndice B:** a apresentação menciona Gramáticas Livres de Contexto, e uma pergunta une engenharia de prompt e máquinas de estados. Alinhar os itens ao objetivo educativo efetivamente avaliado. Não atribuir ao questionário a validação de outro instrumento apenas porque ele foi citado como referência teórica.
7. **Imagens do jogo:** conferir se mostram a versão utilizada na coleta, incluindo o layout de apresentação corrigido em 03/11/2026.
8. **Conclusões:** distinguir implementação concluída, testes técnicos executados, coleta ainda planejada e resultados reais posteriormente obtidos.

## 9. Medições: cuidado com o que está sendo medido

O PDF registra sete interações antigas, com caracteres e tempos de resposta. Esses registros podem ser apresentados como ensaios daquela configuração, desde que tenham origem verificável. Não inventar novas medições nem atribuí-los automaticamente ao código atual.

No código atual, em `scripts/monitor_scene.gd`:

- `start_time` é definido antes da espera pela prontidão do modelo ou pela geração anterior;
- a restauração do contexto também ocorre antes do envio da pergunta;
- a contagem termina ao receber a resposta completa;
- o efeito visual de digitação é posterior.

Assim, o tempo registrado pode incluir espera, carregamento e preparação do contexto. Não descrevê-lo indiscriminadamente como tempo puro de inferência, nem como o tempo completo até o fim da animação visível ao jogador.

Para novos ensaios, é útil distinguir primeira interação/carregamento de interações com o modelo já pronto, registrar a versão e o equipamento e repetir as entradas. Uma comparação entre versões precisa considerar também a mudança do prompt e do contexto.

## 10. Evidências e limites dos testes

- Existe uma suíte em `tests/checkup.gd`, com **78 verificações aprovadas na revisão anterior**. O relatório está em `docs/checkup-2026-10-30.md`.
- A suíte cobre casos dos puzzles, chaves, porta, bloqueios de terminais, reinício, interações e verificações de recursos/colisões. São verificações técnicas, não 78 participantes ou 78 avaliações de aprendizagem.
- Na inspeção de alinhamento de 03/11/2026, foram validados **41 scripts de gameplay/Player**, sem erros de compilação encontrados.
- Foram examinadas referências de recursos em **81 arquivos** das pastas de scripts, cenas, diálogos e recursos; não foram encontrados arquivos ausentes nas referências verificadas.
- Essa inspeção de alinhamento foi de leitura e validação estática; não foi uma nova partida completa ou uma nova coleta com usuários.
- A revisão anterior incluiu testes reais da LLM e dos fluxos do jogo. Ainda assim, o modelo pode variar, esquecer detalhes ou produzir respostas inadequadas. Os filtros são heurísticos, não garantias de segurança ou coerência absoluta.
- Testes na máquina de desenvolvimento não comprovam funcionamento do executável exportado em outros equipamentos.

Para a monografia, aproveitar os testes técnicos como evidência documentada: caso de teste, entrada, saída esperada, saída observada, resultado e versão. Separar essas evidências das respostas do questionário e dos ensaios de desempenho da LLM.

## 11. Recomendações discutidas, ainda não implementadas

Foi sugerida uma breve reflexão educativa ao final do jogo, relacionando a experiência a fornecer contexto, formular uma solicitação clara e verificar a resposta. **Essa sugestão não foi implementada e não deve ser descrita como funcionalidade existente.**

A prioridade recomendada foi congelar funcionalidades, alinhar texto e apêndices, testar a versão exportada em outro computador e realizar a avaliação com participantes. Não foi considerada necessária a criação de novos puzzles para demonstrar o núcleo técnico atual.

## 12. Orientações para continuidade no outro chat

- Usar este documento como contexto, conferindo os arquivos antes de editar ou citar trechos de código.
- Preservar a distinção entre fato observado, resultado de teste, planejamento e sugestão.
- Não inventar resultados, participantes, referências ou funcionalidades.
- Não modificar o jogo para fazê-lo coincidir com uma descrição antiga da monografia sem discutir isso com o autor.
- O usuário prefere aprovar alterações. Este arquivo não constitui autorização ampla para alterar o jogo ou reescrever toda a monografia.
- A tarefa que originou este documento foi apenas criar uma passagem de contexto para o chat da monografia. Nenhuma correção no PDF ou nos fontes LaTeX foi executada nesta tarefa.
