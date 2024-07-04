/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

// swiftlint:disable file_length

struct WeakCallbackRef: Equatable {
	static func == (lhs: WeakCallbackRef, rhs: WeakCallbackRef) -> Bool {
		if lhs.value == nil && rhs.value == nil {
			return true
		}

		if lhs.value == nil && rhs.value != nil {
			return false
		}

		if lhs.value != nil && rhs.value == nil {
			return false
		}

		return lhs.value! === rhs.value!
	}

	private(set) weak var value: WorkflowCallbacks?

	init(_ value: WorkflowCallbacks) {
		self.value = value
	}
}

/**
 WorkflowController is used to control the authentication and pin change workflow
 */
public class WorkflowController {
	public static let PinLength = 6
	public static let TransportPinLength = 5
	public static let PukLength = 10
	public static let CanLength = 6

	private var sdkConnection: SdkConnection
	var workflowCallbacks = [WeakCallbackRef]()

	init(withConnection sdkConnection: SdkConnection) {
		self.sdkConnection = sdkConnection

		self.sdkConnection.onConnected = { [weak self] in
			self?.callback { $0.onStarted() }
		}
		self.sdkConnection.onMessageReceived = { [weak self] message in
			self?.handleMessage(message: message)
		}
	}

	deinit {
		self.sdkConnection.onConnected = nil
		self.sdkConnection.onMessageReceived = nil
	}

	/**
	 Register callbacks with controller.

	 - Parameter callbacks: Callbacks to register.
	 */
	public func registerCallbacks(_ callbacks: WorkflowCallbacks) {
		let weakRef = WeakCallbackRef(callbacks)
		if workflowCallbacks.contains(where: { $0 == weakRef }) {
			print("\(callbacks) already registered")
			return
		}
		workflowCallbacks.append(weakRef)
	}

	/**
	 Unregister callbacks from controller.

	 - Parameter callbacks: Callbacks to unregister.
	 */
	public func unregisterCallbacks(_ callbacks: WorkflowCallbacks) {
		let weakRef = WeakCallbackRef(callbacks)
		workflowCallbacks.removeAll(where: { $0 == weakRef || $0.value == nil })
	}

	/**
	 Indicates that the WorkflowController is ready to be used.
	 When the WorkflowController is not in started state, other api calls will fail.
	 */
	public var isStarted: Bool {
		sdkConnection.isStarted
	}

	/**
	 Initialize the WorkflowController.

	 Before it is possible to use the WorkflowController it needs to be initialized.
	 Make sure to call this function and wait for the WorkflowCallbacks.onStarted callback before using it.
	 */
	public func start() {
		guard !isStarted else {
			print("WorkflowController already started")
			return
		}

		sdkConnection.start()
	}

	/**
	 Stop the WorkflowController.

	 When you no longer need the WorkflowController make sure to stop it to free up some resources.
	 */
	public func stop() {
		guard isStarted else {
			print("WorkflowController not started")
			return
		}

		sdkConnection.stop()
	}

	// swiftformat:sort:begin

	/**
	 Accept the current state.

	 If the SDK Wrapper calls WorkflowCallbacks.onAccessRights() the user needs to accept or deny them.
	 The workflow is paused until your application sends this command to accept the requested information.
	 If the user does not accept the requested information your application needs to call [cancelWorkflow]
	 to abort the whole workflow.

	 This command is allowed only if the SDK Wrapper asked for access rights via WorkflowCallbacks.onAccessRights().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 Note: This accepts the requested access rights as well as the provider's certificate since it is not possible to
	 accept one without the other.
	 */
	public func accept() {
		send(command: Accept())
	}

	/**
	 Cancel the running workflow.

	 If your application sends this command the SDK Wrapper will cancel the workflow.
	 You can send this command in any state of a running workflow to abort it.
	 */
	public func cancel() {
		send(command: Cancel())
	}

	/**
	 Resumes the workflow after a callback to WorkflowCallbacks.onPause().
	 */
	public func continueWorkflow() {
		send(command: ContinueWorkflow())
	}

	/**
	 Returns information about the requested access rights.

	 This command is allowed only if the SDK Wrapper called WorkflowController.onAccessRights() beforehand.
	  */
	public func getAccessRights() {
		send(command: GetAccessRights())
	}

	/**
	 Request the certificate of current authentication.

	 The SDK Wrapper will call WorkflowCallbacks.onCertificate() as an answer.
	 */
	public func getCertificate() {
		send(command: GetCertificate())
	}

	/**
	 Provides information about the utilized AusweisApp2.

	 The SDK Wrapper will call WorkflowCallbacks.onInfo() as an answer.
	 */
	public func getInfo() {
		send(command: GetInfo())
	}

	/**
	 Returns information about the requested reader.

	 If you explicitly want to ask for information of a known reader name you can request it with this command.

	 The SDK Wrapper will call WorkflowCallbacks.onReader() as an answer.

	 - Parameter name: Name of the reader.
	 */
	public func getReader(name: String) {
		send(command: GetReader(name: name))
	}

	/**
	 Returns information about all connected readers.

	 If you explicitly want to ask for information of all connected readers you can request it with this command.

	 The SDK Wrapper will call WorkflowCallbacks.onReaderList() as an answer.
	 */
	public func getReaderList() {
		send(command: GetReaderList())
	}

	/**
	 Request information about the current workflow and state of SDK.

	 The SDK Wrapper will call WorkflowCallbacks.onStatus() as an answer.
	 */
	public func getStatus() {
		send(command: GetStatus())
	}

	/**
	 Closes the iOS NFC dialog to allow user input.

	 This command is only permitted if a PIN/CAN/PUK is requested within a workflow.
	 */
	public func interrupt() {
		send(command: Interrupt())
	}

	/**
	 Set optional access rights

	 If the SDK Wrapper asks for specific access rights in WorkflowCallbacks.onAccessRights(),
	 you can modify the requested optional rights by setting a list of accepted optional rights here.
	 When the command is successful you get a callback to WorkflowCallbacks.onAccessRights()
	 with the updated access rights.

	 List of possible access rights are listed in AccessRight.

	 This command is allowed only if the SDK Wrapper asked for access rights via WorkflowCallbacks.onAccessRights().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter optionalAccessRights: List of enabled optional access rights. If the list is empty all
	 optional access rights are disabled.
	 */
	public func setAccessRights(_ optionalAccessRights: [AccessRight]) {
		send(command: SetAccessRights(chat: optionalAccessRights.map { $0.rawValue }))
	}

	/**
	 Set CAN of inserted card.

	 If the SDK Wrapper calls WorkflowCallbacks.onEnterCan() you need to call this function to unblock the last retry of
	 setPin().

	 The CAN is required to enable the last attempt of PIN input if the retryCounter is 1.
	 The workflow continues automatically with the correct CAN and the SDK Wrapper will call
	 WorkflowCallbacks.onEnterPin().
	 Despite the correct CAN being entered, the retryCounter remains at 1.
	 The CAN is also required, if the authentication terminal has an approved “CAN-allowed right”.
	 This allows the workflow to continue without an additional PIN.

	 If your application provides an invalid CAN the SDK Wrapper will call WorkflowCallbacks.onEnterCan() again.

	 This command is allowed only if the SDK Wrapper asked for a puk via WorkflowCallbacks.onEnterCan().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter can: The card access number (CAN) of the card. Must only contain 6 digits.
	 Must be nil if the current reader has a keypad.
	 */
	public func setCan(_ can: String?) {
		send(command: SetCan(value: can))
	}

	/**
	 Insert “virtual” card.

	 - Parameter name: Name of reader of which the Card shall be used.
	 - Parameter simulator: Optional specific Filesystem data for Simulator reader.
	 */
	public func setCard(name: String, simulator: Simulator? = nil) {
		send(command: SetCard(name: name, simulator: simulator))
	}

	/**
	 Set new PIN for inserted card.

	 If the SDK Wrapper calls WorkflowCallbacks.onEnterNewPin() you need to call this function to provide a new pin.

	 This command is allowed only if the SDK Wrapper asked for a new pin via WorkflowCallbacks.onEnterNewPin().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter newPin: The new personal identification number (PIN) of the card. Must only contain 6 digits.
	 Must be nil if the current reader has a keypad.
	 */
	public func setNewPin(_ newPin: String?) {
		send(command: SetNewPin(value: newPin))
	}

	/**
	 Set PIN of inserted card.

	 If the SDK Wrapper calls WorkflowCallbacks.onEnterPin() you need to call this function to unblock
	 the card with the PIN.

	 If your application provides an invalid PIN the SDK Wrapper will call WorkflowCallbacks.onEnterPin()
	 again with a decreased retryCounter.

	 If the value of retryCounter is 1 the SDK Wrapper will initially call WorkflowCallbacks.onEnterCan().
	 Once your application provides a correct CAN the SDK Wrapper will call WorkflowCallbacks.onEnterPin()
	 again with a retryCounter of 1.
	 If the value of retryCounter is 0 the SDK Wrapper will initially call WorkflowCallbacks.onEnterPuk().
	 Once your application provides a correct PUK the SDK Wrapper will call WorkflowCallbacks.onEnterPin()
	 again with a retryCounter of 3.

	 This command is allowed only if the SDK Wrapper asked for a pin via WorkflowCallbacks.onEnterPin().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter pin: The personal identification number (PIN) of the card. Must contain 5 (Transport PIN) or 6 digits.
	 Must be nil if the current reader has a keypad.
	 */
	public func setPin(_ pin: String?) {
		send(command: SetPin(value: pin))
	}

	/**
	 Set PUK of inserted card.

	 If the SDK Wrapper calls WorkflowCallbacks.onEnterPuk() you need to call this function to unblock setPin().

	 The workflow will automatically continue if the PUK was correct and the SDK Wrapper will call
	 WorkflowCallbacks.onEnterPin().
	 If the correct PUK is entered the retryCounter will be set to 3.

	 If your application provides an invalid PUK the SDK Wrapper will call WorkflowCallbacks.onEnterPuk() again.

	 If the SDK Wrapper calls WorkflowCallbacks.onEnterPuk() with Card.inoperative set true it is not possible to unblock
	 the PIN.
	 You will have to show a message to the user that the card is inoperative and the user should
	 contact the authority responsible for issuing the identification card to unblock the PIN.

	 This command is allowed only if the SDK Wrapper asked for a puk via WorkflowCallbacks.onEnterPuk().
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter puk: The personal unblocking key (PUK) of the card. Must only contain 10 digits.
	 Must be nil if the current reader has a keypad.
	 */
	public func setPuk(_ puk: String?) {
		send(command: SetPuk(value: puk))
	}

	/**
	 Starts an authentication workflow.

	 The WorkflowController will call WorkflowCallbacks.onAuthenticationStarted,
	 when the authentication is started. If the authentication could not be started,
	 you will get a callback to WorkflowCallbacks.onAuthenticationStartFailed().

	 After calling this method, the expected minimal workflow is:
	 WorkflowCallbacks.onAuthenticationStarted() is called.
	 When WorkflowCallbacks.onAccessRights() is called, accept it via accept().
	 WorkflowCallbacks.onInsertCard() is called, when the user has not yet placed the phone on the card.
	 When WorkflowCallbacks.onEnterPin() is called, provide the pin via setPin().
	 When the authentication workflow is finished WorkflowCallbacks.onAuthenticationCompleted() is called.

	 This command is allowed only if the SDK Wrapper has no running workflow.
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter withTcTokenUrl: URL to the TcToken.
	 - Parameter withDeveloperMode: Enable "Developer Mode" for test cards and disable some
	  security checks according to BSI TR-03124-1.
	 - Parameter userInfoMessages: Optional info messages to be display in the NFC dialog.
	 - Parameter withStatusMsgEnabled: True to enable automatic STATUS messages, which are
	  delivered by callbacks to WorkflowCallbacks.onStatus().
	 */
	public func startAuthentication(
		withTcTokenUrl tcTokenUrl: URL,
		withDeveloperMode developerMode: Bool = false,
		withUserInfoMessages userInfoMessages: AA2UserInfoMessages? = nil,
		withStatusMsgEnabled status: Bool = true
	) {
		send(command: RunAuth(tcTokenURL: tcTokenUrl.absoluteString,
		                      developerMode: developerMode,
		                      messages: userInfoMessages,
		                      status: status))
	}

	/**
	 Start a pin change workflow.

	 The WorkflowController will call WorkflowCallbacks.onChangePinStarted(),
	 when the pin change is started.

	 After calling this method, the expected minimal workflow is:
	 WorkflowCallbacks.onChangePinStarted] is called.
	 WorkflowCallbacks.onInsertCard() is called, when the user has not yet placed the phone on the card.
	 When WorkflowCallbacks.onEnterPin() is called, provide the pin via setPin().
	 When WorkflowCallbacks.onEnterNewPin() is called, provide the new pin via setNewPin().
	 When the pin workflow is finished, WorkflowCallbacks.onChangePinCompleted() is called.

	 This command is allowed only if the SDK Wrapper has no running workflow.
	 Otherwise you will get a callback to WorkflowCallbacks.onBadState().

	 - Parameter withStatusMsgEnabled: True to enable automatic STATUS messages, which are
	  delivered by callbacks to WorkflowCallbacks.onAuthenticationCompleted()
	 */
	public func startChangePin(
		withUserInfoMessages userInfoMessages: AA2UserInfoMessages? = nil,
		withStatusMsgEnabled status: Bool = true
	) {
		send(command: RunChangePin(messages: userInfoMessages, status: status))
	}

	// swiftformat:sort:end

	private func send<T: Command>(command: T) {
		guard isStarted else {
			let error = WrapperError(msg: command.cmd, error: "AusweisApp2 SDK Wrapper not started")
			callback { $0.onWrapperError(error: error) }
			return
		}

		DispatchQueue.global(qos: .userInitiated).async {
			self.sdkConnection.send(command: command)
		}
	}

	private func callback(callback: @escaping (WorkflowCallbacks) -> Void) {
		workflowCallbacks.removeAll(where: { $0.value == nil })

		for cbRef in workflowCallbacks {
			if let callbacks = cbRef.value {
				DispatchQueue.main.async { callback(callbacks) }
			}
		}
	}

	// swiftlint:disable cyclomatic_complexity function_body_length
	private func handleMessage(message: AA2Message) {
		switch message.msg {
		case AA2Messages.MsgAuth:
			if let error = message.error {
				callback { $0.onAuthenticationStartFailed(error: error) }
			} else if let authResult = message.getAuthResult() {
				callback { $0.onAuthenticationCompleted(authResult: authResult) }
			} else {
				callback { $0.onAuthenticationStarted() }
			}

		case AA2Messages.MsgAccessRights:
			callback { $0.onAccessRights(error: message.error, accessRights: message.getAccessRights()) }

		case AA2Messages.MsgBadState:
			let errorMessage = message.error ?? "Unknown bad state"
			callback { $0.onBadState(error: errorMessage) }

		case AA2Messages.MsgChangePin:
			if let success = message.success {
				let result = ChangePinResult(success: success, reason: message.reason)
				callback { $0.onChangePinCompleted(changePinResult: result) }
			} else {
				callback { $0.onChangePinStarted() }
			}

		case AA2Messages.MsgEnterPin:
			if let reader = message.getReader() {
				callback { $0.onEnterPin(error: message.error, reader: reader) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing reader object")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgEnterNewPin:
			if let reader = message.getReader() {
				callback { $0.onEnterNewPin(error: message.error, reader: reader) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing reader object")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgEnterPuk:
			if let reader = message.getReader() {
				callback { $0.onEnterPuk(error: message.error, reader: reader) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing reader object")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgEnterCan:
			if let reader = message.getReader() {
				callback { $0.onEnterCan(error: message.error, reader: reader) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing reader object")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgInsertCard:
			callback { $0.onInsertCard(error: message.error) }

		case AA2Messages.MsgCertificate:
			if let certificateDescription = message.getCertificateDescription() {
				callback { $0.onCertificate(certificateDescription: certificateDescription) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing or invalid certificateDescription")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgReader:
			callback { $0.onReader(reader: message.getReader()) }

		case AA2Messages.MsgReaderList:
			callback { $0.onReaderList(readers: message.getReaders()) }

		case AA2Messages.MsgInvalid, AA2Messages.MsgUnknowCommand:
			let error = WrapperError(msg: message.msg, error: message.error ?? "Unknown SDK Wrapper error")
			callback { $0.onWrapperError(error: error) }

		case AA2Messages.MsgInternalError:
			let errorMessage = message.error ?? "Unknown internal error"
			callback { $0.onInternalError(error: errorMessage) }

		case AA2Messages.MsgStatus:
			let workflowProgress = WorkflowProgress(workflow: message.workflow,
			                                        progress: message.progress,
			                                        state: message.state)
			callback { $0.onStatus(workflowProgress: workflowProgress) }

		case AA2Messages.MsgInfo:
			if let info = message.versionInfo {
				let versionInfo = VersionInfo(info: info)

				callback { $0.onInfo(versionInfo: versionInfo) }
			} else {
				let error = WrapperError(msg: message.msg, error: "Missing VersionInfo in message")
				callback { $0.onWrapperError(error: error) }
			}

		case AA2Messages.MsgPause:
			if let cause = message.cause {
				if let cause = Cause(rawValue: cause) {
					callback { $0.onPause(cause: cause) }
				} else {
					let error = WrapperError(msg: message.msg, error: "Failed to map cause \"\(cause)\" to Cause")
					callback { $0.onWrapperError(error: error) }
				}
				return
			}
			let error = WrapperError(msg: message.msg, error: "Missing cause object")
			callback { $0.onWrapperError(error: error) }

		default:
			print("Received unknown message \(message.msg)")
		}
	}

	// swiftlint:enable cyclomatic_complexity function_body_length
}
