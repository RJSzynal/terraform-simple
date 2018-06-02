# terraform-simple
A simple Terraform config to run a cheap but flexible environment.

I created this as an educational base project, I highly recommend you try to understand what everything is doing rather than just running it. You can, however, just run it if you need a cheap hosted site on AWS.

### Usage

Create a file named terraform.tfvars and populate it with the following, replacing the placeholders with your key name and account id.
```tfvars
private_key_name = "YOUR_PRIVATE_KEY_NAME"
account_id = "YOUR_ACCOUNT_ID"
```

Log into your AWS account, go to Key Pairs in the Network & Security section of EC2 and press Create Key Pair. Enter the key name you set in the tfvars file and create the new keypair, this will download the new private key to your machine. This is the only time you can get this key and it will have access to your instances so make sure you store it securely.

Create an S3 bucket to hold your terraform state, as S3 bucket names are globally unique you'll need to create your own name. It is recommended to enable versioning for this bucket in case of accidental deletions and human error. (See this page for further information https://www.terraform.io/docs/backends/types/s3.html)

Set up applications.tf to match what you'd like setting up, update the information to suit your project.

Run `terraform init` on the terraform-simple directory to initialise the configuration. Then run `terraform apply` to plan the resources, check it all looks correct then apply to create the resources.

ssh into your new instance and check out you project into the directory you set in the app_src_location entry in the applications.tf file (you may have to add your private key to the server if it's a private repo, I will not cover how to do that here).

Add the public IP of the instance to your chosen DNS provider.

#### Using route 53 for DNS

If you're using Route 53 for DNS you can follow the instructions in the comments at the bottom of the main.tf in the module directories (e.g. php-mysql/main.tf).
