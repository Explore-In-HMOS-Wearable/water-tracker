@Builder
export function ActionButton(label: string, onTap: () => void, width: string = '42%') {
  Row() {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
  }
  .height(40)
  .width(width)
  .borderRadius(12)
  .justifyContent(FlexAlign.Center)
  .backgroundColor(0x44487CCC)
  .onClick(() => {
    onTap();
  })
}
