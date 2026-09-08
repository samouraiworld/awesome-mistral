# Awesome Mistral [![Awesome](https://awesome.re/badge.svg)](https://awesome.re) ![Last Updated](https://img.shields.io/github/last-commit/samouraiworld/awesome-mistral)

> A curated list of awesome resources, tools, libraries, and projects for the Mistral AI ecosystem.

An independent community directory of Mistral AI models, developer tools, research and product updates. Mistral publishes both open-weight models and proprietary services; each model has its own license and availability conditions.

Curated for AI engineers, researchers and developers. Inclusion does not imply endorsement by Mistral AI or compatibility with every Mistral model.

**Last editorial review: 2026-09-08.** Reviewed weekly; see the [audit and sources](audits/2026-09-08.md), [maintenance process](MAINTENANCE.md), and [security policy](SECURITY.md). Star counts are rounded down snapshots from that review, not quality scores.

**Legend:**

- 🧠 Official Mistral AI
- 🌍 Community project
- 🧪 Experimental

---

## Contents

- [Latest Updates](#latest-updates)
- [Why Mistral?](#why-mistral)
- [Official Mistral Resources](#official-mistral-resources)
- [Model Families](#model-families)
- [Community Fine-Tuned Models](#community-fine-tuned-models)
- [SDKs & APIs](#sdks--apis)
- [Inference & Deployment](#inference--deployment)
- [Fine-Tuning & Training](#fine-tuning--training)
- [Model Merging & Quantization](#model-merging--quantization)
- [Agents & Orchestration](#agents--orchestration)
- [Tooling & Dev Experience](#tooling--dev-experience)
- [Community Projects](#community-projects)
- [Demos & Examples](#demos--examples)
- [Tutorials & Guides](#tutorials--guides)
- [Benchmarks & Evaluation](#benchmarks--evaluation)
- [Research & Papers](#research--papers)
- [Talks & Media](#talks--media)
- [Ecosystem & Community](#ecosystem--community)
- [Contributing](#contributing)
- [License](#license)

---

## Latest Updates

Dates below are publication or availability dates, not the date this list was edited. Older announcements remain in the topic sections. Review [Mistral News](https://mistral.ai/news/), the [API changelog](https://docs.mistral.ai/resources/changelogs), and [product release notes](https://docs.mistral.ai/resources/release-notes) for the complete history.

- **2026-09-08 · [Mistral raises €3B](https://mistral.ai/news/mistral-makes-sovereign-open-weight-ai-to-frontier/)** – Series D at a post-money valuation above €21B, led by Samsung Electronics with Scaleup Europe Fund (EQT) and PSG Equity; Mistral describes it as the largest equity round by a European technology company and earmarks it for frontier research, compute and international expansion.
- **2026-09-04 · [Vibe 2.25.0](https://github.com/mistralai/mistral-vibe/releases/tag/v2.25.0)** – Adds an experimental skills browser and `vibe update`, extends connector support, and fixes approved-file-operation handling and MCP credential isolation.
- **2026-08-31 · [OCR 4.1 reaches general availability](https://docs.mistral.ai/resources/changelogs)** – `mistral-ocr-4-1`, first released July 16, is now GA. `mistral-ocr-latest` and `mistral-ocr-4` point to this version.
- **2026-08-24 · [Mistral × HUMAIN](https://mistral.ai/news/mistral-x-humain/)** – Announced collaboration on infrastructure, model localization and AI deployment in Saudi Arabia and the region; planned focus areas include Arabic, cybersecurity and voice.
- **2026-08-20 · [API key expiration policies](https://docs.mistral.ai/resources/release-notes)** – Public preview of organization/workspace validity limits and expiration notifications for new or rotated keys; existing keys are unaffected.
- **2026-08-20 · [Agentic Search](https://mistral.ai/news/agentic-search/)** – Retrieval tools for navigating and reading documents across sources, available through Search Toolkit, Studio and Vibe.
- **2026-08-11 · [Regional inference and European infrastructure](https://mistral.ai/news/regional-inference-open-models-new-compute/)** – Regional endpoints, Priority Tier preview, third-party model hosting and European compute commitments. The catalog now serves its first third-party model, [Z.ai GLM 5.2](https://z.ai/blog/glm-5.2) (`zai-glm-5-2`, public preview, 1M context), hosted unmodified by Mistral and not a Mistral model.
- **2026-08-04 · [Shieldstral](https://mistral.ai/news/shieldstral/)** – Open-weight safety classifier accepting policies expressed in natural language.

**Upcoming:** the [API changelog](https://docs.mistral.ai/resources/changelogs) schedules `labs-leanstral-1-5` retirement for **2026-09-30**. Downloadable weights and hosted API availability are separate; recheck the official schedule before migrating.

---

## Why Mistral?

Capabilities and deployment options vary by model and hosting provider:

| Aspect | What to check |
|--------|-------------------|
| **Open Weights** | Models like Mistral Medium 3.5 (Modified MIT), Mistral Large 3, Small 4, and Ministral are open-weight, enabling local deployment and full control |
| **Efficiency** | Mistral Small 4 (119B/6.5B active) and Large 3 (675B/41B active) use MoE parameter routing; Medium 3.5 provides high-density performance (128B); Ministral 3B/8B/14B are optimized for edge |
| **European Sovereignty** | Regional inference and deployment options; verify the selected region, processing terms and service-specific controls |
| **Cost Efficiency** | Compare current API prices with the infrastructure and operating costs of self-hosting |
| **Innovation** | MoE architectures, hybrid reasoning models, formal proof agents (Leanstral), and streaming speech models |
| **Full-Stack Platform** | Forge (enterprise model training) + Mistral Compute / AI Cloud (European GPU cloud) + Studio (agents & apps) + Vibe (unified work & coding agent) |

---

## Official Mistral Resources

- 🧠 [AI Studio (la Plateforme)](https://mistral.ai/products/studio/) – Developer console featuring Workflows for production orchestration, Connectors (MCP), API keys, and model access.
- 🧠 [Mistral AI](https://mistral.ai) – Official company website with product information and announcements.
- 🧠 [Mistral AI Documentation](https://docs.mistral.ai) – Comprehensive API documentation, guides, and model specifications.
- 🧠 [Mistral AI GitHub](https://github.com/mistralai) – Official GitHub organization and public repositories.
- 🧠 [Mistral Compute (AI Cloud)](https://mistral.ai/products/aicloud/) – GPU infrastructure for training and inference; consult the product page for deployment options and access.
- 🧠 [Mistral Cookbook](https://github.com/mistralai/cookbook) – Official notebooks and examples for common use cases.
- 🧠 [Mistral Forge](https://mistral.ai/news/forge) – Enterprise platform for training frontier-grade models on proprietary data.
- 🧠 [Mistral Vibe](https://github.com/mistralai/mistral-vibe) – Native CLI coding assistant featuring cloud-async Remote Agents and sandbox PR generation.
- 🧠 [mistral-common](https://github.com/mistralai/mistral-common) – Official tokenization and pre-processing library.
- 🧠 [mistral-finetune](https://github.com/mistralai/mistral-finetune) – ⚠️ Archived, no longer maintained – use [Axolotl](https://github.com/axolotl-ai-cloud/axolotl), [Unsloth](https://github.com/unslothai/unsloth), or Hugging Face [TRL](https://github.com/huggingface/trl) instead.
- 🧠 [mistral-inference](https://github.com/mistralai/mistral-inference) ⭐ 10k+ – ⚠️ Archived, no longer maintained – use [vLLM](https://github.com/vllm-project/vllm), [mistral.rs](https://github.com/EricLBuehler/mistral.rs), or the Mistral API instead.
- 🧠 [Model Lifecycle Policy](https://docs.mistral.ai/inference/model-lifecycle) – Official Labs → Preview → GA → Deprecated → Retired policy; individual model cards carry retirement dates.
- 🧠 [Platform Docs Public](https://github.com/mistralai/platform-docs-public) – Open-source documentation repository.
- 🧠 [Vibe](https://mistral.ai/products/vibe/) – Mistral's unified agent (formerly le Chat) with Work, Code, and Chat modes across web, mobile, CLI, and VS Code.

---

## Model Families

### Flagship Models (API)

Snapshot checked on **2026-09-08** against the [model catalog](https://docs.mistral.ai/models) and [pricing](https://docs.mistral.ai/inference/pricing). License refers to downloadable weights where available; API usage has separate service terms. Context is the advertised window, not a hardware requirement.

| Model | Context | License | Best For |
|-------|---------|---------|----------|
| **Mistral Small 4** | 256k | Apache 2.0 | Hybrid reasoning + coding + multimodal (119B MoE / 6.5B active) |
| **Mistral Large 3** | 256k | Apache 2.0 | Complex reasoning, multilingual, coding, vision (675B / 41B active) |
| **Mistral Medium 3.5** | 256k | Modified MIT | Unified reasoning, coding, and vision (128B dense) |
| **Ministral 3** | 256k | Apache 2.0 | Low-latency, cost-sensitive and edge applications (3B / 8B / 14B, with vision) |
| **Mistral OCR 4.1** | — | Proprietary | Document parsing with bounding boxes, block labels & block-level confidence scores, 170 languages ($4/1k pages) |

### Open-Weight Models

> Entries marked *(legacy)* are older models retained for self-hosting and reproducibility. Dates below are published API retirement dates from the [official model catalog](https://docs.mistral.ai/models); some model pages still say Deprecated after that date. Downloadable weights do not establish live API availability.

#### General Purpose & Reasoning

- 🧠 [Magistral Small 1.2](https://huggingface.co/mistralai/Magistral-Small-2509) – Open 24B multimodal reasoning model (Apache 2.0, 128k context, `[THINK]` tokens). *(legacy – published API retirement 2026-07-31; reasoning now lives in Small 4 / Medium 3.5)*
- 🧠 [Mistral Large 3](https://huggingface.co/mistralai/Mistral-Large-3-675B-Instruct-2512) – Flagship MoE (675B / 41B active) with reasoning and vision.
- 🧠 [Mistral Medium 3.5](https://huggingface.co/mistralai/Mistral-Medium-3.5-128B) – Dense flagship model (128B) unifying instruction-following, reasoning, and coding with 256k context and configurable `reasoning_effort`.
- 🧠 [Mistral Small 3.2](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) – High-performance dense 24B model (v3.2). *(legacy – published API retirement 2026-07-31, superseded by Small 4)*
- 🧠 [Mistral Small 4](https://huggingface.co/mistralai/Mistral-Small-4-119B-2603) – Hybrid MoE (119B / 6.5B active) unifying reasoning, coding, and multimodal. Configurable `reasoning_effort`.
- 🧠 [Mixtral 8x22B](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1) – MoE model (141B total / 39B active). *(legacy – API retired 2025-03-30)*

#### Edge & On-Device (Ministral)

- 🧠 [Ministral 14B](https://huggingface.co/mistralai/Ministral-3-14B-Instruct-2512) – Dense edge model with vision (14B).
- 🧠 [Ministral 3B](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512) – Ultralight model for mobile/browser (3B).
- 🧠 [Ministral 8B](https://huggingface.co/mistralai/Ministral-3-8B-Instruct-2512) – High-performance edge model with vision (8B).

#### Coding & Agentic (Devstral)

- 🧠 [Devstral 2](https://huggingface.co/mistralai/Devstral-2-123B-Instruct-2512) – 123B coding model (Modified MIT License). Mistral reports 72.2% on SWE-bench Verified. *(legacy – published API retirement 2026-07-31, superseded by Medium 3.5)*
- 🧠 [Devstral Small 2](https://huggingface.co/mistralai/Devstral-Small-2-24B-Instruct-2512) – 24B coding model (Apache 2.0) for local agents. Mistral reports 68.0% on SWE-bench Verified. *(legacy – published API retirement 2026-03-31)*

#### Multimodal (Pixtral)

- 🧠 [Pixtral 12B](https://huggingface.co/mistralai/Pixtral-12B-2409) – Efficient vision-language model. *(legacy – published API retirement 2025-12-31, superseded by Ministral 3 14B)*
- 🧠 [Pixtral Large](https://huggingface.co/mistralai/Pixtral-Large-Instruct-2411) – 124B multimodal model building on Mistral Large 2. *(legacy – published API retirement 2026-05-31; vision now native in Medium 3.5 / Large 3)*

#### Audio & Speech (Voxtral)

- 🧠 [Voxtral Mini 3B](https://huggingface.co/mistralai/Voxtral-Mini-3B-2507) – Compact speech understanding model (Apache 2.0). *(legacy – published API retirement 2026-05-31, superseded by Voxtral Mini Transcribe 2, `voxtral-mini-2602`, API only)*
- 🧠 [Voxtral Mini 4B Realtime](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602) – Natively streaming speech-to-text, sub-500ms latency, 13 languages (Apache 2.0).
- 🧠 [Voxtral Small 24B](https://huggingface.co/mistralai/Voxtral-Small-24B-2507) – High-accuracy speech understanding and transcription (Apache 2.0).
- 🧠 [Voxtral TTS](https://huggingface.co/mistralai/Voxtral-4B-TTS-2603) – 4B text-to-speech model, 9 languages, 24 kHz output (CC BY-NC 4.0).

### Specialized Models

- 🧠 [Codestral Embed](https://docs.mistral.ai/models/codestral-embed-25-05) – API embedding model for code retrieval (`codestral-embed`).
- 🧠 [Mistral Embed](https://docs.mistral.ai/models/mistral-embed-23-12) – API embedding model for text retrieval (`mistral-embed`).

- 🧠 [Codestral 25.08](https://docs.mistral.ai/models/codestral-25-08) – Proprietary API model for fill-in-the-middle code completion (`codestral-2508`, 128k context); no downloadable weights listed for this version.
- 🧠 [Leanstral 1.5](https://huggingface.co/mistralai/Leanstral-1.5-119B-A6B) – Lean 4 formal proof agent (119B / 6.5B active, Apache 2.0). Mistral reports 587/672 solved PutnamBench problems. Free on the API as `labs-leanstral-1-5` (scheduled for retirement September 30, 2026).
- 🧠 [Mistral Moderation 2](https://docs.mistral.ai/models/mistral-moderation-26-03) – Content moderation with 128k context and jailbreaking, dangerous, and criminal detection (API `mistral-moderation-2603`, free).
- 🧠 [Mistral OCR 4.1](https://mistral.ai/news/ocr-4/) – Document intelligence with bounding boxes, block classification, and page/block/word-level confidence scores across 170 languages (API `mistral-ocr-4-1`; `mistral-ocr-latest` and `mistral-ocr-4` alias to it; $4/1k pages, $2 with Batch API).
- 🧠 [Shieldstral](https://huggingface.co/mistralai/Shieldstral-1.0-3B) – Policy-adaptive multimodal safety classifier (3.8B total, Apache 2.0): accepts plain-language moderation policies at inference time, no retraining required.

#### Robotics (Robostral)

- 🧠 [Robostral Navigate](https://mistral.ai/news/robostral-navigate/) – Embodied navigation model (8B) using a single RGB camera for wheeled, legged, and flying robots; Mistral reports 76.6% success on unseen R2R-CE environments (proprietary, enterprise access).

---

## Community Fine-Tuned Models

Historical community fine-tunes of earlier Mistral models, retained for reproducibility and comparison. These fixed releases are not current-model recommendations; check their model cards, licenses and hardware requirements.

### Instruction & Chat

- 🌍 [Dolphin-2.8-Mistral-7B](https://huggingface.co/dphn/dolphin-2.8-mistral-7b-v02) – Uncensored model by Eric Hartford.
- 🌍 [Hermes-2-Pro-Mistral-7B](https://huggingface.co/NousResearch/Hermes-2-Pro-Mistral-7B) – Function calling and JSON mode specialist.
- 🌍 [Nous-Hermes-2-Mistral-7B-DPO](https://huggingface.co/NousResearch/Nous-Hermes-2-Mistral-7B-DPO) – DPO-enhanced with strong benchmark scores.
- 🌍 [OpenChat-3.5-0106](https://huggingface.co/openchat/openchat-3.5-0106) – Mistral-based model trained with C-RLFT.
- 🌍 [OpenHermes-2.5-Mistral-7B](https://huggingface.co/teknium/OpenHermes-2.5-Mistral-7B) – Instruction-tuned Mistral 7B model by Teknium.
- 🌍 [Zephyr-7B-beta](https://huggingface.co/HuggingFaceH4/zephyr-7b-beta) – Mistral 7B fine-tune trained with DPO by Hugging Face H4.

### Specialized

- 🌍 [Mistral-7B-OpenOrca](https://huggingface.co/Open-Orca/Mistral-7B-OpenOrca) – Trained on OpenOrca dataset.
- 🌍 [MistralLite](https://huggingface.co/amazon/MistralLite) – AWS-optimized with 32k context window.
- 🌍 [WizardMath-7B-V1.1](https://huggingface.co/WizardLMTeam/WizardMath-7B-V1.1) – Math-specialized Mistral fine-tune.

### Quantized Model Collections

- 🌍 [bartowski](https://huggingface.co/bartowski) – High-quality GGUF quantizations.
- 🌍 [TheBloke](https://huggingface.co/TheBloke) – Extensive GGUF/AWQ/GPTQ quantized model repository.

---

## SDKs & APIs

### Official SDKs

Checked releases: [Python v2.9.4](https://github.com/mistralai/client-python/releases/tag/v2.9.4) and [TypeScript v2.6.4](https://github.com/mistralai/client-ts/releases/tag/v2.6.4), both published 2026-08-21.

**Security:** [MAI-2026-002](https://docs.mistral.ai/resources/security-advisories/MAI-2026-002) documents compromised SDK releases from May 2026, including Python `mistralai` 2.4.6 and npm `@mistralai/mistralai` 2.2.2–2.2.4. Consult the advisory for the full affected-package list and remediation; these releases are not recommended.

- 🧠 [client-python](https://github.com/mistralai/client-python) – Official Python client library.
- 🧠 [client-ts](https://github.com/mistralai/client-ts) – Official TypeScript/JavaScript client library.

### Community SDKs

- 🌍 [@ai-sdk/mistral](https://ai-sdk.dev/providers/ai-sdk-providers/mistral) – Vercel AI SDK provider.
- 🌍 [@langchain/mistralai](https://docs.langchain.com/oss/javascript/integrations/chat/mistral) – LangChain.js integration.
- 🌍 [mistral.rs](https://github.com/EricLBuehler/mistral.rs) ⭐ 7k+ – Rust inference with ISQ, LoRA, quantization.

---

## Inference & Deployment

### High-Performance Inference

- 🌍 [ExLlamaV2](https://github.com/turboderp-org/exllamav2) – Fast inference with EXL2 quantization. Activity watch: last upstream push 2026-03-04; reassess at the next review.
- 🌍 [llama.cpp](https://github.com/ggml-org/llama.cpp) ⭐ 127k+ – CPU/GPU inference with GGUF quantization.
- 🌍 [SGLang](https://github.com/sgl-project/sglang) ⭐ 35k+ – Fast serving with RadixAttention.
- 🌍 [Text Generation Inference](https://github.com/huggingface/text-generation-inference) ⭐ 10k+ – ⚠️ Archived, no longer maintained – use vLLM or SGLang instead.
- 🌍 [vLLM](https://github.com/vllm-project/vllm) ⭐ 91k+ – High-throughput with PagedAttention. Excellent Mistral support.

### Local Inference

- 🌍 [GPT4All](https://www.nomic.ai/gpt4all) – Local inference with Mistral support.
- 🌍 [Jan](https://jan.ai) – Open-source ChatGPT alternative running locally.
- 🌍 [LM Studio](https://lmstudio.ai) – Desktop GUI for local LLMs.
- 🌍 [Msty](https://msty.ai) – Desktop app for running local LLMs.
- 🌍 [Ollama](https://ollama.com) ⭐ 180k+ – Simple CLI for local Mistral models.
- 🧪 [voxtral.c](https://github.com/antirez/voxtral.c) – Experimental C inference for Voxtral Mini 4B Realtime. Activity watch: last upstream push 2026-02-15; verify compatibility before use.

### Cloud & Container Deployment

- 🌍 [LocalAI](https://github.com/mudler/LocalAI) ⭐ 48k+ – OpenAI-compatible local API server.
- 🌍 [MLC LLM](https://github.com/mlc-ai/mlc-llm) ⭐ 23k+ – Universal deployment (iOS/Android); check supported model architectures before deployment.
- 🌍 [SkyPilot](https://github.com/skypilot-org/skypilot) ⭐ 10k+ – Run on any cloud with cost optimization.
- 🌍 [TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM) ⭐ 14k+ – NVIDIA's optimized inference engine for Mistral Large 3 and other Mistral models on NVIDIA GPUs.

---

## Fine-Tuning & Training

### Fine-Tuning Frameworks

- 🌍 [Axolotl](https://github.com/axolotl-ai-cloud/axolotl) ⭐ 12k+ – Streamlined LoRA/QLoRA/full fine-tuning.
- 🌍 [Hugging Face PEFT](https://github.com/huggingface/peft) ⭐ 21k+ – Parameter-Efficient Fine-Tuning.
- 🌍 [Hugging Face TRL](https://github.com/huggingface/trl) ⭐ 19k+ – RLHF and DPO training.
- 🌍 [LLaMA-Factory](https://github.com/hiyouga/LlamaFactory) ⭐ 74k+ – Unified fine-tuning framework.
- 🌍 [torchtune](https://github.com/meta-pytorch/torchtune) ⭐ 5k+ – ⚠️ No longer maintained – development wound down in 2025; use Axolotl or Unsloth instead.
- 🌍 [Unsloth](https://github.com/unslothai/unsloth) ⭐ 75k+ – Fine-tuning and local inference tools; performance depends on the model and hardware.

### Training Infrastructure

- 🌍 [DeepSpeed](https://github.com/deepspeedai/DeepSpeed) ⭐ 43k+ – Distributed training optimization.
- 🌍 [Hugging Face Accelerate](https://github.com/huggingface/accelerate) ⭐ 9k+ – Simple distributed training.

---

## Model Merging & Quantization

### Model Merging

- 🌍 [LazyMergeKit](https://colab.research.google.com/drive/1obulZ1ROXHjYLn6PPZJwRR6GzgQogxxb) – Colab notebook for easy merging.
- 🌍 [MergeKit](https://github.com/arcee-ai/mergekit) ⭐ 7k+ – Toolkit for merging LLMs (SLERP, TIES, DARE).

### Quantization Tools

- 🌍 [AutoAWQ](https://github.com/casper-hansen/AutoAWQ) – ⚠️ Archived, no longer maintained – use bitsandbytes or llama.cpp GGUF instead.
- 🌍 [AutoGPTQ](https://github.com/AutoGPTQ/AutoGPTQ) ⭐ 5k+ – ⚠️ Archived, no longer maintained – use bitsandbytes or llama.cpp GGUF instead.
- 🌍 [bitsandbytes](https://github.com/bitsandbytes-foundation/bitsandbytes) ⭐ 8k+ – 4-bit and 8-bit quantization.
- 🌍 [GGUF](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md) ⭐ 15k+ – Quantization format specification.

---

## Agents & Orchestration

### Agent Frameworks

- 🌍 [Aeon](https://github.com/aeonfun/aeon) – Autonomous agent framework that runs unattended on GitHub Actions and drives Mistral Vibe as one of six coding-agent harnesses behind a single contract, with quality scoring, persistent memory, and a self-healing loop.
- 🌍 [AutoGen](https://github.com/microsoft/autogen) ⭐ 60k+ – Microsoft's multi-agent framework.
- 🌍 [CrewAI](https://github.com/crewAIInc/crewAI) ⭐ 58k+ – Multi-agent orchestration.
- 🌍 [Haystack](https://github.com/deepset-ai/haystack) ⭐ 26k+ – End-to-end NLP framework.
- 🌍 [LangChain](https://github.com/langchain-ai/langchain) ⭐ 145k+ – LLM app framework with native Mistral support.
- 🌍 [LlamaIndex](https://github.com/run-llama/llama_index) ⭐ 52k+ – Data framework for RAG with Mistral.
- 🌍 [LobeHub](https://github.com/lobehub/lobehub) ⭐ 82k+ – Agent operations platform (formerly Lobe Chat) that hires, schedules, and reports on a fleet of AI agents.
- 🌍 [PydanticAI](https://github.com/pydantic/pydantic-ai) ⭐ 19k+ – Type-safe AI agent framework.
- 🌍 [RocketRide](https://github.com/rocketride-org/rocketride-server) ⭐ 8k+ – C++ AI pipeline engine with dedicated Mistral text/vision nodes, Python/TypeScript SDKs, and a visual IDE.
- 🌍 [Semantic Kernel](https://github.com/microsoft/semantic-kernel) ⭐ 28k+ – Microsoft's AI orchestration SDK.

### Function Calling & Structured Output

- 🌍 [Instructor](https://github.com/567-labs/instructor) ⭐ 13k+ – Structured outputs with Pydantic.
- 🌍 [Marvin](https://github.com/PrefectHQ/marvin) ⭐ 6k+ – AI functions with type hints.
- 🧠 [Mistral Function Calling](https://docs.mistral.ai/studio/conversations/function-calling) – Native function calling docs.
- 🌍 [Outlines](https://github.com/dottxt-ai/outlines) ⭐ 15k+ – Guaranteed structured generation.

---

## Tooling & Dev Experience

### IDE Extensions & Code Assistants

- 🌍 [Aider](https://github.com/Aider-AI/aider) ⭐ 48k+ – AI pair programming in terminal.
- 🌍 [Continue](https://github.com/continuedev/continue) ⭐ 35k+ – Open-source AI code assistant (VSCode/JetBrains).
- 🧠 [Mistral Code](https://mistral.ai/news/mistral-code) – Official AI coding assistant (VS Code/JetBrains) built on the Mistral coding stack.
- 🌍 [Tabby](https://github.com/TabbyML/tabby) ⭐ 33k+ – Self-hosted GitHub Copilot alternative.

### Development Tools

- 🧠 [Mistral CLI](https://github.com/mistralai/cli) – Official standalone command-line releases for macOS and Linux, with installation documentation and SHA-256 checksums; this repository distributes binaries rather than source.

- 🌍 [Langfuse](https://github.com/langfuse/langfuse) ⭐ 34k+ – Open-source LLM observability.
- 🌍 [LiteLLM](https://github.com/BerriAI/litellm) ⭐ 58k+ – Unified API for 100+ LLMs.
- 🌍 [Phoenix](https://github.com/Arize-ai/phoenix) ⭐ 11k+ – ML observability for LLM apps.
- 🌍 [Promptfoo](https://github.com/promptfoo/promptfoo) ⭐ 24k+ – LLM evaluation and red-teaming.
- 🌍 [Weights & Biases](https://wandb.ai) – Experiment tracking with LLM support.

---

## Community Projects

### Chat Interfaces

- 🌍 [LibreChat](https://github.com/danny-avila/LibreChat) ⭐ 42k+ – Multi-model chat interface.
- 🌍 [Open WebUI](https://github.com/open-webui/open-webui) ⭐ 151k+ – Self-hosted ChatGPT-like UI.

### RAG & Knowledge Management

- 🌍 [Khoj](https://github.com/khoj-ai/khoj) ⭐ 37k+ – AI second brain.
- 🌍 [LocalGPT](https://github.com/PromtEngineer/localGPT) ⭐ 22k+ – Chat with documents locally.
- 🌍 [Onyx](https://github.com/onyx-dot-app/onyx) ⭐ 31k+ – Enterprise Q&A over internal docs (formerly Danswer).
- 🌍 [PrivateGPT](https://github.com/zylon-ai/private-gpt) ⭐ 57k+ – Private document Q&A.
- 🌍 [Quivr](https://github.com/The-Vibe-Company/quivr) ⭐ 39k+ – Personal knowledge base.

### Specialized Applications

- 🌍 [Fabric](https://github.com/danielmiessler/Fabric) ⭐ 43k+ – AI augmentation framework.
- 🌍 [GPT Researcher](https://github.com/assafelovic/gpt-researcher) ⭐ 29k+ – Autonomous research agent.
- 🌍 [OpenHands](https://github.com/OpenHands/OpenHands) ⭐ 86k+ – AI software engineer (formerly OpenDevin).

---

## Demos & Examples

### Official Examples

See the [Mistral Cookbook](https://github.com/mistralai/cookbook) for notebooks covering RAG, tools, agents and embeddings.

- 🧠 [Agentic Search Guide](https://docs.mistral.ai/studio/search/agentic-search) – Multi-step retrieval (`search`, `open`, `navigate`, `read`, `grep`) over Libraries and Search Toolkit indexes.
- 🧠 [API Examples](https://docs.mistral.ai/api/) – Complete API reference with examples.

### Community Examples

- 🌍 [LangGraph](https://github.com/langchain-ai/langgraph) ⭐ 41k+ – Stateful multi-agent and workflow examples with Mistral.

---

## Tutorials & Guides

### Getting Started

- 🧠 [Mistral Quickstart](https://docs.mistral.ai/getting-started/quickstarts/developer/first-api-request) – Official getting started guide (first API request, agents, RAG, workflows).
- 🧠 [Model Selection Guide](https://docs.mistral.ai/models) – Choosing the right model, with the current lineup and lifecycle status.
- 🌍 [Run Mistral Locally](https://ollama.com/library/mistral) – Ollama setup guide.

### Fine-Tuning Tutorials

- 🌍 [Axolotl Mistral Examples](https://github.com/axolotl-ai-cloud/axolotl/tree/main/examples/mistral) – Config examples.
- 🧠 [Mistral Fine-Tuning API](https://docs.mistral.ai/resources/deprecated/finetuning) – ⚠️ Deprecated, no longer actively supported – use the open-source frameworks below or [Forge](https://mistral.ai/products/forge/) for enterprise training.
- 🌍 [QLoRA Guide](https://huggingface.co/blog/4bit-transformers-bitsandbytes) – 4-bit fine-tuning.
- 🌍 [Unsloth Tutorials](https://github.com/unslothai/notebooks) ⭐ 5k+ – Official Unsloth fine-tuning notebooks, including Mistral-family examples.

### RAG & Applications

- 🌍 [LangChain + Mistral](https://docs.langchain.com/oss/python/integrations/chat/mistralai) – LangChain integration.
- 🌍 [LlamaIndex + Mistral](https://developers.llamaindex.ai/python/framework/integrations/llm/mistralai/) – RAG with LlamaIndex.
- 🧠 [RAG with Mistral](https://docs.mistral.ai/studio/knowledge-rag/rag_quickstart) – Official RAG quickstart.

---

## Benchmarks & Evaluation

### Leaderboards

- 🌍 [Arena](https://arena.ai/) – Human preference rankings (formerly LMArena / Chatbot Arena).
- 🌍 [Artificial Analysis](https://artificialanalysis.ai/) – LLM quality and speed benchmarks.
- 🌍 [Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) – Hugging Face benchmarks.

### Evaluation Frameworks

- 🌍 [HELM](https://github.com/stanford-crfm/helm) – Stanford's holistic evaluation.
- 🌍 [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) ⭐ 13k+ – EleutherAI's eval framework.
- 🌍 [OpenCompass](https://github.com/open-compass/opencompass) ⭐ 7k+ – Comprehensive LLM evaluation.

### Code Benchmarks

- 🌍 [BigCodeBench](https://github.com/bigcode-project/bigcodebench) – ⚠️ Archived, no longer maintained – use EvalPlus or HumanEval instead.
- 🌍 [EvalPlus](https://github.com/evalplus/evalplus) – Published code-evaluation suite; activity watch, last upstream push 2025-10-02.
- 🌍 [HumanEval](https://github.com/openai/human-eval) – Historical code-generation benchmark accompanying the 2021 paper; retained for reproducibility.

---

## Research & Papers

### Mistral Technical Reports

- 🧠 [Introducing Mistral 3](https://mistral.ai/news/mistral-3/) – Mistral Large 3 / Ministral 3 family announcement and benchmarks.
- 🧠 [Leanstral 1.5 Blog](https://mistral.ai/news/leanstral-1-5/) – Lean 4 formal proof agent update.
- 🧠 [Mistral 7B](https://arxiv.org/abs/2310.06825) – Foundational 7B architecture paper.
- 🧠 [Mistral Small 4 Blog](https://mistral.ai/news/mistral-small-4) – Hybrid MoE architecture announcement.
- 🧠 [Mixtral of Experts](https://arxiv.org/abs/2401.04088) – Sparse MoE architecture.
- 🧠 [Robostral Navigate Technical Report](https://arxiv.org/abs/2607.20785) – Robostral Navigate architecture and training paper.
- 🧠 [Shieldstral Technical Report](https://arxiv.org/abs/2607.25857) – Policy-adaptive multimodal safety classifier paper.
- 🧠 [Voxtral Blog](https://mistral.ai/news/voxtral/) – Real-time speech-to-text models.
- 🧠 [Voxtral Mini Technical Report](https://arxiv.org/abs/2602.11298) – Voxtral Mini 4B Realtime architecture paper.

### Related Research

- 🌍 [DPO](https://arxiv.org/abs/2305.18290) – Direct Preference Optimization.
- 🌍 [LoRA](https://arxiv.org/abs/2106.09685) – Low-Rank Adaptation paper.
- 🌍 [Mixture of Experts](https://arxiv.org/abs/1701.06538) – MoE foundations.
- 🌍 [QLoRA](https://arxiv.org/abs/2305.14314) – Quantized LoRA for efficient fine-tuning.
- 🌍 [Sliding Window Attention](https://arxiv.org/abs/2004.05150) – Longformer attention mechanism.

---

## Talks & Media

### Official Channels

- 🧠 [Mistral AI Blog](https://mistral.ai/news/) – Official announcements.
- 🧠 [Mistral AI Discord](https://discord.gg/mistralai) – Official community server.
- 🧠 [Mistral AI Twitter/X](https://x.com/MistralAI) – Official updates.

### Conferences & Talks

- 🌍 [AI Explained](https://www.youtube.com/@aiexplained-official) – Technical breakdowns.
- 🌍 [Hugging Face YouTube](https://www.youtube.com/@HuggingFace) – Tutorials with Mistral.

---

## Ecosystem & Community

Cloud catalogs vary by region, version and retirement policy. A provider listing does not guarantee availability of the latest Mistral models.

### Cloud Providers

- 🌍 [AWS Bedrock](https://aws.amazon.com/bedrock/) – Mistral via Amazon Bedrock.
- 🌍 [Google Cloud Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/mistral) – Mistral partner models on Google Cloud (formerly Vertex AI).
- 🌍 [Microsoft Foundry](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-from-partners) – Mistral models in the Foundry model catalog (formerly Azure AI Studio).
- 🌍 [Replicate](https://replicate.com/) – Run Mistral via API.
- 🌍 [Together AI](https://together.ai/) – Mistral model hosting.

### Community Hubs

- 🧠 [Hugging Face Hub](https://huggingface.co/mistralai) – Official model repository and model cards.
- 🌍 [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) – Local LLM community.
- 🌍 [r/MistralAI](https://www.reddit.com/r/MistralAI/) – Mistral-focused subreddit.

### Partnerships

- 🧠 [European Compute Coalition](https://mistral.ai/news/regional-inference-open-models-new-compute/) – Multi-year compute capacity partnership with Amadeus, ASML, Capgemini, Caisse des Dépôts, and CMA CGM, targeting 1GW of European capacity by 2030.
- 🌍 [Microsoft Strategic Partnership](https://news.microsoft.com/source/2026/07/21/microsoft-and-mistral-expand-strategic-partnership-to-give-enterprises-and-regulated-industries-frontier-ai-they-can-control/) – Multibillion-dollar European AI infrastructure deal; Mistral Medium 3.5 and OCR 4 available in Microsoft Foundry and Copilot Studio.
- 🧠 [NVIDIA Nemotron Coalition](https://mistral.ai/news/mistral-ai-and-nvidia-partner-to-accelerate-open-frontier-models/) – Founding member of NVIDIA's open frontier model coalition, co-developing open-source models.

---

## Contributing

Contributions are welcome! Please read the [contribution guidelines](CONTRIBUTING.md) before submitting a pull request.

### Quick Guidelines

1. Ensure all links point to real, existing resources
2. Use consistent formatting: `- 🧠/🌍/🧪 [Name](url) – Brief description.`
3. Prefer high-signal, actively maintained projects
4. Include star counts for major projects (⭐ 5k+)

---

## License

[![CC0](https://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)

This work is licensed under [CC0 1.0 Universal](LICENSE).
