import type { PluginListenerHandle } from '@capacitor/core'
import { registerPlugin } from '@capacitor/core'

import type { AllMessagesResponse, CatapushError, CatapushFile, CatapushMessageDelegate, CatapushState, CatapushStateDelegate, ICatapushPluginInternal, ICatapushPlugin, MessageIdParams, SendMessageParams } from './definitions'


class CatapushPluginImpl implements ICatapushPlugin {

  catapushBasePlugin = registerPlugin<ICatapushPluginInternal>('CatapushPlugin', {
    web: () => import('./web').then(m => new m.CatapushPluginWeb()),
  })


  messageDelegate: CatapushMessageDelegate | null = null
  stateDelegate: CatapushStateDelegate | null = null

  messageHandlers: PluginListenerHandle[] = []
  stateHandlers: PluginListenerHandle[] = []


  setCatapushMessageDelegate = async (delegate: CatapushMessageDelegate) => {
    if (this.messageDelegate != null) {
      this.messageHandlers.forEach(element => {
        element.remove()
      })
      this.messageHandlers = []
    }

    this.messageDelegate = delegate

    if (this.messageDelegate != null) {
      await this.catapushBasePlugin.addListener(
        'Catapush#catapushMessageReceived',
        (info: any) => {
          this.messageDelegate?.catapushMessageReceived(info.message)
        },
      ).then(handler => this.messageHandlers.push(handler))
      await this.catapushBasePlugin.addListener(
        'Catapush#catapushMessageSent',
        (info: any) => {
          this.messageDelegate?.catapushMessageSent(info.message)
        },
      ).then(handler => this.messageHandlers.push(handler))
    }
  }

  setCatapushStateDelegate = async (delegate: CatapushStateDelegate) => {
    if (this.stateDelegate != null) {
      this.stateHandlers.forEach(element => {
        element.remove()
      })
      this.stateHandlers = []
    }

    this.stateDelegate = delegate

    if (this.stateDelegate != null) {
      await this.catapushBasePlugin.addListener(
        'Catapush#catapushStateChanged',
        (info: any) => {
          const state: CatapushState = (info.status as string).toUpperCase() as CatapushState
          this.stateDelegate?.catapushStateChanged(state)
        },
      ).then(handler => this.stateHandlers.push(handler))
      await this.catapushBasePlugin.addListener(
        'Catapush#catapushHandleError',
        (info: any) => {
          const error: CatapushError = { event: info.event, code: info.code }
          this.stateDelegate?.catapushHandleError(error)
        },
      ).then(handler => this.stateHandlers.push(handler))
    }
  }

  init(options: { appId: string }): Promise<void> {
    return this.catapushBasePlugin.init(options)
  }

  setUser(options: { identifier: string; password: string }): Promise<void> {
    return this.catapushBasePlugin.setUser(options)
  }

  start(): Promise<void> {
    return this.catapushBasePlugin.start()
  }

  allMessages(): Promise<AllMessagesResponse> {
    return this.catapushBasePlugin.allMessages()
  }

  enableLog(options: { enabled: boolean }): Promise<void> {
    return this.catapushBasePlugin.enableLog(options)
  }

  sendMessage(options: SendMessageParams): Promise<void> {
    return this.catapushBasePlugin.sendMessage(options)
  }

  getAttachmentUrlForMessage(options: MessageIdParams): Promise<CatapushFile> {
    return this.catapushBasePlugin.getAttachmentUrlForMessage(options)
  }

  resumeNotifications(): Promise<void> {
    return this.catapushBasePlugin.resumeNotifications()
  }

  pauseNotifications(): Promise<void> {
    return this.catapushBasePlugin.pauseNotifications()
  }

  enableNotifications(): Promise<void> {
    return this.catapushBasePlugin.enableNotifications()
  }

  disableNotifications(): Promise<void> {
    return this.catapushBasePlugin.disableNotifications()
  }

  sendMessageReadNotificationWithId(options: { id: string }): Promise<void> {
    return this.catapushBasePlugin.sendMessageReadNotificationWithId(options)
  }

  addListener(eventName: string, listenerFunc: (...args: any[]) => any): Promise<PluginListenerHandle> {
    return this.catapushBasePlugin.addListener(eventName, listenerFunc)
  }

  removeAllListeners(): Promise<void> {
    return this.catapushBasePlugin.removeAllListeners()
  }

}

const CatapushPlugin = new CatapushPluginImpl()

export * from './definitions'
export { CatapushPlugin }
