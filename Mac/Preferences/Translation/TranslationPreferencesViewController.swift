//
//  TranslationPreferencesViewController.swift
//  NetNewsWire
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import AppKit

final class TranslationPreferencesViewController: NSViewController {
	
	@IBOutlet weak var targetLanguagePopup: NSPopUpButton?
	@IBOutlet weak var translationModeMatrix: NSMatrix?
	
	private var availableLanguages: [Locale.Language] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupLanguagePopup()
		updateUI()
	}
	
	private func setupLanguagePopup() {
		guard let popup = targetLanguagePopup else { return }
		
		popup.removeAllItems()
		
		// Add system language option
		let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
		popup.addItem(withTitle: "System Language (\(systemLanguage))")
		popup.lastItem?.representedObject = nil // nil represents system default
		
		popup.menu?.addItem(NSMenuItem.separator())
		
		// Add common languages
		let commonLanguages = [
			("en", "English"),
			("zh-Hans", "Simplified Chinese"),
			("zh-Hant", "Traditional Chinese"),
			("ja", "Japanese"),
			("ko", "Korean"),
			("es", "Spanish"),
			("fr", "French"),
			("de", "German"),
			("it", "Italian"),
			("pt", "Portuguese"),
			("ru", "Russian"),
			("ar", "Arabic"),
			("hi", "Hindi"),
			("th", "Thai"),
			("vi", "Vietnamese")
		]
		
		for (code, name) in commonLanguages {
			popup.addItem(withTitle: name)
			popup.lastItem?.representedObject = code
		}
	}
	
	private func updateUI() {
		// Update target language selection
		if let targetLanguage = AppDefaults.shared.translationTargetLanguage {
			targetLanguagePopup?.selectItem(withRepresentedObject: targetLanguage)
		} else {
			targetLanguagePopup?.selectItem(at: 0) // Select system language
		}
		
		// Update translation mode
		let mode = AppDefaults.shared.translationMode
		translationModeMatrix?.selectCell(atRow: mode.rawValue, column: 0)
	}
	
	@IBAction func targetLanguageDidChange(_ sender: NSPopUpButton) {
		if let languageCode = sender.selectedItem?.representedObject as? String {
			AppDefaults.shared.translationTargetLanguage = languageCode
		} else {
			// System language selected
			AppDefaults.shared.translationTargetLanguage = nil
		}
	}
	
	@IBAction func translationModeDidChange(_ sender: NSMatrix) {
		let selectedRow = sender.selectedRow
		if let mode = TranslationMode(rawValue: selectedRow) {
			AppDefaults.shared.translationMode = mode
		}
	}
}
