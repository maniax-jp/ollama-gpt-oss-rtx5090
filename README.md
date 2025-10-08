# Ollama GPT-OSS-20B with RTX 5090 (Blackwell) Docker Setup

このリポジトリは、NVIDIA RTX 5090でOllama 0.12.3とgpt-oss-20bモデル（MXFP4量子化）をローカル実行するためのDocker環境を提供します。

## システム要件

### ハードウェア
- **GPU**: NVIDIA GeForce RTX 5090 (32GB VRAM)
- **RAM**: 16GB以上推奨
- **ストレージ**: 50GB以上の空き容量

### ソフトウェア
- **OS**: Ubuntu 22.04/24.04 または Windows 11 (WSL2)
- **Docker**: 24.0.0以降
- **NVIDIA Driver**: 565.xx以降（RTX 5090対応）
- **NVIDIA Container Toolkit**: 最新版
- **CUDA**: 12.8以降（ドライバーに含まれる）

## 事前準備

### 1. NVIDIAドライバーのインストール

```bash
# Ubuntu
sudo apt update
sudo apt install nvidia-driver-565
sudo reboot

# インストール確認
nvidia-smi
```

### 2. Docker & NVIDIA Container Toolkitのインストール

```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# 動作確認
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <your-repo-url>
cd chatbot-gpt-oss
```

### 2. Dockerイメージのビルド

```bash
docker-compose build
```

### 3. コンテナの起動

```bash
docker-compose up -d
```

### 4. gpt-oss-20bモデルのダウンロード

```bash
# セットアップスクリプトの実行
bash setup-model.sh

# または手動で実行
docker exec -it ollama-gpt-oss ollama pull gpt-oss:20b
```

## 使用方法

### 1. Webインターフェース（推奨）

ブラウザで以下のURLにアクセス：

```
http://localhost:3000
```

Open WebUIが起動し、ChatGPTライクなUIで対話できます。
- 認証なしで利用可能（デフォルト設定）
- モデル選択で `gpt-oss:20b` を選択
- リアルタイムストリーミング応答

### 2. コマンドライン

```bash
# インタラクティブモード
docker exec -it ollama-gpt-oss ollama run gpt-oss:20b

# API経由
curl http://localhost:11434/api/generate -d '{
  "model": "gpt-oss:20b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Python SDK経由

```python
import ollama

# クライアント初期化
client = ollama.Client(host='http://localhost:11434')

# 推論実行
response = client.generate(
    model='gpt-oss:20b',
    prompt='Explain quantum computing in simple terms.'
)

print(response['response'])
```

### OpenAI互換API

```python
from openai import OpenAI

# Ollama経由でOpenAI互換APIを使用
client = OpenAI(
    base_url='http://localhost:11434/v1',
    api_key='ollama'  # ダミーキー
)

response = client.chat.completions.create(
    model='gpt-oss:20b',
    messages=[
        {'role': 'user', 'content': 'What is the capital of France?'}
    ]
)

print(response.choices[0].message.content)
```

## パフォーマンス期待値

### RTX 5090での推論速度
- **gpt-oss:20b (MXFP4)**: 約256 tokens/秒
- **メモリ使用量**: 約16GB VRAM

### 注意事項
⚠️ **MXFP4のGPUアクセラレーション問題**

現時点（Ollama 0.12.3）では、MXFP4量子化モデルのGPUネイティブ実行に制限があります：
- GPUはKVキャッシュのみに使用され、主な計算はCPUで実行される可能性
- GPU使用率が低い（1%程度）場合、CPUバウンドになっている

**回避策**:
1. 標準量子化モデルの使用（推奨）:
   ```bash
   docker exec -it ollama-gpt-oss ollama pull llama3.3:70b-instruct-q4_K_M
   ```

2. 将来のOllamaアップデートを待つ

## トラブルシューティング

### GPU認識されない場合

```bash
# NVIDIAランタイムの確認
docker info | grep -i runtime

# GPUテスト
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

### メモリ不足エラー

```bash
# docker-compose.ymlで環境変数を調整
OLLAMA_GPU_OVERHEAD=4096  # 値を増やす
OLLAMA_MAX_LOADED_MODELS=1
```

### ログの確認

```bash
# コンテナログ
docker-compose logs -f ollama

# Ollamaサービスログ
docker exec ollama-gpt-oss ollama ps
```

## 便利なコマンド

```bash
# コンテナの停止
docker-compose down

# モデルリストの確認
docker exec ollama-gpt-oss ollama list

# モデルの削除
docker exec ollama-gpt-oss ollama rm gpt-oss:20b

# リソース使用状況の監視
watch -n 1 nvidia-smi
```

## 参考リンク

- [Ollama公式ドキュメント](https://ollama.com/)
- [gpt-ossモデル情報](https://ollama.com/library/gpt-oss)
- [NVIDIA RTX 5090仕様](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/)
- [Docker Composeドキュメント](https://docs.docker.com/compose/)

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
gpt-oss-20bモデルはApache 2.0ライセンスです。
