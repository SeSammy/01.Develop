### Avaya 基盤構成 概要

---

#### ■ ASP（Avaya Solutions Platform）
- Avaya製アプリケーション群を統合運用する仮想化プラットフォーム
- **VMware ESXi** 上での仮想化構成が可能
- Avayaが提供する認定OS・ドライバ・パッチセットを含む専用ビルド環境で、Experience Portal、AES、CMSなど主要製品の稼働基盤として利用される

---

#### ■ G450（Media Gateway）
- 音声信号をIPパケットに変換する **DSP（Digital Signal Processor）** を搭載
  - DSP処理能力：180ch／360ch
  - BRI接続時：1通話あたり2chを使用
- PBX（ACM）との間でTDM⇔IP変換を行い、音声系トラフィックを制御する中継装置
- 支店やセンター拠点に設置され、音声冗長化・QoS制御を実現

---

#### ■ ESXi構成
- 近年は **仮想化構成が主流**。AESを外部物理サーバで運用する構成も可能だが、費用が高く一般的ではない
- 以下の構成単位ごとに独立したVMを構築する：
  - **ACM（Avaya Communication Manager）**
  - **SMGR（System Manager）**
    - ライセンス管理を担当
    - 30日間までは副系未設定でも稼働可能
    - 正副切替にはサーバ再起動が必要なため、副系構成は運用上考慮されない場合が多い
  - **CMS／AES**
  - **EPM・MPP・WAS（IVR関連）**
- **補足:**
  - ESXiホスト上でVM単位にvCPU・メモリを割り当てる。
  - それぞれのコンポーネントは個別のOSイメージで動作し、相互依存を最小化する設計が推奨される。
  - バックアップ・スナップショットはVM単位で実施し、vMotionによる移行も可能。

---

#### ■ ESS（Enterprise Survivability Server）
- **DR（Disaster Recovery）対策用**の冗長サーバ
- 大規模環境での主系障害時に自動フェイルオーバーを実施
- ACMの設定を同期し、WAN経由で通話制御を継続可能

---

#### ■ LSP（Local Survivability Processor）
- 小規模構成向けのDR代替装置
- 基本的には **ESS** を優先採用し、LSPは分散拠点や小規模拠点に限定して使用
- ACMのサブセット機能として、最小限の通話制御をローカル維持

---

#### ■ SMGR（System Manager）
- Avaya製品群の **ライセンス・設定・証明書管理** を統合的に行う管理サーバ
- ACM／AES／AEPなど各製品の構成情報を一元管理し、証明書ベースの認証を実施
- **補足:**
  - システム全体の“信頼ドメイン”を構成する中心ノード
  - 証明書期限切れによる接続エラーを防ぐため、定期的な更新作業が必要

---

#### ■ CMS（Call Management System）
- コール情報の収集・蓄積を行い、レポート／統計を出力
- オペレーション分析やトラフィック監視に使用
- **補足:**
  - 通話データ（呼数、通話時間、応答率など）をリアルタイムで集計
  - Avaya Supervisor ConsoleなどのGUIツールから確認可能
  - SQLベースの履歴データ抽出にも対応

---

#### ■ AES（Application Enablement Services）
- **CTI（Computer Telephony Integration）連携基盤**
- ソフトフォン（one-X Agent、Communicatorなど）や業務アプリとの制御連携を提供
- Station Link・TSAPI通信を介してIVR／CRMとの情報連携を実現
- **補足:**
  - AESはACMとCTIクライアント（外部アプリ）を仲介する中間層
  - TSAPI／DMCC／JTAPIなど複数のAPIを提供
  - セキュリティ対策としてTLS通信・証明書認証をサポート

---

#### ■ AEP（Avaya Experience Portal）
- **IVR（Interactive Voice Response）基盤**
- 音声ガイダンス・自動応答・顧客入力受付を実現するプラットフォーム

##### ・MPP（Media Processing Platform）
- 通話処理および音声再生の実行エンジン
- 呼制御・DTMF検知・音声再生を担当
- ACMとの仮想内線接続によるセッション管理を実施
- 各着信番号にマッピングされたコールフローをHTTP経由で呼び出し
- WASから受信した **VoiceXML** と音声ファイルをもとに音声を再生
- **補足:**
  - MPPは実際に「話す」「聞く」処理を担当する層であり、シナリオ実行の主役
  - CPU・メモリ負荷が高いため、複数ノードでの水平分散構成が基本

##### ・EPM（Experience Portal Manager）
- **テレフォニーポートライセンス管理**および **MPP制御管理** を担当
- 各ポートの稼働状況、ライセンス設定、MPPノード制御を一元管理
- **補足:**
  - Experience Portal全体の「頭脳」にあたる管理層
  - 通話ポートの使用上限・シナリオ配信・フェイルオーバー設定を集中制御

##### ・WAS（Web Application Server）
- **IVRアプリケーション実行層**
- コールフロー制御、業務ロジック、CTI情報連携を担当
- AES経由で **TSAPI通信** によりCTIイベントを取得
- VoiceXMLと音声ファイルをMPPへ送信して音声ガイダンスを生成
- **補足:**
  - WASはAvaya純正ではなく、顧客業務ごとのアプリケーション層（Tomcat／WebSphere等）
  - IVRで取得した顧客情報をCRM／DB／外部APIへ連携する役割を持つ
  - SmartCB（Smart Call Broker）などの呼制御モジュールと連携し、音声経路を動的に制御

---

#### ■ 総括補足
- **AEP（IVR層）** は **ACM（音声制御）**・**AES（CTI連携）**・**WAS（業務アプリ層）** との協調で動作する多層構成。
- **ESS／LSP** は障害対策、**SMGR／CMS** は統合管理、**ASP／ESXi** は仮想基盤層。
- 各層が分離されていることで、運用時の障害範囲を限定し、構成変更・バージョンアップを独立して行うことが可能。
