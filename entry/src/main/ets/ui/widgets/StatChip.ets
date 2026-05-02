@Builder
export function StatChip(label: string, value: string) {
  Column() {
    Text(label)
      .fontSize(10)
      .fontColor(0xB3FFFFFF)
    Text(value)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .margin({ top: 2 })
  }
  .padding({ left: 8, right: 8, top: 6, bottom: 6 })
  .borderRadius(12)
  .backgroundColor(0x33213A63)
  .alignItems(HorizontalAlign.Center)
}
