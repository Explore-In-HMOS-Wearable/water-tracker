@Component
export struct SetTargetButton {
  @Consume('NavPathStack') pageStack: NavPathStack;
  private readonly setTargetRouteName: string = 'set-target';

  build() {
    Row() {
      Text('Set Target')
        .fontSize($r('app.float.set_target_button_font_size'))
        .fontColor(Color.White)
        .textAlign(TextAlign.End)
        .lineHeight(18)
        .fontWeight(FontWeight.Bold)

      Image($r('app.media.arrow_front'))
        .width(16)
        .height(16)
        .fillColor(Color.White)
    }
    .borderRadius(6)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 8, right: 8 })
    .width('70%')
    .height(45)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [[$r('app.color.gradient_target_button_start'), 0.0],
        [$r('app.color.gradient_target_button_end'), 1]]
    })
    .onClick(() => {
      this.pageStack.pushPath({ name: this.setTargetRouteName, param: null });
    })
  }
}
