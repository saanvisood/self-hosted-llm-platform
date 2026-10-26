# Alerts for idle instances and monthly spend

resource "aws_sns_topic" "alerts" {
  name = "llm-platform-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Detects idle if average CPU under 5% for one hour (12 x 5 min periods)
resource "aws_cloudwatch_metric_alarm" "idle" {
  alarm_name          = "llm-instance-idle"
  alarm_description   = "Open WebUI/Ollama instance has been idle for 1 hour; consider terraform destroy"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.open_web_ui.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 12
  threshold           = 5
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching" # stopped instances produce no metrics

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Monthly spend alerts at 80% of the limit
resource "aws_budgets_budget" "monthly" {
  name         = "llm-platform-monthly"
  budget_type  = "COST"
  limit_amount = "15" # USD
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
