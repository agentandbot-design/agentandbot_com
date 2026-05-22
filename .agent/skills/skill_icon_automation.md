# Agent Skill: Autonomous Icon Generation & Distribution

## Overview
This skill allows the agent to act as the primary "Icon Producer" for the Harezm and Eny ecosystems. It autonomously designs, vectorizes, color-maps, and distributes cross-platform surrealist icons based on the "Messy Marker" brand identity.

## Trigger
When the user says: "Şu menüye X ifade eden bir ikon lazım", "Yeni bir ikon üretelim", or "Y ikonunu oluştur ve dağıt."

## Step-by-Step Workflow

### 1. Phase 1: AI Image Generation
*   **Tool:** Use `generate_image`.
*   **Target Path:** Temporary brain storage.
*   **Prompt String:** `"A single surrealist micro-illustration icon of a [ICON NAME/CONCEPT]. [ABSURD DETAIL]. Messy wobbly marker lines, thick scribbled ink, heavy pencil hatching, sketchy hand-drawn editorial style, white background. Two-color: rough black structural lines, one yellow highlighter accent highlight for the key detail. No clean lines, absurd aesthetic."`
*   *Note:* First, peek at `b:\DEV\HAREZM_EKOSISTEMI\brand\assets\icons\ikon.md` to see if a specific absurd detail was already defined for this concept.

### 2. Phase 2: Staging
*   **Action:** Copy the generated `.png` from the AI workspace to the generator directory.
*   **Command:** `Copy-Item [AI_IMAGE_PATH] -Destination "b:\DEV\HAREZM_EKOSISTEMI\brand\assets\icons\generated\icon_XX_[name].png"`

### 3. Phase 3: Vectorization (SVG Dönüşümü)
*   **Directory:** `b:\DEV\HAREZM_EKOSISTEMI\brand\assets\icons\generated`
*   **Command:** `node vectorize.js`
*   **Verification:** Ensure the command exits successfully. This script will automatically:
    *   Trace the PNG.
    *   Convert black boundaries to `currentColor`.
    *   Convert the yellow highlight to `var(--accent)`.
    *   Nullify white backgrounds.

### 4. Phase 4: Ecosystem Distribution
*   **Directory:** `b:\DEV\HAREZM_EKOSISTEMI\brand`
*   **Command:** `node distribute_icons.mjs`
*   **Expectation:** The SVG file is copied into `[project_name]/public/icons/` for all 8 core ecosystem UI frontends.

### 5. Phase 5: Implementation (Optional)
*   **Action:** If requested, navigate to the specific `Astro` file (e.g., `Header.astro` or `index.astro`) and replace the old icon component with `<Icon name="icon_XX_[name]" />`.
