/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

protocol Command: Encodable {
	var cmd: String { get }
}

struct Accept: Command {
	let cmd = "ACCEPT"
}

struct Cancel: Command {
	let cmd = "CANCEL"
}

struct ContinueWorkflow: Command {
	let cmd = "CONTINUE"
}

struct GetCertificate: Command {
	let cmd = "GET_CERTIFICATE"
}

struct RunAuth: Command {
	let cmd = "RUN_AUTH"
	let tcTokenURL: String
	let developerMode: Bool
	let messages: AA2UserInfoMessages?
	let status: Bool
}

struct RunChangePin: Command {
	let cmd = "RUN_CHANGE_PIN"
	let messages: AA2UserInfoMessages?
	let status: Bool
}

struct SetAccessRights: Command {
	let cmd = "SET_ACCESS_RIGHTS"
	let chat: [String]
}

struct GetAccessRights: Command {
	let cmd = "GET_ACCESS_RIGHTS"
}

struct SetCan: Command {
	let cmd = "SET_CAN"
	let value: String?
}

struct SetPin: Command {
	let cmd = "SET_PIN"
	let value: String?
}

struct SetNewPin: Command {
	let cmd = "SET_NEW_PIN"
	let value: String?
}

struct SetPuk: Command {
	let cmd = "SET_PUK"
	let value: String?
}

struct Interrupt: Command {
	let cmd = "INTERRUPT"
}

struct GetStatus: Command {
	let cmd = "GET_STATUS"
}

struct GetInfo: Command {
	let cmd = "GET_INFO"
}

struct GetReader: Command {
	let cmd = "GET_READER"
	let name: String
}

struct GetReaderList: Command {
	let cmd = "GET_READER_LIST"
}

struct SetCard: Command {
	let cmd = "SET_CARD"
	let name: String
	let simulator: Simulator?
}
