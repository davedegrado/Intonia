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
  enum Status { trainedToday, keepStreak, start }

  let status: Status
  let streak: Int
  let title: String
  let message: String
  /// Ultimi 7 giorni, da 6 giorni fa a oggi: true se fanno parte della serie.
  let week: [Bool]

  var trainedToday: Bool { status == .trainedToday }

  static func of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Date) -> StreakContent {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    func daysBefore(_ date: Date, _ days: Int) -> Date {
      calendar.date(byAdding: .day, value: -days, to: date) ?? date
    }
    let today = formatter.string(from: now)
    let yesterday = formatter.string(from: daysBefore(now, 1))

    var week = Array(repeating: false, count: 7)
    if let last = lastTrainingDay, let lastDate = formatter.date(from: last),
      streakAtLastTraining > 0
    {
      let first = formatter.string(from: daysBefore(lastDate, streakAtLastTraining - 1))
      week = (0..<7).map { index in
        let day = formatter.string(from: daysBefore(now, 6 - index))
        return day >= first && day <= last
      }
    }

    func streakTitle(_ streak: Int) -> String {
      streak == 1 ? "1 giorno di fila" : "\(streak) giorni di fila"
    }

    if lastTrainingDay == today && streakAtLastTraining > 0 {
      return StreakContent(
        status: .trainedToday, streak: streakAtLastTraining,
        title: streakTitle(streakAtLastTraining),
        message: "Fatto oggi! Sei inarrestabile ✨", week: week)
    }
    if lastTrainingDay == yesterday && streakAtLastTraining > 0 {
      return StreakContent(
        status: .keepStreak, streak: streakAtLastTraining,
        title: streakTitle(streakAtLastTraining),
        message: "Allenati oggi per non perdere la serie! 🔥", week: week)
    }
    return StreakContent(
      status: .start, streak: 0, title: "Allena l'orecchio",
      message: "Pronto per l'allenamento di oggi? 🎵", week: week)
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

private func rgb(_ hex: UInt32, _ opacity: Double = 1) -> Color {
  Color(
    red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
    blue: Double(hex & 0xFF) / 255, opacity: opacity)
}

private let widgetGradient = LinearGradient(
  colors: [rgb(0x6D28D9), rgb(0x2A1B6E), rgb(0x0B0730)],
  startPoint: .topLeading, endPoint: .bottomTrailing)
private let cyan = rgb(0x22D3EE)
private let amber = rgb(0xFBBF24)

struct IntoniaWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StreakEntry

  private var content: StreakContent { entry.content }

  private var mascot: some View {
    ZStack {
      Circle()
        .fill(RadialGradient(
          colors: [cyan.opacity(0.55), cyan.opacity(0.18), cyan.opacity(0)],
          center: .center, startRadius: 0, endRadius: 50))
      Image(content.trainedToday ? "MascotHappy" : "MascotInvite")
        .resizable()
        .scaledToFit()
        .accessibilityLabel("Mascotte di Intonia")
    }
  }

  @ViewBuilder
  private func headline(numberSize: CGFloat) -> some View {
    if content.status == .start {
      Text(content.title)
        .font(.system(size: numberSize * 0.5, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    } else {
      let color = content.trainedToday ? cyan : amber
      HStack(alignment: .center, spacing: 6) {
        Text("\(content.streak)")
          .font(.system(size: numberSize, weight: .heavy, design: .rounded))
          .foregroundColor(color)
          .shadow(color: color.opacity(0.6), radius: 8)
        Text(content.streak == 1 ? "giorno\ndi fila" : "giorni\ndi fila")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(rgb(0xE0E7FF))
          .lineLimit(2)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(content.title)
    }
  }

  private var weekDots: some View {
    HStack(spacing: 5) {
      ForEach(0..<7, id: \.self) { index in
        let trained = content.week[index]
        let isToday = index == 6
        Circle()
          .fill(
            trained
              ? AnyShapeStyle(LinearGradient(
                colors: [cyan, rgb(0xA855F7)], startPoint: .topLeading, endPoint: .bottomTrailing))
              : AnyShapeStyle(isToday ? amber.opacity(0.2) : Color.white.opacity(0.12)))
          .overlay(Circle().stroke(amber, lineWidth: !trained && isToday ? 2 : 0))
          .frame(width: 11, height: 11)
      }
    }
    .accessibilityHidden(true)
  }

  private var pill: some View {
    Text(content.message)
      .font(.system(size: 11, weight: .bold))
      .foregroundColor(.white)
      .lineLimit(2)
      .minimumScaleFactor(0.85)
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(
        Group {
          if content.trainedToday {
            Capsule().fill(rgb(0x10B981, 0.2)).overlay(Capsule().stroke(rgb(0x34D399)))
          } else {
            Capsule().fill(LinearGradient(
              colors: [rgb(0xEC4899), rgb(0x8B5CF6)], startPoint: .leading, endPoint: .trailing))
          }
        })
  }

  var body: some View {
    Group {
      if family == .systemSmall {
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 4) {
            mascot.frame(width: 54, height: 54)
            headline(numberSize: 30)
          }
          weekDots
          pill
        }
      } else {
        HStack(spacing: 10) {
          mascot.frame(width: 104, height: 104)
          VStack(alignment: .leading, spacing: 7) {
            headline(numberSize: 40)
            weekDots
            pill
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
