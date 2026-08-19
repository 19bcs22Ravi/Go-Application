output "cluster_id" {
  value = aws_eks_cluster.goapp.id
}

output "node_group_id" {
  value = aws_eks_node_group.goapp.id
}

output "vpc_id" {
  value = aws_vpc.goapp_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.goapp_subnet[*].id
}
