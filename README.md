# On-device AI 동향 브리핑

On-device AI 기술 동향을 매일 자동으로 수집·정리해 공개하는 리포지토리입니다.

**웹으로 보기 → https://samiepapa.github.io/On-device-AI-Briefing/**

## 모니터링 항목

매 회차 아래 6개 도메인을 조사합니다.

| # | 도메인 | 범위 |
|---|---|---|
| 1 | 모델 최적화 | Quantization(PTQ/QAT, INT4/FP8/MXFP4, 1-bit·ternary), Pruning/Sparsity, Distillation, SLM·Hybrid attention 아키텍처 |
| 2 | Inference 최적화 | llama.cpp · ExecuTorch · MLC-LLM · ONNX Runtime · MNN · MLX, 벤더 NPU SDK, speculative decoding, KV cache 압축 |
| 3 | 업계 동향 | 반도체·플랫폼·단말 벤더 발표, 상용화 사례, 규제 |
| 4 | 학계 동향 | arXiv, NeurIPS·ICML·ICLR·MLSys·ASPLOS·ISCA 등 학회, 산업 연구소 |
| 5 | HuggingFace | 트렌딩·다운로드 급증 모델, 10B 이하 / quantized / mobile-friendly 위주 |
| 6 | GitHub | on-device AI · LLM inference · model compression 주제의 star 상위 및 급증 repo |

업계 동향은 검색 결과 대신 **공식 1차 소스 12종**(Qualcomm Developer Blog, Google Developers/DeepMind, Apple Developer News, Meta AI, OpenAI, Anthropic, Epoch AI Trends, HuggingFace Spaces, Stanford HAI AI Index, MIT Technology Review, CB Insights)을 직접 조회합니다.

## 리포트 구성

- **Executive Summary** — 핵심 3건. 각 항목에 판단의 **근거와 출처 링크**를 함께 제시
- **도메인별 상세** — 항목마다 무엇 / 수치 / 성숙도(논문·오픈소스 구현·상용) / 출처 URL
- **워치리스트 · 다가오는 일정 · 수집 한계**

확인되지 않은 수치는 `[미확인]`으로 표기하며, 접근하지 못한 소스는 `수집 한계`에 사유와 함께 남깁니다.

## 자동 생성

매일 **08:00 KST** 에 자동 실행됩니다.

| 시점 | 커밋 |
|---|---|
| ~1분 | `wip: 브리핑 시작` — 진행표 생성 |
| ~5분 | `wip: 도메인 N/6 완료` |
| ~16분 | `brief: YYYY-MM-DD on-device AI 동향` — 최종 |

6개 도메인은 병렬로 조사하며, 완료된 섹션부터 순차적으로 커밋됩니다. 실행 중에는 `reports/_wip/<날짜>/STATUS.md` 에서 진행 상황을 볼 수 있습니다.

## 디렉터리

```
reports/YYYY-MM-DD-on-device-ai-briefing.md   브리핑 본문
reports/data/YYYY-MM-DD-metrics.json          회차별 원시 지표 (증감 계산 기준)
reports/_wip/YYYY-MM-DD/STATUS.md             생성 중 진행표
docs/index.html                               GitHub Pages 뷰어 (외부 의존성 없음)
```

## 뷰어

`docs/index.html` 한 파일로 동작합니다. 외부 CDN·라이브러리를 쓰지 않아 네트워크가 제한된 환경에서도 그대로 렌더링됩니다. 리포트 마크다운을 파싱해 카드와 상세 페이지를 자동 구성하므로, 리포트가 추가되면 별도 배포 없이 최신 상태가 됩니다.
