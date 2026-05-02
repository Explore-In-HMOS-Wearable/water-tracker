import { WaterService } from '../../core/services/WaterService';

@Builder
export function SetTargetPageBuilder() {
  SetTargetPage();
}

@Component
export struct SetTargetPage {
  @State value: number = 0;
  @State showWarningText: boolean = false;
  @Consume('NavPathStack') pageStack: NavPathStack;

  aboutToAppear(): void {
    this.value = WaterService.instance().waterTarget / 100;
  }

  isButtonActive(): boolean {
    return (this.value * 100) !== WaterService.instance().waterTarget
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text((this.value * 100).toString() + 'ml')
            .fontSize($r('app.float.water_target_font_size'))
            .fontColor(Color.White)
            .textAlign(TextAlign.End)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })

          Slider({ style: SliderStyle.InSet, value: this.value })
            .showSteps(true)
            .onChange((value: number) => {
              this.value = value;
              if (this.isButtonActive()) {
                this.showWarningText = false
              }
            }).margin({ bottom: 10 });

          Row() {
            Text('Set')
              .fontSize(18)
              .fontColor(Color.White)
              .textAlign(TextAlign.End)
              .lineHeight(18)
              .fontWeight(FontWeight.Bold)
          }
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[this.isButtonActive() ? $r('app.color.gradient_target_button_start') : 0x664D6385, 0.0],
              [this.isButtonActive() ? $r('app.color.gradient_target_button_end') : 0x664D6385, 1]]
          })
          .borderRadius(6)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('70%')
          .height(45)
          .onClick(() => {
            if (this.isButtonActive()) {
              WaterService.instance().setDailyTarget(this.value * 100)
              this.pageStack.pop({ shouldRefresh: true })
            } else {
              this.showWarningText = true;
            }
          })

          if (this.showWarningText) {
            Text($r('app.string.warning'))
              .fontSize($r('app.float.warning_font_size'))
              .fontColor(0xFFFFA2A2)
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
              .width('50%')
          }
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .padding({ top: 14, bottom: 24 })
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[$r('app.color.base_background_gradient_start'), 0.0],
          [$r('app.color.base_background_gradient_end'), 1]]
      })
    }
    .hideTitleBar(true)
  }
}
