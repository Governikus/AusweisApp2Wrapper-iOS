/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

extension String {
	public var isNumber: Bool {
		return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
	}

	func parseDate(format: String) -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		return dateFormatter.date(from: self)
	}
}
