import { HydrationEntry } from '../../core/models/HydrationModels';
import { WaterService } from '../../core/services/WaterService';
import { SingleWaterItem } from '../widgets/SingleWaterItem'
import { SettingsPageBuilder } from './SettingsPage';
import { LogWaterPageBuilder } from './LogWaterPage';
import { HistoryPageBuilder } from './HistoryPage';
import { SetTargetPageBuilder } from './SetTargetPage';
import { ActionButton } from '../widgets/ActionButton';
import { StatChip } from '../widgets/StatChip';

const SETTINGS_PAGE_ROUTE: string = 'settings';
const LOG_WATER_PAGE_ROUTE: string = 'log-water';
const HISTORY_PAGE_ROUTE: string = 'HydrationHistoryPage';
const SET_TARGET_PAGE_ROUTE: string = 'set-target';

interface DashboardRefreshResult {
  shouldRefresh?: boolean;
}

@Entry
@Component
struct Index {
  @State isLoading: boolean = true;
  @State hasLoadError: boolean = false;
  @State loadErrorText: string = 'Unable to load hydration dashboard';
  @State currentWater: number = 0;
  @State waterTarget: number = 2000;
  @State headerText: string = '0/0';
  @State remainingText: string = '0ml left';
  @State completionText: string = '0% complete';
  @State statusText: string = 'Start your first drink';
  @State lastActionText: string = 'No recent drink';
  @State reminderText: string = 'Reminders off';
  @State showReminderChip: boolean = false;
  @State actionStateText: string = 'Ready to log water';
  @State quickPresets: number[] = [250, 180, 420, 500];
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack()
  private waterService: WaterService = WaterService.instance();
  private skipNextPageShowRefresh: boolean = false;

  @Builder
  PagesMap(name: string) {
    if (name === SETTINGS_PAGE_ROUTE) {
      SettingsPageBuilder()
    } else if (name === LOG_WATER_PAGE_ROUTE) {
      LogWaterPageBuilder()
    } else if (name === HISTORY_PAGE_ROUTE) {
      HistoryPageBuilder()
    } else if (name === SET_TARGET_PAGE_ROUTE) {
      SetTargetPageBuilder()
    }
  }

  aboutToAppear(): void {
    this.refreshDashboard();
  }

  onPageShow(): void {
    if (this.skipNextPageShowRefresh) {
      this.skipNextPageShowRefresh = false;
      return;
    }
    this.refreshDashboard();
  }

  private refreshDashboard(): void {
    this.isLoading = true;
    this.hasLoadError = false;
    try {
      this.waterService.refreshForToday();
      this.syncFromService();
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

  private syncFromService(): void {
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

  private addWater(amountMl: number): void {
    if (amountMl <= 0) {
      this.actionStateText = 'Choose a valid water amount';
      return;
    }
    this.waterService.addWater(amountMl);
    this.syncFromService();
    this.actionStateText = `Added ${amountMl}ml`;
  }

  private undoLastEntry(): void {
    const result: boolean = this.waterService.undoLastEntry();
    this.syncFromService();
    this.actionStateText = result ? 'Last entry removed' : 'No drink to undo';
  }

  private pushPathWithRefresh(routeName: string): void {
    this.pageStack.pushPath({
      name: routeName,
      param: null,
      onPop: (popInfo: PopInfo) => {
        const result = popInfo.result as DashboardRefreshResult;
        if (result?.shouldRefresh) {
          this.skipNextPageShowRefresh = true;
          this.refreshDashboard();
        }
      }
    });
  }

  build() {
    Navigation(this.pageStack) {
      Column() {
        Gauge({ value: this.currentWater, min: 0, max: this.waterTarget }) {
          List({ space: 0 }) {
            ListItem() {
              Column({ space: 8 }) {
                Text(this.headerText)
                  .fontSize(21)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)

                Text(this.remainingText)
                  .fontSize(12)
                  .fontColor(0xD8FFFFFF)
                  .textAlign(TextAlign.Center)

                Text(this.statusText)
                  .fontSize(11)
                  .fontColor(this.currentWater >= this.waterTarget && this.waterTarget > 0 ? 0xFF9FF0B0 : 0xFFFFD780)
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (this.showReminderChip) {
                  Row({ space: 8 }) {
                    StatChip('Completion', this.completionText)
                    StatChip('Reminder', this.reminderText)
                  }
                  .justifyContent(FlexAlign.Center)
                } else {
                  Row() {
                    StatChip('Completion', this.completionText)
                  }
                  .justifyContent(FlexAlign.Center)
                }

                Text(this.lastActionText)
                  .fontSize(10)
                  .fontColor(0xB3FFFFFF)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('88%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .width('95%')
            .margin({ top: 24, bottom: 6 })

            if (this.isLoading) {
              ListItem() {
                Text('Loading hydration dashboard...')
                  .fontSize(11)
                  .fontColor(0xCCFFFFFF)
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width('95%')
              .margin({ bottom: 8 })
            }

            if (this.hasLoadError) {
              ListItem() {
                Column({ space: 8 }) {
                  Text(this.loadErrorText)
                    .fontSize(11)
                    .fontColor(0xFFFFC58A)
                    .textAlign(TextAlign.Center)
                  ActionButton('Retry', () => {
                    this.refreshDashboard();
                  }, '62%')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }
              .width('95%')
              .margin({ bottom: 8 })
            }

            ListItem() {
              Row() {
                SingleWaterItem(this.quickPresets[0], $r('app.color.gradient_green'), 'app.media.bottle_250', 15,
                  (value: number) => this.addWater(value), true)
                SingleWaterItem(this.quickPresets[1], $r('app.color.gradient_orange'), 'app.media.bottle_300', 20,
                  (value: number) => this.addWater(value))
              }
            }
            .width('95%')
            .margin({ bottom: 8 })

            ListItem() {
              Row() {
                SingleWaterItem(this.quickPresets[2], $r('app.color.gradient_brown'), 'app.media.bottle_500', 20,
                  (value: number) => this.addWater(value), true)
                SingleWaterItem(this.quickPresets[3], $r('app.color.gradient_blue'), 'app.media.bottle_1L', 20,
                  (value: number) => this.addWater(value))
              }
            }
            .width('95%')
            .margin({ bottom: 8 })

            ListItem() {
              Column({ space: 8 }) {
                Text(this.actionStateText)
                  .fontSize(10)
                  .fontColor(this.currentWater >= this.waterTarget && this.waterTarget > 0 ? 0xFF9FF0B0 : 0xCCFFFFFF)
                  .textAlign(TextAlign.Center)
                  .width('100%')

                Row({ space: 8 }) {
                  ActionButton('Custom Log', () => {
                    this.pushPathWithRefresh(LOG_WATER_PAGE_ROUTE);
                  })
                  ActionButton('Undo Last', () => {
                    this.undoLastEntry();
                  })
                }
                .justifyContent(FlexAlign.Center)

                Row({ space: 8 }) {
                  ActionButton('History', () => {
                    this.pageStack.pushPath({ name: HISTORY_PAGE_ROUTE, param: null });
                  })
                  ActionButton('Settings', () => {
                    this.pushPathWithRefresh(SETTINGS_PAGE_ROUTE);
                  })
                }
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
            }
            .width('95%')
            .margin({ bottom: 30 })
          }
          .width('100%')
          .height('100%')
          .listDirection(Axis.Vertical)
          .edgeEffect(EdgeEffect.None)
          .scrollBar(BarState.Off)
          .focusable(true)
          .focusOnTouch(true)
          .defaultFocus(true)
        }
        .colors($r('app.color.gauge'))
        .width('100%')
        .height('100%')
        .indicator(null)
        .strokeWidth(14)
        .trackShadow({ radius: 3, offsetX: 3, offsetY: 3 })
        .value(this.currentWater)
        .align(Alignment.Center)
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[$r('app.color.base_background_gradient_start'), 0.0],
          [$r('app.color.base_background_gradient_end'), 1]]
      })
    }
    .hideTitleBar(true)
    .navDestination(this.PagesMap)
    .hideBackButton(true)
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
