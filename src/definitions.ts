// Type definitions for Catapush plugin
// Project: https://github.com/Catapush/catapush-capacitor
// Definitions by: Catapush Team <https://www.catapush.com/>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped
// 
// Copyright (c) Catapush SRL
// Licensed under the Apache License, Version 2.0.

import type { Plugin } from '@capacitor/core'


export interface ICatapushPlugin {

  /**
   * Sets a delegate that gets notified about new received or sent messages
   * @param delegate Object that implements the CatapushMessageDelegate interface callbacks
   */
  setCatapushMessageDelegate(delegate: CatapushMessageDelegate): Promise<void>

  /**
   * Sets a delegate that gets notified when the status of the SDK changes
   * @param delegate Object that implements the CatapushStateDelegate interface callbacks
   */
  setCatapushStateDelegate(delegate: CatapushStateDelegate): Promise<void>

  /**
   * Inits the Catapush native SDK.
   * @param options Your Catapush app ID needed to instantiate the iOS native SDK that can be retrieved from your Catapush dashboard.
   */
  init(
    options: { appId: string }
  ): Promise<void>

  /**
   * Sets the user credentials in the Catapush native SDK.
   * @param options Your Catapush user identifier and password.
   */
  setUser(
    options: {
      identifier: string,
      password: string,
    },
  ): Promise<void>

  /**
   * Start the Catapush native service.
   */
  start(): Promise<void>

  /**
   * Retrieve all the Catapush messages stored for the current user.
   */
  allMessages(): Promise<AllMessagesResponse>

  /**
   * Enable the Catapush native SDK logging.
   * @param options Enable or disable logging passing true or false in the enabled attribute.
   */
  enableLog(
    options: { enabled: boolean }
  ): Promise<void>

  /**
   * Send a message to the Catapush server for delivery.
   * @param options The attributes of the message to be delivered.
   */
  sendMessage(
    options: SendMessageParams
  ): Promise<void>

  /**
   * Get a message attachment URL.
   * @param options The ID of the message whose attachment needs to be retrieved.
   */
  getAttachmentUrlForMessage(
    options: MessageIdParams
  ): Promise<CatapushFile>

  /**
   * Resume displaying notification to the user.
   * This setting is not persisted across Catapush SDK/app restarts.
   * Android only.
   */
  resumeNotifications(): Promise<void>

  /**
   * Pause displaying notification to the user.
   * This setting is not persisted across Catapush SDK/app restarts.
   * Android only.
   */
  pauseNotifications(): Promise<void>

  /**
   * Enable the notification of messages to the user in the status bar.
   * This setting is persisted across Catapush SDK/app restarts.
   * Android only.
   */
  enableNotifications(): Promise<void>

  /**
   * Disable the notification of messages to the user in the status bar.
   * This setting is persisted across Catapush SDK/app restarts.
   * Android only.
   */
  disableNotifications(): Promise<void>

  /**
   * Send the read notification of a message to the Catapush server.
   * @param options The ID of the message to be marked as read.
   */
  sendMessageReadNotificationWithId(
    options: { id: string }
  ): Promise<void>

}

export interface ICatapushPluginInternal extends Plugin {

  init(
    options: { appId: string }
  ): Promise<void>

  setUser(
    options: {
      identifier: string,
      password: string,
    },
  ): Promise<void>

  start(): Promise<void>

  allMessages(): Promise<AllMessagesResponse>

  enableLog(
    options: { enabled: boolean }
  ): Promise<void>

  sendMessage(
    options: SendMessageParams
  ): Promise<void>

  getAttachmentUrlForMessage(
    options: MessageIdParams
  ): Promise<CatapushFile>

  resumeNotifications(): Promise<void>

  pauseNotifications(): Promise<void>

  enableNotifications(): Promise<void>

  disableNotifications(): Promise<void>

  sendMessageReadNotificationWithId(
    options: { id: string }
  ): Promise<void>

}

export interface AllMessagesResponse {
  messages: CatapushMessage[]
}

export interface SendMessageParams {
  body: string
  channel?: string
  replyTo?: string
  file?: CatapushFile
}

export interface MessageIdParams {
  id: string
}

export interface CatapushMessage {
  id: string
  sender: string
  body?: string
  subject?: string
  previewText?: string
  hasAttachment: boolean
  channel?: string
  replyToId?: string
  optionalData?: Map<string, any>
  receivedTime?: Date
  readTime?: Date
  sentTime?: Date
  state: CatapushMessageState
}

export interface CatapushFile {
  mimeType: string
  url: string
}

export interface CatapushError {
  event: string
  code: number
}

export const enum CatapushMessageState {
  RECEIVED = 'RECEIVED',
  RECEIVED_CONFIRMED = 'RECEIVED_CONFIRMED',
  OPENED = 'OPENED',
  OPENED_CONFIRMED = 'OPENED_CONFIRMED',
  NOT_SENT = 'NOT_SENT',
  SENT = 'SENT',
  SENT_CONFIRMED = 'SENT_CONFIRMED',
}

export const enum CatapushState {
  DISCONNECTED = 'DISCONNECTED',
  CONNECTING = 'CONNECTING',
  CONNECTED = 'CONNECTED',
}

export interface CatapushMessageDelegate {
  catapushMessageReceived(message: CatapushMessage): void
  catapushMessageSent(message: CatapushMessage): void
}

export interface CatapushStateDelegate {
  catapushStateChanged(state: CatapushState): void
  catapushHandleError(error: CatapushError): void
}
