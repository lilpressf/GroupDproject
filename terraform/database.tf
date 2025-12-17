resource "aws_db_instance" "mydb" {
  identifier             = "narre-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  name                   = "narre_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "narre-db"
  }
}

resource "null_resource" "db_init" {
  # Only rerun if the DB instance changes or the schema file changes
  triggers = {
    db_instance_id = aws_db_instance.mydb.id
    schema_hash    = filesha1("${path.module}/db/schema.sql")
  }

  provisioner "local-exec" {
    command = <<-EOT
      mysql \
        --host='${aws_db_instance.mydb.address}' \
        --port='${aws_db_instance.mydb.port}' \
        --user='${var.db_username}' \
        --password='${var.db_password}' \
        '${aws_db_instance.mydb.name}' < '${path.module}/db/schema.sql'
    EOT
  }

  depends_on = [aws_db_instance.mydb]
}
