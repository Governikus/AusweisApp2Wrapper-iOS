/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

@testable import AusweisApp2SDKWrapper
import XCTest

class WorkflowControllerTests: XCTestCase {
	private var connection: MockSdkConnection!
	private var workflowController: WorkflowController!
	private var testCallbacks: TestWorkflowCallbacks!

	override func setUp() {
		connection = MockSdkConnection()
		workflowController = WorkflowController(withConnection: connection)
		testCallbacks = TestWorkflowCallbacks()
		workflowController.registerCallbacks(testCallbacks)
	}

	override func tearDown() {
		workflowController.unregisterCallbacks(testCallbacks)
		connection = nil
		workflowController = nil
		testCallbacks = nil
	}

	func testOnStarted() throws {
		let onStartedExpectation = expectation(description: "onStarted called")

		testCallbacks.doOnStarted = {
			onStartedExpectation.fulfill()
		}

		workflowController.start()

		waitForExpectations(timeout: 1, handler: nil)
		XCTAssertTrue(workflowController.isStarted)
	}

	func testErrorNotStarted() throws {
		let onErrorExpectation = expectation(description: "onWrapperError called")

		testCallbacks.doOnError = {
			onErrorExpectation.fulfill()
		}

		XCTAssertFalse(workflowController.isStarted)
		workflowController.startAuthentication(withTcTokenUrl: URL(string: "https://test.test")!)

		waitForExpectations(timeout: 1, handler: nil)
	}

	func testAuthenticationStarted() throws {
		let testUrl = URL(string: "https://test.test")!

		let onAuthenticationStartedExpectation = expectation(description: "onAuthenticationStarted called")
		let authCommandReceivedExpectation = expectation(description: "authCommandReceived")

		connection.onCommandSend = { command in
			let command = command as? RunAuth

			XCTAssertNotNil(command)
			XCTAssertEqual(testUrl.absoluteString, command!.tcTokenURL)

			authCommandReceivedExpectation.fulfill()
			self.connection.receive(messageJson: "{\"msg\":\"AUTH\"}")
		}

		testCallbacks.doOnAuthenticationStarted = {
			onAuthenticationStartedExpectation.fulfill()
		}

		workflowController.start()
		workflowController.startAuthentication(withTcTokenUrl: testUrl)

		waitForExpectations(timeout: 1, handler: nil)
	}

	// swiftlint:disable function_body_length
	func testFullAuthentication() throws {
		let tcTokenUrl = URL(string: "https://test.test")!
		let pin = "123456"

		let exampleDateString = "1999-07-20"
		let exampleDate = exampleDateString.parseDate(format: "yyyy-MM-dd")

		let readerMessage = "{" +
			"  \"msg\": \"READER\"," +
			"  \"name\": \"NFC\"," +
			"  \"attached\": true," +
			"  \"insertable\": true," +
			"  \"keypad\": false," +
			"  \"card\":" +
			"         {" +
			"          \"inoperative\": false," +
			"          \"deactivated\": false," +
			"          \"retryCounter\": 3" +
			"         }" +
			"}"

		let authCommandReceivedExpectation = expectation(description: "authCommandReceived")
		let acceptReceivedExpectation = expectation(description: "acceptReceived")
		let setPinReceivedExpectation = expectation(description: "setPinReceived")
		connection.onCommandSend = { command in
			if let authCommand = command as? RunAuth {
				authCommandReceivedExpectation.fulfill()

				XCTAssertEqual(authCommand.tcTokenURL, tcTokenUrl.absoluteString)

				self.connection.receive(messageJson: "{\"msg\":\"AUTH\"}")
			} else if command as? Accept != nil {
				acceptReceivedExpectation.fulfill()
				self.connection.receive(messageJson: "{\"msg\":\"INSERT_CARD\"}")
			} else if let setPinCommand = command as? SetPin {
				setPinReceivedExpectation.fulfill()

				XCTAssertEqual(setPinCommand.value, pin)

				self.connection.receive(messageJson:
					"{" +
						"  \"msg\": \"AUTH\"," +
						"  \"result\":" +
						"           {" +
						"            \"major\": \"http://www.bsi.bund.de/ecard/api/1.1/resultmajor#ok\"" +
						"           }," +
						"  \"url\": \"https://test.governikus-eid.de/gov_autent/async?refID=_123456789\"" +
						"}"
				)
			}
		}

		let onAuthenticationCompletedExpectation = expectation(description: "onAuthenticationCompleted called")
		testCallbacks.doOnAuthenticationCompleted = { _ in
			onAuthenticationCompletedExpectation.fulfill()
		}

		let onEnterPinExpectation = expectation(description: "onEnterPin called")
		testCallbacks.doOnRequestPin = { card in
			onEnterPinExpectation.fulfill()

			XCTAssertEqual(card.pinRetryCounter, 3)
			XCTAssertEqual(card.deactivated, false)
			XCTAssertEqual(card.inoperative, false)

			self.workflowController.setPin(pin)
		}

		let onRecognizedCardExpectation = expectation(description: "onRecognizedCard called")
		testCallbacks.doOnRecognizedCard = { card in
			onRecognizedCardExpectation.fulfill()

			XCTAssertNotNil(card)
			XCTAssertEqual(card?.pinRetryCounter, 3)
			XCTAssertEqual(card?.deactivated, false)
			XCTAssertEqual(card?.inoperative, false)

			self.connection.receive(messageJson:
				"{" +
					"  \"msg\": \"ENTER_PIN\"," +
					"  \"reader\":" +
					readerMessage +
					"}"
			)
		}

		let onInsertCardExpectation = expectation(description: "onInsertCard called")
		testCallbacks.doOnRequestCard = {
			onInsertCardExpectation.fulfill()

			self.connection.receive(messageJson: readerMessage)
		}

		let onAccessRightsExpectation = expectation(description: "onAccessRights called")
		testCallbacks.doOnRequestAccessRights = { accessRights in
			onAccessRightsExpectation.fulfill()

			XCTAssertEqual(accessRights.auxiliaryData?.ageVerificationDate, exampleDate)
			XCTAssertEqual(accessRights.auxiliaryData?.requiredAge, 18)
			XCTAssertEqual(accessRights.auxiliaryData?.validityDate, exampleDate)
			XCTAssertEqual(accessRights.auxiliaryData?.communityId, "02760400110000")

			XCTAssertTrue(accessRights.requiredRights.contains { $0 == .Address })
			XCTAssertTrue(accessRights.requiredRights.contains { $0 == .FamilyName })
			XCTAssertTrue(accessRights.optionalRights.contains { $0 == .GivenNames })
			XCTAssertTrue(accessRights.optionalRights.contains { $0 == .AgeVerification })

			XCTAssertEqual(accessRights.transactionInfo, "this is an example")

			self.workflowController.accept()
		}

		let onAuthenticationStartedExpectation = expectation(description: "onAuthenticationStarted called")
		testCallbacks.doOnAuthenticationStarted = {
			onAuthenticationStartedExpectation.fulfill()

			self.connection.receive(messageJson:
				"{" +
					"  \"msg\": \"ACCESS_RIGHTS\"," +
					"  \"aux\":" +
					"       {" +
					"        \"ageVerificationDate\": \"" + exampleDateString + "\"," +
					"        \"requiredAge\": \"18\"," +
					"        \"validityDate\": \"" + exampleDateString + "\"," +
					"        \"communityId\": \"02760400110000\"" +
					"       }," +
					"  \"chat\":" +
					"        {" +
					"         \"effective\": [\"Address\", \"FamilyName\", \"GivenNames\", \"AgeVerification\"]," +
					"         \"optional\": [\"GivenNames\", \"AgeVerification\"]," +
					"         \"required\": [\"Address\", \"FamilyName\"]" +
					"        }," +
					"  \"transactionInfo\": \"this is an example\"" +
					"}"
			)
		}

		workflowController.start()
		workflowController.startAuthentication(withTcTokenUrl: tcTokenUrl)
		waitForExpectations(timeout: 2, handler: nil)
	}

	// swiftlint:enable function_body_length
}

class MockSdkConnection: SdkConnection {
	var isStarted = false

	var onConnected: (() -> Void)?
	var onMessageReceived: ((AA2Message) -> Void)?

	var onCommandSend: ((Command) -> Void)?

	func start() {
		isStarted = true
		if let onConnected = onConnected {
			onConnected()
		}
	}

	func stop() {
		isStarted = false
	}

	func send<T>(command: T) where T: Command {
		if let onCommandSend = onCommandSend {
			DispatchQueue.global().async {
				onCommandSend(command)
			}
		}
	}

	func receive(messageJson: String) {
		let messageData = Data(messageJson.utf8)
		let message = try? JSONDecoder().decode(AA2Message.self, from: messageData)

		if let onMessageReceived = onMessageReceived {
			onMessageReceived(message!)
		}
	}
}

class TestWorkflowCallbacks: WorkflowCallbacks {
	var doOnStarted: (() -> Void)?
	var doOnAuthenticationStarted: (() -> Void)?
	var doOnRequestAccessRights: ((AccessRights) -> Void)?
	var doOnRequestCard: (() -> Void)?
	var doOnRecognizedCard: ((Card?) -> Void)?
	var doOnRequestPin: ((Card) -> Void)?
	var doOnAuthenticationCompleted: ((AuthResult) -> Void)?
	var doOnError: (() -> Void)?

	func onInfo(versionInfo _: VersionInfo) {}
	func onReader(reader: Reader?) {
		if let doOnRecognizedCard = doOnRecognizedCard {
			if let card = reader?.card {
				DispatchQueue.global().async {
					doOnRecognizedCard(card)
				}
			}
		}
	}

	func onReaderList(readers _: [Reader]?) {}

	func onStarted() {
		if let doOnStarted = doOnStarted {
			DispatchQueue.global().async {
				doOnStarted()
			}
		}
	}

	func onAuthenticationStarted() {
		if let doOnAuthenticationStarted = doOnAuthenticationStarted {
			DispatchQueue.global().async {
				doOnAuthenticationStarted()
			}
		}
	}

	func onChangePinStarted() {}

	func onAccessRights(error _: String?, accessRights: AccessRights?) {
		if accessRights == nil {
			return
		}

		if let doOnRequestAccessRights = doOnRequestAccessRights {
			DispatchQueue.global().async {
				doOnRequestAccessRights(accessRights!)
			}
		}
	}

	func onCertificate(certificateDescription _: CertificateDescription) {}

	func onInsertCard(error _: String?) {
		if let doOnRequestCard = doOnRequestCard {
			DispatchQueue.global().async {
				doOnRequestCard()
			}
		}
	}

	func onRecognizedCard(card _: Card?) {}
	func onPause(cause _: Cause) {}

	func onEnterPin(error _: String?, reader: Reader) {
		if let doOnRequestPin = doOnRequestPin {
			if let card = reader.card {
				DispatchQueue.global().async {
					doOnRequestPin(card)
				}
			}
		}
	}

	func onEnterNewPin(error _: String?, reader _: Reader) {}

	func onEnterPuk(error _: String?, reader _: Reader) {}

	func onEnterCan(error _: String?, reader _: Reader) {}

	func onAuthenticationCompleted(authResult: AuthResult) {
		if let doOnAuthenticationCompleted = doOnAuthenticationCompleted {
			DispatchQueue.global().async {
				doOnAuthenticationCompleted(authResult)
			}
		}
	}

	func onAuthenticationStartFailed(error _: String) {}

	func onChangePinCompleted(changePinResult _: ChangePinResult) {}

	func onStatus(workflowProgress _: WorkflowProgress) {}
	func onWrapperError(error _: AusweisApp2SDKWrapper.WrapperError) {
		if let doOnError = doOnError {
			DispatchQueue.global().async {
				doOnError()
			}
		}
	}

	func onBadState(error _: String) {}
	func onInternalError(error _: String) {}
}
