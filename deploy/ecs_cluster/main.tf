data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "current" {}

module "lab" {
  source = "github.com/kcdubois/terraform-modules//modules/lab"

  tags = var.tags
}


# networking

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${module.lab.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.current.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true
  default_security_group_ingress = [
    {
      description = "Allow traffic from default"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      self        = true
    }
  ]
  default_security_group_egress = [
    {
      description = "Default outbound allow"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"

    }
  ]

  tags = module.lab.tags
}

# ECS Cluster 

resource "aws_ecs_cluster" "fargate" {
  name = "${module.lab.name}-ecs"

  tags = module.lab.tags
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.fargate.name

  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"

  }
}

resource "aws_iam_role" "ecs" {
  name = "${module.lab.name}-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_cloudwatch" {
  name       = "ecs-cloudwatch-logs"
  policy_arn = data.aws_iam_policy.EcsExecutionTask.arn
  roles      = [aws_iam_role.ecs.name]
}

data "aws_iam_policy" "EcsExecutionTask" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

# ECS Task

resource "aws_ecs_task_definition" "eris" {
  family             = "${module.lab.name}-eris"
  execution_role_arn = aws_iam_role.ecs.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      name      = "eris"
      image     = var.image_name
      essential = true
      portMappings = [
        {
          containerPort = 8000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "${module.lab.name}"
        }
      }
    }
  ])


}

resource "aws_ecs_service" "eris" {
  name = "${module.lab.name}-eris"

  cluster         = aws_ecs_cluster.fargate.id
  task_definition = aws_ecs_task_definition.eris.arn

  desired_count = 1

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.vpc.default_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "eris"
    container_port   = 8000
    target_group_arn = aws_lb_target_group.eris.arn
  }



  tags = module.lab.tags
}

# Load balancer

resource "aws_lb" "ecs" {
  name     = "${module.lab.name}-ecs-alb"
  internal = false

  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group_id]
  subnets            = module.vpc.public_subnets

  tags = module.lab.tags
}

resource "aws_lb_listener" "ecs_http" {
  load_balancer_arn = aws_lb.ecs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eris.arn
  }

  depends_on = [aws_lb.ecs]
}

resource "aws_lb_target_group" "eris" {
  name        = "${module.lab.name}-ecs-target"
  protocol    = "HTTP"
  port        = 8000
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  depends_on = [aws_lb.ecs]
}

# # Logging

resource "aws_cloudwatch_log_group" "ecs" {
  name = "${module.lab.name}-log-group"
  tags = module.lab.tags
}

# Outputs

output "lb_fqdn" {
  value = aws_lb.ecs.dns_name
}
