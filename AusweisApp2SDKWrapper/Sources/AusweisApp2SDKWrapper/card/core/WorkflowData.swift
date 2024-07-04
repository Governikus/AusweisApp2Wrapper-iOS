/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

/// Detailed description of the certificate.
public struct CertificateDescription {
	/// Name of the certificate issuer.
	public let issuerName: String

	/// URL of the certificate issuer.
	public let issuerUrl: URL?

	/// Parsed purpose of the terms of usage.
	public let purpose: String

	/// Name of the certificate subject.
	public let subjectName: String

	/// URL of the certificate subject.
	public let subjectUrl: URL?

	/// Raw certificate information about the terms of usage.
	public let termsOfUsage: String

	/// Certificate validity
	public let validity: CertificateValidity
}

/// Validity dates of the certificate.
public struct CertificateValidity {
	/// Certificate is valid since this date.
	public let effectiveDate: Date

	/// Certificate is invalid after this date.
	public let expirationDate: Date
}

/// Access rights requested by the provider.
public struct AccessRights {
	/// These rights are mandatory and cannot be disabled.
	public let requiredRights: [AccessRight]

	/// These rights are optional and can be enabled or disabled
	public let optionalRights: [AccessRight]

	/// Indicates the enabled access rights of optional and required.
	public let effectiveRights: [AccessRight]

	/// Optional transaction information.
	public let transactionInfo: String?

	/// Optional auxiliary data of the provider.
	public let auxiliaryData: AuxiliaryData?
}

/// Auxiliary data of the provider.
public struct AuxiliaryData {
	/// Optional required date of birth for AgeVerification.
	public let ageVerificationDate: Date?

	/// Optional required age for AgeVerification.
	/// It is calculated by the SDK Wrapper on the basis of ageVerificationDate and current date.
	public let requiredAge: Int?

	/// Optional validity date.
	public let validityDate: Date?

	/// Optional id of community.
	public let communityId: String?
}

/// Provides information about a reader.
public struct Reader {
	/// Identifier of card reader.
	public let name: String

	/// Indicates whether a card can be inserted via setCard()
	public let insertable: Bool

	/// Indicates whether a card reader is connected or disconnected.
	public let attached: Bool

	/// Indicates whether a card reader has a keypad. The parameter is only shown when a reader is attached.
	public let keypad: Bool

	/// Provides information about inserted card, otherwise nil.
	public let card: Card?

	init(name: String, insertable: Bool, attached: Bool, keypad: Bool, card: Card?) {
		self.name = name
		self.insertable = insertable
		self.attached = attached
		self.keypad = keypad
		self.card = card
	}

	init(reader: AA2Reader) {
		name = reader.name
		insertable = reader.insertable
		attached = reader.attached
		keypad = reader.keypad
		card = reader.card != nil ? Card(card: reader.card!) : nil
	}
}

/// Provides information about inserted card.
/// An unknown card (without eID function) is represented by all properties set to null.
public struct Card {
	/// True if PUK is inoperative and cannot unblock PIN otherwise false.
	/// This can be recognized if user enters a correct PUK only.
	/// It is not possible to read this data before a user tries to unblock the PIN.
	public let deactivated: Bool?

	/// True if eID functionality is deactivated otherwise false.
	public let inoperative: Bool?

	/// Count of possible retries for the PIN. If you enter a PIN it will be decreased if PIN was incorrect.
	public let pinRetryCounter: Int?

	init(card: AA2Card) {
		deactivated = card.deactivated
		inoperative = card.inoperative
		pinRetryCounter = card.retryCounter
	}

	/// Convenience method to check if an unknown card (without eID function) was detected.
	public func isUnknown() -> Bool {
		return inoperative == nil && deactivated == nil && pinRetryCounter == nil
	}
}

/// Provides information about why the SDK is waiting.
public enum Cause: String {
	/// Denotes an unstable or lost card connection.
	case BadCardPosition // swiftlint:disable:this identifier_name
}

/// Final result of an authentication.
public struct AuthResult {
	/// Refresh url or communication error address (which is optional).
	public let url: URL?

	/// Contains information about the result of the authentication.
	public let result: AuthResultData?
}

/// Final result of a PIN change.
public struct ChangePinResult {
	// False if an error occured or the PIN change was aborted.
	public let success: Bool

	/// Unique error code if the PIN change failed.
	public let reason: String?
}

/// Information about an authentication.
public struct AuthResultData {
	/// Major error code.
	public let major: String

	/// Minor error code.
	public let minor: String?

	/// Language of description and message. Language “en” is supported only at the moment.
	public let language: String?

	/// Description of the error message.
	public let description: String?

	/// The error message.
	public let message: String?

	/// Unique error code.
	public let reason: String?
}

/// Provides information about an error.
public struct WrapperError {
	/// Message type in which the error occurred.
	public let msg: String

	/// Error message.
	public let error: String
}

/// Provides information about the workflow status
public struct WorkflowProgress {
	/// Type of the current workflow. If there is no workflow in progress this will be null.
	public let workflow: WorkflowProgressType?

	/// Percentage of workflow progress. If there is no workflow in progress this will be null.
	public let progress: Int?

	/// Name of the current state if paused. If there is no workflow in progress or the workflow
	/// is not paused this will be null.
	public let state: String?

	public init() {
		workflow = nil
		progress = nil
		state = nil
	}

	init(workflow: String?, progress: Int?, state: String?) {
		self.workflow = WorkflowProgressType(rawValue: workflow ?? "")
		self.progress = progress
		self.state = state
	}
}

/// Provides information about the underlying AusweisApp2
public struct VersionInfo {
	/// Application name.
	public let name: String

	/// Title of implementation.
	public let implementationTitle: String

	/// Vendor of implementation.
	public let implementationVendor: String

	/// Version of implementation.
	public let implementationVersion: String

	/// Title of specification.
	public let specificationTitle: String

	/// Vendor of specification.
	public let specificationVendor: String

	/// Version of specification.
	public let specificationVersion: String

	init(info: AA2VersionInfo) {
		name = info.name
		implementationTitle = info.implementationTitle
		implementationVendor = info.implementationVendor
		implementationVersion = info.implementationVersion
		specificationTitle = info.specificationTitle
		specificationVendor = info.specificationVendor
		specificationVersion = info.specificationVersion
	}
}

// swiftlint:disable identifier_name
/// List of all available access rights a provider might request.
public enum AccessRight: String {
	case Address,
	     BirthName,
	     FamilyName,
	     GivenNames,
	     PlaceOfBirth,
	     DateOfBirth,
	     DoctoralDegree,
	     ArtisticName,
	     Pseudonym,
	     ValidUntil,
	     Nationality,
	     IssuingCountry,
	     DocumentType,
	     ResidencePermitI,
	     ResidencePermitII,
	     CommunityID,
	     AddressVerification,
	     AgeVerification,
	     WriteAddress,
	     WriteCommunityID,
	     WriteResidencePermitI,
	     WriteResidencePermitII,
	     CanAllowed,
	     PinManagement
}

/// List of all types of WorkflowProgess
public enum WorkflowProgressType: String {
	case AUTHENTICATION = "AUTH"
	case CHANGE_PIN
}

// swiftlint:enable identifier_name

// swiftlint:disable opening_brace
/// Messages for the NFC system dialog
public struct AA2UserInfoMessages: Encodable {
	public init(sessionStarted: String? = "",
	            sessionFailed: String? = "",
	            sessionSucceeded: String? = "",
	            sessionInProgress: String? = "")
	{
		self.sessionStarted = sessionStarted
		self.sessionFailed = sessionFailed
		self.sessionSucceeded = sessionSucceeded
		self.sessionInProgress = sessionInProgress
	}

	/// Shown if scanning is started
	let sessionStarted: String?
	/// Shown if communication was stopped with an error.
	let sessionFailed: String?
	/// Shown if communication was stopped successfully.
	let sessionSucceeded: String?
	/// Shown if communication is in progress. This message will be appended with current percentage level.
	let sessionInProgress: String?
}

// swiftlint:enable opening_brace

/// Optional definition of files and keys for the Simulator reader
public struct Simulator: Encodable {
	/// List of SimulatorFile definitions
	let files: [SimulatorFile]
	/// List of SimulatorKey definitions
	let keys: [SimulatorKey]?

	public init(withFiles: [SimulatorFile], withKeys: [SimulatorKey]? = nil) {
		files = withFiles
		keys = withKeys
	}
}

/// Filesystem for Simulator reader
/// The content of the filesystem can be provided as a JSON array of objects.
/// The fileId and shortFileId are specified on the corresponding technical guideline
/// of the BSI and ISO. The content is an ASN.1 structure in DER encoding.
/// All fields are hex encoded.
public struct SimulatorFile: Encodable {
	let fileId: String
	let shortFileId: String
	let content: String
	public init(withFileId: String, withShortFileId: String, withContent: String) {
		fileId = withFileId
		shortFileId = withShortFileId
		content = withContent
	}
}

/// Keys for Simulator reader
/// The keys are used to check against the blacklist and to calculate the pseudonym for the service provider.
public struct SimulatorKey: Encodable {
	let id: Int
	let content: String
	public init(withId: Int, withContent: String) {
		id = withId
		content = withContent
	}
}
