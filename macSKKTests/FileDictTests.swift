// SPDX-FileCopyrightText: 2023 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

@testable import macSKK

final class FileDictTests: XCTestCase {
    let fileURL = Bundle(for: FileDictTests.self).url(forResource: "empty", withExtension: "txt")!

    func testAdd() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: true)
        XCTAssertEqual(dict.entryCount, 0)
        let word = Word("井")
        XCTAssertFalse(dict.hasUnsavedChanges)
        dict.add(yomi: "い", word: word)
        XCTAssertEqual(dict.refer("い"), [word])
        XCTAssertTrue(dict.hasUnsavedChanges)
    }

    func testDelete() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: true)
        dict.setEntries(["あr": [Word("有"), Word("在")]], readonly: true)
        XCTAssertFalse(dict.delete(yomi: "あr", word: "或"))
        XCTAssertFalse(dict.hasUnsavedChanges)
        XCTAssertTrue(dict.delete(yomi: "あr", word: "在"))
        XCTAssertTrue(dict.hasUnsavedChanges)
    }

    func testSerialize() throws {
        let dict = try FileDict(contentsOf: fileURL, encoding: .utf8, readonly: true)
        XCTAssertEqual(dict.serialize(), FileDict.headers[0])
        dict.add(yomi: "あ", word: Word("亜", annotation: Annotation(dictId: "testDict", text: "亜の注釈")))
        XCTAssertEqual(dict.serialize(), FileDict.headers[0] + "\nあ /亜;亜の注釈/")
    }
}
