resource "aws_db_subnet_group" "this" {
  name = "${var.name}-db-subnets"

  subnet_ids = [
    data.aws_subnet.sub_database_1.id,
    data.aws_subnet.sub_database_2.id
  ]
}

resource "aws_security_group" "rds" {
  name   = "${var.name}-rds"
  vpc_id = data.aws_vpc.vpc_narre_main.id
}

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.eks.node_security_group_id
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20

  db_name  = "training"
  username = "trainingadmin"
  password = "Training123!"

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true
}
