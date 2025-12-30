//
//  TranslationCache.swift
//  NetNewsWire
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import Foundation
import os.log

/// Persistent cache for translated content to avoid re-translating
final class TranslationCache: @unchecked Sendable {
	
	static let shared = TranslationCache()
	
	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TranslationCache")
	private let fileManager = FileManager.default
	private let cacheDirectory: URL
	private let cache: NSCache<NSString, NSString>
	private let diskQueue = DispatchQueue(label: "com.netnewswire.translationcache", qos: .utility)
	
	private init() {
		// Setup in-memory cache
		cache = NSCache<NSString, NSString>()
		cache.countLimit = 1000 // Limit number of cached items in memory
		
		// Setup disk cache directory
		let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = cachesDirectory.appendingPathComponent("TranslationCache", isDirectory: true)
		
		// Create cache directory if it doesn't exist
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}
	
	/// Generate a cache key for an article/text translation
	/// - Parameters:
	///   - articleID: The article identifier
	///   - contentType: The type of content (e.g., "title", "content")
	///   - targetLanguage: The target language code
	/// - Returns: A unique cache key
	private func cacheKey(articleID: String, contentType: String, targetLanguage: String) -> String {
		return "\(articleID)_\(contentType)_\(targetLanguage)"
	}
	
	/// Get translated text from cache
	/// - Parameters:
	///   - articleID: The article identifier
	///   - contentType: The type of content (e.g., "title", "content")
	///   - targetLanguage: The target language code
	/// - Returns: Cached translated text or nil if not found
	func getTranslation(articleID: String, contentType: String, targetLanguage: String) -> String? {
		let key = cacheKey(articleID: articleID, contentType: contentType, targetLanguage: targetLanguage)
		
		// Check in-memory cache first
		if let cachedValue = cache.object(forKey: key as NSString) {
			return cachedValue as String
		}
		
		// Check disk cache
		let fileURL = cacheDirectory.appendingPathComponent(key)
		if fileManager.fileExists(atPath: fileURL.path) {
			do {
				let data = try Data(contentsOf: fileURL)
				if let translation = String(data: data, encoding: .utf8) {
					// Store in memory cache for faster access
					cache.setObject(translation as NSString, forKey: key as NSString)
					return translation
				}
			} catch {
				logger.error("Failed to read translation from disk cache: \(error.localizedDescription)")
			}
		}
		
		return nil
	}
	
	/// Save translated text to cache
	/// - Parameters:
	///   - translation: The translated text
	///   - articleID: The article identifier
	///   - contentType: The type of content (e.g., "title", "content")
	///   - targetLanguage: The target language code
	func setTranslation(_ translation: String, articleID: String, contentType: String, targetLanguage: String) {
		let key = cacheKey(articleID: articleID, contentType: contentType, targetLanguage: targetLanguage)
		
		// Store in memory cache
		cache.setObject(translation as NSString, forKey: key as NSString)
		
		// Store in disk cache asynchronously
		diskQueue.async { [weak self] in
			guard let self = self else { return }
			let fileURL = self.cacheDirectory.appendingPathComponent(key)
			do {
				let data = translation.data(using: .utf8)
				try data?.write(to: fileURL)
			} catch {
				self.logger.error("Failed to write translation to disk cache: \(error.localizedDescription)")
			}
		}
	}
	
	/// Clear all translations from cache
	func clearCache() {
		cache.removeAllObjects()
		
		diskQueue.async { [weak self] in
			guard let self = self else { return }
			do {
				let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
				for file in files {
					try self.fileManager.removeItem(at: file)
				}
			} catch {
				self.logger.error("Failed to clear disk cache: \(error.localizedDescription)")
			}
		}
	}
	
	/// Clear translations for a specific article
	/// - Parameter articleID: The article identifier
	func clearTranslations(forArticle articleID: String) {
		// Clear from memory cache (iterate through all possible keys)
		// Note: NSCache doesn't provide enumeration, so we can only clear disk cache efficiently
		
		// Clear from disk cache
		diskQueue.async { [weak self] in
			guard let self = self else { return }
			do {
				let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
				for file in files {
					if file.lastPathComponent.hasPrefix(articleID) {
						try self.fileManager.removeItem(at: file)
					}
				}
			} catch {
				self.logger.error("Failed to clear translations for article: \(error.localizedDescription)")
			}
		}
	}
	
	/// Get cache size in bytes
	/// - Returns: Size of disk cache in bytes
	func getCacheSize() -> Int64 {
		var size: Int64 = 0
		do {
			let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
			for file in files {
				let attributes = try fileManager.attributesOfItem(atPath: file.path)
				size += attributes[.size] as? Int64 ?? 0
			}
		} catch {
			logger.error("Failed to calculate cache size: \(error.localizedDescription)")
		}
		return size
	}
}
