"use strict";

process.env.AWS_ECR_REGISTRY = "123456789012.dkr.ecr.us-east-1.amazonaws.com"

const assert = require("assert")
const index = require("./index");

const registry = process.env.AWS_ECR_REGISTRY;
const event = { rawPath: '/v2' };
const expected = { statusCode: 307, headers: { location: `https://${registry}/v2` } }

const callback = (_, res) => { assert.deepEqual(res, expected) }

index.handler(event, {}, callback);
