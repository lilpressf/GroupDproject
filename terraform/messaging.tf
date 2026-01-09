resource "aws_sns_topic" "deployments" {
  name = "${var.name}-deployments"
  tags = local.tags
}

resource "aws_sqs_queue" "deployments" {
  name                       = "${var.name}-deployments"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  tags                       = local.tags
}

resource "aws_cloudwatch_event_bus" "deployments" {
  name = "${var.name}-bus"
  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "to_sqs" {
  name           = "${var.name}-rule"
  event_bus_name = aws_cloudwatch_event_bus.deployments.name
  event_pattern = jsonencode({
    "source" : ["training-platform.backend"],
    "detail-type" : ["deploy-request"]
  })
  tags = local.tags
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule           = aws_cloudwatch_event_rule.to_sqs.name
  event_bus_name = aws_cloudwatch_event_bus.deployments.name
  arn            = aws_sqs_queue.deployments.arn
}

# Let EventBridge send to SQS
resource "aws_sqs_queue_policy" "allow_eventbridge" {
  queue_url = aws_sqs_queue.deployments.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowEventBridgeSendMessage",
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sqs:SendMessage",
      Resource  = aws_sqs_queue.deployments.arn,
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.to_sqs.arn }
      }
    }]
  })
}
