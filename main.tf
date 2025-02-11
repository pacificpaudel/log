terraform {
    backend "s3" {
        bucket = "log-server-tf-state"
        region = "eu-west-1"
        key = "log-server-env-terraform.tfstate"
        dynamodb_table = "tf-up-and-run-locks"
    }
}




# -------------------------------------------------------------------------------------------------
# VPC
# -------------------------------------------------------------------------------------------------


# Create VPC
resource "aws_vpc" "vpc_name" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  
}

# Create Subnet
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.vpc_name.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "my-private-subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.vpc_name.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "my-public-subnet"
  }
}
# Create Route Table
resource "aws_route_table" "rt_name" {
  vpc_id = "${aws_vpc.vpc_name.id}"

  
}

# Create Route To The Internet
resource "aws_route" "route_name" {
  route_table_id         = "${aws_route_table.rt_name.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw_name.id}"
}

# Associate The Route Table To Subnet
resource "aws_route_table_association" "rta_name" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.rt_name.id}"
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw_name" {
  vpc_id = "${aws_vpc.vpc_name.id}"

  
}

# Create Security Group
resource "aws_security_group" "sg_name" {
  name        = "my-sg"
  description = "Allow ping, ssh and output traffic"
  vpc_id      = "${aws_vpc.vpc_name.id}"

  

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Ping
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow All Output Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# # Create Instance
# resource "aws_instance" "instance_name" {
#   ami                    = "${var.ami}"
#   availability_zone      = "${var.zone}"
#   instance_type          = "${var.instance_type}"
#   key_name               = "${var.my_key_name}"
#   vpc_security_group_ids = ["${aws_security_group.sg_name.id}"]
#   subnet_id              = "${aws_subnet.subnet_name.id}"

#   associate_public_ip_address = true
#   source_dest_check           = false

#   root_block_device {
#     volume_size = "30"
#     volume_type = "gp2"
#   }

  
# }



# -------------------------------------------------------------------------------------------------
# BASTION
# -------------------------------------------------------------------------------------------------
# Define an AWS EC2 instance resource named "bastion"
resource "aws_instance" "bastion" {
    # Specify the Amazon Linux 2 AMI ID
    ami = "ami-07683a44e80cd32c5"
    # Set the instance type to t2.micro
    instance_type = "t2.micro"
    availability_zone      = "eu-west-1b"
    # Use the first public subnet from the vpc module
    subnet_id = "${aws_subnet.public.id}"
    # Assign security groups to the instance
    vpc_security_group_ids = ["${aws_security_group.sg_name.id}"]
    # Associate a public IP address with the instance
    associate_public_ip_address = true
    # Specify the key pair name for SSH access
    key_name = "web"
    
    # Define the root block device configuration
    root_block_device {
        volume_size = 10
        delete_on_termination = true
    }
    
    # Provide user data to configure the instance at launch
    user_data = <<EOF
  #!/bin/bash
  echo -e "\nPort 22" >> /etc/ssh/sshd_config
  sudo service sshd restart
  yum update -y
  yum install -y nc
  EOF
}

# Define an Elastic IP resource and associate it with the bastion instance
resource "aws_eip" "bastion" {
    instance = "${aws_instance.bastion.id}"
    
}


resource "aws_security_group" "allow_bastion_traffic" {
  vpc_id = aws_vpc.vpc_name.id
  name = "Allow SSH bastion traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------------------------------------------
# Web Server
# -------------------------------------------------------------------------------------------------

resource "aws_instance" "web_server" {
  ami                  = "ami-0a5a6018d12197ea4"
  instance_type        = "t3.medium"
  key_name = "web"
  user_data            = <<EOF
  #!/bin/bash
  echo -e "\nPort 22" >> /etc/ssh/sshd_config
  sudo service sshd restart
  copy ./index.html  > /home/bitnami/stack/nginx/html/index.html
  EOF
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true

}


resource "aws_iam_instance_profile" "web_server" {
  name = "web_profile"
  role = aws_iam_role.role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "test_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.vpc_name.id
  name = "Allow Web traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------------------------------------------
# Postgres Server
# -------------------------------------------------------------------------------------------------
# I have used same key as in web server as this is just a test environment


resource "aws_db_instance" "postgres_db" {
  depends_on              = [aws_db_parameter_group.postgresql_param_group]
  allocated_storage      = 50
  engine                 = "postgres"
  engine_version         = "14.14"
  db_name = "prostgresdb"
  db_subnet_group_name        = aws_db_subnet_group.postgres.name
  identifier             = "log"
  instance_class         = "db.m5d.large"
  skip_final_snapshot    = true
  apply_immediately      = true
  
  
  # Credentials
  username               = "root"
  password               = "admin2025password"

  # network
  publicly_accessible    = false
  # audit
  enabled_cloudwatch_logs_exports = ["postgresql","upgrade"]
  parameter_group_name            = aws_db_parameter_group.postgresql_param_group.name
}

resource "aws_db_subnet_group" "postgres" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id,aws_subnet.public.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_parameter_group" "postgresql_param_group" {
  name   = "logdb"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
    apply_method = "immediate"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
    apply_method = "immediate"
  }

  parameter {
    name  = "log_error_verbosity"
    value = "verbose"
    apply_method = "immediate"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "5000"
    apply_method = "immediate"
  }

  parameter {
    name  = "pgaudit.log"
    value = "all"
    apply_method = "immediate"
  }

  parameter {
    name  = "pgaudit.role"
    value = "rds_pgaudit"
    apply_method = "immediate"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pgaudit,pg_stat_statements"
    apply_method = "pending-reboot"
  }
}


resource "aws_security_group" "allow_postgres" {
  name = "Allow_postgres_traffic"
  description = "Postgres security group"
  vpc_id = aws_vpc.vpc_name.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol = "tcp"
    cidr_blocks = ["20.10.1.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  revoke_rules_on_delete = true

  # Ensure a new sg is in place before destroying the current one.
  # This will/should prevent any race-conditions.
  lifecycle {
    create_before_destroy = true
  }

}


