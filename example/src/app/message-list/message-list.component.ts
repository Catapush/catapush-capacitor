// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ChangeDetectorRef, Component, HostListener } from '@angular/core'
import { FileChooser } from '@ionic-native/file-chooser'
import type { CatapushError, CatapushFile, CatapushMessage, CatapushState, AllMessagesResponse } from "catapush-capacitor-sdk";
import { CatapushPlugin } from "catapush-capacitor-sdk"


@Component({
  selector: 'app-message-list',
  templateUrl: './message-list.component.html',
  styleUrls: ['./message-list.component.scss']
})
export class MessageListComponent {
  messages: CatapushMessage[] = []
  attachments: Map<string, CatapushFile> = new Map<string, CatapushFile>()
  newMessageBody = ''

  constructor(private changeDetectorRef: ChangeDetectorRef) {
    this.loadMessages()

    CatapushPlugin.pauseNotifications()
      .then(() => console.log('Catapush pauseNotifications success'))
      .catch((reason) => console.log('Catapush pauseNotifications failed: ' + reason))


    CatapushPlugin.setCatapushMessageDelegate({
      catapushMessageReceived: (_message: CatapushMessage) => this.loadMessages(),
      catapushMessageSent: (_message: CatapushMessage) => this.loadMessages()
    })

    CatapushPlugin.setCatapushStateDelegate({
      catapushStateChanged: (state: CatapushState) => console.log("Catapush state is now: " + state),
      catapushHandleError: (error: CatapushError) => console.error("Catapush error. code: " + error.code + ", description: " + error.event),
    })
  }

  @HostListener('window:beforeunload', ['$event'])
  onBeforeUnload(): void {
    CatapushPlugin.resumeNotifications()
      .then(() => console.log('Catapush resumeNotifications success'))
      .catch((reason) => console.log('Catapush resumeNotifications failed: ' + reason))

    CatapushPlugin.setCatapushMessageDelegate(null)
    CatapushPlugin.setCatapushStateDelegate(null)
  }

  trackById(index: number, data: any): number {
    return data.id + data.state
  }

  loadMessages(): void {
    CatapushPlugin.allMessages()
      .then((response: AllMessagesResponse) => {
        console.log('Catapush allMessages success')
        response.messages.forEach(message => {
          if (message.hasAttachment) {
            this.preloadAttachment(message)
          }
        })
        this.messages = response.messages.reverse()
        this.changeDetectorRef.detectChanges()
      },
        (message: string) => {
          console.log('Catapush allMessages failed: ' + message)
        }
      )
  }

  preloadAttachment(message: CatapushMessage): void {
    if (this.attachments.has(message.id)) {
      return
    }
    CatapushPlugin.getAttachmentUrlForMessage({ id: message.id })
      .then((attachment: CatapushFile) => {
        this.attachments.set(message.id, attachment)
        this.changeDetectorRef.detectChanges()
        console.log('Catapush getAttachmentUrlForMessage success: ' + attachment.url)
      })
      .catch((reason) => {
        console.log('Catapush getAttachmentUrlForMessage failed: ' + reason)
      })
  }

  sendMessage(): void {
    CatapushPlugin.sendMessage({ body: this.newMessageBody })
      .then(() => {
        this.newMessageBody = ''
        this.loadMessages()
        console.log('Catapush sendMessage success')
      })
      .catch((reason) => {
        console.log('Catapush sendMessage failed: ' + reason)
      })
  }

  sendAttachment(): void {
    FileChooser.open({ mime: 'image/*' })
      .then(uri => {
        CatapushPlugin.sendMessage({ body: '', file: { mimeType: '', url: uri } })
          .then(() => {
            this.newMessageBody = ''
            this.loadMessages()
            console.log('Catapush sendAttachment success')
          })
          .catch((reason) => {
            console.log('Catapush sendAttachment failed: ' + reason)
          })
      })
      .catch(e => console.log('Catapush file choice failed: ' + e))
  }

}