# ALB (public HTTPS in, HTTP to the app tier only)
resource "aws_security_group" "https" {
  name   = "allow-all-https"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = local.https_port
    to_port     = local.https_port
    protocol    = local.tcp
    cidr_blocks = [local.all_traffic_cidr]
  }

  # ALB only needs to reach the app on port 80 inside the VPC
  egress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp
    cidr_blocks = [local.vpc_cidr]
  }
}

# Private HTTP from ALB
resource "aws_security_group" "private_http" {
  name   = "allow-http-from-alb"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = local.http_port
    to_port         = local.http_port
    protocol        = local.tcp
    security_groups = [aws_security_group.https.id]
  }

  # Open during bootstrap (Docker, image, model pull); none after lockdown
  egress = var.lockdown_egress ? [] : [{
    from_port        = local.port_0
    to_port          = local.port_0
    protocol         = local.all_protocols
    cidr_blocks      = [local.all_traffic_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    description      = ""
  }]
}

# Bastion SSH
resource "aws_security_group" "ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = local.tcp
    cidr_blocks = [var.admin_cidr]
  }

  # Bastion only needs to SSH into hosts inside the VPC
  egress {
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = local.tcp
    cidr_blocks = [local.vpc_cidr]
  }
}

# Private SSH from bastion
resource "aws_security_group" "private_ssh" {
  name   = "allow-ssh-from-bastion"
  vpc_id = aws_vpc.open_web_ui.id

  ingress {
    from_port       = local.ssh_port
    to_port         = local.ssh_port
    protocol        = local.tcp
    security_groups = [aws_security_group.ssh.id]
  }

  # Same gate as private_http: both groups must close for the instance to lose internet access
  egress = var.lockdown_egress ? [] : [{
    from_port        = local.port_0
    to_port          = local.port_0
    protocol         = local.all_protocols
    cidr_blocks      = [local.all_traffic_cidr]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    description      = ""
  }]
}
