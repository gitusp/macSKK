// SPDX-FileCopyrightText: 2022 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

struct Romaji: Equatable, Sendable {
    struct Moji: Equatable {
        init(firstRomaji: String, kana: String, katakana: String? = nil, hankaku: String? = nil, remain: String? = nil) {
            self.firstRomaji = firstRomaji
            self.kana = kana
            self.katakana = katakana
            self.hankaku = hankaku
            self.remain = remain
        }

        /**
         * SKK辞書で表現されるローマ字
         *
         * - TODO: EmacsのSKK基準で実装する。とりあえず不明なものは空文字列にしている。
         */
        let firstRomaji: String
        /// ひらがなモードでの表記
        let kana: String
        /// カタカナモードでの表記
        let katakana: String?
        /// 半角カナモードでの表記
        let hankaku: String?
        /**
         * 未確定文字列に残すローマ字
         *
         * 例えば "kk" と入力したら "っ" を確定して "k" を未確定入力に残す
         */
        let remain: String?

        func string(for mode: InputMode) -> String {
            switch mode {
            case .hiragana:
                return kana
            case .katakana:
                return katakana ?? kana.toKatakana()
            case .hankaku:
                return hankaku ?? kana.toKatakana().toHankaku()
            case .direct:  // Abbrevモード用
                return firstRomaji
            default:
                fatalError("Called Romaji.Moji.string from wrong mode \(mode)")
            }
        }
    }

    /**
     * 入力されたローマ字をMojiに変換した結果。Romaji.convertの返値として利用する。
     *
     * 例
     * - aを入力: input: "", kakutei: "あ"
     * - bを入力: input: "b", kakutei: nil
     * - bbと入力: input: "b", kakutei: "っ"
     * - dgと入力: input: "g", kakutei: nil (dのあとに続けられないgを入力したのでdは無効となった)
     */
    struct ConvertedMoji: Equatable {
        /// 未確定で残っているローマ字
        let input: String
        /// 確定した文字。
        let kakutei: Moji?
    }

    static let n = Moji(firstRomaji: "n", kana: "ん")
    static func sokuon(_ firstRomaji: String) -> Moji {
        Moji(firstRomaji: firstRomaji, kana: "っ")
    }

    // ローマ字から平仮名、カタカナ、半角カタカナへの辞書
    // ref. https://ja.wikipedia.org/wiki/%E3%83%AD%E3%83%BC%E3%83%9E%E5%AD%97%E5%85%A5%E5%8A%9B
    static let table: [String: Moji] = [
        "a": Moji(firstRomaji: "a", kana: "あ"),
        "i": Moji(firstRomaji: "i", kana: "い"),
        "u": Moji(firstRomaji: "u", kana: "う"),
        "e": Moji(firstRomaji: "e", kana: "え"),
        "o": Moji(firstRomaji: "o", kana: "お"),
        "ka": Moji(firstRomaji: "k", kana: "か"),
        "ki": Moji(firstRomaji: "k", kana: "き"),
        "ku": Moji(firstRomaji: "k", kana: "く"),
        "ke": Moji(firstRomaji: "k", kana: "け"),
        "ko": Moji(firstRomaji: "k", kana: "こ"),
        "sa": Moji(firstRomaji: "s", kana: "さ"),
        "si": Moji(firstRomaji: "s", kana: "し"),
        "shi": Moji(firstRomaji: "s", kana: "し"),
        "su": Moji(firstRomaji: "s", kana: "す"),
        "se": Moji(firstRomaji: "s", kana: "せ"),
        "so": Moji(firstRomaji: "s", kana: "そ"),
        "ta": Moji(firstRomaji: "t", kana: "た"),
        "ti": Moji(firstRomaji: "t", kana: "ち"),
        "chi": Moji(firstRomaji: "t", kana: "ち"),
        "tu": Moji(firstRomaji: "t", kana: "つ"),
        "tsu": Moji(firstRomaji: "t", kana: "つ"),
        "te": Moji(firstRomaji: "t", kana: "て"),
        "to": Moji(firstRomaji: "t", kana: "と"),
        "na": Moji(firstRomaji: "n", kana: "な"),
        "ni": Moji(firstRomaji: "n", kana: "に"),
        "nu": Moji(firstRomaji: "n", kana: "ぬ"),
        "ne": Moji(firstRomaji: "n", kana: "ね"),
        "no": Moji(firstRomaji: "n", kana: "の"),
        "ha": Moji(firstRomaji: "h", kana: "は"),
        "hi": Moji(firstRomaji: "h", kana: "ひ"),
        "hu": Moji(firstRomaji: "h", kana: "ふ"),
        "fu": Moji(firstRomaji: "f", kana: "ふ"),
        "he": Moji(firstRomaji: "h", kana: "へ"),
        "ho": Moji(firstRomaji: "h", kana: "ほ"),
        "ma": Moji(firstRomaji: "m", kana: "ま"),
        "mi": Moji(firstRomaji: "m", kana: "み"),
        "mu": Moji(firstRomaji: "m", kana: "む"),
        "me": Moji(firstRomaji: "m", kana: "め"),
        "mo": Moji(firstRomaji: "m", kana: "も"),
        "ya": Moji(firstRomaji: "y", kana: "や"),
        "yu": Moji(firstRomaji: "y", kana: "ゆ"),
        "yo": Moji(firstRomaji: "y", kana: "よ"),
        "ra": Moji(firstRomaji: "r", kana: "ら"),
        "ri": Moji(firstRomaji: "r", kana: "り"),
        "ru": Moji(firstRomaji: "r", kana: "る"),
        "re": Moji(firstRomaji: "r", kana: "れ"),
        "ro": Moji(firstRomaji: "r", kana: "ろ"),
        "wa": Moji(firstRomaji: "w", kana: "わ"),
        "wo": Moji(firstRomaji: "w", kana: "を"),
        "nn": Moji(firstRomaji: "n", kana: "ん"),
        "ga": Moji(firstRomaji: "g", kana: "が"),
        "gi": Moji(firstRomaji: "g", kana: "ぎ"),
        "gu": Moji(firstRomaji: "g", kana: "ぐ"),
        "ge": Moji(firstRomaji: "g", kana: "げ"),
        "go": Moji(firstRomaji: "g", kana: "ご"),
        "za": Moji(firstRomaji: "z", kana: "ざ"),
        "zi": Moji(firstRomaji: "z", kana: "じ"),
        "ji": Moji(firstRomaji: "z", kana: "じ"),
        "zu": Moji(firstRomaji: "z", kana: "ず"),
        "ze": Moji(firstRomaji: "z", kana: "ぜ"),
        "zo": Moji(firstRomaji: "z", kana: "ぞ"),
        "da": Moji(firstRomaji: "d", kana: "だ"),
        "di": Moji(firstRomaji: "d", kana: "ぢ"),
        "du": Moji(firstRomaji: "d", kana: "づ"),
        "de": Moji(firstRomaji: "d", kana: "で"),
        "do": Moji(firstRomaji: "d", kana: "ど"),
        "ba": Moji(firstRomaji: "b", kana: "ば"),
        "bi": Moji(firstRomaji: "b", kana: "び"),
        "bu": Moji(firstRomaji: "b", kana: "ぶ"),
        "be": Moji(firstRomaji: "b", kana: "べ"),
        "bo": Moji(firstRomaji: "b", kana: "ぼ"),
        "pa": Moji(firstRomaji: "p", kana: "ぱ"),
        "pi": Moji(firstRomaji: "p", kana: "ぴ"),
        "pu": Moji(firstRomaji: "p", kana: "ぷ"),
        "pe": Moji(firstRomaji: "p", kana: "ぺ"),
        "po": Moji(firstRomaji: "p", kana: "ぽ"),
        "kya": Moji(firstRomaji: "k", kana: "きゃ"),
        "kyu": Moji(firstRomaji: "k", kana: "きゅ"),
        "kyo": Moji(firstRomaji: "k", kana: "きょ"),
        "sya": Moji(firstRomaji: "s", kana: "しゃ"),
        "sha": Moji(firstRomaji: "s", kana: "しゃ"),
        "syu": Moji(firstRomaji: "s", kana: "しゅ"),
        "shu": Moji(firstRomaji: "s", kana: "しゅ"),
        "syo": Moji(firstRomaji: "s", kana: "しょ"),
        "sho": Moji(firstRomaji: "s", kana: "しょ"),
        "tya": Moji(firstRomaji: "t", kana: "ちゃ"),
        "cha": Moji(firstRomaji: "t", kana: "ちゃ"),
        "tyu": Moji(firstRomaji: "t", kana: "ちゅ"),
        "chu": Moji(firstRomaji: "t", kana: "ちゅ"),
        "tyo": Moji(firstRomaji: "t", kana: "ちょ"),
        "cho": Moji(firstRomaji: "t", kana: "ちょ"),
        "nya": Moji(firstRomaji: "n", kana: "にゃ"),
        "nyu": Moji(firstRomaji: "n", kana: "にゅ"),
        "nyo": Moji(firstRomaji: "n", kana: "にょ"),
        "hya": Moji(firstRomaji: "h", kana: "ひゃ"),
        "hyu": Moji(firstRomaji: "h", kana: "ひゅ"),
        "hyo": Moji(firstRomaji: "h", kana: "ひょ"),
        "mya": Moji(firstRomaji: "m", kana: "みゃ"),
        "myu": Moji(firstRomaji: "m", kana: "みゅ"),
        "myo": Moji(firstRomaji: "m", kana: "みょ"),
        "rya": Moji(firstRomaji: "r", kana: "りゃ"),
        "ryu": Moji(firstRomaji: "r", kana: "りゅ"),
        "ryo": Moji(firstRomaji: "r", kana: "りょ"),
        "gya": Moji(firstRomaji: "g", kana: "ぎゃ"),
        "gyu": Moji(firstRomaji: "g", kana: "ぎゅ"),
        "gyo": Moji(firstRomaji: "g", kana: "ぎょ"),
        "zya": Moji(firstRomaji: "z", kana: "じゃ"),
        "ja": Moji(firstRomaji: "z", kana: "じゃ"),
        "zyu": Moji(firstRomaji: "z", kana: "じゅ"),
        "ju": Moji(firstRomaji: "z", kana: "じゅ"),
        "zyo": Moji(firstRomaji: "z", kana: "じょ"),
        "jo": Moji(firstRomaji: "z", kana: "じょ"),
        "dya": Moji(firstRomaji: "d", kana: "ぢゃ"),
        "dyu": Moji(firstRomaji: "d", kana: "ぢゅ"),
        "dyo": Moji(firstRomaji: "d", kana: "ぢょ"),
        "bya": Moji(firstRomaji: "b", kana: "びゃ"),
        "byu": Moji(firstRomaji: "b", kana: "びゅ"),
        "byo": Moji(firstRomaji: "b", kana: "びょ"),
        "pya": Moji(firstRomaji: "p", kana: "ぴゃ"),
        "pyu": Moji(firstRomaji: "p", kana: "ぴゅ"),
        "pyo": Moji(firstRomaji: "p", kana: "ぴょ"),
        "sye": Moji(firstRomaji: "s", kana: "しぇ"),
        "she": Moji(firstRomaji: "s", kana: "しぇ"),
        "tye": Moji(firstRomaji: "t", kana: "ちぇ"),
        "che": Moji(firstRomaji: "t", kana: "ちぇ"),
        "tsa": Moji(firstRomaji: "t", kana: "つぁ"),
        "tse": Moji(firstRomaji: "t", kana: "つぇ"),
        "tso": Moji(firstRomaji: "t", kana: "つぉ"),
        "thi": Moji(firstRomaji: "t", kana: "てぃ"),
        "fa": Moji(firstRomaji: "f", kana: "ふぁ"),
        "fi": Moji(firstRomaji: "f", kana: "ふぃ"),
        "fe": Moji(firstRomaji: "f", kana: "ふぇ"),
        "fo": Moji(firstRomaji: "f", kana: "ふぉ"),
        "zye": Moji(firstRomaji: "z", kana: "じぇ"),
        "je": Moji(firstRomaji: "z", kana: "じぇ"),
        "dye": Moji(firstRomaji: "d", kana: "ぢぇ"),
        "dhi": Moji(firstRomaji: "d", kana: "でぃ"),
        "dhu": Moji(firstRomaji: "d", kana: "でゅ"),
        "xa": Moji(firstRomaji: "", kana: "ぁ"),
        "xi": Moji(firstRomaji: "", kana: "ぃ"),
        "xu": Moji(firstRomaji: "", kana: "ぅ"),
        "xe": Moji(firstRomaji: "", kana: "ぇ"),
        "xo": Moji(firstRomaji: "", kana: "ぉ"),
        "xka": Moji(firstRomaji: "", kana: "ヵ"),
        "xke": Moji(firstRomaji: "", kana: "ヶ"),
        "xtu": Moji(firstRomaji: "", kana: "っ"),
        "xya": Moji(firstRomaji: "", kana: "ゃ"),
        "xyu": Moji(firstRomaji: "", kana: "ゅ"),
        "xyo": Moji(firstRomaji: "", kana: "ょ"),
        "xwa": Moji(firstRomaji: "", kana: "ゎ"),
        // 追加で実装したほうがよい入力方法
        "ye": Moji(firstRomaji: "", kana: "いぇ"),
        "whi": Moji(firstRomaji: "", kana: "うぃ"),
        "wi": Moji(firstRomaji: "", kana: "うぃ"),
        "whe": Moji(firstRomaji: "", kana: "うぇ"),
        "we": Moji(firstRomaji: "", kana: "うぇ"),
        "va": Moji(firstRomaji: "", kana: "う゛ぁ"),
        "vi": Moji(firstRomaji: "", kana: "う゛ぃ"),
        "vu": Moji(firstRomaji: "", kana: "う゛"),
        "ve": Moji(firstRomaji: "", kana: "う゛ぇ"),
        "vo": Moji(firstRomaji: "", kana: "う゛ぉ"),
        "vyu": Moji(firstRomaji: "", kana: "う゛ゅ"),
        "kwa": Moji(firstRomaji: "", kana: "くぁ"),
        "qa": Moji(firstRomaji: "", kana: "くぁ"),
        "kwi": Moji(firstRomaji: "", kana: "くぃ"),
        "qi": Moji(firstRomaji: "", kana: "くぃ"),
        "kwe": Moji(firstRomaji: "", kana: "くぇ"),
        "qe": Moji(firstRomaji: "", kana: "くぇ"),
        "kwo": Moji(firstRomaji: "", kana: "くぉ"),
        "qo": Moji(firstRomaji: "", kana: "くぉ"),
        "gwa": Moji(firstRomaji: "", kana: "ぐぁ"),
        "jya": Moji(firstRomaji: "", kana: "じゃ"),
        "jyu": Moji(firstRomaji: "", kana: "じゅ"),
        "jyo": Moji(firstRomaji: "", kana: "じょ"),
        "cya": Moji(firstRomaji: "", kana: "ちゃ"),
        "cyu": Moji(firstRomaji: "", kana: "ちゅ"),
        "cyo": Moji(firstRomaji: "", kana: "ちょ"),
        "tsi": Moji(firstRomaji: "", kana: "つぃ"),
        "thu": Moji(firstRomaji: "", kana: "てゅ"),
        "twu": Moji(firstRomaji: "", kana: "とぅ"),
        "dwu": Moji(firstRomaji: "", kana: "どぅ"),
        "hwa": Moji(firstRomaji: "", kana: "ふぁ"),
        "hwi": Moji(firstRomaji: "", kana: "ふぃ"),
        "hwe": Moji(firstRomaji: "", kana: "ふぇ"),
        "hwo": Moji(firstRomaji: "", kana: "ふぉ"),
        "fwu": Moji(firstRomaji: "", kana: "ふゅ"),
        "xtsu": Moji(firstRomaji: "t", kana: "っ"),
    ]

    enum RomajiError: Error {
        /// 不正な設定
        case invalid
    }

    /// ローマ字変換テーブル
    let table: [String: Moji]

    /**
     * 未確定文字列のままになることができる文字列の集合。
     *
     * 例えば ["k", "ky", "t"] となっている場合、kt と連続して入力したときには
     * このあとにどんな文字列を入力してもローマ字変換が確定しないためkは捨てられて未確定文字列はtとなる。
     * 現在入力中の未確定文字列がこの集合にないときは最後の未確定文字列だけを残すために利用する。
     */
    let undecidedInputs: Set<String>

    init(contentsOf url: URL) throws {
        var table: [String: Moji] = [:]
        var undecidedInputs: Set<String> = []
        var error: RomajiError? = nil
        var lineNumber = 0
        try String(contentsOf: url, encoding: .utf8).enumerateLines { line, stop in
            lineNumber += 1
            // #で始まる行はコメント行
            if line.starts(with: "#") || line.isEmpty {
                return
            }
            // TODO: 正規表現などで一要素目がキーボードから直接入力できるASCII文字であることを検査する
            let elements = line.split(separator: ",", maxSplits: 5).map {
                $0.replacingOccurrences(of: "&comma;", with: ",")
            }
            if elements.count < 2 || elements.contains(where: { $0.isEmpty }) {
                logger.error("ローマ字変換定義ファイルの \(lineNumber) 行目の記述が壊れています")
                error = RomajiError.invalid
                stop = true
                return
            }
            let firstRomaji = elements.count == 5 ? elements[4] : String(elements[0].first!)
            let katakana = elements.count > 2 ? elements[2] : nil
            let hankaku = elements.count > 3 ? elements[3] : nil
            let remain = elements.count > 4 ? elements[4] : nil
            table[elements[0]] = Moji(firstRomaji: firstRomaji,
                                      kana: elements[1],
                                      katakana: katakana,
                                      hankaku: hankaku,
                                      remain: remain)
            if elements[0].count > 1 {
                undecidedInputs.insert(String(elements[0].dropLast()))
            }
        }
        if let error {
            throw error
        }
        self.table = table
        self.undecidedInputs = undecidedInputs
    }

    /**
     * ローマ字文字列を受け取り、かな確定文字と残りのローマ字文字列を返す.
     *
     * - "ka" が入力されたら確定文字 "か" と残りのローマ字文字列 "" を返す
     * - "k" が入力されたら確定文字はnil, 残りのローマ字文字列 "k" を返す
     * - "kt" のように連続できない子音が連続したinputの場合は"k"を捨てて"t"をinput引数としたときのconvertの結果を返す
     * - "kya" のように確定した文字が複数の場合がありえる
     * - "aiueo" のように複数の確定が可能な場合は最初に確定できた文字だけを確定文字として返し、残りは(確定可能だが)inputとして返す
     * - ",", "." は"、", "。"にする (将来設定で切り変えられるようにするかも)
     * - "1" のように非ローマ字文字列を受け取った場合は未定義とする (呼び出し側で処理する予定だけどここで処理するかも)
     */
    func convert(_ input: String) -> ConvertedMoji {
        if let moji = table[input] {
            return ConvertedMoji(input: moji.remain ?? "", kakutei: moji)
        } else if undecidedInputs.contains(input) {
            return ConvertedMoji(input: input, kakutei: nil)
        } else if input.hasPrefix("n") && input.count == 2 {
            return ConvertedMoji(input: String(input.dropFirst()), kakutei: Romaji.n)
        } else if input.count > 1, let c = input.last {
            return convert(String(c))
        }
        return ConvertedMoji(input: input, kakutei: nil)
    }
}
