# 於 IBM Cloud Functions 上使用無服務器 (Serverless) APIs  (運用 Apache OpenWhisk)

*Read this in other languages: [English](README.md).*

該專案主要用來了解無服務器、事件驅動式架構如何執行能動態擴展以符合資源需求的程式，用以回應HTTP REST API的呼叫。 程式在調用 API 端點之前不會消耗任何資源。 調用它們時，會調配資源以獨立地配置每個HTTP請求所需的當下資源負載。

專案中包含四個 JavaScript 編寫的動作 （運行在 IBM Cloud Functions 使用 Apache OpenWhisk）操作（用JavaScript編寫），四個動作用在 MySQL 資料庫中寫入和讀取資料。 示範每項動作是如何讓資料服務及執行邏輯一起運作以回應HTTP請求。

第一個動作對應到HTTP POST請求，將貓的名字跟顏色參數新增至資料庫中。 第二個動作會對應至PUT請求以更新現有貓資料的欄位值。 第三個動作會對應至傳回指定貓的資料的GET請求。 第四個動作會刪除指定的貓的資料。

IBM Cloud上 的 Node.js 執行系統 (runtime) 會提供內建的npm模組白名單。 此範例也會示範如何使用自訂動作將其它 Node.js 相依模組（例如MySQL用戶端npm）包裝在ZIP檔中以提供進一步的整合。

![架構範例](docs/arch_buildserverless.png)

## 包含的元件

- IBM Cloud Functions (使用 Apache OpenWhisk)
- ClearDB 或是 Compose (MySQL)

## 必備條件

你需要對 OpenWhish 的程式開發模式有基礎的了解。 可 [先了解關於動作, 觸發及規則的範例](https://github.com/IBM/openwhisk-action-trigger-rule).

你也需要有 IBM Cloud 的帳號及最新版本的 [OpenWhisk 安裝命令列工具 (`bx wsk`) 並且加入到你電腦中的 PATH 裡]

除了這個關於端對端 (end-to-end) 的範例, 你也可以參考範例 [用以理解基本底層“基礎元件"版本](https://github.com/IBM/openwhisk-rest-api-trigger)。


## 步驟

1. [準備 MySQL](#1-provision-mysql)
2. [建立 OpenWhisk 動作及對映](#2-create-openwhisk-actions-and-mappings)
3. [測試 API 端點](#3-test-api-endpoints)
4. [刪除 動作 及 對映](#4-delete-actions-and-mappings)
5. [使用手動部署重新建立](#5-recreate-deployment-manually)

## 1. 準備 MySQL

登入 IBM Cloud 並且建立一個 MySQL 環境 [Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/). 

進入 [Compose](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/), 於畫面右方選單, 點選 `服務認證`, 檢視內容

將本專案中的檔案 `template.local.env` 複製一個新檔案, 命名為 `local.env`, 並依照剛剛於`服務認證`內的內容, 修改 `local.env` 中 `MYSQL_HOSTNAME`, `MYSQL_PORT`,`MYSQL_USERNAME`, `MYSQL_PASSWORD` 及 `MYSQL_DATABASE`.

## 2. 建立 OpenWhisk 動作及對應

`deploy.sh` script 會讀取`local.env`中的環境變數並且建立好 OpenWhisk 的動作及對應. 接下來你就可以自己執行這些動作.

```bash
./deploy.sh --install
```

> **Note**: 如果有錯誤訊息, 請參考 [疑難排除](#疑難排除) 章節. 也可另外參考 [另一種部署方式](#另一種部署方式).

## 3. 測試 API 端點

以下四個 helper scripts 用來模擬  HTTP API 用戶端建立, 查詢, 修改即刪除 `/v1/cat` 端點下的實體 (entities).

```bash
# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# GET /v1/cat?id=1
client/cat-get.sh 1 # Or whatever integer ID was returned by the command above

# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# DELETE /v1/cat?id=1
client/cat-delete.sh 1
```

## 4. 刪除動作及對映

再次執行 `deploy.sh` 來刪除 OpenWhisk 動作及對映. 然後再下一章節, 你將會以手動方式一步步地重新建立這些動作 .

```bash
./deploy.sh --uninstall
```

## 5. 重新以手動方式部署

這章節深入`deploy.sh`程式, 讓你更了解什麼是 OpenWhisk 的觸發, 動作, 規則及套件.

### 5.1 建立 OpenWhisk 動作及修改 cat 資料

建立四個動作來管理 cat 資料, 一個動作對應到我們 API 中 (POST, PUT, GET, and DELETE) 四個請求方法中的一個. 程式碼於 `/actions` 目錄下. 我們先從建立 cat 資料開始.

> **Note**: OpenWhish Node.js 執行環境的 [內建套件](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments). 若你需要額外的套件, 你可以將套件與你的動作程式檔案一併壓縮成 ZIP 檔案上傳. 關於要用單一檔案還是壓縮檔的比較, 可參考 [入門手冊](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action).

#### 5.1.1 cat 套件

由於所有動作都必須使用到 MySQL 資料庫服務, 所以先將相關的認證及連線資訊設定在套件中會比較方便. 這樣可以讓套件中的所有動作都可以讀取到這些參數, 而不用每一個動作裡都要重新寫一次.

```bash
source local.env
bx wsk package create cat \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_PORT" $MYSQL_PORT \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

#### 5.1.2 建立 cat 資料的動作

 POST 動作的 JavaScript 程式碼在 `/actions/cat-post-action/index.js` 中. 在程式中我們使用 `mysql` client npm 套件來連接到資料庫. 使用 `npm install` 來安裝 npm 套件 ( `package.json` 定義使用哪些套件), 然後將程式跟相關檔案壓縮成一個 ZIP 壓縮檔.

```bash
cd actions/cat-post-action
npm install
zip -rq action.zip *
```

接下來使用 OpenWhisk CLI 指令將 `action.zip` 建立為一個動作 .

```bash
# Create
bx wsk action create cat/cat-post \
  --kind nodejs:6 action.zip \
  --web true
```

測試使用 `bx wsk` CLI 指令來調用這個動作.

```bash
# Test
bx wsk action invoke \
  --blocking \
  --param name Tarball \
  --param color Black \
  cat/cat-post
```

重複以上步驟來建立及測試其它 GET, PUT, 及 DELETE 三個動作 .

> **Note**: 以下的測試, 你需要把 id 值 1 換成你執行上一個 POST 動作後所回傳的 id 值.

#### 5.1.3 讀取 cat 資料的動作

```bash
# Create
cd ../../actions/cat-get-action
npm install
zip -rq action.zip *
bx wsk action create cat/cat-get \
  --kind nodejs:6 action.zip \
  --web true

# Test
bx wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

##### 5.1.4 修改 cat 資料的動作

```bash
# Create
cd ../../actions/cat-put-action
npm install
zip -rq action.zip *
bx wsk action create cat/cat-put \
  --kind nodejs:6 action.zip \
  --web true

# Test
bx wsk action invoke \
  --blocking \
  --param name Tarball \
  --param color Gray \
  --param id 1 \
  cat/cat-put

bx wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

#### 5.1.5 刪除 cat 資料的動作

```bash
# Create
cd ../../actions/cat-delete-action
npm install
zip -rq action.zip *
bx wsk action create cat/cat-delete \
  --kind nodejs:6 action.zip \
  --web true

# Test
bx wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-delete

bx wsk action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

### 5.2 建立 REST API 端點

將 `GET`, `DELETE`, `PUT`, 及 `POST` 四個 HTTP 請求對應至資源端點 (`/cat`) , 並且將他們關聯至相應的 OpenWhisk 動作, 測試用戶端的 scripts 程式.

```bash
# Create
bx wsk api create -n "Cats API" /v1 /cat post cat/cat-post
bx wsk api create /v1 /cat put cat/cat-put
bx wsk api create /v1 /cat get cat/cat-get
bx wsk api create /v1 /cat delete cat/cat-delete

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

### 5.3 刪除測試環境

移除 API 的對映並且刪除所有動作.

```bash
bx wsk api delete /v1
bx wsk action delete cat/cat-post
bx wsk action delete cat/cat-put
bx wsk action delete cat/cat-get
bx wsk action delete cat/cat-delete
bx wsk package delete cat
```

## 疑難排除

首先在OpenWhisk活動日誌中檢查錯誤。 執行`bx wsk activation poll`指令可持續在畫面上顯示活動日誌，或使用 [點選 IBM Cloud Functions 上的監視選項] 讀取活動日誌詳細訊息 (https://console.ng.bluemix.net/openwhisk/dashboard).

如果沒辦法馬上找到錯誤訊息, 請先確定已安裝了 [最新版本的 `bx wsk` CLI 指令工具](https://console.ng.bluemix.net/openwhisk/learn/cli). 如果版本超過幾週沒更新, 請下載並更新至最新版本.

```bash
bx wsk property get --cliversion
```

## 另一種部署方式

`deploy.sh` 將被 [`wskdeploy`] 取代 (https://github.com/openwhisk/openwhisk-wskdeploy). `wskdeploy` 使用描述檔的方式來宣告 OpenWhisk 中的觸發, 動作及規則.

你可以點擊下面的按鈕複製一份存儲庫的副本，並作為DevOps工具鏈的一部分部署到IBM Cloud。 在Delivery Pipeline 圖示下提供你的 OpenWhisk 和 MySQL 認證資訊，點擊`建立`，執行“交付管道”的“部署”階段。

[![部署至 IBM Cloud](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/openwhisk-serverless-apis.git)

## 授權

[Apache 2.0](LICENSE.txt)
