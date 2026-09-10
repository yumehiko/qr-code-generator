#!/usr/bin/env python3
"""Analyze JSON emitted by coreimage_qr_probe.swift using only the standard library."""

import json
import sys


ECL = {0: "M", 1: "L", 2: "H", 3: "Q"}
ALPHANUMERIC = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"


def crop_quiet_border(matrix):
    """CIQRCodeGenerator emits a one-module white border around the symbol."""
    if not matrix or any(len(row) != len(matrix) for row in matrix):
        raise ValueError("matrix is not square")
    if not (all(bit == "0" for bit in matrix[0]) and all(bit == "0" for bit in matrix[-1])
            and all(row[0] == row[-1] == "0" for row in matrix)):
        raise ValueError("expected one-module white border is absent")
    return [row[1:-1] for row in matrix[1:-1]]


def format_bits(matrix):
    """Read the first format-information copy, returning its unmasked 5-bit value."""
    n = len(matrix)
    value = 0
    for i in range(6):
        value |= int(matrix[i][8]) << i
    value |= int(matrix[7][8]) << 6
    value |= int(matrix[8][8]) << 7
    value |= int(matrix[8][7]) << 8
    for i in range(9, 15):
        value |= int(matrix[8][14 - i]) << i
    return (value ^ 0x5412) >> 10


def mask_applies(mask, x, y):
    product = x * y
    return (
        (x + y) % 2 == 0 if mask == 0 else
        y % 2 == 0 if mask == 1 else
        x % 3 == 0 if mask == 2 else
        (x + y) % 3 == 0 if mask == 3 else
        (y // 2 + x // 3) % 2 == 0 if mask == 4 else
        (product % 2 + product % 3) == 0 if mask == 5 else
        (product % 2 + product % 3) % 2 == 0 if mask == 6 else
        ((x + y) % 2 + product % 3) % 2 == 0
    )


def alignment_positions(version):
    # Positions needed by the observed versions 1 through 5.
    return {1: [], 2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30]}[version]


def function_modules(version):
    n = version * 4 + 17
    cells = set()
    def rectangle(x0, y0, x1, y1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                cells.add((x, y))
    rectangle(0, 0, 8, 8)
    rectangle(n - 8, 0, n - 1, 8)
    rectangle(0, n - 8, 8, n - 1)
    for i in range(8, n - 8):
        cells.add((i, 6))
        cells.add((6, i))
    for x in alignment_positions(version):
        for y in alignment_positions(version):
            if (x, y) not in ((6, 6), (6, n - 7), (n - 7, 6)):
                rectangle(x - 2, y - 2, x + 2, y + 2)
    # Both copies of the 15 format bits, plus the fixed dark module.
    for i in range(6):
        cells.add((8, i)); cells.add((n - 1 - i, 8))
    cells.update(((8, 7), (8, 8), (7, 8), (8, n - 8)))
    for i in range(9, 15):
        cells.add((14 - i, 8)); cells.add((8, n - 15 + i))
    return cells


def data_bits(matrix, version, mask):
    """Traverse QR data modules and remove the selected mask."""
    n = len(matrix)
    reserved = function_modules(version)
    bits = []
    right = n - 1
    upward = True
    while right > 0:
        if right == 6:
            right -= 1
        rows = range(n - 1, -1, -1) if upward else range(n)
        for y in rows:
            for x in (right, right - 1):
                if (x, y) not in reserved:
                    bit = int(matrix[y][x])
                    bits.append(bit ^ int(mask_applies(mask, x, y)))
        upward = not upward
        right -= 2
    return bits


def bytes_from_bits(bits):
    return bytes(sum(bits[i + j] << (7 - j) for j in range(8)) for i in range(0, len(bits) - 7, 8))


class BitReader:
    def __init__(self, data):
        self.bits = ''.join(f'{byte:08b}' for byte in data)
        self.index = 0

    def read(self, count):
        if self.index + count > len(self.bits):
            raise ValueError("unexpected end of corrected payload")
        value = int(self.bits[self.index:self.index + count], 2)
        self.index += count
        return value


def parse_segments(data, version):
    reader = BitReader(data)
    segments = []
    while reader.index + 4 <= len(reader.bits):
        mode = reader.read(4)
        if mode == 0:
            break
        if mode == 7:  # ECI assignment number
            first = reader.read(8)
            assignment = first if first < 128 else ((first & 0x3F) << 8 | reader.read(8))
            segments.append({"mode": "ECI", "assignment": assignment})
            continue
        count_bits = {1: 10, 2: 9, 4: 8, 8: 8}.get(mode)
        if count_bits is None:
            segments.append({"mode": f"unknown({mode})"})
            break
        count = reader.read(count_bits)
        if mode == 1:
            width = (count // 3) * 10 + (7 if count % 3 == 2 else 4 if count % 3 else 0)
            value = ''.join(reader.bits[reader.index:reader.index + width])
            reader.index += width
            segments.append({"mode": "numeric", "count": count, "bits": width})
        elif mode == 2:
            width = (count // 2) * 11 + (6 if count % 2 else 0)
            reader.index += width
            segments.append({"mode": "alphanumeric", "count": count, "bits": width})
        elif mode == 4:
            payload = bytes(reader.read(8) for _ in range(count))
            segments.append({"mode": "byte", "count": count, "hex": payload.hex().upper()})
        else:
            reader.index += count * 13
            segments.append({"mode": "kanji", "count": count, "bits": count * 13})
    return segments


def penalty(matrix, n3_style='nayuki'):
    n = len(matrix)
    score = 0
    for lines in (matrix, [''.join(matrix[y][x] for y in range(n)) for x in range(n)]):
        for line in lines:
            run = 1
            for index in range(1, n):
                if line[index] == line[index - 1]: run += 1
                else:
                    if run >= 5: score += run - 2
                    run = 1
            if run >= 5: score += run - 2
            for index in range(n - 6):
                if line[index:index + 7] == '1011101':
                    before = index >= 4 and line[index - 4:index] == '0000'
                    after = index + 11 <= n and line[index + 7:index + 11] == '0000'
                    if n3_style == 'zxing':
                        score += 40 if before or after else 0
                    else:
                        # Nayuki pads each line with four light modules and scores both sides.
                        before = before or index == 0
                        after = after or index + 7 == n
                        score += 40 * (int(before) + int(after))
    for y in range(n - 1):
        for x in range(n - 1):
            if matrix[y][x] == matrix[y][x + 1] == matrix[y + 1][x] == matrix[y + 1][x + 1]: score += 3
    dark = sum(row.count('1') for row in matrix)
    score += abs(dark * 20 - n * n * 10) // (n * n) * 10
    return score


def analyze(record):
    symbol = crop_quiet_border(record['matrix'])
    version = (len(symbol) - 17) // 4
    format_value = format_bits(symbol)
    level, mask = ECL[format_value >> 3], format_value & 7
    unmasked = bytes_from_bits(data_bits(symbol, version, mask))
    payload = bytes.fromhex(record['visionErrorCorrectedPayloadHex'])
    result = {
        'category': record['category'], 'input': record['input'], 'requestedLevel': record['correctionLevel'],
        'version': version, 'formatLevel': level, 'formatMask': mask,
        'visionVersion': record['visionSymbolVersion'], 'visionMask': record['visionMaskPattern'],
        'unmaskedInterleavedPrefixHex': unmasked[:12].hex().upper(),
        'correctedPayloadHex': payload.hex().upper(), 'segments': parse_segments(payload, version),
    }
    if record.get('candidateMatrices') is not None:
        candidates = [crop_quiet_border(candidate) for candidate in record['candidateMatrices']]
        scores = [penalty(candidate, 'nayuki') for candidate in candidates]
        zxing_scores = [penalty(candidate, 'zxing') for candidate in candidates]
        result.update({
            'candidateFormatMasks': [format_bits(candidate) & 7 for candidate in candidates],
            'candidatePenalties': scores, 'selectedPenalty': scores[mask],
            'zxingCandidatePenalties': zxing_scores,
            'minimumPenalty': min(scores),
            'minimumMasks': [i for i, value in enumerate(scores) if value == min(scores)],
            'selectedMatrixEqualsReconstructed': symbol == candidates[mask],
        })
    return result


def segment_bit_size(segments):
    return sum(4 + {'numeric': 10, 'alphanumeric': 9, 'byte': 8}[item['mode']]
               + item.get('bits', item['count'] * 8) for item in segments)


def optimal_ascii_segment_bits(text):
    """Minimum bit count for numeric/alphanumeric/byte partitions in versions 1--9."""
    best = [0] + [10 ** 9] * len(text)
    for end in range(1, len(text) + 1):
        for start in range(end):
            piece = text[start:end]
            count = len(piece)
            options = [(4, 8, count * 8)]
            if piece.isdigit(): options.append((1, 10, count // 3 * 10 + (0, 4, 7)[count % 3]))
            if all(character in ALPHANUMERIC for character in piece):
                options.append((2, 9, count // 2 * 11 + (count % 2) * 6))
            best[end] = min(best[end], *(best[start] + 4 + width + payload for _, width, payload in options))
    return best[-1]


def main():
    records = json.load(open(sys.argv[1], encoding='utf-8'))
    analyses = [analyze(record) for record in records]
    basic = [item for item in analyses if item['category'] == 'basic']
    optimization = [item for item in analyses if item['category'] == 'optimization']
    mismatches = [item for item in optimization
                  if segment_bit_size(item['segments']) != optimal_ascii_segment_bits(item['input'])]
    print(json.dumps({
        'basic': basic,
        'optimizationCheck': {'caseCount': len(optimization), 'mismatchCount': len(mismatches)},
    }, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
