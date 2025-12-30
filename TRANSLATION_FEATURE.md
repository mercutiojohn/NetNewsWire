# Translation Feature Implementation Guide

This document describes the translation feature added to NetNewsWire, which uses Apple's Translation Framework to provide feed-level translation of article content and titles.

## Overview

The translation feature allows users to:
- Enable translation on a per-feed basis
- Automatically translate article titles in the timeline
- Automatically translate article content when viewing articles
- Choose between bilingual mode (original + translation) and translation-only mode
- Configure target language (defaults to system display language)
- Cache translations to avoid repeated translation requests

## Architecture

### Core Components

#### 1. TranslationManager (`Shared/Translation/TranslationManager.swift`)
- Manages interaction with Apple Translation Framework
- Provides async translation methods for single and batch translations
- Handles translation session lifecycle
- Checks language availability

#### 2. TranslationCache (`Shared/Translation/TranslationCache.swift`)
- Provides persistent caching of translations
- Uses both in-memory (NSCache) and disk-based caching
- Caches translations by article ID, content type, and target language
- Supports cache clearing and size management

#### 3. AppDefaults Extensions
- **Mac**: `Mac/AppDefaults.swift`
- **iOS**: `iOS/AppDefaults.swift`
- Added settings:
  - `translationTargetLanguage`: Target language for translations (nil = system language)
  - `translationMode`: Bilingual or Translation-only mode

#### 4. FeedMetadata Extension (`Modules/Account/Sources/Account/FeedMetadata.swift`)
- Added `isTranslationEnabled` property to enable/disable translation per feed
- Persisted with feed metadata

### UI Components

#### Feed-Level Settings

**Mac Feed Inspector** (`Mac/Inspector/FeedInspectorViewController.swift`)
- Added `isTranslationEnabledCheckBox` checkbox
- Connected to Feed's `isTranslationEnabled` property

**iOS Feed Inspector** (`iOS/Inspector/FeedInspectorViewController.swift`)
- Added `translationEnabledSwitch` switch
- Connected to Feed's `isTranslationEnabled` property

#### App-Level Settings

**Mac Preferences** (`Mac/Preferences/Translation/TranslationPreferencesViewController.swift`)
- Language selection popup with common languages
- Translation mode radio buttons (Bilingual/Translation Only)

**iOS Settings** (`iOS/Settings/TranslationSettingsViewController.swift`)
- Language selection table view with common languages
- Translation mode selection (Bilingual/Translation Only)

### Translation Integration

#### Article Content Translation

**ArticleRenderer+Translation** (`Shared/Article Rendering/ArticleRenderer+Translation.swift`)
- Extends ArticleRenderer with translation support
- Provides `articleHTMLWithTranslation()` async method
- Implements paragraph-level HTML translation
- Supports both bilingual and translation-only modes
- Caches translated content

**Stylesheet Updates** (`Shared/Article Rendering/stylesheet.css`)
- Added CSS classes for translation styling:
  - `.translated-title`: Styled translated titles
  - `.translation`: Styled translation content blocks
- Supports both light and dark modes

#### Timeline Title Translation

**ArticleStringFormatter+Translation** (`Shared/Extensions/ArticleStringFormatter+Translation.swift`)
- Extends ArticleStringFormatter with translation support
- Provides async `translatedTitle()` method with caching
- Provides `formattedTitle()` method for displaying titles with translation

**Timeline Data Models**
- **Mac**: `Mac/MainWindow/Timeline/Cell/TimelineCellData.swift`
- **iOS**: `iOS/MainTimeline/Cells/MainTimelineCellData.swift`
- Added `withTranslation()` factory methods for creating cell data with translated titles

## Usage

### Enabling Translation for a Feed

1. Right-click on a feed and select "Get Info" (Mac) or tap on a feed and select "Get Info" (iOS)
2. Check/toggle the "Enable Translation" option
3. Translation will be applied according to the app-level settings

### Configuring Translation Settings

**macOS:**
1. Open Preferences (⌘,)
2. Navigate to Translation tab
3. Select target language (or keep System Language)
4. Choose translation mode (Bilingual or Translation Only)

**iOS:**
1. Open Settings
2. Navigate to Translation section
3. Select target language (or keep System Language)
4. Choose translation mode (Bilingual or Translation Only)

### Translation Modes

**Bilingual Mode:**
- Shows original text followed by translated text
- Article titles show both versions
- Article content shows original paragraphs with translations underneath
- Translation text is visually distinguished with styling

**Translation Only Mode:**
- Replaces original text with translation
- Only shows translated content
- Original text is not displayed

## Implementation Details

### Translation Flow

#### Article View Translation:
1. User opens an article from a feed with translation enabled
2. System checks if cached translation exists
3. If not cached, content is parsed into paragraphs
4. Each paragraph is sent to Apple Translation Framework
5. Translations are combined with original HTML
6. Result is cached for future use
7. Styled HTML is displayed to user

#### Timeline Title Translation:
1. Timeline loads articles for display
2. For feeds with translation enabled, titles are queued for translation
3. System checks cache for existing translations
4. Missing translations are fetched asynchronously
5. Translations are cached and displayed
6. UI updates when translations become available

### Caching Strategy

**In-Memory Cache:**
- Fast access for recently translated content
- Limited to 1000 items by NSCache
- Cleared when app terminates

**Disk Cache:**
- Persistent storage in app's Caches directory
- Organized by article ID, content type, and language
- Survives app restarts
- Can be cleared by user or system

**Cache Key Format:**
```
{articleID}_{contentType}_{targetLanguage}
```

Example: `article123_title_zh-Hans`

### Supported Languages

The UI provides quick access to common languages:
- English (en)
- Simplified Chinese (zh-Hans)
- Traditional Chinese (zh-Hant)
- Japanese (ja)
- Korean (ko)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Arabic (ar)
- Hindi (hi)
- Thai (th)
- Vietnamese (vi)

Additional languages supported by Apple Translation Framework can be used by setting the language code programmatically.

## Requirements

- **iOS 15.0+** or **macOS 12.0+** (for Translation Framework)
- Internet connection for first-time translation of each language pair
- Storage space for translation models and cached translations

## Integration Steps for Xcode

To complete the integration, the following steps need to be done in Xcode:

### 1. Add Files to Project
- Add all new Swift files to appropriate targets
- Ensure Translation folder files are included in both Mac and iOS targets where applicable

### 2. Update Interface Builder Files

**Mac Feed Inspector XIB:**
```xml
<!-- Add checkbox for translation -->
<button>
  <outlet property="isTranslationEnabledCheckBox" destination="FeedInspectorViewController"/>
  <action selector="isTranslationEnabledChanged:" target="FeedInspectorViewController"/>
</button>
```

**iOS Feed Inspector Storyboard:**
```xml
<!-- Add switch for translation -->
<switch>
  <outlet property="translationEnabledSwitch" destination="FeedInspectorViewController"/>
  <action selector="translationEnabledChanged:" target="FeedInspectorViewController"/>
</switch>
```

### 3. Create Preferences UI

**Mac:**
- Create Translation.xib for TranslationPreferencesViewController
- Add to PreferencesWindowController's tabs

**iOS:**
- Add TranslationSettingsViewController to Settings navigation
- Update Settings.storyboard or create programmatically

### 4. Update Article Rendering

Modify article detail view controllers to use the new translation-aware rendering:

```swift
// Instead of:
let rendering = ArticleRenderer.articleHTML(article: article, theme: theme)

// Use:
let rendering = await ArticleRenderer.articleHTMLWithTranslation(
    article: article, 
    theme: theme, 
    feed: feed
)
```

### 5. Update Timeline Loading

Modify timeline data loading to use translation-aware cell data:

```swift
// Instead of:
let cellData = TimelineCellData(article: article, ...)

// Use:
let cellData = await TimelineCellData.withTranslation(
    article: article, 
    ..., 
    feed: feed
)
```

## Testing Checklist

- [ ] Translation toggle appears in Feed Inspector (Mac & iOS)
- [ ] Translation settings appear in Preferences/Settings (Mac & iOS)
- [ ] Language selection works correctly
- [ ] Translation mode toggle works correctly
- [ ] Enabling translation on a feed translates titles in timeline
- [ ] Article content is translated when viewing
- [ ] Bilingual mode shows both original and translation
- [ ] Translation-only mode shows only translation
- [ ] Translations are cached and reused
- [ ] Cache persists across app restarts
- [ ] Translation works in both light and dark modes
- [ ] Translation styling is visually appealing
- [ ] Performance is acceptable with translation enabled
- [ ] No crashes or errors during translation

## Known Limitations

1. **First Translation Delay**: Initial translations may take longer as language models download
2. **Offline Functionality**: Requires internet for first-time language pair usage
3. **HTML Preservation**: Complex HTML structures may not preserve all formatting
4. **Translation Quality**: Depends on Apple Translation Framework quality
5. **Language Support**: Limited to languages supported by Apple Translation Framework

## Future Enhancements

Potential improvements for future versions:

1. **Manual Translation Trigger**: Allow users to manually trigger re-translation
2. **Translation History**: Show history of translated articles
3. **Custom Language Pairs**: Support custom source-target language pairs
4. **Selective Translation**: Allow users to translate only titles or only content
5. **Translation Indicators**: Visual indicators showing what content is translated
6. **Offline Models**: Pre-download translation models for offline use
7. **Translation Statistics**: Show cache size and translation count
8. **Batch Translation**: Translate multiple articles at once in background

## Troubleshooting

### Translation Not Working

1. Check if translation is enabled for the feed
2. Verify internet connection
3. Check if target language is set correctly
4. Clear translation cache and retry
5. Ensure device supports Apple Translation Framework

### Poor Translation Quality

1. Try different target language
2. Check if source content is clean (no excessive HTML)
3. Report specific issues to Apple via Feedback Assistant

### Performance Issues

1. Clear translation cache if too large
2. Disable translation for feeds with very long articles
3. Use translation-only mode instead of bilingual mode

## Support

For issues or questions about the translation feature:
1. Check this documentation
2. Review the inline code comments
3. Consult Apple's Translation Framework documentation
4. Create an issue in the NetNewsWire repository
