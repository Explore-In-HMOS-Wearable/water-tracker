import { StatChip } from './StatChip';

@Builder
export function ProgressHeader(totalText: string, remainingText: string, statusText: string, completionText: string,
  lastActionText: string, reminderText: string, showReminderChip: boolean = true, statusColor: number = 0xFF9BE8AF) {
  Column({ space: 8 }) {
    Text(totalText)
      .fontSize(21)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
    Text(remainingText)
      .fontSize(12)
      .fontColor(0xD8FFFFFF)
      .textAlign(TextAlign.Center)
    Text(statusText)
      .fontSize(11)
      .fontColor(statusColor)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })

    if (showReminderChip) {
      Row({ space: 8 }) {
        StatChip('Completion', completionText)
        StatChip('Reminder', reminderText)
      }
      .justifyContent(FlexAlign.Center)
    } else {
      Row() {
        StatChip('Completion', completionText)
      }
      .justifyContent(FlexAlign.Center)
    }

    Text(lastActionText)
      .fontSize(10)
      .fontColor(0xB3FFFFFF)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('88%')
      .textAlign(TextAlign.Center)
  }
  .margin({ top: 14, bottom: 4 })
  .alignItems(HorizontalAlign.Center)
  .width('100%')
}
