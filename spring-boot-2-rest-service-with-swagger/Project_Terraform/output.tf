output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.web_lb.dns_name
}
