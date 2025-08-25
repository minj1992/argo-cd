provider "aws" {
  region     = "us-east-1"
  #below is not recomnded its just for testing pupose i am using the code
  access_key = ""
  secret_key = "" 
}


# 1. VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
}

# 3. Public Subnets (2 AZs)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# 4. Route Table and Association
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role_app01" {
  name = "eks-cluster-role-app01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_attach_app01" {
  role       = aws_iam_role.eks_cluster_role_app01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 6. EKS Node IAM Role
resource "aws_iam_role" "eks_node_role_app01" {
  name = "eks-node-role-app01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy_1_app01" {
  role       = aws_iam_role.eks_node_role_app01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_policy_2_app01" {
  role       = aws_iam_role.eks_node_role_app01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_policy_3_app01" {
  role       = aws_iam_role.eks_node_role_app01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# 7. EKS Cluster
resource "aws_eks_cluster" "eks_cluster_app01" {
  name     = "test002-eks"
  role_arn = aws_iam_role.eks_cluster_role_app01.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_attach_app01]
}

# 8. EKS Node Group
resource "aws_eks_node_group" "eks_nodes_app01" {
  cluster_name    = aws_eks_cluster.eks_cluster_app01.name
  node_group_name = "test-eks-nodes"
  node_role_arn   = aws_iam_role.eks_node_role_app01.arn
  subnet_ids      = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.xlarge"]
  ami_type       = "AL2_x86_64"

  depends_on = [
    aws_iam_role_policy_attachment.node_policy_1_app01,
    aws_iam_role_policy_attachment.node_policy_2_app01,
    aws_iam_role_policy_attachment.node_policy_3_app01
  ]
}

# 9. Output Cluster Name
output "cluster_name_app01" {
  value = aws_eks_cluster.eks_cluster_app01.name
}
