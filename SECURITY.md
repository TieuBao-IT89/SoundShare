# Security policy

## Reporting a vulnerability

Do not post vulnerabilities, credentials, connection strings, or private user data in public issues. Contact the [repository maintainer](https://github.com/TieuBao-IT89) privately using an available contact channel on their profile. If GitHub private vulnerability reporting is available on the repository's Security page, use that instead.

Include a description, affected version, impact, and minimal reproduction using synthetic data. Remove tokens and personal information from logs and screenshots. Allow time for review and a coordinated fix before publishing details.

## Supported versions

Security fixes target the latest published release. Older releases may require an upgrade. This is a community project; there is no guaranteed response time or security audit certification.

## Configuration boundaries

Database, Clerk secret, and Cloudinary credentials belong only in the backend environment. Never put them in Flutter configuration, build arguments, committed files, client responses, or public logs. Use separate development, test, and production resources with TLS and appropriate access controls.

If a credential is exposed, revoke or rotate it with its provider and update the affected deployment. Deleting a file or commit does not revoke the credential.
