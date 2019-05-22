resource "aws_vpc" "terraform" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true

  tags {
    Name = "Terraform VPC"
  }
}

resource "aws_subnet" "management" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "${var.management_subnet_cidr_block}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_availability_zone}"

  tags {
    Name = "Terraform Management Subnet"
  }
}

resource "aws_subnet" "client" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "${var.client_subnet_cidr_block}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_availability_zone}"

  tags {
    Name = "Terraform Public Subnet"
  }
}

resource "aws_subnet" "server" {
  vpc_id            = "${aws_vpc.terraform.id}"
  cidr_block        = "${var.server_subnet_cidr_block}"
  availability_zone = "${var.aws_availability_zone}"

  tags {
    Name = "Terraform Server Subnet"
  }
}

resource "aws_internet_gateway" "TR_iGW" {
  vpc_id = "${aws_vpc.terraform.id}"

  tags {
    Name = "Terraform Internet Gateway"
  }
}

resource "aws_route_table" "main_rt_table" {
  vpc_id = "${aws_vpc.terraform.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.TR_iGW.id}"
  }

  tags {
    Name = "Terraform Main Route Table"
  }
}

resource "aws_main_route_table_association" "TR_main_route" {
  vpc_id         = "${aws_vpc.terraform.id}"
  route_table_id = "${aws_route_table.main_rt_table.id}"
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.terraform.id}"

  tags {
    Name = "Terraform Default-Security-Group"
  }
}

resource "aws_security_group_rule" "default_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_default_security_group.default.id}"
  security_group_id        = "${aws_default_security_group.default.id}"
}

resource "aws_security_group_rule" "default_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_default_security_group.default.id}"
}

resource "aws_security_group" "management" {
  vpc_id      = "${aws_vpc.terraform.id}"
  name        = "Terraform management"
  description = "Allow everything from within the management network"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${concat(list(var.controlling_subnet), aws_subnet.management.*.cidr_block)}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Terraform Management Security Group"
  }
}

resource "aws_security_group" "client" {
  name        = "Terraform client side"
  description = "Allow Web Traffic from everywhere"

  vpc_id = "${aws_vpc.terraform.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Terraform Client Security Group"
  }
}

resource "aws_security_group" "server" {
  name        = "Terraform server side"
  description = "Allow all traffic from the server subnet"

  vpc_id = "${aws_vpc.terraform.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_subnet.server.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Terraform Server Security Group"
  }
}
