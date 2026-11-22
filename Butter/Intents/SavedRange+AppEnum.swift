import AppIntents

/// Siri's description of the shared time ranges; kept with the intents so the
/// search code never imports App Intents.
extension SavedRange: AppEnum {
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation { "Time range" }

    nonisolated static var caseDisplayRepresentations: [SavedRange: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today"),
            .lastWeek: DisplayRepresentation(title: "Last week"),
            .lastMonth: DisplayRepresentation(title: "Last month"),
        ]
    }
}
