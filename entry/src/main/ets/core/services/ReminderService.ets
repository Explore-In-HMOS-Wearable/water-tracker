import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DailyHydrationRecord, ReminderSettings } from '../models/HydrationModels';

const DOMAIN = 0x0000;
const TAG: string = 'ReminderService';
const REMINDER_NOTIFICATION_ID: number = 9501;
const REMINDER_PLAN_LIMIT: number = 30;
const REMINDER_NOTIFICATION_ID_BASE: number = 9600;
const WEEKDAYS: number[] = [1, 2, 3, 4, 5, 6, 7];

export interface ReminderCapabilityState {
  notificationsEnabled: boolean;
  statusText: string;
  canRequestEnablement: boolean;
  shouldOpenSettings: boolean;
}

export class ReminderService {
  static _instance: ReminderService;
  private appContext?: common.UIAbilityContext;
  private notificationsEnabled: boolean = false;
  private reminderSlotReady: boolean = false;
  private lastPublishedAt: number = 0;
  private statusText: string = 'Notification status unavailable';
  private shouldOpenSettings: boolean = false;
  private hasAttemptedEnableRequest: boolean = false;
  private remindersSynced: boolean = false;
  private lastPlanKey: string = '';

  initialize(context: Context): void {
    this.appContext = context as common.UIAbilityContext;
  }

  getCapabilityState(): ReminderCapabilityState {
    return {
      notificationsEnabled: this.notificationsEnabled,
      statusText: this.statusText,
      canRequestEnablement: this.appContext !== undefined,
      shouldOpenSettings: this.shouldOpenSettings
    };
  }

  async refreshNotificationStatus(): Promise<ReminderCapabilityState> {
    try {
      this.notificationsEnabled = await notificationManager.isNotificationEnabled();
      this.statusText = this.notificationsEnabled ? 'Notifications are enabled' : 'Notifications are disabled for this app';
      this.shouldOpenSettings = !this.notificationsEnabled && this.hasAttemptedEnableRequest;
      if (this.notificationsEnabled) {
        this.hasAttemptedEnableRequest = false;
      }
    } catch (error) {
      this.notificationsEnabled = false;
      this.statusText = 'Failed to read notification status';
      this.shouldOpenSettings = false;
      hilog.error(DOMAIN, TAG, 'refreshNotificationStatus failed: %{public}s', JSON.stringify(error));
    }
    return this.getCapabilityState();
  }

  async requestEnableNotifications(): Promise<ReminderCapabilityState> {
    if (!this.appContext) {
      this.statusText = 'Notification prompt is unavailable before app context is ready';
      return this.getCapabilityState();
    }
    try {
      this.hasAttemptedEnableRequest = true;
      await notificationManager.requestEnableNotification(this.appContext);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'requestEnableNotification failed: %{public}s', JSON.stringify(error));
    }
    const latestState: ReminderCapabilityState = await this.refreshNotificationStatus();
    if (!latestState.notificationsEnabled) {
      this.statusText = 'Notification prompt unavailable now. Open system notification settings.';
      this.shouldOpenSettings = true;
    }
    return this.getCapabilityState();
  }

  async openNotificationSettings(): Promise<ReminderCapabilityState> {
    if (!this.appContext) {
      this.statusText = 'Unable to open notification settings before app context is ready';
      return this.getCapabilityState();
    }
    if (!canIUse('SystemCapability.Notification.NotificationSettings')) {
      this.statusText = 'Notification settings shortcut is unavailable on this device';
      return this.refreshNotificationStatus();
    }
    try {
      await notificationManager.openNotificationSettings(this.appContext);
      this.statusText = 'Notification settings opened';
    } catch (error) {
      this.statusText = 'Unable to open notification settings';
      hilog.error(DOMAIN, TAG, 'openNotificationSettings failed: %{public}s', JSON.stringify(error));
    }
    return this.refreshNotificationStatus();
  }

  async evaluateHydrationReminder(settings: ReminderSettings, record: DailyHydrationRecord): Promise<void> {
    const shouldSuppress: boolean = this.shouldSuppressReminder(settings, record);
    if (shouldSuppress) {
      await this.cancelHydrationReminders();
      return;
    }

    await this.refreshNotificationStatus();
    if (!this.notificationsEnabled) {
      this.remindersSynced = false;
      return;
    }

    const reminderTimes: number[] = this.buildReminderTimes(settings);
    if (reminderTimes.length === 0) {
      await this.cancelHydrationReminders();
      return;
    }

    if (reminderTimes.length > REMINDER_PLAN_LIMIT) {
      this.statusText = `Reminder plan exceeds ${REMINDER_PLAN_LIMIT}. Increase interval or narrow reminder window.`;
      await this.cancelHydrationReminders();
      return;
    }

    const planKey: string = `${settings.intervalMinutes}-${settings.startHour}-${settings.endHour}` +
      `-${settings.quietHoursEnabled}-${settings.quietStartHour}-${settings.quietEndHour}`;
    if (this.remindersSynced && this.lastPlanKey === planKey) {
      return;
    }

    await this.ensureReminderSlot();
    await this.cancelHydrationReminders();
    const remainingMl: number = Math.max(record.targetMl - record.totalIntakeMl, 0);
    const publishResult: boolean = await this.publishHydrationReminderPlan(reminderTimes, remainingMl);
    if (publishResult) {
      this.lastPlanKey = planKey;
      this.remindersSynced = true;
      this.statusText = `Scheduled ${reminderTimes.length} hydration reminders`;
      return;
    }
    this.remindersSynced = false;
  }

  async publishTestReminder(record: DailyHydrationRecord): Promise<boolean> {
    await this.refreshNotificationStatus();
    if (!this.notificationsEnabled) {
      return false;
    }
    await this.ensureReminderSlot();
    const request: notificationManager.NotificationRequest = {
      id: REMINDER_NOTIFICATION_ID,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: 'Hydration reminder test',
          text: 'Reminder notifications are working',
          additionalText: `${Math.max(record.targetMl - record.totalIntakeMl, 0)}ml remaining`
        }
      }
    };
    try {
      await notificationManager.publish(request);
      this.lastPublishedAt = Date.now();
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'publish test reminder failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async cancelReminderNotification(): Promise<void> {
    try {
      await notificationManager.cancel(REMINDER_NOTIFICATION_ID);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'cancel reminder failed: %{public}s', JSON.stringify(error));
    }
  }

  private async cancelHydrationReminders(): Promise<void> {
    this.lastPlanKey = '';
    this.remindersSynced = false;
    try {
      await reminderAgentManager.cancelAllReminders();
    } catch (error) {
      const code: number = Number((error as BusinessError).code);
      if (code !== 1700004) {
        hilog.error(DOMAIN, TAG, 'cancelAllReminders failed: %{public}s', JSON.stringify(error));
      }
    }
    await this.cancelReminderNotification();
  }

  getReminderSummary(settings: ReminderSettings): string {
    if (!settings.enabled) {
      return 'Reminders off';
    }
    if (!this.notificationsEnabled) {
      return 'Reminders blocked: notifications disabled';
    }
    const reminderCount: number = this.buildReminderTimes(settings).length;
    return `Every ${settings.intervalMinutes}m · ${this.hourText(settings.startHour)}-${this.hourText(settings.endHour)} · ${reminderCount} alerts`;
  }

  private async ensureReminderSlot(): Promise<void> {
    if (this.reminderSlotReady) {
      return;
    }
    const slot: notificationManager.NotificationSlot = {
      notificationType: notificationManager.SlotType.SERVICE_INFORMATION
    };
    try {
      await reminderAgentManager.addNotificationSlot(slot);
      this.reminderSlotReady = true;
    } catch (error) {
      const code: number = Number((error as BusinessError).code);
      if (code === 1600015) {
        this.reminderSlotReady = true;
        return;
      }
      hilog.error(DOMAIN, TAG, 'addNotificationSlot failed: %{public}s', JSON.stringify(error));
    }
  }

  private shouldSuppressReminder(settings: ReminderSettings, record: DailyHydrationRecord): boolean {
    if (!settings.enabled) {
      return true;
    }
    if (record.totalIntakeMl >= record.targetMl) {
      return true;
    }
    return false;
  }

  private async publishHydrationReminderPlan(reminderTimes: number[], remainingMl: number): Promise<boolean> {
    const publishedReminderIds: number[] = [];
    for (let index: number = 0; index < reminderTimes.length; index++) {
      const minuteOfDay: number = reminderTimes[index];
      const hour: number = Math.floor(minuteOfDay / 60);
      const minute: number = minuteOfDay % 60;
      const request: reminderAgentManager.ReminderRequestAlarm = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
        hour,
        minute,
        daysOfWeek: WEEKDAYS,
        notificationId: REMINDER_NOTIFICATION_ID_BASE + index,
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        title: 'Hydration reminder',
        content: `Drink water now · ${remainingMl}ml left`,
        actionButton: [{
          title: 'Dismiss',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        }]
      };
      try {
        const reminderId: number = await reminderAgentManager.publishReminder(request);
        publishedReminderIds.push(reminderId);
      } catch (error) {
        hilog.error(DOMAIN, TAG, 'publishReminder failed: %{public}s', JSON.stringify(error));
        await this.rollbackPublishedReminders(publishedReminderIds);
        return false;
      }
    }
    return true;
  }

  private async rollbackPublishedReminders(reminderIds: number[]): Promise<void> {
    for (let index: number = 0; index < reminderIds.length; index++) {
      try {
        await reminderAgentManager.cancelReminder(reminderIds[index]);
      } catch (error) {
        const code: number = Number((error as BusinessError).code);
        if (code !== 1700004) {
          hilog.error(DOMAIN, TAG, 'rollback cancelReminder failed: %{public}s', JSON.stringify(error));
        }
      }
    }
  }

  private buildReminderTimes(settings: ReminderSettings): number[] {
    const startMinutes: number = this.asMinutes(settings.startHour);
    const endMinutes: number = this.asMinutes(settings.endHour);
    const intervalMinutes: number = Math.max(15, Math.floor(settings.intervalMinutes));
    const totalWindowMinutes: number = this.getWindowMinutes(startMinutes, endMinutes);
    const reminders: number[] = [];
    let offset: number = 0;
    while (offset < totalWindowMinutes) {
      const minuteOfDay: number = (startMinutes + offset) % (24 * 60);
      if (!this.isMinuteInQuietHours(minuteOfDay, settings)) {
        reminders.push(minuteOfDay);
      }
      offset += intervalMinutes;
    }
    return reminders;
  }

  private isMinuteInQuietHours(minuteOfDay: number, settings: ReminderSettings): boolean {
    if (!settings.quietHoursEnabled) {
      return false;
    }
    const hour: number = Math.floor(minuteOfDay / 60);
    return this.isHourInRange(hour, settings.quietStartHour, settings.quietEndHour);
  }

  private asMinutes(hour: number): number {
    const safeHour: number = Math.max(0, Math.min(23, Math.floor(hour)));
    return safeHour * 60;
  }

  private getWindowMinutes(startMinutes: number, endMinutes: number): number {
    if (startMinutes === endMinutes) {
      return 24 * 60;
    }
    if (startMinutes < endMinutes) {
      return endMinutes - startMinutes;
    }
    return (24 * 60 - startMinutes) + endMinutes;
  }

  private isHourInRange(currentHour: number, startHour: number, endHour: number): boolean {
    if (startHour === endHour) {
      return true;
    }
    if (startHour < endHour) {
      return currentHour >= startHour && currentHour < endHour;
    }
    return currentHour >= startHour || currentHour < endHour;
  }

  private hourText(value: number): string {
    return `${value}`.padStart(2, '0') + ':00';
  }

  static instance(): ReminderService {
    if (!ReminderService._instance) {
      ReminderService._instance = new ReminderService();
    }
    return ReminderService._instance;
  }
}
