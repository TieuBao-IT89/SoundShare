# Development archive

The v1.2.0 cleanup removes historical QA screenshots, browser reports, the completed task backlog, and one-off review generators from the current source tree. The automated Flutter, backend, and Web test suites remain in the repository.

The material is preserved in Git history at [the snapshot before cleanup](https://github.com/TieuBao-IT89/SoundShare/tree/cadc3222f13d5d84bbec59c611bc6382ea8196e3):

- [UI audits, QA reports, and screenshots](https://github.com/TieuBao-IT89/SoundShare/tree/cadc3222f13d5d84bbec59c611bc6382ea8196e3/docs/ui)
- [Historical browser review generators](https://github.com/TieuBao-IT89/SoundShare/tree/cadc3222f13d5d84bbec59c611bc6382ea8196e3/scripts)
- [Backend review and V3 preflight tools](https://github.com/TieuBao-IT89/SoundShare/tree/cadc3222f13d5d84bbec59c611bc6382ea8196e3/backend/scripts)
- [Completed task backlog](https://github.com/TieuBao-IT89/SoundShare/blob/cadc3222f13d5d84bbec59c611bc6382ea8196e3/TASKS.md)

These are historical records, not current installation instructions or evidence that a particular deployment has passed device acceptance. Links in older design and feature guides point to this immutable snapshot where relevant.

Four selected sample screenshots remain in `docs/images/` for the README. New temporary review output belongs in ignored `build/` or `.local/`, not in the published documentation tree. This cleanup does not rewrite Git history.
