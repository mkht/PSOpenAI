# 変更履歴
### 1.12.4
- プラットフォームがサポートしている場合、APIリクエストに HTTP/2 を使用します
- APIリクエストのリトライ間隔秒数を調整しました

### 1.12.3
- エラー処理の改善
- `code-davinci-edit-001` モデルを復活    
  以前使用できなくなっていたのはOpenAIの一時的な問題で、永続的な提供終了ではなかったようです

### 1.12.2
- `ConvertTo-Token` と `ConvertFrom-Token` が大幅に高速化しました (最大100倍程度)

### 1.12.1
- エラー処理の改善

### 1.12.0
- メッセージをパイプラインから直接入力できるようになりました (`Request-ChatGPT`)  
   ```PowerShell
   PS C:\> "人気のジャズ音楽を教えて" | Request-ChatGPT | Select-Object -ExpandProperty Answer
   人気のジャズ音楽には、以下のようなものがあります...
   ```
- `Request-Moderation` がコンテンツポリシー抵触を検出した際に警告メッセージを出力するようになりました。警告メッセージを非表示にしたい場合は`-WarningAction Ignore`を指定してください  
   ```PowerShell
   PS C:\> Request-Moderation -Text "これは有害なメッセージです" -WarningAction Ignore
   ```
- コマンドヘルプメッセージのリンクURLの間違いを修正

### 1.11.0
  - Azure OpenAI Service のための新しいコマンドの追加  
    + [Get-AzureOpenAIModels](/Docs/Get-AzureOpenAIModels.md)
    + [Get-AzureOpenAIDeployments](/Docs/Get-AzureOpenAIDeployments.md)
    + [New-AzureOpenAIDeployments](/Docs/New-AzureOpenAIDeployments.md)
    + [Remove-AzureOpenAIDeployments](/Docs/Remove-AzureOpenAIDeployments.md)
  - `-Stream`を使用した際にAPIキーがマスクされずにDebugストリームに出力されていた問題を修正
  - `-Stream`を使用した際にOpenAI組織IDがAPIリクエストに付与されない問題を修正
  - その他の軽微な修正

### 1.10.0
 - APIリクエストに組織IDを指定する`-Organization`パラメータを追加
 - デバッグメッセージと詳細メッセージの出力を強化
 - モデル名のタブ補完を可能にしました
 - 様々な改善

### 1.9.2
 - 新しいコマンド [Get-CosineSimilarity](/Docs/Get-CosineSimilarity.md) を追加。2つのベクトルのコサイン類似度を計算します  
   注意: パフォーマンスや精度を重視していない簡易的な実装です。運用環境では[Math.NET Numerics](https://numerics.mathdotnet.com/)など別の外部ライブラリを使用することをおすすめします

### 1.9.1
 - `ConvertTo-Token` および `ConvertFrom-Token` に複数のオブジェクトをパイプライン経由で入力した場合に予期しない動作をする問題を改善

### 1.9.0
 - 以下の関数で Azure OpenAI Service を試験的にサポートします
   + [Request-AzureChatGPT](/Docs/Request-AzureChatCompletion.md)
   + [Request-AzureEmbeddings](/Docs/Request-AzureEmbeddings.md)
   + [Request-AzureTextCompletion](/Docs/Request-AzureTextCompletion.md)

### 1.8.0
 - `Request-ChatGPT`に`-Name`オプションを追加  
   ChatGPTにユーザの名前を指示することができます  
   使用例.)
   ```PowerShell
   PS C:\> (Request-ChatGPT -Message 'Do you know my name?' -Name 'Samuel' -Model 'gpt-4-0314' -Temperature 0).Answer
   Yes, your name is Samuel.
   ```
 - `Request-ChatGPT`の`-Message`パラメータを必須ではなくオプションにしました。またパイプラインから入力可能にしました
 - `Request-ChatGPT`の`-RolePrompt`に複数の文字列を指定可能にしました  
 - `ConvertFrom-Token`に`-AsArray`を追加    
 - いくつかの細かい変更

### 1.7.0
 - 新しいコマンド [ConvertTo-Token](/Docs/ConvertTo-Token.md) と [ConvertFrom-Token](/Docs/ConvertFrom-Token.md) を追加。テキストとトークンIDを相互に変換できます。  
   ([microsoft/Tokenizer](https://github.com/microsoft/Tokenizer) ライブラリを使用しています)  
 - `-LogitBias` オプションを `Request-ChatGPT` と `Request-TextCompletion`に追加しました  

### 1.6.0
 - 新しい関数 [Request-Embeddings](/Docs/Request-Embeddings.md) を追加
 - **[重大な変更]**  
   API認証用キーの環境変数名を`OPENAI_TOKEN`から`OPENAI_API_KEY`に変更します。関数のパラメータ名も`-Token`から`-ApiKey`に変更します。  
   "Token"という単語が機械学習の分野で使われる用語と混同されやすいことと、OpenAIの公式リファレンスがこの名前を使用していることが理由です。  
   後方互換性を維持するため`OPENAI_TOKEN`および`-Token`も引き続き機能しますが、将来的に完全に廃止する可能性があるため使用しないでください。

### 1.5.0
 - `-MaxRetryCount` オプションを追加  
   APIリクエストが`429 (レート制限超過)` もしくは `5xx (サーバ側エラー)`で失敗した場合に、指定された最大回数までリトライします。リトライ間隔は最大128秒まで指数的に増加します(ジッター付き指数バックオフアルゴリズム)  
 - すでに廃止された以下の関数が完全に削除されます
   + `Request-CodeCompletion`
   + `Request-CodeEdit`
 - いくつかの軽微な修正

### 1.4.0
 - 新しいコマンド [Enter-ChatGPT](/Docs/Enter-ChatGPT.md) を追加。コンソール上でChatGPTとインタラクティブに対話ができます

### 1.3.0
 - `Request-ChatGPT` と `Request-TextCompletion` に `-Stream` オプションを追加
 - `code-davinci-edit-001`モデルが廃止されました(OpenAIによって)
 - AIモデルの廃止日が誤って表示される問題を修正

### 1.2.1
 - OpenAIがCodex APIを2023-03-23に廃止することを発表したため、以下の関数は今後動作しなくなる可能性があります。将来的にこれらの関数はモジュールから完全に削除される予定です
   + `Request-CodeCompletion`
   + `Request-CodeEdit`
 - OpenAIにより廃止、もしくは廃止予定のAIモデルを指定したリクエストを実行しようとした際に警告メッセージを出力するようにしました（リクエスト自体は引き続き実行されます）  
   現時点で警告メッセージが出力されるAIモデル：  
   + `code-davinci-001`
   + `code-davinci-002`
   + `code-cushman-001`
   + `code-cushman-002`

### 1.2.0
 - `Request-ChatGPT`, `Request-TextCompletion`, `Request-CodeCompletion`に新しいパラメータ`StopSequence`を追加   
   特定のワードが出てきた場合にそこで出力を打ち切ることができます  
   使用例.)
    ```PowerShell
    # This code generates only top 4 list.
    Request-TextCompletion -Prompt 'List of top 10 most populous countries' -StopSequence '5.'
    ```

### 1.1.2
 - macOS, Linux環境において`Request-AudioTranscription`関数の`Language`プロパティが意図しない値に設定される場合がある問題を修正
 - Windows PowerShell 5.1環境での細かい不具合を修正
 - テストコードの改善

### 1.1.0
 - エラー処理の改善
 - `Request-TextCompletion`関数における`MaxTokens`パラメータのデフォルト値を`2048`に変更します。以前のデフォルト値 `16` はほとんどの場合において実用的ではありませんでした。
 - `Request-CodeCompletion`関数を追加します。これは`Request-TextCompletion`と同じ処理を実行しますが、デフォルトで使用するAIモデルが`code-davinci-002`であるため、プログラムコードの生成により適しています。
 - 全ての公開された関数についてPesterテストコードを追加します。

### 1.0.0
 - Initial public release.
