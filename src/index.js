"use strict";

const AWS_ECR_REGISTRY = process.env.AWS_ECR_REGISTRY;

exports.handler = (event, context, callback) => {
  console.log(`EVENT ${JSON.stringify(event)}`);
  const path = event.rawPath;
  const location = `https://${AWS_ECR_REGISTRY}${path}`;
  const redirect = { statusCode: 307, headers: { location: location } };
  callback(null, redirect);
};
