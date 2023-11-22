# PSOpenAI

OpenAI および Azure OpenAI Service を PowerShell から使用するためのラッパーモジュールです。  
ChatGPT, 音声の文字起こし, テキストからの画像生成などの OpenAI の提供する機能を使用できます。

**これはコミュニティベースの非公式モジュールであり OpenAI による提供ではありません**

+ OpenAI API について  
https://platform.openai.com/docs

+ Azure OpenAI Service について  
https://learn.microsoft.com/en-us/azure/cognitive-services/openai/overview

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

### 共通
+ [ConvertFrom-Token](/Docs/ConvertFrom-Token.md)
+ [ConvertTo-Token](/Docs/ConvertTo-Token.md)
+ [Get-CosineSimilarity](/Docs/Get-CosineSimilarity.md)

### OpenAI
+ [Enter-ChatGPT](/Docs/Enter-ChatGPT.md)
+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [New-ChatCompletionFunction](/Docs/New-ChatCompletionFunction.md)
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

### Azure OpenAI Service
+ [Get-AzureOpenAIModels](/Docs/Get-AzureOpenAIModels.md)
+ [Request-AzureAudioTranscription](/Docs/Request-AzureAudioTranscription.md)
+ [Request-AzureAudioTranslation](/Docs/Request-AzureAudioTranslation.md)
+ [Request-AzureChatCompletion](/Docs/Request-AzureChatCompletion.md)
+ [Request-AzureChatGPT](/Docs/Request-AZureChatCompletion.md)
+ [Request-AzureEmbeddings](/Docs/Request-AzureEmbeddings.md)
+ [Request-AzureImageGeneration](/Docs/Request-AzureImageGeneration.md)
+ [Request-AzureTextCompletion](/Docs/Request-AzureTextCompletion.md)

----
## 使い方

より詳細で複雑なシナリオの説明は [Docs](/Docs) および [Guides](/Guides) も参照してください。

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

### 関数呼び出し

関数呼び出し は Chat Completion API のオプション機能です。  
関数の定義をパラメータとしてGPTモデルに与えると、モデルが呼び出すべき関数の名前と引数を生成します。

詳しい使い方は[ガイド](/Guides/How_to_call_functions_with_ChatGPT.ipynb)を参照してください。

```PowerShell
$Message = 'Ping the Google Public DNS address three times and briefly report the results.'
$PingFunction = New-ChatCompletionFunction -Command 'Test-Connection' -IncludeParameters ('TargetName', 'Count')
$Answer = Request-ChatCompletion -Message $Message -Model gpt-3.5-turbo-0613 -Functions $PingFunction -InvokeFunctionOnCallMode Auto
```


### 一部が欠けた画像を復元する

一部がマスクされた画像を与え、推定された全体画像を出力させる例です。  
与える画像はマスク部分が完全透過された正方形のPNG画像で、4MB未満でなければなりません。

```PowerShell
Request-ImageEdit -Image 'C:\sunflower_masked.png' -Prompt 'sunflower' -OutFile 'C:\sunflower_restored.png' -Size 256x256
```

左が与えた画像、右が生成された画像です。

| Source                                       | Generated                                        |
| -------------------------------------------- | ------------------------------------------------ |
| ![masked](/Docs/images/sunflower_masked.png) | ![restored](/Docs/images/sunflower_restored.png) |


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

## Azure OpenAI Service
OpenAI ではなく Azure OpenAI Service を使用する場合は、AzureテナントにOpenAIリソースを作成し、APIキーとエンドポイントURLを取得する必要があります。詳細な手順はGuidesを参照してください。

+ [How to use with Azure OpenAI Service](Guides/How_to_use_with_Azure_OpenAI_Service.ipynb)

### Azure のサンプルコード
```powershell
$global:OPENAI_API_KEY = '<Put your api key here>'
$global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'

Request-AzureChatCompletion `
  -Message 'Hello Azure OpenAI Service.' `
  -Deployment 'gpt-35-turbo `
```

----
## 変更履歴

[CHANGELOG.ja.md](/CHANGELOG.ja.md)

----
## ライセンス
[MIT ライセンス](/LICENSE)
