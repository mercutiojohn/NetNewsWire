//
//  TranslationSettingsViewController.swift
//  NetNewsWire-iOS
//
//  Created by NetNewsWire on 12/30/24.
//  Copyright © 2024 Ranchero Software. All rights reserved.
//

import UIKit

final class TranslationSettingsViewController: UITableViewController {
	
	private enum Section: Int, CaseIterable {
		case targetLanguage
		case translationMode
	}
	
	private let commonLanguages = [
		(nil, "System Language"),
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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = NSLocalizedString("Translation", comment: "Translation settings title")
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sectionType = Section(rawValue: section) else { return 0 }
		
		switch sectionType {
		case .targetLanguage:
			return commonLanguages.count
		case .translationMode:
			return 2 // Bilingual and Translation Only
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let sectionType = Section(rawValue: section) else { return nil }
		
		switch sectionType {
		case .targetLanguage:
			return NSLocalizedString("Target Language", comment: "Target Language section header")
		case .translationMode:
			return NSLocalizedString("Translation Mode", comment: "Translation Mode section header")
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		guard let sectionType = Section(rawValue: section) else { return nil }
		
		switch sectionType {
		case .targetLanguage:
			return NSLocalizedString("Choose the language to translate articles into. System Language uses your device's display language.", comment: "Target language footer")
		case .translationMode:
			return NSLocalizedString("Bilingual mode shows both original and translated text. Translation Only mode shows only the translated text.", comment: "Translation mode footer")
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		guard let sectionType = Section(rawValue: indexPath.section) else { return cell }
		
		var content = cell.defaultContentConfiguration()
		
		switch sectionType {
		case .targetLanguage:
			let (languageCode, languageName) = commonLanguages[indexPath.row]
			content.text = languageName
			
			let currentLanguage = AppDefaults.shared.translationTargetLanguage
			if (languageCode == nil && currentLanguage == nil) ||
			   (languageCode == currentLanguage) {
				cell.accessoryType = .checkmark
			} else {
				cell.accessoryType = .none
			}
			
		case .translationMode:
			let currentMode = AppDefaults.shared.translationMode
			
			if indexPath.row == 0 {
				content.text = NSLocalizedString("Bilingual", comment: "Bilingual mode")
				content.secondaryText = NSLocalizedString("Show original and translation", comment: "Bilingual mode description")
				cell.accessoryType = currentMode == .bilingual ? .checkmark : .none
			} else {
				content.text = NSLocalizedString("Translation Only", comment: "Translation only mode")
				content.secondaryText = NSLocalizedString("Show only translated text", comment: "Translation only mode description")
				cell.accessoryType = currentMode == .translationOnly ? .checkmark : .none
			}
		}
		
		cell.contentConfiguration = content
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard let sectionType = Section(rawValue: indexPath.section) else { return }
		
		switch sectionType {
		case .targetLanguage:
			let (languageCode, _) = commonLanguages[indexPath.row]
			AppDefaults.shared.translationTargetLanguage = languageCode
			tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
			
		case .translationMode:
			let mode: TranslationMode = indexPath.row == 0 ? .bilingual : .translationOnly
			AppDefaults.shared.translationMode = mode
			tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
		}
	}
}
