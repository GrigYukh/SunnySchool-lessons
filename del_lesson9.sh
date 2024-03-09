#!/bin/bash

# Удаление DynamoDB таблицы
echo "Deleting DynamoDB table..."
aws dynamodb delete-table --table-name grigDB

# Удаление Lambda функции
echo "Deleting Lambda function..."
aws lambda delete-function --function-name grig-lambda-function

# Удаление API Gateway
echo "Deleting API Gateway..."
api_id=$(aws apigatewayv2 get-apis --query 'Items[?Name==`grig-api`].ApiId' --output text)
aws apigatewayv2 delete-api --api-id $api_id

echo "Домашнее задание удалено!"

