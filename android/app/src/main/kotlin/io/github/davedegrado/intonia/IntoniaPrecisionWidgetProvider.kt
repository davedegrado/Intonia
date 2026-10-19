package io.github.davedegrado.intonia

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Resources
import android.graphics.Color
import android.graphics.Typeface
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import kotlin.math.roundToInt

/**
 * Widget della precisione settimanale: precisione media della settimana in
 * corso (da lunedì a domenica, ora locale) e i sette giorni. L'app pubblica i
 * totali per giorno (HomeWidgetService); la settimana è ricavata qui, così il
 * widget resta corretto anche ad app chiusa. Stessa logica di
 * PrecisionWidgetView (lib/features/home_widget/domain/widget_precision.dart).
 */
class IntoniaPrecisionWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val content =
        PrecisionContent.of(
            PrecisionContent.decode(widgetData.getString(WidgetKeys.PRECISION_DAYS, null)),
            Calendar.getInstance(),
        )
    val res = localizedResources(context, widgetData.getString(WidgetKeys.LANGUAGE, null))
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_precision)
      bind(res, views, content)
      views.setOnClickPendingIntent(
          R.id.widget_root,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
      )
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun bind(res: Resources, views: RemoteViews, content: PrecisionContent) {
    val percent = content.percent
    views.setTextViewText(R.id.precision_percent, if (percent == null) "—" else "$percent%")
    views.setTextColor(R.id.precision_percent, if (percent == null) MUTED else CYAN)
    views.setContentDescription(
        R.id.precision_summary,
        if (percent == null) res.getString(R.string.precision_widget_none)
        else res.getString(R.string.precision_widget_percent, percent),
    )
    views.setTextViewText(
        R.id.precision_message,
        res.getString(
            when (content.message) {
              PrecisionMessage.EMPTY -> R.string.precision_message_empty
              PrecisionMessage.IMPROVED -> R.string.precision_message_improved
              PrecisionMessage.HIGH -> R.string.precision_message_high
              PrecisionMessage.MID -> R.string.precision_message_mid
              PrecisionMessage.LOW -> R.string.precision_message_low
            },
        ),
    )

    val names = res.getStringArray(R.array.precision_weekdays)
    content.days.forEachIndexed { index, status ->
      val ids = DAY_IDS[index]
      val color = dayColor(index)
      val isToday = index == content.todayIndex
      // Ogni stato ha forma e simbolo propri, non solo il colore.
      views.setImageViewResource(
          ids.dot,
          when (status) {
            DayStatus.MEASURED -> R.drawable.widget_pday_fill
            DayStatus.ACTIVITY_ONLY -> R.drawable.widget_pday_activity
            DayStatus.EMPTY ->
                if (isToday) R.drawable.widget_pday_today else R.drawable.widget_pday_empty
            DayStatus.FUTURE -> R.drawable.widget_pday_future
          },
      )
      val tinted = status == DayStatus.MEASURED || status == DayStatus.ACTIVITY_ONLY
      // Il colore 0 non cambia il disegno (SRC_ATOP con un colore trasparente).
      views.setInt(ids.dot, "setColorFilter", if (tinted) color else 0)
      when (status) {
        DayStatus.MEASURED -> {
          views.setViewVisibility(ids.mark, View.VISIBLE)
          views.setImageViewResource(ids.mark, R.drawable.widget_mark_check)
        }
        DayStatus.ACTIVITY_ONLY -> {
          views.setViewVisibility(ids.mark, View.VISIBLE)
          views.setImageViewResource(ids.mark, R.drawable.widget_mark_dash)
        }
        else -> views.setViewVisibility(ids.mark, View.GONE)
      }

      // Linea accesa solo fra due giorni consecutivi con allenamento.
      fun active(i: Int) =
          i in content.days.indices &&
              (content.days[i] == DayStatus.MEASURED || content.days[i] == DayStatus.ACTIVITY_ONLY)
      views.setInt(
          ids.left,
          "setBackgroundColor",
          if (active(index) && active(index - 1)) color else LINE_OFF,
      )
      views.setInt(
          ids.right,
          "setBackgroundColor",
          if (active(index) && active(index + 1)) color else LINE_OFF,
      )

      val name = names[index]
      val label = SpannableString(name)
      if (isToday) {
        label.setSpan(StyleSpan(Typeface.BOLD), 0, name.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }
      views.setTextViewText(ids.label, label)
      views.setTextColor(ids.label, if (status == DayStatus.FUTURE) FUTURE_LABEL else Color.WHITE)
      views.setContentDescription(
          ids.cell,
          when (status) {
            DayStatus.MEASURED ->
                res.getString(R.string.precision_day_measured, name, content.dayPercents[index] ?: 0)
            DayStatus.ACTIVITY_ONLY -> res.getString(R.string.precision_day_activity, name)
            DayStatus.EMPTY -> res.getString(R.string.precision_day_empty, name)
            DayStatus.FUTURE -> res.getString(R.string.precision_day_future, name)
          },
      )
    }
  }

  private class DayIds(
      val cell: Int,
      val dot: Int,
      val mark: Int,
      val left: Int,
      val right: Int,
      val label: Int,
  )

  companion object {
    private val CYAN = Color.parseColor("#5EEAF4")
    private val VIOLET = Color.parseColor("#A855F7")
    private val MUTED = Color.parseColor("#C7C9F2")
    private val LINE_OFF = Color.parseColor("#33FFFFFF")
    private val FUTURE_LABEL = Color.parseColor("#7FC7C9F2")

    /** Colore del giorno [index] (0 = lunedì), dal ciano al viola. */
    private fun dayColor(index: Int): Int {
      val t = index / 6f
      fun mix(shift: Int) =
          (((CYAN shr shift) and 0xFF) * (1 - t) + ((VIOLET shr shift) and 0xFF) * t).roundToInt()
      return Color.rgb(mix(16), mix(8), mix(0))
    }

    private val DAY_IDS =
        listOf(
            DayIds(R.id.pday_0, R.id.pday_0_dot, R.id.pday_0_mark, R.id.pday_0_left, R.id.pday_0_right, R.id.pday_0_label),
            DayIds(R.id.pday_1, R.id.pday_1_dot, R.id.pday_1_mark, R.id.pday_1_left, R.id.pday_1_right, R.id.pday_1_label),
            DayIds(R.id.pday_2, R.id.pday_2_dot, R.id.pday_2_mark, R.id.pday_2_left, R.id.pday_2_right, R.id.pday_2_label),
            DayIds(R.id.pday_3, R.id.pday_3_dot, R.id.pday_3_mark, R.id.pday_3_left, R.id.pday_3_right, R.id.pday_3_label),
            DayIds(R.id.pday_4, R.id.pday_4_dot, R.id.pday_4_mark, R.id.pday_4_left, R.id.pday_4_right, R.id.pday_4_label),
            DayIds(R.id.pday_5, R.id.pday_5_dot, R.id.pday_5_mark, R.id.pday_5_left, R.id.pday_5_right, R.id.pday_5_label),
            DayIds(R.id.pday_6, R.id.pday_6_dot, R.id.pday_6_mark, R.id.pday_6_left, R.id.pday_6_right, R.id.pday_6_label),
        )
  }
}

enum class DayStatus {
  MEASURED,
  ACTIVITY_ONLY,
  EMPTY,
  FUTURE,
}

enum class PrecisionMessage {
  EMPTY,
  IMPROVED,
  HIGH,
  MID,
  LOW,
}

/** Totali di un giorno: note corrette, note valutate, sessioni. */
data class DayTotals(val correct: Int, val attempts: Int, val sessions: Int)

data class PrecisionContent(
    /** Sette giorni, da lunedì (indice 0) a domenica. */
    val days: List<DayStatus>,
    val dayPercents: List<Int?>,
    val todayIndex: Int,
    /** Precisione media della settimana; null se nessuna nota valutata. */
    val percent: Int?,
    val message: PrecisionMessage,
) {
  companion object {
    /** Formato dell'app: `giorno:corrette:valutate:sessioni` separati da `;`. */
    fun decode(raw: String?): Map<String, DayTotals> {
      if (raw.isNullOrEmpty()) {
        return emptyMap()
      }
      val days = mutableMapOf<String, DayTotals>()
      for (item in raw.split(';')) {
        val parts = item.split(':')
        if (parts.size != 4) continue
        val numbers = parts.drop(1).map { it.toIntOrNull() }
        if (numbers.any { it == null || it < 0 }) continue
        days[parts[0]] = DayTotals(numbers[0]!!, numbers[1]!!, numbers[2]!!)
      }
      return days
    }

    private fun percentOf(correct: Int, attempts: Int): Int? =
        if (attempts == 0) null else (correct * 100.0 / attempts).roundToInt()

    fun of(data: Map<String, DayTotals>, now: Calendar): PrecisionContent {
      // Calendar.MONDAY = 2 … Calendar.SUNDAY = 1: lunedì = 0, domenica = 6.
      val todayIndex = (now.get(Calendar.DAY_OF_WEEK) + 5) % 7
      // Giorni di calendario: il cambio dell'ora legale non sposta i confini.
      fun day(offset: Int) = formatDay(addDays(now, offset - todayIndex))

      var previousCorrect = 0
      var previousAttempts = 0
      for (i in -7 until 0) {
        val totals = data[day(i)] ?: continue
        previousCorrect += totals.correct
        previousAttempts += totals.attempts
      }

      var correct = 0
      var attempts = 0
      val days = mutableListOf<DayStatus>()
      val dayPercents = mutableListOf<Int?>()
      for (i in 0 until 7) {
        val totals = if (i > todayIndex) null else data[day(i)]
        correct += totals?.correct ?: 0
        attempts += totals?.attempts ?: 0
        days +=
            when {
              i > todayIndex -> DayStatus.FUTURE
              totals == null || totals.sessions == 0 -> DayStatus.EMPTY
              totals.attempts > 0 -> DayStatus.MEASURED
              else -> DayStatus.ACTIVITY_ONLY
            }
        dayPercents += totals?.let { percentOf(it.correct, it.attempts) }
      }
      val percent = percentOf(correct, attempts)
      val previous = percentOf(previousCorrect, previousAttempts)
      val message =
          when {
            percent == null -> PrecisionMessage.EMPTY
            previous != null && percent > previous -> PrecisionMessage.IMPROVED
            percent >= 80 -> PrecisionMessage.HIGH
            percent >= 60 -> PrecisionMessage.MID
            else -> PrecisionMessage.LOW
          }
      return PrecisionContent(days, dayPercents, todayIndex, percent, message)
    }
  }
}
