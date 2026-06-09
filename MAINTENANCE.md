# Maintenance Checklist

This file contains a checklist for maintainers to perform monthly or upon major releases to ensure the repository remains accurate.

## Monthly Checks

### Model Specifications
- [ ] **Mistral Medium 3.5**: Verify current version and specs (128B dense, 256k ctx, Modified MIT license).
- [ ] **Mistral Small 4**: Verify current version and specs (119B MoE / 6.5B active, 256k ctx).
- [ ] **Mistral Large**: Verify current version (e.g., Mistral Large 3) and context length (256k).
- [ ] **Ministral Family**: Verify 3B/8B/14B models and any new sizes.
- [ ] **Magistral**: Verify latest versions (Small 1.2 = `Magistral-Small-2509`, Medium 1.2 = `magistral-medium-2509`).
- [ ] **Leanstral**: Check for updates or new formal proof models.
- [ ] **Voxtral**: Check the family — TTS (`Voxtral-4B-TTS-2603`), Mini 4B Realtime (`2602`), Small 24B / Mini 3B (`2507`).
- [ ] **Codestral**: Verify latest version (currently 25.08 = `Codestral-2508`).
- [ ] **Moderation**: Check for updated moderation model versions.
- [ ] **Pricing**: Check [Mistral Pricing](https://mistral.ai/pricing/) and the [Changelog](https://docs.mistral.ai/getting-started/changelog) for changes.

### Links & URLs
- [ ] **Hugging Face IDs**: Ensure links point to specific, non-deprecated model IDs (e.g., `mistralai/Mistral-Small-4-119B-2603`).
- [ ] **Official Docs**: Verify links to `docs.mistral.ai` pages are still valid.
- [ ] **Product Pages**: Verify Forge, Compute, le Chat, and AI Studio URLs.

### Product Features
- [ ] **Vibe**: le Chat was rebranded to **Vibe** (May 2026) — verify Work / Code / Chat modes and pricing tiers.
- [ ] **Vibe Remote Agents**: Verify features related to cloud-async sandboxing and PR generation.
- [ ] **AI Studio**: Verify Workflows (Python orchestration) and Connectors (MCP) status.
- [ ] **Search Toolkit**: Verify availability of production search pipelines.

### New Releases
- [ ] Check [Mistral News](https://mistral.ai/news/) for any new "stral" models.
- [ ] Check for new SDK major versions (Python via `client-python`, TS via `client-ts`).
- [ ] Check GitHub org repo count (currently 24+).

## Formatting
- [ ] Ensure all new links follow the `- 🧠/🌍/🧪 [Name](url) – Description.` format.
- [ ] Verify table rendering on GitHub.
- [ ] Confirm the table of contents anchors match their section headings.

## Link & Data Integrity
- [ ] Run an automated link checker (e.g. `lychee README.md` or `markdown-link-check`) and fix any dead URLs.
- [ ] Refresh ⭐ star counts via the GitHub API; note that several repos have moved (llama.cpp → `ggml-org`, aider → `Aider-AI`, instructor → `567-labs`, outlines → `dottxt-ai`, Danswer → Onyx `onyx-dot-app`, OpenDevin → OpenHands).
