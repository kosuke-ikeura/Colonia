
# 変数の定義
variable "name" {}
variable "policy" {}
variable "identifier" {}

# ======================
# 
# IAMポリシー：サービスに対する権限の内容。権限一つごとの単位を「アクション」といい、アクションをグループ化したものが「ポリシー」。
# IAMロール：　人に対して与えるIAMを「IAMユーザー」、それに対してサービスやプログラムに与えるIAMを「IAMロール」と呼ぶ。
# 信頼ポリシー：IAMロールでは、自身をなんのサービスに関連付けるか宣言する必要がある。その宣言は「信頼ポリシー」と呼ばれる。
# 
# ======================

# デフォルトのIAMロールの定義
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 信頼ポリシーをモジュール化
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

# デフォルトのポリシーを定義
# 変数を使用してモジュール化している
resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}

# IAMロールにIAMポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}