# STRUCTURE — Architecture, Ranks, Points, and Rules

Modules: shared (policy, points, ranks), server (permissions, commands, punishments), bot jobs, web-project.
Data: Roblox DataStore + OrderedDataStore; optional external cache for web.
Security: server-authoritative, RBAC, HMAC for svc calls, rate limits.
Testing: unit tests + simple runner.
