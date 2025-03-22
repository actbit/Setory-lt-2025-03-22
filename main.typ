#import "@preview/slydst:0.1.4": *
#import "@preview/codelst:2.0.2": *

#set text(lang: "ja")
#set text(font: ("Yu Gothic UI"))
#set text(size: 12pt)
#set par(spacing: 1em)

#show: slides.with(
  title: "C#アプリにLLMを組み込もう" ,
  subtitle: none,
  authors: "竹内一希",
  layout: "medium",
  ratio: 16/9,
)


= 自己紹介

== 自己紹介
- 名前
  - 竹内 一希
- 所属
  - 近畿大学工学部 電子情報工学科
  - 近畿大学 マイコン部
- 好きな技術
  - C\#
  - dotnet
  - コンパイラ技術
  - バックエンド
- SNS
  - X:\@\_actbit
  - GitHub:actbit

= はじめに

== はじめに

皆さんLLMって使ってますか？

LLMってPythonしか使えないって思っていませんか???

#align(center)[#text(size: 30pt)[*実はC\#からでも動かせるんです*]]

なのでその方法についてお話していきます！

= 使えるライブラリ

== 使えるライブラリ

以下のライブラリが使用できました
- LLamaSharp
- Aspireでコンテナ管理


== LLamaSharp

LLamaSharpは*llama.cpp*をC\#向けにwrapしたものです。なのでllama2,llama3ベースやQwen1.5ベースのライブラリが使用できます！

また、昨日2025/3/22にDeepSeekに対応してます！

実際に動かしていきます！

=== 開発環境の構築



==== dotnetのインストール


*Windows*
```bash
winget install Microsoft.DotNet.SDK.9
```

*Linux(Ubuntu系)* 
```bash
sudo apt update
sudo apt install dotnet-sdk-8.0
```


==== プロジェクトを作成

プロジェクト

```bash
dotnet new console LLamaSharpSample
```

プロジェクトに移動
```bash
cd LLamaSharpSample.csproj
```

#pagebreak()

==== ライブラリを導入

LLamaSharpを導入
```bash
dotnet add package LLamaSharp --version 0.23.0

```

*環境に応じて変更*

CPU
```bash
dotnet add package LLamaSharp.Backend.Cpu --version 0.23.0
```

Cuda12
```bash
dotnet add package LLamaSharp.Backend.Cuda12 --version 0.23.0
```

Vulkan
```bash
dotnet add package LLamaSharp.Backend.Vulkan --version 0.23.0
```

===== 実際のコード

*必要なnamespaceの読み込み*
```cs
using LLama;
using LLama.Common;
using LLama.Sampling;
using LLama.Transformers;
```


*コードでguffファイルの読み込み等を行います。*
```cs
var modelPath = Console.ReadLine().Trim('\"');
var parameters = new ModelParams(modelPath)
{
    GpuLayerCount = 15
};
using var model = LLamaWeights.LoadFromFile(parameters);
using var context = model.CreateContext(parameters);
var ex = new InteractiveExecutor(context); 
```

*chathistoryの作成*

```cs
ChatHistory chatHistory = new ChatHistory();
chatHistory.AddMessage(AuthorRole.System, "あなたは優秀なアシスタントです。どんなことでも的確に答える必要があり、間違えることは許されません。しかしながら、間違えてしまった場合には即座に認め訂正してください");
chatHistory.AddMessage(AuthorRole.User, "こんにちは");
chatHistory.AddMessage(AuthorRole.Assistant, "お手伝いが必要ですか？");
```

#pagebreak()
*コード生成時の設定を作成*

```cs
var inferenceParams = new InferenceParams
{
    SamplingPipeline = new DefaultSamplingPipeline
    {
        Temperature = 0.9f
    },
    AntiPrompts = new List<string> { "User:" },
    MaxTokens=-1
};
```

#pagebreak()

*ChatSessionの作成及び設定*
```cs
var chatSession = new ChatSession(ex, chatHistory);
chatSession.WithHistoryTransform(new PromptTemplateTransformer(model, withAssistant: true));
chatSession.WithOutputTransform(new LLamaTransforms.KeywordTextOutputStreamTransform(
    ["User:", "�"],
    redundancyLength: 5));

```
#pagebreak()

*実際にコードを生成させる*
```cs
while (true)
{
    Console.Write("User>");
    string prompt = Console.ReadLine();
    Console.Write("Assistant>");

    await foreach (var text in chatSession.ChatAsync(
        new ChatHistory.Message(AuthorRole.User, prompt), inferenceParams))
    {
        Console.ForegroundColor = ConsoleColor.White;
        Console.Write(text);
    }
}
```

#link("https://github.com/actbit/LLamaSharpProj")[全コード LLamaSharpProj]

== LLamaSharpを使って作成中の作品
AITDD開発ツール
- C\#にはドキュメントコメントという機能がある。ドキュメントコメントの機能によりコメント上にドキュメントと同様の情報を書くことができる。
- コードにはメソッドなどのパブリックメンバ定義＋多量のドキュメントコメント
- 実際にしてほしい挙動のテストコードを作成する
- LLMがコードの未実装部を実装
- BuildとTestを行い問題があればLLMにフィードバックし、再度コード生成を行う
  - 正しい挙動になるまで繰り返す

#pagebreak()

=== 実際には

以下のようなコードから
#text(size:10pt)[
```cs
/// <summary>
///  計算するためのクラス
/// </summary>
class calc
{
  /// <summary>
  /// <paramref name="n1"/> + <paramref name="n2"/>の計算を行います。
  /// </summary>
  /// <param name="n1">一つ目の数値</param>
  /// <param name="n2">二つ目の数値</param>
  /// <returns><paramref name="n1"/>+<paramref name="n2"/></returns>
  public int Sum(int n1,int n2)
  {
      throw new NotImplementedException();
  }
}

```
]
#pagebreak()

以下のようなコードを生成する
#text(size:10pt)[
```cs
/// <summary>
///  計算するためのクラス
/// </summary>
class calc
{
  /// <summary>
  /// <paramref name="n1"/> + <paramref name="n2"/>の計算を行います。
  /// </summary>
  /// <param name="n1">一つ目の数値</param>
  /// <param name="n2">二つ目の数値</param>
  /// <returns><paramref name="n1"/>+<paramref name="n2"/></returns>
  public int Sum(int n1,int n2)
  {
      return n1 + n2;
  }
}

```
]

一部のドキュメントをとても重視するSIのような開発では重宝できるのではないか？

#pagebreak()

実際のコード(実装途中は以下からご確認いただけます)

#link("https://github.com/actbit/CreateAutoProgram")[実装中のプロジェクト] 