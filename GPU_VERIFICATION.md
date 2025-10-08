# MXFP4 GPU ネイティブ実行の検証結果

## 検証日時
2025-10-08

## 検証環境
- **GPU**: NVIDIA GeForce RTX 5090 (32GB VRAM)
- **CUDA**: 12.9
- **Driver**: 576.88
- **Ollama**: 0.12.3
- **モデル**: gpt-oss:20b (MXFP4量子化)

## 検証結果: ✅ GPU ネイティブ実行を確認

### 1. モデルローディング情報

```
ollama ps
NAME           ID              SIZE     PROCESSOR    CONTEXT    UNTIL
gpt-oss:20b    aa4295ac10c3    14 GB    100% GPU     8192       4 minutes from now
```

**確認事項:**
- ✅ `PROCESSOR: 100% GPU` - 全レイヤーがGPU上で実行
- ✅ サイズ: 14GB (MXFP4量子化により圧縮)

### 2. レイヤーオフロード状況

Ollamaログより:
```
offloading 24 repeating layers to GPU
offloading output layer to GPU
offloaded 25/25 layers to GPU
```

**確認事項:**
- ✅ 全25レイヤー中25レイヤーがGPUにオフロード
- ✅ モデルウェイト: 11.8 GiB (CUDA0デバイス)
- ✅ KVキャッシュ: 300.0 MiB (CUDA0デバイス)
- ✅ 計算グラフ: 121.8 MiB (CUDA0デバイス)

### 3. GPU使用率（推論実行中）

リアルタイムモニタリング結果:

| サンプル | GPU使用率 | メモリ使用率 | VRAM使用量 | 電力消費 |
|---------|----------|------------|-----------|---------|
| 1 | 84% | 59% | 15.4 GB | 394.2 W |
| 2 | 85% | 59% | 15.5 GB | 390.5 W |
| 3 | 84% | 59% | 15.5 GB | 393.0 W |
| 4 | 84% | 59% | 15.5 GB | 396.6 W |
| 5 | 84% | 58% | 15.5 GB | 398.3 W |
| 6 | 86% | 59% | 15.5 GB | 399.5 W |
| 7 | 84% | 58% | 15.4 GB | 399.0 W |
| 8 | 85% | 58% | 15.4 GB | 398.1 W |
| 9 | 84% | 58% | 15.4 GB | 401.2 W |
| 10 | 85% | 59% | 15.4 GB | 405.2 W |

**平均値:**
- GPU使用率: **84.5%**
- メモリ使用率: **58.6%**
- VRAM使用量: **15.4 GB**
- 電力消費: **397.3 W**

### 4. CUDA情報

```
Device 0: NVIDIA GeForce RTX 5090
Compute Capability: 12.0
VMM: yes
CUDA Backend: /usr/lib/ollama/cuda_v12/libggml-cuda.so
Supported Architectures: 500,600,610,700,750,800,860,870,890,900,1200
```

**確認事項:**
- ✅ Compute Capability 12.0 (Blackwell世代)
- ✅ CUDA 12対応バックエンド
- ✅ VMM (Virtual Memory Management) 有効

## MXFP4のGPU実行に関する考察

### 実行確認のポイント

1. **100% GPU処理**: `ollama ps`で`PROCESSOR: 100% GPU`と表示
2. **高GPU使用率**: 推論中に84-86%の一貫したGPU使用率
3. **全レイヤーオフロード**: 25/25レイヤーがGPUに配置
4. **高電力消費**: 平均397W（アイドル時30Wと比較）

### MXFP4量子化の効果

| 項目 | 値 |
|-----|-----|
| オリジナルサイズ（推定） | ~40GB (FP16) |
| MXFP4圧縮後 | ~14GB |
| 圧縮率 | **約65%削減** |
| アクティブVRAM使用量 | 15.4GB |
| 利用可能VRAM残量 | 17.2GB |

### CPUバウンド問題について

以前報告されていた「MXFP4モデルがCPUで実行される」問題は、以下の環境では**発生していない**：

- ✅ Ollama 0.12.3
- ✅ RTX 5090 (Compute Capability 12.0)
- ✅ CUDA 12.9
- ✅ 適切なドライバー (576.88)

## 検証コマンド

### モデルステータス確認
```bash
docker exec ollama-gpt-oss ollama ps
```

### GPU使用率モニタリング
```bash
docker exec ollama-gpt-oss nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,power.draw --format=csv
```

### デバッグログ確認
```bash
docker logs ollama-gpt-oss 2>&1 | grep -i "gpu\|cuda\|layer"
```

### リアルタイム推論＋モニタリング
```bash
# ターミナル1: 推論実行
docker exec -it ollama-gpt-oss ollama run gpt-oss:20b

# ターミナル2: GPU監視
watch -n 1 'docker exec ollama-gpt-oss nvidia-smi'
```

## 結論

✅ **MXFP4量子化されたgpt-oss:20bモデルは、RTX 5090上でGPUネイティブ実行されている**

- 全計算レイヤーがGPU上で実行
- 高いGPU使用率を維持（84-86%）
- VRAM効率的な使用（32GBのうち15.4GB使用）
- CPUバウンド問題は発生していない
- Ollama 0.12.3はMXFP4のGPU実行をサポート

## 参考情報

- MXFP4はBlackwell世代GPU（RTX 5090等）で最適化されたフォーマット
- Ollama 0.11.0以降でMXFP4ネイティブサポートが追加された
- RTX 5090のCompute Capability 12.0が必要
- CUDA 12.8以降が推奨
