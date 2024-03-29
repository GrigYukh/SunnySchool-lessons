#!/bin/bash

# Создание VPC
echo "Creating VPC..."
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# Создание публичной подсети
echo "Creating public subnet..."
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.128.0/24 --query 'Subnet.SubnetId' --output text)

# Создание Internet Gateway (IGW) и привязка его к VPC
echo "Creating and attaching Internet Gateway (IGW)..."
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id

# Создание маршрутной таблицы для публичной подсети и привязка IGW
echo "Creating and associating route table for public subnet..."
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $route_table_id

# Создание приватной подсети
echo "Creating private subnet..."
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.129.0/24 --query 'Subnet.SubnetId' --output text)

# Создание NAT Gateway (NAT GW) и привязка его к публичной подсети
echo "Creating and attaching NAT Gateway (NAT GW) to public subnet..."
eip_allocation_id=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
nat_gateway_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $eip_allocation_id --query 'NatGateway.NatGatewayId' --output text)

# Ожидание, пока NAT GW будет доступен
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $nat_gateway_id

# Создание маршрутной таблицы для приватной подсети и привязка NAT GW
echo "Creating and associating route table for private subnet..."
private_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gateway_id
aws ec2 associate-route-table --subnet-id $private_subnet_id --route-table-id $private_route_table_id

echo "VPC setup complete!"
