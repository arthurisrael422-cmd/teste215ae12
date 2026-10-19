#!/usr/bin/env python3
"""Calcula metricas do CSV produzido pelo teste automatico."""

from pathlib import Path
import argparse

import matplotlib.pyplot as plt
import pandas as pd
from sklearn.metrics import (
    ConfusionMatrixDisplay,
    accuracy_score,
    classification_report,
    confusion_matrix,
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", type=Path, nargs="?",
                        default=Path("resultados_automaticos.csv"))
    args = parser.parse_args()

    dados = pd.read_csv(args.csv)
    obrigatorias = {"classe_real", "previsao"}
    faltantes = obrigatorias - set(dados.columns)
    if faltantes:
        raise ValueError(f"Colunas ausentes: {sorted(faltantes)}")
    if dados.empty:
        raise ValueError("O CSV esta vazio.")

    real = dados["classe_real"].astype(int)
    previsto = dados["previsao"].astype(int)
    if not real.between(0, 9).all() or not previsto.between(0, 9).all():
        raise ValueError("Existem rotulos fora de 0..9.")

    matriz = confusion_matrix(real, previsto, labels=list(range(10)))
    acuracia = accuracy_score(real, previsto)
    relatorio = classification_report(
        real, previsto, labels=list(range(10)), digits=4, zero_division=0
    )

    texto = (
        f"Quantidade de amostras: {len(dados)}\n"
        f"Acuracia: {100 * acuracia:.2f}%\n\n"
        f"Matriz de confusao:\n{matriz}\n\n"
        f"Relatorio por classe:\n{relatorio}"
    )
    print(texto)
    Path("relatorio_automatico.txt").write_text(texto, encoding="utf-8")

    fig, ax = plt.subplots(figsize=(9, 8))
    ConfusionMatrixDisplay(matriz, display_labels=list(range(10))).plot(
        ax=ax, cmap="Blues", values_format="d", colorbar=True
    )
    ax.set_title("Matriz de confusao - CNN FPGA + OV7670")
    ax.set_xlabel("Classe prevista")
    ax.set_ylabel("Classe real")
    fig.tight_layout()
    fig.savefig("matriz_confusao_automatica.png", dpi=300,
                bbox_inches="tight")
    plt.show()


if __name__ == "__main__":
    main()
