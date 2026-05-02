import { ReminderSettings } from '../../core/models/HydrationModels';
import { WaterService } from '../../core/services/WaterService';

@Builder
export function SettingsPageBuilder() {
  SettingsPage();
}

@Component
export struct SettingsPage {
  @State targetMl: number = 2000;
  @State presets: number[] = [250, 180, 420, 500];
  @State reminderEnabled: boolean = false;
  @State reminderInterval: number = 60;
  @State reminderStartHour: number = 8;
  @State reminderEndHour: number = 22;
  @State quietHoursEnabled: boolean = false;
  @State quietStartHour: number = 22;
  @State quietEndHour: number = 7;
  @State notificationsEnabled: boolean = false;
  @State notificationStatusText: string = 'Checking notification status...';
  @State isLoadingNotificationState: boolean = true;
  @State isRequestingNotificationAccess: boolean = false;
  @State shouldOpenNotificationSettings: boolean = false;
  @State reminderHintText: string = 'Enable reminders and save settings to receive hydration nudges.';
  @State savedStateText: string = 'Saved';
  @State hasUnsavedChanges: boolean = false;
  @State isSaving: boolean = false;
  @Consume('NavPathStack') pageStack: NavPathStack;

  aboutToAppear(): void {
    const service = WaterService.instance();
    this.targetMl = service.waterTarget;
    const presets: number[] = service.quickAddPresets;
    this.presets = [presets[0] ?? 250, presets[1] ?? 180, presets[2] ?? 420, presets[3] ?? 500];
    const reminder = service.reminderSettings;
    this.reminderEnabled = reminder.enabled;
    this.reminderInterval = reminder.intervalMinutes;
    this.reminderStartHour = reminder.startHour;
    this.reminderEndHour = reminder.endHour;
    this.quietHoursEnabled = reminder.quietHoursEnabled;
    this.quietStartHour = reminder.quietStartHour;
    this.quietEndHour = reminder.quietEndHour;
    this.hasUnsavedChanges = false;
    this.savedStateText = 'Saved';
    this.isLoadingNotificationState = true;
    this.refreshNotificationState();
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 10 }) {
          Text('Settings')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          Column({ space: 8 }) {
            Text('Daily Goal')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(0xFFEAF1FF)
            Text(`${this.targetMl}ml`)
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
            Slider({ style: SliderStyle.OutSet, min: 1000, max: 5000, value: this.targetMl, step: 100 })
              .showSteps(true)
              .onChange((value: number) => {
                this.targetMl = Math.floor(value);
                this.markDirty();
              })
          }
          .width('86%')
          .padding(10)
          .backgroundColor(0x33223F64)
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text('Quick Add Presets')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(0xFFEAF1FF)
            this.presetSlider(0, 'Preset 1')
            this.presetSlider(1, 'Preset 2')
            this.presetSlider(2, 'Preset 3')
            this.presetSlider(3, 'Preset 4')
          }
          .width('86%')
          .padding(10)
          .backgroundColor(0x33223F64)
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text('Hydration Reminders')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(0xFFEAF1FF)
            Text(this.notificationStatusText)
              .fontSize(10)
              .fontColor(this.notificationsEnabled ? 0xFF9FF0B0 : 0xFFFFC98B)

            if (this.isLoadingNotificationState) {
              Text('Loading reminder capability...')
                .fontSize(10)
                .fontColor(0xB3FFFFFF)
            }

            if (this.reminderEnabled && !this.isReminderWindowValid()) {
              Text('Reminder window equals 24h. Increase interval or narrow hours if notifications feel noisy.')
                .fontSize(10)
                .fontColor(0xFFFFC98B)
            }

            if (this.quietHoursEnabled && this.isQuietWindowAllDay()) {
              Text('Quiet hours currently mute all day. Adjust start/end hours to allow reminders.')
                .fontSize(10)
                .fontColor(0xFFFFC98B)
            }

            Toggle({ type: ToggleType.Switch, isOn: this.reminderEnabled })
              .onChange((value: boolean) => {
                this.reminderEnabled = value;
                this.markDirty();
                this.updateReminderHintText();
              })
            Text(`Interval: ${this.reminderInterval} min`)
              .fontColor(Color.White)
              .fontSize(12)
            Slider({ style: SliderStyle.OutSet, min: 30, max: 180, value: this.reminderInterval, step: 15 })
              .showSteps(true)
              .onChange((value: number) => {
                this.reminderInterval = Math.floor(value);
                this.markDirty();
              })
            Text(`Reminder window: ${this.hourText(this.reminderStartHour)}-${this.hourText(this.reminderEndHour)}`)
              .fontColor(0xD8FFFFFF)
              .fontSize(11)
            Slider({ style: SliderStyle.OutSet, min: 0, max: 23, value: this.reminderStartHour, step: 1 })
              .showSteps(false)
              .onChange((value: number) => {
                this.reminderStartHour = Math.floor(value);
                this.markDirty();
              })
            Slider({ style: SliderStyle.OutSet, min: 0, max: 23, value: this.reminderEndHour, step: 1 })
              .showSteps(false)
              .onChange((value: number) => {
                this.reminderEndHour = Math.floor(value);
                this.markDirty();
              })
            Toggle({ type: ToggleType.Switch, isOn: this.quietHoursEnabled })
              .onChange((value: boolean) => {
                this.quietHoursEnabled = value;
                this.markDirty();
              })
            Text(`Quiet hours: ${this.hourText(this.quietStartHour)}-${this.hourText(this.quietEndHour)}`)
              .fontColor(0xD8FFFFFF)
              .fontSize(11)
            Slider({ style: SliderStyle.OutSet, min: 0, max: 23, value: this.quietStartHour, step: 1 })
              .showSteps(false)
              .onChange((value: number) => {
                this.quietStartHour = Math.floor(value);
                this.markDirty();
              })
            Slider({ style: SliderStyle.OutSet, min: 0, max: 23, value: this.quietEndHour, step: 1 })
              .showSteps(false)
              .onChange((value: number) => {
                this.quietEndHour = Math.floor(value);
                this.markDirty();
              })

            Button(this.isRequestingNotificationAccess ? 'Working...' :
              (this.shouldOpenNotificationSettings ? 'Open Notification Settings' : 'Enable Notifications'))
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor(this.isRequestingNotificationAccess ? 0x664D6385 : 0xFF3E7BFA)
              .width('100%')
              .height(36)
              .borderRadius(10)
              .onClick(() => {
                if (this.isRequestingNotificationAccess) {
                  return;
                }
                this.isRequestingNotificationAccess = true;
                this.notificationStatusText = this.shouldOpenNotificationSettings ?
                  'Opening notification settings...' : 'Requesting notification access...';
                const requestPromise = this.shouldOpenNotificationSettings
                  ? WaterService.instance().openReminderNotificationSettings()
                  : WaterService.instance().requestReminderEnablement();
                requestPromise.then((state) => {
                  this.notificationsEnabled = state.notificationsEnabled;
                  this.notificationStatusText = state.statusText;
                  this.shouldOpenNotificationSettings = state.shouldOpenSettings;
                  this.savedStateText = state.notificationsEnabled ? 'Notifications enabled' : 'Notifications still disabled';
                  this.updateReminderHintText();
                }).catch(() => {
                  this.notificationStatusText = 'Unable to request notifications. Try system settings.';
                  this.savedStateText = 'Notification request failed';
                }).finally(() => {
                  this.isRequestingNotificationAccess = false;
                });
              })

            Button('Send Test Reminder')
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor((this.notificationsEnabled && this.reminderEnabled) ? 0xFF2E9D72 : 0x664D6385)
              .width('100%')
              .height(36)
              .borderRadius(10)
              .onClick(() => {
                if (!this.notificationsEnabled || !this.reminderEnabled) {
                  this.savedStateText = 'Turn on reminders and notifications first';
                  return;
                }
                WaterService.instance().publishReminderTest().then((published: boolean) => {
                  this.savedStateText = published ? 'Test reminder sent' : 'Unable to send test reminder';
                });
              })

            Text(this.reminderHintText)
              .fontColor(0xB3FFFFFF)
              .fontSize(10)
          }
          .width('86%')
          .padding(10)
          .backgroundColor(0x33223F64)
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)

          Button(this.isSaving ? 'Saving...' : (this.hasUnsavedChanges ? 'Save Changes' : 'Saved'))
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor((this.hasUnsavedChanges && !this.isSaving) ? 0xFF3E7BFA : 0x664D6385)
            .width('72%')
            .height(42)
            .borderRadius(12)
            .onClick(() => {
              if (this.isSaving) {
                return;
              }
              if (!this.hasUnsavedChanges) {
                this.savedStateText = 'No new changes';
                return;
              }
              const reminderSettings: ReminderSettings = {
                enabled: this.reminderEnabled,
                intervalMinutes: this.reminderInterval,
                startHour: this.reminderStartHour,
                endHour: this.reminderEndHour,
                quietHoursEnabled: this.quietHoursEnabled,
                quietStartHour: this.quietStartHour,
                quietEndHour: this.quietEndHour
              };
              this.isSaving = true;
              this.savedStateText = 'Saving changes...';
              const service = WaterService.instance();
              service.updateSettings(this.targetMl, this.presets, reminderSettings);
              service.drainPendingPersistence().then(() => {
                this.savedStateText = 'Saved successfully. Returning...';
                this.hasUnsavedChanges = false;
                this.isSaving = false;
                setTimeout(() => {
                  this.pageStack.pop({ shouldRefresh: true });
                }, 1000);
              }).catch(() => {
                this.savedStateText = 'Save failed. Try again';
                this.isSaving = false;
              });
            })

          Button('Cancel')
            .fontSize(12)
            .fontColor(0xFFEAF1FF)
            .backgroundColor(0x334D6385)
            .width('56%')
            .height(36)
            .borderRadius(12)
            .onClick(() => {
              this.tryExitWithoutSaving();
            })

          Text(this.savedStateText)
            .fontSize(10)
            .fontColor(this.hasUnsavedChanges ? 0xFFFFD780 : 0xB3FFFFFF)
        }
        .width('100%')
        .padding({ top: 16, bottom: 30 })
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

  @Builder
  private presetSlider(index: number, title: string) {
    Text(`${title}: ${this.presets[index]}ml`)
      .fontColor(Color.White)
      .fontSize(11)
    Slider({ style: SliderStyle.OutSet, min: 100, max: 1000, value: this.presets[index], step: 10 })
      .showSteps(false)
      .onChange((value: number) => {
        this.presets[index] = Math.floor(value);
        this.presets = [...this.presets];
        this.markDirty();
      })
  }

  private markDirty(): void {
    if (this.isSaving) {
      return;
    }
    this.hasUnsavedChanges = true;
    this.savedStateText = 'Unsaved changes';
  }

  private refreshNotificationState(): void {
    const service = WaterService.instance();
    const cachedState = service.getReminderCapabilityState();
    this.notificationsEnabled = cachedState.notificationsEnabled;
    this.notificationStatusText = cachedState.statusText;
    this.shouldOpenNotificationSettings = cachedState.shouldOpenSettings;
    service.refreshReminderCapabilityState().then((state) => {
      this.notificationsEnabled = state.notificationsEnabled;
      this.notificationStatusText = state.statusText;
      this.shouldOpenNotificationSettings = state.shouldOpenSettings;
      this.isLoadingNotificationState = false;
      this.updateReminderHintText();
    }).catch(() => {
      this.notificationStatusText = 'Failed to read notification status';
      this.isLoadingNotificationState = false;
      this.updateReminderHintText();
    });
    this.updateReminderHintText();
  }

  private isReminderWindowValid(): boolean {
    return this.reminderStartHour !== this.reminderEndHour;
  }

  private isQuietWindowAllDay(): boolean {
    return this.quietStartHour === this.quietEndHour;
  }

  private updateReminderHintText(): void {
    if (!this.reminderEnabled) {
      this.reminderHintText = 'Reminders are turned off.';
      return;
    }
    if (!this.notificationsEnabled) {
      this.reminderHintText = 'Reminder enabled, but notifications are disabled for this app.';
      return;
    }
    this.reminderHintText = 'Hydration nudges will appear only in the configured window and outside quiet hours.';
  }

  private tryExitWithoutSaving(): void {
    if (!this.hasUnsavedChanges || this.isSaving) {
      this.pageStack.pop();
      return;
    }
    this.getUIContext().showAlertDialog({
      title: 'Discard changes?',
      message: 'You have unsaved settings.',
      primaryButton: {
        value: 'Keep editing',
        action: () => {
          this.savedStateText = 'Continue editing';
        }
      },
      secondaryButton: {
        value: 'Discard',
        style: DialogButtonStyle.HIGHLIGHT,
        action: () => {
          this.hasUnsavedChanges = false;
          this.savedStateText = 'Changes discarded';
          this.pageStack.pop();
        }
      }
    });
  }

  private hourText(value: number): string {
    return `${value}`.padStart(2, '0') + ':00';
  }
}
