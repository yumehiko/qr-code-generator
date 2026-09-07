# Issue 棚卸し

この文書は 2026-09-07 時点の整理結果です。作業状態の正本は GitHub Issues とし、`.spec-workflow/specs/qr-code-generator/` は設計・要件の参照資料として保持します。

## 既存成果物と対応先

| 対象 | 状態 | 対応先 |
| --- | --- | --- |
| `.spec-workflow/specs/qr-code-generator/tasks.md` の1〜20 | 完了扱い（20項目） | 再起票なし。成果物とテストを参照 |
| `Sources/` の TODO/FIXME | 未完了項目なし | 対応Issueなし |
| tasks.md 内の「Fix any integration issues」 | 完了済みの統合・テスト項目内の記述 | 新規Issue化しない |
| 要件・設計・承認記録 | 参照資料 | `.spec-workflow/` に保持 |

## 運用Issue

- #1 [公開準備: Git履歴・設定・配布物の監査と機密情報の除去](https://github.com/yumehiko/qr-code-generator/issues/1): 監査。機密情報と公開可否を確認する。
- #2 [整理: ビルド・テスト・配布手順の再現性と不要物を整備](https://github.com/yumehiko/qr-code-generator/issues/2): #1 の監査結果を前提に、再現性を整える。
- #3 [管理: 既存TODOをGitHub Issuesへ集約し開発運用を文書化](https://github.com/yumehiko/qr-code-generator/issues/3): 本文書、運用文書、テンプレートを整える。
- #4 [公開準備: 整理フェーズの完了判定と公開可否の確認](https://github.com/yumehiko/qr-code-generator/issues/4): #1〜#3 完了後に公開可否を判定する。

新しい改善・機能は整理フェーズ完了まで保留します。既存Issueと同じ作業を見つけた場合は、重複Issueを作らず該当Issueへ追記します。
