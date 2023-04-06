作成日 `2023/04/06`
# 目的
Tomo-e Gozenの過去のstack FITSデータ、とりわけある指定のセンサのある時期に取得したデータを一括で手元にダウンロードしたい。

## 事前の準備
Tomo-e Gozen のアーカイブは PostgreSQL で運用されている。  
PostgreSQL のクライアント (psql) をインストールするか、既にインストールされている計算機を使用すること。

### Access to Database
アーカイブ用計算機は `tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp` でホストされている。  
接続するために必要な情報は以下のとおり。

- hostname: tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp
- port: 15432
- database: tomoe
- username: ????(関係者に問い合わせること)
- password: ????(関係者に問い合わせること)

``` console
$ psql -h tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp -p 15432 -d tomoe -U ????
```

`shinohara` などの木曽観測所 10 G ネットワークに接続されている計算機の場合、
hostname を `192.168.11.131` としても接続できる（メリットは特にない）

接続すると以下のようなプロンプトが表示される。

``` console
psql (15.1, server 13.4 (Debian 13.4-4.pgdg110+1))
Type "help" for help.

tomoe=>  
```

ここに検索 query を入力することでデータベースから情報を得られる。
stack データに関する情報は `stack_files` という table (正確には view) に入っている。
まず`stack_files` の情報を表示させてみる。

``` console
tomoe=> \d stack_files
                           View "public.stack_files"
    Column    |              Type              | Collation | Nullable | Default 
--------------+--------------------------------+-----------+----------+---------
 exp_id       | bigint                         |           |          | 
 observer     | character varying(64)          |           |          | 
 object       | character varying(64)          |           |          | 
 obsdate      | timestamp(6) without time zone |           |          | 
 ra_tel       | real                           |           |          | 
 dec_tel      | real                           |           |          | 
 altitude     | real                           |           |          | 
 azimuth      | real                           |           |          | 
 project      | character varying(64)          |           |          | 
 raw_id       | bigint                         |           |          | 
 det_id       | integer                        |           |          | 
 daq_host     | character varying(32)          |           |          | 
 daq_disk     | character varying(32)          |           |          | 
 daq_filename | character varying(1024)        |           |          | 
 reduction_id | bigint                         |           |          | 
 data_type    | character varying(10)          |           |          | 
 timestamp    | timestamp(6) without time zone |           |          | 
 version      | character varying(64)          |           |          | 
 fits_id      | bigint                         |           |          | 
 disk         | character varying(32)          |           |          | 
 host         | character varying(32)          |           |          | 
 filename     | character varying(1024)        |           |          | 
 size         | bigint                         |           |          | 
 naxis1       | integer                        |           |          | 
 naxis2       | integer                        |           |          | 
 naxis3       | integer                        |           |          | 
 science_id   | bigint                         |           |          | 
 dark_id      | bigint                         |           |          | 
 flat_id      | bigint                         |           |          | 
 stack_id     | bigint                         |           |          | 
```

## 流れ
以下のような流れとなる。
1. `tomoearv-master`のデータベース(`stack_files`)にアクセスし、ファイルパスの一覧を取得
2. 木曽にある計算機（例えば`tomoered-node[012]`）にアクセスし、ファイルパス一覧を使って`scp`コマンドなどでFITSデータを転送する
3. 上で持ってきたデータを`scp`で自分のローカルマシンに転送する

### データベースからファイルパスを取得
文字列結合演算子`||`と`WHERE`句を駆使して欲しいFITSリストを出力させ、テキストファイルに保存する。
> 過去のstack FITSデータを（特定のセンサのみ）まとめてダウンロードしたい

この目的にはファイルを格納している計算機とファイルパスが必要で、ファイルパスを得るには
`host`, `disk`, `filename` の 3 つの情報があれば良い。試しに 10 件だけ表示してみる。
``` console
tomoe=> SELECT host, disk, filename FROM stack_files LIMIT 10;
      host      |            disk            |           filename           
----------------+----------------------------+------------------------------
 192.168.11.135 | /pool1/20190731/0000000193 | sTMQ1201907310013088112.fits
 192.168.11.135 | /pool1/20190731/0000000214 | sTMQ1201907310013088212.fits
 192.168.11.135 | /pool1/20190731/0000000235 | sTMQ1201907310013088312.fits
 192.168.11.135 | /pool1/20190731/0000000255 | sTMQ1201907310013088412.fits
 192.168.11.135 | /pool0/20190731/0000000280 | sTMQ1201907310013088612.fits
 192.168.11.135 | /pool1/20190731/0000000281 | sTMQ1201907310013088812.fits
 192.168.11.135 | /pool0/20190731/0000000284 | sTMQ1201907310013088512.fits
 192.168.11.135 | /pool0/20190731/0000000314 | sTMQ1201907310013088912.fits
 192.168.11.135 | /pool1/20190731/0000000353 | sTMQ1201907310013088712.fits
 192.168.11.135 | /pool0/20190731/0000000384 | sTMQ1201907310013089012.fits
(10 rows)
```

文字列結合演算子 `||` を使えばファイルパスになる。
また `WHERE` 句でオブジェクト名、必要なセンサや観測日時を絞り込む。
``` console
tomoe=> SELECT host || ':' || disk || '/' || filename AS filepath FROM stack_files WHERE det_id = 112 and object = 'Pleiades_Star' and timestamp > '2023-03-13 18:00:00' LIMIT 10;
                                filepath                                
------------------------------------------------------------------------
 192.168.11.133:/pool0/20230314/0070694491/sTMQ1202303140093482012.fits
 192.168.11.133:/pool0/20230314/0070694493/sTMQ1202303140093482112.fits
 192.168.11.133:/pool0/20230314/0070694494/sTMQ1202303140093482212.fits
 192.168.11.133:/pool0/20230314/0070694496/sTMQ1202303140093482312.fits
 192.168.11.133:/pool0/20230314/0070694498/sTMQ1202303140093482412.fits
 192.168.11.133:/pool0/20230314/0070694507/sTMQ1202303140093482812.fits
 192.168.11.133:/pool0/20230314/0070694509/sTMQ1202303140093482912.fits
 192.168.11.133:/pool0/20230314/0070694510/sTMQ1202303140093483012.fits
 192.168.11.133:/pool0/20230314/0070694512/sTMQ1202303140093483112.fits
 192.168.11.133:/pool0/20230314/0070694514/sTMQ1202303140093483212.fits
(10 rows)
```

このquery結果をファイル(`test_sql.txt`)として出力してやれば良い。例えば以下のようにする。
``` console
psql -h tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp -p 15432 -d tomoe -U ????? -c "SELECT host || ':' || disk || '/' || filename AS filepath FROM stack_files WHERE det_id = 112 and object = 'Pleiades_Star' and timestamp > '2023-03-13 18:00:00' LIMIT 10" -o test_sql.txt
```



<!-- 1では、PostgreSQL(`psql`コマンド)がインストールされているマシンを使い、Tomo-eのアーカイブ用計算機(`tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp`)にアクセスする。
文字列結合演算子`||`と`WHERE`句を駆使して欲しいFITSリストを出力させ、テキストファイルに保存する。
 -->

1で保存したテキストファイルには、現在ファイルパスの先頭に`/storage`が抜けており不完全である。そのため、例えば以下のようにしてファイルの一部を置換してやる。

`cat filelist.txt | sed s@pool@storage/pool@g > filelist.txt` (区切り文字を通常のスラッシュ`/`ではなく`@`を使った)

その後、 保存したテキストファイル`filelist.txt`を１行ずつ読み込んで`scp`コマンドを木曽のマシン上で(e.g., `tomoe@tomoered-node0.kiso.ioa.s.u-tokyo.ac.jp`)走らせる。例えば以下のようにする。

```
FILE_NAME=filelist.txt
while read LINE; do scp ${LINE} ./; done < ${FILE_NAME}
```

大量のレコードを取得する場合にはそれなりに時間がかかる。
また複雑なクエリをいちいち入力するのは面倒なので、あらかじめクエリを別のファイルに作成しておいてコマンドの引数として与えるとよい。

``` console
$ psql -h tomoearv-master.kiso.ioa.s.u-tokyo.ac.jp \
       -p 15432 \
       -d tomoe \
       -U ????? \
       -f query.sql -o output.txt
```

最後に`tomoe@tomoered-node0.kiso.ioa.s.u-tokyo.ac.jp`に落としてきたFITSを`scp`コマンドで手元のマシンに転送する。


<!-- ## Access to Database -->
<!-- - a
- b
- c -->
