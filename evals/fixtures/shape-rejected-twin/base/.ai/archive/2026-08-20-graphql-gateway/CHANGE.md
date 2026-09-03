---
change: graphql-gateway
branch: graphql-gateway
created: 2026-08-20
status: rejected
rejected: 2026-08-22
---

# Change — a GraphQL gateway in front of the REST endpoints

## Why rejected

Two of the three consumers turned out to need streaming, which the gateway would have terminated,
and the third was already migrating off the REST endpoints entirely. The gateway would have been
built for one caller that is going away. Revisit only if a second streaming-free consumer appears.
