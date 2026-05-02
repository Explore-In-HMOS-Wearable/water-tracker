import { HistoryDaySummary } from '../../../core/models/HydrationModels';

@Builder
export function HistoryDayRow(item: HistoryDaySummary, isToday: boolean = false) {
  Column({ space: 6 }) {
    Row() {
      Text(isToday ? 'Today' : item.dateKey)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xFFEAF1FF)
      Text(item.isGoalReached ? '✓ Complete' : `${Math.floor(item.completionRatio * 100)}%`)
        .fontSize(10)
        .fontColor(item.isGoalReached ? 0xFF8CF0A8 : 0xFFFFD780)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')

    Stack({ alignContent: Alignment.Start }) {
      Row()
        .width('100%')
        .height(6)
        .backgroundColor(0x334D6385)
        .borderRadius(6)
      Row()
        .width(`${Math.max(6, Math.floor(item.completionRatio * 100))}%`)
        .height(6)
        .backgroundColor(item.isGoalReached ? 0xFF4DD078 : 0xFF4A88FF)
        .borderRadius(6)
    }

    Text(`${item.totalIntakeMl}ml / ${item.targetMl}ml · ${item.entryCount} drinks`)
      .fontSize(10)
      .fontColor(0xD8FFFFFF)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .width('100%')
  .padding(10)
  .backgroundColor(0x262A4266)
  .borderRadius(12)
}
