/**
 * Copyright (c) 2020-2023 Governikus GmbH & Co. KG, Germany
 */

import Foundation

/**
 Authentication workflow callbacks.

 You need to register them with the  WorkflowController

 See WorkflowController.registerCallbacks
 */
public protocol WorkflowCallbacks: AnyObject {
	// swiftformat:sort:begin

	/**
	 Access rights requested in response to an authentication.

	 This function will be called once the authentication is started by WorkflowController.startAuthentication()
	 and the SDK Wrapper got the certificate from the service.

	 Accept (WorkflowController.accept()) the rights to continue with the workflow or completely
	 abort the workflow with WorkflowController.cancelWorkflow().

	 It is also possible to change the optional rights via WorkflowController.setAccessRights().

	 - Parameter error: Optional error message if the call to WorkflowController.setAccessRights() failed.
	 - Parameter accessRights: Requested access rights.
	 */
	func onAccessRights(error: String?, accessRights: AccessRights?)

	/**
	 Provides information about the supported API level of the employed AusweisApp2

	 Response to a call to WorkflowController.getApiLevel() and WorkflowController.setApiLevel().

	 - Parameter error: Optional error message if WorkflowController.setApiLevel() failed.
	 - Parameter apiLevel: Contains information about the supported and employed API level.
	 */
	func onApiLevel(error: String?, apiLevel: ApiLevel?)
	/**
	 Indicates that the authentication workflow is completed.

	 The authResult will contain a refresh url or in case of an error a communication error address.
	 You can check the state of the authentication, by looking for the AuthResult.error() field, null on success.

	 - Parameter authResult: Result of the authentication
	 */
	func onAuthenticationCompleted(authResult: AuthResult)

	/**
	 An authentication has been started via WorkflowController.startAuthentication().

	 The next callback should be onAccessRights() or onAuthenticationCompleted() if the authentication immediately results
	 in an error.
	 */
	func onAuthenticationStarted()

	/**
	 An authentication could not be started.
	 This is different from an authentication that was started but failed during the process.

	 - Parameter error: Error message about why the authentication could not be started.
	 */
	func onAuthenticationStartFailed(error: String)

	/**
	 Called if the sent command is not allowed within the current workflow

	 - Parameter error: Error message which SDK command failed.
	 */
	func onBadState(error: String)

	/**
	 Provides information about the used certificate.

	 Response of a call to WorkflowController.getCertificate().

	 - Parameter certificateDescription: Requested certificate.
	 */
	func onCertificate(certificateDescription: CertificateDescription)

	/**
	 Indicates that the pin change workflow is completed.

	 - Parameter changePinResult: Result of the pin change
	 */
	func onChangePinCompleted(changePinResult: ChangePinResult?)

	/**
	 A pin change has been started via WorkflowController.startChangePin().
	 */
	func onChangePinStarted()

	/**
	 Indicates that a CAN is required to continue workflow.

	 A CAN is needed to unlock the id card, provide it with WorkflowController.setCan().

	 - Parameter error: Optional error message if the last call to WorkflowController.setCan() failed.
	 - Parameter reader: Information about the used card and card reader.
	 */
	func onEnterCan(error: String?, reader: Reader)

	/**
	 Indicates that a new PIN is required to continue the workflow.

	 A new PIN is needed fin response to a pin change, provide it with WorkflowController.setNewPin().

	 - Parameter error: Optional error message if the last call to WorkflowController.setNewPin() failed.
	 - Parameter reader: Information about the used card and card reader.
	 */
	func onEnterNewPin(error: String?, reader: Reader)

	/**
	 Indicates that a PIN is required to continue the workflow.

	 A PIN is needed to unlock the id card, provide it with WorkflowController.setPin().

	 - Parameter error: Optional error message if the last call to WorkflowController.setPin() failed.
	 - Parameter reader: Information about the used card and card reader.
	 */
	func onEnterPin(error: String?, reader: Reader)

	/**
	 Indicates that a PUK is required to continue the workflow.

	 A PUK is needed to unlock the id card, provide it with WorkflowController.setPuk().

	 - Parameter error: Optional error message if the last call to WorkflowController.setPuk() failed.
	 - Parameter reader: Information about the used card and card reader.
	 */
	func onEnterPuk(error: String?, reader: Reader)

	/**
	 Provides information about the AusweisApp2 that is used in the SDK Wrapper.

	 Response to a call to WorkflowController.getInfo().

	 - Parameter versionInfo: Holds information about the currently utilized AusweisApp2.
	 */
	func onInfo(versionInfo: VersionInfo)

	/**
	 Indicates that the workflow now requires a card to continue.

	 If your application receives this message it should show a hint to the user.
	 After the user inserted a card the workflow will automatically continue, unless the eID functionality is disabled.
	 In this case, the workflow will be paused until another card is inserted.
	 If the user already inserted a card this function will not be called at all.

	 - Parameter error: Optional detailed error message if the previous call to WorkflowController.setCard() failed.
	 */
	func onInsertCard(error: String?)

	/**
	 Called if an error within the AusweisApp2 SDK occurred. Please report this as it indicates a bug.

	 - Parameter error: Information about the error.
	 */
	func onInternalError(error: String)

	/**
	 A specific reader was recognized or has vanished. Also called as a response to WorkflowController.getReader().

	 - Parameter reader: Recognized or vanished reader, might be nil if an unknown reader was requested
	  in getReader().
	 */
	func onReader(reader: Reader?)

	/**
	 Called as a reponse to WorkflowController.getReaderList().

	 - Parameter readers: Optional list of present readers (if any).
	 */
	func onReaderList(readers: [Reader]?)

	/**
	 WorkflowController has successfully been initialized.
	 */
	func onStarted()

	/**
	 Provides information about the current workflow and state. This callback indicates if a
	 workflow is in progress or the workflow is paused. This can occur if the AusweisApp2 needs
	 additional data like ACCESS_RIGHTS or INSERT_CARD.

	 - Parameter workflowProgress: Holds information about the current workflow progress.
	 */
	func onStatus(workflowProgress: WorkflowProgress)

	/**
	 Indicates that an error within the SDK Wrapper has occurred.

	 This might be called if there was an error in the workflow.

	 - Parameter error: Contains information about the error.
	 */
	func onWrapperError(error: WrapperError)

	// swiftformat:sort:end
}
