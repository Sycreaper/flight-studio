name: Bug report
description: Something does not work as documented
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to file a bug! Check *What works today*
        in the README first — some subsystems are planned-but-not-built in
        this pre-alpha.
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: A clear description of the unexpected behavior. If an error is shown in the chat bubble or logs, paste it verbatim.
      placeholder: |
        Steps to reproduce:
        1. …
        2. …
        Expected: …
        Actual: …
    validations:
      required: true
  - type: dropdown
    id: component
    attributes:
      label: Component
      options:
        - Flutter app (UI / map / inspector / settings)
        - AI copilot (chat, conversations, memory)
        - FlightStudio Core MCP tools (airport / charts / weather)
        - Agent Gateway (Node)
        - Navigation data import
        - Build / CI
        - Documentation
        - Other
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Version / commit
      description: Git commit (run `git rev-parse --short HEAD`) or artifact name if you built from CI.
      placeholder: 93ec3b6
  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: OS, Flutter version (`flutter --version`), Node version (`node --version`), model provider if the copilot is involved.
      placeholder: Windows 11, Flutter 3.44.5, Node 22.19, provider: …
  - type: textarea
    id: logs
    attributes:
      label: Relevant logs
      description: |
        Optional. Gateway log: `%TEMP%/flightstudio-gateway.log`; chat log:
        `%TEMP%/flightstudio-chat.log`. **Redact API keys before pasting.**
        Also check the tool audit trail (mcp-audit.sqlite) if an AI tool
        was involved.
        render: shell
