# 1. AEP（Avaya Experience Portal）とは

| 項目 | 内容 |
| --- | --- |
| **定義** | Avayaが提供する統合IVR（音声自動応答）基盤。通話の着信、ガイダンス再生、番号入力、CTI転送などを行う「音声アプリ実行プラットフォーム」 |
| **位置づけ** | PBX（Communication Manager）とWebアプリケーション（WAS）の中間層で、通話をHTTP＋XMLで制御する音声用アプリサーバ |
| **主要構成要素** | - **EPM（Experience Portal Manager）**：管理・ライセンス・シナリオ配信<br>- **MPP（Media Processing Platform）**：通話処理・音声再生・DTMF認識・HTTP制御<br>- **WAS（Web Application Server）**：業務ロジック実行層（TomcatなどでVXMLを提供） |
| **補助コンポーネント** | - **AES**：CTI情報連携（TSAPI/DMCC）<br>- **POM**：アウトバウンド発信管理<br>- **SmartCB**：呼分岐制御<br>- **CMS**：通話ログ収集 |

---

## 2. AEPの基本動作フロー

1. 通話着信（SIP/H.323）
2. MPPがHTTPでWASにVoiceXMLを要求
3. WASがVXMLを返却（ガイダンス・分岐定義）
4. MPPが音声を再生、DTMF/音声入力を受付
5. 条件に応じてAPI呼出や転送（ACM/AES）
6. 処理完了後、EPMに結果を報告・ログ化

→ WebブラウザがHTMLを読み取るように、AEPはVoiceXMLを読み取って“音声で動くWeb”を実現。

---

## 3. 各コンポーネントの役割詳細

| コンポーネント | 役割 | 補足 |
| --- | --- | --- |
| **EPM** | 全体統制。ライセンス管理、MPP制御、シナリオ配信 | 1台でも動作するが、冗長化（HA構成）推奨 |
| **MPP** | 実行エンジン。音声入出力、DTMF検知、HTTP通信 | CPU負荷が高く、ノード分散が基本設計 |
| **WAS** | 業務アプリ。HTTP応答としてVXMLを返却 | Java/Tomcatなどで構築。外部DB・APIと連携 |
| **AES** | PBX（CM）とのCTIイベント連携 | AEPでの顧客認証やオペレータ転送に使用 |
| **POM** | アウトバウンド発信・SMS通知管理 | 着信と同じAEPフローを流用可能 |

---

## 4. VoiceXML（VXML）の仕組み

| 項目 | 内容 |
| --- | --- |
| **概要** | 音声対話アプリをXML形式で記述するW3C標準仕様 |
| **役割** | ガイダンス内容、入力分岐、HTTP連携などを定義 |
| **対応要素** | `<prompt>`（音声ガイダンス）、`<grammar>`（認識対象）、`<goto>`（遷移先指定）、`<filled>`（条件分岐処理） |
| **補足** | AEPではHTTP経由でVXMLを動的に取得。外部APIと連携可能。 |

### VoiceXML記述例

```xml
<vxml version="2.1">
  <form id="main">
    <block>
      <prompt>いらっしゃいませ。サービス番号を入力してください。</prompt>
    </block>
    <field name="menu">
      <grammar>1|2|3</grammar>
      <prompt>1は残高照会、2は振込、3はオペレーターです。</prompt>
      <filled>
        <if cond="menu=='1'">
          <goto next="balance.vxml"/>
        <elseif cond="menu=='2'"/>
          <goto next="transfer.vxml"/>
        <else/>
          <goto next="operator.vxml"/>
        </if>
      </filled>
    </field>
  </form>
</vxml>

```

## 5. 可用性と設計の要点（SPOF対策）

| 項目 | 内容 |
| --- | --- |
| **SPOFとは** | Single Point of Failure。1要素の障害で全体が停止する構成箇所 |
| **AEPでの対策** | - **EPM**：HA冗長化（アクティブ/スタンバイ）<br>- **MPP**：複数ノード分散構成<br>- **WAS**：クラスタまたはロードバランサ配下運用 |

### 構成例

```
 +-------------------------+
 | EPM-HA (Active/Standby) |
 +------------+------------+
              |
  +-----------+-----------+
  |   LB (Round Robin)    |
  +-----+-----------+-----+
        |           |
     [MPP1]       [MPP2]
        ↓           ↓
       HTTP       HTTP
        ↓           ↓
        [WAS Cluster]

```

---

## 6. 運用・監視の観点

| 項目 | 監視対象 | 監視指標例 |
| --- | --- | --- |
| **EPM** | ライセンス状態、ジョブ実行、ノード状態 | 稼働率・ポート消費数 |
| **MPP** | CPU負荷、同時呼数、HTTP応答 | 同時通話数・エラー率・RTT |
| **WAS** | スレッド、API応答時間 | P95遅延・エラー件数 |
| **SIP/CTI層** | 呼損率、転送成功率 | 呼損率・切断理由コード |

---

## 7. 設計・開発のポイント

| 項目 | 推奨設計 |
| --- | --- |
| **音声ファイル管理** | 8kHz mono WAV（G.711）で統一、キャッシュ利用 |
| **コールフロー設計** | 短く・浅く。タイムアウト・再入力は明示設定 |
| **外部API呼出** | HTTP非同期＋タイムアウト設定（3秒以下） |
| **監査・保守** | EPM配信ジョブ管理・バージョン管理（DEV→STG→PRD） |
| **セキュリティ** | TLS通信、証明書更新スケジュール化（SMGR統制） |

---

## 8. 通録・呼制御補足（AEP外縁）

| 観点 | 内容 |
| --- | --- |
| **呼制御プロトコル** | SIP / H.323 / PRI（TDM）など。CMが通話制御の中心 |
| **録音方式** | - Passive録音（RTPミラー）<br>- AES連携（TSAPI/DMCC）で論理制御<br>- CTI同期で通話メタ情報を取得 |
| **AESの役割** | CMの通話状態を外部録音装置・CRMへ通知。録音はRTP経路で別取得。 |
| **トランク録音** | AESはTSAPI “Trunk Group Call Control”で呼情報取得、音声はミラー録音で取得。 |
| **H.323録音** | H.225/H.245解析で通話開始・終了・RTP経路を特定。 |
| **現行主流** | SIP＋TSAPI＋Passive録音のハイブリッド構成（NICE/Verintなど）。 |

---

## 9. AEP連携構造イメージ

```
         ┌─────────────────┐
         │  EPM（管理層）   │
         └────────┬────────┘
                  │
      ┌───────────┴──────────┐
      │                      │
  ┌────────┐               ┌────────┐
  │  MPP#1 │   … HTTP …    │  MPP#2 │
  └────────┘               └────────┘
      │                      │
      └──────────┬───────────┘
                 ↓
          [ WAS / VXMLサーバ ]
                 ↓
          [ 外部API・DB連携 ]
                 ↓
          [ AES / PBX / CRM ]
                 ↓
          [ 録音・監視システム ]

```

---

## 10. 総括

| 分類 | 概要 |
| --- | --- |
| **AEPの役割** | 音声応答プラットフォームとして、通話と業務アプリをHTTP連携で橋渡し |
| **EPM** | 中枢の管理・配信・監視・ライセンス制御 |
| **MPP** | 音声実行エンジン。VXMLを解釈して音声応答を実行 |
| **WAS** | 業務ロジック提供層（外部DB・CRM・API接続） |
| **SPOF対策** | EPM冗長化＋MPP多重化＋WASクラスタ |
| **録音・呼制御補足** | AESが通話状態をCTIイベントで通知、録音はRTPミラーで取得 |

---

### 出典・根拠

- Avaya Experience Portal Architecture Guide (2024)
- Avaya AES TSAPI SDK Developer Guide (R10.1)
- Avaya Communication Manager Feature Description (R10.x)
- NICE / Verint Integration for Avaya CM/AES
- W3C VoiceXML 2.1 Specification
