# Project Rules

## Language and Communication
- **Documentation**: All documentation (PRD, specs, manuals, code comments) must be written in **English**.
- **Naming Conventions**: All file names, variable names, function names, and other code identifiers must be in **English**.
- **Communication**: All chat communication with the user must be in **Lithuanian**.

## "Memory Bank"
This file serves as the persistent memory for project-specific rules and preferences as requested by the user.

## Privacy and Data Usage
- **No Training**: Project data, code, and documentation must NOT be used for model training purposes.
- **Privacy Mode**: Privacy mode is considered ACTIVE. Treat all data as confidential.

## Security
- **No Default Credentials**: Never use default usernames (e.g., `admin`, `root`) or passwords (e.g., `password`, `123456`).
- **Unique Secrets**: All environments must use unique, strong, generated secrets.
- **No Hardcoded Secrets**: Secrets must be loaded from environment variables (`.env`), never hardcoded in source files.
- **Data Encryption**: All sensitive data must be stored encrypted. Hardcoding of data is prohibited.
