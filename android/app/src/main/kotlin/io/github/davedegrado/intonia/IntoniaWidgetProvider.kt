package io.github.davedegrado.intonia

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Widget della schermata Home: mascotte, serie di giorni consecutivi e invito
 * ad allenarsi. I dati arrivano dall'app (HomeWidgetService); lo stato del
 * giorno è ricalcolato qui, così il widget resta corretto anche ad app chiusa.
 * Stessa logica di WidgetView (lib/features/home_widget/domain/widget_streak.dart).
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
      val views =
          RemoteViews(context.packageName, R.layout.widget_intonia).apply {
            setImageViewResource(
                R.id.widget_mascot,
                if (content.trainedToday) R.drawable.widget_mascot_happy
                else R.drawable.widget_mascot_invite,
            )
            setTextViewText(R.id.widget_title, content.title)
            setTextViewText(R.id.widget_message, content.message)
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    const val KEY_LAST_TRAINING_DAY = "intonia_last_training_day"
    const val KEY_STREAK = "intonia_streak_at_last_training"
  }
}

data class WidgetContent(val trainedToday: Boolean, val title: String, val message: String) {
  companion object {
    private fun day(calendar: Calendar): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

    private fun streakTitle(streak: Int): String =
        if (streak == 1) "1 giorno di fila" else "$streak giorni di fila"

    fun of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Calendar): WidgetContent {
      val today = day(now)
      val yesterday = day((now.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, -1) })
      return when {
        lastTrainingDay == today && streakAtLastTraining > 0 ->
            WidgetContent(
                trainedToday = true,
                title = streakTitle(streakAtLastTraining),
                message = "Allenamento fatto. Sei inarrestabile!",
            )
        lastTrainingDay == yesterday && streakAtLastTraining > 0 ->
            WidgetContent(
                trainedToday = false,
                title = streakTitle(streakAtLastTraining),
                message = "Allenati oggi per non perdere la serie!",
            )
        else ->
            WidgetContent(
                trainedToday = false,
                title = "Allena l'orecchio",
                message = "Pronto per l'allenamento di oggi?",
            )
      }
    }
  }
}
