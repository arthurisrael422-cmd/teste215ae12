#!/usr/bin/env python3
"""Analisa a RAM HIST100 exportada pelo Quartus In-System Sources and Probes.

Uso:
    python analisar_historico.py historico.mif
    python analisar_historico.py historico.hex --saida minha_analise

Nao requer bibliotecas externas.
"""

from __future__ import annotations

import argparse
import csv
import html
import re
import struct
import zlib
from pathlib import Path

PIXELS_PER_RECORD = 900
RECORDS = 100
ACTUAL_BASE = 90000
PREDICTED_BASE = 90100
HEADER_BASE = 90200
MIN_WORDS = 90208


def _radix(name: str) -> int:
    return {"BIN": 2, "OCT": 8, "DEC": 10, "UNS": 10, "HEX": 16}[name.upper()]


def read_mif(text: str) -> list[int]:
    am = re.search(r"ADDRESS_RADIX\s*=\s*(\w+)", text, re.I)
    dm = re.search(r"DATA_RADIX\s*=\s*(\w+)", text, re.I)
    depth_m = re.search(r"DEPTH\s*=\s*(\d+)", text, re.I)
    if not (am and dm):
        raise ValueError("MIF sem ADDRESS_RADIX ou DATA_RADIX")
    address_radix, data_radix = _radix(am.group(1)), _radix(dm.group(1))
    depth = int(depth_m.group(1)) if depth_m else 90208
    memory = [0] * depth
    body_m = re.search(r"CONTENT\s+BEGIN(.*?)END\s*;", text, re.I | re.S)
    if not body_m:
        raise ValueError("MIF sem bloco CONTENT BEGIN ... END;")
    body = re.sub(r"--.*?$|%.*?%", "", body_m.group(1), flags=re.M | re.S)
    token = r"[0-9A-Fa-f]+"
    for statement in body.split(";"):
        statement = statement.strip()
        if not statement:
            continue
        rng = re.match(rf"\[({token})\.\.({token})\]\s*:\s*({token})", statement)
        one = re.match(rf"({token})\s*:\s*({token})", statement)
        if rng:
            start, end = int(rng.group(1), address_radix), int(rng.group(2), address_radix)
            value = int(rng.group(3), data_radix) & 0xFF
            for address in range(start, min(end + 1, depth)):
                memory[address] = value
        elif one:
            address, value = int(one.group(1), address_radix), int(one.group(2), data_radix)
            if address < depth:
                memory[address] = value & 0xFF
    return memory


def read_intel_hex(text: str) -> list[int]:
    memory: dict[int, int] = {}
    upper = 0
    for line_number, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        if not line.startswith(":"):
            raise ValueError(f"Linha {line_number}: formato Intel HEX invalido")
        raw = bytes.fromhex(line[1:])
        if (sum(raw) & 0xFF) != 0:
            raise ValueError(f"Linha {line_number}: checksum Intel HEX invalido")
        count, address, kind = raw[0], (raw[1] << 8) | raw[2], raw[3]
        data = raw[4:4 + count]
        if kind == 0:
            for offset, value in enumerate(data):
                memory[upper + address + offset] = value
        elif kind == 1:
            break
        elif kind == 4:
            upper = int.from_bytes(data, "big") << 16
    if not memory:
        raise ValueError("Intel HEX nao contem dados")
    result = [0] * (max(memory) + 1)
    for address, value in memory.items():
        result[address] = value
    return result


def read_memory(path: Path) -> list[int]:
    text = path.read_text(encoding="utf-8", errors="replace")
    if re.search(r"CONTENT\s+BEGIN", text, re.I):
        return read_mif(text)
    if next((line for line in text.splitlines() if line.strip()), "").lstrip().startswith(":"):
        return read_intel_hex(text)
    values = [int(x, 16) & 0xFF for x in re.findall(r"(?<![0-9A-Fa-f])[0-9A-Fa-f]{2}(?![0-9A-Fa-f])", text)]
    if not values:
        raise ValueError("Formato nao reconhecido. Exporte preferencialmente como .mif")
    return values


def png_gray(path: Path, pixels: list[int], width: int, height: int, scale: int = 1) -> None:
    rows = []
    for y in range(height):
        row = pixels[y * width:(y + 1) * width]
        expanded = b"".join(bytes([p]) * scale for p in row)
        for _ in range(scale):
            rows.append(b"\x00" + expanded)
    raw = b"".join(rows)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", width * scale, height * scale, 8, 0, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(raw, 9))
    payload += chunk(b"IEND", b"")
    path.write_bytes(payload)


def geometry(pixels: list[int]) -> dict[str, object]:
    active = [(i % 30, i // 30, p) for i, p in enumerate(pixels) if p >= 20]
    total = sum(pixels)
    if not active or total == 0:
        return {"active": 0, "bbox": "vazio", "width": 0, "height": 0,
                "center_x": "", "center_y": "", "mean": round(sum(pixels) / 900, 2)}
    xs, ys = [p[0] for p in active], [p[1] for p in active]
    cx = sum((i % 30) * p for i, p in enumerate(pixels)) / total
    cy = sum((i // 30) * p for i, p in enumerate(pixels)) / total
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    return {"active": len(active), "bbox": f"{x0},{y0}-{x1},{y1}",
            "width": x1 - x0 + 1, "height": y1 - y0 + 1,
            "center_x": round(cx, 2), "center_y": round(cy, 2),
            "mean": round(sum(pixels) / 900, 2)}


def matrix_html(matrix: list[list[int]]) -> str:
    head = "<tr><th>Real \\ Prev.</th>" + "".join(f"<th>{i}</th>" for i in range(10)) + "</tr>"
    rows = []
    for actual, row in enumerate(matrix):
        cells = "".join(f'<td class="{("diag" if actual == pred else "err") if value else ""}">{value}</td>'
                        for pred, value in enumerate(row))
        rows.append(f"<tr><th>{actual}</th>{cells}</tr>")
    return "<table>" + head + "".join(rows) + "</table>"


def main() -> None:
    parser = argparse.ArgumentParser(description="Analisa os 100 registros da RAM HIST100")
    parser.add_argument("arquivo", type=Path, help="arquivo .mif ou .hex exportado pelo Quartus")
    parser.add_argument("--saida", type=Path, default=Path("saida_analise"))
    args = parser.parse_args()
    memory = read_memory(args.arquivo)
    if len(memory) < MIN_WORDS:
        raise SystemExit(f"Arquivo possui {len(memory)} bytes; eram esperados pelo menos {MIN_WORDS}.")

    signature = bytes(memory[HEADER_BASE:HEADER_BASE + 4])
    if signature != b"H100":
        raise SystemExit("Cabecalho H100 ausente. Confirme que programou a revisao HIST100 e executou ao menos uma classificacao.")

    args.saida.mkdir(parents=True, exist_ok=True)
    records = []
    matrix = [[0] * 10 for _ in range(10)]
    correct = 0
    for slot in range(RECORDS):
        actual_byte = memory[ACTUAL_BASE + slot]
        if not (actual_byte & 0x80):
            continue
        actual = actual_byte & 0x0F
        predicted = memory[PREDICTED_BASE + slot] & 0x0F
        pixels = memory[slot * PIXELS_PER_RECORD:(slot + 1) * PIXELS_PER_RECORD]
        stats = geometry(pixels)
        filename = f"registro_{slot:02d}_real_{actual}_prev_{predicted}.png"
        png_gray(args.saida / filename, pixels, 30, 30, scale=10)
        ok = actual == predicted
        correct += int(ok)
        if actual < 10 and predicted < 10:
            matrix[actual][predicted] += 1
        records.append({"registro": slot, "real": actual, "previsto": predicted,
                        "correto": int(ok), "imagem": filename, **stats})

    fields = ["registro", "real", "previsto", "correto", "active", "bbox",
              "width", "height", "center_x", "center_y", "mean", "imagem"]
    with (args.saida / "registros.csv").open("w", newline="", encoding="utf-8-sig") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        writer.writerows(records)
    with (args.saida / "matriz_confusao.csv").open("w", newline="", encoding="utf-8-sig") as output:
        writer = csv.writer(output)
        writer.writerow(["real\\previsto", *range(10)])
        for digit, row in enumerate(matrix):
            writer.writerow([digit, *row])

    accuracy = (100.0 * correct / len(records)) if records else 0.0
    summary = (f"Registros validos: {len(records)}\nAcertos: {correct}\n"
               f"Erros: {len(records) - correct}\nAcuracia: {accuracy:.2f}%\n"
               f"Versao do formato: {memory[HEADER_BASE + 4]}\n"
               f"Contador gravado: {memory[HEADER_BASE + 5]}\n"
               f"Proximo registro: {memory[HEADER_BASE + 6] & 127}\n"
               f"Ultimo registro: {memory[HEADER_BASE + 7] & 127}\n")
    (args.saida / "resumo.txt").write_text(summary, encoding="utf-8")

    cards = "".join(
        f'<article><img src="{html.escape(r["imagem"])}"><p>Registro {r["registro"]:02d}: '
        f'real <b>{r["real"]}</b>, previsto <b>{r["previsto"]}</b> '
        f'— {"acerto" if r["correto"] else "ERRO"}</p></article>' for r in records)
    report = f"""<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<title>Analise HIST100</title><style>
body{{font:16px Arial;max-width:1100px;margin:30px auto;color:#222}}table{{border-collapse:collapse}}
th,td{{border:1px solid #aaa;padding:7px;text-align:center}}td.diag{{background:#b8efc4}}
td.err{{background:#ffc6c6}}.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:14px}}
article{{border:1px solid #bbb;padding:9px}}img{{width:150px;height:150px;image-rendering:pixelated;background:#000}}
</style><h1>Analise dos dados da CNN</h1><pre>{html.escape(summary)}</pre>
<h2>Matriz de confusao</h2>{matrix_html(matrix)}<h2>Entradas 30x30</h2><div class="grid">{cards}</div></html>"""
    (args.saida / "relatorio.html").write_text(report, encoding="utf-8")
    print(summary, end="")
    print(f"Relatorio: {(args.saida / 'relatorio.html').resolve()}")


if __name__ == "__main__":
    main()
