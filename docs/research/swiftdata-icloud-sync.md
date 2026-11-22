# SwiftData + iCloud: what backup and restore require

Research for [#4](https://github.com/joshaustintech/Butter/issues/4), feeding the decision in [#11](https://github.com/joshaustintech/Butter/issues/11) ("What exactly does Butter store and sync?"). Researched 2026-11-21 against Apple developer documentation, Apple technotes, WWDC sessions and Apple DTS forum answers. Butter targets iOS 26+, iPhone only, private CloudKit database, no server.

## Answer in brief

- SwiftData syncs to the user's **private CloudKit database** through `NSPersistentCloudKitContainer` ([S1]). On a new iPhone, the app's first launch schedules an **initial import** that pulls every Recipe down ([S6]). This is the restore path. It does not rely on iCloud device Backup, which by Apple's rule leaves out data that already syncs to iCloud ([S12]).
- The model must be **CloudKit-shaped**. That means: no `@Attribute(.unique)` / `#Unique`; every property optional or defaulted; every relationship optional, with an inverse; no `.deny` delete rule; no ordered relationships ([S1], [S2], [S7]).
- Photos go in a `Data` property marked `@Attribute(.externalStorage)`. Core Data moves any value too big for the 1 MB record into a `CKAsset` on its own ([S4], [S7]). Asset bytes count against the **user's own iCloud quota** ([S10]).
- **There is no restore-progress API.** You get start/finish events (setup, import, export), not a percentage ([S6], [S8]). SwiftData does not expose these events directly. On iOS 27 and later, `HistoryObserver` and `ResultsObserver` report that changes arrived, but not that the restore is finished ([S13], [S14]).
- **Signed out of iCloud:** the framework **wipes the synced store on the device by design**. It downloads everything again when the same account signs back in ([S9], [S15]). Changes that hadn't uploaded yet can be lost.
- **Schema changes are additive only once you go to production.** You can add types and fields. You can never rename, delete or retype them ([S1], [S2]).
- **Only one process may sync the store.** If the app and an extension both run `NSPersistentCloudKitContainer` on the same store, they conflict ([S7]). This matters for Butter's Share extension and Siri intents.

## 1. Model rules CloudKit imposes

| Rule | Source |
|---|---|
| No unique constraints. "CloudKit is unable to enforce the unique property option" (`@Attribute(.unique)`, and so `#Unique` too). | [S1], [S2] |
| All relationships must be optional. Inverses are required "in case the records synchronize out of order". SwiftData infers the inverse when it can; otherwise you set it explicitly. | [S1], [S2] |
| The `.deny` delete rule isn't supported. Use cascade or nullify. | [S1], [S2] |
| Every attribute must be optional or have a default. Apple's SwiftData sample uses defaults on every property. Records can arrive with fields missing. | [S1], [S2] |
| Ordered relationships aren't supported. A to-many array comes back in no guaranteed order, so **Steps need an explicit `position: Int`**. | [S7] |
| The `Undefined` and objectID attribute types aren't supported. Entities in one configuration can't relate to entities in another. | [S2] |
| Limits: 256 fields per record type, 1 MB per record (CKAsset fields don't count toward that), and the user's quota. | [S7] |
| Inheritance (new in iOS 26) maps to one record type for the root entity, plus a `CD_entityName` field. It works, but Butter doesn't need it. | [S4], [S11] |

Because there's no uniqueness, duplicates have to be handled in code. Give each Recipe a `UUID` attribute (stored as a string in CloudKit [S4]), and dedupe in app code after imports, the way Apple's sharing sample does ([S7]). The same reasoning covers Butter's "duplicate import of the same page" edge case: detect it in app logic, for example by matching on the Source URL. A database constraint won't do it.

## 2. Photos

- `@Attribute(.externalStorage)` (iOS 17+) "stores the property's value as binary data adjacent to the model storage" ([S3]).
- In CloudKit, a Binary Data attribute is written as `NSData` *or* `CKAsset`. Every variable-length attribute also gets a `CD_<name>_ckAsset` field. "If a field's value grows too large to store within the record size limit of 1MB, Core Data automatically converts the value to an external asset" ([S4]). No CKAsset code is needed.
- CKAsset fields don't count toward the 1 MB record limit ([S7]). I found no current Apple page that states a per-asset size cap, so don't plan around one. Do downscale and compress photos before saving (for example, a long edge of about 2000 px in HEIC or JPEG), because every byte counts against the user's iCloud storage ([S10]).
- Keep the photo on its own small model, for example a `RecipePhoto` in a to-one relationship with the Recipe, or at least in an external-storage property. Then lists and Siri queries never fault in the image bytes.
- The **photographed Source** (the original import image) is a second image per Recipe. Syncing it doubles the storage cost. That is a #11 decision (see the recommendation below).

## 3. First launch on a new iPhone (the restore)

- The restore is CloudKit sync, not device backup. iCloud Backup covers data "that don't already sync to iCloud" ([S12]). The supported path is: the user signs into the same Apple Account, installs Butter, and launches it.
- On that first launch, `NSPersistentCloudKitContainer` schedules "an import for the initial synchronization, which happens in the app's first launch session after being installed", along with imports on activation and on push ([S6]).
- The system decides when it runs. Exports and imports wait for `dasd` to approve them. Throttles (rate limit, low power, thermal) can delay them for hours, and "there is no API for apps to configure the timing" ([S6], [S7], [S8]). Imports may also finish only on a later launch ([S7]). Apple's engineers say sync is more aggressive after the app goes to the background and comes back ([S16]).
- **Detecting progress:**
  - `NSPersistentCloudKitContainer.eventChangedNotification` (iOS 14+) reports events of type `setup`, `import` or `export`, with `startDate`, `endDate` and `succeeded` ([S6], [S8]). Apple's technote: "To know the state of the synchronization, observe eventChangedNotification" ([S7]). SwiftData doesn't document this for its own containers. Because SwiftData runs on `NSPersistentCloudKitContainer` ([S1]), observing the notification with a `nil` object should work, but **confirm it on device**.
  - iOS 27 only: `HistoryObserver` "monitors a model container's data stores for remote changes" and increments `eventCounter`. `ResultsObserver` updates on "external changes from other processes or CloudKit sync" ([S13], [S14]). Both tell you something arrived. Neither says the import is complete.
  - None of these gives a percentage or an "all Recipes restored" signal.
- **What the user sees:** `@Query`-backed SwiftUI views update by themselves as imported Recipes land ([S11]). Don't block the UI. If the library is empty, `CKContainer.accountStatus()` returns `.available`, and no import event has finished successfully yet, show a gentle "Bringing your recipes from iCloud…" empty state. Fall back to the normal empty state after the first successful import, or after a timeout.

## 4. Signed out, iCloud full, account changes

- **No account, or iCloud turned off for Butter:** sync needs iCloud on for the app and a signed-in account ([S7]). Use `CKContainer.accountStatus()` before relying on the private database, and `CKAccountChanged` while the app runs ([S10]). Errors like "a user not being signed in" are transient and need no action ([S5]). A store with no account still works locally, but nothing is backed up.
- **Sign-out wipes the device copy by design.** From Apple DTS: the container "wipes off the Core Data store on the device when it gets notified that the user logs out iCloud. (This doesn't lead to data loss, because `NSPersistentCloudKitContainer` downloads the data from CloudKit when the user logs back in with the same iCloud account.)" ([S9]). For SwiftData specifically, "it is intentional that the framework deletes the local data when the user turns off iCloud for the app in Settings" ([S15]). There's no API to change this. Checking `accountStatus` and observing `CKAccountChanged` are partial mitigations at best, because "`NSPersistentCloudKitContainer` may still erase the data before you release the current model container" ([S17]). The real risk is **unsynced** edits made just before sign-out.
- **Account change (a different Apple Account):** the same mechanism runs. The old account's data leaves the device, and the new account's private database imports. Libraries never mix, which fits Butter's privacy rule.
- **iCloud full:** saving fails with `CKError.quotaExceeded`. In the private database, "the user doesn't have enough iCloud storage. Prompt the user to go to iCloud settings to manage their storage" ([S10]). With SwiftData the error surfaces only in the container's export event (`succeeded == false`, with an `error`) and in the logs. Local saves keep working, and export retries later.

## 5. Changing the model over time

- During development, the schema in the CloudKit Development environment can be reset and rewritten freely ([S2]).
- After promotion to Production: "the record types and their fields are immutable and exist for all time. You can add new record types, and additional fields to existing record types, but you can't modify or delete existing record types" ([S2]). SwiftData's docs say the same: "you're unable to delete model types or change existing model attributes after you promote a schema to production" ([S1]).
- If the app's model has a field the production schema lacks, sync stops ("Cannot create or modify field … in production schema") ([S7]). **TestFlight builds use the Production environment.** If a debug build syncs but TestFlight doesn't, "it is most likely because you haven't deployed your CloudKit schema to the production environment" ([S7]).
- On device, use `VersionedSchema` and `SchemaMigrationPlan` (iOS 17+), with lightweight or custom stages ([S11], [S18]). With CloudKit, keep every version **additive**: new optional or defaulted properties and new models only. `originalName` renames are lightweight locally but create a new CloudKit field, and old versions of the app keep the old one.
- Apple's strategies for bigger changes: add fields incrementally, add a `version` attribute from the start, or move to a new store in a new container ([S2]). **Recommendation: give each model a `schemaVersion: Int = 1` now.**
- iOS 27's `.codable` attribute option "will not trigger a migration" when the type's shape changes, and can't be used in predicates or sorts ([S13], [S19]). Avoid it for Recipe data.
- Apple engineers' advice: keep a corpus of stores from every shipped version for migration tests, and never run migrations from an extension ([S16]).

## 6. Entitlements and container setup

1. **iCloud capability, with CloudKit checked**, and a container such as `iCloud.<bundle id>`. Checking CloudKit "also adds push notifications" ([S5]). This needs a developer account with admin permissions ([S1]).
2. **Background Modes → Remote notifications**, so CloudKit can push changes silently ([S1], [S5]).
3. SwiftData uses the first container in the entitlements, unless you pass `ModelConfiguration(cloudKitDatabase: .private("iCloud.…"))`. Pass the identifier explicitly ([S1]).
4. In DEBUG builds only, initialize the development schema. SwiftData's documented recipe loads the same store with `NSPersistentCloudKitContainer`, calls `initializeCloudKitSchema()`, then unloads it before creating the `ModelContainer` ([S1]). Then **deploy the schema to Production in CloudKit Console before the first TestFlight build** ([S2], [S7]).
5. If you see "Invalid bundle ID for container", the container isn't associated with the App ID. Containers can be hidden but never deleted ([S7]).
6. **Extensions:** two `NSPersistentCloudKitContainer` instances on one store, for example the app and a Share extension using an App Group store, produce error 134410. Apple advises "having the app in charge of the synchronization" ([S7]). Apple engineers add: "You don't want to give your widget or extension the entitlement to have for the CloudKit entitlement", and to use a separate non-synced configuration if needed ([S16]).

## 7. Simulator vs. device

**On the installed simulator, signed into a test Apple Account:**
- Schema initialization against the Development environment, and checking record types and records in CloudKit Console ([S1], [S2]).
- Export, and import after a relaunch or after backgrounding. The simulator receives remote notifications on Apple silicon or T2 Macs ([S20]), and Apple engineers suggest backgrounding the app in the simulator to get realistic sync ([S16]).
- Model rules, migrations between `VersionedSchema`s, and dedupe logic. Stop with the Xcode stop button only after a save, because "if you force quit the app in Xcode by hitting the stop button, autosave never actually happens" ([S16]).
- Reading the sync logs (`com.apple.CoreData.CloudKitDebug`, `log stream`) ([S5]).

**Real devices (iPhone 15 / 15 Pro) and TestFlight are needed for:**
- The real restore: a clean install on a second iPhone signed into the same account, against the **Production** schema.
- Real push delivery, throttling, low-power and thermal behaviour ([S6]).
- Sign-out and turning iCloud off for the app (the wipe and the re-download), and a full iCloud account.
- Apple's own troubleshooting assumes "two unlocked devices logged into the same iCloud account" ([S5]).

## iOS 26 vs. iOS 27

| | iOS 26 (Butter's minimum) | iOS 27 |
|---|---|---|
| CloudKit model rules | Unchanged since iOS 17 | No documented change |
| New SwiftData APIs | Model inheritance; `HistoryDescriptor.sortBy` ([S11], [S21]) | `HistoryObserver`, `ResultsObserver`, `.codable` attribute, sectioned queries ([S13], [S14], [S19], [S21]) |
| Detecting imported changes | `@Query` updates automatically; history via `fetchHistory` with polling or tokens | `HistoryObserver.eventCounter` (still no "restore finished" signal) |

Anything from iOS 27 must sit behind `if #available(iOS 27, *)`. Nothing in iOS 27 changes what Butter's model has to look like.

## Recommendation for #11 ("What exactly does Butter store and sync?")

1. **Sync everything in one private CloudKit-backed SwiftData store.** That covers Recipe, Ingredient, Step, the photo, the Source (URL or image), and the Saved and Updated dates. This is the only supported way to get automatic restore on a new iPhone.
2. Shape the model for CloudKit:
   - Defaults everywhere.
   - Optional relationships with inverses and cascade delete.
   - `Step.position: Int`, and an `Ingredient.position: Int` too.
   - `id: UUID` and `schemaVersion: Int` on Recipe.
   - No unique constraints. Dedupe in code.
3. Store images as downscaled HEIC or JPEG in `.externalStorage` `Data`, ideally on a separate model. Decide in #11 whether a **photographed Source image** syncs at full size, at reduced size, or not at all. It is the biggest driver of the user's iCloud usage.
4. **Keep transient state local and unsynced**, in a second, non-CloudKit `ModelConfiguration` or in `UserDefaults`. That covers Cooking session progress, the "last Siri result" used for "open it", and import queues. Synced data stays small and additive.
5. **Make the main app the only process that syncs.** If a Share extension or an out-of-process App Intent saves an import, write it to a local, non-synced App Group "inbox". The app moves it into the synced store when it next runs, or the intent runs in the app process.
6. Deploy the CloudKit schema to Production before the first TestFlight build. Treat every later model change as additive only.
7. UX: a non-blocking "bringing your recipes from iCloud" empty state, a notice when iCloud is signed out or full, and no promise of restore progress.

## Sources

- [S1] Apple, *Syncing model data across a person's devices* (SwiftData). https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- [S2] Apple, *Creating a Core Data Model for CloudKit*. https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit
- [S3] Apple, `Schema.Attribute.Option.externalStorage`. https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage
- [S4] Apple, *Reading CloudKit Records for Core Data*. https://developer.apple.com/documentation/coredata/reading-cloudkit-records-for-core-data
- [S5] Apple, *Setting Up Core Data with CloudKit* and *Syncing a Core Data Store with CloudKit*. https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit and https://developer.apple.com/documentation/coredata/syncing-a-core-data-store-with-cloudkit
- [S6] Apple, *TN3163: Understanding the synchronization of NSPersistentCloudKitContainer*. https://developer.apple.com/documentation/technotes/tn3163-understanding-the-synchronization-of-nspersistentcloudkitcontainer
- [S7] Apple, *TN3164: Debugging the synchronization of NSPersistentCloudKitContainer*. https://developer.apple.com/documentation/technotes/tn3164-debugging-the-synchronization-of-nspersistentcloudkitcontainer
- [S8] Apple, `NSPersistentCloudKitContainer.eventChangedNotification` / `Event` / `EventType`. https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer/eventchangednotification
- [S9] Apple DTS (Ziqiao Chen), forum answer, Sep 2024. https://developer.apple.com/forums/thread/764080?answerId=804739022
- [S10] Apple, `CKContainer.accountStatus()`, `CKAccountChanged`, `CKError.Code.quotaExceeded`, `CKAsset`. https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus(completionhandler:) · https://developer.apple.com/documentation/foundation/nsnotification/name-swift.struct/ckaccountchanged · https://developer.apple.com/documentation/cloudkit/ckerror/code/quotaexceeded · https://developer.apple.com/documentation/cloudkit/ckasset
- [S11] WWDC25 *SwiftData: Dive into inheritance and schema migration*. https://developer.apple.com/videos/play/wwdc2025/291/
- [S12] Apple Support, *What does iCloud back up?* https://support.apple.com/en-us/108770
- [S13] Apple, `HistoryObserver` (iOS 27+), and WWDC26 *What's new in SwiftData*. https://developer.apple.com/documentation/swiftdata/historyobserver · https://developer.apple.com/videos/play/wwdc2026/274/
- [S14] Apple, `ResultsObserver` (iOS 27+). https://developer.apple.com/documentation/swiftdata/resultsobserver
- [S15] Apple DTS (Ziqiao Chen), forum answer on SwiftData, Nov 2025. https://developer.apple.com/forums/thread/805940
- [S16] WWDC26 *SwiftData Group Lab*. https://developer.apple.com/videos/play/wwdc2026/8017/
- [S17] Apple DTS (Ziqiao Chen), forum answer, Jan 2025. https://developer.apple.com/forums/thread/771870
- [S18] WWDC23 *Model your schema with SwiftData*. https://developer.apple.com/videos/play/wwdc2023/10195/
- [S19] Apple, `Schema.Attribute.Option.codable` (iOS 27+). https://developer.apple.com/documentation/swiftdata/schema/attribute/option/codable
- [S20] Apple, *Xcode 14 Release Notes* (Simulator supports remote notifications). https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes
- [S21] Apple, *SwiftData updates*. https://developer.apple.com/documentation/updates/swiftdata
