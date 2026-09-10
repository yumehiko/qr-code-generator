# CIQRCodeGenerator 実測記録

このディレクトリの二つのスクリプトは、`CIQRCodeGenerator` が生成した
モジュール行列と、同じ行列を Vision で読んだ `CIQRCodeDescriptor` を記録・解析する。

## 再実行

```sh
mkdir -p docs/research/out
xcrun swiftc docs/research/coreimage_qr_probe.swift -framework AppKit -framework CoreImage -framework Vision -o docs/research/out/coreimage_qr_probe
docs/research/out/coreimage_qr_probe > docs/research/out/raw.json
python3 docs/research/analyze_coreimage_qr.py docs/research/out/raw.json > docs/research/out/analysis.json
python3 docs/research/analyze_coreimage_qr.py docs/research/out/raw.json --markdown > docs/research/results.md
git diff --exit-code -- docs/research/results.md
```

Swift は CoreImage の出力をグレースケールの各画素へ描画して `0`/`1` 行列にする。
出力行列は各辺に白い 1 モジュールを含むため、Python はこれを除いて QR symbol を解析する。
Swift は Vision の `CIQRCodeDescriptor` から `symbolVersion`、`maskPattern`、
`errorCorrectionLevel`、`errorCorrectedPayload` も記録する。Python は第一形式情報コピーを
XOR `0x5412` 後に復号し、予約領域を除くジグザグ走査とマスク解除を行う。セグメント解析は
Vision の訂正済み payload を使う。各候補は同 payload・version・ECC・mask で
`CIBarcodeGenerator` に再生成する。

候補ペナルティは、外側の白 1 モジュールを除いた symbol に対するスクリプトの N1--N4 合計である。
Nayuki 列は vendor の固定コミット参照実装の `_get_penalty_score()` をそのまま適用する。ZXing 列は固定 `1011101` と前後 4 白モジュールの片側成立を N3 とする独自実装である。
列 `m0...m7` は mask 0...7 の順である。

## 実測環境

- macOS 15.7.9 (24G830)、arm64
- Apple Swift 6.2 (`swiftlang-6.2.0.19.9`)、target `arm64-apple-macosx15.0`

## 基本入力の結果

すべての行で、形式情報から得た ECC・mask は Vision の `errorCorrectionLevel`・`maskPattern` と一致した。
全候補で、再生成した候補の形式情報の mask は要求した 0...7 と一致した。選択済み行列は、その mask の再生成行列と一致した。
byte セグメントの各 payload は対応する入力文字列の UTF-8 byte 列と一致した。ECI mode はこの 28 件の訂正済み payload には現れなかった。

全 28 行×8候補の Nayuki/ZXing ペナルティ、version、選択 mask は [results.md](results.md) に記録する。このファイルは `analyze_coreimage_qr.py --markdown` の出力である。

## 出典

- [Apple CIQRCodeGenerator archive](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/)
- [Apple CIQRCodeDescriptor.errorCorrectedPayload](https://developer.apple.com/documentation/coreimage/ciqrcodedescriptor/errorcorrectedpayload-swift.property)
- [ISO/IEC 18004:2015 §7.8.3.1 / Table 11](https://nuintun.github.io/qrcode/spec/ISO-IEC-18004-2015.pdf)
- [Nayuki QR Code generator](https://www.nayuki.io/page/qr-code-generator-library), commit `3c6d0b3cefb4e049dc337e82237c9644399716a8`
- [ZXing MaskUtil](https://github.com/zxing/zxing/blob/zxing-3.5.3/core/src/main/java/com/google/zxing/qrcode/encoder/MaskUtil.java), tag `zxing-3.5.3`

最後の入力の M は version 3 であり、訂正済み payload の先頭は byte mode・count 20、続いて numeric mode・count 40 だった。

## ASCII 数字 run の追加実測

M を指定して 120 件を実行した。入力は数字 run 長 1...24 に対し、`https://example.com/` の後、
`a` と `b` の間、`ABC` と `DEF` の間、`https://example.com/` と `?q=a` の間、および
`a` と `b` の間の大文字 run である。Python は各入力について numeric、alphanumeric、byte の全区間分割を
動的計画法で列挙した。Vision payload から読んだセグメントの bit 数と最小値は 120/120 件で一致した。
