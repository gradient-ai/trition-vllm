terraform {
  required_providers {
    paperspace = {
      source = "Paperspace/paperspace"
      version = "0.4.5"
    }
  }
}

provider "paperspace" {
  region = "East Coast (NY2)"
  api_key = "" // modify this to use your actual api key
}

data "paperspace_template" "my-template-1" {
  id = "tkni3aa4" // this is one of the ML in a Box templates from docs.digitalocean.com/reference/paperspace/core/commands/templates/
}

data "paperspace_user" "my-user-1" {
  email = "" // change to the email address of a user on your paperspace team
  team_id = "" // team ID of your Private workspace
}

resource "paperspace_script" "my-script-1" {
  name = "My Script"
  description = "a short description"
  script_text = <<EOF
#!/bin/bash
echo "Hello, World" > index.html
ufw allow 8080
nohup busybox httpd -f -p 8080 &
EOF
  is_enabled = true
  run_once = false
}

resource "paperspace_machine" "my-machine-1" {
  region = "East Coast (NY2)" // optional, defaults to provider region if not specified
  name = "Terraform ML in a Box"
  machine_type = "A6000x4"
  size = 500
  billing_type = "hourly"
  assign_public_ip = true // optional, remove if you don't want a public ip assigned
  template_id = data.paperspace_template.my-template-1.id
  user_id = data.paperspace_user.my-user-1.id  // optional, remove to default
  team_id = data.paperspace_user.my-user-1.team_id
  script_id = paperspace_script.my-script-1.id // optional, remove for no script
  shutdown_timeout_in_hours = 42
  # live_forever = true # enable this to make the machine have no shutdown timeout
}

