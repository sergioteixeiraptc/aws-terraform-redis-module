resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = format("%.20s", "${var.name}-${var.environment}")
  replication_group_description = "Terraform managed | ${var.replication_group_description}"
  number_cache_clusters         = var.redis_clusters
  node_type                     = var.redis_node_type
  automatic_failover_enabled    = var.redis_failover
  engine_version                = var.redis_version
  port                          = var.redis_port
  parameter_group_name          = aws_elasticache_parameter_group.redis_parameter_group.id
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.id
  security_group_ids            = [aws_security_group.redis_security_group.id]
  apply_immediately             = var.apply_immediately
  maintenance_window            = var.redis_maintenance_window
  snapshot_window               = var.redis_snapshot_window
  snapshot_retention_limit      = var.redis_snapshot_retention_limit
  tags                          = merge(map("Name", format("terraform-elasticache-%s", var.name)), var.tags)
  snapshot_name                 = var.snapshot_name

}

resource "aws_elasticache_parameter_group" "redis_parameter_group" {
  name = replace(format("%.255s", lower(replace("redis-${var.name}-${var.environment}", "_", "-"))), "/\\s/", "-")

  description = "Terraform-managed ElastiCache parameter group for ${var.name}-${var.environment}"

  # Strip the patch version from redis_version var
  family = "redis${replace(var.redis_version, "/\\.[\\d]+$/", "")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = replace(format("%.255s", lower(replace("redis-${var.name}-${var.environment}", "_", "-"))), "/\\s/", "-")
  subnet_ids = var.subnets
}

resource "aws_security_group" "redis_security_group" {
  name        = format("%.255s", "${var.name}-${var.environment}")
  description = "Terraform-managed ElastiCache security group for ${var.name}-${var.environment}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-${var.environment}"
  }
}

resource "aws_security_group_rule" "redis_ingress" {
  count                    = length(var.allowed_security_groups)
  type                     = "ingress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  source_security_group_id = element(var.allowed_security_groups, count.index)
  security_group_id        = aws_security_group.redis_security_group.id
}

resource "aws_security_group_rule" "redis_networks_ingress" {
  type              = "ingress"
  from_port         = var.redis_port
  to_port           = var.redis_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr
  security_group_id = aws_security_group.redis_security_group.id
}
