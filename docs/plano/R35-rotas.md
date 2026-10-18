# R35 — Rotas com `go_router`

**Repo:** zywny · **Depende de:** R27, R31 · **Decisão necessária:** sim
(D-REV-ROTAS)

## Objetivo

A navegação passa a ter rotas com nome. Na versão Web cada tela ganha um
endereço, e o voltar do navegador volta de tela em tela (achado 25 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 25.
- `lib/main.dart` (`MyApp`) e `lib/app/library_screen.dart` (`_open`,
  `_openSettings`, `_openCourses`).

## Contexto que você precisa

- 25 `Navigator.push`/`MaterialPageRoute` no `lib/` (`grep -rn
  'Navigator.*push\|MaterialPageRoute' lib`).
- A partitura abre com um `OpenedPiece` montado na hora (bytes da
  partitura, configurações, callbacks): não dá para pôr isso numa URL. Uma
  rota da partitura precisa receber `biblioteca/música` e carregar o resto
  ao abrir, o que hoje `_open` faz antes do `push`.
- A Web publicada fica no GitHub Pages com `--base-href /zywny/`
  (`tool/publish_web.sh`, `just publicar-web`). O GitHub Pages não devolve
  o `index.html` para caminhos desconhecidos: com URL de caminho
  (`usePathUrlStrategy`), recarregar a página numa tela interna dá 404.
  Com URL de `#` (o padrão do Flutter na Web), funciona.
- Abrir `.zywny` pelo sistema (B11) chega por `IncomingPackages`, não por
  URL; as rotas não mudam isso.

## Decisão necessária (D-REV-ROTAS)

Pergunte ao usuário antes de escrever código:

- **(a) `go_router` com URL de `#`.** Rotas para biblioteca, configurações,
  cursos, curso, lição, exercício, níveis da leitura, Sobre e partitura
  (`/musica/:biblioteca/:id`). O voltar do navegador funciona e cada tela
  pode ser aberta por link.
- **(b) Ficar como está.** O app é usado sobretudo no celular, onde a URL
  não aparece; o custo de reorganizar a abertura da partitura não se paga.

Recomendação: **(b) por enquanto**, rever se a versão Web ganhar uso
próprio (link para uma música, aula compartilhada). Se for (a), faça
depois do R27 e do R31, que deixam a biblioteca sem os serviços e sem a
abertura da partitura misturada ao resto.

## O que fazer (só com a)

1. `lib/app/router.dart` com as rotas; `MaterialApp.router` no `MyApp`.
2. A abertura da partitura vira uma tela de carregamento na rota
   `/musica/:biblioteca/:id` (o que `_open` faz antes do `push`).
3. Troque os `Navigator.push` por `context.push`/`go`. Diálogos e
   bottom sheets continuam com `showDialog`/`showModalBottomSheet`.
4. Testes: cada rota abre a sua tela; voltar da partitura volta à
   biblioteca; uma URL de música inexistente mostra a mensagem do R21.

## Fora de escopo

URL de caminho no GitHub Pages (precisaria de um `404.html` que redireciona).

## Critérios de aceite (com a)

1. `grep -rn 'MaterialPageRoute' lib` não acha nada.
2. `just analyze` e `just test` limpos.
3. Web: navegar até uma lição, recarregar a página e cair na mesma lição;
   o voltar do navegador volta tela a tela **(manual)**.
4. Android: o botão voltar do sistema faz o mesmo que antes **(manual)**.

## Notas de execução

