[![Build Status](https://travis-ci.org/IBM/ibm-cloud-functions-serverless-apis.svg?branch=master)](https://travis-ci.org/IBM/ibm-cloud-functions-serverless-apis)

# IBM Cloud Functions でサーバーレス API ハンドラーを作成する (Apache OpenWhisk の利用)

*Read this in other languages: [English](README.md), [한국어](README-ko.md).*

このプロジェクトは、サーバーレスのイベント駆動型アーキテクチャーの仕組みを説明するものです。このアーテクチャーでは、HTTP REST API の呼び出しにより、需要に応じてコードが実行されます。API エンドポイントが呼び出されるまでは、レスポンスにリソースは消費されません。API エンドポイントが呼び出されると、現在の負荷とちょうど一致するようにリソースがプロビジョニングされます。

このプロジェクトでは、MySQL データベース内のデータの書き込み/読み取りを行う 4 つの (Apache OpenWhisk ベースの) IBM Cloud Functions を取り上げて、アクションとサポート・データ・サービスが連動して HTTP リクエストに応じてロジックを実行する仕組みを説明します。

最初の関数 (アクション) は、HTTP POST リクエストにマッピングされています。このアクションは、入力された猫の名前と色のパラメーターをデータベースに挿入します。2 番目のアクションは PUT リクエストにマッピングされていて、既存の猫の名前と色のフィールドを更新します。3 番目のアクションは GET リクエストにマッピングされていて、特定の猫のデータを返します。4 番目のアクションは、特定の猫のデータを削除します。

IBM Cloud 上の Node.js ランタイムには、NPM モジュールの組み込みホワイトリストが用意されています。このデモでは高度な拡張性にも焦点を当て、MySQL クライアントなどの他の Node.js 依存関係をカスタム・アクションと一緒に ZIP ファイルにパッケージ化する方法を説明します。

## Flow

![Sample Architecture](docs/arch_buildserverless.png)

1. API クライアントが REST API に HTTP POST リクエストを送信します。
2. API ゲートウェイがリクエストを受け取り、それを OpenWhisk アクションに転送します。
3. OpenWhisk アクションがリクエスト本文のパラメーターを抽出し、NPM MySQL クライアントを使用して SQL INSERT を作成します。
4. 猫のデータがデータベースに保管されます。

## 含まれるコンポーネント

- IBM Cloud Functions (powered by Apache OpenWhisk)
- ClearDB or Compose (MySQL)

## 前提条件

OpenWhisk プログラミングモデルの基本的な理解が必要です。そうでない場合は、アクション、トリガー、ルールの [デモ](https://github.com/IBM/openwhisk-action-trigger-rule) を最初に試みてください。

また、IBM Cloudアカウントを取得し、最新の [OpenWhiskコマンドライン・ツール(`wsk`)](https://github.com/IBM/openwhisk-action-trigger-rule/blob/master/docs/OPENWHISK.md) がインストールされ、PATH に追加されている必要があります。

この一通り動作するサンプルの代わりに、このサンプルより [より基本的な要素を理解するためのバージョン](https://github.com/IBM/openwhisk-rest-api-trigger) を参考にすることもできます。

## 手順

1. [MySQL の準備](#1-provision-mysql)
2. [OpenWhisk アクションとマッピングを作成する](#2-create-openwhisk-actions-and-mappings)
3. [APIエンドポイントをテストする](#3-test-api-endpoints)
4. [アクションとマッピングを削除する](#4-delete-actions-and-mappings)
5. [こんどは手動でデプロイする](#5-recreate-deployment-manually)

<a name="1-provision-mysql"></a>
# 1. MySQL の準備

IBM Cloudにログインし、[ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/) または [Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/) データベースインスタンスを準備 (プロビジョニング) します。
ClearDB には簡単なテストのためのフリーの段階 (tier) がありますが、Compose にはより大きなワークロードの段階があります。

* [ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/) の場合は、ClearDB ダッシュボードにログインし、作成されたデフォルトのデータベースを選択します。
`Endpoint Information` でユーザー、パスワード、およびホスト情報を取得します。

* [Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/) の場合は、IBM Cloud コンソールの `Service Credentials` タブから情報を入手してください。

`template.local.env` を `local.env` という名前の新しいファイルにコピーし、MySQL インスタンスの `MYSQL_HOSTNAME`、`MYSQL_USERNAME`、`MYSQL_PASSWORD`、`MYSQL_DATABASE` の値を書き込んでください。

> 訳者注: 2018年7月現在、ClearDB サービスは利用できないようですが、参考のためにテキストは翻訳します

<a name="2-create-openwhisk-actions-and-mappings"></a>
# 2. OpenWhisk アクションとマッピングを作成する

`deploy.sh` は便利なスクリプトで、`local.env` から環境変数を読み込み、あなたのために OpenWhisk アクションと API マッピングを作成します。
後でこれらのコマンドを自分で実行します。

```bash
./deploy.sh --install
```

> **注**: エラーメッセージが表示された場合は、後の [トラブルシューティング](#troubleshooting) セクションを参照してください。
[別のデプロイ方法](#alternative-deployment-methods) を参照することもできます。

<a name="3-test-api-endpoints"></a>
# 3. APIエンドポイントをテストする

`/v1/cat` エンドポイントに対して、エンティティを作成、取得、更新、削除する HTTP API クライアントをシミュレートする4つのヘルパースクリプトがあります。

```bash
# エンティティの作成テスト
# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# エンティティの取得テスト
# GET /v1/cat?id=1
client/cat-get.sh 1 # Or whatever integer ID was returned by the command above

# エンティティの更新テスト
# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# エンティティの削除テスト
# DELETE /v1/cat?id=1
client/cat-delete.sh 1
```

<a name="4-delete-actions-and-mappings"></a>
# 4. アクションとマッピングを削除する

`deploy.sh` をもう一度使って、OpenWhiskのアクションとマッピングを削除してください。
次のセクションではそれらをステップバイステップで再作成します。

```bash
./deploy.sh --uninstall
```

<a name="5-recreate-deployment-manually"></a>
# 5. こんどは手動でデプロイする

このセクションでは、`deploy.sh` スクリプトの実行内容を詳しく見て、OpenWhiskのトリガー、アクション、ルール、およびパッケージをより詳しく扱う方法を理解していきます。

## 5.1 猫データを変更するための OpenWhisk アクションの作成

猫のデータを管理するアクションを API の各メソッド(POST、PUT、GET、DELETE)ごとに1つずつ、合計で4つ作成します。
アクションのコードは `/actions` にあります。
最初に猫のレコードを作成するアクションから始めましょう。

> **注**: OpenWhisk Node.jsランタイム環境で使用できる組み込みパッケージの [詳細はこちら](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments)。
追加パッケージが必要な場合は、アクションファイルとともに ZIP ファイルにまとめてアップロードすることができます。
単一ファイルと ZIP 圧縮アーカイブの違いの詳細については、[Getting Started Guide](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action) を参照してください。

### 5.1.1 猫パッケージ

すべてのアクションは MySQL データベースサービスに依存しているため、パッケージレベルで一度、資格情報を設定すると便利です。
これにより、パッケージ内のすべてのアクションで資格情報を使用できるようになります。
したがって、作成時および実行時にアクションごとに定義する必要はありません。

```bash
source local.env
wsk package create cat \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

### 5.1.2 猫の作成アクション

POSTアクションのJavaScriptコードは、 [`/actions/cat-post-action/index.js`](actions/cat-post-action/index.js) にあります。
この関数は、データベースに接続するために必要な `mysql` クライアント npm パッケージに依存します。
`npm install` ([`package.json`](actions/cat-post-action/package.json) を解析する) を使ってパッケージをインストールし、アプリケーションとその依存関係の両方を含む ZIP ファイルを作成します。

```bash
cd actions/cat-post-action
npm install
zip -rq action.zip *
```

次に、OpenWhisk CLI を使用して `action.zip` からアクションを作成 (create) します。

```bash
# Create
wsk action create cat/cat-post \
  --kind nodejs:6 action.zip \
  --web true
```

次に、テストする `wsk` CLIを使って手動でアクションを起動 (invoke) します。

```bash
# Test
wsk action invoke \
  --blocking \
  --param name Tarball \
  --param color Black \
  cat/cat-post
```

> 訳者注: 上記のアクションでデータベースに、「名前が Tarball で、色が黒」である猫のレコードが新規作成されました。

上記の手順を繰り返して、対応する GET、PUT、DELETE アクションを作成してテストしていきます。


> **注**: 上記の POST アクション結果から返された実際の ID を反映させるために、あなたのテストでは `id 1` を置き換えてください。

### 5.1.3 猫の参照アクション

GET アクションを作成してテストします。

```bash
# Create
cd ../../actions/cat-get-action
npm install
zip -rq action.zip *
wsk action create cat/cat-get \
  --kind nodejs:6 action.zip \
  --web true

# Test
wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

> 訳者注: このアクションで、さきほど作成された「名前が Tarball で、色が黒」である猫のレコードが読み取られ表示されるはずです。

### 5.1.4 猫の更新アクション

PUT アクションを作成してテストします。

```bash
# Create
cd ../../actions/cat-put-action
npm install
zip -rq action.zip *
wsk action create cat/cat-put \
  --kind nodejs:6 action.zip \
  --web true

# Test
wsk action invoke \
  --blocking \
  --param name Tarball \
  --param color Gray \
  --param id 1 \
  cat/cat-put

wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

> 訳者注: このアクションで、さきほど作成・参照された「名前が Tarball で、色が黒」である猫のレコードが、「名前が Tarball で、色が灰色」に書き換えられました。

### 5.1.5 猫の削除アクション

DELETE アクションを作成してテストします。

```bash
# Create
cd ../../actions/cat-delete-action
npm install
zip -rq action.zip *
wsk action create cat/cat-delete \
  --kind nodejs:6 action.zip \
  --web true

# Test
wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-delete

wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

> 訳者注: このアクションで、さきほど作成・参照・更新された「名前が Tarball で、色が灰色」である猫のレコードが、削除されました。

## 5.2 REST APIエンドポイントを作成する

次に、リソースエンドポイント (`/cat`) を `GET`、`DELETE`、`PUT`、`POST` HTTP メソッドにマップし、対応する OpenWhisk アクションに関連づけて、クライアントスクリプトを使ってテストします。

```bash
# Create
wsk api create -n "Cats API" /v1 /cat post cat/cat-post
wsk api create /v1 /cat put cat/cat-put
wsk api create /v1 /cat get cat/cat-get
wsk api create /v1 /cat delete cat/cat-delete

# Test

# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# GET /v1/cat?id=1
client/cat-get.sh 1 # Replace 1 with the id returned from the POST action above

# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# DELETE /v1/cat?id=1
client/cat-delete.sh 1
```

## 5.3 クリーンアップ

APIマッピングを解除し、アクションを削除します。

```bash
wsk api delete /v1
wsk action delete cat/cat-post
wsk action delete cat/cat-put
wsk action delete cat/cat-get
wsk action delete cat/cat-delete
wsk package delete cat
```

<a name="troubleshooting"></a>
# トラブルシューティング

まずは OpenWhisk アクティベーションログでエラーをチェックしてください。
`wsk activation poll` を使用してコマンドラインでログを出力するか、[IBM Cloudの監視コンソール](https://console.ng.bluemix.net/openwhisk/dashboard) で視覚的に細部を掘り下げてください。

エラー内容が不明確な場合は、[最新バージョンの `wsk` CLI](https://console.ng.bluemix.net/openwhisk/learn/cli) がインストールされていることを確認してください。
もし数週間以上経過している場合は、アップデートをダウンロードしてください。

```bash
wsk property get --cliversion
```

<a name="alternative-deployment-methods"></a>
# 別のデプロイ方法

`deploy.sh` は将来、[`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) に置き換えられます。 `wskdeploy` は、宣言されたトリガー、アクション、ルールを OpenWhisk にデプロイするためにマニフェスト (manifest) を使います。

次のボタンを使用して、このリポジトリーのコピーをクローンし、DevOps ツールチェーンの一部として IBM Cloud にデプロイすることもできます。
OpenWhisk と MySQL の資格情報を Delivery Pipeline アイコンの下に入力し、`Create` をクリックしてから、配信パイプラインの Deploy ステージを実行します。

[![Deploy to the IBM Cloud](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/openwhisk-serverless-apis.git)

# ライセンス
[Apache 2.0](LICENSE)
