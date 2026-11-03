# Modelo utilizado pelo jogo

O S.A.R.A. Protocol utiliza `gemma-2-2b-it-Q5_K_M.gguf`, baseado no Gemma 2 2B Instruct da Google, em formato GGUF e quantização Q5_K_M. O arquivo local foi incluído sem modificações nesta publicação.

O modelo é armazenado pelo Git LFS. Para obter os arquivos reais ao clonar:

```sh
git lfs install
git clone https://github.com/Lucascapyb/Godot_game_TCC---lastUpdate.git
cd Godot_game_TCC---lastUpdate
git lfs pull
```

A extensão NobodyWho também está incluída em `addons/nobodywho`, com as bibliotecas nativas armazenadas por Git LFS. Símbolos de depuração `.pdb`, backups e o modelo Qwen antigo, que não é usado pelo jogo, permanecem fora do repositório.

O modelo está sujeito aos termos em `LICENSE-Gemma.txt`, ao aviso em `NOTICE` e às restrições de uso da Google: https://ai.google.dev/gemma/prohibited_use_policy. Esses termos se aplicam ao uso e à redistribuição do modelo; a inclusão no projeto não substitui sua licença.

Modelo base: https://huggingface.co/google/gemma-2-2b-it

Termos oficiais: https://ai.google.dev/gemma/terms

O Git LFS possui cotas próprias de armazenamento e downloads. O envio do projeto-fonte não é uma versão executável para participantes: a distribuição para os testes com o público deve usar uma exportação do jogo com seus recursos e dependências.
