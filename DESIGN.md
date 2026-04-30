# Caledoro Cozy Quests - Design System

## Core Theme Tokens
- **Color Mode**: LIGHT
- **Roundness**: ROUND_FULL (Maximum pill-shaped borders)
- **Primary Color**: #A9C4A6

### Typography
- **Headline Font**: Plus Jakarta Sans
- **Body Font**: Be Vietnam Pro
- **Label Font**: Space Grotesk

---

# Design System Specification

## 1. Overview & Creative North Star
**The Creative North Star: "The Digital Sanctuary"**
This design system moves away from the clinical efficiency of traditional productivity tools. Instead, it embraces the philosophy of "Cozy Productivity"—the idea that focus is best achieved in a low-stress, tactile, and nurturing environment. 

To break the "standard template" look, this system utilizes **Organic Layering**. We bypass rigid grids in favor of floating islands of content, intentional asymmetry, and extreme corner radii. The interface should feel less like a software dashboard and more like a collection of smooth river stones arranged on a desk. We prioritize breathability and soft transitions to ensure the user feels "at home" rather than "at work."

---

## 2. Colors
Our palette is rooted in nature-inspired tones, designed to reduce cognitive load and eye strain.

### Surface Hierarchy & The "No-Line" Rule
**Rule:** 1px solid borders are strictly prohibited for sectioning. 
Boundaries must be defined solely through background color shifts or tonal nesting. 
*   **Base Layer:** `surface` (#fcf9f2) provides the warm, paper-like foundation.
*   **Secondary Sections:** Use `surface_container_low` (#f6f3ec) for large, non-interactive areas.
*   **Interactive Cards:** Use `surface_container_lowest` (#ffffff) to make elements "pop" forward naturally.
*   **Depth through Nesting:** To indicate a "sub-task" or nested quest, move *up* the hierarchy (e.g., a `surface_container_highest` element sitting inside a `surface_container` parent).

### The "Glass & Gradient" Rule
To elevate the "Indie Sandbox" feel, use **Glassmorphism** for floating overlays (e.g., Modals or Popovers). 
*   **Formula:** `surface_variant` at 60% opacity + 20px Backdrop Blur.
*   **Signature Textures:** For Primary CTAs, use a subtle linear gradient (Top-Left to Bottom-Right) from `primary` (#4c644c) to `primary_container` (#a9c4a6). This adds a soft, "pillowy" volume that flat colors cannot replicate.

---

## 3. Typography
The typography strategy balances playfulness with high-performance legibility.

*   **Display & Headlines (Fredoka 600):** These are our "Voice." The rounded terminals of Fredoka mirror our UI's 24px radius, creating a unified visual language. Use large scales (`display-lg`) for "Quest" titles to create an editorial, low-stress feel.
*   **Body & UI (Nunito 600):** Nunito provides excellent readability for task descriptions and notes. Its high x-height keeps the "cozy" vibe even at smaller sizes.
*   **Functional & Timer (VT323):** The pixel-font is reserved strictly for time-tracking and gamified "XP" stats. This creates a nostalgic "Indie Sandbox" contrast against the soft, modern headlines.
*Note: Though the system defaults rely on Plus Jakarta Sans, Be Vietnam Pro, and Space Grotesk, use the specified web-fonts above when customizing the feel.*

---

## 4. Elevation & Depth

### The Layering Principle
Hierarchy is achieved through **Tonal Layering**. Instead of using shadows to indicate every interactive element, we use the `surface-container` tiers. 
*   **Low Importance:** `surface_dim`
*   **Default State:** `surface`
*   **High Importance:** `surface_bright`

### Ambient Shadows
When a component must "float" (e.g., a hovering timer or a persistent quest tracker):
*   **Shadow Color:** Use a tinted version of `on_surface` (e.g., #1c1c18 at 6% opacity).
*   **Blur/Spread:** Use high blur (30px+) and 0 spread. The shadow should feel like a soft glow of light, not a hard drop-shadow.

### The "Ghost Border" Fallback
If accessibility requirements demand a stroke (e.g., in Dark Mode), use a **Ghost Border**: 
*   `outline_variant` at 15% opacity. Never use 100% opaque lines; they break the "soft" immersion.

---

## 5. Components

### Buttons (The Pill System)
All buttons must use `rounded-full` (pill shape).
*   **Primary:** Gradient of `primary` to `primary_container`. White text. Use for "Start Quest" or "Complete."
*   **Secondary (Break):** `secondary_container`. Use for "Take a Break."
*   **Urgent/Stop:** `tertiary_container`. Use for "End Session" or "Delete."
*   **Padding:** 16px vertical / 32px horizontal. This "over-padding" reinforces the premium, airy feel.

### Chips (Quest Tags)
Use `surface_container_high` with `label-md` (Space Grotesk). These should feel like small, tactile stickers. No borders—only a subtle color shift on hover.

### Cards & Containers
*   **Radius:** Always `24px` (`xl` scale).
*   **Separation:** Strictly forbid dividers. Use `32px` vertical spacing or a shift to `surface_container_lowest` to separate content blocks.
*   **Interactive State:** On hover, a card should shift from `surface` to `surface_container_lowest` and gain a 4% ambient shadow.

### Quest Progress Inputs
Checkboxes should be oversized (28px x 28px) with a `10px` border-radius. When checked, use a soft bounce animation and fill with `primary`.

---

## 6. Do's and Don'ts

### Do:
*   **Do** embrace white space. If you think there’s enough room, add 16px more.
*   **Do** use asymmetrical layouts for "Quest" cards to make the app feel hand-crafted.
*   **Do** use the VT323 font for numbers ONLY to maintain a "retro-cozy" aesthetic without sacrificing general readability.

### Don’t:
*   **Don't** use pure black (#000000) for text or shadows. Use `on_surface` (#1c1c18).
*   **Don't** use sharp corners. If a component is smaller than 40px, use `rounded-md` (1.5rem); otherwise, use `rounded-xl` (3rem).
*   **Don't** use "Alert Red" for errors. Use the `tertiary` (#884d5a) tone—it signals urgency without inducing anxiety.
