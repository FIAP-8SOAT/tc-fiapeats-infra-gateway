provider "aws" {
  region = "us-east-1"
}

data "aws_cognito_user_pool" "fiapeats_user_pool" {
  user_pool_id = "us-east-1_udRdYqNeL"  
}

data "aws_cognito_user_pool_client" "fiapeats_client" {
  client_id = "2mj0dbqvpnlm5513i9v90sttp5"
  user_pool_id = data.aws_cognito_user_pool.fiapeats_user_pool.id
}

resource "aws_apigatewayv2_api" "api" {
  name          = "fiapeats-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "cognito_authorizer" {
  name            = "fiapeats-cognito-authorizer"
  api_id          = aws_apigatewayv2_api.api.id
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [data.aws_cognito_user_pool_client.fiapeats_client.id]
    issuer   = "https://cognito-idp.us-east-1.amazonaws.com/${data.aws_cognito_user_pool.fiapeats_user_pool.id}"
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:831926610628:function:lambdaTeste/invocations"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "videos_get_route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /videos"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_authorizer.id
  authorization_type = "JWT"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "lambdaTeste"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}