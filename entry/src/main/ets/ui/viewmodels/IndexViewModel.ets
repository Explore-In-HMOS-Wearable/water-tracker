import { BaseViewModel } from '../../core/services/BaseViewModel';
import { WaterService } from '../../core/services/WaterService';

@ObservedV2
export class IndexViewModel extends BaseViewModel {
  @Trace isInited: boolean = false;
  waterService: WaterService = WaterService.instance();

  constructor() {
    super();
    this.initVm();
  }

  initVm() {
    this.isInited = true;
  }

  aboutToAppear(context: UIContext) {
    if (this.waterService.waterTarget === 0) {
      WaterService.instance().setWaterTarget(2000, context)
    }

    this.waterService.setHeader(context)
  }
}
