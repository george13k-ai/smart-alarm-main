package com.example.app1

import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity

class OnboardingActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val contentPadding = dp(20)

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(contentPadding, contentPadding, contentPadding, contentPadding)
        }

        val title = TextView(this).apply {
            text = "Подключение к Health Connect"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(0, 0, 0, dp(12))
        }

        val body = TextView(this).apply {
            text = "Чтобы включить синхронизацию, откройте приложение и нажмите кнопку синхронизации " +
                "на экране статистики. После этого подтвердите доступ к данным сна, шагов и пульса."
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(0, 0, 0, dp(24))
        }

        val openAppButton = Button(this).apply {
            text = "Продолжить"
            setOnClickListener {
                startActivity(
                    Intent(this@OnboardingActivity, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                )
                finish()
            }
        }

        container.addView(title)
        container.addView(body)
        container.addView(openAppButton)

        val root = ScrollView(this).apply {
            addView(container)
        }

        setContentView(root)
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()
    }
}
