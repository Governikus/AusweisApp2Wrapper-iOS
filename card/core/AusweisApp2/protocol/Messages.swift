/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

enum AA2Messages {
	static let MsgAccessRights = "ACCESS_RIGHTS"
	static let MsgAuth = "AUTH"
	static let MsgCertificate = "CERTIFICATE"
	static let MsgChangePin = "CHANGE_PIN"
	static let MsgEnterPin = "ENTER_PIN"
	static let MsgEnterNewPin = "ENTER_NEW_PIN"
	static let MsgEnterPuk = "ENTER_PUK"
	static let MsgEnterCan = "ENTER_CAN"
	static let MsgInsertCard = "INSERT_CARD"
	static let MsgBadState = "BAD_STATE"
	static let MsgReader = "READER"
	static let MsgInvalid = "INVALID"
	static let MsgUnknowCommand = "UNKNOWN_COMMAND"
	static let MsgInternalError = "INTERNAL_ERROR"
	static let MsgStatus = "STATUS"
	static let MsgInfo = "INFO"
	static let MsgReaderList = "READER_LIST"
	static let MsgApiLevel = "API_LEVEL"
}

struct AA2Message: Decodable {
	let msg: String
	let error: String?
	let card: AA2Card?
	let result: AA2Result?
	let chat: AA2Chat?
	let aux: AA2Aux?
	let transactionInfo: String?
	let validity: AA2Validity?
	let description: AA2Description?
	let url: String?
	let success: Bool?
	let reason: String?
	let reader: AA2Reader?
	let readers: [AA2Reader]?
	let name: String?
	let insertable: Bool?
	let attached: Bool?
	let keypad: Bool?
	let workflow: String?
	let progress: Int?
	let state: String?
	let versionInfo: AA2VersionInfo?
	let available: [Int]?
	let current: Int?

	enum CodingKeys: String, CodingKey {
		case versionInfo = "VersionInfo"

		case msg, error, card, result, chat, aux, transactionInfo, validity
		case description, url, success, reader, workflow, progress, state
		case name, insertable, attached, keypad, readers, available, current
		case reason
	}
}

struct AA2Description: Decodable {
	let issuerName: String
	let issuerUrl: String
	let purpose: String
	let subjectName: String
	let subjectUrl: String
	let termsOfUsage: String
}

struct AA2Validity: Decodable {
	let effectiveDate: String
	let expirationDate: String
}

struct AA2Chat: Decodable {
	let effective: [String]
	let optional: [String]
	let required: [String]
}

struct AA2Aux: Decodable {
	let ageVerificationDate: String?
	let requiredAge: String?
	let validityDate: String?
	let communityId: String?
}

struct AA2Card: Decodable {
	let deactivated: Bool
	let inoperative: Bool
	let retryCounter: Int
}

struct AA2Reader: Decodable {
	let name: String
	let insertable: Bool
	let attached: Bool
	let keypad: Bool
	let card: AA2Card?
}

struct AA2Result: Decodable {
	let major: String?
	let minor: String?
	let url: String?
	let language: String?
	let description: String?
	let message: String?
	let reason: String?
}

struct AA2VersionInfo: Decodable {
	let name: String
	let implementationTitle: String
	let implementationVendor: String
	let implementationVersion: String
	let specificationTitle: String
	let specificationVendor: String
	let specificationVersion: String

	enum CodingKeys: String, CodingKey {
		case name = "Name"
		case implementationTitle = "Implementation-Title"
		case implementationVendor = "Implementation-Vendor"
		case implementationVersion = "Implementation-Version"
		case specificationTitle = "Specification-Title"
		case specificationVendor = "Specification-Vendor"
		case specificationVersion = "Specification-Version"
	}
}
