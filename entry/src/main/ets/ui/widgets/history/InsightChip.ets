@Builder
export function InsightChip(title: string, value: string, tintColor: number = 0xFF6F8ED8) {
  Column({ space: 4 }) {
    Text(title)
      .fontSize(10)
      .fontColor(0xB3FFFFFF)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    Text(value)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .width('31%')
  .padding({ top: 8, bottom: 8, left: 6, right: 6 })
  .backgroundColor(0x332B446E)
  .border({ width: 1, color: tintColor })
  .borderRadius(10)
}
