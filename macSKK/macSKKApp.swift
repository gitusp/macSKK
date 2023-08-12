// SPDX-FileCopyrightText: 2022 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Combine
import InputMethodKit
import SwiftUI
import os

let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")
var dictionary: UserDict!

func isTest() -> Bool {
    return ProcessInfo.processInfo.environment["MACSKK_IS_TEST"] == "1"
}

@main
struct macSKKApp: App {
    private var server: IMKServer!
    private var panel: CandidatesPanel! = CandidatesPanel()
    @StateObject var settingsViewModel = SettingsViewModel()
    private var cancellables: Set<AnyCancellable> = []
    /// SKK辞書を配置するディレクトリ
    /// "~/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Dictionaries"
    private let dictionariesDirectoryUrl: URL

    init() {
        do {
            dictionariesDirectoryUrl = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("Dictionaries")
        } catch {
            fatalError("辞書を配置するディレクトリを探せませんでした")
        }
        setupUserDefaults()
        if isTest() {
            do {
                dictionary = try UserDict(dicts: [])
            } catch {
                logger.error("Error while loading userDictionary")
            }
        } else {
            do {
                try setupDictionaries()
                if Bundle.main.bundleURL.deletingLastPathComponent().lastPathComponent == "Input Methods" {
                    guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
                    else {
                        fatalError("InputMethodConnectionName is not set")
                    }
                    server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
                }
            } catch {
                logger.error("辞書の読み込みに失敗しました")
            }
        }
        // 設定が変更されたfileDictだけを見る
        // settingsViewModel.$fileDicts
        //     .zip(settingsViewModel.$fileDicts.dropFirst())
        //     .sink { (prev, curr) in
        //
        //     }
        //     .store(in: &cancellables)
        settingsViewModel.$fileDicts
            .sink { dictSettings in
                // 差分があれば更新する
                dictSettings.forEach { dictSetting in
                    if let dict = dictionary.fileDict(id: dictSetting.id) {
                        if !dictSetting.enabled {
                            // dictをdictionaryから削除する
                        } else if dictSetting.encoding != dict.encoding {
                            // encodingを変えて読み込み直す
                        }
                    } else {
                        // dictSettingsの設定でFileDictを読み込んでdictionaryに追加
                    }
                }
                // dictSettingsをUserDefaultsに永続化する
            }
            .store(in: &cancellables)
    }

    var body: some Scene {
        Settings {
            SettingsView(settingsViewModel: settingsViewModel)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Save User Directory") {
                    do {
                        try dictionary.save()
                    } catch {
                        print(error)
                    }
                }.keyboardShortcut("S")
                #if DEBUG
                Button("Show CandidatesPanel") {
                    let words = [Word("こんにちは", annotation: "辞書の注釈"), Word("こんばんは"), Word("おはようございます")]
                    panel.setCandidates(CurrentCandidates(words: words, currentPage: 0, totalPageCount: 1), selected: words.first)
                    panel.show(cursorPosition: NSRect(origin: NSPoint(x: 100, y: 20), size: CGSize(width: 0, height: 30)))
                }
                Button("Add Word") {
                    let words = [Word("こんにちは", annotation: "辞書の注釈"), Word("こんばんは"), Word("おはようございます"), Word("追加したよ", annotation: "辞書の注釈")]
                    panel.setCandidates(CurrentCandidates(words: words, currentPage: 0, totalPageCount: 1), selected: words.last)
                    panel.viewModel.systemAnnotations = [words.last!: String(repeating: "これはシステム辞書の注釈です。", count: 5)]
                }
                #endif
            }
        }
    }

    private func setupUserDefaults() {
        UserDefaults.standard.register(defaults: [
            "dictionaries": [
                FileDictSetting(filename: "SKK-JISYO.L", encoding: .japaneseEUC, enabled: true)
            ],
        ])
    }

    // Dictionariesフォルダのファイルのうち、UserDefaultsで有効になっているものだけ読み込む
    private func setupDictionaries() throws {
        let fileDictSettings = UserDefaults.standard.array(forKey: "dictionaries")?.compactMap { obj in
            if let setting = obj as? [String: Any] {
                return FileDictSetting(setting)
            } else {
                return nil
            }
        }
        guard var fileDictSettings else {
            logger.error("環境設定の辞書設定が壊れています")
            return
        }

        // 辞書ディレクトリ直下にあるファイル一覧(シンボリックリンク、サブディレクトリは探索しない)
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .nameKey]
        let enumerator = FileManager.default.enumerator(at: dictionariesDirectoryUrl,
                                                        includingPropertiesForKeys: Array(resourceKeys),
                                                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        guard let enumerator else {
            logger.error("辞書フォルダのファイル一覧が取得できません")
            return
        }
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let isDirectory = resourceValues.isDirectory,
                let filename = resourceValues.name
                else {
                    continue
                }
            if isDirectory || filename == UserDict.userDictFilename {
                continue
            }
            if let setting = fileDictSettings.first(where: { $0.filename == filename }) {
                let dict: FileDict
                do {
                    dict = try FileDict(contentsOf: fileURL, encoding: setting.encoding)
                } catch {
                    // TODO: NotificationCenter経由でユーザーにエラー理由を通知する
                    logger.error("SKK辞書 \(setting.filename) の読み込みに失敗しました: \(error)")
                    return
                }
                do {
                    dictionary = try UserDict(dicts: [dict])
                    logger.log("\(setting.filename)から \(dict.entries.count) エントリ読み込みました")
                } catch {
                    // TODO: NotificationCenter経由でユーザーにエラー理由を通知する
                    logger.error("SKK辞書 \(setting.filename) の読み込みに失敗しました: \(error)")
                }
            } else {
                // FIXME: 起動時にだけSKK辞書ファイルを検査するんじゃなくてディレクトリを監視自体を監視しておいたほうがよさそう
                // UserDefaultsの辞書設定に存在しないファイルが見つかったのでデフォルトEUC-JPにしておく
                fileDictSettings.append(FileDictSetting(filename: filename, encoding: .japaneseEUC, enabled: false))
            }
        }
        settingsViewModel.fileDicts = fileDictSettings.map {
            DictSetting(filename: $0.filename, enabled: $0.enabled, encoding: $0.encoding)
        }
    }
}
