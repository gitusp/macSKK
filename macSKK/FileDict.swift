// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

// 辞書ディレクトリに新規ファイルが作成されたときに通知する通知の名前。objectはURL
let notificationNameDictFileDidAppear = Notification.Name("dictFileDidAppear")
// 辞書ディレクトリからファイルが移動されたときに通知する通知の名前。objectは移動前のURL
let notificationNameDictFileDidMove = Notification.Name("dictFileDidMove")

/// 実ファイルをもつSKK辞書
class FileDict: NSObject, DictProtocol, Identifiable {
    // FIXME: URLResourceのfileResourceIdentifierKeyをidとして使ってもいいかもしれない。
    // FIXME: ただしこの値は再起動したら同一性が保証されなくなるのでIDとしての永続化はできない
    // FIXME: iCloud Documentsとかでてくるとディレクトリが複数になるけど、ひとまずファイル名だけもっておけばよさそう。
    let id: String
    let fileURL: URL
    let encoding: String.Encoding
    var version: NSFileVersion?
    private(set) var dict: MemoryDict

    /// シリアライズ時に先頭に付ける
    static let headers = [";; -*- mode: fundamental; coding: utf-8 -*-"]

    // MARK: NSFilePresenter
    var presentedItemURL: URL? { fileURL }
    let presentedItemOperationQueue: OperationQueue = OperationQueue()

    init(contentsOf fileURL: URL, encoding: String.Encoding) throws {
        // iCloud Documents使うときには辞書フォルダが複数になりうるけど、それまではひとまずファイル名をIDとして使う
        self.id = fileURL.lastPathComponent
        self.fileURL = fileURL
        self.encoding = encoding
        self.dict = MemoryDict(entries: [:])
        self.version = NSFileVersion.currentVersionOfItem(at: fileURL)
        super.init()
        try load(fileURL)
        NSFileCoordinator.addFilePresenter(self)
    }

    func load(_ url: URL) throws {
        var coordinationError: NSError?
        var readingError: NSError?
        let fileCoordinator = NSFileCoordinator(filePresenter: self)
        fileCoordinator.coordinate(readingItemAt: fileURL, error: &coordinationError) { [weak self] newURL in
            if let self {
                do {
                    let source = try String(contentsOf: url, encoding: self.encoding)
                    let memoryDict = try MemoryDict(dictId: self.id, source: source)
                    self.dict = memoryDict
                    self.version = NSFileVersion.currentVersionOfItem(at: url)
                    logger.log("辞書 \(self.id, privacy: .public) から \(self.dict.entries.count) エントリ読み込みました")
                } catch {
                    logger.error("辞書 \(self.id, privacy: .public) の読み込みでエラーが発生しました: \(error)")
                    readingError = error as NSError
                }
            }
        }
        if let error = coordinationError ?? readingError {
            throw error
        }
    }

    func save() throws {
        guard let data = serialize().data(using: encoding) else {
            fatalError("辞書 \(self.id) のシリアライズに失敗しました")
        }
        var coordinationError: NSError?
        var writingError: NSError?
        let fileCoordinator = NSFileCoordinator(filePresenter: self)
        fileCoordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { [weak self] newURL in
            if let self {
                do {
                    self.version = try NSFileVersion.addOfItem(at: newURL, withContentsOf: newURL)
                    logger.log("辞書のバージョンを作成しました")
                } catch {
                    logger.error("辞書のバージョン作成でエラーが発生しました: \(error)")
                    writingError = error as NSError
                    return
                }
                do {
                    try data.write(to: newURL)
                } catch {
                    logger.error("辞書 \(self.id, privacy: .public) の書き込みに失敗しました: \(error)")
                    writingError = error as NSError
                }
            }
        }
        if let error = coordinationError ?? writingError {
            throw error
        }
    }

    deinit {
        logger.log("辞書 \(self.id, privacy: .public) がプロセスから削除されます")
        NSFileCoordinator.removeFilePresenter(self)
    }

    /// ユーザー辞書をSKK辞書形式に変換する
    func serialize() -> String {
        // FIXME: 送り仮名あり・なしでエントリを分けるようにする?
        return (Self.headers + dict.entries.map { entry in
            return "\(entry.key) /\(serializeWords(entry.value))/"
        }).joined(separator: "\n")
    }

    var entryCount: Int { return dict.entries.count }

    private func serializeWords(_ words: [Word]) -> String {
        return words.map { word in
            if let annotation = word.annotation {
                return word.word + ";" + annotation.text
            } else {
                return word.word
            }
        }.joined(separator: "/")
    }

    // MARK: DictProtocol
    func refer(_ yomi: String) -> [Word] {
        return dict.refer(yomi)
    }

    func add(yomi: String, word: Word) {
        dict.add(yomi: yomi, word: word)
    }

    func delete(yomi: String, word: Word.Word) -> Bool {
        return dict.delete(yomi: yomi, word: word)
    }

    // ユニットテスト用
    func setEntries(_ entries: [String: [Word]]) {
        self.dict = MemoryDict(entries: entries)
    }
}

extension FileDict: NSFilePresenter {
    // 他プログラムでの書き込みなどでは呼ばれないみたい
    func presentedItemDidGain(_ version: NSFileVersion) {
        if version == self.version {
            logger.log("辞書 \(self.id, privacy: .public) のバージョンが自分自身に更新されたため何もしません")
        } else {
            logger.log("辞書 \(self.id, privacy: .public) のバージョンが更新されたので読み込みます")
            try? load(fileURL)
        }
    }

    func presentedItemDidLose(_ version: NSFileVersion) {
        logger.log("辞書 \(self.id, privacy: .public) が更新されたので読み込みます (バージョン情報が消失)")
        try? load(fileURL)
    }

    // NOTE: save() で保存した場合はバージョンが必ず更新されるのでこのメソッドは呼ばれない
    // IMEとして動いているmacSKK (A) とXcodeからデバッグ起動しているmacSKK (B) の両方がいる場合、
    // どちらも同じ辞書ファイルを監視しているので、Aが保存してもAのpresentedItemDidChangeは呼び出されないが、
    // BのpresentedItemDidChangeは呼び出される。
    func presentedItemDidChange() {
        if let version = NSFileVersion.currentVersionOfItem(at: fileURL), version == self.version {
            logger.log("辞書 \(self.id, privacy: .public) が変更されましたがバージョンが変更されてないため何もしません")
        } else {
            logger.log("辞書 \(self.id, privacy: .public) が変更されたので読み込みます")
            try? load(fileURL)
        }
    }
}
