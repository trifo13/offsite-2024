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
resource "aws_subnet" "hvn_vpc" {
  vpc_id     = hcp_aws_network_peering.peer.peer_vpc_id
  cidr_block = "172.31.0.0/20"

  availability_zone = "us-west-2c"
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa_4096_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-key"
  public_key = trim("${tls_private_key.rsa_4096_key.public_key_openssh}", "\n")


  provisioner "local-exec" {
    command = <<-EOT
    echo '${tls_private_key.rsa_4096_key.private_key_pem}' > ec2-key.pem
      chmod 400 ec2-key.pem
    EOT
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.hvn_vpc.id
  key_name      = aws_key_pair.ec2_key.key_name
  tags = {
    Name  = "Super-secret-EC2-instance"
    TTL   = var.ttl
    Owner = "${var.project_name}-operator"
  }
}

#
### Re-declare resources from the previous project:
#

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

resource "aws_vpc" "peer" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

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

# Create HCP HVN:
resource "hcp_hvn" "offsite-2024" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_hvn_route" "peer_route" {
  hvn_link         = hcp_hvn.offsite-2024.self_link
  hvn_route_id     = var.route_id
  destination_cidr = aws_vpc.peer.cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}


# Create HCP Vault cluster:
resource "hcp_vault_cluster" "offsite-2024" {
  hvn_id          = hcp_hvn.offsite-2024.hvn_id
  cluster_id      = var.cluster_id
  tier            = var.hcp-vault_tier
  public_endpoint = true
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
