/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

public extension AuthResult {
	var hasError: Bool {
		result?.major.contains("resultmajor#error") ?? false
	}
}

public extension AuthResultData {
	var isCancellationByUser: Bool {
		minor?.contains("cancellationByUser") ?? false
	}
}
