import { WaterService } from '../../core/services/WaterService'

@Builder
export function SingleWaterItem(value: number,
  color: ResourceColor,
  iconPath: string,
  iconSize: number,
  context: UIContext,
  isLeft: boolean = false,
) {
  Row() {
    Image($r(iconPath))
      .width(iconSize)
      .height(iconSize)
      .fillColor(Color.White)
      .margin({ right: 4 })

    Text(value.toString())
      .fontSize($r(`app.float.water_item_font_size`))
      .fontColor(Color.White)
      .textAlign(TextAlign.End)
      .lineHeight(18)

    Text('ml')
      .fontSize($r(`app.float.water_item_ml_font_size`))
      .fontColor(Color.White)
      .textAlign(TextAlign.End)
      .lineHeight(18)
  }
  .backgroundColor(color)
  .borderRadius(6)
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Center)
  .margin({ right: isLeft ? 10 : 0 })
  .width('35%')
  .height('65px')
  .linearGradient({
    direction: GradientDirection.Bottom,
    colors: [[color, 0.0],
      [0x99070738, 0.8]]
  })
  .onClick(() => {
    WaterService.instance().setCurrentWater(WaterService.instance().currentWater + value, context);
  })
}