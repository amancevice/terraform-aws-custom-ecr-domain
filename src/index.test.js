"use strict";

const assert = require("assert")
const index = require("./index");

const event = {
  Records: [{
    cf: {
      request: {
        clientIp: "1.2.3.4",
        headers: {
          host: [{key: "Host", value: "ecr.example.com"}]
        },
        origin: {
          custom: {
            domainName: "123456789012.dkr.ecr.us-east-1.amazonaws.com"
          }
        }
      }
    }
  }]
};
const expected = {
  clientIp: "1.2.3.4",
  headers: {
    "host": [{key: "Host", value: "123456789012.dkr.ecr.us-east-1.amazonaws.com"}],
    "x-forwarded-for": [{key: "X-Forwarded-For", value: "1.2.3.4"}]
  },
  origin: {
    custom: {
      domainName: "123456789012.dkr.ecr.us-east-1.amazonaws.com"
    }
  }
}

const callback = (_, res) => { assert.deepEqual(res, expected) }

index.handler(event, {}, callback);
