name: Feature request
description: Propose a new capability or improvement
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem would this solve?
      description: The flight-planning or copilot workflow that is painful or impossible today. Feature requests are evaluated by the problem, not the solution.
      placeholder: As a sim pilot, I want to … but currently …
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: What solution do you imagine?
      description: Optional — a rough sketch is enough. Roadmap alignment helps (see the Roadmap section of the README).
  - type: dropdown
    id: area
    attributes:
      label: Area
      options:
        - Flight planning (routes, procedures, export)
        - AI copilot / MCP tools
        - Map & airport inspector
        - Simulator connectivity (X-Plane / MSFS)
        - Navigation data
        - Remote monitoring
        - UI / UX / i18n
        - Other
    validations:
      required: true
  - type: checkboxes
    id: checks
    attributes:
      label: Before you submit
      options:
        - label: I checked the README Roadmap — this is not already planned there
          required: true
        - label: I searched the open issues for duplicates
          required: true
