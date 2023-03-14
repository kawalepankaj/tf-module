/* .................APPLICATION-LOAD-BALANCER........................ */
resource "aws_lb" "alb" {
  count                      = var.type == "application" ? 1 : 0
  name                       = format("%s-%s-%s", var.appname, var.env, "application")
  internal                   = var.internal
  load_balancer_type         = var.type
  security_groups            = var.security_groups
  subnets                    = var.subnets
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.my-log-bucket.id
    prefix  = var.appname
    enabled = true
  }
  tags = merge(var.tags, { Name = format("%s-%s-%s", var.appname, var.env, "ALB") })
}  

/* .................NETWORK-LOAD-BALANCER........................ */
resource "aws_lb" "nlb" {
  count                      = var.type == "network" ? 1 : 0
  name                       = format("%s-%s-%s", var.appname, var.env, "network")
  internal                   = var.internal
  load_balancer_type         = var.type
  subnets                    = var.subnets
  enable_deletion_protection = false
  tags                       = merge(var.tags, { Name = format("%s-%s-%s", var.appname, var.env, "NLB") })
}

/* .................S3-BUCKET........................ */
resource "aws_s3_bucket" "my-log-bucket" {
  bucket = "mylogbucket-${var.appname}-${var.env}-${random_string.random.id}"
}
resource "random_string" "random" {
  length           = 3
  special          = false
  upper = false
}

/* .................S3-BUCKET-POLICY........................ */
resource "aws_s3_bucket_policy" "my-log-bucket-policy" {
  bucket = aws_s3_bucket.my-log-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.my-log-bucket.arn}/*"
      }
    ]
  })
}

/* .................TARGET-GROUP........................ */
resource "aws_lb_target_group" "mytg" {
  name        = format("%s-%s-%s", var.appname, var.env, "MYTG")
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

/* .................LISTENER........................ */
resource "aws_lb_listener" "alb_listener" {
  port              = 80
  protocol = var.type == "application" ? "HTTP" : "TCP"

  dynamic "default_action" {
    for_each = var.type == "application" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.mytg.arn
    }
  }

  dynamic "default_action" {
    for_each = var.type == "network" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.mytg.arn
    }
  }

 load_balancer_arn = element(var.type == "application" ? aws_lb.alb[*].arn : aws_lb.nlb[*].arn, 0)
}

  /* default_action {}
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301" 
    } 
} */


/* # create a listener on port 443 with forward action
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn  = aws_lb.application_load_balancer.arn
  port               = 80
  protocol           = "HTTP"
  ssl_policy         = "ELBSecurityPolicy-2016-08"
  certificate_arn    = 

  default_action {
    type             = 
    target_group_arn = 
  }
} */