package test

import (
	"fmt"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

const (
	cloudflareAPITokenEnvKey = "CLOUDFLARE_API_TOKEN"
	cloudflareZoneEnvKey     = "TF_VAR_cloudflare_zone_id"
	upcloudUsernameEnvKey    = "UPCLOUD_USERNAME"
	upcloudPasswordEnvKey    = "UPCLOUD_PASSWORD"
	sshPrivateKeyEnvKey      = "UPCLOUD_PRIVATE_SSH_KEY"
	sshPublicKeyEnvKey       = "UPCLOUD_PUBLIC_SSH_KEY"
	ownPublicIPEnvKey        = "TF_VAR_own_public_ip"
)

var requiredEnvVars = []string{
	cloudflareAPITokenEnvKey,
	cloudflareZoneEnvKey,
	upcloudPasswordEnvKey,
	upcloudUsernameEnvKey,
	ownPublicIPEnvKey,
}

func TestScalableInfrastructure(t *testing.T) {
	checkEnvVariables(t)

	subdomain := strings.ToLower(random.UniqueId())
	publicKey := os.Getenv(sshPublicKeyEnvKey)
	privateKey := os.Getenv(sshPrivateKeyEnvKey)

	tfOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./basic",
		Vars: map[string]interface{}{
			"subdomain_name":   subdomain,
			"servers_ssh_keys": []string{publicKey},
		},
	})

	defer terraform.Destroy(t, tfOpts)
	terraform.InitAndApply(t, tfOpts)

	var servers []string
	terraform.OutputStruct(t, tfOpts, "servers_public_ips", &servers)

	outputs := terraform.OutputAll(t, tfOpts)
	keyPair := &ssh.KeyPair{
		PublicKey:  publicKey,
		PrivateKey: privateKey,
	}
	wg := sync.WaitGroup{}

	for _, serverIP := range servers {
		wg.Add(1)

		serverIP := serverIP

		go func() {
			defer wg.Done()
			installWordpress(t, serverIP, keyPair, outputs)
		}()
	}

	wg.Wait()

	// We go directly to install page because links don't work properly with SSL without the X-Forwarded-Proto header
	// UpCloud Load Balancer already supports adding that header (as a frontend rule), but it's not yet implemented in UpCloud TF provider
	URL := fmt.Sprintf("https://%s/wp-admin/install.php", outputs["url"])

	http_helper.HttpGetWithRetryWithCustomValidation(t, URL, nil, 50, 5*time.Second, func(_ int, resBody string) bool {
		// First thing on the installation page is the language selection
		return strings.Contains(resBody, "WordPress") && strings.Contains(resBody, "Select a default language")
	})
}

func installWordpress(t *testing.T, serverIP string, keyPair *ssh.KeyPair, outputs map[string]interface{}) {
	logger.Log(t, fmt.Sprintf("Installing Wordpress on the server %s", serverIP))

	host := ssh.Host{
		Hostname:    serverIP,
		SshUserName: "root",
		SshKeyPair:  keyPair,
	}

	ssh.CheckSshCommand(t, host, "curl -fsSL https://get.docker.com -o get-docker.sh && sh ./get-docker.sh")
	ssh.CheckSshCommand(t, host, fmt.Sprintf(`docker run --name test -p 80:80 -d -v "$PWD/html":/var/www/html -e WORDPRESS_DB_HOST=%s:%s -e WORDPRESS_DB_USER=%s -e WORDPRESS_DB_PASSWORD=%s -e WORDPRESS_DB_NAME=%s wordpress:6.0.0`,
		outputs["db_host"],
		outputs["db_port"],
		outputs["db_username"],
		outputs["db_password"],
		outputs["primary_db"]))

	logger.Log(t, fmt.Sprintf("Wordpress installed on the server %s", serverIP))
}

func checkEnvVariables(t *testing.T) {
	for i := 0; i < len(requiredEnvVars); i++ {
		envVar := os.Getenv(requiredEnvVars[i])
		if envVar == "" {
			t.Logf("%s enviroment variable is not set", requiredEnvVars[i])
			t.FailNow()
		}
	}
}
