# Cursor Alignment — Factorio 2.1

Faixas horizontal e vertical de um tile de largura, com preenchimento translúcido, ajudam a alinhar esteiras e construções.

## Instalação no Windows

1. Copie `cursor-alignment_0.4.1.zip` para `%APPDATA%\Factorio\mods` (sem extrair).
2. Reinicie o Factorio e confirme que **Cursor Alignment** está habilitado em **Mods**.
3. Abra seu mapa e pegue uma esteira, construção ou blueprint, ou use Ctrl+C / Ctrl+X / Ctrl+V.

Não instale simultaneamente a pasta extraída e o ZIP. Requer Factorio 2.1; não requer Space Age.

## Uso

- As guias aparecem automaticamente com itens de construção, pisos, ghosts, blueprints, livros e ferramentas de seleção.
- Hover com a mão vazia não ativa as faixas automaticamente. Pressione **Ctrl+Shift+S** sobre uma entidade para alternar o destaque dela; ao sair da entidade, o destaque é desativado. O atalho é remapeável nos controles.
- **Ctrl+Shift+H** liga/desliga as guias. O atalho pode ser alterado nos controles.
- Abra o painel pelo botão no topo da tela ou **Ctrl+Shift+O**. Ajustes são salvos por jogador e aplicados imediatamente.
- Em **Configurações → Configurações de mods → Por jogador**, ajuste cor/alpha, alcance e intensidade do preenchimento, ou habilite a exibição permanente. A largura é sempre um tile.
- Cada jogador vê suas próprias guias. As preferências são individuais.

## Comportamento e limites

Ao construir entidades comuns, as faixas seguem o encaixe da prévia do jogo. Para entidades de tamanho par, aplica-se meio tile de deslocamento para cobrir um tile inteiro em vez de ficar entre dois. Ao ativar o destaque de uma entidade com Ctrl+Shift+S, a referência é o tile da posição do mouse recebida no evento do atalho.

Ao copiar/colar, usar blueprints, pintar pisos ou colocar entidades fora da grade/com direções diagonais, as faixas seguem o mouse livremente: **nesses casos não há encaixe automático na grade**. A API de renderização consegue seguir o cursor, mas não fornece suas coordenadas continuamente ao script para arredondar ao tile. Com uma ferramenta na mão, **Ctrl+Shift+S** fixa as guias no tile do cursor. Pressione novamente para soltar. A referência fica parada e é liberada ao trocar a ferramenta ou superfície; isso não é snap contínuo.

A intensidade padrão multiplica o alpha da cor por 25% (com a cor padrão resulta em aproximadamente 16% de opacidade por faixa). A interseção fica um pouco mais intensa. A mistura aditiva preserva mais brilho do fundo. As guias não alteram a colocação das construções.

O painel oferece modos contextual, manual e sempre visível. O modo manual é uma alternância pelo atalho; **segurar Shift não é suportado**, pois a API não informa o estado da tecla nem sua liberação. A opção "Somente guias encaixadas" oculta faixas sem snap. Idiomas: inglês, português brasileiro, espanhol, francês, alemão, italiano, russo, chinês simplificado, japonês e coreano.

O alcance padrão é de 256 tiles em cada direção (ajustável até 2048). As guias são desenhadas no mundo, acima das entidades; o mapa estratégico não é o alvo deste mod. O movimento é acompanhado pelo renderer do jogo. A verificação do item/superfície ocorre também a cada 6 ticks, sem recriar linhas enquanto nada muda.

## Fontes consultadas

- Alternativa de grade: https://mods.factorio.com/mod/SchallChunkAlignment
- API usada: https://lua-api.factorio.com/latest/concepts/ScriptRenderTargetTable.html
- Renderização: https://lua-api.factorio.com/latest/classes/LuaRendering.html

O código-fonte Lua está incluído no ZIP.

## Validação desta versão

Testes headless verificam carregamento, inventários reais, seleção/desseleção, alvos `cursor` e `build-cursor`, largura de um tile, compensação de tamanho par, coordenadas negativas, limpeza e mudança de superfície. O teste de comportamento usa um jogador simulado. Um teste adicional com cliente gráfico valida os componentes reais do painel e as gravações de configuração. O fluxo real de Ctrl+C/Ctrl+V, a rotação/espelhamento visual e o multiplayer ainda precisam de teste numa partida com interface gráfica.
