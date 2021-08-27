resource "aws_sns_topic" "alb_tg_status_offline" {
  name = "alb-tg-status-offline"
  
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 10
    }
  }
}
EOF
}

resource "aws_sns_topic" "alb_tg_status_online" {
  name = "alb-tg-status-online"

  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 10
    }
  }
}
EOF
}

#SNS email topic subscription
#We put the e-mail where we want to send the messages
resource "aws_sns_topic_subscription" "sns_topic_offline_subscription_myself" {
  topic_arn = aws_sns_topic.alb_tg_status_offline.arn
  protocol  = "email"
  endpoint  = "serhp07@gmail.com"
}

resource "aws_sns_topic_subscription" "sns_topic_offline_subscription_lambda_maintenance_page" {
  topic_arn = aws_sns_topic.alb_tg_status_offline.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.aws_lambda_maintenance_page.arn
}

resource "aws_sns_topic_subscription" "sns_topic_online_subscription_myself" {
  topic_arn = aws_sns_topic.alb_tg_status_online.arn
  protocol  = "email"
  endpoint  = "serhp07@gmail.com"
}

resource "aws_sns_topic_subscription" "sns_topic_online_subscription_labmda_alb_web_http_tg" {
  topic_arn = aws_sns_topic.alb_tg_status_online.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.aws_lambda_web_http_tg.arn
}
resource "local_file" "web_lb_http_listener" {
  content  = "${aws_lb_listener.web_lb_http.arn}"
  filename = "${path.module}/lambda_functions/lambda_alb_maintenance_page/web_lb_http_listener"
}
resource "local_file" "web_lb_http_tg" {
  content  = "${aws_lb_target_group.web_lb_http_target.arn}"
  filename = "${path.module}/lambda_functions/lambda_alb_maintenance_page/web_http_tg"
}
resource "local_file" "web_lb_http_rule_http_tg" {
  content  = "${aws_lb_listener_rule.web_lb_http_rule_http_tg.arn}"
  filename = "${path.module}/lambda_functions/lambda_alb_maintenance_page/web_lb_http_rule_http_tg"
}
resource "local_file" "web_lb_http_rule_http_fixed_content" {
  content  = "${aws_lb_listener_rule.web_lb_http_rule_fixed_content.arn}"
  filename = "${path.module}/lambda_functions/lambda_alb_maintenance_page/web_lb_http_rule_http_fixed_content"

}
data "archive_file" "lambda_alb_maintenance_page" {
  depends_on = [local_file.web_lb_http_listener, local_file.web_lb_http_tg, local_file.web_lb_http_rule_http_tg, local_file.web_lb_http_rule_http_fixed_content]
  source_dir = "${path.module}/lambda_functions/lambda_alb_maintenance_page"
  output_path = "${path.module}/lambda_functions/lambda_alb_maintenance_page.zip"
  type = "zip"
}

data "aws_iam_policy_document" "lambda_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_role_elb_modify_listener" {
  name        = "iam_role_elb_modify_listener"
  description = "IAM Role for ALB listener modification"

  assume_role_policy = data.aws_iam_policy_document.lambda_instance_assume_role_policy.json
  inline_policy {
    name   = "alb_modify_listener_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = ["elasticloadbalancing:SetRulePriorities"]
          Resource = "*"
        },
      ]
    })
 }

}

resource "aws_lambda_function" "aws_lambda_maintenance_page" {
  function_name = "aws_lambda_maintenance_page"
  description = "Enables AWS maintenance page"
  handler = "lambda_function.lambda_maintenance"
  runtime = "python3.8"

  role = aws_iam_role.iam_role_elb_modify_listener.arn
  memory_size = 128
  timeout = 300

  source_code_hash = data.archive_file.lambda_alb_maintenance_page.output_base64sha256
  filename = data.archive_file.lambda_alb_maintenance_page.output_path
}

resource "aws_lambda_permission" "aws_lambda_maintenance_page_permission" {
  statement_id = "SNSTopicInvokeFunction"
  action       = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_lambda_maintenance_page.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alb_tg_status_offline.arn
}
resource "aws_lambda_function" "aws_lambda_web_http_tg" {
  function_name = "aws_lambda_web_http_tg"
  description = "Enables AWS maintenance page"
  handler = "lambda_function.lambda_tg"
  runtime = "python3.8"

  role = aws_iam_role.iam_role_elb_modify_listener.arn
  memory_size = 128
  timeout = 300

  source_code_hash = data.archive_file.lambda_alb_maintenance_page.output_base64sha256
  filename = data.archive_file.lambda_alb_maintenance_page.output_path
}

resource "aws_lambda_permission" "aws_lambda_web_http_tg_permission" {
  statement_id = "SNSTopicInvokeFunction"
  action       = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_lambda_web_http_tg.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alb_tg_status_online.arn
}

resource "aws_cloudwatch_metric_alarm" "alb_tg_healthy_hosts_count" {
  alarm_name          = "alb_tg_healthy_hosts_count"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  threshold           = "1"
  statistic           = "Average"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alb_tg_status_offline.arn]
  ok_actions          = [aws_sns_topic.alb_tg_status_online.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.web_lb_http_target.arn_suffix
    LoadBalancer = aws_lb.web_lb.arn_suffix
  }
}
