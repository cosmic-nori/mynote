作成日 `2023/04/06`
# 目的
Tomo-e Gozenの過去のstack FITSデータ、とりわけある指定のセンサのある時期に取得したデータを一括で手元にダウンロードしたい。
## 流れ
以下のような流れとなる。
1. `tomoearv-master`のデータベース(`stack_files`)にアクセスし、ファイルパスの一覧を取得
2. 木曽にある計算機（例えば`tomoered-node[012]`）にアクセスし、ファイルパス一覧を使って`scp`コマンドなどでFITSデータを転送する
3. 上で持ってきたデータを`scp`で自分のローカルマシンに転送する
## 具体的には...
1では、PostgreSQL(`psql`コマンド)がインストールされているマシンを使い、Tomo-eのアーカイブ用計算機(`tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp`)にアクセスする。
文字列結合演算子`||`と`WHERE`句を駆使して欲しいFITSリストを出力させ、テキストファイルに保存する。


1で保存したテキストファイルには、現在ファイルパスの先頭に`/storage`が抜けており不完全である。そのため、例えば以下のようにしてファイルの一部を置換してやる。
`cat filelist.txt | sed s@pool@storage/pool@g > filelist.txt` (区切り文字を通常のスラッシュ`/`ではなく`@`を使った)
その後、 保存したテキストファイル`filelist.txt`を１行ずつ読み込んで`scp`コマンドを木曽のマシン上で(e.g., `tomoe@tomoered-node0.kiso.ioa.s.u-tokyo.ac.jp`)走らせる。例えば以下のようにする。

```
FILE_NAME=filelist.txt
while read LINE; do scp ${LINE} ./; done < ${FILE_NAME}
```

最後に`tomoe@tomoered-node0.kiso.ioa.s.u-tokyo.ac.jp`に落としてきたFITSを`scp`コマンドで手元のマシンに転送する。


<!-- ## Access to Database -->
<!-- - a
- b
- c -->
