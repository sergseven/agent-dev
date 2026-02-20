based on this finding and proposal [text](../sdd/spec-driven-development-workflow.md), i want to create a skill which should help to onboard a repository to generate specification and documentation right in the repository.
The spec and doc should be created by gradual chunked code and docs analysis, with mandatory research on Jira and Confluence, Slack or Google docs to find intentions or Other github repositories to find dependencies. Using MCP, the sources are configurable.
The spec and doc should be built with such precision, that it should be possible to reimplement existing functionality solely based on the generated specification and documentation(without additional context or knowledge from the original developers or from external sources).
Another sub agent can be used to verify if the spec or doc produced can be used to reimplement existing functionality.
Challenge me on the proposed solution, don't take it as a final decision.

Requirements:
* it should be possible to reimplement existing functionality solely based on the generated specification and documentation
* the skill should be able to analyze code and documentation in chunks, gradually building a comprehensive specification
* it should be possible to configure the sources for research, such as Jira, Confluence, Slack, or Google Docs, Github repos
* it should be possible to resume the analysis from where it left off in case of interruptions
* it should be possible to work with such repository types:
 - Protocol definitions (eg: Thrift, Protobuf API definitions)
 - Backend only
 - API-heavy (GraphQL + REST) backend only
 - Web frontend single application
 - Web frontend monorepo
 - ETL repo(like Airflow)
 * can be started manually
* it should be verified automatically, if the spec or doc produced can be used to reimplement existing functionality
* the skill should be located in this repo (agent-dev)




