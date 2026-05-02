import { BaseViewModel } from '../../core/services/BaseViewModel';
import { WaterService } from '../../core/services/WaterService';
import { HydrationEntry } from '../../core/models/HydrationModels';

@ObservedV2
export class IndexViewModel extends BaseViewModel {
  @Trace isLoading: boolean = true;
  @Trace hasLoadError: boolean = false;
  @Trace loadErrorText: string = 'Unable to load hydration data';
  @Trace isInited: boolean = false;
  @Trace currentWater: number = 0;
  @Trace waterTarget: number = 0;
  @Trace headerText: string = '0/0';
  @Trace remainingText: string = '0ml left';
  @Trace completionText: string = '0% complete';
  @Trace statusText: string = 'Start your first drink';
  @Trace lastActionText: string = 'No recent drink';
  @Trace reminderText: string = 'Reminders off';
  @Trace showReminderChip: boolean = false;
  @Trace actionStateText: string = 'Ready to log water';
  @Trace quickPresets: number[] = [250, 180, 420, 500];
  waterService: WaterService = WaterService.instance();

  constructor() {
    super();
    this.initVm();
  }

  initVm() {
    this.isInited = true;
  }

  aboutToAppear(): void {
    this.isLoading = true;
    this.hasLoadError = false;
    try {
      this.waterService.refreshForToday();
      this.refreshViewState();
    } catch (error) {
      this.hasLoadError = true;
      this.loadErrorText = 'Unable to load hydration dashboard';
    } finally {
      this.isLoading = false;
    }
    this.waterService.refreshReminderCapabilityState().then(() => {
      this.reminderText = this.waterService.reminderSummaryText();
      this.showReminderChip = this.shouldShowReminderChip(this.reminderText);
    }).catch(() => {
      this.reminderText = 'Reminder status unavailable';
      this.showReminderChip = false;
    });
  }

  addWater(amountMl: number): void {
    if (amountMl <= 0) {
      this.actionStateText = 'Choose a valid water amount';
      return;
    }
    this.waterService.addWater(amountMl);
    this.refreshViewState();
    this.actionStateText = `Added ${amountMl}ml`;
  }

  undoLastEntry(): boolean {
    const result: boolean = this.waterService.undoLastEntry();
    this.refreshViewState();
    this.actionStateText = result ? 'Last entry removed' : 'No drink to undo';
    return result;
  }

  setWaterTarget(targetMl: number): void {
    this.waterService.setDailyTarget(targetMl);
    this.refreshViewState();
  }

  private refreshViewState(): void {
    this.currentWater = this.waterService.currentWater;
    this.waterTarget = this.waterService.waterTarget;
    this.headerText = `${this.currentWater}/${this.waterTarget}`;
    this.remainingText = `${this.waterService.metrics.remainingMl}ml left`;
    const completion: number = Math.floor(this.waterService.metrics.completionRatio * 100);
    this.completionText = `${completion}% complete`;
    const presets: number[] = this.waterService.quickAddPresets;
    const fallback: number[] = [250, 180, 420, 500];
    this.quickPresets = [
      presets[0] ?? fallback[0],
      presets[1] ?? fallback[1],
      presets[2] ?? fallback[2],
      presets[3] ?? fallback[3]
    ];
    this.statusText = this.waterService.metrics.isGoalReached ? 'Goal reached · Great job!' : 'Keep hydrating';
    const lastEntry: HydrationEntry | undefined = this.waterService.lastEntry;
    this.lastActionText = lastEntry ? `Last +${lastEntry.amountMl}ml at ${this.formatTime(lastEntry.timestamp)}` : 'No recent drink';
    if (this.currentWater === 0) {
      this.actionStateText = 'Start with a quick preset or custom drink';
    }
    this.reminderText = this.waterService.reminderSummaryText();
    this.showReminderChip = this.shouldShowReminderChip(this.reminderText);
  }

  private shouldShowReminderChip(reminderText: string): boolean {
    return !reminderText.startsWith('Reminders blocked') && reminderText !== 'Reminders off';
  }

  private formatTime(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const hour: string = `${date.getHours()}`.padStart(2, '0');
    const minute: string = `${date.getMinutes()}`.padStart(2, '0');
    return `${hour}:${minute}`;
  }
}
