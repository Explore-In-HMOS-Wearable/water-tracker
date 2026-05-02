import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  createDefaultHydrationState,
  DailyHydrationRecord,
  HydrationEntry,
  HydrationState,
  ReminderSettings
} from '../../models/HydrationModels';
import { HydrationRepository } from '../../repositories/HydrationRepository';

const STORE_NAME: string = 'hydration_store';
const STATE_KEY: string = 'hydration_state_v1';
const HISTORY_LIMIT: number = 14;
const DOMAIN = 0x0000;
const TAG: string = 'PreferencesStorageService';

export class PreferencesStorageService implements HydrationRepository {
  private store?: preferences.Preferences;
  private saveQueue: Promise<void> = Promise.resolve();

  isUsable(): boolean {
    return this.store !== undefined;
  }

  initialize(context: Context): void {
    if (this.store) {
      return;
    }
    const options: preferences.Options = { name: STORE_NAME };
    try {
      this.store = preferences.getPreferencesSync(context, options);
    } catch (error) {
      this.store = undefined;
      hilog.error(DOMAIN, TAG, 'Failed to initialize preferences store.');
    }
  }

  loadState(): HydrationState {
    const todayKey: string = this.getTodayKey();
    if (!this.store) {
      return createDefaultHydrationState(todayKey);
    }

    try {
      const raw: string = this.store.getSync(STATE_KEY, '') as string;
      if (raw.length === 0) {
        return createDefaultHydrationState(todayKey);
      }
      const parsed: HydrationState = JSON.parse(raw) as HydrationState;
      return this.sanitizeState(parsed, todayKey);
    } catch (error) {
      return createDefaultHydrationState(todayKey);
    }
  }

  saveState(state: HydrationState): void {
    if (!this.store) {
      hilog.error(DOMAIN, TAG, 'Skip save because store is not initialized.');
      return;
    }

    const serializedState: string = JSON.stringify(state);
    this.saveQueue = this.saveQueue.then(async () => {
      const saved: boolean = await this.persistState(serializedState);
      if (!saved) {
        hilog.error(DOMAIN, TAG, 'Failed to persist hydration state.');
      }
    }).catch((error: Object) => {
      hilog.error(DOMAIN, TAG, 'Unexpected save queue error: %{public}s', JSON.stringify(error));
    });
  }

  drainPendingSaves(): Promise<void> {
    return this.saveQueue.then(() => {
      return;
    }).catch((error: Object) => {
      hilog.error(DOMAIN, TAG, 'Drain pending saves failed: %{public}s', JSON.stringify(error));
      throw new Error('Drain pending saves failed.');
    });
  }

  private async persistState(serializedState: string): Promise<boolean> {
    if (!this.store) {
      return false;
    }
    try {
      this.store.putSync(STATE_KEY, serializedState);
      await this.store.flush();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Preferences flush failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  ensureCurrentDay(state: HydrationState, todayKey: string): HydrationState {
    if (state.currentDay.dateKey === todayKey) {
      return state;
    }
    const archived: HydrationState = this.archivePreviousDay(state);
    archived.currentDay = {
      dateKey: todayKey,
      totalIntakeMl: 0,
      targetMl: archived.settings.dailyTargetMl,
      entries: []
    };
    return archived;
  }

  archivePreviousDay(state: HydrationState): HydrationState {
    const currentDay: DailyHydrationRecord = state.currentDay;
    if (currentDay.dateKey.length === 0) {
      return state;
    }

    const filtered: DailyHydrationRecord[] = state.history.filter((item: DailyHydrationRecord) => {
      return item.dateKey !== currentDay.dateKey;
    });
    const updatedHistory: DailyHydrationRecord[] = [currentDay, ...filtered].slice(0, HISTORY_LIMIT);
    return {
      settings: state.settings,
      currentDay: state.currentDay,
      history: updatedHistory
    };
  }

  listRecentDays(limit: number): DailyHydrationRecord[] {
    const state: HydrationState = this.loadState();
    return state.history.slice(0, Math.max(limit, 0));
  }

  private sanitizeState(source: HydrationState, todayKey: string): HydrationState {
    const fallback: HydrationState = createDefaultHydrationState(todayKey);
    const dailyTargetMl: number = this.asPositiveNumber(
      source.settings?.dailyTargetMl,
      fallback.settings.dailyTargetMl
    );
    const reminder: ReminderSettings = this.sanitizeReminder(source.settings?.reminder, fallback.settings.reminder);
    const currentDay: DailyHydrationRecord = this.sanitizeRecord(source.currentDay, todayKey, dailyTargetMl);
    const history: DailyHydrationRecord[] = this.sanitizeHistory(source.history, dailyTargetMl);
    return {
      settings: {
        dailyTargetMl,
        quickAddPresetsMl: this.sanitizePresets(
          source.settings?.quickAddPresetsMl,
          fallback.settings.quickAddPresetsMl
        ),
        reminder
      },
      currentDay,
      history
    };
  }

  private sanitizeReminder(source: ReminderSettings | undefined, fallback: ReminderSettings): ReminderSettings {
    return {
      enabled: typeof source?.enabled === 'boolean' ? source.enabled : fallback.enabled,
      intervalMinutes: this.asPositiveNumber(source?.intervalMinutes, fallback.intervalMinutes),
      startHour: this.asHour(source?.startHour, fallback.startHour),
      endHour: this.asHour(source?.endHour, fallback.endHour),
      quietHoursEnabled: typeof source?.quietHoursEnabled === 'boolean' ? source.quietHoursEnabled : fallback.quietHoursEnabled,
      quietStartHour: this.asHour(source?.quietStartHour, fallback.quietStartHour),
      quietEndHour: this.asHour(source?.quietEndHour, fallback.quietEndHour)
    };
  }

  private sanitizeRecord(
    source: DailyHydrationRecord | undefined,
    dateKey: string,
    targetMl: number
  ): DailyHydrationRecord {
    return {
      dateKey: this.asDateKey(source?.dateKey, dateKey),
      totalIntakeMl: this.asNonNegativeNumber(source?.totalIntakeMl),
      targetMl: this.asPositiveNumber(source?.targetMl, targetMl),
      entries: this.sanitizeEntries(source?.entries)
    };
  }

  private sanitizeHistory(source: DailyHydrationRecord[] | undefined, targetMl: number): DailyHydrationRecord[] {
    if (!source || source.length === 0) {
      return [];
    }
    return source.map((item: DailyHydrationRecord) => this.sanitizeRecord(item, '', targetMl))
      .filter((item: DailyHydrationRecord) => item.dateKey.length > 0)
      .slice(0, HISTORY_LIMIT);
  }

  private sanitizeEntries(source: HydrationEntry[] | undefined): HydrationEntry[] {
    if (!source || source.length === 0) {
      return [];
    }
    return source.map((entry: HydrationEntry) => {
      const sanitizedEntry: HydrationEntry = {
        id: this.asDateKey(entry.id, `${Date.now()}`),
        amountMl: this.asNonNegativeNumber(entry.amountMl),
        timestamp: this.asNonNegativeNumber(entry.timestamp)
      };
      return sanitizedEntry;
    });
  }

  private sanitizePresets(source: number[] | undefined, fallback: number[]): number[] {
    if (!source || source.length === 0) {
      return fallback;
    }
    const values: number[] = source
      .map((item: number) => this.asNonNegativeNumber(item))
      .filter((item: number) => item > 0)
      .slice(0, 8);
    return values.length > 0 ? values : fallback;
  }

  private asDateKey(value: string | undefined, fallback: string): string {
    if (!value || value.length === 0) {
      return fallback;
    }
    return value;
  }

  private asHour(value: number | undefined, fallback: number): number {
    const hour: number = this.asNonNegativeNumber(value);
    return hour > 23 ? fallback : hour;
  }

  private asNonNegativeNumber(value: number | undefined): number {
    if (typeof value !== 'number' || Number.isNaN(value)) {
      return 0;
    }
    return Math.max(0, Math.floor(value));
  }

  private asPositiveNumber(value: number | undefined, fallback: number): number {
    const safeValue: number = this.asNonNegativeNumber(value);
    return safeValue > 0 ? safeValue : fallback;
  }

  private getTodayKey(): string {
    const today: Date = new Date();
    const month: string = `${today.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${today.getDate()}`.padStart(2, '0');
    return `${today.getFullYear()}-${month}-${day}`;
  }
}
