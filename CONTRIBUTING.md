# Contributing to Cursor Chat Recovery Kit

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the Cursor Chat Recovery Kit project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a branch for your changes
4. Make your changes
5. Test thoroughly on your own Cursor workspace
6. Submit a pull request

## Development Guidelines

### Code Style

- Use bash for shell scripts with `set -euo pipefail` for safety
- Follow existing script patterns and structure
- Add comments for complex logic
- Ensure scripts are executable (`chmod +x`)

### Testing

- Test all changes on a non-critical project first
- Verify scripts work with both zsh and bash
- Test on macOS (primary platform)
- Ensure backward compatibility when possible

### Documentation

- Update README.md for user-facing changes
- Add examples for new features
- Document any breaking changes clearly

### Pull Request Process

Before submitting a pull request, ensure:

- [ ] All scripts are executable
- [ ] Documentation is updated as needed
- [ ] Changes are tested on your own workspace
- [ ] Clear description of changes is provided
- [ ] Any related issues are referenced
- [ ] Code follows existing style and patterns

## Areas for Contribution

- **Platform Support** — Additional platform support (Linux, Windows)
- **Error Handling** — Improved error handling and user feedback
- **Performance** — Performance optimizations
- **Documentation** — Documentation improvements and examples
- **Testing** — Test coverage and test cases
- **Features** — New features (with discussion first)

## Questions?

Open an issue for discussion before implementing major changes.

---

<br>

**Made with ❤️ for the Cursor community**
