//
//  ArticleStringFormatter+Translation.swift
//  NetNewsWire
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import Foundation
import Articles
import Account

@MainActor extension ArticleStringFormatter {
	
	private static var translatedTitleCache = [String: String]()
	
	/// Get translated title for an article (with caching)
	/// - Parameters:
	///   - article: The article to get the translated title for
	///   - feed: The feed this article belongs to
	/// - Returns: Translated title if translation is enabled and available, otherwise nil
	static func translatedTitle(_ article: Article, feed: Feed?) async -> String? {
		// Check if translation is enabled for this feed
		guard let feed = feed, feed.isTranslationEnabled == true else {
			return nil
		}
		
		// Get target language
		let targetLanguage = AppDefaults.shared.translationTargetLanguage ?? Locale.current.language.languageCode?.identifier ?? "en"
		
		// Create cache key
		let cacheKey = "\(article.articleID)_\(targetLanguage)"
		
		// Check in-memory cache first
		if let cached = translatedTitleCache[cacheKey] {
			return cached
		}
		
		// Check persistent cache
		if let cached = TranslationCache.shared.getTranslation(articleID: article.articleID, contentType: "title", targetLanguage: targetLanguage) {
			translatedTitleCache[cacheKey] = cached
			return cached
		}
		
		// Get original title
		guard let title = article.title, !title.isEmpty else {
			return nil
		}
		
		// Translate
		if let translated = await TranslationManager.shared.translate(title, to: targetLanguage) {
			// Cache the result
			translatedTitleCache[cacheKey] = translated
			TranslationCache.shared.setTranslation(translated, articleID: article.articleID, contentType: "title", targetLanguage: targetLanguage)
			return translated
		}
		
		return nil
	}
	
	/// Get formatted title for display in timeline (with optional translation)
	/// - Parameters:
	///   - article: The article to get the title for
	///   - feed: The feed this article belongs to
	///   - translationMode: The translation display mode
	/// - Returns: Formatted title (original, translated, or bilingual)
	static func formattedTitle(_ article: Article, feed: Feed?, translationMode: TranslationMode) async -> String {
		let originalTitle = truncatedTitle(article)
		
		// Get translated title if available
		if let translated = await translatedTitle(article, feed: feed) {
			switch translationMode {
			case .bilingual:
				// Show both original and translation
				return "\(originalTitle)\n\(translated)"
			case .translationOnly:
				// Show only translation
				return translated
			}
		}
		
		// No translation available or translation not enabled
		return originalTitle
	}
	
	/// Clear translation caches
	static func emptyTranslationCaches() {
		translatedTitleCache = [String: String]()
	}
}
