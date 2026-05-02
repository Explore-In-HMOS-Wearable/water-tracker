let widgetStorage = new LocalStorage();

@Entry(widgetStorage)
@Component
struct WidgetCard {
  @LocalStorageProp('intakeMl') intakeMl: number = 0;
  @LocalStorageProp('targetMl') targetMl: number = 2000;
  @LocalStorageProp('progressText') progressText: string = '0%';
  @LocalStorageProp('goalReached') goalReached: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 3 }) {
        Text(this.goalReached ? 'Hydration ✅' : 'Hydration')
          .fontSize(12)
          .fontColor('#F5F7FF')
          .fontWeight(FontWeight.Medium)

        Text(this.progressText)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.goalReached ? '#58E39B' : '#7DC4FF')

        Text(`${this.intakeMl}/${this.targetMl} ml`)
          .fontSize(10)
          .fontColor('#B8C5E6')
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor('#162544')
    .borderRadius('50%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility'
      });
    })
  }
}
