import { HistoryDaySummary, HydrationEntry, HydrationInsights } from '../../core/models/HydrationModels';
import { WaterService } from '../../core/services/WaterService';

@Builder
export function HistoryPageBuilder() {
  HistoryPage();
}

@Component
export struct HistoryPage {
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorText: string = 'Unable to load history';
  @State timeline: HydrationEntry[] = [];
  @State recentDays: HistoryDaySummary[] = [];
  @State hasAnyRecords: boolean = false;
  @State streakText: string = '0 day';
  @State averageText: string = '0ml';
  @State completionText: string = '0/0';

  aboutToAppear(): void {
    this.refreshInsights();
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 10 }) {
          Text('Hydration History')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          if (this.isLoading) {
            Text('Loading history...')
              .fontSize(10)
              .fontColor(0xB3FFFFFF)
              .width('86%')
              .textAlign(TextAlign.Center)
          } else if (this.hasError) {
            Column({ space: 8 }) {
              Text(this.errorText)
                .fontSize(10)
                .fontColor(0xFFFFC58A)
                .textAlign(TextAlign.Center)
              this.secondaryAction('Retry', () => {
                this.refreshInsights();
              })
            }
            .width('86%')
            .alignItems(HorizontalAlign.Center)
          } else {
            if (this.hasAnyRecords) {
              Row({ space: 6 }) {
                this.insightCard('Streak', this.streakText, 0x664DD078)
                this.insightCard('Avg/day', this.averageText, 0x665F92FF)
                this.insightCard('Completion', this.completionText, 0x66E3A84C)
              }
              .width('86%')
              .justifyContent(FlexAlign.SpaceBetween)
            } else {
              Text('No hydration history yet. Start by logging your first drink.')
                .fontSize(10)
                .fontColor(0xCCFFFFFF)
                .width('86%')
                .textAlign(TextAlign.Center)
            }

            Column({ space: 8 }) {
              Text('Today Timeline')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(0xFFEAF1FF)
                .width('100%')
                .textAlign(TextAlign.Start)

              if (this.timeline.length === 0) {
                Text('No drinks logged yet today.')
                  .fontSize(10)
                  .fontColor(0xB3FFFFFF)
                  .width('100%')
                  .textAlign(TextAlign.Start)
              } else {
                // eslint-disable-next-line @performance/foreach-index-check
                ForEach(this.timeline, (item: HydrationEntry, index: number) => {
                  Row() {
                    Text(`${this.formatTime(item.timestamp)} · +${item.amountMl}ml`)
                      .fontSize(10)
                      .fontColor(0xFFEAF1FF)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`#${index + 1}`)
                      .fontSize(9)
                      .fontColor(0xB3FFFFFF)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ top: 5, bottom: 5, left: 8, right: 8 })
                  .backgroundColor(0x22324D78)
                  .borderRadius(8)
                }, (item: HydrationEntry) => `timeline-${item.timestamp}-${item.amountMl}`)
              }
            }
            .width('86%')
            .padding(10)
            .backgroundColor(0x2A223F64)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('Recent 7 Days')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(0xFFEAF1FF)
                .width('100%')
                .textAlign(TextAlign.Start)

              if (this.recentDays.length === 0) {
                Text(this.hasAnyRecords ? 'No recent records yet.' : 'No drink records yet.')
                  .fontSize(10)
                  .fontColor(0xB3FFFFFF)
                  .width('100%')
                  .textAlign(TextAlign.Start)
              } else {
                // eslint-disable-next-line @performance/foreach-index-check
                ForEach(this.recentDays, (item: HistoryDaySummary, index: number) => {
                  this.dayRow(item, index === 0)
                }, (item: HistoryDaySummary) => `day-${item.dateKey}`)
              }
            }
            .width('86%')
            .padding(10)
            .backgroundColor(0x2A223F64)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
          }
        }
        .width('100%')
        .padding({ top: 16, bottom: 28 })
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[$r('app.color.base_background_gradient_start'), 0.0],
          [$r('app.color.base_background_gradient_end'), 1]]
      })
    }
    .hideTitleBar(true)
  }

  private refreshInsights(): void {
    this.isLoading = true;
    this.hasError = false;
    try {
      const insights: HydrationInsights = WaterService.instance().getHydrationInsights(7);
      this.timeline = [...insights.timeline].reverse();
      this.recentDays = insights.recentDays;
      this.hasAnyRecords = this.timeline.length > 0 || this.recentDays.length > 0;
      this.streakText = insights.streakDays === 1 ? '1 day' : `${insights.streakDays} days`;
      this.averageText = `${insights.averageIntakeMl}ml`;
      this.completionText = `${insights.completionDays}/${insights.recentDays.length}`;
    } catch (error) {
      this.hasError = true;
      this.errorText = 'Unable to read hydration history right now';
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  private secondaryAction(label: string, action: () => void) {
    Row() {
      Text(label)
        .fontSize(11)
        .fontColor(Color.White)
    }
    .width('46%')
    .height(34)
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(0x44487CCC)
    .onClick(() => {
      action();
    })
  }

  @Builder
  private insightCard(title: string, value: string, tintColor: number) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(10)
        .fontColor(0xB3FFFFFF)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('31%')
    .padding({ top: 8, bottom: 8, left: 6, right: 6 })
    .backgroundColor(0x332B446E)
    .border({ width: 1, color: tintColor })
    .borderRadius(10)
  }

  @Builder
  private dayRow(item: HistoryDaySummary, isToday: boolean) {
    Column({ space: 6 }) {
      Row() {
        Text(isToday ? 'Today' : item.dateKey)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFFEAF1FF)
        Text(item.isGoalReached ? 'Complete' : `${this.completionPercent(item.completionRatio)}%`)
          .fontSize(10)
          .fontColor(item.isGoalReached ? 0xFF8CF0A8 : 0xFFFFD780)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      Text(`${item.totalIntakeMl}ml / ${item.targetMl}ml · ${item.entryCount} drinks`)
        .fontSize(10)
        .fontColor(0xD8FFFFFF)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(10)
    .backgroundColor(0x262A4266)
    .borderRadius(12)
  }

  private completionPercent(ratio: number): number {
    if (!Number.isFinite(ratio)) {
      return 0;
    }
    return Math.max(0, Math.min(100, Math.floor(ratio * 100)));
  }

  private formatTime(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const hour: string = `${date.getHours()}`.padStart(2, '0');
    const minute: string = `${date.getMinutes()}`.padStart(2, '0');
    return `${hour}:${minute}`;
  }
}
