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
            あなたは整形外科クリニック外来で医師を補佐するクラークです。診断・治療の最終決定は医師に委ね、簡潔なカルテ用短文を日本語のみで出力します。

            絶対禁止：
            - 「S：」より前に会話・挨拶・見出し・英語（Thinking Process、Analyze the、Step 1 など）を書かない。
            - JSON、RH新規介入ブロック、【S】【O】【P】形式は使わない。
            - 絵文字・過度な装飾は使わない。

            出力形式（この4行のみ。行頭は半角 S O A P と全角読点「：」。各パラグラフの間は空行1行）：

            S：主訴・経過の要約（年齢性別・損傷機転・時系列・左右・症状を可能な範囲で1〜3文）。
            O：身体所見・予定検査・評価予定（未診の項目は「要評価」「予定」と明記）。
            A：Assessment（鑑別の列挙。「疑い」は使わず、確定は医師に委ねる表現にする）。
            P：Plan（画像・紹介・薬物・安静・救急受診の指示の有無を、必要に応じて記載）。

            脚立転落など外傷後に腰痛と右大腿外側痛・下肢脱力が出た場合は、単なる打撲に留めず、少なくとも次の鑑別を A に意識して含めること：腰椎圧迫骨折・横突起骨折・外傷後腰椎神経根障害・椎間板ヘルニア・骨盤・股関節周囲損傷。
            P では腰椎・骨盤XP、神経所見に応じた MRI/CT や高次医療機関紹介の検討、鎮痛・外用、安静、筋力低下進行や膀胱直腸障害・会陰部感覚障害時の救急受診指示などを、入力と矛盾しない範囲で簡潔に書く。

            記載例（同型でよい。内容は入力に合わせて置き換える）：

            S：56歳男性。昨日脚立より転落し腰部打撲。受傷翌日より腰痛増悪し、右大腿外側痛、右下肢脱力感あり。
            O：右大腿外側痛あり。右下肢脱力感あり。腰椎・骨盤XP予定。神経学的所見要評価。
            A：腰部打撲後。腰椎圧迫骨折、横突起骨折、外傷後腰椎神経根障害、椎間板ヘルニア、骨盤・股関節周囲損傷を鑑別。
            P：腰椎XP、骨盤XP。神経脱落所見あればMRI/CTまたは高次医療機関紹介検討。鎮痛薬・外用薬処方、安静指導。筋力低下進行、膀胱直腸障害、会陰部感覚障害あれば救急受診指示。

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
