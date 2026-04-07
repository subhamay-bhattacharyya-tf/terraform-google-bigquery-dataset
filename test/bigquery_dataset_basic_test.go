package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// TestBigQueryDatasetBasic tests creating a basic BigQuery dataset.
func TestBigQueryDatasetBasic(t *testing.T) {
	t.Parallel()

	retrySleep := 5 * time.Second
	unique := strings.ToLower(random.UniqueId())
	datasetID := fmt.Sprintf("tt_bq_basic_%s", unique)
	projectID := mustEnv(t, "GOOGLE_CLOUD_PROJECT")

	tfOptions := &terraform.Options{
		TerraformDir: "../examples/bigquery_dataset/basic",
		NoColor:      true,
		Vars: map[string]interface{}{
			"dataset_id": datasetID,
			"project":    projectID,
			"location":   "US",
		},
	}

	defer terraform.Destroy(t, tfOptions)
	terraform.InitAndApply(t, tfOptions)

	time.Sleep(retrySleep)

	// Assert all module outputs
	outputID := terraform.Output(t, tfOptions, "id")
	require.NotEmpty(t, outputID, "id output should not be empty")

	outputDatasetID := terraform.Output(t, tfOptions, "dataset_id")
	require.Equal(t, datasetID, outputDatasetID)

	outputProject := terraform.Output(t, tfOptions, "project")
	require.Equal(t, projectID, outputProject)

	outputLocation := terraform.Output(t, tfOptions, "location")
	require.Equal(t, "US", outputLocation)

	outputSelfLink := terraform.Output(t, tfOptions, "self_link")
	require.NotEmpty(t, outputSelfLink, "self_link output should not be empty")

	outputCreationTime := terraform.Output(t, tfOptions, "creation_time")
	require.NotEmpty(t, outputCreationTime, "creation_time output should not be empty")

	outputLastModifiedTime := terraform.Output(t, tfOptions, "last_modified_time")
	require.NotEmpty(t, outputLastModifiedTime, "last_modified_time output should not be empty")

	outputEtag := terraform.Output(t, tfOptions, "etag")
	require.NotEmpty(t, outputEtag, "etag output should not be empty")
}
