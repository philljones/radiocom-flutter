# Aber Radio image asset catalogue

Last audited: 27 September 2026

Use the IDs in this document when discussing, replacing, or reviewing an image. The ID identifies the visual role; platform-generated size variants share one ID because they must always be regenerated together from the same master artwork.

## General rules

- Keep master artwork outside the generated iOS and Android asset folders. Regenerate all platform sizes from the master rather than editing individual renditions.
- Use sRGB colour. Remove metadata that is not needed for display.
- Use PNG for logos, icons, line art, and transparency; JPEG or WebP for photographs. Flutter can display SVG only through an additional SVG package, which this app does not currently include.
- App icons must be square and must not include pre-rounded corners. iOS applies its own mask. The iOS App Store icon should be an opaque 1024 × 1024 PNG with no alpha channel or transparent pixels.
- Images displayed with `BoxFit.cover` will be cropped. Keep faces, text, logos, and other important content inside the central safe area noted below.
- Remote images must use HTTPS and should remain available at stable URLs. A changing image should use a versioned URL or appropriate cache headers so the app does not retain an older cached copy.

## Brand and fallback artwork

| ID | Current file | Current size | Preferred source | Use and restrictions |
|---|---|---:|---|---|
| **AR-IMG-001** | `assets/graphics/aber-radio-app-icon.png` | 1024 × 1024, PNG with alpha channel | 1024 × 1024 opaque PNG, plus an editable SVG master | Shown at 120 × 120 on the first onboarding screen and serves as the source design for platform icons. Keep the AR mark centred and readable at very small sizes. For App Store delivery, export an opaque version without an alpha channel. |
| **AR-IMG-002** | `assets/graphics/aber-radio-logo.png` | 1800 × 900, PNG with alpha | Prefer a **separate square station artwork** at 1200 × 1200 PNG/JPEG for playback; retain a wide 2:1 SVG/PNG wordmark for headers | Current fallback for station identity, live programme artwork, schedule cards, player artwork, lock screen and CarPlay media artwork when the API supplies no logo. It is a 2:1 image used in several square `cover` frames, so its sides may be cropped. Avoid small text near the edges. This is the highest-priority asset to split into square artwork and a wide wordmark. |
| **AR-IMG-003** | `assets/graphics/default_programme_cover.png` | 1080 × 1080, PNG, opaque | 1200 × 1200 PNG or high-quality JPEG/WebP | Fallback for programmes and podcasts without artwork. Used in square and portrait cards, episode details, the compact player, and sharing/player artwork. Keep all essential content within the centre 70% because portrait cards crop the sides. |
| **AR-IMG-004** | `assets/graphics/joinus.jpg` | 1424 × 949, JPEG | 1600 × 900 JPEG/WebP (16:9) | Photograph in the Join Us card on Home/Menu. Displayed full-width at 180–200 points high with `cover`, so it is cropped differently by screen width. Keep the subject in the central 70%; do not bake text into the photograph. |

## Category photographs

These are shown behind a colour overlay in two-column category tiles. The tile is approximately 2.2:1 and uses `BoxFit.cover`. A consistent **1320 × 600 JPEG or WebP** is ideal. Keep the recognisable subject in the central 60%, avoid embedded text, and allow for a strong coloured overlay and white category label.

| ID | Current file | Current size | Used for |
|---|---|---:|---|
| **AR-CAT-001** | `assets/graphics/categories/tv.jpeg` | 800 × 541 | Film & TV |
| **AR-CAT-002** | `assets/graphics/categories/news.jpeg` | 800 × 467 | News & politics |
| **AR-CAT-003** | `assets/graphics/categories/sports.jpeg` | 800 × 533 | Sport |
| **AR-CAT-004** | `assets/graphics/categories/society.jpeg` | 800 × 533 | Magazine/society |
| **AR-CAT-005** | `assets/graphics/categories/education.jpeg` | 800 × 600 | Education |
| **AR-CAT-006** | `assets/graphics/categories/comedy.jpeg` | 800 × 534 | Comedy |
| **AR-CAT-007** | `assets/graphics/categories/music.jpeg` | 800 × 533 | Music |
| **AR-CAT-008** | `assets/graphics/categories/science.jpeg` | 800 × 533 | Science |
| **AR-CAT-009** | `assets/graphics/categories/arts.jpeg` | 800 × 533 | Arts |
| **AR-CAT-010** | `assets/graphics/categories/goverment.jpeg` | 800 × 533 | Government & organisations. The existing filename misspells “government”; renaming it requires updating `pubspec.yaml` and `Program.getImages`. |
| **AR-CAT-011** | `assets/graphics/categories/health.jpeg` | 800 × 534 | Health |
| **AR-CAT-012** | `assets/graphics/categories/tech.jpeg` | 800 × 533 | Technology |

## iOS platform artwork

| ID | Physical files | Required sizes and format | Use and restrictions |
|---|---|---|---|
| **AR-IOS-001** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | PNG renditions at 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180 and 1024 pixels, as mapped in `Contents.json` | iPhone/iPad Home Screen, Settings, Spotlight and App Store icon. Regenerate the whole set from AR-IMG-001. The current files contain an alpha channel; remove alpha for distribution, especially from the 1024 × 1024 marketing icon. Do not add rounded corners. |
| **AR-IOS-002** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/Icon-76x76@1x.png`, `Icon-76x76@2x.png`, `Icon-83.5x83.5@2x.png` | Prefer 128, 256 and 384 pixel PNGs for the launch screen’s 128-point image view | Centred launch-screen mark on white. The current 76, 152 and 167 pixel files are scaled to the 128-point view and are therefore not an ideal set. Use a compact mark rather than a wide logo; transparency is allowed here. |

## Android platform artwork

| ID | Physical files | Required sizes and format | Use and restrictions |
|---|---|---|---|
| **AR-AND-001** | `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` | 48, 72, 96, 144 and 192 pixel PNGs | Legacy Android launcher icon. Generate from AR-IMG-001. Keep critical artwork inside the central safe area because launchers apply different masks. |
| **AR-AND-002** | `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png` | 108, 162, 216, 324 and 432 pixel transparent PNGs | Foreground layer of the adaptive launcher icon. The visible safe zone is roughly the central 66 × 66 units of the 108-unit base canvas. The background colour currently comes from Android XML and is black. |
| **AR-AND-003** | `android/app/src/main/res/drawable/ic_launcher.png` | Currently 72 × 72 transparent PNG; this duplicate drawable is not referenced by the manifest | Legacy leftover. The active app icon comes from the `mipmap` sets above. It can be removed after confirming no external Android flavour uses it. |
| **AR-AND-004** | `android/app/src/main/res/drawable/splash.png` | Current 255 × 255 transparent PNG; ideally provide a compact transparent PNG around 384 × 384 | Centred Android launch-screen mark on the configured solid background. Do not include a full-screen background in the image. Keep the mark compact so it works on varied aspect ratios. |
| **AR-AND-005** | `android/app/src/main/res/drawable/ic_notification.png` | Current 72 × 72 transparent PNG; Android notification artwork should be a white-only silhouette on transparency, commonly designed on a 24 dp canvas with density variants | Push/local notification small icon. Colours are ignored or tinted by Android. Avoid a full-colour app icon, gradients, text, and fine detail. Density-specific versions would be preferable to this single drawable. |

## Remote and API-supplied artwork

These images are used by the app but are not files in this repository, so their exact dimensions can change independently.

| ID | Current source | Preferred dimensions/format | Use and restrictions |
|---|---|---|---|
| **AR-REMOTE-001** | `https://aberradio.com/fb_cover_photo.png` | Current design is a wide banner. Keep a web version at least 1600 px wide; also provide a separate 1200 × 1200 playback image | Station photo and fallback for news/live player artwork. A wide banner is suitable for station headers but gets cropped in square lock-screen and CarPlay artwork. A dedicated square endpoint is strongly recommended. |
| **AR-REMOTE-002** | `icon_url`, `big_icon_url`, and live `logo_url` from the station API | Square 1200 × 1200 JPEG/PNG/WebP | Station and current-programme artwork throughout the app and system media controls. HTTPS is required in practice. Keep the subject centred and avoid text near the edges. |
| **AR-REMOTE-003** | Programme `photo_url`/logo URLs from the API and RSS feeds | Square 1200 × 1200 preferred; at least 600 × 600 | Podcast grids, favourites, schedules, details, playlist and player artwork. The UI uses both square and 2:3 portrait crops, so use central-safe compositions. |
| **AR-REMOTE-004** | News/RSS story images | 1200 × 675 JPEG/WebP (16:9), minimum about 800 px wide | News list thumbnails and the single hero image on story details. The list crops to 108 × 80 and the detail page uses a wide hero crop. Ensure Aber Radio has permission to reproduce and cache the image, and keep source/copyright attribution with the story. |
| **AR-REMOTE-005** | Outstanding/Join card images supplied by WordPress/API | 1600 × 900 JPEG/WebP | Full-width promotional cards at 200 points high using `cover`. Keep important content central and avoid text baked into the image. |

## Bundled but currently unused

These files are declared in `pubspec.yaml`, so they increase the app bundle, but no production code references them.

| ID | File | Size | Status |
|---|---|---:|---|
| **AR-UNUSED-001** | `assets/graphics/icon_info.png` | 200 × 200 PNG with alpha | Bundled, no production reference found. |
| **AR-UNUSED-002** | `assets/graphics/play_podcast.png` | 72 × 72 PNG with alpha | Bundled, no production reference found. |
| **AR-UNUSED-003** | `assets/graphics/empty-logo.png` | 410 × 428 PNG with alpha | Bundled, no production reference found. |

## Present in the repository but not bundled or used

These legacy files are not listed in `pubspec.yaml` and have no production references. Flutter cannot load them as assets in the current build.

| ID | File | Size | Status |
|---|---|---:|---|
| **AR-LEGACY-001** | `assets/graphics/aber-radio-app-icon.svg` | 1024 × 1024 viewBox | Useful editable master for AR-IMG-001, but not included in the app and not directly renderable by the current Flutter dependencies. |
| **AR-LEGACY-002** | `assets/graphics/cuac-icon-app.png` | 192 × 192 PNG | Old CUAC artwork; unused. |
| **AR-LEGACY-003** | `assets/graphics/cuac-logo-v2.png` | 600 × 102 PNG | Old CUAC artwork; unused. |
| **AR-LEGACY-004** | `assets/graphics/cuac-logo.png` | 600 × 102 PNG | Old CUAC artwork; production-unused, though old test fixtures still mention its path. |
| **AR-LEGACY-005** | `assets/graphics/cuac-utilidade-publica.png` | 786 × 788 PNG | Old CUAC artwork; unused. |
| **AR-LEGACY-006** | `assets/graphics/cuac_music_cover.png` | 1080 × 1080 PNG | Old CUAC artwork; unused. |
| **AR-LEGACY-007** | `assets/graphics/watch.png` | 410 × 428 PNG | Old artwork; unused. |

## Recommended cleanup and next assets

1. Create a dedicated square **station playback artwork** for AR-IMG-002/AR-REMOTE-002 and keep the current wide Aber Radio wordmark as a separate header asset.
2. Re-export AR-IMG-001 without alpha and regenerate the entire iOS/Android icon sets.
3. Replace the undersized iOS launch images in AR-IOS-002 with 128/256/384 pixel renditions.
4. Standardise AR-CAT-001 through AR-CAT-012 to one 2.2:1 size so cropping is predictable.
5. Remove AR-UNUSED-001 through AR-UNUSED-003 from `pubspec.yaml` after a final visual check, then delete the obsolete CUAC assets when historical reference is no longer needed.
