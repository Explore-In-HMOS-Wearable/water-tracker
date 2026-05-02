# Water Tracker

A simple water tracker app to help users stay hydrated by tracking their daily water intake goals.

# Preview

<p align="left">
  <img src="screenshots/water1.png" width="24%">
  <img src="screenshots/water2.png" width="24%">
  <img src="screenshots/water3.png" width="24%">
</p>

# Use Cases

Ideal for fitness enthusiasts or anyone aiming to improve daily water consumption through simple yet effective tracking.

# Tech Stack

- **Languages**: ArkTS, TypeScript
- **Frameworks**: HarmonyOS SDK 6.0.0(20)
- **Tools**: DevEco Studio 6.0.0
- **Kits/Libraries**: `@kit.AbilityKit`, `@kit.ArkUI`, `@kit.ArkData`, `@kit.FormKit`, `@kit.BackgroundTasksKit`, `@kit.NotificationKit`, `@kit.PerformanceAnalysisKit`, `@kit.BasicServicesKit`, `@kit.CoreFileKit`

# Directory Structure

```entry/src/main/ets/
|---core
| |---services
| | |---BaseViewModel.ets # Base view model
| | |---RouteService.ets # Route Service
| | |---WaterService.ets # Water Service
|---entryability
| |---EntryAbility.ets
|---entrybackupability
| |---EntryBackupAbility.ets
|---ui
| |---pages
| | |---Index.ets
| | |---SetTargetPage.ets # Target Setting Page
| |---viewmodels
| | |---IndexViewModel.ets
| |---widgets
| | |---SetTargetButton.ets # Button component
| | |---SingleWaterItem.ets # Water item component
```

# Constraints and Restrictions
## Supported Devices
- Huawei Watch 5

# LICENSE

water-tracker is distributed under the terms of the MIT License.
See the [LICENSE](/LICENSE) for more information.
