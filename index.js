"use strict";

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;
  headers["host"] = [{ key: "Host", value: request.origin.custom.domainName }];
  headers["x-forwarded-for"] = [{ key: "X-Forwarded-For", value: request.clientIp }];
  callback(null, request);
};
