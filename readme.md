# Terraform Example

Just enough to get started.

## Basics

# Terraform

Setup
Download terraform zip file from terraform.io
`unzip terraform` unzip the zip file
`mv terraform /usr/local/bin` move it to the user bin folder as it is already in the PATH

.tf file
HCL - Harshicorp Configuration Language (Happy middle of JSON and YAML)

`terraform init` will dowload the provider

`terraform apply` is idempotent.

To delete `terraform destroy`

To automatically approve (Without hitting yes everytime)

`terraform apply --auto-approve`

Never touch state file unless you are very sure (`.tfstate`)

To view the items in the current state : `terraform state list`

Example:

```
$ terraform state list

aws_eip.one
aws_instance.web_server_instance
aws_internet_gateway.prod_igw
aws_network_interface.web_server_nic
aws_route_table.prod_route_table
aws_route_table_association.prod_vpc_subnet_1_to_prod_route_table
aws_security_group.allow_web
aws_subnet.prod_vpc_subnet_1
aws_vpc.prod_vpc
```

To view specific details about a particular item `terraform state show <resourcename>`

Example:

```
~$ terraform state show aws_vpc.prod_vpc

# aws_vpc.prod_vpc:
resource "aws_vpc" "prod_vpc" {
    arn                              = "arn:aws:ec2:us-east-1:053500961007:vpc/vpc-0d96765da99979939"
    assign_generated_ipv6_cidr_block = false
    cidr_block                       = "10.0.0.0/16"
    default_network_acl_id           = "acl-0d78bdc962af760d9"
    default_route_table_id           = "rtb-0de67d63128bb8bd5"
    default_security_group_id        = "sg-02910956310a3e3f4"
    dhcp_options_id                  = "dopt-4b771f31"
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    enable_dns_hostnames             = false
    enable_dns_support               = true
    id                               = "vpc-0d96765da99979939"
    instance_tenancy                 = "default"
    main_route_table_id              = "rtb-0de67d63128bb8bd5"
    owner_id                         = "053500961007"
    tags                             = {
        "Name"    = "prod_vpc"
        "Warning" = "Created by terraform. Dont alter or delete manually"
    }
    tags_all                         = {
        "Name"    = "prod_vpc"
        "Warning" = "Created by terraform. Dont alter or delete manually"
    }
}

```

To output the state details when applying use the output

`terraform output`

If you are in production you dont want to use the output command. Instead try
`terraform refresh` which will grab all the output statements and print out for us.

To delete/apply just one resource out of hte list use the terraform target.

Example: This will destroy the webserve EC2 instance alone and refresh the state.
`terraform destroy -target aws_instance.web_server_instance `
This will just create the EC2 instance and refresh state
`terraform apply -target aws_instance.web_server_instance `

### Variables

```

variable "variable_name" {
description =""
default =""
type =string
}

```

Terraform supports various types. (Refer documentation)
Variable values can be either keyed in , or passed as command line argument or be supplied from a `.tfvars` file.

Example: `terraform apply -var-file example.tfvars` (If you name the file as terraform.tfvars then you dont have to specify the file name)

## This Project details below:

### 1. Create a VPC

### 2. Create an Internet Gateway

### 3. Create a Custom Route Table

### 4. Create a subnet

### 5. Associate the subnet from Step 4 with a Route Table

### 6. Create a Security Group to allow ports 22,80 and 443

### 7. Create a network interface with an ip in the subnet that was created in step 4

### 8. Assign Elastic IP to the Network Interface created in Step 7

### 9. Create an Ubuntu server and install/enable Apache2

### 10. Output properties of resources created.

### NOTE: For your screts, create a secrets.tfvars file and provide values Example below

```
access_key = "ABCDEFGHIJKLMNOPQ"
secret_key = "AAsWlmnqweerd23rfdffj34113jfsj34KDB"

```

When you apply you have to specify `terraform apply -var-file secrtes.tfvars`
