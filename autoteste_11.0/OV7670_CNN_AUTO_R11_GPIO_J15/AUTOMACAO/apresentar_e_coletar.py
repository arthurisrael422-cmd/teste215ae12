#!/usr/bin/env python3
"""Apresenta dígitos à câmera e coleta várias classificações por imagem.

Fluxo de cada imagem:
    exibir -> aguardar estabilização -> classificar N vezes -> próxima imagem

Dependências:
    python -m pip install pyserial pillow
"""

from __future__ import annotations

import argparse
import csv
import random
import re
import time
from pathlib import Path
import tkinter as tk

import serial
from PIL import Image, ImageTk


EXTENSOES = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}


def chave_natural(caminho: Path):
    return [
        int(parte) if parte.isdigit() else parte.lower()
        for parte in re.split(r"(\d+)", caminho.name)
    ]


def carregar_imagens(raiz: Path, por_classe: int):
    """Retorna (classe, caminho) em ordem: classes 0..9."""
    raiz = raiz.resolve()
    if not raiz.is_dir():
        raise FileNotFoundError(f"Pasta não encontrada: {raiz}")

    itens = []
    for classe in range(10):
        pasta = raiz / str(classe)
        if not pasta.is_dir():
            raise FileNotFoundError(f"Pasta da classe ausente: {pasta}")

        imagens = sorted(
            (
                arquivo
                for arquivo in pasta.iterdir()
                if arquivo.is_file()
                and arquivo.suffix.lower() in EXTENSOES
            ),
            key=chave_natural,
        )

        if len(imagens) < por_classe:
            raise ValueError(
                f"Classe {classe}: existem {len(imagens)} imagens, "
                f"mas foram solicitadas {por_classe}."
            )

        itens.extend((classe, imagem) for imagem in imagens[:por_classe])

    return itens


def carregar_imagem_fixa(imagem: Path, classe: int):
    imagem = imagem.resolve()
    if not imagem.is_file():
        raise FileNotFoundError(f"Imagem não encontrada: {imagem}")
    if imagem.suffix.lower() not in EXTENSOES:
        raise ValueError(f"Formato não suportado: {imagem.suffix}")
    return [(classe, imagem)]


class Tela:
    def __init__(self, tamanho: int):
        self.janela = tk.Tk()
        self.janela.configure(bg="black")
        self.janela.attributes("-fullscreen", True)
        self.janela.config(cursor="none")

        self.iniciar = False
        self.cancelar = False
        self.janela.bind("<space>", self._iniciar)
        self.janela.bind("<Escape>", self._cancelar)
        self.janela.protocol("WM_DELETE_WINDOW", self._cancelar)

        self.painel = tk.Label(self.janela, bg="black", borderwidth=0)
        self.painel.pack(expand=True, fill="both")
        self.tamanho = tamanho
        self.foto = None
        self.janela.update()

    def _iniciar(self, _evento=None):
        self.iniciar = True

    def _cancelar(self, _evento=None):
        self.cancelar = True

    def atualizar(self):
        self.janela.update()
        if self.cancelar:
            raise KeyboardInterrupt

    def exibir(self, caminho: Path):
        with Image.open(caminho) as original:
            digito = original.convert("L").resize(
                (self.tamanho, self.tamanho),
                Image.Resampling.NEAREST,
            ).convert("RGB")

        largura = self.janela.winfo_screenwidth()
        altura = self.janela.winfo_screenheight()
        quadro = Image.new("RGB", (largura, altura), "black")
        quadro.paste(
            digito,
            ((largura - self.tamanho) // 2, (altura - self.tamanho) // 2),
        )

        self.foto = ImageTk.PhotoImage(quadro)
        self.painel.configure(image=self.foto)
        self.atualizar()

    def aguardar_confirmacao(self):
        print("\nMODO DE ENQUADRAMENTO")
        print("A primeira imagem está parada e ainda não foi classificada.")
        print("Ajuste a câmera e pressione ESPAÇO para iniciar.")
        print("Pressione ESC para cancelar.")

        while not self.iniciar:
            self.atualizar()
            time.sleep(0.02)

        for segundos in (3, 2, 1):
            print(f"Iniciando em {segundos}...")
            self.atualizar()
            time.sleep(1.0)

    def esperar(self, segundos: float):
        """Espera sem congelar os eventos da janela."""
        fim = time.monotonic() + segundos
        while time.monotonic() < fim:
            self.atualizar()
            time.sleep(min(0.02, max(0.0, fim - time.monotonic())))

    def fechar(self):
        try:
            if self.janela.winfo_exists():
                self.janela.destroy()
        except tk.TclError:
            pass


def aguardar_esp32(esp32: serial.Serial, timeout: float = 10.0):
    limite = time.monotonic() + timeout
    proximo_ping = 0.0

    while time.monotonic() < limite:
        agora = time.monotonic()
        if agora >= proximo_ping:
            esp32.write(b"P\n")
            esp32.flush()
            proximo_ping = agora + 0.5

        resposta = esp32.readline().decode(errors="ignore").strip()
        if resposta == "READY":
            print("ESP32: READY")
            return
        if resposta:
            print("ESP32:", resposta)

    raise TimeoutError("O ESP32 não respondeu READY.")


def classificar(esp32: serial.Serial, timeout: float = 7.0):
    esp32.reset_input_buffer()
    esp32.write(b"C\n")
    esp32.flush()

    limite = time.monotonic() + timeout
    while time.monotonic() < limite:
        resposta = esp32.readline().decode(errors="ignore").strip()
        if not resposta:
            continue

        if resposta.startswith("R,"):
            previsao = int(resposta.split(",", 1)[1])
            if 0 <= previsao <= 9:
                return previsao
            raise ValueError(f"Previsão inválida: {previsao}")

        if resposta.startswith("E,"):
            raise RuntimeError(f"Erro do ESP32: {resposta}")

        print("Mensagem ignorada:", resposta)

    raise TimeoutError("A FPGA não devolveu a classificação.")


def criar_parser():
    parser = argparse.ArgumentParser(
        description="Coleta várias classificações antes de trocar a imagem."
    )
    parser.add_argument(
        "pasta",
        type=Path,
        nargs="?",
        help="Pasta com as subpastas 0, 1, ..., 9",
    )
    parser.add_argument("--porta", required=True, help="Exemplo: COM4")
    parser.add_argument("--por-classe", type=int, default=10)
    parser.add_argument(
        "--repeticoes",
        type=int,
        default=5,
        help="Classificações por imagem antes de trocar (padrão: 5)",
    )
    parser.add_argument(
        "--estabilizacao",
        type=float,
        default=3.0,
        help="Espera após exibir uma nova imagem (padrão: 3 s)",
    )
    parser.add_argument(
        "--intervalo",
        type=float,
        default=0.5,
        help="Intervalo entre repetições da mesma imagem (padrão: 0,5 s)",
    )
    parser.add_argument("--tamanho", type=int, default=300)
    parser.add_argument(
        "--embaralhar",
        action="store_true",
        help="Apresenta as imagens em ordem pseudoaleatória",
    )
    parser.add_argument(
        "--semente",
        type=int,
        default=42,
        help="Semente do embaralhamento reproduzível (padrão: 42)",
    )
    parser.add_argument(
        "--saida",
        type=Path,
        default=Path("resultados_repetidos.csv"),
    )
    parser.add_argument("--imagem-fixa", type=Path)
    parser.add_argument("--classe-fixa", type=int, choices=range(10))
    return parser


def main():
    parser = criar_parser()
    args = parser.parse_args()

    if args.repeticoes < 1:
        parser.error("--repeticoes deve ser maior que zero.")
    if args.estabilizacao < 0 or args.intervalo < 0:
        parser.error("Os tempos não podem ser negativos.")
    if args.tamanho < 1 or args.por_classe < 1:
        parser.error("--tamanho e --por-classe devem ser maiores que zero.")

    if args.imagem_fixa is not None:
        if args.classe_fixa is None:
            parser.error("Use --classe-fixa junto com --imagem-fixa.")
        if args.pasta is not None:
            parser.error("Não informe a pasta no modo --imagem-fixa.")
        itens = carregar_imagem_fixa(args.imagem_fixa, args.classe_fixa)
    else:
        if args.pasta is None:
            parser.error("Informe a pasta ou use --imagem-fixa.")
        if args.classe_fixa is not None:
            parser.error("--classe-fixa exige --imagem-fixa.")
        itens = carregar_imagens(args.pasta, args.por_classe)

    # A classe permanece associada ao respectivo caminho porque cada elemento
    # da lista é uma tupla (classe, imagem). Uma instância local de Random
    # evita interferir em qualquer outro gerador aleatório do programa.
    if args.embaralhar:
        random.Random(args.semente).shuffle(itens)

    total_imagens = len(itens)
    total_capturas = total_imagens * args.repeticoes
    args.saida = args.saida.resolve()
    args.saida.parent.mkdir(parents=True, exist_ok=True)

    print(f"Imagens diferentes: {total_imagens}")
    print(f"Repetições por imagem: {args.repeticoes}")
    print(f"Total de classificações: {total_capturas}")
    print(f"Estabilização: {args.estabilizacao:.2f} s")
    print(f"Intervalo entre repetições: {args.intervalo:.2f} s")
    if args.embaralhar:
        print(f"Ordem aleatória reproduzível: semente {args.semente}")
    else:
        print("Ordem das imagens: classes 0 até 9")

    tela = Tela(args.tamanho)
    capturas_realizadas = 0

    try:
        with serial.Serial(args.porta, 115200, timeout=0.25) as esp32:
            aguardar_esp32(esp32)
            tela.exibir(itens[0][1])
            tela.aguardar_confirmacao()

            with args.saida.open("w", newline="", encoding="utf-8") as arquivo:
                escritor = csv.writer(arquivo)
                escritor.writerow(
                    [
                        "imagem_indice",
                        "repeticao",
                        "arquivo",
                        "classe_real",
                        "previsao",
                        "correto",
                        "tempo_s",
                    ]
                )

                inicio = time.monotonic()

                for imagem_indice, (classe, imagem) in enumerate(itens):
                    # A imagem é renderizada somente uma vez. Ela permanece
                    # inalterada durante todas as classificações seguintes.
                    tela.exibir(imagem)
                    print(
                        f"\nImagem {imagem_indice + 1}/{total_imagens}: "
                        f"classe={classe} | {imagem.name}"
                    )
                    tela.esperar(args.estabilizacao)

                    for repeticao in range(1, args.repeticoes + 1):
                        if repeticao > 1:
                            tela.esperar(args.intervalo)

                        previsao = classificar(esp32)
                        correto = int(previsao == classe)
                        capturas_realizadas += 1
                        decorrido = time.monotonic() - inicio

                        escritor.writerow(
                            [
                                imagem_indice,
                                repeticao,
                                imagem.name,
                                classe,
                                previsao,
                                correto,
                                f"{decorrido:.3f}",
                            ]
                        )
                        arquivo.flush()

                        estado = "OK" if correto else "ERRO"
                        print(
                            f"  repetição {repeticao}/{args.repeticoes} | "
                            f"real={classe} | previsto={previsao} | {estado} "
                            f"[{capturas_realizadas}/{total_capturas}]"
                        )

    except KeyboardInterrupt:
        print("\nTeste cancelado com segurança.")
        print(f"Classificações salvas: {capturas_realizadas}")
        return
    finally:
        tela.fechar()

    print(f"\nConcluído. Resultados: {args.saida}")


if __name__ == "__main__":
    main()
