# PSOpenAI

OpenAI API を PowerShell から使用するためのラッパーモジュールです。  
ChatGPT, 音声の文字起こし, テキストからの画像生成などの OpenAI の提供する機能を使用できます。

**これはコミュニティベースの非公式モジュールであり OpenAI による提供ではありません**

OpenAI API の公式ドキュメントはこちら    
https://platform.openai.com/docs


----
## 動作環境

+ Windows PowerShell 5.1
+ PowerShell 7 or higher
+ Windows, macOS or Linux

使用するには OpenAI のアカウントを作成し、以下URLから API キーを取得する必要があります。  
https://platform.openai.com/account/api-keys

----
## インストール

[PowerShell Gallery](https://www.powershellgallery.com/packages/PSOpenAI/) からインストールしてください。
```Powershell
Install-Module -Name PSOpenAI
```

----
## 使用できる関数

+ [ConvertFrom-Token](/Docs/ConvertFrom-Token.md)
+ [ConvertTo-Token](/Docs/ConvertTo-Token.md)
+ [Enter-ChatGPT](/Docs/Enter-ChatGPT.md)
+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [Request-AudioTranscription](/Docs/Request-AudioTranscription.md)
+ [Request-AudioTranslation](/Docs/Request-AudioTranslation.md)
+ [Request-ChatCompletion](/Docs/Request-ChatCompletion.md)
+ [Request-ChatGPT](/Docs/Request-ChatCompletion.md)
+ [Request-Embeddings](/Docs/Request-Embeddings.md)
+ [Request-ImageEdit](/Docs/Request-ImageEdit.md)
+ [Request-ImageGeneration](/Docs/Request-ImageGeneration.md)
+ [Request-ImageVariation](/Docs/Request-ImageVariation.md)
+ [Request-Moderation](/Docs/Request-Moderation.md)
+ [Request-TextCompletion](/Docs/Request-TextCompletion.md)
+ [Request-TextEdit](/Docs/Request-TextEdit.md)

----
## 使い方

より詳細で複雑なシナリオの説明は [Docs](/Docs) および [Examples](/Examples) も参照してください。

### ChatGPT (インタラクティブ)

コンソール上でインタラクティブにChatGPTと対話します。

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Enter-ChatGPT
```

![Interactive Chat](/Docs/images/InteractiveChat.gif)


### ChatGPT (スクリプティング)

ChatGPTに質問をして回答を得ます。

```PowerShell
$global:OPENAI_API_KEY = '<APIキーをここに貼り付ける>'
$Result = Request-ChatGPT -Message "自己紹介をしてください"
Write-Output $Result.Answer
```

このような出力が得られます。

```
はじめまして、私はAIアシスタントのGPT-3です。人工知能のプログラムであり、自然言語処理を使って... (以下省略)
```

> Tips:  
> デフォルトで使用するモデルはGPT-3.5です。  
> GPT-4を使用したい場合はモデル名を明示的に指定してください。    
> ```PowerShell
> Request-ChatGPT -Message "Who are you?" -Model "gpt-4"
> ```
> 

### 音声文字起こし

音声ファイルからテキストに文字起こしをさせます。

```PowerShell
$global:OPENAI_API_KEY = '<APIキーをここに貼り付ける>'
Request-AudioTranscription -File 'C:\SampleData\audio.mp3' -Format text
```

文字起こしの結果が出力されます。

```
Perhaps he made up to the party afterwards and took her and ...
```

### 画像生成

テキストで指示を与えると、AIがそれっぽい画像を生成します。

```PowerShell
$global:OPENAI_API_KEY = '<APIキーをここに貼り付ける>'
Request-ImageGeneration -Prompt 'かわいいライオンの子供' -Size 256x256 -OutFile 'C:\output\babylion.png'
```

このような画像が出力されます。

![Generated image](/Docs/images/babylion.png)


### 文脈を保ったままChatGPTと対話する

パイプライン経由で `Request-ChatGPT` に対話の履歴を与えることで、文脈を維持したまま複数の質問を行うことができます。

```PowerShell
PS C:\> $FirstQA = Request-ChatGPT -Message "アメリカの人口は？"
PS C:\> Write-Output $FirstQA.Answer

2021年現在、アメリカ合衆国の人口は約3億3300万人です。

PS C:\> $SecondQA = $FirstQA | Request-ChatGPT -Message "では日本は？"
PS C:\> Write-Output $SecondQA.Answer

2021年現在、日本の人口は約1億2600万人です。

PS C:\> $ThirdQA = $SecondQA | Request-ChatGPT -Message 'アメリカと日本を比較すると？'
PS C:\> Write-Output $ThirdQA.Answer

アメリカと日本の人口は、約3倍以上の開きがあります。
```

### ストリーム出力

デフォルトではサーバからのレスポンスがすべて完了してから結果がまとめて出力されるため、特に長い出力がある場合は、処理結果が得られるまでに時間がかかります。

`-Stream`オプションを使用するとChatGPTのWebUIのように結果はストリームとして逐次的に出力されるため、UXが改善する場合があります。現在`-Stream`オプションは`Request-ChatGPT`と`Request-TextCompletion`で使用可能です。

```PowerShell
Request-ChatGPT 'Describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![Stream](/Docs/images/StreamOutput.gif)


### 一部が欠けた画像を復元する

一部がマスクされた画像を与え、推定された全体画像を出力させる例です。  
与える画像はマスク部分が完全透過された正方形のPNG画像で、4MB未満でなければなりません。

```PowerShell
Request-ImageEdit -Image 'C:\sunflower_masked.png' -Prompt 'sunflower' -OutFile 'C:\sunflower_restored.png' -Size 256x256
```

左が与えた画像、右が生成された画像です。

|Source|Generated|
|----|----|
| ![masked](/Docs/images/sunflower_masked.png)  | ![restored](/Docs/images/sunflower_restored.png)   |


### モデレーション

テキストが OpenAI のコンテンツポリシ－に抵触しているかテストします。

> 注意：モデレーションAPI は OpenAI への入力もしくは OpenAI からの出力結果をテストする目的に限り使用できます

```PowerShell
PS C:\> $Result = Request-Moderation -Text "気に入らない人間を皆殺しにしてやる"
PS C:\> $Result.results.categories

# True となっているカテゴリに抵触していることを示します
sexual           : False
hate             : True
violence         : True
self-harm        : False
sexual/minors    : False
hate/threatening : False
violence/graphic : False
```

----
## API キーについて
ほぼ全ての関数で認証のための API キーが必要です.  
OpenAI のアカウントを作成し、以下URLから API キーを取得する必要があります。  
https://platform.openai.com/account/api-keys

関数に API キーを指定するには3種類の方法があります。

### 方法 1: 環境変数 `OPENAI_API_KEY`. (推奨)
API キーを環境変数 `OPENAI_API_KEY`に設定します。関数呼び出し時に暗黙的に使用されます。  

```PowerShell
PS C:> $env:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```

### 方法 2: Global 変数 `OPENAI_API_KEY`
API キーを`$global:OPENAI_API_KEY`変数に設定します。関数呼び出し時に暗黙的に使用されます。

```PowerShell
PS C:> $global:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```

### 方法 3: 名前付きパラメータ
各関数の `ApiKey` パラメータに API キーを指定します。すべての関数呼び出しに都度指定する必要があります。  

```PowerShell
PS C:> Request-ChatGPT -Message "Who are you?" -ApiKey '<Put your API key here.>'
```


----
## 変更履歴
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

----
## ライセンス
[MIT ライセンス](/LICENSE)
