# Maintenance Checklist

This file contains a checklist for maintainers to perform monthly or upon major releases to ensure the repository remains accurate.

## Monthly Checks

### Model Specifications
- [ ] **Mistral Medium 3.5**: Verify current version and specs (128B dense, 256k ctx, Modified MIT license).
- [ ] **Mistral Small 4**: Verify current version and specs (119B MoE / 6.5B active, 256k ctx).
- [ ] **Mistral Large**: Verify current version (e.g., Mistral Large 3) and context length (256k).
- [ ] **Ministral Family**: Verify 3B/8B/14B models and any new sizes.
- [ ] **Magistral**: Verify latest version (e.g., Magistral Small 1.2 = `Magistral-Small-2509`).
- [ ] **Leanstral**: Check for updates or new formal proof models.
- [ ] **Voxtral**: Check for new speech/audio models.
- [ ] **Moderation**: Check for updated moderation model versions.
- [ ] **Pricing**: Check [Mistral Pricing](https://mistral.ai/technology/#pricing) for changes (note: URL may have changed with site redesign).

### Links & URLs
- [ ] **Hugging Face IDs**: Ensure links point to specific, non-deprecated model IDs (e.g., `mistralai/Mistral-Small-4-119B-2603`).
- [ ] **Official Docs**: Verify links to `docs.mistral.ai` pages are still valid.
- [ ] **Product Pages**: Verify Forge, Compute, le Chat, and AI Studio URLs.

### Product Features
- [ ] **Vibe Remote Agents**: Verify features related to cloud-async sandboxing.
- [ ] **Le Chat Work Mode**: Verify features related to multi-step agent workflows.
- [ ] **AI Studio Workflows**: Verify status of Python orchestration capabilities.

### New Releases
- [ ] Check [Mistral News](https://mistral.ai/news/) for any new "stral" models.
- [ ] Check for new SDK major versions (Python via `client-python`, TS via `client-ts`).
- [ ] Check GitHub org repo count (currently 24+).

## Formatting
- [ ] Ensure all new links follow the `- 🧠/🌍/🧪 [Name](url) – Description.` format.
- [ ] Verify table rendering on GitHub.
