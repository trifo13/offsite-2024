# Create AWS User and Policy:
resource "aws_iam_user" "secrets_engine" {
  name = "${var.project_name}-user"
}

resource "aws_iam_access_key" "secrets_engine_credentials" {
  user = aws_iam_user.secrets_engine.name
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

# Ask TFC to use the HCP SP and Generate HCP Vault token:
resource "hcp_vault_cluster_admin_token" "hcp-v-offsite-2024" {
  cluster_id = var.cluster_id
}

# Ask TFC to enable the AWS Secret Engine and configure it with the variables we set in the Workspace:
resource "vault_aws_secret_backend" "aws" {
  region = var.region
  path   = "${var.project_name}-path"

  access_key = aws_iam_access_key.secrets_engine_credentials.id
  secret_key = aws_iam_access_key.secrets_engine_credentials.secret

  default_lease_ttl_seconds = "120"
}

# Ask TFC to create a role for the AWS Secret Engine with a policy that allows the role access to iam and ec2:
resource "vault_aws_secret_backend_role" "admin" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "${var.project_name}-role"
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

#
### Re-declare resources from the previous project:
#

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