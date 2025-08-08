import { WaterService } from '../../core/services/WaterService'
import { SingleWaterItem } from '../widgets/SingleWaterItem'
import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute, ComponentContent } from '@kit.ArkUI';
import { IndexViewModel } from '../viewmodels/IndexViewModel';
import { SetTargetButton } from '../widgets/SetTargetButton';


@Entry
@Component
struct Index {
  indexVm: IndexViewModel = new IndexViewModel()
  @State context: UIContext = this.getUIContext()

  aboutToAppear(): void {
    this.indexVm.aboutToAppear(this.context);
  }

  build() {
    Column() {
      Gauge({ value: WaterService.instance().currentWater, min: 0, max: WaterService.instance().waterTarget }) {
        ArcList({ initialIndex: 0, header: WaterService.instance().header }) {
          ArcListItem() {
            Row() {
              SingleWaterItem(250, $r('app.color.gradient_green'), 'app.media.bottle_250', 15, this.context, true);
              SingleWaterItem(180, $r('app.color.gradient_orange'), 'app.media.bottle_300', 20, this.context);
            }

          }
          .width('95%')
          .margin({ bottom: 10 });

          ArcListItem() {
            Row() {
              SingleWaterItem(420, $r('app.color.gradient_brown'), 'app.media.bottle_500', 20, this.context, true);
              SingleWaterItem(500, $r('app.color.gradient_blue'), 'app.media.bottle_1L', 20, this.context);
            };

          }
          .width('95%')
          .margin({ bottom: 20 });

          ArcListItem() {
            SetTargetButton(this.context);
          }
          .width('95%')

        }
        .width('100%')
        .height('100%')
        .borderRadius('466px')
        .focusable(true)
        .focusOnTouch(true)
        .defaultFocus(true)

      }
      .colors($r('app.color.gauge'))
      .width('100%')
      .height('100%')
      .indicator(null)
      .strokeWidth(18)
      .trackShadow({ radius: 3, offsetX: 3, offsetY: 3 })
      .value(WaterService.instance().currentWater)
      .align(Alignment.Center)

    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[$r('app.color.base_background_gradient_start'), 0.0],
        [$r('app.color.base_background_gradient_end'), 1],]
    })
  }
}