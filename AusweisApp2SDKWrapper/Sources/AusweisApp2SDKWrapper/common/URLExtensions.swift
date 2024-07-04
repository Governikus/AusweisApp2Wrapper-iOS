/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

public extension URL {
	var isValidHttpsURL: Bool {
		guard let scheme = scheme, scheme == "https" else { return false }

		let string = absoluteString

		let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		if let match = detector?.firstMatch(
			in: string,
			options: [],
			range: NSRange(location: 0, length: string.utf16.count)
		) {
			return match.range.length == string.utf16.count
		}

		return false
	}
}
