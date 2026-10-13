package io.github.davedegrado.intonia

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Widget della schermata Home: mascotte, serie di giorni consecutivi, ultimi
 * 7 giorni e invito ad allenarsi. I dati arrivano dall'app (HomeWidgetService);
 * lo stato del giorno è ricalcolato qui, così il widget resta corretto anche ad
 * app chiusa. Stessa logica di WidgetView
 * (lib/features/home_widget/domain/widget_streak.dart).
 */
class IntoniaWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val content =
        WidgetContent.of(
            lastTrainingDay = widgetData.getString(KEY_LAST_TRAINING_DAY, null),
            streakAtLastTraining = widgetData.getString(KEY_STREAK, null)?.toIntOrNull() ?: 0,
            now = Calendar.getInstance(),
        )
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_intonia)
      bind(views, content)
      views.setOnClickPendingIntent(
          R.id.widget_root,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
      )
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun bind(views: RemoteViews, content: WidgetContent) {
    val trainedToday = content.status == WidgetStatus.TRAINED_TODAY
    views.setImageViewResource(
        R.id.widget_mascot,
        if (trainedToday) R.drawable.widget_mascot_happy else R.drawable.widget_mascot_invite,
    )

    val hasStreak = content.status != WidgetStatus.START
    views.setViewVisibility(R.id.widget_streak_row, if (hasStreak) View.VISIBLE else View.GONE)
    views.setViewVisibility(R.id.widget_title, if (hasStreak) View.GONE else View.VISIBLE)
    views.setTextViewText(R.id.widget_streak_number, content.streak.toString())
    views.setTextColor(
        R.id.widget_streak_number,
        // Ciano a obiettivo raggiunto, ambra quando la serie va salvata oggi.
        Color.parseColor(if (trainedToday) "#22D3EE" else "#FBBF24"),
    )
    views.setTextViewText(
        R.id.widget_streak_label,
        if (content.streak == 1) "giorno\ndi fila" else "giorni\ndi fila",
    )
    views.setTextViewText(R.id.widget_title, content.title)
    views.setContentDescription(R.id.widget_streak_row, content.title)

    content.week.forEachIndexed { index, trained ->
      val isToday = index == content.week.lastIndex
      views.setImageViewResource(
          DAY_IDS[index],
          when {
            trained -> R.drawable.widget_dot_on
            isToday -> R.drawable.widget_dot_today
            else -> R.drawable.widget_dot_off
          },
      )
    }

    views.setTextViewText(R.id.widget_message, content.message)
    views.setInt(
        R.id.widget_message,
        "setBackgroundResource",
        if (trainedToday) R.drawable.widget_pill_done else R.drawable.widget_pill_cta,
    )
  }

  companion object {
    const val KEY_LAST_TRAINING_DAY = "intonia_last_training_day"
    const val KEY_STREAK = "intonia_streak_at_last_training"

    private val DAY_IDS =
        intArrayOf(
            R.id.widget_day_0,
            R.id.widget_day_1,
            R.id.widget_day_2,
            R.id.widget_day_3,
            R.id.widget_day_4,
            R.id.widget_day_5,
            R.id.widget_day_6,
        )
  }
}

enum class WidgetStatus {
  TRAINED_TODAY,
  KEEP_STREAK,
  START,
}

data class WidgetContent(
    val status: WidgetStatus,
    val streak: Int,
    val title: String,
    val message: String,
    /** Ultimi 7 giorni, da 6 giorni fa a oggi: true se fanno parte della serie. */
    val week: List<Boolean>,
) {
  companion object {
    private fun format(calendar: Calendar): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

    private fun daysBefore(calendar: Calendar, days: Int): Calendar =
        (calendar.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, -days) }

    private fun streakTitle(streak: Int): String =
        if (streak == 1) "1 giorno di fila" else "$streak giorni di fila"

    private fun weekOf(lastTrainingDay: String?, streak: Int, now: Calendar): List<Boolean> {
      val lastDate =
          lastTrainingDay?.let {
            runCatching { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(it) }.getOrNull()
          }
      if (lastTrainingDay == null || lastDate == null || streak <= 0) {
        return List(7) { false }
      }
      val first = format(daysBefore(Calendar.getInstance().apply { time = lastDate }, streak - 1))
      return (6 downTo 0).map { back ->
        val day = format(daysBefore(now, back))
        day >= first && day <= lastTrainingDay
      }
    }

    fun of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Calendar): WidgetContent {
      val today = format(now)
      val yesterday = format(daysBefore(now, 1))
      val week = weekOf(lastTrainingDay, streakAtLastTraining, now)
      return when {
        lastTrainingDay == today && streakAtLastTraining > 0 ->
            WidgetContent(
                status = WidgetStatus.TRAINED_TODAY,
                streak = streakAtLastTraining,
                title = streakTitle(streakAtLastTraining),
                message = "Fatto! Sei inarrestabile ✨",
                week = week,
            )
        lastTrainingDay == yesterday && streakAtLastTraining > 0 ->
            WidgetContent(
                status = WidgetStatus.KEEP_STREAK,
                streak = streakAtLastTraining,
                title = streakTitle(streakAtLastTraining),
                message = "Allenati oggi: salva la serie! 🔥",
                week = week,
            )
        else ->
            WidgetContent(
                status = WidgetStatus.START,
                streak = 0,
                title = "Allena l'orecchio",
                message = "Pronto ad allenarti? 🎵",
                week = week,
            )
      }
    }
  }
}
