#!/bin/bash

# Brand Development Pipeline
# Chains multiple Claude prompts together, passing output from each step to the next

set -e  # Exit on error

echo "🎨 Starting Brand Development Pipeline..."
echo ""

# Create artifacts directory
ARTIFACTS_DIR="artifacts"
mkdir -p "$ARTIFACTS_DIR"
echo "📁 Created artifacts directory: $ARTIFACTS_DIR"

# Initialize token tracking log
TOKEN_LOG="${ARTIFACTS_DIR}/token-usage.log"
echo "Token Usage Log - $(date)" > "$TOKEN_LOG"
echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
echo "" >> "$TOKEN_LOG"

echo ""

# Build prompt text with previous context and a heredoc body.
build_prompt() {
    local prev="$1"
    printf 'Previous context:\n'
    printf '%s\n' "$prev"
    printf '\n'
    cat
}

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

# Track token usage (estimates based on character count)
TOTAL_ESTIMATED_INPUT_TOKENS=0
TOTAL_ESTIMATED_OUTPUT_TOKENS=0
declare -a STEP_TOKENS

# Estimate tokens (rough approximation: ~4 chars per token)
estimate_tokens() {
    local text="$1"
    local char_count=${#text}
    echo $((char_count / 4))
}

# Log token usage for a step
log_tokens() {
    local step_num="$1"
    local step_name="$2"
    local input_text="$3"
    local output_text="$4"

    local input_tokens=$(estimate_tokens "$input_text")
    local output_tokens=$(estimate_tokens "$output_text")
    local total_tokens=$((input_tokens + output_tokens))

    TOTAL_ESTIMATED_INPUT_TOKENS=$((TOTAL_ESTIMATED_INPUT_TOKENS + input_tokens))
    TOTAL_ESTIMATED_OUTPUT_TOKENS=$((TOTAL_ESTIMATED_OUTPUT_TOKENS + output_tokens))

    local step_info="Step $step_num ($step_name): Input≈$input_tokens, Output≈$output_tokens, Total≈$total_tokens"
    STEP_TOKENS+=("$step_info")

    # Log to file
    echo "$step_info" >> "$TOKEN_LOG"

    # Display to console
    echo "📊 Estimated tokens: ~$total_tokens (Input: ~$input_tokens, Output: ~$output_tokens)"
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

    # Create blank Remotion project without git
    npx create-video@latest video --blank || {
        echo "❌ Remotion project creation failed."
        exit 1
    }

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
echo "Enter your vision below (press Ctrl+D when finished):"
echo "────────────────────────────────────────────────────────────────"
echo ""

# Read multi-line input until EOF (Ctrl+D)
USER_VISION=$(cat)

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
echo "Step 1/9: Creating Target Profile..."
STEP1_OUTPUT=$(claude -p "$(cat <<EOF
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

log_tokens "1" "target-profile" "$USER_VISION" "$STEP1_OUTPUT"
save_artifact "1" "target-profile" "$STEP1_OUTPUT"
echo "✓ Step 1 complete"
echo ""

# Step 2: Product Features
echo "Step 2/9: Defining Product Features..."
STEP2_OUTPUT=$(claude -p "$(build_prompt "$STEP1_OUTPUT" <<'EOF'
Based on this target profile, list all of the potential product features that would be amazing for a consumer-based AI service following the framework in @instructions/2.png

Think comprehensively about what features would delight users and differentiate the product.
EOF
)")

log_tokens "2" "product-features" "$STEP1_OUTPUT" "$STEP2_OUTPUT"
save_artifact "2" "product-features" "$STEP2_OUTPUT"
echo "✓ Step 2 complete"
echo ""

# Step 3: Features to Benefits
echo "Step 3/9: Converting Features to Benefits..."
STEP3_OUTPUT=$(claude -p "$(build_prompt "$STEP2_OUTPUT" <<'EOF'
Next, turn our features into benefits following the framework in @instructions/3.png

For each feature, explain the tangible benefit it provides to the user. Focus on emotional and practical outcomes, not just functionality.
EOF
)")

log_tokens "3" "features-to-benefits" "$STEP2_OUTPUT" "$STEP3_OUTPUT"
save_artifact "3" "features-to-benefits" "$STEP3_OUTPUT"
echo "✓ Step 3 complete"
echo ""

# Step 4: Winning Zone
echo "Step 4/9: Mapping Winning Zone..."
STEP4_OUTPUT=$(claude -p "$(build_prompt "$STEP3_OUTPUT" <<'EOF'
Our next step is to map out our winning zone following the framework in @instructions/4.png

How will our AI service outperform everyone else? What is our unique positioning and competitive advantage in the market?
EOF
)")

log_tokens "4" "winning-zone" "$STEP3_OUTPUT" "$STEP4_OUTPUT"
save_artifact "4" "winning-zone" "$STEP4_OUTPUT"
echo "✓ Step 4 complete"
echo ""

# Step 5: Brand Persona
echo "Step 5/9: Defining Brand Persona..."
STEP5_OUTPUT=$(claude -p "$(build_prompt "$STEP4_OUTPUT" <<'EOF'
Now based on this, let's choose a primary and secondary brand persona following the framework in @instructions/5.png

Consider brand archetypes (e.g., Hero, Sage, Explorer, Creator, etc.) and explain why these personas align with our positioning.
EOF
)")

log_tokens "5" "brand-persona" "$STEP4_OUTPUT" "$STEP5_OUTPUT"
save_artifact "5" "brand-persona" "$STEP5_OUTPUT"
echo "✓ Step 5 complete"
echo ""

# Step 6: Brand Guidelines
echo "Step 6/9: Creating Brand Guidelines..."
STEP6_OUTPUT=$(claude -p "$(build_prompt "$STEP5_OUTPUT" <<'EOF'
Translate this into comprehensive brand guidelines, including:
- Tone of voice with specific examples
- Visual direction and design principles
- Do's and don'ts for brand communication
- Key messaging pillars
EOF
)")

log_tokens "6" "brand-guidelines" "$STEP5_OUTPUT" "$STEP6_OUTPUT"
save_artifact "6" "brand-guidelines" "$STEP6_OUTPUT"

# Generate PDF for brand guidelines
echo "📄 Generating PDF for brand guidelines..."
if command -v pandoc &> /dev/null; then
    pandoc "${ARTIFACTS_DIR}/step6-brand-guidelines.md" \
        -o "${ARTIFACTS_DIR}/step6-brand-guidelines.pdf" \
        --pdf-engine=xelatex \
        -V geometry:margin=1in \
        -V fontsize=12pt \
        --toc \
        2>/dev/null && echo "✓ PDF generated: ${ARTIFACTS_DIR}/step6-brand-guidelines.pdf" || echo "⚠️  PDF generation failed, markdown saved"
else
    echo "⚠️  pandoc not found, skipping PDF generation (markdown saved)"
fi

echo "✓ Step 6 complete"
echo ""

# Step 7: Website Design Prompt
echo "Step 7/9: Generating Website Design Prompt..."
STEP7_OUTPUT=$(claude -p "$(build_prompt "$STEP6_OUTPUT" <<'EOF'
Research Aura.build and some of its most popular templates. Create a comprehensive prompt that can be used in v0.app to create an amazingly rich, visually appealing landing page.

Include:
- How to Use This
- Full Prompt (Copy This First)
- Section-by-Section Refinement Prompts
- Style Refinement Prompts
- Alternative Hero Prompts
- Component Prompts for Remixing
- Final Checklist Prompt
- Notes for Best Results
EOF
)")

log_tokens "7" "website-design-prompt" "$STEP6_OUTPUT" "$STEP7_OUTPUT"
save_artifact "7" "website-design-prompt" "$STEP7_OUTPUT"
echo "✓ Step 7 complete"
echo ""

# Step 8: Build Site
echo "Step 8/9: Building High Fidelity Website..."
STEP8_OUTPUT=$(claude -p "$(build_prompt "$STEP7_OUTPUT" <<'EOF'
Sequentially implement all of the steps in the website project, building a high fidelity website based on the brand guidelines and design prompt we've created.

Review the website requirements and create a comprehensive implementation plan that brings the brand to life through code.
EOF
)")

log_tokens "8" "build-site" "$STEP7_OUTPUT" "$STEP8_OUTPUT"
save_artifact "8" "build-site" "$STEP8_OUTPUT"
echo "✓ Step 8 complete"
echo ""

# Step 9: Video Marketing Prompt
echo "Step 9/9: Creating Video Marketing Prompts..."
STEP9_OUTPUT=$(claude -p "$(build_prompt "$STEP8_OUTPUT" <<'EOF'
Look at the Remotion framework and come up with a series of prompts to create an amazing marketing video using Claude Code.

References:
- https://x.com/Remotion/status/2013626968386765291
- https://gist.github.com/JonnyBurger/5b801182176f1b76447901fbeb5a84ac
- https://www.remotion.dev

Create detailed prompts for:
- Video concept and storyboard
- Scene-by-scene breakdown
- Animation specifications
- Code structure for Remotion
- Asset requirements
EOF
)")

log_tokens "9" "video-marketing-prompts" "$STEP8_OUTPUT" "$STEP9_OUTPUT"
save_artifact "9" "video-marketing-prompts" "$STEP9_OUTPUT"
echo "✓ Step 9 complete"
echo ""

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
EOF

echo "✅ Brand development pipeline complete!"
echo ""
echo "📄 Outputs saved:"
echo "  - Consolidated: brand-output.md"
echo "  - Individual steps: ${ARTIFACTS_DIR}/"
echo "  - Brand Guidelines PDF: ${ARTIFACTS_DIR}/step6-brand-guidelines.pdf (if pandoc available)"
echo ""
ls -lh ${ARTIFACTS_DIR}/*.md 2>/dev/null | awk '{print "  - "$9" ("$5")"}'
if [ -f "${ARTIFACTS_DIR}/step6-brand-guidelines.pdf" ]; then
    ls -lh "${ARTIFACTS_DIR}/step6-brand-guidelines.pdf" | awk '{print "  - "$9" ("$5")"}'
fi

# Display token usage summary
if [ "$TOTAL_ESTIMATED_INPUT_TOKENS" != "0" ] || [ "$TOTAL_ESTIMATED_OUTPUT_TOKENS" != "0" ]; then
    echo ""
    echo "📊 Token Usage Summary (Estimated):"
    echo "════════════════════════════════════════════════════════════════"
    for step_info in "${STEP_TOKENS[@]}"; do
        echo "  $step_info"
    done
    echo "────────────────────────────────────────────────────────────────"
    echo "  Total Input Tokens:  ~$TOTAL_ESTIMATED_INPUT_TOKENS"
    echo "  Total Output Tokens: ~$TOTAL_ESTIMATED_OUTPUT_TOKENS"
    echo "  Grand Total:         ~$((TOTAL_ESTIMATED_INPUT_TOKENS + TOTAL_ESTIMATED_OUTPUT_TOKENS))"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Note: Token estimates use ~4 chars/token approximation."
    echo "Detailed log saved to: $TOKEN_LOG"

    # Save summary to log file
    echo "" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "SUMMARY" >> "$TOKEN_LOG"
    echo "═══════════════════════════════════════════════════════" >> "$TOKEN_LOG"
    echo "Total Estimated Input Tokens:  $TOTAL_ESTIMATED_INPUT_TOKENS" >> "$TOKEN_LOG"
    echo "Total Estimated Output Tokens: $TOTAL_ESTIMATED_OUTPUT_TOKENS" >> "$TOKEN_LOG"
    echo "Grand Total:                   $((TOTAL_ESTIMATED_INPUT_TOKENS + TOTAL_ESTIMATED_OUTPUT_TOKENS))" >> "$TOKEN_LOG"
    echo "" >> "$TOKEN_LOG"
    echo "Estimation method: ~4 characters per token" >> "$TOKEN_LOG"
fi
