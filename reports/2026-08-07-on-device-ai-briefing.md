# On-device AI 동향 브리핑 — 2026-08-07
> 커버 기간: 2026-07-08 ~ 2026-08-07
> **초회 baseline 리포트** — 이전 리포트가 없어 Δ(증감) 수치는 다음 회차부터 표기됩니다. 이번 회차의 HF 다운로드·GitHub star는 `reports/data/2026-08-07-metrics.json`에 기준선으로 기록했습니다.

## 🎯 Executive Summary

**1. 메모리 크런치가 온디바이스 AI를 볼륨존에서 밀어내고 있다 — 그런데 탈출구가 학계에서 먼저 나왔다.**
Q2 스마트폰 출하가 13년 만의 최저(YoY -11%)로 떨어졌고 LPDDR5X 계약가는 QoQ +78~83% 폭등했다. 동시에 Gemini Nano 4의 실질 요건은 **12GB RAM**으로 굳어졌다 — A/M 시리즈에서 "AI 폰"을 만들 수 없다는 뜻이다. 반면 같은 기간 ScaleQ-1.58이 **사전학습 없이 PTQ만으로 1.58-bit ternary 양자화**를 성립시켰고(Qwen3-4B에서 선행 BitNet 대비 +8.97%p), HuggingFace에서는 1bit/2bit/ternary 모델이 동시다발로 트렌딩에 올랐다.
**근거:** [Q2 출하 YoY -11% · 13년 만의 최저 (Counterpoint)](https://counterpointresearch.com/en/insights/global-smartphone-shipments-q2-2026) · [DRAM 계약가 QoQ +70~83% (Telecompaper)](https://www.telecompaper.com/news/dram-prices-surge-70-83-in-q2-2026-deepening-smartphone-industry-squeeze--1571206) · [ScaleQ-1.58 / AYOT — PTQ만으로 1.58-bit, Qwen3-4B +8.97%p (arXiv:2608.01078)](https://arxiv.org/abs/2608.01078) · Gemini Nano 4 요건 12GB RAM → 본 리포트 §3 업계 동향

**2. "NPU를 쓸 수 있다"는 더 이상 차별점이 아니다 — 오픈소스가 무료로 따라잡았고, 학계는 NPU 우위론 자체를 부정했다.**
alibaba/MNN 3.6.1이 **Hexagon NPU 백엔드를 정식 탑재하고 Snapdragon CPU 대비 7.9×를 공표**했고, llama.cpp도 Hexagon 백엔드를 재작업(eager L2 flush → lazy dirty-bit)했으며 Qualcomm은 자사 GenieX 런타임의 공식 백엔드로 llama.cpp를 채택했다. 동시에 학계에서는 **memory-bound decode 구간에서 CPU가 NPU보다 빠르다**는 실측(arXiv:2607.05475)과, 프레임워크 설정만 바꿔도 NPU 에너지를 54.8% 절감할 수 있다는 결과가 나왔다.
**근거:** [alibaba/MNN 3.6.1 — Hexagon NPU 백엔드, CPU 대비 7.9× 주장 (⭐15,825)](https://github.com/alibaba/MNN) · [llama.cpp Snapdragon 백엔드 문서](https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/snapdragon/README.md) · [Qualcomm GenieX — llama.cpp를 공식 백엔드로 채택](https://github.com/qualcomm/geniex) · [Is Your NPU Ready for LLMs? — decode 구간 CPU 우세, 설정만으로 에너지 54.8% 절감 (arXiv:2607.05475)](https://arxiv.org/abs/2607.05475)

**3. 경쟁 축이 "AI 기능 개수"에서 "온디바이스 개인 메모리 + 에이전트 오케스트레이션"으로 넘어갔고, OPPO가 먼저 움직였다.**
OPPO가 7/27 **업계 최초로 에이전트 오케스트레이션 계층 자체를 단말에 내린** Xiaobu Next 베타를 공개했다 — 온디바이스 全域记忆(full-domain memory) 기반 상시 센싱 + 선제적 행동, 시스템 기능 100종 이상 통합. 같은 기간 GitHub에서는 폰을 직접 조작하는 온디바이스 에이전트(OmniBot ⭐1,984 / PhoneClaw ⭐1,201 / PokeClaw ⭐999)가 반년 내 동시 등장했다.
**근거:** [OPPO Xiaobu Next 베타 공개 (2026-07-27)](https://www.thetechoutlook.com/new-release/software-apps/oppo-launches-its-xiaobu-next-project-first-round-of-recruitment-officially-started-in-china/) · [대상 기기 및 기능 범위](https://www.androidpure.com/oppo-xiaobu-next-eligible-devices/) · [omnimind-ai/OmniBot ⭐1,984](https://github.com/omnimind-ai/OmniBot) · [kellyvv/PhoneClaw ⭐1,201](https://github.com/kellyvv/PhoneClaw) · [agents-io/PokeClaw ⭐999](https://github.com/agents-io/PokeClaw)

## 1. 모델 최적화

> 커버 기간: 2026-07-08 ~ 2026-08-07 / 초회 baseline 리포트 (중복 회피 대상 없음)
> 이번 기간 핵심: **1.58-bit PTQ가 "pretraining 없이" 실용 영역에 진입**했고, on-device foundation model이 **NPU 배포 바이너리까지 동봉**해 출시되기 시작했다.

---

### ▪ ScaleQ-1.58 / AYOT — reasoning LLM의 1.58-bit Post-Training Quantization
- **무엇**: 모델 자신의 reasoning trace(사고 과정)를 calibration 컨텍스트로 사용해, 별도 사전학습 없이 PTQ만으로 ternary(1.58-bit) 양자화를 성립시킨 프레임워크. 지금까지 1-bit 계열은 "처음부터 1-bit로 학습(BitNet)"해야만 성능이 나온다는 것이 통념이었는데, 그 전제를 깬 결과다.
- **수치**: 1.58-bit ternary / calibration 토큰 **4M** (BitNet b1.58 대비 약 **1,000,000배 적음**) / Qwen3-4B에서 선행 BitNet 대비 **+8.97%p 절대 개선** / Qwen3-1.7B는 BitNet b1.58 2B4T 대비 **90.52%** 성능 / 최대 235B까지 검증. 수학·코딩·과학추론·commonsense·생성 전반.
- **성숙도**: 논문 단계 (arXiv 2026-08-02, Intel Labs 계열 저자). 코드는 "will be available"로 예고, 제출 시점 미공개 → **오픈소스 구현 아직 없음 [미확인]**.
- 출처: https://arxiv.org/abs/2608.01078

---

### ▪ Opt.Gear — NPU 배포 바이너리까지 동봉된 on-device foundation model 패밀리
- **무엇**: 1M / 270M / 1B 3종 dense 모델. Convolutional KV-gated mixer + local-global attention 하이브리드로 long-context KV cache 증가를 억제한 구조. 국내 스타트업(OptAI) 결과물.
- **수치**: context 64K / 동급 규모 대비 NPU에서 prefill·decode **최대 4.9배** / 2T 후보 코퍼스에서 **0.5T 토큰만 선별 학습**, knowledge distillation 미사용 / Opt.Gear-1M은 STM32H747I-DISCO(ARM Cortex-M7 MCU)에서 W4A32로 **20 TPS**.
- **성숙도**: **오픈 웨이트 + 배포 바이너리 공개** (ONNX / Qualcomm NPU / Apple ANE). 라이선스는 CC BY-NC-ND 4.0 → **상용 적용 불가, 평가·벤치마킹 용도만 가능**.
- 출처: https://arxiv.org/abs/2608.01034

---

- **무엇**: MXFP4가 블록마다 특성이 다른데 단일 스케일링 방식을 강제한다는 점을 지적하고, 블록별로 precision-recovery 기법과 operand별 표현을 적응적으로 선택하는 포맷/하드웨어 co-design.
- **수치**: commonsense reasoning에서 MXFP4 정확도 손실의 **83%** 제거, MMLU에서 **82%** 제거 / NVFP4 대비로는 손실의 43%·27% 회복 / 멀티모달(Gemma-4 12B)에서 **FP16 정확도의 96%** 유지 / 3B~70B 검증 / **22nm FD-SOI 가속기 프로토타입**에서 baseline MXFP4 대비 시스템 에너지 오버헤드 **약 1%**.
- **성숙도**: 논문 + 실리콘 프로토타입 단계. 상용 IP 아님.
- 출처: https://arxiv.org/abs/2608.03867

---

### ▪ Prox — 학습 없이 FFN activation sparsity로 decode 2배
- **무엇**: FFN 중간 상태의 정확한 값 대신 **크기 순위(magnitude ranking)** 만 맞으면 된다는 관찰에서 출발. 1단계에서 입력 sparsity와 양자화된 proxy weight로 중요 채널을 싸게 추정하고, 2단계에서 선택된 채널만 정확히 계산하는 2-stage sparse execution.
- **수치**: FFN sparsity **70%**에서 end-to-end decoding **최대 1.99배** / **6개 모델 패밀리, 10개 LLM**에서 검증 / **training-free** / quantization 및 sparse attention과 **병용 가능**. 측정 하드웨어는 초록에 미명시 [미확인].
- **성숙도**: 논문 단계 (2026-07-30). 코드 공개 여부 **[미확인]**.
- 출처: https://arxiv.org/abs/2607.27591

---

### ▪ PolyQ — edge CPU용 fractional-bit quantization 컴파일러 co-design (ICCAD 2026)
- **무엇**: 채널마다 {2,3,4,8,16} 중 다른 bit-width를 할당하는 "분수 비트" 양자화를, 컴파일 타임에 채널을 재배열·클러스터링해 bit-homogeneous 블록으로 묶고 SIMD/LUT 커널을 생성함으로써 런타임 오버헤드 없이 실현.
- **수치**: 3-bit 타깃에서 기존 기법 대비 perplexity **2.4~32.1% 개선** / LUT 최적화 백엔드 대비 에너지 오버헤드 **2% 미만** / activation reorder 트래픽 **최대 70.8% 감소** / Falcon-H1-3B, Llama2-13B, Qwen3-32B 검증 / 워크스테이션·랩탑·**모바일** 3종 CPU 실측.
- **성숙도**: **ICCAD 2026 accepted** (2026-07-16). 코드 공개 여부 [미확인].
- 출처: https://arxiv.org/abs/2607.14618

---

### ⚠️ 수집 한계
- **ScaleQ-1.58 / Prox / PolyQ**: 초록 기준 정리. 코드 공개 여부와 측정 하드웨어 상세는 본문 미확인 — 전문 확인 필요.
- **Prox의 1.99배 decode 가속**: 측정 하드웨어(CPU/GPU/모바일) 초록에 미명시. 모바일 실측치 아님을 전제로 해석할 것.
- 커버 기간 경계 밖이라 제외했으나 참고 가치가 있는 항목:
  - *Is Your NPU Ready for LLMs?* (arXiv 2607.05475, 2026-07-06 — 2일 차이로 기간 밖). 모바일 LLM 추론에서 프레임워크별 NPU 성능 격차 최대 10배, 설정 최적화만으로 NPU 에너지 **최대 54.8% 절감**. 다음 리포트에서 재검토 권고.
  - *Qwen3.5-0.8B* (2026-03-02 공개, 기간 밖): Gated DeltaNet 하이브리드 + 262K context + 네이티브 멀티모달. 기간 밖이라 신규 항목으로 다루지 않음.
- **검토했으나 우선순위에서 탈락한 항목** (참고): NOVA-KV(2-bit KV cache VQ, arXiv 2608.04074), WIDE(token-level dynamic width pruning, 1.68×/1.55× e2e, arXiv 2607.28418), BitNet-embedding-0.6B/270M(2026-07-20 HF 공개, MIT, CPU 1.42~2.28× — 임베딩 전용이라 별도 도메인), AnchorKV(20× KV 압축이나 70B 스케일 검증 중심으로 데이터센터 성격).
- 상용 벤더(Qualcomm/MediaTek/Apple)의 비공개 최적화 스택 관련 1차 자료는 접근 불가. 공개 논문·릴리스 기준으로만 작성.
## 2. Inference 최적화

> 커버 기간: 2026-07-08 ~ 2026-08-07 (초회 baseline) · 담당 도메인: Runtime & Serving

### ▪ llama.cpp Hexagon NPU 백엔드 재작업 (L2 cache lazy flush + tiled activation)
- **무엇**: Snapdragon Hexagon NPU 백엔드에서 연산마다 하던 eager L2 flush를 dirty-bit 기반 lazy flush로 교체하고, MUL_MAT에 tiled activation 처리를 도입 (2026년 7월 중순 머지).
- **수치**: "measurable performance gains across supported Hexagon NPU devices" — [구체 수치 미공개]
- **성숙도**: 오픈소스 구현 존재 (master 브랜치, `docs/backend/hexagon`). 더불어 Qualcomm이 2026-06 공개한 GenieX 런타임이 llama.cpp(ggml-hexagon) + QAIRT 두 백엔드를 공식 플러그인으로 채택 → 벤더 지원 경로로 승격 중.
- 출처: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/snapdragon/README.md , https://buttondown.com/weekly-project-news/archive/weekly-github-report-for-llamacpp-july-13-2026-4011/ , https://github.com/qualcomm/geniex

### ▪ Arm KleidiAI v1.29.0 — SME2 int4 micro-kernel 확장
- **무엇**: 2026-07-27 릴리스. QAI8DXP(8-bit 동적 비대칭 활성화) × QSI4CXP(4-bit 대칭 weight) 조합에 **F16 출력** SME2 matmul micro-kernel 신규 추가, SME2 F32 elastic GEMM 성능 개선.
- **성숙도**: 상용 적용. XNNPACK/ExecuTorch/llama.cpp에 이미 통합된 라이브러리의 정기 릴리스.
- 출처: https://github.com/ARM-software/kleidiai/releases , https://pytorch.org/blog/unleashing-ai-mobile/
- 비고: v1.28.0(SVE2.1 FP16 micro-kernel)은 2026-07-07 릴리스로 커버 기간 직전.

### ▪ 모바일 NPU 컴파일러 fusion이 유발하는 Power Burst 완화 (arXiv 2607.16555)
- **무엇**: 벤더 NPU 컴파일러의 공격적 operator fusion이 거대 "superlayer"를 만들어 전력 전달망(PDN)에 순간 전류 스파이크를 유발 — 배터리 노후화 시 voltage droop으로 이어짐. 사전 컴파일 단계 graph rewrite로 PAR(peak-to-average) hot spot에 barrier를 삽입해 완화. (2026-07-17)
- **수치**: Snapdragon 8 Gen 3 실기 측정, peak current **3.12A → 1.94A (약 38% 감소)**, latency overhead **3.76%**, DVFS 마진 약 **173mV** 확보. (벤치마크는 MobileNetV4 768×768 / ImageNet-1k)
- **성숙도**: 논문 단계 (실기 측정 기반, 구현 공개 여부 [미확인]).
- 출처: https://arxiv.org/abs/2607.16555

### ▪ NPU 타깃 아키텍처-배포 Co-design 2건 (Opt.Gear / StepX-Edge)
- **무엇**: (a) **Opt.Gear** (2026-08-02, v2 08-04) — convolutional KV-gated mixer + local-global attention 하이브리드로 KV cache를 구조적으로 줄인 edge foundation model 패밀리(1M/270M/1B, 64K context). (b) **StepX-Edge** (2026-07-20) — 0.9B 온디바이스 UI VLM을 architecture-training-deployment 3단 co-design으로 설계.
- **수치**: Opt.Gear — NPU에서 prefill·decode **최대 4.9배** 가속(Qualcomm NPU / Apple ANE 타깃), 1M 모델은 ARM Cortex-M7에서 W4A32로 20 TPS. StepX-Edge — Snapdragon 8 Gen5에서 W4A16+KV8 기준 **TTFT ~0.84초, decode 98 tok/s, peak memory 1.4GB**, ScreenQA 88.76 F1 / RefCOCO 92.0%.
- **성숙도**: 논문/테크리포트 단계. Opt.Gear는 모델 가중치 공개 여부 [미확인], StepX-Edge 배포 런타임/엔진 명시 없음 [미확인].
- 출처: https://arxiv.org/abs/2608.01034 , https://arxiv.org/abs/2607.22708

### ▪ KV cache 압축 신규 흐름 — AnchorKV / OptR (INT2)
- **무엇**: (a) **AnchorKV** (2026-08-03) — 토큰을 버리거나 저정밀 저장하는 대신, 소수 anchor를 정확히 보관하고 나머지 토큰은 최유사 anchor에 대한 residual로 표현. (b) **OptR** (2026-08-03, v2 08-05) — INT2 KV cache 양자화에서 post-$W_O$ attention 출력 오차를 직접 최소화하는 per-head orthogonal rotation 학습.
- **수치**: AnchorKV — **20× cache 축소, 70B 스케일에서 full-cache 대비 99% 정확도 유지**. OptR — QuaRot/OSCAR 대비 일관된 개선, paged KV format 유지 및 추론 오버헤드 무시 가능 수준이나 **구체 수치는 abstract 미기재 [미확인]**.
- **성숙도**: 둘 다 논문 단계(AnchorKV는 under review, 코드 공개 확인 안 됨).
- 출처: https://arxiv.org/abs/2608.02901 , https://arxiv.org/abs/2608.02691

---

### 그 외 커버 기간 내 관측 (요약, 우선순위 하위)
- **Qualcomm AI Hub 툴체인 업데이트** (07-06, 07-20): QAIRT 2.48.0 지원, ONNX Runtime 1.27.1 + QNN EP 2.3.0, AIMET 2.35.1(정확도 회귀 수정), RMSNorm fusion을 opset<23 export에도 정상 적용. AI Hub Models v0.58.0(07-15)은 **LLM용 memory-mapped prefilled input**을 추가해 host memory 압박 완화. → 벤더 툴체인의 실무 안정화 단계. 출처: https://workbench.aihub.qualcomm.com/docs/hub/release_notes.html , https://github.com/qualcomm/ai-hub-models/releases
- **ONNX Runtime v1.28.0** (07-25): ARM64 **2-bit weight CPU 커널** 추가, WebGPU KV cache quantization, QNN EP 버그 수정. 2-bit CPU 커널은 초저비트 온디바이스 실험의 진입 장벽을 낮춤. 출처: https://github.com/microsoft/onnxruntime/releases/tag/v1.28.0
- **DraftExpert** (2607.24434, 07-27): 레이어별 경량 draft expert + expert prefetch로 **Flash→모바일 NPU** 오프로딩 환경에서 decode throughput 1.45×, draft 수용률 84–87%. 온디바이스 MoE를 고려한다면 참고 가치.
- **EdgeXpert** (2608.05303, 08-05, MICRO 2026): MoE + speculative decoding 하드웨어-소프트웨어 co-design, 28nm 800MHz 합성 기준 latency 최대 56.3% / energy 44.1% 감소. **ASIC 프로토타입**이므로 단기 적용성은 낮으나 차세대 NPU IP 방향성 참고.
- **PolyQ** (2607.14618, 07-16): 채널별 가변 비트({2,3,4,8,16}) 할당 + 컴파일러 co-design, 3-bit 타깃에서 perplexity 2.4–32.1% 개선, activation reorder traffic 최대 70.8% 감소. 모바일 CPU 포함 3종 CPU 평가.

### 커버 기간 내 신규 없음으로 확인된 항목
- **ExecuTorch**: 최신 릴리스는 v1.3.1 (2026-05-29). 커버 기간 내 신규 태그 릴리스 없음. (해당 릴리스에는 Arm TOSA lowering 확대, QNN ATen op 확대, Qwen3.5 MoE/Gemma 4 지원 포함)
- **MLC-LLM**: GitHub Releases에 정식 태그 부재(v0.1.dev0, 2023). 릴리스 기반 추적 불가.
- **MediaTek NeuroPilot**: 커버 기간 내 신규 SDK 릴리스 확인 실패. Dimensity 8550의 LLM Booster/speculative decoding 발표는 2026-05-27로 기간 외.

### ⚠️ 수집 한계
- **arXiv 최신성 편향**: arXiv API의 `submittedDate` 정렬로 수집했으나, 07-08~07-31 구간은 08월 제출분에 밀려 노출이 적었을 수 있음. `abs:"efficient inference"` 쿼리는 30건 요청 대비 7건만 반환되어 결과가 불완전할 가능성 있음.
- **llama.cpp Hexagon 최적화 수치**: 릴리스 노트가 아닌 커뮤니티 주간 요약을 통해 확인. 원 PR 번호 및 정량 벤치마크는 **[미확인]** — 후속 리포트에서 PR 직접 확인 필요.
- **OptR(INT2 KV)의 정량 수치**: abstract에 미기재. 본문 PDF 미확인.
- **Opt.Gear 4.9× 가속의 기준 NPU 모델/비교 baseline**: abstract에 미명시 **[미확인]**.
- **접근 실패 소스**: MLC-LLM 릴리스 추적(정식 태그 부재), MediaTek NeuroPilot 릴리스 노트(공개 changelog 미확인).
- **ONNX Runtime v1.28.0 릴리스 일자**: GitHub API는 2026-07-25로 반환, 릴리스 페이지 파싱 시 2024-07-25로 오독됨. API 값(2026-07-25)을 채택하되 교차 확인 권장.
## 3. 업계 동향

> 커버 기간: 2026-07-08 ~ 2026-08-07 (초회 baseline) · 작성 2026-08-07

---

### ▪ 메모리 크런치 — Q2 스마트폰 출하 13년 만의 최저, On-device AI의 RAM 요구와 정면 충돌

- **무엇**: Counterpoint 집계 기준 2026년 2분기 글로벌 스마트폰 출하가 YoY -11%로 13년 만의 Q2 최저치 (IDC 기준 277.5M대, -6.7%). 원인은 AI 데이터센터가 DRAM/NAND 공급을 흡수하는 메모리 대란. (보도 2026-07-14)
  - 참고 수치: TrendForce 5월 조사 기준 Q2 모바일 DRAM 계약가 LPDDR5X +78~83% QoQ, LPDDR4X +70~75% QoQ.
- 출처: https://counterpointresearch.com/en/insights/global-smartphone-shipments-q2-2026 / https://www.androidauthority.com/counterpoint-research-q2-2026-smartphone-shipment-report-3686931/ / https://www.telecompaper.com/news/dram-prices-surge-70-83-in-q2-2026-deepening-smartphone-industry-squeeze--1571206

---

### ▪ 중국 CAC — 사상 첫 "휴대폰 단말 측(端侧) 생성형 AI" 별도 备案 카테고리 신설, 7개사 승인 (2026-07-15)

  - 같은 날(7/15) Xiaomi는 MiMo 단말 측 모델이 국가 대모델 등록을 완료했다고 별도 발표 — 언어/멀티모달/음성 전 매트릭스 완비를 주장.
- 출처: https://www.news.cn/tech/20260715/946a9e3e979745628447c2d2b52667c4/c.html / https://www.stdaily.com/web/gdxw/2026-07/15/content_547774.html / http://finance.people.com.cn/n1/2026/0715/c1004-40761348.html

---

### ▪ OPPO — "Xiaobu Next" 업계 최초 온디바이스 Multi-Agent 협업 시스템 베타 공개 (2026-07-27, 선전)

- **무엇**: OPPO가 컨텍스트 이해·태스크 플래닝·스케줄링을 **클라우드가 아닌 단말에서 수행하는 멀티에이전트 협업 시스템**을 공개하고 베타 모집 개시. 핵심은 사용자 동의 기반으로 습관·맥락을 지속 학습하는 **온디바이스 全域记忆(full-domain memory)** 프레임워크와 상시 센싱(트리거 워드 없이 맥락을 계속 읽는 방식). 시스템 레벨 기능 100종 이상 통합, 루이싱커피·메이투안 등 서드파티 연동, 구직/학습/오피스 시나리오 지원. 대상은 Find X8·X9 시리즈 및 일부 OnePlus.
  - 알리페이 "阿바오(A Bao)"와의 크로스 디바이스 에이전트 연동도 별도 발표됨 (정확한 발표일 [미확인]).
- 출처: https://finance.biggo.com/news/681e2f81-d26b-4336-9659-53a70d548e64 / https://www.thetechoutlook.com/new-release/software-apps/oppo-launches-its-xiaobu-next-project-first-round-of-recruitment-officially-started-in-china/ / https://www.androidpure.com/oppo-xiaobu-next-eligible-devices/

---

### ▪ Qualcomm — Modular 인수 완료(7/30, 약 $3.9B 추정)로 AI 소프트웨어 스택 수직화 + 핸드셋 매출 -20%

- **무엇**:
  1. **7/29 FY26 Q3 실적**: 매출 $9.95B(YoY -4%, 컨센 $9.67B 상회), 그러나 QCT 핸드셋 매출 $5.09B로 **YoY -20%**. 메모리 제약과 수요 약세가 직격. 순이익 -25%.
  2. **7/30 Modular 인수 완료**: 6/24 발표건의 클로징. Reuters 산정 약 **$3.92B**(공식 미공개). Mojo·MAX·Modular Cloud 브랜드 유지, **Chris Lattner(LLVM/Swift 창시자)가 EVP of Advanced AI Software and Platforms로 합류**. 8월 중 AI 소프트웨어 플랫폼 공개 예고.
  3. **[루머]** 차세대 Snapdragon 8 Elite Gen 6 Pro(SM8975) 유출(7/26~28): TSMC N2P 2nm, 다이 약 134mm²(Gen 5는 126.2mm²), **Android 최초 LPDDR6 지원**, GPU 셰이더 내 Matrix ALU 2블록을 이용한 "AI Frame Fusion" 업스케일링. 표준형은 LPDDR5X 유지 전망.
  - 핸드셋 -20%는 Qualcomm의 협상 레버리지 약화를 뜻하기도 함 — 조달 관점의 기회.
- 출처: https://www.cnbc.com/2026/07/29/qualcomm-qcom-earnings-report-q3-2026-.html / https://www.digitimes.com/news/a20260730PR200/qualcomm-acquisition-software-infrastructure-hardware.html / https://www.qualcomm.com/news/releases/2026/06/qualcomm-to-acquire-modular / https://www.techtimes.com/articles/321683/20260727/snapdragon-8-elite-gen-6-pro-exclusive-die-size-lpddr6-first-ai-frame-fusion-detailed.htm

---

### ▪ EU AI Act — Article 50 투명성 의무 2026-08-02 발효 (온디바이스 AI 어시스턴트 직접 적용)

- **무엇**: 8월 2일부터 AI Act 제50조 투명성 의무가 적용. **사용자와 직접 상호작용하는 AI 시스템(챗봇·음성 어시스턴트·AI 에이전트·아바타)은 "AI와 대화 중"임을 명확히 고지**해야 하며, 고지는 약관 매설이나 메타데이터 워터마크만으로는 불충분하고 **상호작용 화면에서 첫 메시지 이전에 인지 가능**해야 함. AI 생성 콘텐츠의 기계 판독 가능 마킹 의무도 포함. 위반 시 **최대 €15M 또는 전세계 연매출 3%** 중 큰 금액. 시장 출시 시점과 무관하게 기존 제품에도 즉시 적용.
- **주의**: 일부 로펌 해설은 마킹·탐지 의무에 대해 **2026-12-02까지의 준수 유예**를 언급하며, Annex I 제품 내장 AI는 2028-08-02로 연기됨. 해석 편차가 있으므로 법무 확인 필요. [미확인 — 최종 유권해석]
- 출처: https://commission.europa.eu/news-and-media/news/safer-and-more-transparent-ai-2026-08-02_en / https://www.cooley.com/news/insight/2026/2026-08-03-eu-ai-act-transparency-obligations-take-effect-2-august-2026 / https://www.traverssmith.com/knowledge/knowledge-container/is-it-a-bot-eu-ai-act-transparency-rules-take-effect-2-august-2026/

---

### 🗓 다가오는 일정

| 일자 | 이벤트 | 비고 |
|---|---|---|
| 2026-08-12 | **Made by Google** (뉴욕, 18:00 ET) — Pixel 11 / 11 Pro / Pro XL / Pro Fold, Pixel Watch 5 | 공식 확정. Tensor G6(TSMC 2nm) 및 Gemini Intelligence 기본 탑재는 **루머/추정** |
| 2026-08-12 | **Honor Robot Phone** 중국 출시 | 공식 확정(Weibo). 로봇암 200MP 카메라, Snapdragon 8 Elite Gen 5. 미국/영국 출시 계획 없음 |
| 2026년 8월 중 | Qualcomm **AI 소프트웨어 플랫폼** 공개 (Modular 통합) | 실적 발표에서 예고. 구체 행사/일자 [미확인] |
| 2026-09-22 ~ 24 | **Qualcomm Snapdragon Summit** (하와이 마우이) | Snapdragon 8 Elite Gen 6 / Gen 6 Pro 발표 예상 (루머) |
| 2026 Q3 (9월 유력) | **MediaTek Dimensity 9600** 시리즈 (9600s / Pro / Pro Max) | 루머. vivo X500·OPPO Find X10 탑재 전망 |
| 2026년 9월 | Xiaomi 18 / vivo X500 / OPPO Find X10 플래그십 동시 경쟁 | 루머 |
| 2026년 가을 | Apple **iOS 27** + Google Gemini 기반 신형 Siri 정식 배포 | WWDC26 발표 기준. 정확 일자 [미확인] |
| 2026-12-02 | EU AI Act 투명성 관련 일부 준수 기한 | 해석 편차 있음. 법무 확인 필요 |

---

### ⚠️ 수집 한계

- **Apple**: 커버 기간(7/8~8/7) 내 신규 온디바이스 발표를 확인하지 못함. AFM 3 Core Advanced(20B 파라미터 sparse, 요청당 1~4B 활성 / A19 Pro·M3·M4 이상 필요), Siri Expressive Voices, Foundation Models framework 개편은 모두 **WWDC26(6월) 발표분**으로 이번 기간 신규가 아니다. 7월 중 Apple 온디바이스 관련 신규 발표는 CAC 备案 등재(7/15)가 유일하게 확인됨.
- **Google**: I/O '26(5월) 이후 ML Kit GenAI API 업데이트(Prompt API for Gemini Nano 4, Structured Output API, Prefix Caching)는 5월 발표분. 7~8월 신규 플랫폼 발표는 미확인.
- **Microsoft**: Copilot+ NPU 전용 노선 철회 및 GPU/CPU 확대는 **Build 2026(6/2~3)** 발표분으로 기간 외. 본문에는 맥락으로만 인용.
- **차세대 실리콘 스펙 전량이 유출/루머** — Snapdragon 8 Elite Gen 6 Pro, Dimensity 9600, Tensor G6 모두 벤더 공식 확인 없음. 본문에 [루머] 표기.
- 본 리포트는 웹 검색 결과 스니펫에 기반했으며, 일부 원문(특히 중문 매체 및 유료 리서치 원본)은 직접 검증하지 못함. Counterpoint/IDC/TrendForce 수치는 2차 인용 기준.
- OPPO Xiaobu Next의 실제 온디바이스 처리 비중, 클라우드 폴백 조건, 메모리 프레임워크 용량 등 기술 상세는 [미확인].
- M&A는 Qualcomm-Modular 1건 외 온디바이스 AI 관련 유의미한 인수·주요 인사 이동은 이번 기간 내 미확인.
## 4. 학계 동향

> 커버 기간: 2026-07-08 ~ 2026-08-07 (초회 baseline, 이전 리포트 없음)
> 관점: 개별 기법 심층이 아닌 **학계 생태계**(연구 흐름·기관·벤치마크·학회 일정) 중심

---

### ▪ EdgeXpert: An Edge Device for Memory-Efficient LLM Inference with Mixture-of-Experts and Speculative Decoding (KAIST 유회준 교수 연구실 추정, arXiv:2608.05303)
- **핵심 기여**: Edge LLM에서 서로 충돌하던 speculative decoding과 MoE를 HW/SW co-design으로 결합. Prefill 단계의 prompt-wise expert reuse, decode 단계의 depth-aware expert coalescing으로 FFN external memory access 병목 완화. **28nm 공정 800MHz 합성** 기준 latency 최대 56.3%, energy 44.1% 절감(정확도 baseline 수준 유지).
- **재현 가능성**: ASIC 설계 논문으로 코드/RTL 공개 없음 `[미확인]`. 논문 내 수치 기반 재현만 가능.
- 출처: https://arxiv.org/abs/2608.05303

### ▪ Mitigating Compiler Fusion-Induced Power Bursts in Mobile NPU Inference as the Battery Depletes (arXiv:2607.16555)
- **핵심 기여**: 벤더 NPU 컴파일러의 operator fusion이 거대 superlayer를 만들어 peak-current burst를 유발하고, 저배터리 구간에서 PDN voltage droop을 일으킨다는 문제 제기. 측정 기반으로 PAR(peak-to-average power ratio) hot spot에 barrier를 삽입하는 pre-compilation graph rewrite 제안. **Snapdragon 8 Gen 3 + MobileNetV4에서 peak current 3.12A → 1.94A**, 저전압 안정성 마진 약 173mV 개선, latency overhead는 미미.
- 출처: https://arxiv.org/abs/2607.16555

### ▪ Device-First Feedback: Toward Mobile-Native LLM-Driven Neural Architecture Search (arXiv:2608.00078)
- **재현 가능성**: **코드 공개** (https://github.com/ABrain-One/nn-gpt). cycle별 지표를 95% 신뢰구간과 함께 공개하고 재현 커맨드 전체 제공 — 재현성 수준 상.
- 출처: https://arxiv.org/abs/2608.00078

### ▪ Is Your NPU Ready for LLMs? Dissecting the Hidden Efficiency Bottlenecks in Mobile LLM Inference (arXiv:2607.05475)
- **핵심 기여**: 5개 프레임워크 × 3개 백엔드(CPU/GPU/NPU)를 가로지른 **최초의 cross-layer 측정 연구**. 백엔드별 에너지 프로파일링 도구 **PowerBench** 공개 제안. 주요 발견: ① 프레임워크 간 성능 격차가 NPU에서 최대 10배까지 증폭 ② compute-bound prefill은 NPU 우세, memory-bound decode는 **CPU가 NPU보다 우세** ③ 스케줄링 비효율로 최대 40% 에너지 낭비, 제안 구성 적용 시 NPU 에너지 54.8% 절감.
- **재현 가능성**: PowerBench 공개 여부 초록 상 명시 없음 `[미확인]`.
- **날짜 주의**: v1 제출 **2026-07-06**으로 커버 기간 시작 2일 전. 흐름 파악상 포함하되 엄밀히는 경계 직전 항목.
- 출처: https://arxiv.org/abs/2607.05475

### ▪ [벤치마크] Android Bench 평가 체계 개편 (Google, 2026-07-08)
- **핵심 기여**: Android 개발 태스크용 LLM 벤치마크를 mini-swe-agent v1 → **Harbor 프레임워크**로 전환하고, 리더보드에 **cost·efficiency 차원을 추가**. Jetpack Compose 마이그레이션, **wearable networking**, 플랫폼 API 업데이트 등 Android 고유 과제로 평가. 신규 8개 모델 추가(open-weight 최상위는 GLM 5.2 = 72.2, Kimi K2.7 Code = 70.4). 커뮤니티가 자체 태스크를 GitHub로 제출 가능.
- **재현 가능성**: 평가 하네스 및 커뮤니티 기여 채널 공개 — 재현성 상.
- 출처: https://android-developers.googleblog.com/2026/07/android-bench-llm-measurement.html

---

### 🗓 학회 일정

**즉시 조치 필요 (마감 임박)**

| 일정 | 내용 | 비고 |
|---|---|---|
| **2026-08-29 (23:59 UTC)** | **NeurIPS 2026 Workshop "AXIOM: Foundations of Efficient Deep Learning" 논문 마감** | 12/12 파리. ELLIS 기반, scaling law·sparsity·compression 이론 축. 통지 9/29 |
| **2026-08-29 (AoE)** | NeurIPS 2026 워크샵 기여 제출 권장 마감(공통) | |

**주요 예정 일정**

| 일정 | 내용 |
|---|---|
| 2026-09-09 | **ASPLOS 2027 September cycle 논문 마감** (개최 2027-04-11~15, 그리스 헤라클리온 / 통지 2026-12-21) |
| 2026-09-18~19 (AoE) | **ICLR 2027 abstract 마감** (자료 간 9/18과 9/19 불일치 — 공식 확인 필요) |
| 2026-09-24~25 (AoE) | **ICLR 2027 full paper 마감** (개최 2027년 4월, 브라질). 자료 간 9/24와 9/25 불일치 — 공식 확인 필요 |
| 2026-09-24 (AoE) | NeurIPS 2026 본회의 채택 통지 (main / datasets & benchmarks / position) |
| 2026-09-29 (AoE) | NeurIPS 2026 워크샵 accept/reject 통지 |
| 2026-10-24~29 | **EMNLP 2026 개최** (헝가리 부다페스트). 22개 영역 중 efficient methods 트랙 포함 |
| 2026-12-06~13 | **NeurIPS 2026 개최 — 3개 도시 분산**: 시드니 12/6~12, 애틀랜타 12/9~13, 파리 12/9~13 |
| 2027-07-13~17 | ICML 2027 개최 예정 (마감일은 과거 패턴 기반 추정, `[미확인]`) |

**참고 (기간 내 신규 아님)**
- MLSys 2026은 **2026-05-19~21 이미 개최 완료**(Indio, CA). 다음 사이클(MLSys 2027) CFP는 통상 9월경 공개 예상 — 모니터링 대상.
- MICRO 2026 채택 논문 목록은 공개 확인 불가 `[미확인]`.

---

### 🔭 기관 발표 워치리스트

- **Apple**: 3세대 Apple Foundation Models 발표(2026-06-08, 커버 기간 이전). 온디바이스 라인업은 AFM 3 Core(3B dense)와 **AFM 3 Core Advanced(20B sparse, 요청당 1~4B만 활성, 전체 가중치를 DRAM이 아닌 NAND flash에 상주)**, QAT 적용. **"기술 리포트를 여름 중 공개"**라 예고했으나 **2026-08-07 기준 미공개** — 8~9월 중 공개 시 온디바이스 sparse/flash-resident 아키텍처의 상세 수치가 나올 가능성이 높아 최우선 추적 대상.

---

### 📌 기간 종합 관찰 (baseline)

1. **NPU 무조건 우위론의 붕괴**가 이번 기간 가장 뚜렷한 학계 컨센서스. Prefill=NPU / Decode=CPU·GPU의 단계별 이기종 스케줄링을 다룬 논문이 다수 동시 출현(arXiv:2607.05475, 2607.12839, 2607.25498, 2606.27906 등).
2. **전력 품질(peak current, DVFS, PDN)**이 latency/throughput을 대체하는 새 최적화 축으로 부상(arXiv:2607.16555 외 cs.AR 다수).
3. **평가 방법론의 이동**: 정확도 단일 축 → 비용·에너지·실단말 실측 포함(Android Bench 개편, PowerBench, device-first NAS).
4. NeurIPS 2026이 **온디바이스 전용 워크샵을 정식 채택**했고 Qualcomm AI Research가 주최에 참여 — 경쟁사가 학계 어젠다 세팅에 선점적으로 관여 중. 8/29 마감 대응 여부에 대한 조직 차원 판단 필요.

---

### ⚠️ 수집 한계

- `https://huggingface.co/api/papers/trending` — **HTTP 404**. 대체로 `huggingface.co/papers/trending` 페이지를 조회했으나, 반환된 상위 트렌딩은 대형 모델 위주(Kimi K3 등)로 온디바이스 관련 신규 항목 없음.
- **MLSys 2026 / MICRO 2026 채택 논문 개별 목록** 확인 불가. MLSys 2026은 이미 개최 완료되어 신규성 없음, MICRO 2026 목록은 공개 확인되지 않음.
- **arXiv 소속기관(affiliation)** 정보는 abs 페이지에 노출되지 않아 대부분 `[미확인]`. EdgeXpert의 KAIST 소속은 저자명(Hoi-Jun Yoo) 기반 추정이며 PDF 원문 확인 전까지 확정 아님.
- **ICLR 2027 마감일**이 출처 간 하루 차이(9/18 vs 9/19, 9/24 vs 9/25)로 불일치. 투고 계획 시 iclr.cc 공식 페이지 재확인 필수.
- 코드 공개 여부는 arXiv abs 페이지 링크 유무로 판단했으므로, 링크 미기재 논문이라도 PDF 내 repo가 있을 수 있음.
## 5. HuggingFace 인기 모델

> 커버 기간 2026-07-08 ~ 2026-08-07 / **초회 baseline 회차** — 이전 리포트가 없어 Δ 계산 불가.
> 다운로드·Likes 수치는 2026-08-07 HuggingFace API 조회값 그대로이며, `downloads`는 HF API 정의상 **최근 30일 누적 다운로드**다.
> 다음 회차는 아래 `05-metrics.json`의 수치를 기준선으로 Δ를 산출한다.

| 모델 | 파라미터 | 다운로드(Δ) | Likes(Δ) | On-device 적합성 | 비고 |
|---|---|---|---|---|---|
| LiquidAI/LFM2.5-2.6B | 2.70B (2,697,198,592) | 73,573 —(baseline) | 341 —(baseline) | ◎ | 7/28 신규 릴리스. 모델 카드 태그에 `edge` 명시. 15개국어. GGUF/ONNX/MLX 3포맷 동시 배포로 이번 달 최대 화제 SLM |
| LiquidAI/LFM2.5-2.6B-GGUF | 2.70B (양자화) | 12,790 —(baseline) | 130 —(baseline) | ◎ | llama.cpp 공식 배포. 본체 릴리스 4일 뒤(8/1) 게시, 8/6 갱신 — 벤더가 직접 on-device 포맷을 1차 산출물로 취급 |
| LiquidAI/LFM2.5-2.6B-ONNX | 2.70B (양자화) | 811 —(baseline) | 17 —(baseline) | ◎ | ONNX Runtime 경로 확보. 모바일 NPU 백엔드 연결 시 가장 이식성 높은 형태 |
| LiquidAI/LFM2.5-8B-A1B-MLX-8bit | 8.47B total / A1B active | 1,553 —(baseline) | 29 —(baseline) | ◎ | MoE 8B이지만 **활성 파라미터 1B** → 실효 연산량이 1B급. 8bit MLX. 메모리 대비 성능비가 폰에 가장 유리한 구조 |
| LiquidAI/LFM2.5-1.2B-Instruct-ONNX | 1.2B (양자화) | 1,310 —(baseline) | 35 —(baseline) | ◎ | 태그에 `onnxruntime`, `webgpu` 동시 보유. 온디바이스+웹 하이브리드 배포 레퍼런스 |
| LiquidAI/LFM2.5-VL-1.6B-ONNX | 1.6B (양자화) | 473 —(baseline) | 33 —(baseline) | ◎ | 1.6B급 VLM의 ONNX 배포. 카메라/스크린 이해 기능의 온디바이스 후보 |
| Audio8/Audio8-TTS-Preview-0.6b | 0.60B (601,159,424) | 12,211 —(baseline) | 298 —(baseline) | ◎ | 7/28 신규. 0.6B로 zero-shot 보이스 클로닝 + 11개국어. 별도 `Audio8-TTS-Preview-0.6B-ONNX-INT4`(179 dl / 36 likes) 동시 제공 |
| ornith-ai/Ornith-1.0-9B-GGUF | 9B | 4,632,751 —(baseline) | 613 —(baseline) | ◎ | 이번 조사 대상 중 **10B 이하 GGUF 다운로드 1위**. 6/25 게시 후 30일 460만 다운로드로 실사용 채택 규모가 압도적 |
| cyankiwi/Qwen3.5-9B-AWQ-4bit | 9.88B (9,875,665,038) | 320,768 —(baseline) | 35 —(baseline) | ○ | AWQ 4bit. 10B 상한 경계값이라 4bit에서도 플래그십 폰 메모리 압박. VLM(image-text-to-text) 겸용 |
| onnx-community/embeddinggemma-300m-ONNX | 0.3B | 150,895 —(baseline) | 73 —(baseline) | ◎ | 온디바이스 RAG용 임베딩. `transformers.js` 지원으로 앱 내 검색·개인화에 즉시 투입 가능 |
| mistralai/Shieldstral-1.0-3B | 3.85B (3,849,090,048) | 1,511 —(baseline) | 165 —(baseline) | ○ | 7/16 릴리스 **가드레일 전용 SLM**. Apache-2.0. 아직 safetensors만 배포되어 GGUF/ONNX 부재가 유일한 걸림돌 |
| Jackrong/DeepSeek-V4-Pro-Qwen3.5-9B-MTP-GGUF | 9B | 42,552 —(baseline) | 33 —(baseline) | ○ | DeepSeek-V4-Pro → Qwen3.5-9B 증류 + MTP. 4B 버전(4,800 dl / 13 likes)도 병행. 커뮤니티발 프론티어→SLM 증류 흐름의 대표 사례 |

---

### 주목할 모델 3개

**1) LiquidAI LFM2.5 패밀리 — 온디바이스가 "포팅"이 아니라 "1차 배포 형태"가 된 첫 사례**

LFM2.5-2.6B(7/28 릴리스)는 한 달도 안 돼 30일 다운로드 73,573 / Likes 341을 기록하며 이번 기간 SLM 중 최대 관심을 받았다. 주목할 지점은 절대 수치보다 **배포 방식**이다. 통상 SLM은 본체(safetensors) 공개 후 커뮤니티(bartowski, mradermacher, unsloth 등)가 수일~수주 뒤 GGUF를 올리는 순서인데, LiquidAI는 본체·GGUF·ONNX·MLX를 벤더가 직접, 사실상 동시에 게시했다. 모델 카드 태그에도 `edge`가 박혀 있다.

라인업 전체가 온디바이스 전 구간을 커버한다 — 230M / 350M / 1.2B(Instruct·Thinking·JP) / 1.6B VL / 2.6B / 8B-A1B MoE. 특히 **LFM2.5-8B-A1B는 총 8.47B이면서 활성 파라미터가 1B**로, "메모리는 중급기 상한, 연산은 1B급"이라는 폰에 최적화된 트레이드오프를 취한다. 1.2B-Instruct-ONNX에 `webgpu` 태그가 함께 붙은 것도 앱-웹뷰 공용 추론 경로를 노린 설계로 읽힌다.

**2) Audio8-TTS-Preview-0.6b — 0.6B로 zero-shot 보이스 클로닝, 그리고 INT4 ONNX 동시 배포**

파라미터 601,159,424개(0.6B)에 불과한 TTS가 30일 12,211 다운로드 / Likes 298을 기록했다. 광범위한 다국어(한국어 포함 11개국어)에 zero-shot voice cloning을 표방하며, Apache-2.0이다. 결정적으로 `Audio8-TTS-Preview-0.6B-ONNX-INT4`가 함께 올라와 있어 **양자화된 온디바이스 경로가 이미 검증 가능한 상태**다.

**3) mistralai/Shieldstral-1.0-3B — 온디바이스 안전 계층의 공백을 메우는 3B 가드레일**

7/16 공개된 3.85B 가드레일 전용 모델로, Ministral-3-3B-Base 파생에 Apache-2.0이다. Likes 165 대비 다운로드 1,511로 **"관심 대비 실사용이 아직 낮은" 전형적 초기 곡선**을 그리고 있어, 다음 회차 Δ에서 확산 여부를 가장 흥미롭게 관찰할 대상이다.

의미는 크다. 온디바이스 LLM 상용화의 실질 병목은 성능이 아니라 안전 필터링인데, 서버 모더레이션에 의존하면 오프라인 동작이라는 온디바이스의 핵심 가치가 무너진다. 3B 가드레일은 이 딜레마의 해법이다. 다만 현재 safetensors만 배포되어 **GGUF/ONNX가 없다**는 점이 온디바이스 적합성을 ◎가 아닌 ○로 낮춘 이유다.

---

### 이번 기간 구조적 관찰

- **10B 초과지만 압축으로 내려오는 흐름이 뚜렷하다.** `prism-ml/Bonsai-27B-mlx-1bit`(593,916 dl / 204 likes), `prism-ml/Ternary-Bonsai-27B-mlx-2bit`(591,608 dl / 168 likes), `deepgrove/maple-preview`(20.2B ternary MoE, 419 dl / **213 likes**) 등 **1bit/2bit/ternary** 계열이 동시다발로 등장했다. 파라미터 상한(10B)만으로 온디바이스 후보를 거르는 기준이 다음 분기부터는 유효하지 않을 수 있다. 다음 회차부터 **"실효 메모리 풋프린트" 기준을 병행**할 것을 제안한다. (본 표에는 파라미터 기준을 지켜 미포함)
- **커뮤니티 GGUF 파이프라인이 사실상 실시간이다.** `search=gguf&sort=lastModified` 조회 시 조회 시점 기준 몇 시간 내 업로드가 50건을 채웠다. 8/2 공개된 `inclusionAI/Ling-3.0-flash`는 8/7 이미 GGUF 변환본이 올라왔다. 신규 모델의 on-device 가용화 지연(lag)이 **일 단위로 축소**됐다.
- **프론티어 → SLM 증류가 커뮤니티 주도로 일어난다.** `Jackrong/DeepSeek-V4-Pro-Qwen3.5-9B/4B-MTP-GGUF`처럼 프론티어 모델을 4B~9B로 증류하고 곧바로 GGUF로 내놓는 패턴이 정착했다.
- **다운로드 절대 규모는 여전히 소형 범용 모델이 지배한다.** text-generation 다운로드 1위는 `Qwen/Qwen3-0.6B`(28,862,849), 3위 `Qwen/Qwen3-8B`(15,485,922), `meta-llama/Llama-3.2-1B-Instruct`(10,016,506), `google/gemma-3-1b-it`(4,965,745). 화제성과 실사용 채택은 별개 축임을 유의.

---

### ⚠️ 수집 한계

- `https://huggingface.co/api/papers/trending` — **HTTP 404**. `https://huggingface.co/api/daily_papers?limit=20`로 대체 수집했으나, 해당 결과에 on-device/양자화 직결 논문은 없었다(에이전트 RL·VLA·문서파싱 위주). 본 섹션 판단에는 미반영.
- `downloads` 필드는 HF API 정의상 **최근 30일 누적**이며 전체 누적(`downloadsAllTime`)이 아니다. 커버 기간(7/8~8/7)과 근사하게 일치하나 완전히 동일하지는 않다. 다음 회차 Δ는 동일 필드끼리 비교해야 유효하다.
- 트렌딩 목록 API가 요청한 50건 중 34건만 반환했다(응답 자체가 절단). 누락분에 10B 이하 후보가 추가로 존재할 가능성이 있다.
- 파라미터 수는 safetensors 메타데이터가 있는 모델만 정확 수치를 기재했다. GGUF 전용 리포지토리(Ornith-1.0-9B-GGUF, Jackrong 계열)는 safetensors 메타데이터가 없어 **모델명 표기 기준**(9B)으로만 기록했다.
- `ethanfel/...`, `lodestones/Kroma` 등 다운로드 0인 신규/이미지생성 항목, MiniMax-H3(영상생성) 및 70B+ 거대 모델(GLM-5.2, Kimi-K3, DeepSeek-V4-Flash, Inkling-Small 266B, XYZ-Aquila-mini 35B, Ling-3.0-flash 127B)은 도메인 필터에 따라 제외했다.
## 6. GitHub 인기 Repository

> 커버 기간: 2026-07-08 ~ 2026-08-07 / 수집 시점: 2026-08-07 (KST 오후)
> **초회 baseline 회차** — 이전 리포트가 없어 Δstar 산출 불가. 아래 star 수치는 GitHub Search API 원본 값을 반올림 없이 그대로 기록한 것으로, **다음 회차 Δ 계산의 기준선**이 된다.

| Repo | ⭐ Star(Δ) | 언어 | 최근 릴리스 | 요약 |
|---|---|---|---|---|
| ollama/ollama | 177,962 —(baseline) | Go | v0.32.6 (2026-08-04) | 로컬 LLM 실행 표준 런처. 최신 버전에서 MLX 엔진이 Qwen3.5 MTP head 기반 speculative decoding 채택, OpenAI 호환 스트리밍 정합 |
| ggml-org/llama.cpp | 122,941 —(baseline) | C++ | b10298 (2026-08-06) | GGUF/양자화 추론의 사실상 표준. 일 단위 롤링 릴리스, Android·Vulkan·OpenVINO·SYCL 등 모바일 포함 전 플랫폼 바이너리 배포 |
| ml-explore/mlx | 27,857 —(baseline) | C++ | v0.32.0 (2026-07-07) | Apple Silicon 통합메모리 최적화 프레임워크. Ollama·SwiftLM 등 상위 스택이 MLX를 백엔드로 채택하는 흐름 확산 |
| google-ai-edge/gallery | 24,374 —(baseline) | Kotlin | 1.0.17 (2026-08-03) | 구글의 온디바이스 GenAI 레퍼런스 Android 앱. HuggingFace LiteRT-LM 모델 임포트(1.0.16), MCP 툴 연동 지원 |
| Tencent/ncnn | 23,652 —(baseline) | C++ | 20260526 (2026-05-26) | 모바일 특화 경량 추론 엔진. HarmonyOS 프리빌드 신규 추가, ARM SDPA·ARMv8.4 BF16 최적화, Vulkan FlashAttention |
| mlc-ai/mlc-llm | 23,038 —(baseline) | Python | 정식 태그 릴리스 없음(nightly 배포, 최근 push 2026-07-31) | TVM 기반 컴파일러형 모바일/웹 LLM 배포 스택. 릴리스 태깅 대신 nightly 운영 |
| microsoft/onnxruntime | 21,293 —(baseline) | C++ | v1.28.0 (2026-07-25) | 크로스플랫폼 추론 런타임. WebGPU Plugin EP v0.2.1(2026-07-30) 별도 배포로 브라우저·엣지 GPU 경로 강화 |
| **alibaba/MNN** | 15,825 —(baseline) | C++ | **3.6.1 (2026-07-23)** | **Hexagon NPU 백엔드 신규 탑재, Snapdragon에서 CPU 대비 7.9× 성능 주장.** 직전 3.6.0은 Gemma4 등 멀티모달 LLM 확장 |
| google-ai-edge/LiteRT-LM | 6,115 —(baseline) | C++ | v0.15.0 (2026-08-04) | 구글의 엣지 LLM 추론 프레임워크. v0.15.0에서 Apple Foundation Framework 어댑터, v0.14.0에서 Android Python/CLI 지원 |
| **cactus-compute/cactus** | 5,563 —(baseline) | C++ | **v2.0.1 (2026-07-09)** | **모바일·웨어러블·스마트홈 전용 양자화/커널/런타임 풀스택.** v2.0에서 transpiler 완성, INT8/FP16 하이브리드 디코드 커널, NPU·Metal 지원 |
| pytorch/executorch | 4,869 —(baseline) | Python | v1.3.1 (2026-05-29) | PyTorch 공식 온디바이스 런타임. Arm·Qualcomm·Metal·MLX·Vulkan 백엔드 확장, Qwen3.5 MoE·Gemma 4 31B 커버 |
| qualcomm/aimet | 2,674 —(baseline) | Python | 2.36.0 (2026-07-27) | 퀄컴 공식 양자화·압축 툴킷. 7월 한 달 2.35.0→2.36.0까지 3회 릴리스로 릴리스 케이던스 상승 |

---

### 주목할 프로젝트

**1) alibaba/MNN 3.6.1 — Hexagon NPU 백엔드 (⭐15,825)**

7/23 릴리스된 3.6.1의 핵심은 **Hexagon NPU 백엔드 정식 추가**이며, 릴리스 노트는 Snapdragon 기기에서 CPU 대비 **7.9배** 성능을 명시한다. 오픈소스 추론 엔진이 Qualcomm NPU를 "실험적 지원"이 아니라 정식 백엔드로 넣고 배수까지 공표한 사례로, 6월 3.6.0(Gemma4 등 멀티모달 LLM 확장) → 7월 3.6.1(NPU)로 이어지는 한 달 간격의 공격적 케이던스도 주목할 지점이다.

**2) cactus-compute/cactus v2.0 — 모바일/웨어러블 전용 풀스택 (⭐5,563)**

2025년 4월 생성된 신생 프로젝트가 1년여 만에 5,563 star에 도달했다. 특징은 "양자화 + 커널 + 런타임 + 추론 엔진"을 **모바일·웨어러블·스마트홈·로봇 타깃으로만** 수직 통합했다는 점이다. 7/9 v2.0에서 transpiler를 완성하고 **INT8/FP16 하이브리드 디코드 커널**, transpiled LLM 번들에 대한 native chunked prefill, NPU 및 Metal GPU 가속을 넣었다. 데이터센터에서 내려오는 스택(vLLM 계열)이 아니라 처음부터 배터리·메모리 제약을 전제로 설계된 bottom-up 접근이다.

### 이번 기간 관찰된 흐름 (요약)

- **NPU 백엔드 대중화**: MNN(Hexagon), cactus(NPU), executorch(Qualcomm 백엔드 강화)가 동시에 NPU 경로를 밀고 있다.
- **Apple 생태계 흡인력**: LiteRT-LM v0.15.0의 Apple Foundation Framework 어댑터, Ollama의 MLX 엔진 우선 개발, apple/coreai-models(⭐1,468, 2026-06 신규) 등 온디바이스 논의가 Apple 쪽으로 쏠리는 경향. Android 진영 레퍼런스는 google-ai-edge/gallery가 거의 유일하게 대형화(⭐24,374).

### ⚠️ 수집 한계

- **`gh` CLI 사용 불가**: 실행 권한이 거부되어 `gh auth status` 확인 자체가 불가했다. 전량 GitHub REST API(비인증) + WebFetch 폴백으로 수집. 비인증 호출은 rate limit이 낮아 다음 회차에는 gh 인증 또는 토큰 확보를 권장한다.
- **Δstar 산출 불가**: 초회 baseline이므로 전 항목 `—(baseline)` 표기. 또한 GitHub API는 "최근 N일 star 증가분"을 제공하지 않으므로, **급증 여부는 2회차부터만 정량 판정 가능**하다. 이번 회차의 "트렌딩" 판단은 created_at(신생 여부)과 절대 star 수 기반의 정성 판단이다.
- **일부 검색 쿼리 오염**: 지정된 `npu OR mobile llm created:>2026-02-07` 쿼리는 GitHub가 OR을 광범위 토큰 매칭으로 처리해 AI 코딩 에이전트·게이트웨이 등 무관 repo가 상위를 점유했다. `on-device AI mobile NPU created:>2026-02-07`, `on-device AI created:>2026-02-07` 등 대체 쿼리로 보완했다.
- **일부 API 응답 말미 절단**: per_page=30 응답 중 18번째 이후 항목이 잘려 반환된 경우가 있었으나, 해당 구간은 star 수가 낮아(대부분 3자리 이하) 선정 결과에 영향 없음.
- **릴리스 표기 원칙**: 모든 태그/날짜는 `/repos/{owner}/{repo}/releases` 응답에서 직접 확인된 값만 기재했다. mlc-llm은 정식 릴리스 태그가 v0.1.dev0(2023-04-29)뿐이라 "정식 태그 릴리스 없음"으로 표기했다(추정 아님).
---

## 📌 워치리스트 (다음 회차 추적)

**최우선**
- [ ] **Apple AFM 3 기술 리포트** — "여름 중 공개" 예고 후 8/7 기준 미공개. AFM 3 Core Advanced의 **20B sparse / 요청당 1~4B 활성 / 전체 가중치를 DRAM이 아닌 NAND flash에 상주** 구조 상세 수치가 나올 가능성. 메모리 크런치 국면에서 가장 중요한 경쟁 정보

**기술 검증**
- [ ] **AnchorKV 20× KV 압축** — 검증이 70B 중심이라 **1~4B 소형 모델 재현성이 핵심 리스크**. 자체 재현 우선순위 높음

**경쟁/생태계**
- [ ] **OPPO Xiaobu Next** — 실제 온디바이스 처리 비중, 클라우드 폴백 조건, 메모리 프레임워크 용량 모두 [미확인]. 정식 출시 시 재조사
- [ ] **mistralai/Shieldstral-1.0-3B** — Likes 165 대비 다운로드 1,511로 "관심 대비 실사용 낮은" 초기 곡선. 다음 회차 Δ로 온디바이스 가드레일 수요의 실체 판정
- [ ] **1bit/2bit/ternary 모델군** (Bonsai-27B-1bit 등) — 다음 회차부터 **파라미터 수가 아닌 "실효 메모리 풋프린트" 기준**을 병행 적용

**운영 개선**
- [ ] `gh` CLI 인증 또는 GitHub 토큰 확보 (이번 회차 비인증 REST API 폴백으로 수집, rate limit 제약)
- [ ] `huggingface.co/api/papers/trending` 엔드포인트가 HTTP 404 → 대체 경로(`daily_papers`) 확정 필요

## 🗓 다가오는 일정

| 일자 | 이벤트 | 확실도 |
|---|---|---|
| **2026-08-12** | **Made by Google** (뉴욕) — Pixel 11 시리즈, Pixel Watch 5 | 공식 확정 (Tensor G6 / Gemini Intelligence 탑재는 루머) |
| 2026-08-12 | Honor Robot Phone 중국 출시 | 공식 확정 |
| 2026년 8월 중 | Qualcomm AI 소프트웨어 플랫폼 공개 (Modular 통합) | 실적발표 예고, 일자 [미확인] |
| **2026-08-29 (AoE)** | **NeurIPS 2026 "Efficient and On-Device AI Agents" 워크샵 마감** | 확정 — **액션 필요** |
| 2026-08-29 | NeurIPS 2026 "AXIOM: Foundations of Efficient Deep Learning" 워크샵 마감 | 확정 |
| 2026-09-09 | ASPLOS 2027 September cycle 마감 | 확정 |
| 2026-09-18~19 / 09-24~25 | ICLR 2027 abstract / full paper 마감 | 출처 간 하루 불일치 — iclr.cc 공식 확인 필수 |
| **2026-09-22~24** | **Qualcomm Snapdragon Summit** (마우이) — 8 Elite Gen 6 / Gen 6 Pro 발표 예상 | 일정 확정, 발표 내용은 루머 |
| 2026 Q3 (9월 유력) | MediaTek Dimensity 9600 시리즈 | 루머 |
| 2026년 9월 | Xiaomi 18 / vivo X500 / OPPO Find X10 동시 경쟁 | 루머 |
| 2026-09-24 / 09-29 | NeurIPS 2026 본회의 / 워크샵 채택 통지 | 확정 |
| 2026년 가을 | Apple iOS 27 + Gemini 기반 신형 Siri 배포 | WWDC26 발표 기준, 일자 [미확인] |
| 2026-10-24~29 | EMNLP 2026 (부다페스트) — efficient methods 트랙 | 확정 |
| 2026-12-02 | EU AI Act 투명성 관련 일부 준수 기한 | 해석 편차 있음 — 법무 확인 필요 |
| 2026-12-06~13 | NeurIPS 2026 (시드니/애틀랜타/파리 분산 개최) | 확정 |

---

## ⚠️ 수집 한계 (전체 종합)

각 섹션 하단에 도메인별 상세 한계를 기재했습니다. 리포트 전체에 영향을 주는 항목만 아래에 종합합니다.

**구조적 한계**
- **초회 baseline이므로 Δ(증감) 판정이 불가능하다.** HuggingFace 다운로드·GitHub star의 "급증" 여부는 **2회차부터만 정량 판정 가능**하며, 이번 회차의 트렌딩 판단은 절대 수치와 신생 여부(created_at) 기반의 정성 판단이다.
- **커버 기간 경계(7/8) 직전 항목 처리**: *Is Your NPU Ready for LLMs?*(7/6, 2일 차이), MLX v0.32.0(7/7, 1일 차이), KleidiAI v1.28.0(7/7) 등은 규칙에 따라 정식 항목에서 제외하고 참고로만 표기했다. 중요도 대비 누락 리스크가 있어 워치리스트에 이월했다.

**접근 실패 소스**
- `huggingface.co/api/papers/trending` — **HTTP 404** (2개 도메인에서 동일 확인). `daily_papers`로 대체했으나 on-device 직결 논문 없음
- `gh` CLI — 실행 권한 거부. 비인증 GitHub REST API + WebFetch 폴백으로 전량 수집 (rate limit 제약)
- HF 트렌딩 API가 요청 50건 중 34건만 반환 (응답 절단). 누락분에 10B 이하 후보가 추가 존재할 가능성
- `abs:"efficient inference"` arXiv 쿼리가 30건 요청 대비 7건만 반환
- MICRO 2026 채택 논문 목록, MediaTek NeuroPilot 릴리스 노트 — 공개 확인 불가

**커버 기간 내 신규 없음이 확인된 항목** (조용히 건너뛴 것이 아님)
- **Apple**: 7/8~8/7 내 신규 온디바이스 발표 없음. AFM 3 / Siri Expressive Voices / Foundation Models 개편은 전부 WWDC26(6월) 발표분. 유일한 기간 내 확인 건은 중국 CAC 备案 등재(7/15)
- **Google**: ML Kit GenAI API 업데이트는 I/O '26(5월) 발표분. 7~8월 신규 플랫폼 발표 미확인
- **Microsoft**: Copilot+ NPU 전용 노선 철회는 Build 2026(6/2~3)로 기간 외
- **ExecuTorch / MLX / MLC-LLM**: 커버 기간 내 신규 태그 릴리스 없음
- **M&A·인사**: Qualcomm-Modular 1건 외 온디바이스 AI 관련 유의미한 건 미확인

**신뢰도 주의**
- 차세대 실리콘 스펙(Snapdragon 8 Elite Gen 6 Pro, Dimensity 9600, Tensor G6)은 **전량 유출 기반 [루머]**. 벤더 공식 확인 없음
- 업계 섹션의 Counterpoint/IDC/TrendForce 수치는 **2차 인용** 기준. 유료 리서치 원본 미검증
- arXiv 항목 다수는 **초록 기준** 정리. 코드 공개 여부·측정 하드웨어 상세는 PDF 원문 미확인
- 상용 벤더(Qualcomm/MediaTek/Apple)의 비공개 최적화 스택 1차 자료는 접근 불가. 공개 논문·릴리스 기준으로만 작성

---
*생성: on-device-ai-monitor 에이전트 | 6개 도메인 병렬 조사 | 근거 파일: `reports/_wip/2026-08-07/` | 지표 기준선: `reports/data/2026-08-07-metrics.json`*
