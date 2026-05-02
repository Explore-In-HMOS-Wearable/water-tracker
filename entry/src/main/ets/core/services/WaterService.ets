import {
  computeHydrationMetrics,
  createDefaultHydrationState,
  DailyHydrationRecord,
  HistoryDaySummary,
  HydrationDerivedMetrics,
  HydrationEntry,
  HydrationInsights,
  HydrationSettings,
  ReminderSettings,
  HydrationState
} from '../models/HydrationModels';
import { HydrationRepository } from '../repositories/HydrationRepository';
import { PreferencesStorageService } from './storage/PreferencesStorageService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ReminderCapabilityState, ReminderService } from './ReminderService';
import { formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TAG: string = 'WaterService';

interface HydrationWidgetPayload {
  intakeMl: number;
  targetMl: number;
  progressPercent: number;
  progressText: string;
  goalReached: boolean;
  statusText: string;
}

@ObservedV2
export class WaterService {
  static _instance: WaterService;
  @Trace private _state: HydrationState = createDefaultHydrationState(this.getTodayKey());
  @Trace private initialized: boolean = false;
  private repository: HydrationRepository = new PreferencesStorageService();
  private reminderService: ReminderService = ReminderService.instance();
  private appContext?: Context;

  initialize(context: Context): void {
    this.appContext = context;
    this.reminderService.initialize(context);
    this.tryInitializeRepository();
  }

  get currentWater(): number {
    return this._state.currentDay.totalIntakeMl;
  }

  get waterTarget(): number {
    return this._state.settings.dailyTargetMl;
  }

  get todayRecord(): DailyHydrationRecord {
    return this._state.currentDay;
  }

  get metrics(): HydrationDerivedMetrics {
    return computeHydrationMetrics(this._state.currentDay);
  }

  get state(): HydrationState {
    return this._state;
  }

  get quickAddPresets(): number[] {
    return [...this._state.settings.quickAddPresetsMl];
  }

  get reminderSettings(): ReminderSettings {
    return this._state.settings.reminder;
  }

  get lastEntry(): HydrationEntry | undefined {
    const entries: HydrationEntry[] = this._state.currentDay.entries;
    if (entries.length === 0) {
      return undefined;
    }
    return entries[entries.length - 1];
  }

  refreshForToday(): void {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    this.reconcileReminderState();
    this.refreshWidgetSnapshot();
  }

  addWater(amountMl: number): void {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    const safeAmount: number = Math.max(0, Math.floor(amountMl));
    if (safeAmount === 0) {
      return;
    }
    const entryTimestamp: number = Date.now();
    const newTotal: number = this._state.currentDay.totalIntakeMl + safeAmount;
    this._state.currentDay.totalIntakeMl = newTotal;
    this._state.currentDay.entries = [...this._state.currentDay.entries, {
      id: `${entryTimestamp}`,
      amountMl: safeAmount,
      timestamp: entryTimestamp
    }];
    this.repository.saveState(this._state);
    this.reconcileReminderState();
    this.refreshWidgetSnapshot();
  }

  undoLastEntry(): boolean {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    const entries: HydrationEntry[] = this._state.currentDay.entries;
    if (entries.length === 0) {
      return false;
    }
    const lastEntry: HydrationEntry = entries[entries.length - 1];
    this._state.currentDay.entries = entries.slice(0, entries.length - 1);
    this._state.currentDay.totalIntakeMl = Math.max(0, this._state.currentDay.totalIntakeMl - lastEntry.amountMl);
    this.repository.saveState(this._state);
    this.reconcileReminderState();
    this.refreshWidgetSnapshot();
    return true;
  }

  setDailyTarget(value: number): void {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    const safeTarget: number = Math.max(100, Math.floor(value));
    this._state.settings.dailyTargetMl = safeTarget;
    this._state.currentDay.targetMl = safeTarget;
    this.repository.saveState(this._state);
    this.refreshWidgetSnapshot();
  }

  updateSettings(targetMl: number, quickPresets: number[], reminder: ReminderSettings): void {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    const safeTarget: number = Math.max(100, Math.floor(targetMl));
    const sanitizedPresets: number[] = quickPresets.map((item: number) => Math.floor(item))
      .filter((item: number) => item > 0)
      .slice(0, 4);

    const settings: HydrationSettings = {
      dailyTargetMl: safeTarget,
      quickAddPresetsMl: sanitizedPresets.length > 0 ? sanitizedPresets : this._state.settings.quickAddPresetsMl,
      reminder: {
        enabled: reminder.enabled,
        intervalMinutes: Math.max(15, Math.floor(reminder.intervalMinutes)),
        startHour: this.asHour(reminder.startHour, this._state.settings.reminder.startHour),
        endHour: this.asHour(reminder.endHour, this._state.settings.reminder.endHour),
        quietHoursEnabled: reminder.quietHoursEnabled,
        quietStartHour: this.asHour(reminder.quietStartHour, this._state.settings.reminder.quietStartHour),
        quietEndHour: this.asHour(reminder.quietEndHour, this._state.settings.reminder.quietEndHour)
      }
    };
    this._state.settings = settings;
    this._state.currentDay.targetMl = safeTarget;
    this.repository.saveState(this._state);
    this.reconcileReminderState();
    this.refreshWidgetSnapshot();
  }

  getReminderCapabilityState(): ReminderCapabilityState {
    return this.reminderService.getCapabilityState();
  }

  refreshReminderCapabilityState(): Promise<ReminderCapabilityState> {
    return this.reminderService.refreshNotificationStatus();
  }

  requestReminderEnablement(): Promise<ReminderCapabilityState> {
    return this.reminderService.requestEnableNotifications();
  }

  openReminderNotificationSettings(): Promise<ReminderCapabilityState> {
    return this.reminderService.openNotificationSettings();
  }

  publishReminderTest(): Promise<boolean> {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();
    return this.reminderService.publishTestReminder(this._state.currentDay);
  }

  reminderSummaryText(): string {
    return this.reminderService.getReminderSummary(this._state.settings.reminder);
  }

  drainPendingPersistence(): Promise<void> {
    return this.repository.drainPendingSaves();
  }

  getHydrationInsights(windowDays: number = 7): HydrationInsights {
    this.ensureReady();
    this.rolloverToTodayIfNeeded();

    const safeWindowDays: number = Math.max(1, Math.floor(windowDays));
    const allDays: DailyHydrationRecord[] = [this._state.currentDay, ...this._state.history]
      .filter((item: DailyHydrationRecord, index: number, source: DailyHydrationRecord[]) => {
        return source.findIndex((candidate: DailyHydrationRecord) => candidate.dateKey === item.dateKey) === index;
      })
      .sort((left: DailyHydrationRecord, right: DailyHydrationRecord) => right.dateKey.localeCompare(left.dateKey));

    const loggedDays: DailyHydrationRecord[] = allDays.filter((item: DailyHydrationRecord) => item.entries.length > 0);
    const recentDays: HistoryDaySummary[] = loggedDays.slice(0, safeWindowDays).map((item: DailyHydrationRecord) => {
      const safeTarget: number = Math.max(1, item.targetMl);
      const summary: HistoryDaySummary = {
        dateKey: item.dateKey,
        totalIntakeMl: item.totalIntakeMl,
        targetMl: item.targetMl,
        completionRatio: Math.min(item.totalIntakeMl / safeTarget, 1),
        isGoalReached: item.totalIntakeMl >= item.targetMl,
        entryCount: item.entries.length
      };
      return summary;
    });

    let streakDays: number = 0;
    let expectedNextDate: Date | undefined = undefined;
    for (let i: number = 0; i < recentDays.length; i++) {
      const currentDay: HistoryDaySummary = recentDays[i];
      if (!currentDay.isGoalReached) {
        break;
      }
      const currentDate: Date | undefined = this.parseDateKey(currentDay.dateKey);
      if (!currentDate) {
        break;
      }
      if (expectedNextDate && !this.isSameDate(currentDate, expectedNextDate)) {
        break;
      }
      streakDays += 1;
      expectedNextDate = this.addDays(currentDate, -1);
    }

    const completionDays: number = recentDays.filter((item: HistoryDaySummary) => item.isGoalReached).length;
    const intakeTotal: number = recentDays
      .reduce((sum: number, item: HistoryDaySummary) => sum + item.totalIntakeMl, 0);
    const averageIntakeMl: number = recentDays.length > 0 ? Math.floor(intakeTotal / recentDays.length) : 0;

    const insights: HydrationInsights = {
      timeline: [...this._state.currentDay.entries],
      recentDays,
      streakDays,
      averageIntakeMl,
      completionDays,
      windowDays: safeWindowDays
    };
    return insights;
  }

  private rolloverToTodayIfNeeded(): void {
    this._state = this.repository.ensureCurrentDay(this._state, this.getTodayKey());
    this.repository.saveState(this._state);
  }

  private reconcileReminderState(): void {
    this.reminderService.evaluateHydrationReminder(this._state.settings.reminder, this._state.currentDay)
    .catch((error: Object) => {
      hilog.error(DOMAIN, TAG, 'Reminder reconcile failed: %{public}s', JSON.stringify(error));
    });
  }

  private ensureReady(): void {
    if (!this.initialized) {
      this.tryInitializeRepository();
      if (!this.initialized) {
        this._state = this.repository.ensureCurrentDay(this._state, this.getTodayKey());
      }
    }
  }

  private tryInitializeRepository(): void {
    if (this.initialized || !this.appContext) {
      return;
    }
    try {
      this.repository.initialize(this.appContext);
      if (!this.repository.isUsable()) {
        this.initialized = false;
        this._state = this.repository.ensureCurrentDay(this._state, this.getTodayKey());
        hilog.error(DOMAIN, TAG, 'Repository storage unavailable after init, will retry later.');
        return;
      }
      this._state = this.repository.ensureCurrentDay(this.repository.loadState(), this.getTodayKey());
      this.repository.saveState(this._state);
      this.initialized = true;
    } catch (error) {
      this.initialized = false;
      this._state = this.repository.ensureCurrentDay(this._state, this.getTodayKey());
      hilog.error(DOMAIN, TAG, 'Repository init failed, will retry later: %{public}s', JSON.stringify(error));
    }
  }

  private getTodayKey(): string {
    const today: Date = new Date();
    const month: string = `${today.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${today.getDate()}`.padStart(2, '0');
    return `${today.getFullYear()}-${month}-${day}`;
  }

  private asHour(value: number, fallback: number): number {
    const safeValue: number = Math.max(0, Math.floor(value));
    if (safeValue > 23) {
      return fallback;
    }
    return safeValue;
  }

  private parseDateKey(dateKey: string): Date | undefined {
    const parts: string[] = dateKey.split('-');
    if (parts.length !== 3) {
      return undefined;
    }
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const day: number = Number(parts[2]);
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day)) {
      return undefined;
    }
    return new Date(year, month - 1, day);
  }

  private addDays(source: Date, days: number): Date {
    const nextDate: Date = new Date(source.getTime());
    nextDate.setDate(nextDate.getDate() + days);
    return nextDate;
  }

  private isSameDate(left: Date, right: Date): boolean {
    return left.getFullYear() === right.getFullYear() &&
      left.getMonth() === right.getMonth() &&
      left.getDate() === right.getDate();
  }

  private refreshWidgetSnapshot(): void {
    const payload: HydrationWidgetPayload = this.buildWidgetPayload();
    const data: formBindingData.FormBindingData = formBindingData.createFormBindingData(payload);
    formProvider.getPublishedRunningFormInfos().then((forms: formInfo.RunningFormInfo[]) => {
      const widgetForms: formInfo.RunningFormInfo[] = forms.filter((item: formInfo.RunningFormInfo) => {
        return item.moduleName === 'entry' && item.abilityName === 'EntryFormAbility' &&
          item.formName === 'hydration_progress_widget';
      });
      widgetForms.forEach((item: formInfo.RunningFormInfo) => {
        formProvider.updateForm(item.formId, data).catch((error: BusinessError) => {
          hilog.error(DOMAIN, TAG, 'Widget update failed, id: %{public}s, code: %{public}d, message: %{public}s',
            item.formId, error.code, error.message);
        });
      });
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Widget refresh lookup failed, code: %{public}d, message: %{public}s',
        error.code, error.message);
    });
  }

  private buildWidgetPayload(): HydrationWidgetPayload {
    const metrics: HydrationDerivedMetrics = computeHydrationMetrics(this._state.currentDay);
    const percent: number = Math.floor(metrics.completionRatio * 100);
    return {
      intakeMl: this._state.currentDay.totalIntakeMl,
      targetMl: this._state.currentDay.targetMl,
      progressPercent: percent,
      progressText: `${percent}%`,
      goalReached: metrics.isGoalReached,
      statusText: metrics.isGoalReached ? 'Goal reached' : 'Keep going'
    };
  }

  // Ensure only one instance of this Service has created
  static instance() {
    if (!WaterService._instance) {
      WaterService._instance = new WaterService();
    }
    return WaterService._instance;
  }
}
