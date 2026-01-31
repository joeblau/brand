#!/bin/bash

# Brand Development Pipeline
# Chains multiple Claude prompts together, passing output from each step to the next

set -e  # Exit on error

echo "🎨 Starting Brand Development Pipeline..."
echo ""

# Create artifacts directory
ARTIFACTS_DIR="artifacts"
mkdir -p "$ARTIFACTS_DIR"

# Check for existing artifacts and offer resume
RESUME_FROM=0
if ls ${ARTIFACTS_DIR}/step*.md 1> /dev/null 2>&1; then
    echo "📋 Found existing artifacts:"
    ls -1 ${ARTIFACTS_DIR}/step*.md | while read file; do
        echo "  ✓ $(basename $file)"
    done
    echo ""

    # Find the last completed step
    LAST_STEP=$(ls -1 ${ARTIFACTS_DIR}/step*.md 2>/dev/null | sed 's/.*step\([0-9][0-9]*\).*/\1/' | sort -n | tail -1)

    if [ -n "$LAST_STEP" ]; then
        echo "Last completed step: $LAST_STEP"
        read -p "Resume from step $((LAST_STEP + 1))? (y/n, default: y): " RESUME_CHOICE
        RESUME_CHOICE=${RESUME_CHOICE:-y}

        if [[ "$RESUME_CHOICE" == "y" ]]; then
            RESUME_FROM=$LAST_STEP
            echo "✓ Resuming from step $((RESUME_FROM + 1))"
            echo ""
        else
            echo "Starting from beginning (existing artifacts will be overwritten)"
            echo ""
        fi
    fi
else
    echo "📁 Created artifacts directory: $ARTIFACTS_DIR"
fi

# Initialize token tracking log
TOKEN_LOG="${ARTIFACTS_DIR}/token-usage.log"
if [ "$RESUME_FROM" -eq 0 ]; then
    echo "Token Usage Log - $(date)" > "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "" >> "$TOKEN_LOG"
else
    echo "" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "Resumed session - $(date)" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "" >> "$TOKEN_LOG"
fi

echo ""

# Save step output to markdown file
save_artifact() {
    local step_num="$1"
    local step_name="$2"
    local content="$3"
    local filename="${ARTIFACTS_DIR}/step${step_num}-${step_name}.md"

    cat > "$filename" <<EOF
# Step ${step_num}: ${step_name}

${content}
EOF
    echo "💾 Saved: $filename"
}

# Load artifact from file
load_artifact() {
    local step_num="$1"
    local step_name="$2"
    local filename="${ARTIFACTS_DIR}/step${step_num}-${step_name}.md"

    if [ -f "$filename" ]; then
        # Extract content after the header (skip first 2 lines)
        tail -n +3 "$filename"
        return 0
    else
        return 1
    fi
}

# Check if step should run
should_run_step() {
    local step_num="$1"
    [ "$step_num" -gt "$RESUME_FROM" ]
}

# Track token usage (estimates based on character count)
# Note: Only tracking output tokens; input tokens managed by --continue
TOTAL_ESTIMATED_OUTPUT_TOKENS=0
declare -a STEP_TOKENS

# Estimate tokens (rough approximation: ~4 chars per token)
estimate_tokens() {
    local text="$1"
    local char_count=${#text}
    echo $((char_count / 4))
}

# Log token usage for a step (output only, input managed by --continue)
log_tokens() {
    local step_num="$1"
    local step_name="$2"
    local output_text="$3"

    local output_tokens=$(estimate_tokens "$output_text")

    TOTAL_ESTIMATED_OUTPUT_TOKENS=$((TOTAL_ESTIMATED_OUTPUT_TOKENS + output_tokens))

    local step_info="Step $step_num ($step_name): Output≈$output_tokens"
    STEP_TOKENS+=("$step_info")

    # Log to file
    echo "$step_info" >> "$TOKEN_LOG"

    # Display to console
    echo "📊 Estimated output tokens: ~$output_tokens"
}

# Check for Node.js and npm
echo "🔍 Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "📦 Installing Node.js..."

    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install node
        else
            echo "⚠️  Homebrew not found. Please install Node.js manually from https://nodejs.org/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y nodejs npm
        elif command -v yum &> /dev/null; then
            sudo yum install -y nodejs npm
        else
            echo "⚠️  Package manager not found. Please install Node.js manually from https://nodejs.org/"
            exit 1
        fi
    else
        echo "⚠️  OS not supported for auto-install. Please install Node.js manually from https://nodejs.org/"
        exit 1
    fi
else
    echo "✓ Node.js $(node --version) is installed"
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    echo "⚠️  npm should come with Node.js. Please reinstall Node.js from https://nodejs.org/"
    exit 1
else
    echo "✓ npm $(npm --version) is installed"
fi

# Check for Claude CLI
if ! command -v claude &> /dev/null; then
    echo "❌ Claude CLI is not installed"
    echo "⚠️  Please install Claude CLI first: https://claude.ai/download"
    exit 1
else
    echo "✓ Claude CLI is installed"
fi

echo ""

# Create shadcn project
if [ -d "website" ]; then
    echo "✓ website/ folder already exists, skipping creation"
    echo ""
else
    # Open the shadcn UI in the user's default browser before proceeding
    if command -v open &> /dev/null; then
        open "https://ui.shadcn.com/create"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://ui.shadcn.com/create"
    else
        echo "⚠️  Please manually open https://ui.shadcn.com/create in your browser."
    fi

    echo "🚀 Project Setup"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Please visit https://ui.shadcn.com/create to configure your project"
    echo ""
    echo "Once you've configured your preferences, copy the npx command and paste it below."
    echo "The project will be created in the 'website/' folder."
    echo ""
    echo "Example:"
    echo "npx shadcn@latest create --preset \"https://ui.shadcn.com/init?base=radix&style=vega&baseColor=neutral&theme=neutral&iconLibrary=lucide&font=inter&menuAccent=subtle&menuColor=default&radius=default&template=next&rtl=false\" --template next"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    read -p "Paste your npx command here: " NPX_COMMAND

    if [[ -z "$NPX_COMMAND" ]]; then
        echo "❌ No command provided. Exiting..."
        exit 1
    fi

    echo ""
    echo "📦 Creating your shadcn project in website/ folder..."
    echo ""

    # Execute the npx command with website as the project name
    eval "$NPX_COMMAND website"

    if [ $? -ne 0 ]; then
        echo "❌ Project creation failed. Please check the command and try again."
        exit 1
    fi

    echo ""
    echo "✓ Project created successfully in website/ folder!"
    echo ""
fi

# Create Remotion video project
if [ -d "video" ]; then
    echo "✓ video/ folder already exists, skipping creation"
    echo ""
else
    echo "🎬 Video Project Setup"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📦 Creating Remotion video project in video/ folder..."
    echo ""

    # Create Remotion project with prompt-to-motion-graphics template
    expect <<'EOF'
spawn npx create-video@latest video --prompt-to-motion-graphics
expect "Add agent skills?"
send "n\r"
expect "Open in Cursor?"
send "n\r"
expect eof
EOF

    if [ $? -ne 0 ]; then
        echo "❌ Remotion project creation failed."
        exit 1
    fi

    # Navigate to video folder and set up additional tools
    cd video || {
        echo "❌ Failed to enter video directory"
        exit 1
    }

    # Install Tailwind CSS
    echo "📦 Installing Tailwind CSS..."
    npm install -D tailwindcss postcss autoprefixer || {
        echo "❌ Failed to install Tailwind CSS"
        cd ..
        exit 1
    }

    npx tailwindcss init -p || {
        echo "⚠️  Tailwind init failed, but continuing..."
    }

    # Create Tailwind config
    cat > tailwind.config.js <<'TAILWIND_EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
TAILWIND_EOF

    # Add Tailwind directives to a global CSS file
    mkdir -p src/styles
    cat > src/styles/globals.css <<'CSS_EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSS_EOF

    # Create .clawdbot directory and symlink agent skills
    echo "🔗 Setting up agent skills..."
    mkdir -p .clawdbot

    # Symlink recommended agent skills from parent or home directory
    # Users can customize this based on their agent skills location
    if [ -d "$HOME/.clawdbot/skills" ]; then
        ln -s "$HOME/.clawdbot/skills" .clawdbot/skills
        echo "✓ Symlinked agent skills from ~/.clawdbot/skills"
    else
        echo "⚠️  No agent skills found at ~/.clawdbot/skills"
        echo "   You can manually create symlinks later"
    fi

    cd ..

    echo ""
    echo "✓ Remotion project created successfully in video/ folder!"
    echo "✓ Tailwind CSS configured"
    echo "✓ Agent skills setup complete"
    echo ""
fi

# Collect user input for brand development
echo "💭 Brand Vision"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "What do you want to build? Describe your product/service idea."
echo ""
echo "You can include:"
echo "  - Product description"
echo "  - Reference websites (URLs)"
echo "  - Target audience"
echo "  - Key differentiators"
echo "  - Any other relevant details"
echo ""
echo "Enter your vision below (press Enter on an empty line when finished):"
echo "────────────────────────────────────────────────────────────────"
echo ""

# Read multi-line input until empty line
USER_VISION=""
while IFS= read -r line; do
    # Break on empty line
    if [[ -z "$line" ]]; then
        break
    fi
    # Append line to vision
    if [[ -z "$USER_VISION" ]]; then
        USER_VISION="$line"
    else
        USER_VISION="${USER_VISION}"$'\n'"${line}"
    fi
done

if [[ -z "$USER_VISION" ]]; then
    echo ""
    echo "❌ No vision provided. Exiting..."
    exit 1
fi

echo ""
echo "────────────────────────────────────────────────────────────────"
echo "✓ Vision captured! Starting brand development..."
echo ""

# Step 1: Target Profile
if should_run_step 1; then
    echo "Step 1/10: Creating Target Profile..."
    STEP1_OUTPUT=$(claude -p --permission-mode bypassPermissions --model claude-opus-4-5-20251101 "$(cat <<EOF
We're going to build the following product/service. Create a brand target profile following the brand framework shown in @instructions/1.png

USER VISION:
${USER_VISION}

Consider:
- consumer vs b2b positioning
- "this for that" comparisons
- high level strategic ideas
- competitive landscape

Create a comprehensive target profile based on the user's vision above.
EOF
)")

    log_tokens "1" "target-profile" "$STEP1_OUTPUT"
    save_artifact "1" "target-profile" "$STEP1_OUTPUT"
    echo "✓ Step 1 complete"
    echo ""
else
    echo "⏭️  Step 1: Loading from artifacts..."
    STEP1_OUTPUT=$(load_artifact "1" "target-profile")
    echo "✓ Step 1 loaded"
    echo ""
fi

# Step 2: Product Features
if should_run_step 2; then
    echo "Step 2/10: Defining Product Features..."
    STEP2_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Based on this target profile, list all of the potential product features that would be amazing for a consumer-based AI service following the framework in @instructions/2.png

Think comprehensively about what features would delight users and differentiate the product.")

    log_tokens "2" "product-features" "$STEP2_OUTPUT"
    save_artifact "2" "product-features" "$STEP2_OUTPUT"
    echo "✓ Step 2 complete"
    echo ""
else
    echo "⏭️  Step 2: Loading from artifacts..."
    STEP2_OUTPUT=$(load_artifact "2" "product-features")
    echo "✓ Step 2 loaded"
    echo ""
fi

# Step 3: Features to Benefits
if should_run_step 3; then
    echo "Step 3/10: Converting Features to Benefits..."
    STEP3_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Next, turn our features into benefits following the framework in @instructions/3.png

For each feature, explain the tangible benefit it provides to the user. Focus on emotional and practical outcomes, not just functionality.")

    log_tokens "3" "features-to-benefits" "$STEP3_OUTPUT"
    save_artifact "3" "features-to-benefits" "$STEP3_OUTPUT"
    echo "✓ Step 3 complete"
    echo ""
else
    echo "⏭️  Step 3: Loading from artifacts..."
    STEP3_OUTPUT=$(load_artifact "3" "features-to-benefits")
    echo "✓ Step 3 loaded"
    echo ""
fi

# Step 4: Winning Zone
if should_run_step 4; then
    echo "Step 4/10: Mapping Winning Zone..."
    STEP4_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Our next step is to map out our winning zone following the framework in @instructions/4.png

How will our AI service outperform everyone else? What is our unique positioning and competitive advantage in the market?")

    log_tokens "4" "winning-zone" "$STEP4_OUTPUT"
    save_artifact "4" "winning-zone" "$STEP4_OUTPUT"
    echo "✓ Step 4 complete"
    echo ""
else
    echo "⏭️  Step 4: Loading from artifacts..."
    STEP4_OUTPUT=$(load_artifact "4" "winning-zone")
    echo "✓ Step 4 loaded"
    echo ""
fi

# Step 5: Brand Persona
if should_run_step 5; then
    echo "Step 5/10: Defining Brand Persona..."
    STEP5_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Now based on this, let's choose a primary and secondary brand persona following the framework in @instructions/5.png

Consider brand archetypes (e.g., Hero, Sage, Explorer, Creator, etc.) and explain why these personas align with our positioning.")

    log_tokens "5" "brand-persona" "$STEP5_OUTPUT"
    save_artifact "5" "brand-persona" "$STEP5_OUTPUT"
    echo "✓ Step 5 complete"
    echo ""
else
    echo "⏭️  Step 5: Loading from artifacts..."
    STEP5_OUTPUT=$(load_artifact "5" "brand-persona")
    echo "✓ Step 5 loaded"
    echo ""
fi

# Step 6: Brand Guidelines
if should_run_step 6; then
    echo "Step 6/10: Creating Brand Guidelines..."
    STEP6_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Translate this into comprehensive brand guidelines, including:
- Tone of voice with specific examples
- Visual direction and design principles
- Do's and don'ts for brand communication
- Key messaging pillars")

    log_tokens "6" "brand-guidelines" "$STEP6_OUTPUT"
    save_artifact "6" "brand-guidelines" "$STEP6_OUTPUT"

    # Generate PDF for brand guidelines
    echo "📄 Generating high-quality PDF for brand guidelines..."
    mkdir -p assets
    if command -v pandoc &> /dev/null; then
        if command -v xelatex &> /dev/null; then
            pandoc "${ARTIFACTS_DIR}/step6-brand-guidelines.md" \
                -o "assets/brand-guidelines.pdf" \
                --pdf-engine=xelatex \
                -V geometry:margin=1in \
                -V fontsize=11pt \
                -V documentclass=article \
                -V papersize=letter \
                --toc \
                --toc-depth=2 \
                2>&1 | tee /tmp/pandoc-error.log
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                echo "✓ PDF generated: assets/brand-guidelines.pdf"
            else
                echo "⚠️  PDF generation failed. Error log:"
                cat /tmp/pandoc-error.log
                echo "Markdown version saved in artifacts/"
            fi
        else
            echo "⚠️  xelatex (MacTeX) not found. Install with: brew bundle"
            echo "   Skipping PDF generation (markdown saved)"
        fi
    else
        echo "⚠️  pandoc not found. Install with: brew bundle"
        echo "   Skipping PDF generation (markdown saved)"
    fi

    echo "✓ Step 6 complete"
    echo ""
else
    echo "⏭️  Step 6: Loading from artifacts..."
    STEP6_OUTPUT=$(load_artifact "6" "brand-guidelines")
    echo "✓ Step 6 loaded"
    echo ""
fi

# Step 7: Website Design Prompt
if should_run_step 7; then
    echo "Step 7/10: Generating Website Design Prompt..."
    STEP7_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Research Aura.build and some of its most popular templates. Create a comprehensive prompt that can be used in v0.app to create an amazingly rich, visually appealing landing page.

    See @instructions/7.md for the framework example, but don't use it exactly. Follow the brand guidelines we created.

Include:
- How to Use This
- Full Prompt (Copy This First)
- Section-by-Section Refinement Prompts
- Style Refinement Prompts
- Alternative Hero Prompts
- Component Prompts for Remixing
- Support for light/dark mode
- Final Checklist Prompt
- Notes for Best Results")

    log_tokens "7" "website-design-prompt" "$STEP7_OUTPUT"
    save_artifact "7" "website-design-prompt" "$STEP7_OUTPUT"
    echo "✓ Step 7 complete"
    echo ""
else
    echo "⏭️  Step 7: Loading from artifacts..."
    STEP7_OUTPUT=$(load_artifact "7" "website-design-prompt")
    echo "✓ Step 7 loaded"
    echo ""
fi

# Step 8: Build Site
if should_run_step 8; then
    echo "Step 8/10: Building High Fidelity Website..."
    STEP8_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Now implement the website design in the website/ directory. Use the design prompt from the previous step as your guide.

IMPORTANT:
- Work in the website/ directory (a Next.js project with shadcn/ui)
- Put all brand assets (logos, images, icons, etc.) in assets/ directory at the project root
- Actually write/edit the code files - don't just describe what to do
- Implement all sections from the design prompt systematically
- Use the Read, Edit, and Write tools to modify files in website/
- Follow the brand guidelines we created
- Create a high-fidelity implementation, not a prototype

Start by reading the existing website structure, then implement each section of the landing page.")

    log_tokens "8" "build-site" "$STEP8_OUTPUT"
    save_artifact "8" "build-site" "$STEP8_OUTPUT"
    echo "✓ Step 8 complete"
    echo ""
else
    echo "⏭️  Step 8: Loading from artifacts..."
    STEP8_OUTPUT=$(load_artifact "8" "build-site")
    echo "✓ Step 8 loaded"
    echo ""
fi

# Step 9: Video Marketing Prompt
if should_run_step 9; then
    echo "Step 9/10: Creating Video Marketing Prompts..."
    STEP9_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Look at the Remotion framework and come up with a series of prompts to create an amazing marketing video using Claude Code.

References:
- https://x.com/Remotion/status/2013626968386765291
- https://gist.github.com/JonnyBurger/5b801182176f1b76447901fbeb5a84ac
- https://www.remotion.dev

Create detailed prompts for:
- Video concept and storyboard
- Scene-by-scene breakdown
- Animation specifications
- Code structure for Remotion
- Asset requirements")

    log_tokens "9" "video-marketing-prompts" "$STEP9_OUTPUT"
    save_artifact "9" "video-marketing-prompts" "$STEP9_OUTPUT"
    echo "✓ Step 9 complete"
    echo ""
else
    echo "⏭️  Step 9: Loading from artifacts..."
    STEP9_OUTPUT=$(load_artifact "9" "video-marketing-prompts")
    echo "✓ Step 9 loaded"
    echo ""
fi

# Step 10: Build Video
if should_run_step 10; then
    echo "Step 10/10: Building High Quality Brand Video..."
    STEP10_OUTPUT=$(claude -p --permission-mode bypassPermissions --continue --model claude-opus-4-5-20251101 "Now implement the marketing video in the video/ directory. Use the video prompts from the previous step as your guide.

IMPORTANT:
- Work in the video/ directory (a Remotion project with Tailwind CSS)
- Use brand assets from the assets/ directory at the project root
- Actually write/edit the code files - don't just describe what to do
- Implement all scenes from the video prompts systematically
- Use the Read, Edit, and Write tools to modify files in video/
- Follow the brand guidelines we created
- Create high-quality animations and transitions

Start by reading the existing video project structure, then implement each scene of the marketing video.")

    log_tokens "10" "build-video" "$STEP10_OUTPUT"
    save_artifact "10" "build-video" "$STEP10_OUTPUT"
    echo "✓ Step 10 complete"
    echo ""

    # Render the video
    echo "🎬 Rendering brand video..."
    mkdir -p assets
    cd video
    npx remotion render --output ../assets/brand-video.mp4
    if [ $? -eq 0 ]; then
        echo "✓ Video rendered to assets/brand-video.mp4"
    else
        echo "⚠️  Video rendering failed, but continuing..."
    fi
    cd ..
    echo ""
else
    echo "⏭️  Step 10: Loading from artifacts..."
    STEP10_OUTPUT=$(load_artifact "10" "build-video")
    echo "✓ Step 10 loaded"
    echo ""
fi

# Save final output
echo "💾 Saving complete brand development to brand-output.md..."
cat > brand-output.md <<EOF
# Complete Brand Development Output

## Step 1: Target Profile
${STEP1_OUTPUT}

---

## Step 2: Product Features
${STEP2_OUTPUT}

---

## Step 3: Features to Benefits
${STEP3_OUTPUT}

---

## Step 4: Winning Zone
${STEP4_OUTPUT}

---

## Step 5: Brand Persona
${STEP5_OUTPUT}

---

## Step 6: Brand Guidelines
${STEP6_OUTPUT}

---

## Step 7: Website Design Prompt
${STEP7_OUTPUT}

---

## Step 8: Build Site
${STEP8_OUTPUT}

---

## Step 9: Video Marketing Prompts
${STEP9_OUTPUT}

---

## Step 10: Build Video
${STEP10_OUTPUT}
EOF

echo "✅ Brand development pipeline complete!"
echo ""
echo "📄 Outputs saved:"
echo "  - Consolidated: brand-output.md"
echo "  - Individual steps: ${ARTIFACTS_DIR}/"
echo ""
echo "🎨 Brand Assets (assets/):"
if [ -f "assets/brand-guidelines.pdf" ]; then
    ls -lh assets/brand-guidelines.pdf | awk '{print "  - "$9" ("$5")"}'
fi
if [ -f "assets/brand-video.mp4" ]; then
    ls -lh assets/brand-video.mp4 | awk '{print "  - "$9" ("$5")"}'
fi
if [ -d "assets" ]; then
    echo "  - Other assets: assets/"
fi
echo ""
echo "📝 Step Artifacts:"
ls -lh ${ARTIFACTS_DIR}/*.md 2>/dev/null | awk '{print "  - "$9" ("$5")"}'

# Display token usage summary
if [ "$TOTAL_ESTIMATED_OUTPUT_TOKENS" != "0" ]; then
    echo ""
    echo "📊 Token Usage Summary (Estimated):"
    echo "════════════════════════════════════════════════════════════════"
    for step_info in "${STEP_TOKENS[@]}"; do
        echo "  $step_info"
    done
    echo "────────────────────────────────────────────────────────────────"
    echo "  Total Output Tokens: ~$TOTAL_ESTIMATED_OUTPUT_TOKENS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Note: Token estimates use ~4 chars/token approximation."
    echo "      Input tokens managed by --continue are not tracked here."
    echo "Detailed log saved to: $TOKEN_LOG"

    # Save summary to log file
    echo "" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "SUMMARY" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "Total Estimated Output Tokens: $TOTAL_ESTIMATED_OUTPUT_TOKENS" >> "$TOKEN_LOG"
    echo "" >> "$TOKEN_LOG"
    echo "Estimation method: ~4 characters per token" >> "$TOKEN_LOG"
    echo "Note: Input tokens managed by --continue are not tracked" >> "$TOKEN_LOG"
fi
