# Hardening Guide

## Disable registration and (optionally) invitations

- By default, vaultwarden allows any anonymous user to register new accounts on the server without first being invited.
- vaultwarden also allows registered users to invite other new users to create accounts on the server and join their organizations.

## Strick SNI

Suppose bitwarden.example.com has the IP address 1.2.3.4. Ideally, you want your instance to only be accessible via https://bitwarden.example.com, and not https://1.2.3.4.

## Access logs contain access_token parameter

A WSS connection is established for notifications by invoking a GET request with a JWT key.

Example GET request:

```
/notifications/hub?access_token=[this part is always the same].eyJuYmYi[redacted]sImV4cCI6MTcxNzc1NzQ1OCwiaXN[redacted]M6Ly92YXVsdC5zZWMuYXJwYXxsb2dpbiIsInN1YiI6ImY5YmVhN[redacted]tNGJjNS05MDY2LTQ3NjFlZmY4ND[redacted]sInByZW1pdW0iOnRydWU[redacted]JjaXBoZXIiLCJlbWFpbCI6ImNpc[redacted]ljdSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJzc3RhbXAiOiJlZjM3[redacted]MjctODE2OS1hZTQ3NmFjNDc4MGQiLCJkZX[redacted]02ZTk3LTQ2N2M[redacted]jM3NmEiLCJzY29wZSI6WyJhcG[redacted]5lX2FjY2VzcyJdLCJhbXIiOlsiQXBwbGljY[redacted]hGDeCNdjTs1cOL2fV_OR96Sey-gA5eRa8OCGNgCrDeyYAPyk[redacted]BkQGwjEhD7fcWILxRYqQ7W6rkC2o[redacted]LB_nztpAgeRUbsPgsd3RNTWJDKdlH8aMf1[redacted]vB_doENJPeyaeMuEG85KqpAN2A[redacted]GeeCztxmQIe21PMtBG-SAgGeI[redacted]X_9mmyv0nISHBuHjhQ_km[redacted]VCLoFneb-MEzN[redacted]T8VcXSKhGXpwJUx8j1[redacted]k_nH27vrD2Dg
```

- If your reverse proxy is configured to save access logs, or the access logs are shipped to an external service such as Prometheus + Promtail, it is recommended to redact the value of the access_token parameter on the external log store, or directly on your reverse proxy of choice, if supported.

- No other data is ever sent via GET request, encrypted or unencrypted.

- Be advised that internal vaultwarden logging strips query to 30 chars, hence access_token is truncated, meaning if not using reverse proxy, you shall be safe from this by default.

## Run as a non-root user

url : https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide