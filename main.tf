terraform {
  backend "s3" {
    bucket  = "terraform-fiapeats-videos"
    key     = "state/fiapeatsgateway/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_cognito_user_pool" "upload_user_pool" {
  user_pool_id = "us-east-1_K6TdejMf2"
}

data "aws_cognito_user_pool_client" "upload_client" {
  client_id    = "3s550l9fqaito48eb8tbu2msrt"
  user_pool_id = data.aws_cognito_user_pool.upload_user_pool.id
}

resource "aws_apigatewayv2_api" "api" {
  name          = "fiapeats-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "upload_cognito_authorizer" {
  name            = "upload-api-cognito-authorizer"
  api_id          = aws_apigatewayv2_api.api.id
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [data.aws_cognito_user_pool_client.upload_client.id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${data.aws_cognito_user_pool.upload_user_pool.id}"
  }
}

# POST /upload
resource "aws_apigatewayv2_integration" "upload_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:577638369685:function:tc-fiap-upload-video/invocations"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_post_route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /upload"
  target             = "integrations/${aws_apigatewayv2_integration.upload_lambda_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.upload_cognito_authorizer.id
  authorization_type = "JWT"
}

# GET /upload
resource "aws_apigatewayv2_integration" "get_upload_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:577638369685:function:fiapeats-lambda-consultavideos/invocations"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "videos_get_route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /upload"
  target             = "integrations/${aws_apigatewayv2_integration.get_upload_lambda_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.upload_cognito_authorizer.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "upload_apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvokeUploadPost"
  action        = "lambda:InvokeFunction"
  function_name = "tc-fiap-upload-video"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_upload_apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvokeUploadGet"
  action        = "lambda:InvokeFunction"
  function_name = "fiapeats-lambda-consultavideos"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
