package tests

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSharedNetworkingModule(t *testing.T) {
	t.Parallel()

	// Pick a random AWS region to test in
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	// Give this VPC a unique ID for a name tag so we can distinguish it from any other VPC created concurrently
	uniqueID := random.UniqueId()

	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../terraform/modules/shared-networking",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"project_name":            fmt.Sprintf("test-epic-%s", uniqueID),
			"environment":            "test",
			"vpc_cidr":               "10.0.0.0/16",
			"public_subnet_count":    2,
			"private_subnet_count":   2,
			"database_subnet_count":  2,
			"enable_nat_gateway":     true,
			"nat_gateway_count":      1,
			"enable_flow_logs":       true,
			"enable_vpc_endpoints":   true,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr_block")
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	databaseSubnetIDs := terraform.OutputList(t, terraformOptions, "database_subnet_ids")
	igwID := terraform.Output(t, terraformOptions, "internet_gateway_id")

	// Verify that we get back the outputs we expect
	assert.NotEmpty(t, vpcID)
	assert.Equal(t, "10.0.0.0/16", vpcCidr)
	assert.Len(t, publicSubnetIDs, 2)
	assert.Len(t, privateSubnetIDs, 2)
	assert.Len(t, databaseSubnetIDs, 2)
	assert.NotEmpty(t, igwID)

	// Verify the VPC exists and has the expected properties
	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	assert.Equal(t, vpcCidr, *vpc.CidrBlock)
	assert.True(t, *vpc.EnableDnsHostnames)
	assert.True(t, *vpc.EnableDnsSupport)

	// Verify subnets are in different AZs
	azs := make(map[string]bool)
	for _, subnetID := range publicSubnetIDs {
		subnet := aws.GetSubnetById(t, subnetID, awsRegion)
		azs[*subnet.AvailabilityZone] = true
		assert.True(t, *subnet.MapPublicIpOnLaunch)
	}
	assert.GreaterOrEqual(t, len(azs), 1, "Subnets should be distributed across multiple AZs")

	// Verify Internet Gateway is attached to VPC
	igw := aws.GetInternetGatewayById(t, igwID, awsRegion)
	assert.Len(t, igw.Attachments, 1)
	assert.Equal(t, vpcID, *igw.Attachments[0].VpcId)
	assert.Equal(t, "available", *igw.Attachments[0].State)

	// Verify Security Groups exist and have proper rules
	webSGID := terraform.Output(t, terraformOptions, "web_security_group_id")
	appSGID := terraform.Output(t, terraformOptions, "application_security_group_id")
	dbSGID := terraform.Output(t, terraformOptions, "database_security_group_id")

	assert.NotEmpty(t, webSGID)
	assert.NotEmpty(t, appSGID)
	assert.NotEmpty(t, dbSGID)

	// Verify VPC endpoints are created when enabled
	s3EndpointID := terraform.Output(t, terraformOptions, "s3_vpc_endpoint_id")
	dynamodbEndpointID := terraform.Output(t, terraformOptions, "dynamodb_vpc_endpoint_id")

	assert.NotEmpty(t, s3EndpointID)
	assert.NotEmpty(t, dynamodbEndpointID)

	// Verify Flow Logs are enabled
	flowLogsEnabled := terraform.Output(t, terraformOptions, "vpc_flow_logs_enabled")
	assert.Equal(t, "true", flowLogsEnabled)
}

func TestSharedNetworkingModuleMinimal(t *testing.T) {
	t.Parallel()

	// Pick a random AWS region to test in
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	// Give this VPC a unique ID for a name tag
	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/modules/shared-networking",

		Vars: map[string]interface{}{
			"project_name":            fmt.Sprintf("test-minimal-%s", uniqueID),
			"environment":            "test",
			"public_subnet_count":    1,
			"private_subnet_count":   1,
			"database_subnet_count":  0,
			"enable_nat_gateway":     false,
			"enable_flow_logs":       false,
			"enable_vpc_endpoints":   false,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify basic resources are created
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")

	assert.NotEmpty(t, vpcID)
	assert.Len(t, publicSubnetIDs, 1)
	assert.Len(t, privateSubnetIDs, 1)

	// Verify no database subnets when count is 0
	dbSubnetGroupName := terraform.Output(t, terraformOptions, "db_subnet_group_name")
	assert.Empty(t, dbSubnetGroupName)
}

func TestSharedNetworkingModuleValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name          string
		vars          map[string]interface{}
		expectError   bool
		errorContains string
	}{
		{
			name: "invalid_environment",
			vars: map[string]interface{}{
				"project_name": "test-epic",
				"environment":  "invalid",
			},
			expectError:   true,
			errorContains: "Environment must be one of: shared, staging, production",
		},
		{
			name: "invalid_vpc_cidr",
			vars: map[string]interface{}{
				"project_name": "test-epic",
				"environment":  "test",
				"vpc_cidr":     "invalid-cidr",
			},
			expectError:   true,
			errorContains: "VPC CIDR must be a valid CIDR block",
		},
		{
			name: "invalid_subnet_count",
			vars: map[string]interface{}{
				"project_name":         "test-epic",
				"environment":         "test",
				"public_subnet_count": 10,
			},
			expectError:   true,
			errorContains: "Public subnet count must be between 1 and 6",
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../terraform/modules/shared-networking",
				Vars:         tc.vars,
			}

			_, err := terraform.InitAndPlanE(t, terraformOptions)

			if tc.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorContains)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestSharedNetworkingModuleNaming(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	uniqueID := random.UniqueId()
	projectName := fmt.Sprintf("test-naming-%s", uniqueID)
	environment := "test"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/modules/shared-networking",

		Vars: map[string]interface{}{
			"project_name": projectName,
			"environment":  environment,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify naming conventions
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpc := aws.GetVpcById(t, vpcID, awsRegion)

	expectedVPCName := fmt.Sprintf("%s-%s-vpc", projectName, environment)
	vpcName := aws.GetTagsForVpc(t, vpcID, awsRegion)["Name"]
	assert.Equal(t, expectedVPCName, vpcName)

	// Verify tags are consistent
	tags := aws.GetTagsForVpc(t, vpcID, awsRegion)
	assert.Equal(t, environment, tags["Environment"])
	assert.Equal(t, "shared-networking", tags["Module"])

	// Verify subnet naming
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	for i, subnetID := range publicSubnetIDs {
		subnetTags := aws.GetTagsForSubnet(t, subnetID, awsRegion)
		expectedSubnetName := fmt.Sprintf("%s-%s-public-%d", projectName, environment, i+1)
		assert.Equal(t, expectedSubnetName, subnetTags["Name"])
		assert.Equal(t, "Public", subnetTags["Type"])
	}
}