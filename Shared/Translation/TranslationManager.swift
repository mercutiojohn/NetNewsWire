//
//  TranslationManager.swift
//  NetNewsWire
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import Foundation
import Translation
import os.log

/// Manages translation of article content and titles using Apple Translation Framework
@MainActor final class TranslationManager {
	
	static let shared = TranslationManager()
	
	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TranslationManager")
	private var translationSession: TranslationSession?
	
	private init() {}
	
	/// Translate a single text string
	/// - Parameters:
	///   - text: The text to translate
	///   - targetLanguage: The target language code (e.g., "zh-Hans", "en")
	/// - Returns: Translated text or nil if translation fails
	func translate(_ text: String, to targetLanguage: String) async -> String? {
		guard !text.isEmpty else { return nil }
		
		do {
			let configuration = TranslationSession.Configuration(
				source: nil, // Auto-detect source language
				target: Locale.Language(identifier: targetLanguage)
			)
			
			if translationSession == nil {
				translationSession = TranslationSession(configuration: configuration)
			}
			
			let response = try await translationSession?.translate(text)
			return response?.targetText
		} catch {
			logger.error("Translation failed: \(error.localizedDescription)")
			return nil
		}
	}
	
	/// Translate multiple text strings in batch
	/// - Parameters:
	///   - texts: Array of texts to translate
	///   - targetLanguage: The target language code
	/// - Returns: Array of translated texts (nil for failed translations)
	func translateBatch(_ texts: [String], to targetLanguage: String) async -> [String?] {
		await withTaskGroup(of: (Int, String?).self) { group in
			for (index, text) in texts.enumerated() {
				group.addTask {
					let translated = await self.translate(text, to: targetLanguage)
					return (index, translated)
				}
			}
			
			var results: [String?] = Array(repeating: nil, count: texts.count)
			for await (index, translation) in group {
				results[index] = translation
			}
			return results
		}
	}
	
	/// Check if translation is available for a language
	/// - Parameter languageCode: The language code to check
	/// - Returns: True if translation is available
	func isTranslationAvailable(for languageCode: String) async -> Bool {
		let availability = await LanguageAvailability()
		let targetLanguage = Locale.Language(identifier: languageCode)
		let status = await availability.status(for: targetLanguage)
		return status == .installed || status == .supported
	}
	
	/// Invalidate the current translation session
	func invalidateSession() {
		translationSession?.invalidate()
		translationSession = nil
	}
}
