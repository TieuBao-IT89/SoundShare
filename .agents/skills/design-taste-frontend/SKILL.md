---
name: design-taste-frontend
description: Apply intentional, distinctive visual direction when designing, reviewing, or improving SoundShare Flutter screens. Use for UI/UX work across Home, Explore, Player, Upload, Library, and Profile.
---

# Taste Skill for SoundShare

This project skill adapts the [Taste Skill](https://github.com/Leonxlnx/taste-skill) approach to SoundShare's Flutter mobile application. It keeps its emphasis on deliberate art direction, product-specific ideas, complete screen states, and visual review. The upstream browser scripts and website-only rules are not part of this Flutter adaptation.

## Read the project first

Before changing a screen, read `README.md`, `DESIGN.md`, and `PRD.md`. Inspect the relevant Flutter feature, shared theme, navigation, state, and assets. Identify:

- The user's goal on this screen and the next action they should take.
- What is distinctive to SoundShare: independent artists sharing music, discovery, listening continuity, and the current MVP's real capabilities.
- Which content and artwork actually exist. Do not invent real artists, tracks, metrics, or production integrations; label sample content as sample content.
- Existing brand constraints and working behavior that the visual change must preserve.

If the request leaves room for interpretation, state a reasonable design direction and proceed. Ask only when a missing product fact blocks the work.

## Art direction

Write a one-sentence concept for the screen that connects a real SoundShare characteristic to a visual device. Check that it could not be copied unchanged to any generic music player. Choose hierarchy, composition, type scale, imagery, and color deliberately around that concept.

Treat `DESIGN.md` as the current brand system: dark charcoal backgrounds, purple for primary actions and selected states, mint used sparingly, clear text contrast, album artwork as a focal point, and rounded reusable controls. The established purple palette is intentional brand color; do not remove or replace it to follow generic upstream website rules. If a screen needs a brand change, explain why and update `DESIGN.md` as part of the work.

Avoid defaulting to identical cards, decorative gradients, arbitrary badges, or icon-in-colored-square patterns. Use only components that improve hierarchy or help the user act. Do not add imagery or animation without a clear role.

## Design for mobile use

- Keep the existing Flutter, Riverpod, GoRouter, and feature organization. Do not migrate frameworks or add packages for visual polish alone.
- Preserve routes, playback state, upload validation, and existing interaction behavior.
- Compose for narrow phone widths first; allow content to scroll without clipping or horizontal overflow.
- Give important controls comfortable touch areas, accessible labels, visible focus/selected states, and text contrast that does not depend on color alone.
- Design loading, empty, error, and success states where the screen can encounter them.
- Respect reduced-motion preferences and keep transitions brief and functional.
- Use the project's actual artwork when available. Do not present placeholders as licensed or production-ready assets.

## Workflow

1. Inspect the current screen and its related code. Record the main UX problems and the behaviors that must survive.
2. Define the screen's user goal, product-specific concept, and content hierarchy before editing.
3. Make the smallest coherent design-system or screen changes needed to deliver that direction.
4. Review the result at representative phone sizes and check long text, empty/error states, touch targets, and the primary flow. Use an emulator or screenshots when available; do not claim a visual check that was not performed.
5. Fix the most visible layout and hierarchy problems, then summarize the design direction, files changed, checks performed, and any mock content or unverified states.

## Scope and limitations

This local skill applies Taste Skill principles to native Flutter UI. Upstream `draw.mjs`, `inspect.mjs`, `assets.mjs`, and web-page rules require a browser-based web project and are not installed here. Do not claim those tools ran against Flutter screens. For a separate web page in this repository, consult the upstream repository and follow its complete instructions for that page.
