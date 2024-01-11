resource "aws_iam_role" "this" {
  name = "my-stepfunctions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action: "sts:AssumeRole"
        Effect: "Allow"
        Sid: ""
        Principal: {
          Service: "states.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "this" {
  name        = "test-policmy-stepfunctions"
  policy      = jsonencode(var.iam_policy)
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.this.arn
  definition = var.definition
}