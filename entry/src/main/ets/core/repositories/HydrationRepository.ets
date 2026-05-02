import { DailyHydrationRecord, HydrationState } from '../models/HydrationModels';

export interface HydrationRepository {
  initialize(context: Context): void;
  isUsable(): boolean;
  loadState(): HydrationState;
  saveState(state: HydrationState): void;
  drainPendingSaves(): Promise<void>;
  ensureCurrentDay(state: HydrationState, todayKey: string): HydrationState;
  archivePreviousDay(state: HydrationState): HydrationState;
  listRecentDays(limit: number): DailyHydrationRecord[];
}
