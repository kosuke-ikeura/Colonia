resource "aws_lb" "colonia-alb" {
    name                        = "colonia-alb"
    load_balancer_type          = "application"
    internal                    = false
    idle_timeout                = 60
    enable_deletion_protection  = false

    subnets = [
        aws_subnet.colonia_public_0.id,
        aws_subnet.colonia_public_1.id,
    ]

    access_logs {
        bucket  = aws_s3_bucket.alb_log.id
        enabled = true
    }

    security_groups = [
        module.http_sg.security_group_id,
        module.https_sg.security_group_id,
        module.http_redirect_sg.security_group_id,
    ]
}
output "alb_dns_name" {
        value = aws_lb.colonia-alb.dns_name
}

module "http_sg" {
    source          = "./security_group"
    name            = "http-sg"
    vpc_id          = aws_vpc.colonia-vpc.id
    port            = 80
    cidr_blocks     = ["0.0.0.0/0"]
}

module "https_sg" {
    source          = "./security_group"
    name            = "https-sg"
    vpc_id          = aws_vpc.colonia-vpc.id
    port            = 443
    cidr_blocks     = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
    source            = "./security_group"
    name              = "http-redirect-sg"
    vpc_id            = aws_vpc.colonia-vpc.id
    port              = 8080
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.colonia-alb.arn
    port                = "80"
    protocol            = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "これは[HTTP]です"
            status_code  = "200"
        }
    }
}

data "aws_route53_zone" "wwwcolonia" {
    name = "wwwcolonia.com"
}

resource "aws_route53_record" "wwwcolonia" {
    zone_id = data.aws_route53_zone.wwwcolonia.zone_id
    name    = data.aws_route53_zone.wwwcolonia.name
    type    = "A"

    alias {
        name                    = aws_lb.colonia-alb.dns_name
        zone_id                 = aws_lb.colonia-alb.zone_id
        evaluate_target_health  = true
    }
}

output "domain_name" {
    value = aws_route53_record.wwwcolonia.name
}

resource "aws_acm_certificate" "wwwcolonia" {
    domain_name                 = aws_route53_record.wwwcolonia.name
    subject_alternative_names   = []
    validation_method           = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}
resource "aws_route53_record" "wwwcolonia_certificate" {
    name    = aws_acm_certificate.wwwcolonia.domain_validation_options[0].resource_record_name
    type    = aws_acm_certificate.wwwcolonia.domain_validation_options[0].resource_record_type
    records = [aws_acm_certificate.wwwcolonia.domain_validation_options[0].resource_record_value]
    zone_id = data.aws_route53_zone.wwwcolonia.id
    ttl     = 60
}
resource "aws_acm_certificate_validation" "wwwcolonia" {
    certificate_arn         = aws_acm_certificate.wwwcolonia.arn
    validation_record_fqdns = [aws_route53_record.wwwcolonia_certificate.fqdn]
}

resource "aws_lb_listener" "https" {
    load_balancer_arn   = aws_lb.colonia-alb.arn
    port                = "443"
    protocol            = "HTTPS"
    certificate_arn     = aws_acm_certificate.wwwcolonia.arn
    ssl_policy          = "ELBSecurityPolicy-2016-08"

    default_action {
        target_group_arn = aws_lb_target_group.colonia-target.arn
        type = "forward"
    }
}

resource "aws_lb_listener" "redirect_http_to_https" {
    load_balancer_arn = aws_lb.colonia-alb.arn
    port              = "8080"
    protocol          = "HTTP"

    default_action {
        type = "redirect"
        
        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}
resource "aws_lb_target_group" "colonia-target" {
    name                  = "colonia-target${substr(uuid(),0, 3)}"
    target_type           = "instance"
    vpc_id                = aws_vpc.colonia-vpc.id
    port                  = 80
    protocol              = "HTTP"
    deregistration_delay  = 300

    health_check {
        interval            = 30
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 4
        matcher             = 200
    }
    lifecycle {
        create_before_destroy = true
        ignore_changes        = [name]
    }

    depends_on = [aws_lb.colonia-alb]
}

resource "aws_alb_target_group_attachment" "alb" {
    target_group_arn = aws_lb_target_group.colonia-target.arn
    target_id        = aws_instance.colonia.id
    port             = 80
}


resource "aws_lb_listener_rule" "colonia" {
    listener_arn            = aws_lb_listener.https.arn
    priority                = 100

    action {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.colonia-target.arn
    }

    condition {
        field  = "path-pattern"
        values = ["/*"]
    }
}





