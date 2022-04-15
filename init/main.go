package main

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/secretsmanager"

	"github.com/pulumi/pulumi-github/sdk/v4/go/github"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {

	pulumi.Run(func(ctx *pulumi.Context) error {
		callerId, err := aws.GetCallerIdentity(ctx, nil, nil)
		project := "developers-paradise"
		githubUser := "mabels"

		// config := config.New(ctx, "")
		// Secret NECKLESS_PRIVATE_KEY
		sm, err := secretsmanager.GetSecret(ctx, "project/neckless",
			pulumi.ID(fmt.Sprintf("%s/neckless", project)), &secretsmanager.SecretState{})
		if err != nil {
			sm, _ = secretsmanager.NewSecret(ctx, "project/neckless", &secretsmanager.SecretArgs{
				Description: pulumi.String("Private key for Neckless"),
				Name:        pulumi.Sprintf("%s/neckless", project),
			})
			ctx.Export("neckless-privekey", pulumi.String("missing"))
		}
		// secretsmanager.PutSecretValue(ctx, &secretsmanager.PutSecretValueArgs{})

		// EC2 Runtime Role to access NECKLESS_PRIVATE_KEY
		ec2GHRunnerRole, _ := iam.NewRole(ctx, "ec2-github-runner", &iam.RoleArgs{
			Name: pulumi.Sprintf("%s-ec2-github-runner", project),
			AssumeRolePolicy: pulumi.String(`{
					"Version": "2012-10-17",
					"Statement": [
						{
							"Effect": "Allow",
							"Principal": {
								"Service": "ec2.amazonaws.com"
							},
							"Action": "sts:AssumeRole"
						}
					]
				}`),
		})

		iam.NewRolePolicy(ctx, "access-neckless-privkey", &iam.RolePolicyArgs{
			Role: ec2GHRunnerRole,
			Policy: pulumi.Sprintf(`{
				"Version": "2012-10-17",
				"Statement": {
					"Action": [
						"secretsmanager:GetResourcePolicy",
						"secretsmanager:GetSecretValue",
						"secretsmanager:DescribeSecret",
						"secretsmanager:ListSecretVersionIds",
						"secretsmanager:GetRandomPassword"
					],
					"Effect":   "Allow",
					"Resource": "%s"
				}
			}`, sm.Arn),
		})
		iam.NewRolePolicy(ctx, "ec2-self-assume", &iam.RolePolicyArgs{
			Role: ec2GHRunnerRole,
			Policy: pulumi.Sprintf(`{
							"Version": "2012-10-17",
							"Statement": {
								"Effect": "Allow",
								"Action": "sts:AssumeRole",
								"Resource": "%s"
							}
						}`, ec2GHRunnerRole.Arn),
		})

		iam.NewInstanceProfile(ctx, "ec2-github-runner", &iam.InstanceProfileArgs{
			Name: pulumi.Sprintf("%s-ec2-github-runner", project),
			Role: ec2GHRunnerRole,
		})

		ghUser, _ := github.GetUser(ctx, &github.GetUserArgs{
			Username: githubUser,
		})
		ec2.NewKeyPair(ctx, "ec2-github-manager", &ec2.KeyPairArgs{
			KeyName:   pulumi.Sprintf("%s-ec2-github-manager", project),
			PublicKey: pulumi.String(ghUser.SshKeys[0]),
			// pulumi.String("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7BOKHV5d3/cnXsZ23X8d6MT9H/1kn+oT2LRaKtyyKB6iLsEN6Hk2017RyFR98oWXqo5EM5ttL4ZTQNEawqp52KPGujDV7XHvu4/cxfNzjxhOUtJ9j5wOG4qVVvBfcvbFRo1wVuJRe+7uiA9seGU3LZ01ASM+ajEtRY2tLBrwJhY/4q08ghy8gBfFV0LDkY8wH965PYUZButHpJvCz6xTEzVVqeLKobD6jsE0PafgdBuiRC+ErRH0vkVfb5NEoB2UhZB/L9QqeVDEyrKTk2AcxlCa6zcLkcLq5ygel8+MUuW3zBscDQrNxJ09vzBFq0auV+Wq8/ElTJC5eIIYJ1WO88EuoMiG/BCMM75NrUqa6Bn5rgbHNVZAAxo0/qJSV4i7RTE+0OVEDu2jt+wNpWZEmCJ4TNIQyNFmxuRGjQqxHAtSWnkkO/LzOUw8rWCGLvgnrIX8jtRXvNqNnv1lTQ5X97d8TTA55dNkeYUCC4NbeWr49zqcW//36r4KIku48PuU= revealsix"),
		})
		// ec2.GetDefaultVpc(ctx, "default-vpc", id IDInput, state *DefaultVpcState, opts ...ResourceOption) (*DefaultVpc, error)
		// Copy

		ec2.NewSecurityGroup(ctx, "ec2-github-runner", &ec2.SecurityGroupArgs{
			Name: pulumi.Sprintf("%s-ec2-github-runner", project),
			Egress: ec2.SecurityGroupEgressArray{
				&ec2.SecurityGroupEgressArgs{
					FromPort: pulumi.Int(0),
					ToPort:   pulumi.Int(0),
					Protocol: pulumi.String("-1"),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
				},
			},
			Ingress: ec2.SecurityGroupIngressArray{
				&ec2.SecurityGroupIngressArgs{
					Description: pulumi.String("SSH-into-Github-Runner"),
					FromPort:    pulumi.Int(22),
					ToPort:      pulumi.Int(22),
					Protocol:    pulumi.String("tcp"),
					CidrBlocks: pulumi.StringArray{
						pulumi.String("0.0.0.0/0"),
					},
					Ipv6CidrBlocks: pulumi.StringArray{
						pulumi.String("::/0"),
					},
				},
			},
		})
		// aws iam create-instance-profile --instance-profile-name Neckless
		// aws iam add-role-to-instance-profile --instance-profile-name Neckless --role-name codebuild-developers-paradise-service-role

		// OCID Github Role + EC2 Create
		oicp, err := iam.GetOpenIdConnectProvider(ctx, "github-provider",
			pulumi.ID(fmt.Sprintf("arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
				callerId.AccountId)),
			&iam.OpenIdConnectProviderState{})
		if err != nil {
			oicp, _ = iam.NewOpenIdConnectProvider(ctx, "github-provider", &iam.OpenIdConnectProviderArgs{
				Url:             pulumi.String("https://token.actions.githubusercontent.com"),
				ClientIdLists:   pulumi.StringArray{pulumi.String("sts.amazonaws.com")},
				ThumbprintLists: pulumi.StringArray{pulumi.String("6938fd4d98bab03faadb97b34396831e3780aea1")},
			})
		}
		ghRunnerRole, _ := iam.NewRole(ctx, "github-runner", &iam.RoleArgs{
			Name: pulumi.Sprintf("%s-github-runner", project),
			AssumeRolePolicy: pulumi.Sprintf(`{
				"Version": "2008-10-17",
				"Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Federated": "%s"
						},
						"Action": "sts:AssumeRoleWithWebIdentity",
						"Condition": {
							"StringLike": {
								"token.actions.githubusercontent.com:sub": "repo:%s/%s:*"
							}
						}
					}
				]
			}`, oicp.Arn, githubUser, project),
		})
		iam.NewRolePolicyAttachment(ctx, "ec2-full-access", &iam.RolePolicyAttachmentArgs{
			Role:      ghRunnerRole,
			PolicyArn: iam.ManagedPolicyAmazonEC2FullAccess,
		})
		iam.NewRolePolicyAttachment(ctx, "ecr-power-user", &iam.RolePolicyAttachmentArgs{
			Role:      ghRunnerRole,
			PolicyArn: pulumi.String("arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicPowerUser"),
		})
		iam.NewRolePolicy(ctx, "ecr-public-batch-clean", &iam.RolePolicyArgs{
			Role: ghRunnerRole,
			Policy: pulumi.Sprintf(`{
				"Version": "2012-10-17",
				"Statement": [
					{
						"Effect": "Allow",
						"Action": [
							"ecr-public:BatchDeleteImage"
						],
						"Resource": "*"
					}
				]
			}`),
		})
		iam.NewRolePolicy(ctx, "iam-get-pass-role", &iam.RolePolicyArgs{
			Role: ghRunnerRole,
			Policy: pulumi.Sprintf(`{
			"Version": "2012-10-17",
			"Statement": [
				{
					"Effect": "Allow",
					"Action": [
						"iam:GetRole",
						"iam:PassRole"
					],
					"Resource": "%s" 
				}
			]
		}`, ec2GHRunnerRole.Arn),
		})

		// ctx.Export("roleArn", allowS3ManagementRole.Arn)
		// ctx.Export("accessKeyId", unprivilegedUserCreds.ID().ToStringOutput())
		// ctx.Export("secretAccessKey", unprivilegedUserCreds.Secret)
		return nil
	})
}
