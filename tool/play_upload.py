#!/usr/bin/env python3
"""Sobe o AAB do zywny no Google Play pela Play Developer API.

O AAB (Android App Bundle) é o que o Play Console pede: o Google gera os APKs
por aparelho a partir dele. Este script faz o mesmo trabalho que o console,
pela API `androidpublisher`:

  1. abre uma edição  (edits.insert)
  2. sobe o .aab      (edits.bundles.upload, upload resumível)
  3. joga na faixa    (edits.tracks.update)
  4. aplica           (edits.commit)

A identidade é uma service account do Google Cloud, com a JSON da chave em
`keys/` (fora do git). O convite dela no Play Console é em Usuários e
permissões → Convidar novos usuários, com a permissão "Liberar apps para as
faixas de teste" no app.

  tool/play_upload.py --check                 # só testa o acesso (não sobe nada)
  tool/play_upload.py                         # sobe o AAB padrão na faixa internal
  tool/play_upload.py --aab X.aab --track alpha
  tool/play_upload.py --list                  # o que já está publicado

A faixa "internal" não passa por revisão e serve para conferir o build.
Produção exige o teste fechado (12 testadores, 14 dias) e a ficha da loja
completa — e a API não substitui os questionários do console.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

PROJ = Path(__file__).resolve().parent.parent
KEYS = PROJ / "keys"
AAB_PADRAO = PROJ / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"

PACKAGE = "br.com.kanada.zywny.musicas"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
TOKEN_URL = "https://oauth2.googleapis.com/token"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3"

FAIXAS = ("internal", "alpha", "beta", "production")


class Falha(Exception):
    """Erro com a mensagem que a API devolveu (traduzida quando dá)."""


# --- HTTP -------------------------------------------------------------------


def _request(req: urllib.request.Request) -> tuple[int, bytes, dict]:
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, r.read(), dict(r.headers)
    except urllib.error.HTTPError as e:
        return e.code, e.read(), dict(e.headers)


def _request_com_retry(req: urllib.request.Request, tentativas: int = 4):
    """Refaz a requisição quando a conexão cai (o upload em blocos sofre com isso)."""
    ultimo = None
    for tentativa in range(tentativas):
        try:
            return _request(req)
        except urllib.error.URLError as e:
            ultimo = e
            if tentativa < tentativas - 1:
                time.sleep(2 * (tentativa + 1))
    raise Falha(f"a conexão caiu e não voltou: {ultimo}")


def _erro(status: int, corpo: bytes, cabecalhos: dict) -> Falha:
    """Traduz a resposta da API numa mensagem que dá para actedir."""
    try:
        erro = json.loads(corpo)["error"]
        msg = erro.get("message", corpo.decode(errors="replace"))
        status = erro.get("status", status)
    except Exception:
        msg = corpo.decode(errors="replace")[:400]

    if status == 401:
        msg += (
            "\n  401 = a credencial está errada: a chave JSON não bate com a API "
            "ativada, ou o escopo não é androidpublisher. O convite no console "
            "não entra nesta conta."
        )
    elif status == 403:
        msg += (
            "\n  403 = a service account não tem permissão neste app. Confira o "
            "convite em Usuários e permissões → Convidar novos usuários, com a "
            "permissão 'Liberar apps para as faixas de teste'. Se a permissão foi "
            "concedida agora, ela pode levar horas para valer."
        )
    elif status == 404:
        msg += (
            "\n  404 = o app não existe nesta conta de desenvolvedor, ou o nome do "
            "pacote está errado."
        )
    return Falha(f"HTTP {status} ({status_code(status)}): {msg}")


def status_code(status: int) -> str:
    return {
        400: "requisição inválida",
        401: "não autenticado",
        403: "sem permissão",
        404: "não encontrado",
        409: "conflito",
        429: "limite de requisições",
        500: "erro do Google",
    }.get(status, "erro")


# --- credencial -------------------------------------------------------------


def achar_chave() -> Path:
    """A JSON da service account em keys/ (a única que tem 'client_email')."""
    achados = [
        p
        for p in sorted(KEYS.glob("*.json"))
        if "client_email" in json.loads(p.read_text())
    ]
    if not achados:
        raise Falha(
            f"nenhuma service account em {KEYS}/ — baixe a chave JSON no Google "
            "Cloud (IAM e Administração → Contas de serviço → Chaves) e ponha "
            "aqui. O nome do arquivo não importa."
        )
    if len(achados) > 1:
        raise Falha(
            "mais de uma service account em keys/ — escolha uma com --chave: "
            + ", ".join(p.name for p in achados)
        )
    return achados[0]


def token(cred: dict) -> str:
    """Troca o JWT assinado pela service account por um token de acesso."""
    agora = int(time.time())
    cabecalho = {"alg": "RS256", "typ": "JWT"}
    corpo = {
        "iss": cred["client_email"],
        "scope": SCOPE,
        "aud": TOKEN_URL,
        "iat": agora,
        "exp": agora + 3600,
    }

    def b64(d: bytes) -> str:
        import base64

        return base64.urlsafe_b64encode(d).rstrip(b"=").decode()

    entrada = (
        b64(json.dumps(cabecalho).encode()) + "." + b64(json.dumps(corpo).encode())
    ).encode()
    chave = serialization.load_pem_private_key(cred["private_key"].encode(), password=None)
    assinatura = chave.sign(entrada, padding.PKCS1v15(), hashes.SHA256())
    jwt = (entrada + b"." + b64(assinatura).encode()).decode()

    dados = urllib.parse.urlencode(
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt,
        }
    ).encode()
    req = urllib.request.Request(TOKEN_URL, data=dados, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    st, corpo_resp, _ = _request(req)
    if st != 200:
        raise _erro(st, corpo_resp, {})
    return json.loads(corpo_resp)["access_token"]


# --- API --------------------------------------------------------------------


class Play:
    def __init__(self, token_acesso: str):
        self.token = token_acesso

    def _get(self, caminho: str) -> dict:
        req = urllib.request.Request(f"{API}{caminho}")
        req.add_header("Authorization", f"Bearer {self.token}")
        st, corpo, _ = _request(req)
        if st != 200:
            raise _erro(st, corpo, {})
        return json.loads(corpo)

    def _post(self, caminho: str, dados: dict) -> dict:
        req = urllib.request.Request(
            f"{API}{caminho}", data=json.dumps(dados).encode(), method="POST"
        )
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Bearer {self.token}")
        st, corpo, _ = _request(req)
        if st != 200:
            raise _erro(st, corpo, {})
        return json.loads(corpo)

    def _put(self, caminho: str, dados: dict) -> dict:
        req = urllib.request.Request(
            f"{API}{caminho}", data=json.dumps(dados).encode(), method="PUT"
        )
        req.add_header("Content-Type", "application/json")
        req.add_header("Authorization", f"Bearer {self.token}")
        st, corpo, _ = _request(req)
        if st != 200:
            raise _erro(st, corpo, {})
        return json.loads(corpo)

    # -- operações --

    def abrir_edicao(self) -> str:
        return self._post(f"/applications/{PACKAGE}/edits", {})["id"]

    def faixas(self, edit_id: str) -> list[dict]:
        return self._get(f"/applications/{PACKAGE}/edits/{edit_id}/tracks").get("tracks", [])

    def bundles(self, edit_id: str) -> list[dict]:
        return self._get(f"/applications/{PACKAGE}/edits/{edit_id}/bundles").get("bundles", [])

    def subir_bundle(self, edit_id: str, aab: Path, bloco: int = 8 * 1024 * 1024) -> dict:
        """Sobe o .aab com upload resumível, em blocos.

        O servidor pede blocos (X-Goog-Upload-Chunk-Granularity); mandar o
        arquivo inteiro num PUT só derruba a conexão. O último bloco leva o
        comando "upload, finalize" e a resposta é o bundle.
        """
        tamanho = aab.stat().st_size
        url = (
            f"https://androidpublisher.googleapis.com/resumable/upload"
            f"/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}/bundles"
            f"?uploadType=resumable"
        )

        # 1) abre a sessão de upload; a resposta traz a URL de destino
        req = urllib.request.Request(url, data=b"", method="POST")
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("X-Goog-Upload-Protocol", "resumable")
        req.add_header("X-Goog-Upload-Command", "start")
        req.add_header("X-Goog-Upload-Header-Content-Length", str(tamanho))
        req.add_header("X-Goog-Upload-Header-Content-Type", "application/octet-stream")
        st, corpo, cabecalhos = _request(req)
        if st != 200:
            raise _erro(st, corpo, cabecalhos)
        destino = (
            cabecalhos.get("X-Goog-Upload-URL")
            or cabecalhos.get("Location")
            or cabecalhos.get("location")
        )
        if not destino:
            raise Falha("a API não devolveu a URL de upload (X-Goog-Upload-URL)")

        # 2) manda o arquivo em blocos
        enviado = 0
        with aab.open("rb") as f:
            while enviado < tamanho:
                pedaco = f.read(bloco)
                if not pedaco:
                    break
                fim = enviado + len(pedaco) - 1
                ultimo = fim >= tamanho - 1

                req = urllib.request.Request(destino, data=pedaco, method="PUT")
                req.add_header("Content-Length", str(len(pedaco)))
                req.add_header("Content-Range", f"bytes {enviado}-{fim}/{tamanho}")
                req.add_header("Content-Type", "application/octet-stream")
                req.add_header("X-Goog-Upload-Command", "upload, finalize" if ultimo else "upload")
                req.add_header("X-Goog-Upload-Offset", str(enviado))

                st, corpo, _ = _request_com_retry(req)
                if st != 200:
                    raise _erro(st, corpo, {})
                enviado = fim + 1
                if corpo.strip():
                    # o último bloco volta com o bundle; os outros, vazios
                    return json.loads(corpo)
                print(f"  {enviado / 1_000_000:.1f} / {tamanho / 1_000_000:.1f} MB", end="\r")

        raise Falha("o upload terminou sem a resposta do bundle")

    def jogar_na_faixa(self, edit_id: str, faixa: str, version_codes: list[str], status: str) -> dict:
        # O corpo é a faixa com a lista de releases — não o release solto, que
        # é o que o documento de descoberta da API promete.
        return self._put(
            f"/applications/{PACKAGE}/edits/{edit_id}/tracks/{faixa}",
            {"releases": [{"versionCodes": version_codes, "status": status}]},
        )

    def aplicar(self, edit_id: str) -> dict:
        return self._post(f"/applications/{PACKAGE}/edits/{edit_id}:commit", {})


# --- o que o script faz ------------------------------------------------------


def conferir(play: Play) -> int:
    """Testa o acesso sem subir nada (a edição expira sozinha)."""
    edit_id = play.abrir_edicao()
    print(f"edição aberta: {edit_id}")
    print("faixas:", ", ".join(t["track"] for t in play.faixas(edit_id)))
    print("bundles já no app:", len(play.bundles(edit_id)))
    print("\nacesso OK — a service account conversa com o app", PACKAGE)
    return 0


def subir(play: Play, aab: Path, faixa: str, status: str, notas: str | None) -> int:
    if not aab.exists():
        raise Falha(
            f"{aab} não existe — rode antes: just build-appbundle"
        )

    print(f"abrindo edição…")
    edit_id = play.abrir_edicao()
    print(f"  editId: {edit_id}")

    print(f"subindo {aab.name} ({aab.stat().st_size / 1_000_000:.1f} MB)…")
    bundle = play.subir_bundle(edit_id, aab)
    version_code = str(bundle.get("versionCode"))
    print(f"  versionCode: {version_code}  sha1: {bundle.get('sha1', '?')[:16]}…")

    print(f"jogando na faixa '{faixa}' (status={status})…")
    release = {
        "versionCodes": [version_code],
        "status": status,
    }
    if notas:
        release["releaseNotes"] = [{"language": "pt-BR", "text": notas}]
    play.jogar_na_faixa(edit_id, faixa, [version_code], status)

    print("aplicando a edição…")
    play.aplicar(edit_id)
    print(f"\npronto: versão {version_code} na faixa '{faixa}'")
    if status == "draft":
        print("ficou em rascunho: abra o Play Console e clique em 'Publicar'.")
    return 0


def listar(play: Play) -> int:
    edit_id = play.abrir_edicao()
    for t in play.faixas(edit_id):
        nome = t["track"]
        releases = t.get("releases", [])
        if not releases:
            print(f"{nome:12} (vazio)")
            continue
        for r in releases:
            codigos = ", ".join(r.get("versionCodes", []))
            print(f"{nome:12} versão {codigos}  status={r.get('status')}")
    return 0


def aplicar_edicao(play: Play, edit_id: str) -> int:
    """Aplica uma edição que já está aberta (bundle já subido)."""
    print(f"aplicando a edição {edit_id}…")
    play.aplicar(edit_id)
    print("pronto — a faixa já está no console")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--aab", type=Path, default=AAB_PADRAO, help="o .aab a subir")
    ap.add_argument("--track", default="internal", choices=FAIXAS, help="faixa de destino")
    ap.add_argument(
        "--status",
        default="completed",
        choices=("draft", "completed", "inProgress", "halted"),
        help="completed publica na faixa; draft deixa para conferir no console",
    )
    ap.add_argument("--notas", help="notas de versão (pt-BR)")
    ap.add_argument("--chave", type=Path, help="caminho da JSON da service account")
    ap.add_argument("--check", action="store_true", help="só testa o acesso")
    ap.add_argument("--list", action="store_true", help="mostra o que está publicado")
    ap.add_argument(
        "--aplicar", metavar="EDIT_ID", help="aplica uma edição já aberta (bundle já subido)"
    )
    args = ap.parse_args()

    try:
        caminho = args.chave or achar_chave()
        cred = json.loads(caminho.read_text())
        print(f"service account: {cred['client_email']}")
        print(f"pacote:          {PACKAGE}\n")

        play = Play(token(cred))

        if args.check:
            return conferir(play)
        if args.list:
            return listar(play)
        if args.aplicar:
            return aplicar_edicao(play, args.aplicar)
        return subir(play, args.aab, args.track, args.status, args.notas)
    except Falha as e:
        print(f"\nFALHOU: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
