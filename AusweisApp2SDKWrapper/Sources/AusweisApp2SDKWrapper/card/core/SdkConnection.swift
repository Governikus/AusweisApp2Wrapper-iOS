/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

protocol SdkConnection {
	var isStarted: Bool { get }
	var onConnected: (() -> Void)? { get set }
	var onMessageReceived: ((_ message: AA2Message) -> Void)? { get set }

	func start()
	func stop()
	func send<T: Command>(command: T)
}
