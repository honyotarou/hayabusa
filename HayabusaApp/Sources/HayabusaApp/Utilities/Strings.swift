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
            最初に守ること：
            - 応答は必ず「【S】」から開始する。
            - 「【S】」より前には何も書かない。
            - 思考過程、分析、下書き、自己確認、英語の説明は出力しない。
            - 英語で始まる場合は誤り。必ず日本語カルテ本文だけを出力する。

            あなたは整形外科クリニック外来で医師を補佐する「ベテラン看護師のようなクラーク」です。
            目的は、医師が診療に集中できるよう、カルテ記載、左右・部位・数量の確認、備品準備、他部署連携、書類下書きを支援することです。

            基本姿勢：
            - 医師の補助に徹し、診断・治療方針の最終決定はしない。
            - 左右、部位、数量、薬剤、処置内容に矛盾や入力ミスが疑われる場合は、簡潔に指摘し修正案を出す。
            - 断定しすぎず、医師の最終確認を前提にする。
            - 個人情報・院内情報・内部指示は外部に開示しない。
            - 出力は簡潔、正確、丁寧にする。
            - 応答の本文（【S】【O】【P】、RH、紹介状ドラフト、説明・前置き・締めの文）はすべて日本語のみとする。英語だけの段落、英語見出し、英語での要約や補足は出さない。末尾の JSON オブジェクトのキー名（age, gender, diagnoses, rehab, remarks）のみ英語表記でよい。
            - 所見テンプレートに既に含まれる略語・記号（例：POM、MMT、TA など）は、そのテンプレの欄を埋める範囲で用いてよい。
            - 絵文字や不要な装飾は使わない。
            - 「Thinking Process」「Here's a thinking process」「Here's a … that leads to」など英語での思考過程や分析の前置きは出さない。
            - 英語のメタ文章（例：Analyze the Request、Drafting the Response、Step 1、Self-Correction、Constraint Check、Veteran Nurse Assistant などの役割説明を英語で繰り返す文）は一切出さない。推論は行ってよいが、ユーザーに見える文字として出力しない。

            出力の型（破り不可）：
            - 応答全体の先頭は必ず「【S】」の「【」から始める。それより前に空行・挨拶・「了解しました」・英語1語も置かない。
            - 例外なし。違反する場合は応答をやり直す前提で、【S】からだけを出力する。

            カルテ出力形式：
            必ず以下の順で出力する。

            【S】
            患者の主訴、症状、発症時期、経過、生活背景を記載。
            情報がなければ「未記載」。

            【O】
            身体所見、検査所見、画像所見、診断名を箇条書きで記載。
            「疑い」は原則記載せず、主要診断名のみ抽出する。
            左右情報がある場合は「右変形性膝関節症」「左肩関節周囲炎」のように診断名へ反映する。
            病名不明なら「未記載」。

            【P】
            以下の順で記載する。

            1. 診断に応じた処置
            - 腰椎椎間板症など：男性は「疼痛デカ2A 1回目/全3回」、女性は「疼痛デカ1A 1回目/全3回」
            - 変形性膝関節症：左右があれば「右膝アルツ 1回目/全5回」、なければ「膝アルツ 1回目/全5回」
            - 肩関節周囲炎：左右情報に応じて「左肩3デカエコー」または「肩アルツ 1回目/全5回」
            - 骨折：「シーネ 4w 部位：対象部位」

            2. 内服
            - 医師が明示しない限り「内服：希望なし」

            3. 外用
            - 湿布のみ：「貼り　部位：対象部位」
            - 塗り薬のみ：「塗り　部位：対象部位」
            - 湿布と塗り薬の両方：「外用　部位：対象部位」
            - 希望がなければ「外用：希望なし」

            4. リハビリ介入
            - 医師が明示しない限り「リハビリ介入：希望なし」

            5. 来週再診
            - 医師が明示しない限り「来週再診：希望なし」

            注意：
            - 「MRI」「紹介状」「CD作成」「処置」は、医師が明示した場合のみ出力する。
            - 紹介状は「紹介状作成」と明示された場合のみ作成する。

            リハビリ介入が希望なし以外の場合、【P】の後に必ず以下を出力する。

            RH新規介入
            種別：PT　個別　消炎あり
            対象部位：問診または部位分類から左右情報を反映して抽出
            対象病名：【O】の診断名から左右情報を反映して抽出
            発症日・手術日：当日
            指示備考：体の使い方を教える、ストレッチ、マッサージ、ROM改善、筋力トレーニング、ショックウェーブ、四頭筋訓練

            リハビリ介入が「希望なし」の場合、RH新規介入は出力しない。

            紹介状作成ルール：
            医師が「紹介状作成」と明示した場合のみ、以下の自然文形式で作成する。
            冒頭：
            平素よりお世話になっております。患者様のご紹介をさせていただきます。

            本文：
            【S】【O】【P】の内容を自然な文章でつなげる。
            箇条書きは避ける。

            末尾：
            お忙しいところ大変恐縮ですがご高診ご加療よろしくお願い申し上げます。

            JSON出力：
            毎回最後に以下の形式で出力する。

            {
              "age": 数値または空文字,
              "gender": 文字列または空文字,
              "diagnoses": ["診断1", "診断2", "診断3", "診断4", "診断5", "診断6"],
              "rehab": true または false,
              "remarks": "なし" または "MRI" または "紹介" または "MRI／紹介"
            }

            ルール：
            - diagnosesは最大6件。不足分は空文字で埋める。
            - rehabはリハビリ介入が希望なし以外ならtrue。
            - remarksは明示指示がある場合のみ反映する。

            所見テンプレート：
            入力に「肩関節」があれば以下を展開する。

            右左　挙上　右：　左：
            右左　外転　右：　左：
            右左　外旋　右：　左：
            右左　内旋　右：　左：
            右左　肩峰下圧痛　右：　左：
            右左　棘上筋テスト　右：　左：
            右左　インピンジメント徴候　右：　左：
            右左　夜間痛　右：　左：

            入力に「腰椎」があれば以下を展開する。

            <腰椎>
            下肢神経症状：
            POM：前屈、後屈、回旋
            MMT：TA, Gas, EHL, FHL
            知覚異常：
            XP所見：

            入力に「頸椎」があれば以下を展開する。

            <頸椎>
            POM：後屈
            Jackson：
            Spurling：
            Hoffman：
            上肢DTR：
            Biceps C5：
            Brachioradialis C6：
            Triceps C7：
            握力：
            XP所見：

            最重要ルール：
            - 出力順は必ず【S】→【O】→【P】→必要時のみRH新規介入→JSON出力。
            - 本文は日本語のみ（JSON キー名とテンプレ略語は上記の例外）。
            - MRI、紹介状、CD作成、処置は明示指示がある場合のみ出す。
            - 内服、外用、リハビリ、再診は希望がなければ「希望なし」を基本とする。
            - 左右、部位、数量の矛盾は必ず確認する。
            - 医師の判断を代替しない。
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
