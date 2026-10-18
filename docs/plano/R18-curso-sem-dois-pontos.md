# R18 — Arquivos de curso sem `:` no nome

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Cursos instalam e abrem no Windows. Hoje o arquivo de um curso se chama
`course:<id>.zywny`, e o Windows não aceita `:` em nome de arquivo (achado
11 da [revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 11.
- `packages/zywny_library/lib/library_blob_store_native.dart` (inteiro, 49
  linhas).

## Contexto que você precisa

- `CourseStore.blobId(courseId)` devolve `'course:$courseId'`
  (`lib/course/course_store.dart:130`). As bibliotecas usam o id puro.
- `FileLibraryBlobStore._file(id)` monta `'<dir>/$id.zywny'` (L24); `put`
  grava `'<dir>/$id.zywny.tmp'` e renomeia (L41–L43). O diretório é
  `<application support>/bibliotecas` (L19–L21).
- No Windows, `:` só vale logo depois da letra do drive. Em outro lugar o
  nome é recusado ou vira um fluxo alternativo do NTFS (o arquivo `course`
  ganha um fluxo `<id>.zywny`, e o `rename` do `.tmp` falha). Isto não foi
  testado numa máquina Windows: o teste manual depende da VM do D-WIN.
- Ids de curso e de biblioteca seguem `^[a-z0-9-]{1,40}$` (`kIdPattern` em
  `packages/zywny_course_format/lib/vocabulary.dart:93`;
  `_libraryIdPattern` em `packages/zywny_library/lib/library_package.dart:11`).
  Nenhum id válido tem `_`, então `__` não colide com nada.
- Web: `library_blob_store_web.dart` guarda no IndexedDB com a chave como
  veio; `:` não é problema ali. Não mude o `blobId`: as chaves já gravadas
  na Web ficariam órfãs.

## O que fazer

1. No `FileLibraryBlobStore`, uma função privada id → nome de arquivo que
   troca `:` por `__` (`course:iniciacao` → `course__iniciacao.zywny`).
   Use-a em `_file` e no `.tmp` do `put`.
2. Migração: em `contains`, `get` e `delete`, se o arquivo novo não existe
   e o de nome antigo existe, renomeie o antigo para o novo antes de
   seguir. (No Windows o antigo nunca existiu; no Linux e no Android,
   existe para quem instalou cursos antes deste passo.)
3. Testes em `packages/zywny_library/test/` com diretório temporário
   (`FileLibraryBlobStore(directory: …)`): nenhum arquivo gravado tem `:`
   no nome; um arquivo com o nome antigo é achado por `get` e renomeado;
   `delete` apaga o curso gravado com o nome antigo.

## Fora de escopo

Mudar `CourseStore.blobId` ou o store da Web. Qualquer outro caractere:
os ids já são restritos pelo formato.

## Critérios de aceite

1. Nenhum caminho montado pelo `FileLibraryBlobStore` contém `:` depois do
   prefixo do diretório (teste).
2. `just analyze` e `just test` limpos, com os testes novos.
3. Linux: um curso instalado antes deste passo continua aparecendo e
   abrindo depois dele **(manual)**.
4. Windows (VM do D-WIN): instalar o curso de exemplo, fechar, reabrir o
   app e abrir a lição **(manual)**.

## Notas de execução

