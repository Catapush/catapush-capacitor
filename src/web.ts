import { WebPlugin } from '@capacitor/core';

import type { AllMessagesResponse, CatapushFile, CatapushMessageDelegate, CatapushStateDelegate, ICatapushPluginInternal, MessageIdParams, SendMessageParams } from './definitions';

export class CatapushPluginWeb
  extends WebPlugin
  implements ICatapushPluginInternal {

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  setCatapushMessageDelegate(_delegate: CatapushMessageDelegate): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  setCatapushStateDelegate(_delegate: CatapushStateDelegate): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async init(_options: { appId: string }): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async setUser(_options: { identifier: string, password: string }): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  async start(): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  async allMessages(): Promise<AllMessagesResponse> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async enableLog(_options: { enabled: boolean }): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async sendMessage(_options: SendMessageParams): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async getAttachmentUrlForMessage(_options: MessageIdParams): Promise<CatapushFile> {
    throw new Error('Web implementation not yet available.');
  }

  async resumeNotifications(): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  async pauseNotifications(): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  async enableNotifications(): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  async disableNotifications(): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async sendMessageReadNotificationWithId(_options: { id: string }): Promise<void> {
    throw new Error('Web implementation not yet available.');
  }

}
