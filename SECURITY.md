# Security Policy

## Reporting a vulnerability

Please report suspected vulnerabilities privately through GitHub Security Advisories at https://github.com/excelano/bogenzeit-swift/security/advisories/new. If you would rather not use GitHub, email david.anderson@excelano.com instead. I aim to respond within seven days.

Please do not open public issues for security problems.

## Supported versions

The latest release receives fixes. A security fix ships through `main` in a new tagged release; there are no maintained release branches.

## Security model

**The package has no network surface.** It makes no network request, opens no socket and links no networking or analytics code. It reads nothing from the device: the app using it supplies the instant and the coordinates, and the package keeps nothing.
