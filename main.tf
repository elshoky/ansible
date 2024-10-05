provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_all_ports" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kubernetes-machine" {
  ami                         = "ami-0e86e20dae9224db8" 
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "yat-devops-httpd-webserver"

  tags = {
    "Name" = "kubernetes-machine"
  }

  security_groups = [
    aws_security_group.allow_all_ports.name
  ]

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/aws_ec2.yaml"
    destination = "/home/ubuntu/aws_ec2.yaml"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/ansible.cfg"
    destination = "/home/ubuntu/ansible.cfg"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/ping_hosts.yaml"
    destination = "/home/ubuntu/ping_hosts.yaml"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/.ssh/yat-devops-httpd-webserver.pem"
    destination = "/home/ubuntu/.ssh/yat-devops-httpd-webserver.pem"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/roles"
    destination = "/home/ubuntu/roles"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/setup.yaml"
    destination = "/home/ubuntu/setup.yaml"
  }

  provisioner "file" {
    source      = "/home/ahmedkhalid/DEPI-DevOps/ansible/env.sh"
    destination = "/home/ubuntu/env.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 600 /home/ubuntu/.ssh/yat-devops-httpd-webserver.pem",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/ahmedkhalid/.ssh/yat-devops-httpd-webserver.pem")
    host        = self.public_ip
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update

              curl -sfL https://get.k3s.io | sh -

              # Ensure kubeconfig permissions are set
              mkdir -p /home/ubuntu/.kube
              sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
              sudo chmod 600 /home/ubuntu/.kube/config
              echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> "/home/ubuntu/.bashrc"

              sudo apt install -y software-properties-common
              sudo add-apt-repository --yes --update ppa:ansible/ansible
              sudo apt install -y ansible

              sudo apt install -y python3-pip
              ansible-galaxy collection install amazon.aws --force
              pip install boto3 --break-system-packages
              EOF
}

resource "aws_instance" "jenkins-machine" { 
  ami                         = "ami-0e86e20dae9224db8" 
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "yat-devops-httpd-webserver"

  tags = {
    "Name" = "jenkins-machine"
  }

  security_groups = [
    aws_security_group.allow_all_ports.name
  ]
}