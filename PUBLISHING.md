# Publicação no Factorio Mod Portal

O GitHub compartilha o código. Para o mod aparecer na busca dentro do Factorio, publique também no [Mod Portal](https://mods.factorio.com/).

## Conta

Entre com uma conta Factorio.com que tenha uma cópia comprada do jogo. Se a compra foi pela Steam, vincule sua conta Steam no [perfil do Factorio](https://www.factorio.com/profile). Consulte os [termos oficiais](https://www.factorio.com/terms-of-service).

## Antes do envio

- Rode `make test` e confira o painel numa partida com interface gráfica, incluindo rotação, blueprints e os idiomas desejados. Testes headless passaram, mas não validam o layout visual nem multiplayer real.
- Use o ZIP gerado em `dist/cursor-alignment_0.4.1.zip`, sem extrair. Ele contém a pasta `cursor-alignment_0.3.0/`, `info.json`, código, traduções, licença, changelog e `thumbnail.png` de 144 × 144.
- O nome técnico é `cursor-alignment`; o portal exige um nome ainda disponível. Se já estiver ocupado, altere o campo `name` e todas as referências relacionadas antes de publicar.
- Prepare uma ou duas capturas das faixas e do painel para a galeria. Elas ajudam as pessoas a entender o comportamento.

## Envio manual

1. No Mod Portal, abra **Submit mod**.
2. Envie o ZIP.
3. Use o título **Cursor Alignment**, a categoria **Utilities** e a licença **MIT**.
4. Adicione `https://github.com/gabrsar/factorio-cursor-alignment` como repositório do código.
5. Use uma descrição baseada no README e informe os controles, Factorio 2.1 e as limitações atuais.
6. Publique e confira a página e a instalação pelo gerenciador de mods do jogo.

Não anuncie modos de Shift segurado ou snap contínuo ao copiar/selecionar: essas funções ainda não foram implementadas. A seleção por atalho encaixa a posição recebida naquele evento.

Para atualizações, aumente a versão em `src/info.json`, atualize `src/changelog.txt`, teste e envie um novo ZIP.

## Automação opcional

A [API de publicação](https://wiki.factorio.com/Mod_publish_API) aceita uma chave com a permissão **ModPortal: Publish Mods**, criada no perfil. Guarde a chave em variável de ambiente ou secret do GitHub; nunca no código. Para publicar pelo site, você não precisa criar essa chave.

Fontes: [estrutura do mod](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html), [API de publicação](https://wiki.factorio.com/Mod_publish_API), [termos e vínculo com Steam](https://www.factorio.com/terms-of-service).
