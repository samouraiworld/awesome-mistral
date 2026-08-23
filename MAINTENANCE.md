# Maintenance Checklist

This file contains a checklist for maintainers to perform monthly or upon major releases to ensure the repository remains accurate.

## Monthly Checks

### Model Specifications
- [ ] **Mistral Medium 3.5**: Verify current version and specs (128B dense, 256k ctx, Modified MIT license).
- [ ] **Mistral Small 4**: Verify current version and specs (119B MoE / 6.5B active, 256k ctx).
- [ ] **Mistral Large**: Verify current version (e.g., Mistral Large 3) and context length (256k).
- [ ] **Ministral Family**: Verify Ministral 3 (3B/8B/14B = `Ministral-3-*-Instruct-2512`, 256k ctx) and any new sizes.
- [ ] **Magistral**: All Magistral API models were retired (July 2026); Small 1.2 weights remain on HF and are listed as *(legacy)*. Watch for any new reasoning release.
- [ ] **Leanstral**: Check for updates or new formal proof models.
- [ ] **Voxtral**: Check the family — TTS (`Voxtral-4B-TTS-2603`), Mini 4B Realtime (`2602`), Mini Transcribe 2 (`voxtral-mini-2602`, API only), Small 24B (`2507`); Mini 3B (`2507`) is *(legacy)*.
- [ ] **Codestral**: Verify latest version (currently 25.08 = `Codestral-2508`).
- [ ] **OCR**: Verify latest version (currently OCR 4.1 = `mistral-ocr-4-1`; `mistral-ocr-latest` alias) and pricing.
- [ ] **Moderation & Safety**: Check Mistral Moderation 2 (`mistral-moderation-2603`) and Shieldstral for new versions.
- [ ] **Pricing**: Check [Mistral Pricing](https://docs.mistral.ai/inference/pricing), the [Changelog](https://docs.mistral.ai/resources/changelogs), and the [Release Notes](https://docs.mistral.ai/resources/release-notes) for changes.
- [ ] **Model lifecycle**: Review the *Deprecated & retired models* table on [docs.mistral.ai/models](https://docs.mistral.ai/models) — mark newly retired API models *(legacy)* if weights remain, remove API-only ones, and update the Flagship (API) table. Upcoming: `mistral-medium-2508` (Aug 31, 2026), `labs-leanstral-1-5` (Sep 30, 2026).

### Links & URLs
- [ ] **Hugging Face IDs**: Ensure links point to specific, non-deprecated model IDs (e.g., `mistralai/Mistral-Small-4-119B-2603`).
- [ ] **Official Docs**: Verify links to `docs.mistral.ai` pages are still valid.
- [ ] **Product Pages**: Verify Forge, Mistral Compute / AI Cloud (`/products/aicloud/`), Vibe, and Studio URLs.
- [ ] **Redirects**: Re-run the link check with redirects visible (`curl -sIL`) — silently redirected URLs usually mean a rename (e.g. LMArena → Arena, Vertex AI → Gemini Enterprise Agent Platform, Azure AI Studio → Microsoft Foundry).

### Product Features
- [ ] **Vibe**: le Chat was rebranded to **Vibe** (May 2026) — verify Work / Code / Chat modes and pricing tiers.
- [ ] **Vibe Remote Agents**: Verify features related to cloud-async sandboxing and PR generation.
- [ ] **AI Studio**: Verify Workflows (Python orchestration) and Connectors (MCP) status.
- [ ] **Search Toolkit / Agentic Search**: Verify availability of production search pipelines and the Agentic Search tools.
- [ ] **Fine-tuning API**: Deprecated since mid-2026 (docs moved under `/resources/deprecated/`) — keep the ⚠️ note unless Mistral reinstates it; Forge is the enterprise training path.

### New Releases
- [ ] Check [Mistral News](https://mistral.ai/news/) for any new "stral" models.
- [ ] Check for new SDK major versions (Python via `client-python`, TS via `client-ts`).
- [ ] Check GitHub org repo count (currently 28) and new official repos (e.g. `mistralai/cli`, a binaries-only release repo created Aug 2026 — add once it has docs and adoption).

## Formatting
- [ ] Ensure all new links follow the `- 🧠/🌍/🧪 [Name](url) – Description.` format.
- [ ] Verify table rendering on GitHub.
- [ ] Confirm the table of contents anchors match their section headings.

## Link & Data Integrity
- [ ] Run an automated link checker (e.g. `lychee README.md` or `markdown-link-check`) and fix any dead URLs.
- [ ] Refresh ⭐ star counts via the GitHub API; note that several repos have moved (llama.cpp → `ggml-org`, aider → `Aider-AI`, instructor → `567-labs`, outlines → `dottxt-ai`, Danswer → Onyx `onyx-dot-app`, OpenDevin → OpenHands). Hugging Face repos move too (WizardLM → `WizardLMTeam`, cognitivecomputations → `dphn`) — check for 307s.
- [ ] Verify 🧠 entries actually point to Mistral-owned orgs/domains (not partner or community projects), and flag community entries whose upstream has been inactive for >1 year per CONTRIBUTING.md.
