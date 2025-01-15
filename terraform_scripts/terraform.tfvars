web_app_repo_zip = "../fake-crypto-web-app-project-main.zip"

enabled_modules = {
  code_upload            = true
  codebuild_creation     = true
  ecs_service_creation   = true
  alb_creation           = true
  circuit_breaker        = true  // Remains as a flag within ecs_service_creation
  codepipeline_creation = true
}