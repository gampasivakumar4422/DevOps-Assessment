# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  vpc_id      = aws_vpc.main_vpc.id

  # Inbound rule for HTTP (port 3000) from ALB
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere, you can restrict this as needed
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-service-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main_cluster" {
  name = "notification-service-cluster"
}

# ECS Task Definition (declaring this resource)
resource "aws_ecs_task_definition" "task" {
  family                   = "notification-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "notification-service",
    "image": "${aws_ecr_repository.notification_service.repository_url}:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
DEFINITION
}

# ECS Service
resource "aws_ecs_service" "service" {
  name              = "notification-service"
  cluster           = aws_ecs_cluster.main_cluster.id
  task_definition   = aws_ecs_task_definition.task.arn  # Ensure this points to the defined task definition
  desired_count     = 1
  launch_type       = "FARGATE"
  platform_version  = "LATEST"
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "notification-service"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.frontend]
}


