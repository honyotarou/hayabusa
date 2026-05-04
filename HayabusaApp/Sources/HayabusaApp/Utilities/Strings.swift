import Foundation

enum Strings {
    // MARK: - Wizard
    enum Wizard {
        static let welcomeTitle = "Hayabusa へようこそ"
        static let welcomeSubtitle = "Apple Silicon で動く高速AIサーバー"
        static let welcomeDescription = "病院内のMacでAIを安全に使えるようにします。\nインターネット不要で、患者データは外部に出ません。"
        static let getStarted = "はじめる"

        static let modelSelectTitle = "AIモデルを選択"
        static let modelSelectDescription = "お使いのMacに合ったモデルを選んでください"

        static let modelInstalledTab = "インストール済み"
        static let modelDownloadTab = "新しくダウンロード"
        static let modelNoneInstalled = "インストール済みのモデルが見つかりません"

        static let modelLightName = "軽量モデル"
        static let modelLightDescription = "メモリ8GBのMacで動作"
        static let modelLightDetail = "簡単な質問応答に最適"
        static let modelLightMemory = "必要メモリ: 4GB"

        static let modelRecommendedName = "おすすめモデル"
        static let modelRecommendedDescription = "メモリ16GBのMacに最適"
        static let modelRecommendedDetail = "日常業務での利用に推奨"
        static let modelRecommendedMemory = "必要メモリ: 8GB"
        static let modelRecommendedBadge = "おすすめ"

        static let modelHighName = "高性能モデル"
        static let modelHighDescription = "メモリ32GB以上のMacで動作"
        static let modelHighDetail = "高度な分析・文書作成に最適"
        static let modelHighMemory = "必要メモリ: 20GB"

        static let downloadTitle = "モデルをダウンロード中"
        static let downloadProgress = "ダウンロード中..."
        static let downloadRemaining = "残り約%@"
        static let downloadCancel = "キャンセル"
        static let downloadRetry = "再試行"
        static let downloadComplete = "ダウンロード完了"

        static let clusterTitle = "接続設定"
        static let clusterDescription = "他のMacと連携してAIの処理能力を上げることができます"
        static let clusterStandalone = "このMacだけで使う"
        static let clusterStandaloneDescription = "1台のMacで動作します"
        static let clusterConnect = "他のMacと連携する"
        static let clusterConnectDescription = "複数のMacでAI処理を分散します"
        static let clusterScanning = "周辺のMacを探しています..."
        static let clusterFound = "%d台のMacが見つかりました"
        static let clusterNoneFound = "他のMacが見つかりませんでした"
        static let clusterConnectButton = "接続"

        static let completeTitle = "セットアップ完了"
        static let completeDescription = "準備が整いました。サーバーを起動しましょう。"
        static let startServer = "サーバーを起動"
        static let serverStarted = "サーバーが起動しました"
        static let skipStart = "あとで起動する"
        static let closeWindow = "閉じる"

        static let back = "戻る"
        static let next = "次へ"
    }

    // MARK: - Dashboard
    enum Dashboard {
        static let serverRunning = "サーバー稼働中"
        static let serverStopped = "サーバー停止中"
        static let serverStarting = "サーバー起動中..."
        static let serverError = "サーバーエラー"

        static let startButton = "サーバーを起動"
        static let stopButton = "サーバーを停止"

        static let statusComfortable = "快適"
        static let statusModerate = "混雑"
        static let statusBusy = "混み合っています"

        static let activeConnections = "接続中のアプリ"
        static let clusterNodes = "クラスターノード"
        static let tokensPerSecond = "トークン/秒"

        static let advancedMode = "上級者モード"
        static let simpleMode = "かんたんモード"
    }

    /// Prepended to every Chat API request (not shown as a bubble).
    enum Chat {
        static let systemPrompt = """
            あなたは整形外科外来のカルテ作成支援AIです。
            入力された診察情報をSOAP形式で整理してください。

            重要ルール：
            1. S（Subjective）は必ず作成する。
            2. Sには、患者が訴えた内容、受傷機転、発症時期、症状の経過、自覚症状を記載する。
            3. 入力文に「痛い」「力が入らない」「しびれる」「昨日から」「転んだ」「落ちた」などの患者の訴えや経過が含まれる場合、Sを「未記載」にしてはいけない。
            4. Sに入れるべき情報をO・A・Pだけに移してはいけない。
            5. Oには、医師が確認した身体所見、検査予定、画像所見、神経学的所見などの客観情報を記載する。
            6. Aには、診断・鑑別診断・病態評価を記載する。
            7. Pには、検査、処方、安静指導、再診指示、紹介方針、救急受診目安を記載する。
            8. 入力にない陰性所見は断定しない。「要確認」と記載する。
            9. 各項目は簡潔なカルテ文体で記載する。
            10. SOAPの4項目すべてを必ず出力する。

            Sは空欄・未記載にしない。入力文の冒頭にある症例説明や患者の主訴は、必ずSへ変換して記載する。

            技術的制約（必ず守る）：
            - 応答の先頭は「S：」から始める。「S：」より前に会話・挨拶・見出し・英語（Thinking、Analyze、Step 1 など）を書かない。
            - 出力は次の4ブロックのみ（行頭は半角 S O A P と全角コロン「：」。各ブロックの間は空行1行）。JSON、【S】【O】【P】形式、RH新規介入ブロックは使わない。絵文字・過度な装飾は使わない。

            出力形式：

            S：
            患者の訴え、受傷機転、発症時期、症状の経過、自覚症状を記載。

            O：
            身体所見、検査予定、画像所見、神経学的所見などを記載。

            A：
            診断または鑑別診断を記載。

            P：
            検査、処方、安静指導、再診・救急受診指示を記載。

            脚立転落など外傷後に腰痛と右大腿外側痛・下肢脱力が出た場合の鑑別の参考：腰椎圧迫骨折、横突起骨折、外傷後腰椎神経根障害、椎間板ヘルニア、骨盤・股関節周囲損傷。Aでは確定せず鑑別として列挙する。

            記載例（別シナリオ。ユーザー入力と同一症例にしないこと。同型でよい）：

            S：
            72歳女性。浴室で滑って転倒し左臀部を打撲。当日から左膝部痛が増強。歩行時痛あり。

            O：
            左膝圧痛あり。変形目立たず。単純XP予定。腫脹の程度は要確認。

            A：
            左膝部打撲。骨折、半月板損傷、側副靭帯損傷を鑑別。

            P：
            左膝XP。疼痛・増悪時は再受診。必要に応じてMRI検討。鎮痛薬・外用薬処方、安静指導。

            紹介状の全文は、ユーザーが「紹介状作成」と明示したときだけ別回答で出す（上記4行形式を崩さない通常応答では書かない）。
            """
    }

    // MARK: - Errors
    enum Errors {
        static let downloadFailed = "ダウンロードに失敗しました"
        static let downloadFailedDetail = "ネットワーク接続を確認して、もう一度お試しください。"
        static let serverStartFailed = "サーバーの起動に失敗しました"
        static let modelNotFound = "モデルファイルが見つかりません"
        static let binaryNotFound = "Hayabusa本体が見つかりません"
        static let clusterConnectionFailed = "接続に失敗しました"
    }

    // MARK: - Update
    enum Update {
        static let available = "新しいバージョンがあります"
        static let updateNow = "今すぐ更新"
        static let later = "あとで"
    }
}
