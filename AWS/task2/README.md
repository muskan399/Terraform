# Task details
1. Create Security group which allow the port 80.

2. Launch EC2 instance.

3. In this Ec2 instance use the existing key or provided key and security group which we have created in step 1.

4. Launch one Volume using the EFS service and attach it in your vpc, then mount that volume into /var/www/html

5. Developer has uploded the code into github repo also the repo has some images.

6. Copy the GitHub repo code into /var/www/html

7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.

8. Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html.

Here we are using EFS rather than EBS because:

In EBS if we have various servers for our client then if we want to update our code then we need to go to every EBS volume and update it but using EFS we just need to make changes one time and it will get updated everywhere since it has centralized storage and also in EBS volume, we can attach to only that instance that is in the same datacentre or availability zone as EBS volume whereas EFS is a regional service we can match it to any instance in the same regional zone.

## EFS
Elastic File system is the service provided by AWS for File system .In the filesystem behind the scene, NAS protocol is used similarly EBS uses iSCSI/fiber channel in the backend, and object storage like s3 uses http protocol to retrieve data.Whenever we create a filesystem a NAS server is created in the backend which is centralized storage.
