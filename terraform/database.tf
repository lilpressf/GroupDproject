# # this gives error:
# resource "aws_db_subnet_group" "db_subnet_group" {
#   name = "narre-db-subnet-group"

#   subnet_ids = [
#     aws_subnet.sub_database_2.id,
#     aws_subnet.sub_private_1.id
#   ]

#   tags = {
#     Name = "narre-db-subnet-group"
#   }
# }

# resource "aws_db_instance" "mydb" {
#   identifier           = "narre-db"
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = "db.t3.micro"
#   allocated_storage    = 20

#   db_name  = "narre_db"
#   username = var.db_username
#   password = var.db_password

#   db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.database_sg.id]

#   publicly_accessible = false
#   multi_az            = false
#   skip_final_snapshot = true

#   tags = {
#     Name = "narre-db"
#   }
# }

# # this gives error:
# # resource "null_resource" "db_init" {
# #   triggers = {
# #     db_instance_id = aws_db_instance.mydb.id
# #     schema_hash    = filesha1("${path.module}/db/schema.sql")
# #   }

# #   provisioner "local-exec" {
# #     command = <<-EOT
# #       mysql \
# #         --host='${aws_db_instance.mydb.address}' \
# #         --port='${aws_db_instance.mydb.port}' \
# #         --user='${var.db_username}' \
# #         --password='${var.db_password}' \
# #         '${aws_db_instance.mydb.db_name}' < '${path.module}/db/schema.sql'
# #     EOT
# #   }

# #   depends_on = [aws_db_instance.mydb]
# # }
