#!/bin/bash

# Brand Development Pipeline
# Chains multiple Claude prompts together, passing output from each step to the next

set -e  # Exit on error

echo "🎨 Starting Brand Development Pipeline..."
echo ""

# Step 1: Target Profile
echo "Step 1/8: Creating Target Profile..."
STEP1_OUTPUT=$(claude -p "$(cat <<'EOF'
We're going to create clawdbot as a service, build the brand target profile following the brand framework.

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
echo "Step 2/8: Defining Product Features..."
STEP2_OUTPUT=$(claude -p "$(cat <<EOF
Context from previous step:
${STEP1_OUTPUT}

Based on this target profile, list all of the potential product features that would be amazing for a consumer-based AI service. Think comprehensively about what features would delight users and differentiate the product.
EOF
)")

echo "✓ Step 2 complete"
echo ""

# Step 3: Features to Benefits
echo "Step 3/8: Converting Features to Benefits..."
STEP3_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP2_OUTPUT}

Next, turn our features into benefits. For each feature, explain the tangible benefit it provides to the user. Focus on emotional and practical outcomes, not just functionality.
EOF
)")

echo "✓ Step 3 complete"
echo ""

# Step 4: Winning Zone
echo "Step 4/8: Mapping Winning Zone..."
STEP4_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP3_OUTPUT}

Our next step is to map out our winning zone. How will our AI service outperform everyone else? What is our unique positioning and competitive advantage in the market?
EOF
)")

echo "✓ Step 4 complete"
echo ""

# Step 5: Brand Persona
echo "Step 5/8: Defining Brand Persona..."
STEP5_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP4_OUTPUT}

Now based on this, let's choose a primary and secondary brand persona. Consider brand archetypes (e.g., Hero, Sage, Explorer, Creator, etc.) and explain why these personas align with our positioning.
EOF
)")

echo "✓ Step 5 complete"
echo ""

# Step 6: Brand Guidelines
echo "Step 6/8: Creating Brand Guidelines..."
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
echo "Step 7/8: Generating Website Design Prompt..."
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

# Step 8: Video Marketing Prompt
echo "Step 8/8: Creating Video Marketing Prompts..."
STEP8_OUTPUT=$(claude -p "$(cat <<EOF
Previous context:
${STEP7_OUTPUT}

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

echo "✓ Step 8 complete"
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

## Step 8: Video Marketing Prompts
${STEP8_OUTPUT}
EOF

echo "✅ Brand development pipeline complete!"
echo "📄 Full output saved to: brand-output.md"
