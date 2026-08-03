# Awesome Mistral [![Awesome](https://awesome.re/badge.svg)](https://awesome.re) ![Last Updated](https://img.shields.io/github/last-commit/samouraiworld/awesome-mistral)

> A curated list of awesome resources, tools, libraries, and projects for the Mistral AI ecosystem.

Mistral AI is a Paris-based AI company building open-weight, high-performance large language models. Founded in 2023, Mistral has quickly become a leading force in open-source AI, offering models that rival proprietary alternatives while remaining accessible to developers worldwide.

This repository maps and curates the entire Mistral.ai ecosystem for AI engineers, researchers, startup founders, and open-source contributors.

**Legend:**
- 🧠 Official Mistral AI
- 🌍 Community project
- 🧪 Experimental

---

## Contents

- [What's New (July 2026)](#whats-new-july-2026)
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

## What's New (July 2026)

- 🤝 **[Microsoft partnership expansion](https://news.microsoft.com/source/2026/07/21/microsoft-and-mistral-expand-strategic-partnership-to-give-enterprises-and-regulated-industries-frontier-ai-they-can-control/)** – Multibillion-dollar deal to expand European AI compute (NVIDIA Vera Rubin GPUs); Mistral Medium 3.5 and OCR 4 now available in Microsoft Foundry and Copilot Studio, with cloud, cloud-connected, and fully disconnected deployment options.
- 🔖 **[Prompts & Skills versioning in Studio](https://mistral.ai/news/manage-prompts-and-skills-in-studio/)** – Immutable version history, ownership, and rollback for production prompts and MCP skills.
- 🤖 **[Robostral Navigate](https://mistral.ai/news/robostral-navigate/)** – Mistral's first embodied-AI model: 8B parameters, single-RGB-camera navigation for wheeled, legged, and flying robots (proprietary, enterprise access).
- 🧪 **[Leanstral 1.5](https://mistral.ai/news/leanstral-1-5/)** – Updated Lean 4 formal proof agent (Apache 2.0): saturates miniF2F, solves 587/672 PutnamBench problems, and found 5 real bugs across open-source repos.
- 🔌 **[More control over connectors](https://mistral.ai/news/more-control-over-connectors/)** – Admin workspace controls, scoped API keys, and a connectors debugger for the 60+ Studio integrations.
- 🔎 **[Mistral OCR 4](https://mistral.ai/news/ocr-4/)** – Document intelligence model with bounding boxes, block classification, and confidence scores across 170 languages ($4/1k pages, $2 with Batch API).
- 🤖 **[Le Chat is now Vibe](https://mistral.ai/news/vibe-agent/)** – Mistral's assistant rebranded to **Vibe**, a unified agent with **Work**, **Code**, and **Chat** modes (web, mobile, CLI, and VS Code). Code sessions run in parallel, persist while your machine is off, and open PRs autonomously.
- 🚀 **[Mistral Medium 3.5](https://huggingface.co/mistralai/Mistral-Medium-3.5-128B)** – 128B dense flagship unifying reasoning, coding, and vision with 256k context (Modified MIT License); now the default model in Vibe. 77.6% SWE-bench Verified.
- 🚀 **[Mistral Small 4](https://huggingface.co/mistralai/Mistral-Small-4-119B-2603)** – Hybrid MoE (119B / 6.5B active) unifying reasoning, coding, and multimodal (Apache 2.0).
- 🎙️ **[Voxtral TTS](https://huggingface.co/mistralai/Voxtral-4B-TTS-2603)** – 4B text-to-speech model across 9 languages (CC BY-NC 4.0).
- 🎙️ **[Voxtral Mini 4B Realtime](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602)** – Real-time speech-to-text with sub-500ms latency (13 languages, Apache 2.0).

---

## Why Mistral?

Mistral AI offers a compelling alternative in the LLM landscape:

| Aspect | Mistral Advantage |
|--------|-------------------|
| **Open Weights** | Models like Mistral Medium 3.5 (Modified MIT), Mistral Large 3, Small 4, and Ministral are open-weight, enabling local deployment and full control |
| **Efficiency** | Mistral Small 4 (119B/6.5B active) and Large 3 (675B/41B active) use MoE parameter routing; Medium 3.5 provides high-density performance (128B); Ministral 3B/8B/14B are optimized for edge |
| **European Sovereignty** | Paris-based company offering GDPR-compliant, EU-hosted API options via Forge and Compute |
| **Cost Efficiency** | Competitive API pricing; open models enable free self-hosting |
| **Innovation** | Pioneered efficient MoE architectures, hybrid reasoning models, formal proof agents (Leanstral), and real-time speech AI |
| **Full-Stack Platform** | Forge (enterprise model training) + Compute (European GPU cloud) + Vibe (unified work & coding agent) |

---

## Official Mistral Resources

- 🧠 [Mistral AI](https://mistral.ai) – Official company website with product information and announcements.
- 🧠 [Mistral AI Documentation](https://docs.mistral.ai) – Comprehensive API documentation, guides, and model specifications.
- 🧠 [AI Studio (la Plateforme)](https://console.mistral.ai) – Developer console featuring Workflows for production orchestration, Connectors (MCP), API keys, and model access.
- 🧠 [Vibe](https://chat.mistral.ai) – Mistral's unified agent (formerly le Chat) with Work, Code, and Chat modes across web, mobile, CLI, and VS Code.
- 🧠 [Mistral Forge](https://mistral.ai/news/forge) – Enterprise platform for training frontier-grade models on proprietary data.
- 🧠 [Mistral Compute](https://mistral.ai/products/compute) – European-hosted GPU cloud (NVIDIA Grace Blackwell).
- 🧠 [Mistral AI GitHub](https://github.com/mistralai) – Official GitHub organization with 24+ repositories.
- 🧠 [mistral-inference](https://github.com/mistralai/mistral-inference) ⭐ 10k+ – ⚠️ Archived, no longer maintained – use [vLLM](https://github.com/vllm-project/vllm), [mistral.rs](https://github.com/EricLBuehler/mistral.rs), or the Mistral API instead.
- 🧠 [mistral-finetune](https://github.com/mistralai/mistral-finetune) ⭐ 3k+ – ⚠️ Archived, no longer maintained – use [Axolotl](https://github.com/axolotl-ai-cloud/axolotl), [Unsloth](https://github.com/unslothai/unsloth), or Hugging Face [TRL](https://github.com/huggingface/trl) instead.
- 🧠 [Mistral Cookbook](https://github.com/mistralai/cookbook) ⭐ 2k+ – Official notebooks and examples for common use cases.
- 🧠 [mistral-common](https://github.com/mistralai/mistral-common) – Official tokenization and pre-processing library.
- 🧠 [Mistral Vibe](https://github.com/mistralai/mistral-vibe) – Native CLI coding assistant featuring cloud-async Remote Agents and sandbox PR generation.
- 🧠 [Platform Docs Public](https://github.com/mistralai/platform-docs-public) – Open-source documentation repository.

---

## Model Families

### Flagship Models (API)

| Model | Context | License | Best For |
|-------|---------|---------|----------|
| **Mistral Small 4** | 256k | Apache 2.0 | Hybrid reasoning + coding + multimodal (119B MoE / 6.5B active) |
| **Mistral Large 3** | 256k | Apache 2.0 | Complex reasoning, multilingual, coding, vision (675B / 41B active) |
| **Mistral Medium 3.5** | 256k | Modified MIT | Unified reasoning, coding, and vision (128B dense) |
| **Mistral Small 3.2** | 128k | Apache 2.0 | Low-latency, cost-sensitive applications (24B) |
| **Mistral OCR 4** | — | Proprietary | Document parsing with bounding boxes & confidence scores, 170 languages ($4/1k pages) |

### Open-Weight Models

#### General Purpose & Reasoning
- 🧠 [Mistral Medium 3.5](https://huggingface.co/mistralai/Mistral-Medium-3.5-128B) – Dense flagship model (128B) unifying instruction-following, reasoning, and coding with 256k context and configurable `reasoning_effort`.
- 🧠 [Mistral Small 4](https://huggingface.co/mistralai/Mistral-Small-4-119B-2603) – Hybrid MoE (119B / 6.5B active) unifying reasoning, coding, and multimodal. Configurable `reasoning_effort`.
- 🧠 [Mistral Large 3](https://huggingface.co/mistralai/Mistral-Large-3-675B-Instruct-2512) – Flagship MoE (675B / 41B active) with state-of-the-art reasoning and vision.
- 🧠 [Mistral Small 3.2](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) – High-performance dense 24B model (v3.2).
- 🧠 [Magistral Small 1.2](https://huggingface.co/mistralai/Magistral-Small-2509) – Open 24B multimodal reasoning model (Apache 2.0, 128k context, `[THINK]` tokens).
- 🧠 [Magistral Medium 1.2](https://docs.mistral.ai/models/magistral-medium-1-2-25-09) – Frontier-class multimodal reasoning model (API, `magistral-medium-2509`).
- 🧠 [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1) – Legacy MoE workhorse (141B total / 39B active).

#### Edge & On-Device (Ministral)
- 🧠 [Ministral 14B](https://huggingface.co/mistralai/Ministral-3-14B-Instruct-2512) – Dense edge model with vision (14B). Best-in-class at small scale.
- 🧠 [Ministral 8B](https://huggingface.co/mistralai/Ministral-8B-Instruct-2410) – High-performance edge model (8B).
- 🧠 [Ministral 3B](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512) – Ultralight model for mobile/browser (3B).

#### Coding & Agentic (Devstral)
- 🧠 [Devstral 2](https://huggingface.co/mistralai/Devstral-2-123B-Instruct-2512) – 123B coding model (Modified MIT License). 72.2% SWE-bench Verified.
- 🧠 [Devstral Small 2](https://huggingface.co/mistralai/Devstral-Small-2-24B-Instruct-2512) – 24B coding model (Apache 2.0) for local agents. 68.0% SWE-bench Verified.
- 🧠 [Codestral 25.08](https://huggingface.co/mistralai/Codestral-2508) – Latest FIM code-completion specialist (22B, 256k context).

#### Multimodal (Pixtral)
- 🧠 [Pixtral Large](https://huggingface.co/mistralai/Pixtral-Large-Instruct-2411) – 124B multimodal model building on Mistral Large 2.
- 🧠 [Pixtral 12B](https://huggingface.co/mistralai/Pixtral-12B-2409) – Efficient vision-language model.

#### Audio & Speech (Voxtral)
- 🧠 [Voxtral TTS](https://huggingface.co/mistralai/Voxtral-4B-TTS-2603) – 4B text-to-speech model, 9 languages, 24 kHz output (CC BY-NC 4.0).
- 🧠 [Voxtral Mini 4B Realtime](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602) – Natively streaming speech-to-text, sub-500ms latency, 13 languages (Apache 2.0).
- 🧠 [Voxtral Small 24B](https://huggingface.co/mistralai/Voxtral-Small-24B-2507) – High-accuracy speech understanding and transcription (Apache 2.0).
- 🧠 [Voxtral Mini 3B](https://huggingface.co/mistralai/Voxtral-Mini-3B-2507) – Compact speech understanding model (Apache 2.0).

### Specialized Models
- 🧠 **[Mistral OCR 4](https://mistral.ai/news/ocr-4/)** – Document intelligence with bounding boxes, block classification, and per-word confidence scores across 170 languages (API `mistral-ocr-4-0`, $4/1k pages, $2 with Batch API).
- 🧠 [Leanstral 1.5](https://huggingface.co/mistralai/Leanstral-1-5-119B-A6B) – Lean 4 formal proof agent (119B / 6.5B active, Apache 2.0). Saturates miniF2F, solves 587/672 PutnamBench problems.
- 🧠 **Mistral Moderation 2603** – Content moderation with jailbreaking, dangerous, and criminal detection (3B, API only).

#### Robotics (Robostral)
- 🧠 [Robostral Navigate](https://mistral.ai/news/robostral-navigate/) – Embodied navigation model (8B) using a single RGB camera for wheeled, legged, and flying robots; 76.6% success rate on unseen R2R-CE environments (proprietary, enterprise access).

---

## Community Fine-Tuned Models

High-quality community fine-tunes built on Mistral base models:

### Instruction & Chat

- 🌍 [OpenHermes-2.5-Mistral-7B](https://huggingface.co/teknium/OpenHermes-2.5-Mistral-7B) – GPT-4 quality instruction-tuned by Teknium.
- 🌍 [Zephyr-7B-beta](https://huggingface.co/HuggingFaceH4/zephyr-7b-beta) – DPO-trained by HuggingFace H4, outperforms 70B on MT-Bench.
- 🌍 [Nous-Hermes-2-Mistral-7B-DPO](https://huggingface.co/NousResearch/Nous-Hermes-2-Mistral-7B-DPO) – DPO-enhanced with strong benchmark scores.
- 🌍 [Hermes-2-Pro-Mistral-7B](https://huggingface.co/NousResearch/Hermes-2-Pro-Mistral-7B) – Function calling and JSON mode specialist.
- 🌍 [OpenChat-3.5-0106](https://huggingface.co/openchat/openchat-3.5-0106) – C-RLFT trained, ChatGPT-comparable performance.
- 🌍 [Dolphin-2.8-Mistral-7B](https://huggingface.co/cognitivecomputations/dolphin-2.8-mistral-7b-v02) – Uncensored model by Eric Hartford.

### Specialized

- 🌍 [MistralLite](https://huggingface.co/amazon/MistralLite) – AWS-optimized with 32k context window.
- 🌍 [Mistral-7B-OpenOrca](https://huggingface.co/Open-Orca/Mistral-7B-OpenOrca) – Trained on OpenOrca dataset.
- 🌍 [WizardMath-7B-V1.1](https://huggingface.co/WizardLM/WizardMath-7B-V1.1) – Math-specialized Mistral fine-tune.

### Quantized Model Collections

- 🌍 [TheBloke](https://huggingface.co/TheBloke) – Extensive GGUF/AWQ/GPTQ quantized model repository.
- 🌍 [bartowski](https://huggingface.co/bartowski) – High-quality GGUF quantizations.

---

## SDKs & APIs

### Official SDKs

- 🧠 [client-python](https://github.com/mistralai/client-python) – Official Python client library.
- 🧠 [client-ts](https://github.com/mistralai/client-ts) – Official TypeScript/JavaScript client library.
- 🧠 [@mistralai/mistralai](https://www.npmjs.com/package/@mistralai/mistralai) – Official TypeScript/JavaScript SDK (npm).

### Community SDKs

- 🌍 [mistral.rs](https://github.com/EricLBuehler/mistral.rs) ⭐ 7k+ – Blazingly fast Rust inference with ISQ, LoRA, quantization.
- 🌍 [mistral-go](https://github.com/Gage-Technologies/mistral-go) – Go client for Mistral AI API.
- 🌍 [@ai-sdk/mistral](https://www.npmjs.com/package/@ai-sdk/mistral) – Vercel AI SDK provider.
- 🌍 [@langchain/mistralai](https://www.npmjs.com/package/@langchain/mistralai) – LangChain.js integration.

---

## Inference & Deployment

### High-Performance Inference

- 🌍 [vLLM](https://github.com/vllm-project/vllm) ⭐ 86k+ – High-throughput with PagedAttention. Excellent Mistral support.
- 🌍 [Text Generation Inference](https://github.com/huggingface/text-generation-inference) ⭐ 10k+ – Hugging Face's production inference server.
- 🌍 [llama.cpp](https://github.com/ggml-org/llama.cpp) ⭐ 121k+ – CPU/GPU inference with GGUF quantization.
- 🌍 [ExLlamaV2](https://github.com/turboderp/exllamav2) – Fast inference with EXL2 quantization.
- 🌍 [SGLang](https://github.com/sgl-project/sglang) ⭐ 30k+ – Fast serving with RadixAttention.

### Local Inference

- 🌍 [Ollama](https://ollama.com) ⭐ 176k+ – Simple CLI for local Mistral models.
- 🌍 [LM Studio](https://lmstudio.ai) – Desktop GUI for local LLMs.
- 🌍 [Jan](https://jan.ai) – Open-source ChatGPT alternative running locally.
- 🌍 [GPT4All](https://gpt4all.io) – Local inference with Mistral support.
- 🌍 [Msty](https://msty.app) – Desktop app for running local LLMs.

### Cloud & Container Deployment

- 🌍 [LocalAI](https://github.com/mudler/LocalAI) ⭐ 47k+ – OpenAI-compatible local API server.
- 🌍 [SkyPilot](https://github.com/skypilot-org/skypilot) ⭐ 10k+ – Run on any cloud with cost optimization.
- 🌍 [MLC LLM](https://github.com/mlc-ai/mlc-llm) ⭐ 22k+ – Universal deployment (iOS/Android) perfect for Ministral 3B.
- 🧠 [TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM) ⭐ 14k+ – Optimized inference for Mistral Large 3 on NVIDIA GPUs.

---

## Fine-Tuning & Training

### Fine-Tuning Frameworks

- 🧠 [mistral-finetune](https://github.com/mistralai/mistral-finetune) – ⚠️ Archived, no longer maintained.
- 🌍 [Axolotl](https://github.com/axolotl-ai-cloud/axolotl) ⭐ 12k+ – Streamlined LoRA/QLoRA/full fine-tuning.
- 🌍 [Unsloth](https://github.com/unslothai/unsloth) ⭐ 68k+ – 2-5x faster fine-tuning, 80% less memory.
- 🌍 [Hugging Face PEFT](https://github.com/huggingface/peft) – Parameter-Efficient Fine-Tuning.
- 🌍 [Hugging Face TRL](https://github.com/huggingface/trl) – RLHF and DPO training.
- 🌍 [LLaMA-Factory](https://github.com/hiyouga/LLaMA-Factory) ⭐ 73k+ – Unified fine-tuning framework.
- 🌍 [torchtune](https://github.com/pytorch/torchtune) – PyTorch-native fine-tuning.

### Training Infrastructure

- 🌍 [DeepSpeed](https://github.com/microsoft/DeepSpeed) – Distributed training optimization.
- 🌍 [Hugging Face Accelerate](https://github.com/huggingface/accelerate) – Simple distributed training.

---

## Model Merging & Quantization

### Model Merging

- 🌍 [MergeKit](https://github.com/arcee-ai/mergekit) ⭐ 7k+ – Toolkit for merging LLMs (SLERP, TIES, DARE).
- 🌍 [LazyMergeKit](https://colab.research.google.com/drive/1obulZ1ROXHjYLn6PPZJwRR6GzgQogxxb) – Colab notebook for easy merging.

### Quantization Tools

- 🌍 [llama.cpp](https://github.com/ggml-org/llama.cpp) – GGUF quantization (Q4, Q5, Q8).
- 🌍 [AutoGPTQ](https://github.com/AutoGPTQ/AutoGPTQ) – GPTQ quantization.
- 🌍 [AutoAWQ](https://github.com/casper-hansen/AutoAWQ) – AWQ quantization.
- 🌍 [bitsandbytes](https://github.com/TimDettmers/bitsandbytes) – 4-bit and 8-bit quantization.
- 🌍 [GGUF](https://github.com/ggml-org/ggml/blob/master/docs/gguf.md) – Quantization format specification.

---

## Agents & Orchestration

### Agent Frameworks

- 🌍 [LangChain](https://github.com/langchain-ai/langchain) ⭐ 142k+ – LLM app framework with native Mistral support.
- 🌍 [LlamaIndex](https://github.com/run-llama/llama_index) ⭐ 51k+ – Data framework for RAG with Mistral.
- 🌍 [CrewAI](https://github.com/crewAIInc/crewAI) ⭐ 56k+ – Multi-agent orchestration.
- 🌍 [AutoGen](https://github.com/microsoft/autogen) ⭐ 59k+ – Microsoft's multi-agent framework.
- 🌍 [Semantic Kernel](https://github.com/microsoft/semantic-kernel) – Microsoft's AI orchestration SDK.
- 🌍 [Haystack](https://github.com/deepset-ai/haystack) – End-to-end NLP framework.
- 🌍 [PydanticAI](https://github.com/pydantic/pydantic-ai) – Type-safe AI agent framework.
- 🌍 [RocketRide](https://github.com/rocketride-org/rocketride-server) ⭐ 5k+ – C++ AI pipeline engine with dedicated Mistral text/vision nodes, Python/TypeScript SDKs, and a visual IDE.
- 🌍 [Aeon](https://github.com/aeonfun/aeon) ⭐ 588 – Autonomous agent framework that runs unattended on GitHub Actions and drives Mistral Vibe as one of six coding-agent harnesses behind a single contract, with quality scoring, persistent memory, and a self-healing loop.

### Function Calling & Structured Output

- 🧠 [Mistral Function Calling](https://docs.mistral.ai/capabilities/function_calling/) – Native function calling docs.
- 🌍 [Instructor](https://github.com/567-labs/instructor) ⭐ 13k+ – Structured outputs with Pydantic.
- 🌍 [Outlines](https://github.com/dottxt-ai/outlines) ⭐ 15k+ – Guaranteed structured generation.
- 🌍 [Marvin](https://github.com/prefecthq/marvin) – AI functions with type hints.

---

## Tooling & Dev Experience

### IDE Extensions & Code Assistants

- 🧠 [Mistral Code](https://mistral.ai/news/mistral-code) – Official AI coding assistant (VS Code/JetBrains) built on the Mistral coding stack.
- 🧠 [Zed Extensions](https://github.com/mistralai/zed-extensions) – Official Mistral for Zed editor.
- 🌍 [Continue](https://github.com/continuedev/continue) ⭐ 35k+ – Open-source AI code assistant (VSCode/JetBrains).
- 🌍 [Tabby](https://github.com/TabbyML/tabby) ⭐ 33k+ – Self-hosted GitHub Copilot alternative.
- 🌍 [Aider](https://github.com/Aider-AI/aider) ⭐ 47k+ – AI pair programming in terminal.
- 🌍 [Cody](https://sourcegraph.com/cody) – AI coding assistant with codebase context.

### Development Tools

- 🌍 [LiteLLM](https://github.com/BerriAI/litellm) ⭐ 54k+ – Unified API for 100+ LLMs.
- 🌍 [Promptfoo](https://github.com/promptfoo/promptfoo) ⭐ 23k+ – LLM evaluation and red-teaming.
- 🌍 [Langfuse](https://github.com/langfuse/langfuse) ⭐ 31k+ – Open-source LLM observability.
- 🌍 [Phoenix](https://github.com/Arize-ai/phoenix) ⭐ 10k+ – ML observability for LLM apps.
- 🌍 [Weights & Biases](https://wandb.ai) – Experiment tracking with LLM support.

---

## Community Projects

### Chat Interfaces

- 🌍 [Open WebUI](https://github.com/open-webui/open-webui) ⭐ 146k+ – Self-hosted ChatGPT-like UI.
- 🌍 [LibreChat](https://github.com/danny-avila/LibreChat) ⭐ 41k+ – Multi-model chat interface.
- 🌍 [Lobe Chat](https://github.com/lobehub/lobe-chat) ⭐ 80k+ – Modern extensible chat framework.
- 🌍 [Chatbot UI](https://github.com/mckaywrigley/chatbot-ui) – Open-source ChatGPT clone.
- 🌍 [BetterChatGPT](https://github.com/ztjhz/BetterChatGPT) – Enhanced chat interface.

### RAG & Knowledge Management

- 🌍 [PrivateGPT](https://github.com/zylon-ai/private-gpt) ⭐ 57k+ – Private document Q&A.
- 🌍 [Onyx](https://github.com/onyx-dot-app/onyx) ⭐ 31k+ – Enterprise Q&A over internal docs (formerly Danswer).
- 🌍 [Quivr](https://github.com/QuivrHQ/quivr) ⭐ 39k+ – Personal knowledge base.
- 🌍 [Khoj](https://github.com/khoj-ai/khoj) – AI second brain.
- 🌍 [LocalGPT](https://github.com/PromtEngineer/localGPT) – Chat with documents locally.

### Specialized Applications

- 🌍 [Fabric](https://github.com/danielmiessler/fabric) ⭐ 43k+ – AI augmentation framework.
- 🌍 [GPT Researcher](https://github.com/assafelovic/gpt-researcher) ⭐ 28k+ – Autonomous research agent.
- 🌍 [OpenHands](https://github.com/OpenHands/OpenHands) ⭐ 81k+ – AI software engineer (formerly OpenDevin).

---

## Demos & Examples

### Official Examples

- 🧠 [Mistral Cookbook](https://github.com/mistralai/cookbook) – RAG, function calling, embeddings, agents.
- 🧠 [Fine-Tuning Guide](https://docs.mistral.ai/capabilities/finetuning/) – Official fine-tuning documentation.
- 🧠 [API Examples](https://docs.mistral.ai/api/) – Complete API reference with examples.

### Community Examples

- 🌍 [Awesome-LLM](https://github.com/Hannibal046/Awesome-LLM) – Curated LLM resources including Mistral.
- 🌍 [LangGraph](https://github.com/langchain-ai/langgraph) – Stateful multi-agent and workflow examples with Mistral.

---

## Tutorials & Guides

### Getting Started

- 🧠 [Mistral Quickstart](https://docs.mistral.ai/getting-started/quickstart/) – Official getting started guide.
- 🧠 [Model Selection Guide](https://docs.mistral.ai/getting-started/models/) – Choosing the right model.
- 🌍 [Run Mistral Locally](https://ollama.com/library/mistral) – Ollama setup guide.

### Fine-Tuning Tutorials

- 🧠 [Official Fine-Tuning](https://docs.mistral.ai/capabilities/finetuning/) – Mistral's fine-tuning guide.
- 🌍 [Axolotl Mistral Examples](https://github.com/axolotl-ai-cloud/axolotl/tree/main/examples/mistral) – Config examples.
- 🌍 [QLoRA Guide](https://huggingface.co/blog/4bit-transformers-bitsandbytes) – 4-bit fine-tuning.
- 🌍 [Unsloth Tutorial](https://github.com/unslothai/unsloth#mistral) – Fast Mistral fine-tuning.

### RAG & Applications

- 🧠 [RAG with Mistral](https://docs.mistral.ai/guides/rag/) – Official RAG guide.
- 🌍 [LlamaIndex + Mistral](https://docs.llamaindex.ai/en/stable/examples/llm/mistralai/) – RAG with LlamaIndex.
- 🌍 [LangChain + Mistral](https://python.langchain.com/docs/integrations/llms/mistralai/) – LangChain integration.

---

## Benchmarks & Evaluation

### Leaderboards

- 🌍 [Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard) – Hugging Face benchmarks.
- 🌍 [Chatbot Arena](https://lmarena.ai/) – Human preference rankings.
- 🌍 [Artificial Analysis](https://artificialanalysis.ai/) – LLM quality and speed benchmarks.

### Evaluation Frameworks

- 🌍 [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) – EleutherAI's eval framework.
- 🌍 [HELM](https://github.com/stanford-crfm/helm) – Stanford's holistic evaluation.
- 🌍 [OpenCompass](https://github.com/open-compass/opencompass) – Comprehensive LLM evaluation.

### Code Benchmarks

- 🌍 [HumanEval](https://github.com/openai/human-eval) – Code generation benchmark.
- 🌍 [BigCodeBench](https://github.com/bigcode-project/bigcodebench) – Comprehensive code evaluation.
- 🌍 [EvalPlus](https://github.com/evalplus/evalplus) – Rigorous code evaluation.

---

## Research & Papers

### Mistral Technical Reports

- 🧠 [Mistral 7B](https://arxiv.org/abs/2310.06825) – Foundational 7B architecture paper.
- 🧠 [Mixtral of Experts](https://arxiv.org/abs/2401.04088) – Sparse MoE architecture.
- 🧠 [Introducing Mistral 3](https://mistral.ai/news/mistral-3/) – Mistral Large 3 / Ministral 3 family announcement and benchmarks.
- 🧠 [Mistral Small 4 Blog](https://mistral.ai/news/mistral-small-4) – Hybrid MoE architecture announcement.
- 🧠 [Leanstral 1.5 Blog](https://mistral.ai/news/leanstral-1-5/) – Lean 4 formal proof agent update.
- 🧠 [Forge Announcement](https://mistral.ai/news/forge) – Enterprise model training platform.
- 🧠 [Voxtral Blog](https://mistral.ai/news/voxtral/) – Real-time speech-to-text models.
- 🧠 [Voxtral Mini Technical Report](https://arxiv.org/abs/2602.11298) – Voxtral Mini 4B Realtime architecture paper.
- 🧠 [Mistral OCR 4 Blog](https://mistral.ai/news/ocr-4/) – Document intelligence model announcement.
- 🧠 [Robostral Navigate Blog](https://mistral.ai/news/robostral-navigate/) – First embodied-AI navigation model.

### Related Research

- 🌍 [Sliding Window Attention](https://arxiv.org/abs/2004.05150) – Longformer attention mechanism.
- 🌍 [LoRA](https://arxiv.org/abs/2106.09685) – Low-Rank Adaptation paper.
- 🌍 [QLoRA](https://arxiv.org/abs/2305.14314) – Quantized LoRA for efficient fine-tuning.
- 🌍 [DPO](https://arxiv.org/abs/2305.18290) – Direct Preference Optimization.
- 🌍 [Mixture of Experts](https://arxiv.org/abs/1701.06538) – MoE foundations.

---

## Talks & Media

### Official Channels

- 🧠 [Mistral AI Blog](https://mistral.ai/news/) – Official announcements.
- 🧠 [Mistral AI Discord](https://discord.gg/mistralai) – Official community server.
- 🧠 [Mistral AI Twitter/X](https://twitter.com/MistralAI) – Official updates.

### Conferences & Talks

- 🌍 [Hugging Face YouTube](https://www.youtube.com/@HuggingFace) – Tutorials with Mistral.
- 🌍 [AI Explained](https://www.youtube.com/@aiexplained-official) – Technical breakdowns.

---

## Ecosystem & Community

### Cloud Providers

- 🌍 [Azure AI](https://azure.microsoft.com/en-us/products/ai-studio/) – Mistral on Azure AI Studio.
- 🌍 [AWS Bedrock](https://aws.amazon.com/bedrock/) – Mistral via Amazon Bedrock.
- 🌍 [Google Cloud Vertex AI](https://cloud.google.com/vertex-ai) – Mistral on GCP.
- 🌍 [Groq](https://groq.com/) – Ultra-fast Mistral inference.
- 🌍 [Together AI](https://together.ai/) – Mistral model hosting.
- 🌍 [Replicate](https://replicate.com/) – Run Mistral via API.

### Community Hubs

- 🌍 [Hugging Face Hub](https://huggingface.co/mistralai) – Official model repository.
- 🧠 [Mistral Discord](https://discord.gg/mistralai) – Official community.
- 🌍 [r/LocalLLaMA](https://www.reddit.com/r/LocalLLaMA/) – Local LLM community.
- 🌍 [r/MistralAI](https://www.reddit.com/r/MistralAI/) – Mistral-focused subreddit.

### Partnerships

- 🧠 [Microsoft Strategic Partnership](https://news.microsoft.com/source/2026/07/21/microsoft-and-mistral-expand-strategic-partnership-to-give-enterprises-and-regulated-industries-frontier-ai-they-can-control/) – Multibillion-dollar European AI infrastructure deal; Mistral Medium 3.5 and OCR 4 available in Microsoft Foundry and Copilot Studio.
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
