# CIQRCodeGenerator 実測記録

このディレクトリの二つのスクリプトは、`CIQRCodeGenerator` が生成した
モジュール行列と、同じ行列を Vision で読んだ `CIQRCodeDescriptor` を記録・解析する。
製品ターゲット、`Package.swift`、外部依存は変更しない。

## 再実行

```sh
mkdir -p research/out
xcrun swiftc research/coreimage_qr_probe.swift -framework AppKit -framework CoreImage -framework Vision -o research/out/coreimage_qr_probe
research/out/coreimage_qr_probe > research/out/raw.json
python3 research/analyze_coreimage_qr.py research/out/raw.json > research/out/analysis.json
```

Swift は CoreImage の出力をグレースケールの各画素へ描画して `0`/`1` 行列にする。
出力行列は各辺に白い 1 モジュールを含むため、Python はこれを除いて QR symbol を解析する。
Swift は Vision の `CIQRCodeDescriptor` から `symbolVersion`、`maskPattern`、
`errorCorrectionLevel`、`errorCorrectedPayload` も記録する。Python は第一形式情報コピーを
XOR `0x5412` 後に復号し、予約領域を除くジグザグ走査とマスク解除を行う。セグメント解析は
Vision の訂正済み payload を使う。各候補は同 payload・version・ECC・mask で
`CIBarcodeGenerator` に再生成する。

候補ペナルティは、外側の白 1 モジュールを除いた symbol に対するスクリプトの N1--N4 合計である。
N1 は連続 5 以上、N2 は 2x2、N3 は `00001011101` または `10111010000`、N4 は黒モジュール比で計算する。
列 `m0...m7` は mask 0...7 の順である。

## 実測環境

- macOS 15.7.9 (24G830)、arm64
- Apple Swift 6.2 (`swiftlang-6.2.0.19.9`)、target `arm64-apple-macosx15.0`

## 基本入力の結果

すべての行で、形式情報から得た ECC・mask は Vision の `errorCorrectionLevel`・`maskPattern` と一致した。
全候補で、再生成した候補の形式情報の mask は要求した 0...7 と一致した。選択済み行列は、その mask の再生成行列と一致した。
全 byte セグメントの payload は入力の UTF-8 bytes と一致した。ECI mode はこの 28 件の訂正済み payload には現れなかった。

|入力|ECC|version|mask|segments|m0/m1/m2/m3/m4/m5/m6/m7|
|---|---:|---:|---:|---|---|
|https://example.com|L|2|5|byte:19|590/597/588/566/548/507/503/637|
|https://example.com|M|2|2|byte:19|675/459/440/656/570/481/596/760|
|https://example.com|Q|2|0|byte:19|404/626/498/517/663/427/502/460|
|https://example.com|H|3|3|byte:19|602/660/652/560/891/781/700/695|
|8675309|L/M/Q/H|1/1/1/1|2/0/6/1|numeric:7|381/360/340/351/490/505/422/428; 265/386/399/446/441/556/425/383; 353/508/518/477/363/611/303/500; 360/306/392/466/618/485/334/347|
|HELLO WORLD|L/M/Q/H|1/1/1/2|7/0/6/5|alphanumeric:11|349/454/363/391/391/538/413/310; 311/406/442/463/367/528/395/445; 347/470/506/441/539/516/314/558; 498/650/623/571/769/481/682/549|
|hello world|L/M/Q/H|1/1/1/2|0/2/6/2|byte:11|376/500/392/432/493/475/554/422; 387/442/303/340/395/453/463/434; 372/454/341/327/394/438/303/354; 547/638/424/608/735/564/596/532|
|こんにちは世界|L/M/Q/H|2/2/3/3|3/3/3/0|byte:21|489/568/684/461/528/532/572/492; 519/635/634/441/627/510/518/476; 660/794/701/544/683/1011/618/591; 577/656/819/836/756/653/820/660|
|https://example.com/item/20260910?id=42|L/M/Q/H|3/3/4/5|3/2/2/0|byte:25,numeric:8,byte:6|683/686/647/512/729/774/766/685; 752/615/569/613/622/740/665/745; 764/964/705/934/871/828/800/833; 891/909/1088/1087/1074/972/1105/996|
|https://example.com/ + 40 digits|L/M/Q/H|3/3/4/5|4/3/7/2|byte:20,numeric:40|607/614/752/606/535/668/589/616; 586/736/781/570/725/926/637/721; 683/808/948/926/775/931/918/670; 1058/1069/941/1120/954/1255/1067/1054|

最後の入力の M は version 3 であり、訂正済み payload の先頭は byte mode・count 20、続いて numeric mode・count 40 だった。

## ASCII 数字 run の追加実測

M を指定して 120 件を実行した。入力は数字 run 長 1...24 に対し、`https://example.com/` の後、
`a` と `b` の間、`ABC` と `DEF` の間、`https://example.com/` と `?q=a` の間、および
`a` と `b` の間の大文字 run である。Python は各入力について numeric、alphanumeric、byte の全区間分割を
動的計画法で列挙した。Vision payload から読んだセグメントの bit 数と最小値は 120/120 件で一致した。
