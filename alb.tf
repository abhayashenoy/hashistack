resource "aws_alb" "fabio" {
  internal        = false
  security_groups = ["${aws_security_group.private.id}"]
  subnets         = ["${aws_subnet.private.id}", "${aws_subnet.public.id}"]
}

resource "aws_alb_target_group" "fabio" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
}

resource "aws_alb_listener" "fabio" {
  load_balancer_arn = "${aws_alb.fabio.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.fabio.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "fabio" {
  listener_arn = "${aws_alb_listener.fabio.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.fabio.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

resource "aws_alb_target_group_attachment" "fabio" {
  target_group_arn = "${aws_alb_target_group.fabio.arn}"
  target_id        = "${element(aws_instance.workers.*.id, count.index)}"
  port             = 9999
  count            = "${var.worker_count}"
}
