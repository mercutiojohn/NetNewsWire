//
//  ArticleRenderer+Translation.swift
//  NetNewsWire
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import Foundation
import Articles
import Account

@MainActor extension ArticleRenderer {
	
	/// Renders article with translation support
	/// - Parameters:
	///   - article: The article to render
	///   - extractedArticle: Optional extracted article content
	///   - theme: The article theme to use
	///   - feed: The feed this article belongs to (for checking translation settings)
	/// - Returns: Article rendering with translation if enabled
	static func articleHTMLWithTranslation(article: Article, extractedArticle: ExtractedArticle? = nil, theme: ArticleTheme, feed: Feed?) async -> Rendering {
		
		// Check if translation is enabled for this feed
		guard let feed = feed, feed.isTranslationEnabled == true else {
			// Translation not enabled, return normal rendering
			return articleHTML(article: article, extractedArticle: extractedArticle, theme: theme)
		}
		
		// Get target language (use system language if not set)
		let targetLanguage = AppDefaults.shared.translationTargetLanguage ?? Locale.current.language.languageCode?.identifier ?? "en"
		
		// Get translation mode
		let translationMode = AppDefaults.shared.translationMode
		
		// Translate title if available
		var translatedTitle: String?
		if let title = article.title, !title.isEmpty {
			translatedTitle = await getTranslatedTitle(article: article, title: title, targetLanguage: targetLanguage)
		}
		
		// Get article body
		let originalBody = extractedArticle?.content ?? article.body ?? ""
		
		// Translate body content
		let translatedBody = await translateArticleBody(article: article, body: originalBody, targetLanguage: targetLanguage, mode: translationMode)
		
		// Create modified article renderer with translated content
		var rendering = articleHTML(article: article, extractedArticle: extractedArticle, theme: theme)
		
		// Replace title with translated version if available
		if let translated = translatedTitle {
			let displayTitle: String
			if translationMode == .bilingual {
				displayTitle = "\(article.sanitizedTitle() ?? "")<br><em class=\"translated-title\">\(translated)</em>"
			} else {
				displayTitle = translated
			}
			rendering.html = rendering.html.replacingOccurrences(of: article.sanitizedTitle() ?? "", with: displayTitle)
		}
		
		// Replace body with translated version
		rendering.html = rendering.html.replacingOccurrences(of: originalBody, with: translatedBody)
		
		return rendering
	}
	
	/// Get translated title with caching
	private static func getTranslatedTitle(article: Article, title: String, targetLanguage: String) async -> String? {
		// Check cache first
		if let cached = TranslationCache.shared.getTranslation(articleID: article.articleID, contentType: "title", targetLanguage: targetLanguage) {
			return cached
		}
		
		// Translate
		if let translated = await TranslationManager.shared.translate(title, to: targetLanguage) {
			// Cache the result
			TranslationCache.shared.setTranslation(translated, articleID: article.articleID, contentType: "title", targetLanguage: targetLanguage)
			return translated
		}
		
		return nil
	}
	
	/// Translate article body content with paragraph-level translation
	private static func translateArticleBody(article: Article, body: String, targetLanguage: String, mode: TranslationMode) async -> String {
		// Check cache first
		if let cached = TranslationCache.shared.getTranslation(articleID: article.articleID, contentType: "body", targetLanguage: targetLanguage) {
			return cached
		}
		
		// Parse HTML to extract text paragraphs
		let paragraphs = extractParagraphs(from: body)
		
		guard !paragraphs.isEmpty else {
			return body
		}
		
		// Translate each paragraph
		var translatedBody = body
		
		for paragraph in paragraphs {
			// Skip empty or very short paragraphs
			guard paragraph.text.trimmingCharacters(in: .whitespacesAndNewlines).count > 3 else {
				continue
			}
			
			// Translate the paragraph
			if let translation = await TranslationManager.shared.translate(paragraph.text, to: targetLanguage) {
				// Replace in the body based on mode
				let replacement: String
				if mode == .bilingual {
					// Bilingual: show original + translation
					replacement = "\(paragraph.html)<div class=\"translation\">\(translation)</div>"
				} else {
					// Translation only: replace original with translation
					replacement = paragraph.html.replacingOccurrences(of: paragraph.text, with: translation)
				}
				
				translatedBody = translatedBody.replacingOccurrences(of: paragraph.html, with: replacement)
			}
		}
		
		// Cache the translated body
		TranslationCache.shared.setTranslation(translatedBody, articleID: article.articleID, contentType: "body", targetLanguage: targetLanguage)
		
		return translatedBody
	}
	
	/// Extract text paragraphs from HTML content
	private static func extractParagraphs(from html: String) -> [(text: String, html: String)] {
		var paragraphs: [(text: String, html: String)] = []
		
		// Simple regex-based extraction of paragraph-like elements
		let patterns = [
			"<p[^>]*>(.*?)</p>",
			"<div[^>]*>(.*?)</div>",
			"<li[^>]*>(.*?)</li>",
			"<h[1-6][^>]*>(.*?)</h[1-6]>"
		]
		
		for pattern in patterns {
			if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
				let range = NSRange(html.startIndex..., in: html)
				let matches = regex.matches(in: html, range: range)
				
				for match in matches {
					if let matchRange = Range(match.range, in: html),
					   let textRange = Range(match.range(at: 1), in: html) {
						let fullHTML = String(html[matchRange])
						let text = String(html[textRange])
						
						// Remove inner HTML tags from text
						let cleanText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
						
						if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
							paragraphs.append((text: cleanText, html: fullHTML))
						}
					}
				}
			}
		}
		
		return paragraphs
	}
}
