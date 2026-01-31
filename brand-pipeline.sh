#!/bin/bash

# Brand Development Pipeline
# Chains multiple Claude prompts together, passing output from each step to the next

set -e  # Exit on error

echo "🎨 Starting Brand Development Pipeline..."
echo ""

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

echo ""

# Create shadcn project
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

# Remove existing website folder if it exists
if [ -d "website" ]; then
    echo "⚠️  website/ folder already exists. Removing..."
    rm -rf website
fi

# Execute the npx command with website as the project name
eval "$NPX_COMMAND website"

if [ $? -ne 0 ]; then
    echo "❌ Project creation failed. Please check the command and try again."
    exit 1
fi

echo ""
echo "✓ Project created successfully in website/ folder!"
echo ""

# Step 1: Target Profile
echo "Step 1/9: Creating Target Profile..."
STEP1_OUTPUT=$(claude -p "$(cat <<'EOF'
We're going to create clawdbot as a service, build the brand target profile following the brand framework shown in @instructions/1.png

Reference websites:
- https://clawdhub.com
- https://clawdhub.com/skills
- https://x.com/steipete

Consider:
- consumer vs b2b positioning
- "this for that" comparisons
- high level strategic ideas

Create a comprehensive target profile for this AI service.
EOF
)")

echo "✓ Step 1 complete"
echo ""

# Step 2: Product Features
echo "Step 2/9: Defining Product Features..."
STEP2_OUTPUT=$(claude -p "$(cat <<EOF
Context from previous step:
${STEP1_OUTPUT}

Based on this target profile, list all of the potential product features that would be amazing for a consumer-based AI service following the framework in @instructions/2.png

Think comprehensively about what features would delight users and differentiate the product.
EOF
)")

echo "✓ Step 2 complete"
echo ""

# Step 3: Features to Benefits
echo "Step 3/9: Converting Features to Benefits..."
STEP3_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP2_OUTPUT}

Next, turn our features into benefits following the framework in @instructions/3.png

For each feature, explain the tangible benefit it provides to the user. Focus on emotional and practical outcomes, not just functionality.
EOF
)")

echo "✓ Step 3 complete"
echo ""

# Step 4: Winning Zone
echo "Step 4/9: Mapping Winning Zone..."
STEP4_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP3_OUTPUT}

Our next step is to map out our winning zone following the framework in @instructions/4.png

How will our AI service outperform everyone else? What is our unique positioning and competitive advantage in the market?
EOF
)")

echo "✓ Step 4 complete"
echo ""

# Step 5: Brand Persona
echo "Step 5/9: Defining Brand Persona..."
STEP5_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP4_OUTPUT}

Now based on this, let's choose a primary and secondary brand persona following the framework in @instructions/5.png

Consider brand archetypes (e.g., Hero, Sage, Explorer, Creator, etc.) and explain why these personas align with our positioning.
EOF
)")

echo "✓ Step 5 complete"
echo ""

# Step 6: Brand Guidelines
echo "Step 6/9: Creating Brand Guidelines..."
STEP6_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP5_OUTPUT}

Translate this into comprehensive brand guidelines, including:
- Tone of voice with specific examples
- Visual direction and design principles
- Do's and don'ts for brand communication
- Key messaging pillars
EOF
)")

echo "✓ Step 6 complete"
echo ""

# Step 7: Website Design Prompt
echo "Step 7/9: Generating Website Design Prompt..."
STEP7_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP6_OUTPUT}

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

echo "✓ Step 7 complete"
echo ""

# Step 8: Build Site
echo "Step 8/9: Building High Fidelity Website..."
STEP8_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP7_OUTPUT}

Sequentially implement all of the steps in the website project, building a high fidelity website based on the brand guidelines and design prompt we've created.

Review the website requirements and create a comprehensive implementation plan that brings the brand to life through code.
EOF
)")

echo "✓ Step 8 complete"
echo ""

# Step 9: Video Marketing Prompt
echo "Step 9/9: Creating Video Marketing Prompts..."
STEP9_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP8_OUTPUT}

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
echo "📄 Full output saved to: brand-output.md"
