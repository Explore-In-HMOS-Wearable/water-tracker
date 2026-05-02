import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { computeHydrationMetrics, HydrationState } from '../core/models/HydrationModels';
import { PreferencesStorageService } from '../core/services/storage/PreferencesStorageService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'EntryFormAbility';

interface HydrationWidgetPayload {
  intakeMl: number;
  targetMl: number;
  progressPercent: number;
  progressText: string;
  goalReached: boolean;
  statusText: string;
}

export default class EntryFormAbility extends FormExtensionAbility {
  private repository: PreferencesStorageService = new PreferencesStorageService();

  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(this.buildHydrationPayload());
  }

  onUpdateForm(formId: string): void {
    const payload: HydrationWidgetPayload = this.buildHydrationPayload();
    const data: formBindingData.FormBindingData = formBindingData.createFormBindingData(payload);
    formProvider.updateForm(formId, data).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'onUpdateForm failed, code: %{public}d, message: %{public}s', error.code, error.message);
    });
  }

  private buildHydrationPayload(): HydrationWidgetPayload {
    const defaultPayload: HydrationWidgetPayload = {
      intakeMl: 0,
      targetMl: 2000,
      progressPercent: 0,
      progressText: '0%',
      goalReached: false,
      statusText: 'Keep going'
    };

    try {
      this.repository.initialize(this.context);
      if (!this.repository.isUsable()) {
        return defaultPayload;
      }
      const state: HydrationState = this.repository.ensureCurrentDay(this.repository.loadState(), this.getTodayKey());
      this.repository.saveState(state);
      const metrics = computeHydrationMetrics(state.currentDay);
      const percent: number = Math.floor(metrics.completionRatio * 100);
      const payload: HydrationWidgetPayload = {
        intakeMl: state.currentDay.totalIntakeMl,
        targetMl: state.currentDay.targetMl,
        progressPercent: percent,
        progressText: `${percent}%`,
        goalReached: metrics.isGoalReached,
        statusText: metrics.isGoalReached ? 'Goal reached' : 'Keep going'
      };
      return payload;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'buildHydrationPayload failed: %{public}s', JSON.stringify(error));
      return defaultPayload;
    }
  }

  private getTodayKey(): string {
    const today: Date = new Date();
    const month: string = `${today.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${today.getDate()}`.padStart(2, '0');
    return `${today.getFullYear()}-${month}-${day}`;
  }
}
