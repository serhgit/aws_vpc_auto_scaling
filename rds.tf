resource "aws_security_group" "allow_db_from_internal_subnets" {
  name        = "allow_db_from_internal_subnets"
  description = "Allow DB access from WEB servers"
  vpc_id      = aws_vpc.vpc_01.id

  ingress =[
    {
      description = "DB access to the instance"
      protocol    = "tcp"
      from_port   = 3306
      to_port     = 3306
      cidr_blocks = aws_subnet.vpc_subnets.*.cidr_block
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
}

resource "aws_db_subnet_group" "aurora_db_subnet_group" {
  name       = "aurora-db-subnet-group"
  subnet_ids = aws_subnet.vpc_subnets.*.id

  tags = {
    Name = "Aurora DB subnet group"
  }
}


resource "aws_rds_cluster" "aurora_mysql_cluster" {

  cluster_identifier = "aurora-mysql-cluster"
  db_subnet_group_name = aws_db_subnet_group.aurora_db_subnet_group.name
  engine               = "aurora-mysql"
  engine_mode          = "provisioned"
  database_name        = "auroradb"
  master_username      = "aurorauser"
  master_password     = "aurorapassword"

 skip_final_snapshot  = true
}

resource "aws_rds_cluster_instance" "aurora_mysql_cluster_instance" {
  count = 2
  identifier         = "aurora-mysql-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_mysql_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.aurora_mysql_cluster.engine
  engine_version     = aws_rds_cluster.aurora_mysql_cluster.engine_version

}
