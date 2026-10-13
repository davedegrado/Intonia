import SwiftUI
import WidgetKit

/// App Group condiviso con l'app (HomeWidgetService.appGroupId).
private let appGroupId = "group.io.github.davedegrado.intonia"
private let keyLastTrainingDay = "intonia_last_training_day"
private let keyStreak = "intonia_streak_at_last_training"

/// Contenuto del widget. Stessa logica di WidgetView
/// (lib/features/home_widget/domain/widget_streak.dart) e di WidgetContent
/// (IntoniaWidgetProvider.kt).
struct StreakContent {
  let trainedToday: Bool
  let title: String
  let message: String

  static func of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Date) -> StreakContent {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: now)
    let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
    let yesterday = formatter.string(from: yesterdayDate)

    func streakTitle(_ streak: Int) -> String {
      streak == 1 ? "1 giorno di fila" : "\(streak) giorni di fila"
    }

    if lastTrainingDay == today && streakAtLastTraining > 0 {
      return StreakContent(
        trainedToday: true,
        title: streakTitle(streakAtLastTraining),
        message: "Allenamento fatto. Sei inarrestabile!")
    }
    if lastTrainingDay == yesterday && streakAtLastTraining > 0 {
      return StreakContent(
        trainedToday: false,
        title: streakTitle(streakAtLastTraining),
        message: "Allenati oggi per non perdere la serie!")
    }
    return StreakContent(
      trainedToday: false,
      title: "Allena l'orecchio",
      message: "Pronto per l'allenamento di oggi?")
  }

  static func load(now: Date) -> StreakContent {
    let defaults = UserDefaults(suiteName: appGroupId)
    let day = defaults?.string(forKey: keyLastTrainingDay)
    let streak = Int(defaults?.string(forKey: keyStreak) ?? "") ?? 0
    return of(lastTrainingDay: day, streakAtLastTraining: streak, now: now)
  }
}

struct StreakEntry: TimelineEntry {
  let date: Date
  let content: StreakContent
}

struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry {
    StreakEntry(
      date: Date(),
      content: StreakContent.of(lastTrainingDay: nil, streakAtLastTraining: 0, now: Date()))
  }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    completion(StreakEntry(date: Date(), content: StreakContent.load(now: Date())))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    // Contenuto di adesso e di mezzanotte (cambio giorno); l'app chiede un
    // aggiornamento a ogni nuova sessione.
    let now = Date()
    let midnight = Calendar.current.nextDate(
      after: now, matching: DateComponents(hour: 0, minute: 0, second: 5),
      matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
    let entries = [
      StreakEntry(date: now, content: StreakContent.load(now: now)),
      StreakEntry(date: midnight, content: StreakContent.load(now: midnight)),
    ]
    completion(Timeline(entries: entries, policy: .after(midnight)))
  }
}

private let widgetGradient = LinearGradient(
  colors: [Color(red: 0.106, green: 0.086, blue: 0.251), Color(red: 0.012, green: 0.004, blue: 0.102)],
  startPoint: .topLeading, endPoint: .bottomTrailing)

struct IntoniaWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StreakEntry

  var body: some View {
    let content = entry.content
    let mascot = Image(content.trainedToday ? "MascotHappy" : "MascotInvite")
      .resizable()
      .scaledToFit()
      .accessibilityLabel("Mascotte di Intonia")

    Group {
      if family == .systemSmall {
        VStack(alignment: .leading, spacing: 2) {
          mascot.frame(height: 64)
          Text(content.title)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
          Text(content.message)
            .font(.system(size: 11))
            .foregroundColor(Color(red: 0.78, green: 0.82, blue: 1.0))
            .lineLimit(2)
            .minimumScaleFactor(0.8)
        }
      } else {
        HStack(spacing: 10) {
          mascot.frame(width: 96, height: 96)
          VStack(alignment: .leading, spacing: 4) {
            Text(content.title)
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.white)
              .lineLimit(2)
            Text(content.message)
              .font(.system(size: 14))
              .foregroundColor(Color(red: 0.78, green: 0.82, blue: 1.0))
              .lineLimit(3)
          }
          Spacer(minLength: 0)
        }
      }
    }
    .widgetBackground(widgetGradient)
  }
}

extension View {
  /// Sfondo compatibile con iOS 17+ (containerBackground) e versioni precedenti.
  @ViewBuilder
  func widgetBackground(_ gradient: LinearGradient) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { gradient }
    } else {
      self.padding().background(gradient)
    }
  }
}

@main
struct IntoniaWidget: Widget {
  /// Deve coincidere con HomeWidgetService.iOSWidgetKind.
  let kind = "IntoniaWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
      IntoniaWidgetView(entry: entry)
    }
    .configurationDisplayName("Intonia")
    .description("La tua serie di allenamenti con la mascotte di Intonia.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
