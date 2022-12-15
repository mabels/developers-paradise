package main

import (
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/iam"
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/projects"
	"github.com/pulumi/pulumi-gcp/sdk/v6/go/gcp/serviceaccount"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		tmp, _ := ctx.GetConfig("gcp:project")
		gcpProject := pulumi.String(tmp)
		projects.NewService(ctx, "compute.googleapis.com", &projects.ServiceArgs{
			Service: pulumi.String("compute.googleapis.com"),
			Project: gcpProject,
		})
		// gcloud services enable iamcredentials.googleapis.com --project "${PROJECT_ID}"
		// gcloud iam service-accounts create "github-action-service-account" --project "${PROJECT_ID}"
		sa, err := serviceaccount.NewAccount(ctx, "github-action-service-account", &serviceaccount.AccountArgs{
			AccountId:   pulumi.String("github-action-service-account"),
			DisplayName: pulumi.String("Github Action Service Account"),
			Project:     gcpProject,
		})
		if err != nil {
			return err
		}

		// gcloud projects add-iam-policy-binding $PROJECT_ID \
		// 			"--member=serviceAccount:github-action-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
		// 			"--role=roles/compute.admin" "--role=roles/iam.serviceAccountUser"
		// ctx.Export("service-account", sa.Email)
		_, err = projects.NewIAMBinding(ctx, "compute-admin", &projects.IAMBindingArgs{
			Members: pulumi.StringArray{pulumi.Sprintf("serviceAccount:%s", sa.Email)},
			Project: gcpProject,
			Role:    pulumi.String("roles/compute.admin"),
		})
		if err != nil {
			return err
		}
		_, err = projects.NewIAMBinding(ctx, "iam-serviceAccountUser", &projects.IAMBindingArgs{
			Members: pulumi.StringArray{pulumi.Sprintf("serviceAccount:%s", sa.Email)},
			Project: gcpProject,
			Role:    pulumi.String("roles/iam.serviceAccountUser"),
		})
		if err != nil {
			return err
		}

		// gcloud iam workload-identity-pools create "github-action-pool" --project="${PROJECT_ID}" \
		//   --location="global" \
		//   --display-name="Github Action Pool"
		wip, err := iam.GetWorkloadIdentityPool(ctx, "github-action-pool", pulumi.ID("github-action-pool"), &iam.WorkloadIdentityPoolState{})
		if err != nil {
			wip, err = iam.NewWorkloadIdentityPool(ctx, "github-action-pool", &iam.WorkloadIdentityPoolArgs{
				Project:                gcpProject,
				DisplayName:            pulumi.String("Github Action Pool"),
				WorkloadIdentityPoolId: pulumi.String("github-action-pool"),
			})
			if err != nil {
				return err
			}
		}

		// WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "github-action-pool" \
		//   --project="${PROJECT_ID}" \
		//   --location="global" \
		//   --format="value(name)")
		// echo $WORKLOAD_IDENTITY_POOL_ID

		// gcloud iam workload-identity-pools providers create-oidc "github-action-provider" \
		//   --project="${PROJECT_ID}" \
		//   --location="global" \
		//   --workload-identity-pool="github-action-pool" \
		//   --display-name="Github Action Provider" \
		//   --attribute-mapping="
		//	google.subject=assertion.sub,
		//	attribute.actor=assertion.actor,
		//	attribute.repository=assertion.repository,
		//	attribute.repository_owner=assertion.repository_owner"
		//   --issuer-uri="https://token.actions.githubusercontent.com"

		wipp, err := iam.GetWorkloadIdentityPoolProvider(ctx, "github-action-provider", pulumi.ID("github-action-provider"), &iam.WorkloadIdentityPoolProviderState{
			WorkloadIdentityPoolId: wip.WorkloadIdentityPoolId,
		})
		if err != nil {
			wipp, err = iam.NewWorkloadIdentityPoolProvider(ctx, "github-action-provider", &iam.WorkloadIdentityPoolProviderArgs{
				Project:                        gcpProject,
				WorkloadIdentityPoolProviderId: pulumi.String("github-action-provider"),
				WorkloadIdentityPoolId:         wip.WorkloadIdentityPoolId,
				DisplayName:                    pulumi.String("Github Action Provider"),
				AttributeMapping: pulumi.StringMap{
					"google.subject":             pulumi.String("assertion.sub"),
					"attribute.actor":            pulumi.String("assertion.actor"),
					"attribute.repository":       pulumi.String("assertion.repository"),
					"attribute.repository_owner": pulumi.String("assertion.repository_owner"),
				},
				Oidc: iam.WorkloadIdentityPoolProviderOidcArgs{
					IssuerUri: pulumi.String("https://token.actions.githubusercontent.com"),
				},
			})
			if err != nil {
				return err
			}
		}
		// export REPO="mabels/mailu-arm" # e.g. "google/chrome"
		members := pulumi.StringArray{pulumi.String("user:meno.abels@gmail.com")}
		for _, repo := range []string{"mabels/mailu-arm", "mabels/developers-paradise"} {
			// gcloud iam service-accounts add-iam-policy-binding "github-action-service-account@${PROJECT_ID}.iam.gserviceaccount.com" \
			//   --project="${PROJECT_ID}" \
			//   --role="roles/iam.workloadIdentityUser" \
			//   --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
			members = append(members, pulumi.Sprintf("principalSet://iam.googleapis.com/%s/attribute.repository/%s", wip.Name, repo))
		}

		_, err = serviceaccount.NewIAMBinding(ctx, "workloadIdentityUser", &serviceaccount.IAMBindingArgs{
			ServiceAccountId: sa.ID(),
			Role:             pulumi.String("roles/iam.workloadIdentityUser"),
			Members:          members,
		})
		if err != nil {
			return err
		}

		_, err = serviceaccount.NewIAMBinding(ctx, "sa-iam-serviceAccountTokenCreator", &serviceaccount.IAMBindingArgs{
			ServiceAccountId: sa.ID(),
			Members: members,
			// pulumi.StringArray{pulumi.Sprintf("serviceAccount:%s", sa.Email)},
			// Project: gcpProject,
			Role:    pulumi.String("roles/iam.serviceAccountTokenCreator"),
		})
		if err != nil {
			return err
		}

		// gcloud iam workload-identity-pools providers describe "github-action-provider" \
		//   --project="${PROJECT_ID}" \
		//   --location="global" \
		//   --workload-identity-pool="github-action-pool" \
		//   --format="value(name)"

		// Export the DNS name of the bucket
		ctx.Export("service_account", sa.Email)
		ctx.Export("workload_identity_provider", wipp.Name)
		return nil
	})
}
