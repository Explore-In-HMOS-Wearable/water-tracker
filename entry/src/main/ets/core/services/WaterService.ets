import { ComponentContent } from '@kit.ArkUI';

@Builder
function buildText() {
  Column() {
    Text(`${WaterService.instance().currentWater}/${WaterService.instance().waterTarget}`)
      .fontSize($r('app.float.water_target_font_size'))
      .fontWeight(FontWeight.Bold)
  }
  .margin({ top: 20 })
  .justifyContent(FlexAlign.Center)
}

@ObservedV2
export class WaterService {
  static _instance: WaterService;
  @Trace private _currentWater: number = 0;
  @Trace private _waterTarget: number = 0;
  @Trace header?: ComponentContent<Object>;

  setHeader(context: UIContext) {
    this.header = new ComponentContent(context, wrapBuilder(buildText));
  }

  get currentWater() {
    return this._currentWater;
  }

  get waterTarget() {
    return this._waterTarget;
  }

  setCurrentWater(value: number, context: UIContext) {
    this._currentWater = value;
    WaterService.instance().setHeader(context);

  }

  setWaterTarget(value: number, context: UIContext) {
    this._waterTarget = value;
    WaterService.instance().setHeader(context);
  }

  // Ensure only one instance of this Service has created
  static instance() {
    if (!WaterService._instance) {
      WaterService._instance = new WaterService();
    }
    return WaterService._instance;
  }
}

