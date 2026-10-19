import SwiftUI
import WidgetKit

/// App Group condiviso con l'app (HomeWidgetService.appGroupId).
private let appGroupId = "group.io.github.davedegrado.intonia"
private let keyLastTrainingDay = "intonia_last_training_day"
private let keyStreak = "intonia_streak_at_last_training"
private let keyPrecisionDays = "intonia_precision_days"
private let keyLanguage = "intonia_language"

/// Testi dei widget nella lingua scelta nell'app (salvata da
/// HomeWidgetService); senza indicazioni, italiano se il dispositivo è in
/// italiano, altrimenti inglese (come l'app per le lingue non supportate).
enum WidgetStrings {
  static var italian: Bool {
    let appLanguage = UserDefaults(suiteName: appGroupId)?.string(forKey: keyLanguage)
    let language = appLanguage ?? Locale.preferredLanguages.first ?? "en"
    return language.hasPrefix("it")
  }

  // Serie.

  static func streakTitle(_ streak: Int) -> String {
    if italian {
      return streak == 1 ? "1 giorno di fila" : "\(streak) giorni di fila"
    }
    return streak == 1 ? "1 day in a row" : "\(streak) days in a row"
  }

  static func streakLabel(_ streak: Int) -> String {
    if italian {
      return streak == 1 ? "giorno\ndi fila" : "giorni\ndi fila"
    }
    return streak == 1 ? "day\nin a row" : "days\nin a row"
  }

  static var startMessage: String {
    italian ? "Inizia oggi la tua serie!" : "Start your streak today!"
  }
  static var keepStreakMessage: String {
    italian ? "Allenati oggi per non perdere la serie!" : "Practise today to keep your streak!"
  }
  static var firstDayMessage: String {
    italian ? "Primo giorno: ottimo inizio!" : "Day one: great start!"
  }
  static var trainedMessage: String {
    italian ? "Continua così, sei sulla strada giusta!" : "Keep it up, you're on track!"
  }
  static var mascot: String { italian ? "Mascotte di Intonia" : "Intonia mascot" }
  static var streakName: String { italian ? "Serie" : "Streak" }
  static var streakDescription: String {
    italian
      ? "La tua serie di allenamenti con la mascotte di Intonia."
      : "Your Intonia training streak with the mascot."
  }

  // Precisione.

  static var precisionName: String { italian ? "Precisione" : "Accuracy" }
  static var precisionDescription: String {
    italian
      ? "La tua precisione media della settimana, giorno per giorno."
      : "Your average pitch accuracy this week, day by day."
  }
  static var precisionTitle: String { italian ? "Precisione media" : "Average accuracy" }
  static var precisionPeriod: String { italian ? "Questa settimana" : "This week" }
  static var precisionNone: String {
    italian ? "Nessuna precisione misurata questa settimana" : "No accuracy measured this week yet"
  }
  static func precisionPercent(_ percent: Int) -> String {
    italian
      ? "Precisione media della settimana: \(percent) per cento"
      : "Average accuracy this week: \(percent) percent"
  }
  static func message(_ message: PrecisionContent.Message) -> String {
    switch message {
    case .empty: return italian ? "Fai un esercizio per misurarla" : "Do an exercise to measure it"
    case .improved:
      return italian ? "Voce sempre più intonata!" : "Your voice is more and more in tune!"
    case .high: return italian ? "Intonazione eccellente!" : "Excellent pitch!"
    case .mid: return italian ? "Buona intonazione, continua così!" : "Good pitch, keep going!"
    case .low: return italian ? "Ogni esercizio affina la tua voce" : "Every exercise sharpens your voice"
    }
  }
  static var weekdays: [String] {
    italian
      ? ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]
      : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  }
  static func day(_ name: String, _ status: PrecisionContent.DayStatus, percent: Int?) -> String {
    switch status {
    case .measured:
      let value = percent ?? 0
      return italian ? "\(name): precisione \(value) per cento" : "\(name): accuracy \(value) percent"
    case .activityOnly:
      return italian ? "\(name): allenamento senza note valutate" : "\(name): practice without scored notes"
    case .empty: return italian ? "\(name): nessun allenamento" : "\(name): no practice"
    case .future: return italian ? "\(name): non ancora arrivato" : "\(name): not yet"
    }
  }
}

/// Giorno locale nel formato `yyyy-MM-dd` usato dall'app.
private let dayFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter
}()

/// [date] spostata di [days] giorni di calendario (negativo = indietro).
private func addDays(_ date: Date, _ days: Int) -> Date {
  Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}

/// Contenuto del widget della serie. Stessa logica di WidgetView
/// (lib/features/home_widget/domain/widget_streak.dart) e di WidgetContent
/// (IntoniaWidgetProvider.kt).
struct StreakContent {
  enum Status { case trainedToday, firstDay, keepStreak, start }

  let status: Status
  /// Giorni di fila mostrati (0 se la serie non è in corso).
  let streak: Int

  var celebrating: Bool { status == .trainedToday || status == .firstDay }

  var message: String {
    switch status {
    case .trainedToday: return WidgetStrings.trainedMessage
    case .firstDay: return WidgetStrings.firstDayMessage
    case .keepStreak: return WidgetStrings.keepStreakMessage
    case .start: return WidgetStrings.startMessage
    }
  }

  static func of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Date) -> StreakContent {
    let today = dayFormatter.string(from: now)
    let yesterday = dayFormatter.string(from: addDays(now, -1))
    let alive =
      streakAtLastTraining > 0 && (lastTrainingDay == today || lastTrainingDay == yesterday)
    if !alive {
      return StreakContent(status: .start, streak: 0)
    }
    let status: Status =
      lastTrainingDay == yesterday
      ? .keepStreak : (streakAtLastTraining == 1 ? .firstDay : .trainedToday)
    return StreakContent(status: status, streak: streakAtLastTraining)
  }

  static func load(now: Date) -> StreakContent {
    let defaults = UserDefaults(suiteName: appGroupId)
    let day = defaults?.string(forKey: keyLastTrainingDay)
    let streak = Int(defaults?.string(forKey: keyStreak) ?? "") ?? 0
    return of(lastTrainingDay: day, streakAtLastTraining: streak, now: now)
  }
}

/// Contenuto del widget della precisione: settimana in corso da lunedì a
/// domenica (ora locale). Stessa logica di PrecisionWidgetView
/// (lib/features/home_widget/domain/widget_precision.dart) e di
/// PrecisionContent (IntoniaPrecisionWidgetProvider.kt).
struct PrecisionContent {
  enum DayStatus { case measured, activityOnly, empty, future }
  enum Message { case empty, improved, high, mid, low }

  struct Totals {
    let correct: Int
    let attempts: Int
    let sessions: Int
  }

  /// Sette giorni, da lunedì (indice 0) a domenica.
  let days: [DayStatus]
  let dayPercents: [Int?]
  let todayIndex: Int
  /// Precisione media della settimana; nil se nessuna nota valutata.
  let percent: Int?
  let message: Message

  /// Formato dell'app: `giorno:corrette:valutate:sessioni` separati da `;`.
  static func decode(_ raw: String?) -> [String: Totals] {
    guard let raw = raw, !raw.isEmpty else { return [:] }
    var days: [String: Totals] = [:]
    for item in raw.split(separator: ";") {
      let parts = item.split(separator: ":", omittingEmptySubsequences: false)
      guard parts.count == 4 else { continue }
      let numbers = parts.dropFirst().map { Int($0) }
      guard numbers.allSatisfy({ ($0 ?? -1) >= 0 }) else { continue }
      days[String(parts[0])] = Totals(
        correct: numbers[0]!, attempts: numbers[1]!, sessions: numbers[2]!)
    }
    return days
  }

  private static func percentOf(_ correct: Int, _ attempts: Int) -> Int? {
    attempts == 0 ? nil : Int((Double(correct) * 100 / Double(attempts)).rounded())
  }

  static func of(_ data: [String: Totals], now: Date) -> PrecisionContent {
    // weekday: 1 = domenica … 7 = sabato → lunedì = 0, domenica = 6.
    let weekday = Calendar(identifier: .gregorian).component(.weekday, from: now)
    let todayIndex = (weekday + 5) % 7
    // Giorni di calendario: il cambio dell'ora legale non sposta i confini.
    func day(_ offset: Int) -> String { dayFormatter.string(from: addDays(now, offset - todayIndex)) }

    var previousCorrect = 0
    var previousAttempts = 0
    for i in -7..<0 {
      if let totals = data[day(i)] {
        previousCorrect += totals.correct
        previousAttempts += totals.attempts
      }
    }

    var correct = 0
    var attempts = 0
    var days: [DayStatus] = []
    var dayPercents: [Int?] = []
    for i in 0..<7 {
      let totals = i > todayIndex ? nil : data[day(i)]
      correct += totals?.correct ?? 0
      attempts += totals?.attempts ?? 0
      if i > todayIndex {
        days.append(.future)
      } else if let totals = totals, totals.sessions > 0 {
        days.append(totals.attempts > 0 ? .measured : .activityOnly)
      } else {
        days.append(.empty)
      }
      dayPercents.append(totals.flatMap { percentOf($0.correct, $0.attempts) })
    }
    let percent = percentOf(correct, attempts)
    let previous = percentOf(previousCorrect, previousAttempts)
    let message: Message
    if let percent = percent {
      if let previous = previous, percent > previous {
        message = .improved
      } else if percent >= 80 {
        message = .high
      } else if percent >= 60 {
        message = .mid
      } else {
        message = .low
      }
    } else {
      message = .empty
    }
    return PrecisionContent(
      days: days, dayPercents: dayPercents, todayIndex: todayIndex, percent: percent,
      message: message)
  }

  static func load(now: Date) -> PrecisionContent {
    let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: keyPrecisionDays)
    return of(decode(raw), now: now)
  }
}

/// Contenuto di adesso e di mezzanotte (cambio di giorno e di settimana);
/// l'app chiede un aggiornamento a ogni nuova sessione.
private func midnightTimeline<Entry: TimelineEntry>(_ make: (Date) -> Entry) -> Timeline<Entry> {
  let now = Date()
  let midnight =
    Calendar.current.nextDate(
      after: now, matching: DateComponents(hour: 0, minute: 0, second: 5),
      matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
  return Timeline(entries: [make(now), make(midnight)], policy: .after(midnight))
}

struct StreakEntry: TimelineEntry {
  let date: Date
  let content: StreakContent
}

struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry {
    StreakEntry(date: Date(), content: StreakContent(status: .start, streak: 0))
  }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    completion(StreakEntry(date: Date(), content: StreakContent.load(now: Date())))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    completion(midnightTimeline { StreakEntry(date: $0, content: StreakContent.load(now: $0)) })
  }
}

struct PrecisionEntry: TimelineEntry {
  let date: Date
  let content: PrecisionContent
}

struct PrecisionProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrecisionEntry {
    PrecisionEntry(date: Date(), content: PrecisionContent.of([:], now: Date()))
  }

  func getSnapshot(in context: Context, completion: @escaping (PrecisionEntry) -> Void) {
    completion(PrecisionEntry(date: Date(), content: PrecisionContent.load(now: Date())))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrecisionEntry>) -> Void) {
    completion(
      midnightTimeline { PrecisionEntry(date: $0, content: PrecisionContent.load(now: $0)) })
  }
}

// Palette: la notte indaco di Intonia.

private func rgb(_ hex: UInt32, _ opacity: Double = 1) -> Color {
  Color(
    red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
    blue: Double(hex & 0xFF) / 255, opacity: opacity)
}

private let widgetGradient = LinearGradient(
  colors: [rgb(0x1E1B57), rgb(0x241A63), rgb(0x161443)],
  startPoint: .topLeading, endPoint: .bottomTrailing)
private let cyan = rgb(0x5EEAF4)
private let sky = rgb(0x7DD3FC)
private let violet = rgb(0xA855F7)
private let magenta = rgb(0xE879F9)
private let muted = rgb(0xC7C9F2)
private let onDot = rgb(0x1B1846)
private let cardBorder = rgb(0x3B3592)
private let numberGradient = LinearGradient(
  colors: [cyan, sky, rgb(0x8B9CFA)], startPoint: .top, endPoint: .bottom)

/// Colore del giorno [index] (0 = lunedì), dal ciano al viola.
private func dayColor(_ index: Int) -> Color {
  let t = Double(index) / 6
  func mix(_ a: UInt32, _ b: UInt32, _ shift: UInt32) -> Double {
    (Double((a >> shift) & 0xFF) * (1 - t) + Double((b >> shift) & 0xFF) * t) / 255
  }
  return Color(
    red: mix(0x5EEAF4, 0xA855F7, 16), green: mix(0x5EEAF4, 0xA855F7, 8),
    blue: mix(0x5EEAF4, 0xA855F7, 0))
}

struct StreakWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StreakEntry

  private var content: StreakContent { entry.content }
  private var sceneName: String { content.celebrating ? "SceneHappy" : "SceneInvite" }

  private func number(size: CGFloat) -> some View {
    HStack(alignment: .center, spacing: 8) {
      Text("\(content.streak)")
        .font(.system(size: size, weight: .black, design: .rounded))
        .foregroundStyle(numberGradient)
        .shadow(color: cyan.opacity(0.45), radius: 10)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
      Text(verbatim: WidgetStrings.streakLabel(content.streak))
        .font(.system(size: size * 0.3, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
  }

  private var message: some View {
    Text(content.message)
      .font(.system(size: 13, weight: .medium))
      .foregroundColor(muted)
      .lineLimit(2)
      .minimumScaleFactor(0.85)
      .fixedSize(horizontal: false, vertical: true)
  }

  var body: some View {
    Group {
      if family == .systemSmall {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 2) {
            Image(sceneName)
              .resizable()
              .scaledToFit()
              .frame(width: 64, height: 60)
              .accessibilityHidden(true)
            number(size: 36)
          }
          message
        }
        .widgetBackground(widgetGradient)
      } else {
        // La scena (mascotte, alone, nuvole) è lo sfondo della metà sinistra,
        // a tutta altezza; il testo occupa la metà destra.
        GeometryReader { geo in
          HStack(spacing: 0) {
            Color.clear.frame(width: geo.size.width * 0.4)
            VStack(alignment: .leading, spacing: 6) {
              number(size: 48)
              message
            }
            Spacer(minLength: 0)
          }
          .frame(maxHeight: .infinity)
        }
        .widgetBackground(
          ZStack(alignment: .leading) {
            widgetGradient
            GeometryReader { geo in
              Image(sceneName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width * 0.46, height: geo.size.height)
                .clipped()
            }
          })
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      Text("\(WidgetStrings.streakTitle(content.streak)). \(content.message)"))
  }
}

struct PrecisionWidgetView: View {
  let entry: PrecisionEntry

  private var content: PrecisionContent { entry.content }
  private let dot: CGFloat = 22

  private var summary: some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(spacing: 6) {
        Image(systemName: "waveform")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(cyan)
        Text(WidgetStrings.precisionTitle)
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(.white)
          .lineLimit(1)
      }
      Text(content.percent.map { "\($0)%" } ?? "—")
        .font(.system(size: 32, weight: .black, design: .rounded))
        .foregroundColor(content.percent == nil ? muted : cyan)
        .shadow(color: cyan.opacity(0.35), radius: 8)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(WidgetStrings.precisionPeriod)
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(muted)
        .lineLimit(1)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      Text(content.percent.map(WidgetStrings.precisionPercent) ?? WidgetStrings.precisionNone))
  }

  private var pill: some View {
    HStack(spacing: 4) {
      Text(WidgetStrings.message(content.message))
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.white)
        .lineLimit(3)
        .minimumScaleFactor(0.8)
      Image(systemName: "music.note")
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(magenta)
        .accessibilityHidden(true)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1)))
  }

  private func active(_ index: Int) -> Bool {
    guard content.days.indices.contains(index) else { return false }
    return content.days[index] == .measured || content.days[index] == .activityOnly
  }

  /// Ogni stato ha forma e simbolo propri, non solo il colore.
  @ViewBuilder
  private func dayDot(_ index: Int) -> some View {
    let color = dayColor(index)
    let isToday = index == content.todayIndex
    switch content.days[index] {
    case .measured:
      Circle().fill(color)
        .overlay(
          Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy))
            .foregroundColor(onDot))
    case .activityOnly:
      Circle().fill(color.opacity(0.25))
        .overlay(Circle().stroke(color, lineWidth: 2))
        .overlay(
          Image(systemName: "minus").font(.system(size: 10, weight: .heavy))
            .foregroundColor(.white))
    case .empty:
      Circle().fill(onDot)
        .overlay(
          Circle().stroke(
            Color.white.opacity(isToday ? 0.9 : 0.35), lineWidth: isToday ? 2 : 1.5))
    case .future:
      Circle().stroke(Color.white.opacity(0.22), lineWidth: 1.5)
    }
  }

  private func line(lit: Bool, color: Color, hidden: Bool) -> some View {
    Rectangle()
      .fill(lit ? color : Color.white.opacity(0.2))
      .frame(height: 2)
      .opacity(hidden ? 0 : 1)
  }

  private var week: some View {
    let names = WidgetStrings.weekdays
    return HStack(spacing: 0) {
      ForEach(0..<7, id: \.self) { index in
        let color = dayColor(index)
        VStack(spacing: 3) {
          ZStack {
            // Linea accesa solo fra due giorni consecutivi con allenamento.
            HStack(spacing: 0) {
              line(lit: active(index) && active(index - 1), color: color, hidden: index == 0)
              Color.clear.frame(width: dot)
              line(lit: active(index) && active(index + 1), color: color, hidden: index == 6)
            }
            dayDot(index).frame(width: dot, height: dot)
          }
          .frame(height: dot + 2)
          Text(names[index])
            .font(.system(size: 11, weight: index == content.todayIndex ? .heavy : .medium))
            .foregroundColor(
              content.days[index] == .future ? muted.opacity(0.55) : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          Text(
            WidgetStrings.day(
              names[index], content.days[index], percent: content.dayPercents[index])))
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center, spacing: 8) {
        summary
        Spacer(minLength: 0)
        pill
      }
      week
    }
    .widgetBackground(widgetGradient)
  }
}

extension View {
  /// Sfondo compatibile con iOS 17+ (containerBackground) e versioni precedenti.
  @ViewBuilder
  func widgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) { background }
    } else {
      self.padding().background(background)
    }
  }
}

struct IntoniaWidget: Widget {
  /// Deve coincidere con HomeWidgetService.iOSWidgetKind.
  let kind = "IntoniaWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
      StreakWidgetView(entry: entry)
    }
    .configurationDisplayName(WidgetStrings.streakName)
    .description(WidgetStrings.streakDescription)
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct IntoniaPrecisionWidget: Widget {
  /// Deve coincidere con HomeWidgetService.iOSPrecisionWidgetKind.
  let kind = "IntoniaPrecisionWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrecisionProvider()) { entry in
      PrecisionWidgetView(entry: entry)
    }
    .configurationDisplayName(WidgetStrings.precisionName)
    .description(WidgetStrings.precisionDescription)
    .supportedFamilies([.systemMedium])
  }
}

@main
struct IntoniaWidgets: WidgetBundle {
  var body: some Widget {
    IntoniaWidget()
    IntoniaPrecisionWidget()
  }
}
