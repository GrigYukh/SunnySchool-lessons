#!/bin/bash

# Создание DynamoDB таблицы
echo "Creating DynamoDB table..."
aws dynamodb create-table \
    --table-name grigDB \
    --attribute-definitions \
        AttributeName=ID,AttributeType=S \
    --key-schema \
        AttributeName=ID,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5

# Ожидание создания DynamoDB таблицы
echo "Waiting for DynamoDB table to be created..."
aws dynamodb wait table-exists --table-name grigDB

# Создание Lambda функции
echo "Creating Lambda function..."
aws lambda create-function \
    --function-name grig-lambda-function \
    --runtime python3.8 \
    --role arn:aws:iam::730335231758:role/lambda-role \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://lambda_function.zip

# Создание Lambda функции 
echo 'import json\n\ndef lambda_handler(event, context):\n    return {\n        "statusCode": 200,\n        "body": json.dumps("Hello World! My first Lambda Functions in AWS!")\n    }' > lambda_function.py
zip lambda_function.zip lambda_function.py

# Создание API Gateway
echo "Creating API Gateway..."
api_id=$(aws apigatewayv2 create-api --name grig-api --protocol-type HTTP --target lambda:us-east-1:730335231758:function:grig-lambda-function --query 'ApiId' --output text)

# Создание REST API
echo "Creating REST API..."
aws apigatewayv2 create-api-mapping --api-id $api_id --domain-name-id $DOMAIN_NAME_ID --stage auto --api-mapping-key ""

# Публикация REST API
echo "Deploying REST API..."
aws apigatewayv2 create-stage --api-id $api_id --stage-name v1

echo "API Gateway setup complete!"
