# Infrastructure as Code with Terraform

This Terraform configuration sets up a complete AWS infrastructure for running a Node.js application with PostgreSQL database.

## Infrastructure Components

1. **VPC (Virtual Private Cloud)**
   - CIDR block: 10.0.0.0/16
   - Public and private subnets
   - Internet Gateway for public access
   - NAT Gateway for private subnet internet access

2. **EC2 Instance**
   - t2.micro instance (Free Tier eligible)
   - Ubuntu AMI
   - Public IP address
   - Security group allowing:
     - SSH (port 22)
     - HTTP (port 3000)
     - All outbound traffic

3. **RDS Instance (PostgreSQL)**
   - db.t3.micro instance (Free Tier eligible)
   - 20GB storage
   - Security group allowing:
     - PostgreSQL (port 5432) from EC2
     - PostgreSQL from within VPC

4. **Security Groups**
   - EC2 Security Group: Allows SSH and HTTP
   - RDS Security Group: Allows PostgreSQL from EC2 and VPC

## Prerequisites

1. **AWS Account Setup**
   - Create an AWS account at https://aws.amazon.com/
   - Enable MFA (Multi-Factor Authentication) for your root account
   - Set up billing alerts to monitor costs

2. **IAM User Setup**
   - Log in to AWS Console and go to IAM service
   - Create a new IAM user:
     1. Click "Users" → "Add user"
     2. Enter a username (e.g., "terraform-user")
     3. Select "Access key - Programmatic access"
     4. Click "Next: Permissions"
   - Attach required permissions:
     1. Click "Attach existing policies directly"
     2. Search for and select these policies:
        - `AmazonEC2FullAccess`
        - `AmazonRDSFullAccess`
        - `AmazonVPCFullAccess`
        - `IAMFullAccess`
   - Review and create the user
   - **IMPORTANT**: Save the Access Key ID and Secret Access Key securely

3. **AWS CLI Configuration**
   - Install AWS CLI if not already installed
   - Configure AWS CLI with your IAM user credentials:
     ```bash
     aws configure
     ```
   - Enter the following when prompted:
     - AWS Access Key ID: [Your Access Key ID]
     - AWS Secret Access Key: [Your Secret Access Key]
     - Default region name: [Your preferred region, e.g., eu-central-1]
     - Default output format: json

4. **Terraform**
   - Install Terraform (version 1.0.0 or later)
   - Verify installation:
     ```bash
     terraform --version
     ```

5. **SSH Key Pair**
   - Create an SSH key pair for EC2 access:
     ```bash
     ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws_key
     ```

## Configuration

1. **Environment Setup**
   Create and configure the Terraform environment file:
   ```bash
   cd terraform
   cp .env.terraform-script.example .env.terraform-script
   ```
   
   Edit `.env.terraform-script` with your values:
   ```bash
   # AWS Credentials
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_DEFAULT_REGION=eu-central-1
   ```


2. **Set Variables**
   Create `terraform.tfvars` from the example file:
   ```bash
   cp terraform.tfvars-example terraform.tfvars
   ```

## Usage

The easiest way to manage your Terraform infrastructure is using the provided `run-terraform.sh` script. This script handles environment variable loading and Terraform command execution.

1. **Initialize Terraform**
   ```bash
   ./run-terraform.sh init
   ```

2. **Plan Changes**
   ```bash
   ./run-terraform.sh plan
   ```

3. **Apply Configuration**
   ```bash
   ./run-terraform.sh apply
   ```

4. **Destroy Infrastructure**
   ```bash
   ./run-terraform.sh destroy
   ```

The script automatically:
- Sources the `.env.terraform` file
- Sets up the AWS credentials
- Runs the specified Terraform command
- Handles error cases

For manual Terraform operations (not recommended):
```bash
cd terraform
source .env.terraform
terraform [command]
```

## Post-Deployment Steps

1. **Access EC2 Instance**
   ```bash
   ssh -i $AWS_KEY_PATH ubuntu@<ec2-public-ip>
   ```

2. **Check Setup Logs**
   After deployment, check the setup logs to ensure everything was configured correctly:
   ```bash
   # Check cloud-init logs
   sudo cat /var/log/cloud-init-output.log
   
   # Check application setup logs
   sudo cat /var/log/app-setup.log
   
   # Check PM2 logs
   pm2 logs
   
   # Check database initialization logs
   sudo cat /var/log/db-init.log
   ```

3. **Check Application Status**
   ```bash
   pm2 list
   pm2 logs
   ```

4. **Check Database Connection**
   ```bash
   nc -zv <rds-endpoint> 5432
   ```

## Monitoring

1. **EC2 Instance**
   - Check CPU and memory usage
   - Monitor application logs
   - Verify security group rules

2. **RDS Instance**
   - Monitor database connections
   - Check storage usage
   - Review performance metrics

## Cost Considerations

This configuration uses Free Tier eligible resources:
- EC2: t2.micro instance
- RDS: db.t3.micro instance with 20GB storage
- EBS: 8GB root volume

Note: Some resources (like NAT Gateway) are not Free Tier eligible.

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

1. **Database Connection Issues**
   - Verify security group rules
   - Check RDS endpoint
   - Confirm database credentials

2. **EC2 Access Problems**
   - Verify SSH key pair
   - Check security group rules
   - Confirm instance status

3. **Application Deployment**
   - Check setup script logs
   - Verify environment variables
   - Review PM2 process status

## Security Notes

1. **Database Security**
   - Use strong passwords
   - Limit database access to EC2 only
   - Regularly rotate credentials

2. **Instance Security**
   - Use SSH key pairs
   - Keep systems updated
   - Monitor security groups

3. **Network Security**
   - Use private subnets for databases
   - Implement proper security group rules
   - Monitor network traffic

4. **Environment Variables**
   - Keep `.env.terraform` secure and never commit it to version control
   - Use `.env.terraform.example` as a template
   - Regularly rotate AWS credentials

## Support

For issues or questions:
1. Check Terraform documentation
2. Review AWS documentation
3. Check application logs
4. Contact repository maintainer 