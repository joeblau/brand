# Brand Development Pipeline

Automated end-to-end brand development using Claude Opus 4.5 AI.

## Getting Started

### Prerequisites

- macOS or Linux
- Node.js and npm (auto-installed if missing via Homebrew)
- Claude CLI (https://claude.ai/download)
- Pandoc (optional, for PDF generation) - install via `brew bundle`

### Running the Pipeline

Execute the complete brand development pipeline:

```bash
./brand-pipeline.sh
```

## What It Does

### 1. Environment Setup
- Checks and installs Node.js/npm if needed
- Verifies Claude CLI installation

### 2. Project Scaffolding
- Creates Next.js website with shadcn/ui in `website/` folder
- Creates Remotion video project in `video/` folder with Tailwind CSS

### 3. Brand Development (10 AI-Powered Steps)

Using **Claude Opus 4.5** with conversation continuity (`--continue`):

1. **Target Profile** - Analyzes your vision and creates brand positioning
2. **Product Features** - Defines comprehensive feature set
3. **Features to Benefits** - Translates features into user benefits
4. **Winning Zone** - Maps competitive advantages
5. **Brand Persona** - Selects primary/secondary brand archetypes
6. **Brand Guidelines** - Creates comprehensive brand guidelines (+ PDF)
7. **Website Design Prompt** - Generates detailed v0.dev prompts
8. **Build Website** - Fully implements website in `website/` directory
9. **Video Marketing Prompts** - Creates Remotion video specifications
10. **Build Video** - Implements and renders video to `assets/brand-video.mp4`

### 4. Interactive Steps

You'll be prompted to:
1. Enter your product vision (multi-line input, Ctrl+D to finish)
2. Visit https://ui.shadcn.com/create to configure Next.js preferences
3. Paste the generated `npx` command (only on first run)
4. Choose to resume from previous step if artifacts exist

## Output Structure

```
brand/
├── artifacts/           # All AI-generated outputs
│   ├── step1-target-profile.md
│   ├── step2-product-features.md
│   ├── ...
│   ├── step6-brand-guidelines.pdf
│   └── token-usage.log
├── assets/             # Brand assets (logos, images, rendered video)
│   └── brand-video.mp4
├── website/            # Fully implemented Next.js website
├── video/              # Fully implemented Remotion video project
└── brand-output.md     # Consolidated documentation
```

## Features

- **Resume Capability** - Skip completed steps, resume from any point
- **Token Tracking** - Estimates API usage for each step
- **PDF Generation** - Converts brand guidelines to PDF (requires pandoc)
- **Conversation Continuity** - Maintains context across all 10 steps
- **Fully Automated** - No manual intervention after initial setup