import { WaterService } from '../../core/services/WaterService';

@Builder
export function LogWaterPageBuilder() {
  LogWaterPage();
}

@Component
export struct LogWaterPage {
  @State amountMl: number = 250;
  @State infoText: string = 'Choose custom amount';
  @State infoTextColor: ResourceColor = 0xB3FFFFFF;
  @State isSubmitting: boolean = false;
  @Consume('NavPathStack') pageStack: NavPathStack;

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Text('Custom Drink')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(`${this.amountMl}ml`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          Slider({ style: SliderStyle.OutSet, min: 50, max: 1200, value: this.amountMl, step: 10 })
            .showSteps(true)
            .onChange((value: number) => {
              this.amountMl = Math.max(50, Math.min(1200, Math.floor(value)));
            })
            .width('86%')

          Row({ space: 8 }) {
            this.stepButton('-50', -50)
            this.stepButton('+50', 50)
            this.stepButton('+100', 100)
          }

          Button(this.isSubmitting ? 'Logging...' : 'Log Drink')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(this.isSubmitting ? 0x664D6385 : 0xFF3E7BFA)
            .borderRadius(12)
            .width('72%')
            .height(42)
            .onClick(() => {
              if (this.isSubmitting) {
                return;
              }
              if (this.amountMl < 50 || this.amountMl > 1200) {
                this.infoText = 'Amount must stay between 50ml and 1200ml';
                this.infoTextColor = 0xFFFFC98B;
                return;
              }
              this.isSubmitting = true;
              WaterService.instance().addWater(this.amountMl);
              this.infoText = `Added ${this.amountMl}ml. Returning...`;
              this.infoTextColor = 0xFF9FF0B0;
              this.isSubmitting = false;
              setTimeout(() => {
                this.pageStack.pop({ shouldRefresh: true });
              }, 900);
            })

          Button('Cancel')
            .fontSize(12)
            .fontColor(0xFFEAF1FF)
            .backgroundColor(0x334D6385)
            .borderRadius(12)
            .width('56%')
            .height(36)
            .onClick(() => {
              this.pageStack.pop();
            })

          Text(this.infoText)
            .fontSize(10)
            .fontColor(this.infoTextColor)
        }
        .width('100%')
        .padding({ top: 18, bottom: 26 })
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

  @Builder
  private stepButton(label: string, delta: number) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor(Color.White)
    }
    .width(52)
    .height(34)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(0x40467AC8)
    .borderRadius(10)
    .onClick(() => {
      this.amountMl = Math.max(50, Math.min(1200, this.amountMl + delta));
    })
  }
}
