# PR Review Checklist

Use only relevant sections for the current pull request. Prefer depth over breadth.

## 1. Backend Code Quality and Structure

- Confirm naming follows project conventions.
- Confirm style and formatting align with repository standards.
- Flag duplicated logic that should be consolidated.
- Check separation of concerns across handlers/controllers, services, repositories, and domain logic.
- Flag complex functions or deeply nested branching that are hard to reason about or test.
- Flag unexplained magic numbers and hidden constants.
- Verify comments explain non-obvious logic and remove noise comments.

## 2. Security, Authentication, and Authorization

- Validate and sanitize all untrusted input.
- Verify SQL/database calls are parameterized.
- Verify authentication checks on protected backend operations.
- Verify authorization and role checks are complete on every sensitive code path.
- Flag hardcoded secrets, tokens, or credentials.
- Verify secure transport assumptions for sensitive backend operations.
- Flag dependency or package-level vulnerability concerns when visible.

## 3. Error Handling, Logging, and Observability

- Ensure expected failures are handled and surfaced safely.
- Ensure errors do not leak sensitive internals.
- Verify log level choices are appropriate.
- Verify cleanup paths for files, transactions, locks, and connections.
- Verify important operational signals are observable (metrics, traces, or structured logs where applicable).

## 4. Data Access and Migrations

- Check for N+1 queries and avoidable repeated database access.
- Validate indexes, query shape, and pagination for large datasets.
- Ensure schema changes include migrations.
- Ensure rollback or safe recovery path exists.
- Validate constraints and data integrity rules.
- Estimate migration impact on large datasets and runtime risk.

## 5. Performance and Scalability

- Check heavy computations and synchronous blocking work in request paths.
- Evaluate algorithmic complexity in hot paths.
- Verify async/concurrency usage avoids unnecessary blocking and race conditions.
- Check retry/backoff behavior for external dependencies.
- Identify useful caching opportunities when repeated reads dominate.

## 6. API Contracts and Backward Compatibility

- Validate API changes against existing contracts.
- Check backward compatibility and versioning impact.
- Ensure request/response and error formats stay consistent.
- Verify API behavior/documentation updates where needed.
- Consider rate limiting and abuse controls for exposed endpoints.

## 7. Testing Strategy

- Ensure new behavior has tests.
- Ensure tests cover boundary, failure, and concurrency cases.
- Ensure tests assert external behavior (not only implementation details).
- Ensure critical integration paths are exercised when changed.
- Verify mocks isolate external dependencies correctly.

## 8. Business Rules and Invariants

- Verify behavior matches requirements and acceptance criteria.
- Validate business-rule enforcement and edge cases.
- Verify auditability for high-risk backend operations.
- Flag flows that can violate invariants under concurrency.
