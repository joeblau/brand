# Brand

## Getting Started

### Running the Automated Pipeline

Execute the brand development pipeline with a single command:

```bash
./brand-pipeline.sh
```

### What It Does

The pipeline automates the complete brand development process:

1. **Environment Setup**
   - Checks for Node.js and npm (auto-installs if missing)

2. **Project Scaffolding**
   - Creates Next.js website with shadcn/ui in `website/` folder
   - Creates Remotion video project in `video/` folder

3. **Brand Development** (9 AI-powered steps)
   - Target Profile Analysis
   - Product Features Definition
   - Features to Benefits Mapping
   - Winning Zone Strategy
   - Brand Persona Selection
   - Brand Guidelines Creation
   - Website Design Prompts
   - Website Implementation Plan
   - Video Marketing Prompts

### Interactive Steps

You'll be prompted to:
1. Visit https://ui.shadcn.com/create to configure your Next.js project
2. Paste the generated `npx` command when prompted

### Output

- `website/` - Next.js project with shadcn/ui components
- `video/` - Remotion video project
- `brand-output.md` - Complete brand development documentation with all AI-generated content

### Prerequisites

- macOS or Linux
- Internet connection (for package installation)