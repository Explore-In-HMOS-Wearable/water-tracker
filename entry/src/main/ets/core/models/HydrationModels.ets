export interface HydrationEntry {
  id: string;
  amountMl: number;
  timestamp: number;
}

export interface ReminderSettings {
  enabled: boolean;
  intervalMinutes: number;
  startHour: number;
  endHour: number;
  quietHoursEnabled: boolean;
  quietStartHour: number;
  quietEndHour: number;
}

export interface HydrationSettings {
  dailyTargetMl: number;
  quickAddPresetsMl: number[];
  reminder: ReminderSettings;
}

export interface DailyHydrationRecord {
  dateKey: string;
  totalIntakeMl: number;
  targetMl: number;
  entries: HydrationEntry[];
}

export interface HydrationState {
  settings: HydrationSettings;
  currentDay: DailyHydrationRecord;
  history: DailyHydrationRecord[];
}

export interface HydrationDerivedMetrics {
  remainingMl: number;
  completionRatio: number;
  isGoalReached: boolean;
}

export interface ReminderStatus {
  enabled: boolean;
  message: string;
}

export interface HistoryDaySummary {
  dateKey: string;
  totalIntakeMl: number;
  targetMl: number;
  completionRatio: number;
  isGoalReached: boolean;
  entryCount: number;
}

export interface HydrationInsights {
  timeline: HydrationEntry[];
  recentDays: HistoryDaySummary[];
  streakDays: number;
  averageIntakeMl: number;
  completionDays: number;
  windowDays: number;
}

export function createDefaultHydrationSettings(): HydrationSettings {
  return {
    dailyTargetMl: 2000,
    quickAddPresetsMl: [250, 180, 420, 500],
    reminder: {
      enabled: false,
      intervalMinutes: 60,
      startHour: 8,
      endHour: 22,
      quietHoursEnabled: false,
      quietStartHour: 22,
      quietEndHour: 7
    }
  };
}

export function createEmptyDailyRecord(dateKey: string, targetMl: number): DailyHydrationRecord {
  return {
    dateKey,
    totalIntakeMl: 0,
    targetMl,
    entries: []
  };
}

export function createDefaultHydrationState(dateKey: string): HydrationState {
  const settings: HydrationSettings = createDefaultHydrationSettings();
  return {
    settings,
    currentDay: createEmptyDailyRecord(dateKey, settings.dailyTargetMl),
    history: []
  };
}

export function computeHydrationMetrics(record: DailyHydrationRecord): HydrationDerivedMetrics {
  const safeTarget: number = Math.max(1, record.targetMl);
  const completionRatio: number = Math.min(record.totalIntakeMl / safeTarget, 1);
  return {
    remainingMl: Math.max(record.targetMl - record.totalIntakeMl, 0),
    completionRatio,
    isGoalReached: record.totalIntakeMl >= record.targetMl
  };
}
