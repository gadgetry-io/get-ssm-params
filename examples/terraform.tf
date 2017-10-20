data "external" "app_config" {
  program = ["../build/get-ssm-params-linux"]

  query = {
    path = "/dev/myapp"
  }
}

output one_way {
  value = "${data.external.app_config.result.ApplicationParameters}"
}

output another_way {
  value = "${lookup(data.external.app_config.result, "ApplicationParameters")}"
}
