# 開発運用

- 作業状態の正本は GitHub Issues とする。`.spec-workflow/specs/` は要件・設計の参照資料として扱う。
- Issue 単位で実装担当（Terra/Luna）が作業し、PR を提出する。別担当（Sol/Terra）が受入条件、テスト、PR の HEAD を独立に確認する。
- レビューで変更した場合は同じPRのHEADを再レビューする。受入条件を満たした後、保護設定を回避せず通常のマージ手順を使う。
- 完了済み作業を未完了として再起票しない。新しい改善・機能は整理フェーズ完了後まで保留し、必要なら別Issueにする。
- Issue、PR、ログに秘密の実値、トークン、個人環境の絶対パスを含めない。公開設定は変更しない。
- テストは `swift test` または `./run_tests.sh` を基本とし、変更内容に応じてビルドも確認する。

Issue間の対応は [`docs/issue-inventory.md`](docs/issue-inventory.md) を参照する。
