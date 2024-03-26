# Add the private EC2 instance as a target.
resource "boundary_target" "super-secret-ec2-instance" {
  type                     = "tcp"
  name                     = "super-secret-ec2-instance"
  description              = "Super-secret-EC2-instance"
  address                  = aws_instance.main.private_ip
  ingress_worker_filter    = " \"pki-worker\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
}

# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "ops-org"
  description              = "Support Ops Team"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsiation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "Ops_Production"
  description              = "Manage Prod Resources"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}


# Create and configure the PKI Worker in HCP Boundary:
resource "boundary_worker" "pki_worker" {
  scope_id                    = "global"
  name                        = "bounday-pki-worker"
  worker_generated_auth_token = ""
}

locals {
  boundary_pki_worker_service_config = <<-WORKER_SERVICE_CONFIG
  [Unit]
  Description="HashiCorp Boundary - Identity-based access management for dynamic infrastructure"
  Documentation=https://www.boundaryproject.io/docs
  #StartLimitIntervalSec=60
  #StartLimitBurst=3

  [Service]
  EnvironmentFile=-/etc/boundary.d/boundary.env
  User=boundary
  Group=boundary
  ProtectSystem=full
  ProtectHome=read-only
  ExecStart=/usr/bin/boundary server -config=/etc/boundary.d/pki-worker.hcl
  ExecReload=/bin/kill --signal HUP $MAINPID
  KillMode=process
  KillSignal=SIGINT
  Restart=on-failure
  RestartSec=5
  TimeoutStopSec=30
  LimitMEMLOCK=infinity

  [Install]
  WantedBy=multi-user.target
  WORKER_SERVICE_CONFIG

  boundary_pki_worker_hcl_config = <<-WORKER_HCL_CONFIG
  disable_mlock = true

  hcp_boundary_cluster_id = "${split(".", split("//", hcp_boundary_cluster.offsite-2024.cluster_url)[1])[0]}"

  listener "tcp" {
    address = "0.0.0.0:9202"
    purpose = "proxy"
  }

  worker {
    public_addr = "file:///tmp/ip"
    auth_storage_path = "/etc/boundary.d/worker"
    controller_generated_activation_token = "${boundary_worker.pki_worker.controller_generated_activation_token}"
    tags {
      type = ["pki-worker", "upstream"]
    }
  }
WORKER_HCL_CONFIG

  cloudinit_config_boundary_pki_worker = {
    write_files = [
      {
        content = local.boundary_pki_worker_service_config
        path    = "/usr/lib/systemd/system/boundary.service"
      },

      {
        content = local.boundary_pki_worker_hcl_config
        path    = "/etc/boundary.d/pki-worker.hcl"
      },
    ]
  }
}

data "cloudinit_config" "boundary_pki_worker" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
      sudo apt update -y && apt upgrade -y
      sudo apt install boundary-enterprise
      curl 'https://api.ipify.org?format=txt' > /tmp/ip      
  EOF
  }
  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.cloudinit_config_boundary_pki_worker)
  }
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo boundary server -config="/etc/boundary.d/pki-worker.hcl"
    EOF
  }
}

# RSA key of size 4096 bits
resource "tls_private_key" "public-ec2_rsa_4096_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "public-ec2_key" {
  key_name   = "public-ec2_key"
  public_key = trim("${tls_private_key.public-ec2_rsa_4096_key.public_key_openssh}", "\n")

  provisioner "local-exec" {
    command = <<-EOT
    echo '${tls_private_key.public-ec2_rsa_4096_key.private_key_pem}' > public-ec2_key.pem
      chmod 400 public-ec2_key.pem
    EOT
  }
}

resource "aws_instance" "boundary_pki_worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  user_data_replace_on_change = true
  user_data_base64            = data.cloudinit_config.boundary_pki_worker.rendered
  subnet_id     = aws_subnet.public_subnets[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.pki-worker-sg.id]
  key_name      = aws_key_pair.public-ec2_key.key_name
  tags = {
    Name = "Boundary PKI Worker"
  }
}

# Deploy public EC2 instance, which will be used as PKI worker connected to our HCP Boundary (controller):

data "aws_ami" "pki-worker-ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "pki-worker-sg" {
  name   = "pki-worker-sg"
  vpc_id = hcp_aws_network_peering.peer.peer_vpc_id

  # Inbound rules:
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound connection to secure target:
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules added 80 and 443 as apt was failing with timeouts:
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound connection to HCP Boundary (controller):
  egress {
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
### Re-declare resources from the previous project:
#

resource "hcp_boundary_cluster" "offsite-2024" {
  cluster_id = var.hcp-b-cluster_id
  tier       = var.hcp-b_tier
  username   = var.HCP_B_U
  password   = var.HCP_B_P
}

#
### Re-declare resources from the previous project:
#

resource "aws_iam_user" "secrets_engine" {
  name = "dynamic-aws-creds-vault-user"
}

resource "aws_iam_access_key" "secrets_engine_credentials" {
  user = aws_iam_user.secrets_engine.name
}

resource "vault_aws_secret_backend" "aws" {
  region = var.region
  path   = "dynamic-aws-creds-vault-path"

  access_key = aws_iam_access_key.secrets_engine_credentials.id
  secret_key = aws_iam_access_key.secrets_engine_credentials.secret

  default_lease_ttl_seconds = "120"
}

data "vault_aws_access_credentials" "creds" {
  backend = "dynamic-aws-creds-vault-path"
  role    = "dynamic-aws-creds-vault-role"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# RSA key of size 4096 bits
resource "tls_private_key" "private-ec2_rsa_4096_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "private-ec2_key" {
  key_name   = "private-ec2-key"
  public_key = trim("${tls_private_key.private-ec2_rsa_4096_key.public_key_openssh}", "\n")

  provisioner "local-exec" {
    command = <<-EOT
    echo '${tls_private_key.private-ec2_rsa_4096_key.private_key_pem}' > private-ec2-key.pem
      chmod 400 private-ec2-key.pem
    EOT
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = aws_key_pair.private-ec2_key.key_name
  tags = {
    Name  = "Super-secret-EC2-instance"
    TTL   = var.ttl
    Owner = "${var.project_name}-operator"
  }
}

resource "aws_iam_user_policy" "secrets_engine" {
  user = aws_iam_user.secrets_engine.name

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "iam:*", "ec2:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
    Version = "2012-10-17"
  })
}

# Ask TFC to create a role for the AWS Secret Engine with a policy that allows the role access to iam and ec2:
resource "vault_aws_secret_backend_role" "admin" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "dynamic-aws-creds-vault-role"
  credential_type = "iam_user"

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*", "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Dynamically generate token a for HCP Vault using the variables we set in TFC:
resource "hcp_vault_cluster_admin_token" "hcp-v-offsite-2024" {
  cluster_id = var.cluster_id
}

resource "hcp_vault_cluster" "offsite-2024" {
  hvn_id          = hcp_hvn.offsite-2024.hvn_id
  cluster_id      = var.cluster_id
  tier            = var.hcp-vault_tier
  public_endpoint = true
  depends_on      = [aws_internet_gateway.hvn-gw]
}

# Create HCP HVN:
resource "hcp_hvn" "offsite-2024" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "aws_vpc" "peer" {
  cidr_block = "172.31.0.0/16"
}

# Create HCP HVN Peering to AWS VPC:
data "aws_arn" "peer" {
  arn = aws_vpc.peer.arn
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id          = hcp_hvn.offsite-2024.hvn_id
  peering_id      = var.peering_id
  peer_vpc_id     = aws_vpc.peer.id
  peer_account_id = aws_vpc.peer.owner_id
  peer_vpc_region = data.aws_arn.peer.region
}

resource "hcp_hvn_route" "peer_route" {
  hvn_link         = hcp_hvn.offsite-2024.self_link
  hvn_route_id     = var.route_id
  destination_cidr = aws_vpc.peer.cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

# Create AWS Internet gateway:
resource "aws_internet_gateway" "hvn-gw" {
  vpc_id = aws_vpc.peer.id
}

resource "aws_route_table" "hvn_second_rt" {
  vpc_id = aws_vpc.peer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hvn-gw.id
  }
}

resource "aws_subnet" "public_subnets" {
  count      = length(var.subnet_cidrs)
  vpc_id     = aws_vpc.peer.id
  cidr_block = element(var.subnet_cidrs, count.index)
}

resource "aws_route_table_association" "subnet_asso" {
  count          = length(var.subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.hvn_second_rt.id
}
